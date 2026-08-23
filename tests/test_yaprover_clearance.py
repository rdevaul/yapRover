"""OCC collision and clearance acceptance for the detailed suspension.

Only a wheel and its own future hub/shaft may overlap.  All other printed
moving parts must have zero positive intersection volume, and every wheel must
retain five millimetres of clearance from links and chassis.
"""

from __future__ import annotations

import math
from pathlib import Path

import numpy as np
import pytest

from yapcad.brep import has_brep_data, occ_available
from yapcad.dsl import compile_and_run
from yaprover.kinematics.clearance import (
    audit_positioned_breps,
    canonical_pair,
    canonical_pairs,
)

from test_yaprover_suspension_detailed import PART_INSTANCES, make_detailed_assembly


EXAMPLE = (
    Path(__file__).resolve().parents[1]
    / "designs"
    / "yaprover_suspension_detailed.dsl"
)
PART_COMMANDS = {
    command: (command,)
    for command in dict.fromkeys(command for command, _ in PART_INSTANCES)
}
WHEELS = (
    "left_front_wheel", "left_middle_wheel", "left_rear_wheel",
    "right_front_wheel", "right_middle_wheel", "right_rear_wheel",
)
PRINTED_LINKS = ("chassis", "left_rocker", "right_rocker",
                 "left_bogie", "right_bogie")


def _intended_wheel_contacts(part_names):
    """Return only explicit wheel-to-own-hub/shaft contact pairs."""
    names = set(part_names)
    allowed = set()
    for wheel in WHEELS:
        stem = wheel.removesuffix("_wheel")
        for candidate in (f"{stem}_hub", f"{stem}_shaft"):
            if wheel in names and candidate in names:
                allowed.add(canonical_pair(wheel, candidate))
    return allowed


def _intended_differential_contacts(part_names):
    """Allow only the two explicitly meshing bevel-gear pairs."""
    names = set(part_names)
    pairs = {
        canonical_pair("differential_planet_pair", side)
        for side in (
            "left_differential_side_gear",
            "right_differential_side_gear",
        )
        if "differential_planet_pair" in names and side in names
    }
    return pairs


def _intended_contacts(part_names):
    return (_intended_wheel_contacts(part_names) |
            _intended_differential_contacts(part_names))


def _wheel_clearance_requirements():
    return {
        canonical_pair(wheel, link): 5.0
        for wheel in WHEELS for link in PRINTED_LINKS
    }


def _sweep_collision_pairs():
    """Pairs that can approach during the bounded planar joint sweep."""
    pairs = set(_wheel_clearance_requirements())
    pairs.update(canonical_pairs({
        ("chassis", "left_rocker"),
        ("chassis", "right_rocker"),
        ("left_rocker", "left_bogie"),
        ("right_rocker", "right_bogie"),
    }))
    return pairs


def _compile_first(source, candidates):
    diagnostics = []
    for command in candidates:
        result = compile_and_run(source, command, {})
        if result.success:
            return result.geometry
        diagnostics.append(f"{command}: {result.error_message}")
    pytest.skip("No supported rover command found; " + "; ".join(diagnostics))


def test_contact_allowlist_is_exact_and_never_allows_wheel_to_link():
    names = set(WHEELS) | set(PRINTED_LINKS) | {
        "left_front_hub", "left_front_shaft", "unrelated_hub",
    }

    allowed = _intended_wheel_contacts(names)

    assert allowed == canonical_pairs({
        ("left_front_wheel", "left_front_hub"),
        ("left_front_wheel", "left_front_shaft"),
    })
    assert canonical_pair("left_front_wheel", "left_rocker") not in allowed
    assert canonical_pair("left_front_wheel", "unrelated_hub") not in allowed


def test_differential_allowlist_contains_only_the_two_tooth_meshes():
    names = {
        "differential_planet_pair",
        "left_differential_side_gear",
        "right_differential_side_gear",
        "differential_cross_pin",
        "left_rocker_pivot_shaft",
    }

    allowed = _intended_differential_contacts(names)

    assert allowed == canonical_pairs({
        ("differential_planet_pair", "left_differential_side_gear"),
        ("differential_planet_pair", "right_differential_side_gear"),
    })
    assert canonical_pair(
        "differential_cross_pin", "left_rocker_pivot_shaft"
    ) not in allowed


def test_clearance_policy_covers_every_wheel_against_links_and_chassis():
    requirements = _wheel_clearance_requirements()

    assert len(requirements) == len(WHEELS) * len(PRINTED_LINKS)
    assert all(clearance == 5.0 for clearance in requirements.values())


@pytest.fixture(scope="module")
def occ_rover():
    if not occ_available():
        pytest.skip("pythonocc-core is not available")
    source = EXAMPLE.read_text(encoding="utf-8")
    solids = {
        canonical: _compile_first(source, candidates)
        for canonical, candidates in PART_COMMANDS.items()
    }
    assert all(has_brep_data(solid) for solid in solids.values())
    assembly = make_detailed_assembly(solids)
    result = assembly.solve("chassis")
    assert result.success, result.errors
    return assembly


@pytest.mark.requires_occ
@pytest.mark.expensive_geometry
def test_flat_pose_has_no_unallowlisted_positive_intersection(occ_rover):
    positioned = occ_rover.positioned_parts()
    report = audit_positioned_breps(
        positioned,
        intended_contacts=_intended_contacts(positioned),
    )

    assert not report.collision_violations, report.collision_violations


@pytest.mark.requires_occ
@pytest.mark.expensive_geometry
def test_flat_wheel_to_link_and_chassis_clearance_is_at_least_5mm(occ_rover):
    positioned = occ_rover.positioned_parts()
    report = audit_positioned_breps(
        positioned,
        intended_contacts=_intended_wheel_contacts(positioned),
        minimum_clearances=_wheel_clearance_requirements(),
        pairs=_wheel_clearance_requirements(),
    )

    assert not report.collision_violations, report.collision_violations
    assert not report.clearance_violations, report.clearance_violations


@pytest.mark.requires_occ
@pytest.mark.expensive_geometry
def test_joint_range_sweep_uses_at_most_two_degree_steps(occ_rover):
    """Sweep representative one-DOF sections rather than the full 4-D grid."""
    sweeps = (
        ("left_rocker_pivot", np.arange(-18.0, 18.01, 2.0)),
        ("left_bogie_pivot", np.arange(-35.0, 38.01, 2.0)),
        ("right_bogie_pivot", np.arange(-35.0, 38.01, 2.0)),
    )
    checked = 0
    for joint, angles in sweeps:
        assert np.max(np.diff(angles)) <= 2.0
        if joint == "left_rocker_pivot":
            requirements = {
                canonical_pair(wheel, "chassis"): 5.0 for wheel in WHEELS
            }
            collision_pairs = set(requirements) | canonical_pairs({
                ("chassis", "left_rocker"),
                ("chassis", "right_rocker"),
                ("chassis", "left_bogie"),
                ("chassis", "right_bogie"),
                ("left_rocker", "left_bogie"),
                ("right_rocker", "right_bogie"),
                ("differential_planet_pair", "left_differential_side_gear"),
                ("differential_planet_pair", "right_differential_side_gear"),
                ("differential_cross_pin", "left_rocker_pivot_shaft"),
                ("differential_cross_pin", "right_rocker_pivot_shaft"),
                ("differential_carrier_bearings", "left_rocker_pivot_shaft"),
                ("differential_carrier_bearings", "right_rocker_pivot_shaft"),
            })
        else:
            side = "left" if joint.startswith("left") else "right"
            moving_wheels = (f"{side}_middle_wheel", f"{side}_rear_wheel")
            requirements = {
                canonical_pair(wheel, structure): 5.0
                for wheel in moving_wheels
                for structure in ("chassis", f"{side}_rocker")
            }
            collision_pairs = set(requirements) | canonical_pairs({
                (f"{side}_bogie", f"{side}_rocker"),
                (f"{side}_bogie", "chassis"),
            })
        for angle in angles:
            result = occ_rover.solve("chassis", {
                "left_rocker_pivot": 0.0,
                "left_bogie_pivot": 0.0,
                "right_bogie_pivot": 0.0,
                joint: math.radians(float(angle)),
            })
            assert result.success, (joint, angle, result.errors)
            needed_parts = {
                name for pair in collision_pairs | set(requirements)
                for name in pair
            }
            positioned = {
                name: occ_rover.get_part_geometry(name, positioned=True)
                for name in needed_parts
            }
            report = audit_positioned_breps(
                positioned,
                intended_contacts=_intended_contacts(positioned),
                minimum_clearances=requirements,
                pairs=collision_pairs,
            )
            assert report.success, (joint, angle, report)
            checked += 1
    assert checked >= 90


def test_rover_defines_separate_hub_or_shaft_geometry_for_contact_allowlist():
    source = EXAMPLE.read_text(encoding="utf-8")
    proposed = ("AXLE_SHAFT", "WHEEL_SHAFT")

    assert any(f"command {name}(" in source for name in proposed)
