"""OCC acceptance tests for the detailed YapRover suspension geometry."""

from __future__ import annotations

import math
from pathlib import Path

import numpy as np
import pytest

from yapcad.brep import has_brep_data, occ_available
from yapcad.dsl import compile_and_run
from yapcad.dsl.runtime.builtins import call_builtin
from yapcad.dsl.runtime.values import float_val, list_val, solid_val, string_val
from yapcad.dsl.types import FLOAT, STRING
from yapcad.geom3d import issolid, solidbbox
from yapcad.io.step import write_step_analytic
from yaprover.kinematics.clearance import (
    audit_positioned_breps,
    canonical_pair,
    measure_brep_volume,
)

from test_yaprover_suspension import MATES, _add_named_mate


EXAMPLE = (
    Path(__file__).resolve().parents[1]
    / "designs"
    / "yaprover_suspension_detailed.dsl"
)
PART_INSTANCES = (
    ("CHASSIS_FINISHED", "chassis"),
    ("LEFT_ROCKER", "left_rocker"),
    ("RIGHT_ROCKER", "right_rocker"),
    ("LEFT_BOGIE", "left_bogie"),
    ("RIGHT_BOGIE", "right_bogie"),
    ("LEFT_WHEEL", "left_front_wheel"),
    ("LEFT_WHEEL", "left_middle_wheel"),
    ("LEFT_WHEEL", "left_rear_wheel"),
    ("RIGHT_WHEEL", "right_front_wheel"),
    ("RIGHT_WHEEL", "right_middle_wheel"),
    ("RIGHT_WHEEL", "right_rear_wheel"),
    ("LEFT_FRONT_AXLE", "left_front_shaft"),
    ("LEFT_BOGIE_AXLE", "left_middle_shaft"),
    ("LEFT_BOGIE_AXLE", "left_rear_shaft"),
    ("RIGHT_FRONT_AXLE", "right_front_shaft"),
    ("RIGHT_BOGIE_AXLE", "right_middle_shaft"),
    ("RIGHT_BOGIE_AXLE", "right_rear_shaft"),
    ("LEFT_WHEEL_BEARINGS", "left_front_bearings"),
    ("LEFT_WHEEL_BEARINGS", "left_middle_bearings"),
    ("LEFT_WHEEL_BEARINGS", "left_rear_bearings"),
    ("RIGHT_WHEEL_BEARINGS", "right_front_bearings"),
    ("RIGHT_WHEEL_BEARINGS", "right_middle_bearings"),
    ("RIGHT_WHEEL_BEARINGS", "right_rear_bearings"),
    ("LEFT_CHASSIS_PIVOT_BEARINGS", "left_chassis_pivot_bearings"),
    ("RIGHT_CHASSIS_PIVOT_BEARINGS", "right_chassis_pivot_bearings"),
    ("LEFT_BOGIE_PIVOT_BEARINGS", "left_bogie_pivot_bearings"),
    ("RIGHT_BOGIE_PIVOT_BEARINGS", "right_bogie_pivot_bearings"),
    ("LEFT_ROCKER_PIVOT_SHAFT", "left_rocker_pivot_shaft"),
    ("RIGHT_ROCKER_PIVOT_SHAFT", "right_rocker_pivot_shaft"),
    ("LEFT_BOGIE_PIVOT_SHAFT", "left_bogie_pivot_shaft"),
    ("RIGHT_BOGIE_PIVOT_SHAFT", "right_bogie_pivot_shaft"),
    ("LEFT_DIFFERENTIAL_SIDE_GEAR", "left_differential_side_gear"),
    ("RIGHT_DIFFERENTIAL_SIDE_GEAR", "right_differential_side_gear"),
    ("DIFFERENTIAL_PLANET_PAIR", "differential_planet_pair"),
    ("DIFFERENTIAL_CARRIER_BEARINGS", "differential_carrier_bearings"),
    ("DIFFERENTIAL_CROSS_PIN", "differential_cross_pin"),
)
WHEELS = tuple(name for _, name in PART_INSTANCES if name.endswith("_wheel"))
PRINTED_STRUCTURE = (
    "chassis", "left_rocker", "right_rocker", "left_bogie", "right_bogie",
)
HARDWARE_MATES = (
    ("left_front_shaft_mount", "left_rocker", "left_front_shaft",
     "front_axle", "axle"),
    ("left_middle_shaft_mount", "left_bogie", "left_middle_shaft",
     "middle_axle", "axle"),
    ("left_rear_shaft_mount", "left_bogie", "left_rear_shaft",
     "rear_axle", "axle"),
    ("right_front_shaft_mount", "right_rocker", "right_front_shaft",
     "front_axle", "axle"),
    ("right_middle_shaft_mount", "right_bogie", "right_middle_shaft",
     "middle_axle", "axle"),
    ("right_rear_shaft_mount", "right_bogie", "right_rear_shaft",
     "rear_axle", "axle"),
    ("left_front_bearing_mount", "left_front_wheel", "left_front_bearings",
     "axle", "axle"),
    ("left_middle_bearing_mount", "left_middle_wheel", "left_middle_bearings",
     "axle", "axle"),
    ("left_rear_bearing_mount", "left_rear_wheel", "left_rear_bearings",
     "axle", "axle"),
    ("right_front_bearing_mount", "right_front_wheel", "right_front_bearings",
     "axle", "axle"),
    ("right_middle_bearing_mount", "right_middle_wheel", "right_middle_bearings",
     "axle", "axle"),
    ("right_rear_bearing_mount", "right_rear_wheel", "right_rear_bearings",
     "axle", "axle"),
    ("left_chassis_bearing_mount", "chassis", "left_chassis_pivot_bearings",
     "left_rocker", "axle"),
    ("right_chassis_bearing_mount", "chassis", "right_chassis_pivot_bearings",
     "right_rocker", "axle"),
    ("left_bogie_bearing_mount", "left_bogie", "left_bogie_pivot_bearings",
     "rocker_pivot", "axle"),
    ("right_bogie_bearing_mount", "right_bogie", "right_bogie_pivot_bearings",
     "rocker_pivot", "axle"),
    ("left_rocker_shaft_mount", "left_rocker", "left_rocker_pivot_shaft",
     "chassis_pivot", "axle"),
    ("right_rocker_shaft_mount", "right_rocker", "right_rocker_pivot_shaft",
     "chassis_pivot", "axle"),
    ("left_bogie_shaft_mount", "left_rocker", "left_bogie_pivot_shaft",
     "bogie_pivot", "axle"),
    ("right_bogie_shaft_mount", "right_rocker", "right_bogie_pivot_shaft",
     "bogie_pivot", "axle"),
    ("left_side_gear_mount", "left_rocker", "left_differential_side_gear",
     "chassis_pivot", "axis"),
    ("right_side_gear_mount", "right_rocker", "right_differential_side_gear",
     "chassis_pivot", "axis"),
    ("differential_bearing_mount", "chassis",
     "differential_carrier_bearings", "differential_axis", "axis"),
    ("differential_cross_pin_mount", "chassis", "differential_cross_pin",
     "planet_axis", "axis"),
)


pytestmark = [
    pytest.mark.requires_occ,
    pytest.mark.skipif(not occ_available(), reason="pythonocc-core is unavailable"),
]


@pytest.fixture(scope="module")
def source():
    return EXAMPLE.read_text(encoding="utf-8")


def _compile(source, command, args=None):
    result = compile_and_run(source, command, args or {})
    assert result.success, result.error_message
    assert issolid(result.geometry)
    assert has_brep_data(result.geometry)
    return result.geometry


@pytest.fixture(scope="module")
def detailed_solids(source):
    return {
        command: _compile(source, command)
        for command in dict.fromkeys(command for command, _ in PART_INSTANCES)
    }


def make_detailed_assembly(detailed_solids):
    asm = call_builtin("assembly", [string_val("yaprover_suspension_detailed")])
    for command, instance in PART_INSTANCES:
        call_builtin("add_part", [
            asm, solid_val(detailed_solids[command]), string_val(instance),
        ])
    for mate in MATES:
        _add_named_mate(asm, mate)
    for name, parent, child, parent_datum, child_datum in HARDWARE_MATES:
        call_builtin("add_named_mate", [
            asm, string_val(name), string_val("rigid"),
            string_val(parent), string_val(parent_datum),
            string_val(child), string_val(child_datum),
        ])
    call_builtin("add_named_mate", [
        asm, string_val("planet_pair_pivot"), string_val("revolute"),
        string_val("chassis"), string_val("planet_axis"),
        string_val("differential_planet_pair"), string_val("axis"),
    ])
    call_builtin("add_joint_coupling", [
        asm,
        string_val("rocker_differential"),
        string_val("right_rocker_pivot"),
        list_val([string_val("left_rocker_pivot")], STRING),
        list_val([float_val(-1.0)], FLOAT),
        float_val(0.0),
    ])
    call_builtin("add_joint_coupling", [
        asm,
        string_val("planet_differential"),
        string_val("planet_pair_pivot"),
        list_val([string_val("left_rocker_pivot")], STRING),
        list_val([float_val(-1.0)], FLOAT),
        float_val(0.0),
    ])
    for name, minimum, maximum in (
        ("left_rocker_pivot", -18.0, 18.0),
        ("right_rocker_pivot", -18.0, 18.0),
        ("left_bogie_pivot", -35.0, 38.0),
        ("right_bogie_pivot", -35.0, 38.0),
    ):
        call_builtin("set_mate_limits", [
            asm, string_val(name), float_val(math.radians(minimum)),
            float_val(math.radians(maximum)),
        ])
    return asm.data


def _extent(solid):
    bounds = solidbbox(solid)
    return np.asarray(bounds[1][:3]) - np.asarray(bounds[0][:3])


def test_every_printed_component_fits_220_mm_bed(source):
    components = {
        "rocker front": _compile(source, "ROCKER_FRONT_COMPONENT"),
        "rocker rear": _compile(source, "ROCKER_REAR_COMPONENT"),
        "bogie": _compile(source, "BOGIE_FINISHED", {"side": 1}),
        "wheel": _compile(source, "WHEEL_HUB"),
        "chassis tub": _compile(source, "CHASSIS_TUB"),
        "chassis front": _compile(source, "CHASSIS_FRONT_SEGMENT"),
        "chassis rear": _compile(source, "CHASSIS_REAR_SEGMENT"),
        "chassis interface": _compile(
            source, "CHASSIS_SIDE_INTERFACE", {"side": 1},
        ),
        "differential cradle": _compile(source, "DIFFERENTIAL_CRADLE"),
    }
    for name, solid in components.items():
        assert np.all(_extent(solid) <= [220.0, 220.0, 250.0]), (name, _extent(solid))


def test_detailed_geometry_retains_proven_datum_graph(detailed_solids):
    assembly = make_detailed_assembly(detailed_solids)
    result = assembly.solve("chassis", {"left_rocker_pivot": math.radians(12.0)})

    assert result.success, result.errors
    assert len(assembly.parts) == 36
    assert len(assembly.mates) == 35
    assert assembly._joint_values["right_rocker_pivot"] == pytest.approx(
        math.radians(-12.0)
    )
    assert assembly._joint_values["planet_pair_pivot"] == pytest.approx(
        math.radians(-12.0)
    )
    assert max(result.residuals.values()) <= 1e-8
    assert all(has_brep_data(solid) for solid in assembly.positioned_parts().values())


def test_metric_hardware_is_explicit_and_dimensionally_bounded(detailed_solids):
    assembly = make_detailed_assembly(detailed_solids)
    assert assembly.solve("chassis").success

    assert len([name for name in assembly.parts if name.endswith("_shaft")]) == 10
    assert len([name for name in assembly.parts if name.endswith("_bearings")]) == 11
    bearing_extent = _extent(detailed_solids["LEFT_WHEEL_BEARINGS"])
    np.testing.assert_allclose(bearing_extent[[0, 2]], [22.0, 21.839595], atol=0.02)
    assert bearing_extent[1] == pytest.approx(35.7, abs=0.02)
    for name, part in assembly.parts.items():
        if name.endswith(("_shaft", "_bearings")):
            datum = part.datums.get("axle") or part.datums["axis"]
            np.testing.assert_allclose(datum.direction[:3], [0, 1, 0])


def test_physical_differential_tracks_the_affine_joint_contract(detailed_solids):
    assembly = make_detailed_assembly(detailed_solids)
    angle = math.radians(12.0)
    result = assembly.solve("chassis", {"left_rocker_pivot": angle})

    assert result.success, result.errors
    assert assembly._joint_values["right_rocker_pivot"] == pytest.approx(-angle)
    assert assembly._joint_values["planet_pair_pivot"] == pytest.approx(-angle)
    assert {
        "left_differential_side_gear",
        "right_differential_side_gear",
        "differential_planet_pair",
        "differential_carrier_bearings",
        "differential_cross_pin",
    } <= set(assembly.parts)
    chassis = assembly.parts["chassis"]
    np.testing.assert_allclose(
        chassis.datums["differential_axis"].direction[:3], [0, 1, 0]
    )
    np.testing.assert_allclose(
        chassis.datums["planet_axis"].direction[:3], [1, 0, 0]
    )
    side_extent = _extent(detailed_solids["LEFT_DIFFERENTIAL_SIDE_GEAR"])
    assert np.all(side_extent <= [41.0, 9.0, 41.0])


def test_level_pose_has_five_mm_wheel_to_structure_clearance(detailed_solids):
    assembly = make_detailed_assembly(detailed_solids)
    assert assembly.solve("chassis").success
    positioned = assembly.positioned_parts()
    requirements = {
        canonical_pair(wheel, structure): 5.0
        for wheel in WHEELS for structure in PRINTED_STRUCTURE
    }
    report = audit_positioned_breps(
        positioned, minimum_clearances=requirements, pairs=requirements,
    )

    assert not report.collision_violations, report.collision_violations
    assert not report.clearance_violations, report.clearance_violations


def test_level_pose_moving_structure_has_no_positive_overlap(detailed_solids):
    assembly = make_detailed_assembly(detailed_solids)
    assert assembly.solve("chassis").success
    pairs = {
        canonical_pair("chassis", "left_rocker"),
        canonical_pair("chassis", "right_rocker"),
        canonical_pair("left_rocker", "left_bogie"),
        canonical_pair("right_rocker", "right_bogie"),
    }
    report = audit_positioned_breps(assembly.positioned_parts(), pairs=pairs)

    assert not report.collision_violations, report.collision_violations


def test_full_dsl_build_exports_strict_analytic_step(tmp_path, source):
    geometry = _compile(
        source, "BUILD_DETAILED_SUSPENSION",
        {"rocker_angle": math.radians(12.0)},
    )
    output = tmp_path / "yaprover_suspension_detailed.step"

    assert measure_brep_volume(geometry) > 0.0
    assert write_step_analytic(
        geometry, str(output), fallback_to_faceted=False,
    ) is True
    assert output.stat().st_size > 0
