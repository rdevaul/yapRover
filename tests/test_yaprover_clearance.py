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
from yapcad.geom3d import solidbbox
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
LIMIT_CONTACT_PAIRS = canonical_pairs({
    ("left_rocker", "left_rocker_limit_bumpers"),
    ("right_rocker", "right_rocker_limit_bumpers"),
    ("left_bogie", "left_bogie_limit_bumpers"),
    ("right_bogie", "right_bogie_limit_bumpers"),
})
MOVING_AXLE_PARTS = tuple(
    instance for _, instance in PART_INSTANCES
    if instance.endswith(("_shaft", "_spacer", "_hardware",
                          "_keys", "_bearings"))
)


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
    """Allow only the four explicitly meshing bevel-gear pairs."""
    names = set(part_names)
    pairs = {
        canonical_pair(planet, side)
        for planet in (
            "front_differential_planet_gear",
            "rear_differential_planet_gear",
        )
        for side in (
            "left_differential_side_gear",
            "right_differential_side_gear",
        )
        if planet in names and side in names
    }
    return pairs


def _intended_key_contacts(part_names):
    """Allow the two parallel keys to bear on their keyed rocker shafts."""
    names = set(part_names)
    return {
        canonical_pair(f"{side}_rocker_pivot_shaft",
                       f"{side}_rocker_pivot_keys")
        for side in ("left", "right")
        if f"{side}_rocker_pivot_shaft" in names
        and f"{side}_rocker_pivot_keys" in names
    }


def _intended_contacts(part_names, *, limit_contacts=()):
    names = set(part_names)
    present_limit_contacts = {
        pair for pair in limit_contacts
        if pair[0] in names and pair[1] in names
    }
    return (_intended_wheel_contacts(part_names) |
            _intended_differential_contacts(part_names) |
            _intended_key_contacts(part_names) |
            present_limit_contacts)


def _wheel_clearance_requirements():
    return {
        canonical_pair(wheel, link): 5.0
        for wheel in WHEELS for link in PRINTED_LINKS
    }


def _foreign_wheel_hardware_requirements():
    """Require every wheel to clear every other station's axle stack."""
    requirements = {}
    for wheel in WHEELS:
        station = wheel.removesuffix("_wheel")
        for part in MOVING_AXLE_PARTS:
            if part.startswith(station + "_"):
                continue
            requirements[canonical_pair(wheel, part)] = 5.0
    return requirements


def _chassis_hardware_pairs():
    """All modeled axle-stack parts must remain out of chassis material."""
    return {
        canonical_pair("chassis", part) for part in MOVING_AXLE_PARTS
    }


def _bbox_corners(solid):
    lower, upper = (np.asarray(point[:3]) for point in solidbbox(solid))
    return np.asarray([
        [x, y, z, 1.0]
        for x in (lower[0], upper[0])
        for y in (lower[1], upper[1])
        for z in (lower[2], upper[2])
    ])


def _transformed_bounds(corners, transform):
    points = (transform @ corners.T).T[:, :3]
    return points.min(axis=0), points.max(axis=0)


def _aabb_distance(first, second):
    first_min, first_max = first
    second_min, second_max = second
    separation = np.maximum(
        0.0, np.maximum(first_min - second_max, second_min - first_max)
    )
    return float(np.linalg.norm(separation))


def _broad_phase_candidates(local_corners, transforms, pairs, requirements):
    """Promote only pairs whose transformed AABBs cannot prove clearance."""
    names = {name for pair in pairs for name in pair}
    bounds = {
        name: _transformed_bounds(local_corners[name], transforms[name])
        for name in names
    }
    return {
        pair for pair in pairs
        if _aabb_distance(bounds[pair[0]], bounds[pair[1]])
        <= requirements.get(pair, 0.0) + 1e-9
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
    pairs.update(LIMIT_CONTACT_PAIRS)
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


def test_differential_allowlist_contains_only_the_four_tooth_meshes():
    names = {
        "front_differential_planet_gear",
        "rear_differential_planet_gear",
        "left_differential_side_gear",
        "right_differential_side_gear",
        "differential_cross_pin",
        "left_rocker_pivot_shaft",
    }

    allowed = _intended_differential_contacts(names)

    assert allowed == canonical_pairs({
        ("front_differential_planet_gear", "left_differential_side_gear"),
        ("front_differential_planet_gear", "right_differential_side_gear"),
        ("rear_differential_planet_gear", "left_differential_side_gear"),
        ("rear_differential_planet_gear", "right_differential_side_gear"),
    })
    assert canonical_pair(
        "differential_cross_pin", "left_rocker_pivot_shaft"
    ) not in allowed


def test_split_parallel_keys_only_allow_contact_with_their_own_shafts():
    names = {
        "left_rocker_pivot_shaft", "left_rocker_pivot_keys",
        "right_rocker_pivot_shaft", "right_rocker_pivot_keys",
    }
    assert _intended_key_contacts(names) == canonical_pairs({
        ("left_rocker_pivot_shaft", "left_rocker_pivot_keys"),
        ("right_rocker_pivot_shaft", "right_rocker_pivot_keys"),
    })


def test_clearance_policy_covers_every_wheel_against_links_and_chassis():
    requirements = _wheel_clearance_requirements()

    assert len(requirements) == len(WHEELS) * len(PRINTED_LINKS)
    assert all(clearance == 5.0 for clearance in requirements.values())


def test_rom_policy_covers_foreign_hardware_and_every_chassis_axle_pair():
    requirements = _foreign_wheel_hardware_requirements()
    chassis_pairs = _chassis_hardware_pairs()

    assert requirements
    assert chassis_pairs == {
        canonical_pair("chassis", part) for part in MOVING_AXLE_PARTS
    }
    for wheel in WHEELS:
        station = wheel.removesuffix("_wheel")
        assert canonical_pair(wheel, f"{station}_shaft") not in requirements
        assert all(
            requirements[canonical_pair(wheel, part)] == 5.0
            for part in MOVING_AXLE_PARTS
            if not part.startswith(station + "_")
        )


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
    """Sweep every joint range with broad-phase promotion to exact BREP."""
    sweeps = (
        ("left_rocker_pivot", np.arange(-18.0, 18.01, 2.0)),
        ("left_bogie_pivot",
         np.concatenate((np.arange(-35.0, 38.0, 2.0), [38.0]))),
        ("right_bogie_pivot",
         np.concatenate((np.arange(-35.0, 38.0, 2.0), [38.0]))),
    )
    foreign_hardware_requirements = _foreign_wheel_hardware_requirements()
    chassis_hardware_pairs = _chassis_hardware_pairs()
    local_corners = {
        name: _bbox_corners(occ_rover.get_part_geometry(name))
        for name in occ_rover.parts
    }
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
                ("front_differential_planet_gear", "left_differential_side_gear"),
                ("front_differential_planet_gear", "right_differential_side_gear"),
                ("rear_differential_planet_gear", "left_differential_side_gear"),
                ("rear_differential_planet_gear", "right_differential_side_gear"),
                ("differential_cross_pin", "left_rocker_pivot_shaft"),
                ("differential_cross_pin", "right_rocker_pivot_shaft"),
                ("differential_carrier_bearings", "left_rocker_pivot_shaft"),
                ("differential_carrier_bearings", "right_rocker_pivot_shaft"),
            })
            collision_pairs.update(LIMIT_CONTACT_PAIRS)
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
                (f"{side}_bogie", f"{side}_bogie_limit_bumpers"),
            })
        requirements.update(foreign_hardware_requirements)
        collision_pairs.update(chassis_hardware_pairs)
        collision_pairs.update(foreign_hardware_requirements)
        for angle in angles:
            result = occ_rover.solve("chassis", {
                "left_rocker_pivot": 0.0,
                "left_bogie_pivot": 0.0,
                "right_bogie_pivot": 0.0,
                joint: math.radians(float(angle)),
            })
            assert result.success, (joint, angle, result.errors)
            candidate_pairs = _broad_phase_candidates(
                local_corners, result.transforms,
                collision_pairs, requirements,
            )
            candidate_requirements = {
                pair: clearance for pair, clearance in requirements.items()
                if pair in candidate_pairs
            }
            needed_parts = {
                name for pair in candidate_pairs
                for name in pair
            }
            positioned = {
                name: occ_rover.get_part_geometry(name, positioned=True)
                for name in needed_parts
            }
            endpoint_contacts = set()
            if joint == "left_rocker_pivot" and abs(angle) == 18.0:
                endpoint_contacts.update({
                    canonical_pair("left_rocker",
                                   "left_rocker_limit_bumpers"),
                    canonical_pair("right_rocker",
                                   "right_rocker_limit_bumpers"),
                })
            elif joint.endswith("_bogie_pivot") and angle in (-35.0, 38.0):
                side = "left" if joint.startswith("left") else "right"
                endpoint_contacts.add(canonical_pair(
                    f"{side}_bogie", f"{side}_bogie_limit_bumpers",
                ))
            report = audit_positioned_breps(
                positioned,
                intended_contacts=_intended_contacts(
                    positioned, limit_contacts=endpoint_contacts,
                ),
                minimum_clearances=candidate_requirements,
                pairs=candidate_pairs,
            )
            assert report.success, (joint, angle, report)
            checked += 1
    assert checked >= 90


def test_rover_defines_separate_hub_or_shaft_geometry_for_contact_allowlist():
    source = EXAMPLE.read_text(encoding="utf-8")
    proposed = ("AXLE_SHAFT", "WHEEL_SHAFT")

    assert any(f"command {name}(" in source for name in proposed)
