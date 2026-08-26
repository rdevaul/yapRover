"""OCC acceptance tests for the detailed YapRover suspension geometry."""

from __future__ import annotations

import math
from collections import Counter
from pathlib import Path

import numpy as np
import pytest

from yapcad.brep import has_brep_data, occ_available
from yapcad.dsl import compile_and_run
from yapcad.dsl.packaging import package_from_dsl
from yapcad.dsl.runtime.builtins import call_builtin
from yapcad.dsl.runtime.values import float_val, list_val, solid_val, string_val
from yapcad.dsl.types import FLOAT, STRING
from yapcad.geom3d import issolid, solidbbox
from yapcad.io.step import write_step_analytic
from yapcad.package import validate_package
from yaprover.kinematics.clearance import (
    audit_positioned_breps,
    canonical_pair,
    measure_brep_pair,
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
    ("LEFT_ROCKER_LIMIT_BUMPERS", "left_rocker_limit_bumpers"),
    ("RIGHT_ROCKER_LIMIT_BUMPERS", "right_rocker_limit_bumpers"),
    ("LEFT_BOGIE_LIMIT_BUMPERS", "left_bogie_limit_bumpers"),
    ("RIGHT_BOGIE_LIMIT_BUMPERS", "right_bogie_limit_bumpers"),
    ("LEFT_WHEEL", "left_front_wheel"),
    ("LEFT_WHEEL", "left_middle_wheel"),
    ("LEFT_WHEEL", "left_rear_wheel"),
    ("RIGHT_WHEEL", "right_front_wheel"),
    ("RIGHT_WHEEL", "right_middle_wheel"),
    ("RIGHT_WHEEL", "right_rear_wheel"),
    ("LEFT_WHEEL_AXLE_SHAFT", "left_front_shaft"),
    ("LEFT_BOGIE_WHEEL_AXLE_SHAFT", "left_middle_shaft"),
    ("LEFT_BOGIE_WHEEL_AXLE_SHAFT", "left_rear_shaft"),
    ("RIGHT_WHEEL_AXLE_SHAFT", "right_front_shaft"),
    ("RIGHT_BOGIE_WHEEL_AXLE_SHAFT", "right_middle_shaft"),
    ("RIGHT_BOGIE_WHEEL_AXLE_SHAFT", "right_rear_shaft"),
    ("LEFT_WHEEL_AXLE_SPACER", "left_front_spacer"),
    ("LEFT_BOGIE_WHEEL_AXLE_SPACER", "left_middle_spacer"),
    ("LEFT_BOGIE_WHEEL_AXLE_SPACER", "left_rear_spacer"),
    ("RIGHT_WHEEL_AXLE_SPACER", "right_front_spacer"),
    ("RIGHT_BOGIE_WHEEL_AXLE_SPACER", "right_middle_spacer"),
    ("RIGHT_BOGIE_WHEEL_AXLE_SPACER", "right_rear_spacer"),
    ("LEFT_WHEEL_AXLE_HARDWARE", "left_front_axle_hardware"),
    ("LEFT_WHEEL_AXLE_HARDWARE", "left_middle_axle_hardware"),
    ("LEFT_WHEEL_AXLE_HARDWARE", "left_rear_axle_hardware"),
    ("RIGHT_WHEEL_AXLE_HARDWARE", "right_front_axle_hardware"),
    ("RIGHT_WHEEL_AXLE_HARDWARE", "right_middle_axle_hardware"),
    ("RIGHT_WHEEL_AXLE_HARDWARE", "right_rear_axle_hardware"),
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
    ("LEFT_ROCKER_PIVOT_KEYS", "left_rocker_pivot_keys"),
    ("RIGHT_ROCKER_PIVOT_KEYS", "right_rocker_pivot_keys"),
    ("LEFT_ROCKER_PIVOT_HARDWARE", "left_rocker_pivot_hardware"),
    ("RIGHT_ROCKER_PIVOT_HARDWARE", "right_rocker_pivot_hardware"),
    ("LEFT_BOGIE_PIVOT_SHAFT", "left_bogie_pivot_shaft"),
    ("RIGHT_BOGIE_PIVOT_SHAFT", "right_bogie_pivot_shaft"),
    ("LEFT_BOGIE_PIVOT_HARDWARE", "left_bogie_pivot_hardware"),
    ("RIGHT_BOGIE_PIVOT_HARDWARE", "right_bogie_pivot_hardware"),
    ("LEFT_DIFFERENTIAL_SIDE_GEAR", "left_differential_side_gear"),
    ("RIGHT_DIFFERENTIAL_SIDE_GEAR", "right_differential_side_gear"),
    ("FRONT_DIFFERENTIAL_PLANET_GEAR", "front_differential_planet_gear"),
    ("REAR_DIFFERENTIAL_PLANET_GEAR", "rear_differential_planet_gear"),
    ("DIFFERENTIAL_CRADLE_FINISHED", "differential_cradle"),
    ("DIFFERENTIAL_CRADLE_FASTENERS", "differential_cradle_fasteners"),
    ("DIFFERENTIAL_CARRIER_BEARINGS", "differential_carrier_bearings"),
    ("DIFFERENTIAL_CROSS_PIN", "differential_cross_pin"),
    ("DIFFERENTIAL_PLANET_THRUST_WASHERS",
     "differential_planet_thrust_washers"),
)
WHEELS = tuple(name for _, name in PART_INSTANCES if name.endswith("_wheel"))
PRINTED_STRUCTURE = (
    "chassis", "left_rocker", "right_rocker", "left_bogie", "right_bogie",
)
DIFFERENTIAL_MESHES = tuple(
    (f"{position}_differential_planet_gear", f"{side}_differential_side_gear")
    for position in ("front", "rear") for side in ("left", "right")
)
HARDWARE_MATES = (
    ("left_rocker_limit_bumper_mount", "chassis",
     "left_rocker_limit_bumpers", "left_rocker", "joint_axis"),
    ("right_rocker_limit_bumper_mount", "chassis",
     "right_rocker_limit_bumpers", "right_rocker", "joint_axis"),
    ("left_bogie_limit_bumper_mount", "left_rocker",
     "left_bogie_limit_bumpers", "bogie_pivot", "joint_axis"),
    ("right_bogie_limit_bumper_mount", "right_rocker",
     "right_bogie_limit_bumpers", "bogie_pivot", "joint_axis"),
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
    ("left_front_spacer_mount", "left_rocker", "left_front_spacer",
     "front_axle", "axle"),
    ("left_middle_spacer_mount", "left_bogie", "left_middle_spacer",
     "middle_axle", "axle"),
    ("left_rear_spacer_mount", "left_bogie", "left_rear_spacer",
     "rear_axle", "axle"),
    ("right_front_spacer_mount", "right_rocker", "right_front_spacer",
     "front_axle", "axle"),
    ("right_middle_spacer_mount", "right_bogie", "right_middle_spacer",
     "middle_axle", "axle"),
    ("right_rear_spacer_mount", "right_bogie", "right_rear_spacer",
     "rear_axle", "axle"),
    ("left_front_axle_hardware_mount", "left_rocker",
     "left_front_axle_hardware", "front_axle", "axle"),
    ("left_middle_axle_hardware_mount", "left_bogie",
     "left_middle_axle_hardware", "middle_axle", "axle"),
    ("left_rear_axle_hardware_mount", "left_bogie",
     "left_rear_axle_hardware", "rear_axle", "axle"),
    ("right_front_axle_hardware_mount", "right_rocker",
     "right_front_axle_hardware", "front_axle", "axle"),
    ("right_middle_axle_hardware_mount", "right_bogie",
     "right_middle_axle_hardware", "middle_axle", "axle"),
    ("right_rear_axle_hardware_mount", "right_bogie",
     "right_rear_axle_hardware", "rear_axle", "axle"),
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
    ("left_rocker_key_mount", "left_rocker", "left_rocker_pivot_keys",
     "chassis_pivot", "axle"),
    ("right_rocker_key_mount", "right_rocker", "right_rocker_pivot_keys",
     "chassis_pivot", "axle"),
    ("left_rocker_hardware_mount", "left_rocker",
     "left_rocker_pivot_hardware", "chassis_pivot", "axle"),
    ("right_rocker_hardware_mount", "right_rocker",
     "right_rocker_pivot_hardware", "chassis_pivot", "axle"),
    ("left_bogie_shaft_mount", "left_rocker", "left_bogie_pivot_shaft",
     "bogie_pivot", "axle"),
    ("right_bogie_shaft_mount", "right_rocker", "right_bogie_pivot_shaft",
     "bogie_pivot", "axle"),
    ("left_bogie_hardware_mount", "left_rocker",
     "left_bogie_pivot_hardware", "bogie_pivot", "axle"),
    ("right_bogie_hardware_mount", "right_rocker",
     "right_bogie_pivot_hardware", "bogie_pivot", "axle"),
    ("left_side_gear_mount", "left_rocker", "left_differential_side_gear",
     "chassis_pivot", "axis"),
    ("right_side_gear_mount", "right_rocker", "right_differential_side_gear",
     "chassis_pivot", "axis"),
    ("differential_cradle_mount", "chassis", "differential_cradle",
     "differential_mount", "mount"),
    ("differential_fastener_mount", "differential_cradle",
     "differential_cradle_fasteners", "mount", "mount"),
    ("differential_bearing_mount", "differential_cradle",
     "differential_carrier_bearings", "differential_axis", "axis"),
    ("differential_cross_pin_mount", "differential_cradle",
     "differential_cross_pin",
     "planet_axis", "axis"),
    ("differential_thrust_washer_mount", "differential_cradle",
     "differential_planet_thrust_washers", "planet_axis", "axis"),
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


def make_detailed_assembly(detailed_solids, *, couple_planets=True):
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
    for position in ("front", "rear"):
        call_builtin("add_named_mate", [
            asm, string_val(f"{position}_planet_pivot"),
            string_val("revolute"), string_val("differential_cross_pin"),
            string_val("axis"),
            string_val(f"{position}_differential_planet_gear"),
            string_val("axis"),
        ])
    call_builtin("add_joint_coupling", [
        asm,
        string_val("rocker_differential"),
        string_val("right_rocker_pivot"),
        list_val([string_val("left_rocker_pivot")], STRING),
        list_val([float_val(-1.0)], FLOAT),
        float_val(0.0),
    ])
    if couple_planets:
        for position, coefficient in (("front", -1.0), ("rear", 1.0)):
            call_builtin("add_joint_coupling", [
                asm,
                string_val(f"{position}_planet_differential"),
                string_val(f"{position}_planet_pivot"),
                list_val([string_val("left_rocker_pivot")], STRING),
                list_val([float_val(coefficient)], FLOAT),
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


@pytest.mark.expensive_geometry
def test_split_rocker_halves_share_one_band_without_intersection(source):
    front = _compile(source, "ROCKER_FRONT_COMPONENT")
    rear = _compile(source, "ROCKER_REAR_COMPONENT")
    measurement = measure_brep_pair("rocker_front", front, "rocker_rear", rear)

    assert measurement.intersection_volume <= 1e-7
    assert measurement.clearance <= 0.05


def test_detailed_geometry_retains_proven_datum_graph(detailed_solids):
    assembly = make_detailed_assembly(detailed_solids)
    result = assembly.solve("chassis", {"left_rocker_pivot": math.radians(12.0)})

    assert result.success, result.errors
    assert len(assembly.parts) == 62
    assert len(assembly.mates) == 61
    assert assembly._joint_values["right_rocker_pivot"] == pytest.approx(
        math.radians(-12.0)
    )
    assert assembly._joint_values["front_planet_pivot"] == pytest.approx(
        math.radians(-12.0)
    )
    assert assembly._joint_values["rear_planet_pivot"] == pytest.approx(
        math.radians(12.0)
    )
    assert max(result.residuals.values()) <= 1e-8
    assert all(has_brep_data(solid) for solid in assembly.positioned_parts().values())


def test_metric_hardware_is_explicit_and_dimensionally_bounded(detailed_solids):
    assembly = make_detailed_assembly(detailed_solids)
    assert assembly.solve("chassis").success

    assert len([name for name in assembly.parts if name.endswith("_shaft")]) == 10
    assert len([name for name in assembly.parts if name.endswith("_bearings")]) == 11
    assert len([name for name in assembly.parts if name.endswith("_spacer")]) == 6
    assert len([name for name in assembly.parts if name.endswith("_hardware")]) == 10
    bearing_extent = _extent(detailed_solids["LEFT_WHEEL_BEARINGS"])
    np.testing.assert_allclose(bearing_extent[[0, 2]], [22.0, 21.839595], atol=0.02)
    assert bearing_extent[1] == pytest.approx(35.7, abs=0.02)
    for name, part in assembly.parts.items():
        if name.endswith(("_shaft", "_bearings")):
            datum = part.datums.get("axle") or part.datums["axis"]
            np.testing.assert_allclose(datum.direction[:3], [0, 1, 0])


def test_tightened_lateral_stack_restores_310_mm_track(detailed_solids):
    assembly = make_detailed_assembly(detailed_solids)
    assert assembly.solve("chassis").success
    positioned = assembly.positioned_parts()

    left_bounds = solidbbox(positioned["left_front_wheel"])
    right_bounds = solidbbox(positioned["right_front_wheel"])
    left_center = (left_bounds[0][1] + left_bounds[1][1]) / 2.0
    right_center = (right_bounds[0][1] + right_bounds[1][1]) / 2.0
    assert left_center == pytest.approx(155.0, abs=0.02)
    assert right_center == pytest.approx(-155.0, abs=0.02)
    assert left_center - right_center == pytest.approx(310.0, abs=0.02)

    shaft_extent = _extent(detailed_solids["LEFT_WHEEL_AXLE_SHAFT"])
    spacer_extent = _extent(detailed_solids["LEFT_WHEEL_AXLE_SPACER"])
    bogie_shaft_extent = _extent(
        detailed_solids["LEFT_BOGIE_WHEEL_AXLE_SHAFT"]
    )
    bogie_spacer_extent = _extent(
        detailed_solids["LEFT_BOGIE_WHEEL_AXLE_SPACER"]
    )
    assert shaft_extent[1] == pytest.approx(84.0, abs=0.02)
    assert spacer_extent[1] == pytest.approx(21.4, abs=0.02)
    assert bogie_shaft_extent[1] == pytest.approx(69.0, abs=0.02)
    assert bogie_spacer_extent[1] == pytest.approx(4.4, abs=0.02)

    shaft_bounds = solidbbox(detailed_solids["LEFT_WHEEL_AXLE_SHAFT"])
    hardware_bounds = solidbbox(detailed_solids["LEFT_WHEEL_AXLE_HARDWARE"])
    assert shaft_bounds[0][1] == pytest.approx(-56.0, abs=0.02)
    assert hardware_bounds[0][1] > 18.0


@pytest.mark.expensive_geometry
@pytest.mark.parametrize(
    ("joint", "angle_deg", "moving", "bumpers"),
    (
        ("left_rocker_pivot", -18.0, "left_rocker",
         "left_rocker_limit_bumpers"),
        ("left_rocker_pivot", 18.0, "left_rocker",
         "left_rocker_limit_bumpers"),
        ("left_bogie_pivot", -35.0, "left_bogie",
         "left_bogie_limit_bumpers"),
        ("left_bogie_pivot", 38.0, "left_bogie",
         "left_bogie_limit_bumpers"),
    ),
)
def test_replaceable_bumpers_meet_moving_tabs_at_joint_limits(
    detailed_solids, joint, angle_deg, moving, bumpers,
):
    assembly = make_detailed_assembly(detailed_solids)
    result = assembly.solve("chassis", {joint: math.radians(angle_deg)})
    assert result.success, result.errors
    positioned = assembly.positioned_parts()
    measurement = measure_brep_pair(
        moving, positioned[moving], bumpers, positioned[bumpers]
    )
    # The nominal endpoint intentionally preloads the flexible pad by a tiny
    # amount. It is well below one cubic millimetre for three of the four
    # limits and below two cubic millimetres at the asymmetric -35 degree
    # bogie stop; two degrees inside the range remains fully separated.
    assert 0.0 < measurement.intersection_volume <= 2.0
    assert measurement.clearance == pytest.approx(0.0, abs=1e-8)


def test_physical_differential_tracks_the_affine_joint_contract(detailed_solids):
    assembly = make_detailed_assembly(detailed_solids)
    angle = math.radians(12.0)
    result = assembly.solve("chassis", {"left_rocker_pivot": angle})

    assert result.success, result.errors
    assert assembly._joint_values["right_rocker_pivot"] == pytest.approx(-angle)
    assert assembly._joint_values["front_planet_pivot"] == pytest.approx(-angle)
    assert assembly._joint_values["rear_planet_pivot"] == pytest.approx(angle)
    assert {
        "left_differential_side_gear",
        "right_differential_side_gear",
        "front_differential_planet_gear",
        "rear_differential_planet_gear",
        "differential_cradle",
        "differential_cradle_fasteners",
        "differential_carrier_bearings",
        "differential_cross_pin",
        "differential_planet_thrust_washers",
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


def test_planet_gears_have_independent_running_joints(detailed_solids):
    assembly = make_detailed_assembly(detailed_solids, couple_planets=False)
    zero = assembly.solve("chassis")
    assert zero.success, zero.errors
    front_at_zero = zero.transforms["front_differential_planet_gear"].copy()
    rear_at_zero = zero.transforms["rear_differential_planet_gear"].copy()

    angle = math.radians(17.0)
    moved = assembly.solve("chassis", {"front_planet_pivot": angle})
    assert moved.success, moved.errors
    assert not np.allclose(
        moved.transforms["front_differential_planet_gear"], front_at_zero,
    )
    np.testing.assert_allclose(
        moved.transforms["rear_differential_planet_gear"], rear_at_zero,
        atol=1e-10,
    )
    assert assembly._joint_values["front_planet_pivot"] == pytest.approx(angle)
    assert assembly._joint_values["rear_planet_pivot"] == pytest.approx(0.0)


def test_planet_gears_use_plain_clearance_bores_on_fixed_cross_pin(
    detailed_solids,
):
    assembly = make_detailed_assembly(detailed_solids)
    mates = {mate.name: mate for mate in assembly.mates}
    assert mates["differential_cross_pin_mount"].mate_type.value == "rigid"
    for position in ("front", "rear"):
        mate = mates[f"{position}_planet_pivot"]
        assert mate.mate_type.value == "revolute"
        assert mate.part_a == "differential_cross_pin"
        gear = detailed_solids[f"{position.upper()}_DIFFERENTIAL_PLANET_GEAR"]
        extent = _extent(gear)
        assert np.all(extent <= [27.0, 41.0, 41.0])


def test_differential_is_a_removable_retained_cartridge(detailed_solids):
    assembly = make_detailed_assembly(detailed_solids)
    mates = {mate.name: mate for mate in assembly.mates}

    cradle_mount = mates["differential_cradle_mount"]
    assert cradle_mount.part_a == "chassis"
    assert cradle_mount.part_b == "differential_cradle"
    for name in (
        "differential_fastener_mount",
        "differential_bearing_mount",
        "differential_cross_pin_mount",
        "differential_thrust_washer_mount",
    ):
        assert mates[name].part_a == "differential_cradle"

    pin_extent = _extent(detailed_solids["DIFFERENTIAL_CROSS_PIN"])
    assert pin_extent[0] == pytest.approx(82.0, abs=0.02)
    washer_extent = _extent(
        detailed_solids["DIFFERENTIAL_PLANET_THRUST_WASHERS"]
    )
    np.testing.assert_allclose(washer_extent, [55.4, 16.0, 16.0], atol=0.15)


@pytest.mark.expensive_geometry
def test_planet_thrust_stack_has_controlled_axial_float(detailed_solids):
    assembly = make_detailed_assembly(detailed_solids)
    assert assembly.solve("chassis").success
    positioned = assembly.positioned_parts()
    washers = positioned["differential_planet_thrust_washers"]
    for position in ("front", "rear"):
        gear_name = f"{position}_differential_planet_gear"
        measurement = measure_brep_pair(
            gear_name, positioned[gear_name],
            "differential_planet_thrust_washers", washers,
        )
        assert measurement.intersection_volume <= 1e-7
        assert measurement.clearance == pytest.approx(0.2, abs=0.03)


@pytest.mark.expensive_geometry
def test_independent_planets_have_running_clearance_on_cross_pin(detailed_solids):
    assembly = make_detailed_assembly(detailed_solids)
    result = assembly.solve("chassis")
    assert result.success, result.errors
    positioned = assembly.positioned_parts()
    for position in ("front", "rear"):
        measurement = measure_brep_pair(
            "differential_cross_pin", positioned["differential_cross_pin"],
            f"{position}_differential_planet_gear",
            positioned[f"{position}_differential_planet_gear"],
        )
        assert measurement.intersection_volume <= 1e-7
        assert measurement.clearance == pytest.approx(0.25, abs=0.02)


@pytest.mark.expensive_geometry
def test_side_gears_clear_their_parallel_keys_and_rocker_shafts(
    detailed_solids,
):
    assembly = make_detailed_assembly(detailed_solids)
    result = assembly.solve("chassis")
    assert result.success, result.errors
    positioned = assembly.positioned_parts()
    for side in ("left", "right"):
        measurement = measure_brep_pair(
            f"{side}_rocker_pivot_shaft",
            positioned[f"{side}_rocker_pivot_shaft"],
            f"{side}_differential_side_gear",
            positioned[f"{side}_differential_side_gear"],
        )
        assert measurement.intersection_volume <= 1e-7


@pytest.mark.expensive_geometry
def test_all_four_miter_meshes_remain_phased_through_one_tooth_pitch(
    detailed_solids,
):
    assembly = make_detailed_assembly(detailed_solids)
    for angle_deg in (0.0, 3.75, 7.5, 11.25, 15.0):
        result = assembly.solve(
            "chassis", {"left_rocker_pivot": math.radians(angle_deg)},
        )
        assert result.success, result.errors
        positioned = assembly.positioned_parts()
        for planet, side in DIFFERENTIAL_MESHES:
            measurement = measure_brep_pair(
                planet, positioned[planet], side, positioned[side],
                intended_contact=True,
            )
            assert measurement.intersection_volume <= 1e-6, (
                angle_deg, planet, side, measurement,
            )
            assert measurement.clearance <= 0.30, (
                angle_deg, planet, side, measurement,
            )


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


@pytest.mark.expensive_geometry
def test_full_dsl_build_creates_valid_v02_product_package(tmp_path, source):
    result = package_from_dsl(
        source,
        "BUILD_DETAILED_SUSPENSION",
        {"rocker_angle": 0.0},
        tmp_path / "yaprover.ycpkg",
        name="yaprover",
        version="0.1.0",
    )

    assert result.success, result.error_message
    manifest = result.manifest
    assert manifest.data["schema"] == "ycpkg-spec-v0.2"
    assert len(manifest.data["instances"]) == 62
    assert len(manifest.data["components"]) <= 62
    components = {
        component["id"]: component for component in manifest.data["components"]
    }
    dispositions = Counter(
        components[instance["component"]]["disposition"]
        for instance in manifest.data["instances"]
    )
    assert dispositions == {"make": 20, "buy": 30, "raw_stock": 12}
    assert manifest.data["geometry"]["primary"]["schema"] == (
        "yapcad-geometry-json-v0.2"
    )
    assert all(
        component["geometry"]["schema"] == "yapcad-geometry-json-v0.2"
        for component in manifest.data["components"]
    )
    ok, messages = validate_package(manifest.root, strict=True)
    assert ok, messages
