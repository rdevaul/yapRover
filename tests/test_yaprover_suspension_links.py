"""Geometry study tests for printable YapRover rocker and bogie links."""

from __future__ import annotations

from pathlib import Path

import numpy as np
import pytest

from yapcad.brep import has_brep_data, occ_available
from yapcad.dsl import compile_and_run
from yapcad.dsl.runtime.builtins import call_builtin
from yapcad.dsl.runtime.values import solid_val, string_val
from yapcad.geom import point
from yapcad.geom3d import issolid, solidbbox, translatesolid
from yapcad.io.step import write_step_analytic
from yaprover.kinematics.clearance import measure_brep_volume


SOURCE_PATH = (
    Path(__file__).resolve().parents[1]
    / "designs"
    / "yaprover_suspension_links.dsl"
)


@pytest.fixture(scope="module")
def source():
    return SOURCE_PATH.read_text(encoding="utf-8")


def _run(source, command):
    result = compile_and_run(source, command, {})
    assert result.success, result.error_message
    assert issolid(result.geometry)
    return result.geometry


def _bounds(solid):
    box = solidbbox(solid)
    assert box
    return np.asarray(box[0][:3]), np.asarray(box[1][:3])


def _extents(solid):
    low, high = _bounds(solid)
    return high - low


@pytest.mark.parametrize(
    "command",
    ["ROCKER_FRONT_BLANK", "ROCKER_REAR_BLANK", "BOGIE_LAYOUT_PROXY"],
)
def test_each_printed_component_fits_220_mm_bed(source, command):
    geometry = _run(source, command)

    # The large X/Z silhouette can be laid flat; Y is the 16 mm thickness.
    assert np.all(_extents(geometry) <= [220.001, 220.001, 220.001])


def test_split_rocker_components_are_separate_sixteen_mm_layers(source):
    front = _run(source, "ROCKER_FRONT_BLANK")
    rear = _run(source, "ROCKER_REAR_BLANK")
    front_low, front_high = _bounds(front)
    rear_low, rear_high = _bounds(rear)

    assert front_high[1] - front_low[1] == pytest.approx(16.0)
    assert rear_high[1] - rear_low[1] == pytest.approx(16.0)
    assert front_high[1] == pytest.approx(-0.5)
    assert rear_low[1] == pytest.approx(0.5)


def test_bogie_is_one_symmetric_16_mm_component(source):
    bogie = _run(source, "BOGIE_LAYOUT_PROXY")
    low, high = _bounds(bogie)

    assert high[0] - low[0] == pytest.approx(220.0, abs=1e-5)
    assert high[1] - low[1] == pytest.approx(16.0)
    assert low[0] == pytest.approx(-high[0], abs=1e-6)


@pytest.mark.parametrize(
    ("command", "expected"),
    [
        (
            "ROCKER_LAYOUT_PROXY",
            {
                "chassis_pivot": [0.0, 0.0, 0.0],
                "front_axle": [190.0, 0.0, -75.0],
                "bogie_pivot": [-95.0, 0.0, -35.0],
            },
        ),
        (
            "BOGIE_LAYOUT_PROXY",
            {
                "rocker_pivot": [0.0, 0.0, 0.0],
                "middle_axle": [95.0, 0.0, -40.0],
                "rear_axle": [-95.0, 0.0, -40.0],
            },
        ),
    ],
)
def test_annotations_preserve_required_axis_names_and_coordinates(
        source, command, expected):
    solid = _run(source, command)
    asm = call_builtin("assembly", [string_val("link_study")])
    call_builtin("add_part", [asm, solid_val(solid), string_val("link")])

    datums = asm.data.parts["link"].datums
    assert set(datums) == set(expected)
    for name, origin in expected.items():
        np.testing.assert_allclose(datums[name].origin[:3], origin)
        np.testing.assert_allclose(datums[name].direction[:3], [0.0, 1.0, 0.0])


def test_vectors_follow_the_required_suspension_layout(source):
    rocker = _run(source, "ROCKER_LAYOUT_PROXY")
    bogie = _run(source, "BOGIE_LAYOUT_PROXY")
    asm = call_builtin("assembly", [string_val("layout")])
    call_builtin("add_part", [asm, solid_val(rocker), string_val("rocker")])
    call_builtin("add_part", [asm, solid_val(bogie), string_val("bogie")])

    rocker_datums = asm.data.parts["rocker"].datums
    bogie_datums = asm.data.parts["bogie"].datums
    center = np.asarray(rocker_datums["chassis_pivot"].origin[:3])
    np.testing.assert_allclose(
        np.asarray(rocker_datums["front_axle"].origin[:3]) - center,
        [190.0, 0.0, -75.0],
    )
    np.testing.assert_allclose(
        np.asarray(rocker_datums["bogie_pivot"].origin[:3]) - center,
        [-95.0, 0.0, -35.0],
    )
    pivot = np.asarray(bogie_datums["rocker_pivot"].origin[:3])
    np.testing.assert_allclose(
        np.asarray(bogie_datums["middle_axle"].origin[:3]) - pivot,
        [95.0, 0.0, -40.0],
    )
    np.testing.assert_allclose(
        np.asarray(bogie_datums["rear_axle"].origin[:3]) - pivot,
        [-95.0, 0.0, -40.0],
    )


def test_recommended_lateral_offsets_clear_wheel_volumes(source):
    rocker = _run(source, "ROCKER_LAYOUT_PROXY")
    left_link = translatesolid(rocker, point(0.0, 55.0, 0.0))
    right_link = translatesolid(rocker, point(0.0, -55.0, 0.0))
    left_wheel = _run(source, "LEFT_WHEEL_CLEARANCE_PROXY")
    right_wheel = _run(source, "RIGHT_WHEEL_CLEARANCE_PROXY")

    _, left_link_high = _bounds(left_link)
    left_wheel_low, _ = _bounds(left_wheel)
    right_link_low, _ = _bounds(right_link)
    _, right_wheel_high = _bounds(right_wheel)
    assert left_wheel_low[1] - left_link_high[1] == pytest.approx(0.5)
    assert right_link_low[1] - right_wheel_high[1] == pytest.approx(0.5)


@pytest.mark.requires_occ
@pytest.mark.skipif(not occ_available(), reason="pythonocc-core is not available")
@pytest.mark.parametrize(
    "command",
    ["ROCKER_FRONT_COMPONENT", "ROCKER_REAR_COMPONENT", "BOGIE_FINISHED"],
)
def test_finished_links_keep_brep_fillet_bores_and_strict_step(
        tmp_path, source, command):
    blank_name = {
        "ROCKER_FRONT_COMPONENT": "ROCKER_FRONT_BLANK",
        "ROCKER_REAR_COMPONENT": "ROCKER_REAR_BLANK",
        "BOGIE_FINISHED": "BOGIE_LAYOUT_PROXY",
    }[command]
    blank = _run(source, blank_name)
    finished = _run(source, command)

    assert has_brep_data(finished)
    # Ø8.4 through-bores and 608 seats remove material from the boss blanks.
    assert 0.0 < measure_brep_volume(finished) < measure_brep_volume(blank)
    assert np.all(_extents(finished) <= [220.001, 220.001, 220.001])
    output = tmp_path / f"{command.lower()}.step"
    assert write_step_analytic(
        finished, str(output), fallback_to_faceted=False,
    ) is True
    assert output.exists() and output.stat().st_size > 0
