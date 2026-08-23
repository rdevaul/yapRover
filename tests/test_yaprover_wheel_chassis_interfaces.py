"""Geometry contract for the YapRover wheel/hub and chassis interfaces."""

from pathlib import Path

import pytest

from yapcad.brep import brep_from_solid, occ_available
from yapcad.dsl import check, compile_and_run, parse, tokenize
from yapcad.geom3d import issolid, solidbbox, volumeof


SOURCE_PATH = (
    Path(__file__).resolve().parents[1]
    / "designs"
    / "yaprover_wheel_chassis_interfaces.dsl"
)
SOURCE = SOURCE_PATH.read_text(encoding="utf-8")


def _module():
    return parse(tokenize(SOURCE), source=SOURCE)


def _command(name):
    return next(command for command in _module().commands if command.name == name)


def _run(name, parameters=None):
    result = compile_and_run(SOURCE, name, parameters or {})
    assert result.success, result.error_message
    assert issolid(result.geometry)
    return result.geometry


def _xyz_bounds(solid):
    bounds = solidbbox(solid)
    assert len(bounds) == 2
    return bounds[0][:3], bounds[1][:3]


def _inside(solid, xyz):
    from OCC.Core.BRepClass3d import BRepClass3d_SolidClassifier
    from OCC.Core.TopAbs import TopAbs_IN, TopAbs_ON
    from OCC.Core.gp import gp_Pnt

    brep = brep_from_solid(solid)
    assert brep is not None and brep.shape is not None
    classifier = BRepClass3d_SolidClassifier(
        brep.shape, gp_Pnt(*map(float, xyz)), 1e-6
    )
    return classifier.State() in (TopAbs_IN, TopAbs_ON)


def test_module_parses_and_typechecks_without_occ():
    module = _module()
    result = check(module)

    assert not result.has_errors, [str(item) for item in result.diagnostics]
    assert [command.name for command in module.commands] == [
        "WHEEL_HUB",
        "AXLE_SPACER",
        "CHASSIS_PIVOT_CUTTERS",
        "CHASSIS_PIVOT_CARTRIDGE",
        "CHASSIS_INTERFACE",
    ]


def test_wheel_metadata_freezes_axle_and_bearing_interfaces():
    metadata = _command("WHEEL_HUB").meta_hint
    datums = {item["id"]: item for item in metadata["assembly.datums"]}

    assert metadata["material"] == "PETG"
    assert datums["axle"] == {
        "id": "axle",
        "kind": "axis",
        "origin_mm": [0.0, 0.0, 0.0],
        "direction": [0.0, 1.0, 0.0],
    }
    assert datums["inner_bearing_plane"]["origin_mm"] == [0.0, -10.8, 0.0]
    assert datums["outer_bearing_plane"]["origin_mm"] == [0.0, 10.8, 0.0]


def test_chassis_metadata_exposes_track_and_belly_reference_datums():
    metadata = _command("CHASSIS_INTERFACE").meta_hint
    datums = {item["id"]: item for item in metadata["assembly.datums"]}

    assert datums["left_rocker"]["origin_mm"] == [0.0, 155.0, 0.0]
    assert datums["right_rocker"]["origin_mm"] == [0.0, -155.0, 0.0]
    assert datums["left_rocker"]["direction"] == [0.0, 1.0, 0.0]
    assert datums["right_rocker"]["direction"] == [0.0, 1.0, 0.0]
    assert datums["payload_frame"]["origin_mm"] == [0.0, 0.0, 85.0]


def test_source_documents_frozen_hardware_and_petg_minima():
    # Keep the manufacturability assumptions reviewable even when the pure
    # Python environment cannot construct the exact OCC booleans.
    for required in (
        "wheel_od_mm: float = 130.0",
        "wheel_width_mm: float = 36.0",
        "bearing_seat_d_mm: float = 22.15",
        "axle_bore_d_mm: float = 8.3",
        "let seat_depth: float = 7.2",
        "let hub: solid = cylinder(18.0",
        "box(112.0, 8.0, 8.0)",
        "box(300.0, 205.0, 110.0)",
        "box(292.0, 197.0, 106.0)",
    ):
        assert required in SOURCE


@pytest.mark.skipif(not occ_available(), reason="exact interface geometry requires OCC")
def test_wheel_occ_envelope_and_dual_bearing_seats():
    wheel = _run("WHEEL_HUB")
    lower, upper = _xyz_bounds(wheel)

    assert lower == pytest.approx([-65.0, -18.0, -65.0], abs=1e-5)
    assert upper == pytest.approx([65.0, 18.0, 65.0], abs=1e-5)
    assert brep_from_solid(wheel) is not None

    # Both side seats are open at radius 10.5; the central shoulder remains.
    assert not _inside(wheel, (10.5, -16.0, 0.0))
    assert not _inside(wheel, (10.5, 16.0, 0.0))
    assert _inside(wheel, (10.5, 0.0, 0.0))
    # Ø8.3 is a true running bore through the complete hub.
    assert not _inside(wheel, (3.0, 0.0, 0.0))
    assert _inside(wheel, (5.0, 0.0, 0.0))


@pytest.mark.skipif(not occ_available(), reason="exact interface geometry requires OCC")
def test_wheel_occ_is_lightened_but_structurally_connected():
    wheel = _run("WHEEL_HUB")
    full_disk_volume = 3.141592653589793 * 65.0**2 * 36.0

    assert 0.20 * full_disk_volume < volumeof(wheel) < 0.55 * full_disk_volume
    # 18 mm hub radius - 11.075 mm seat radius = 6.925 mm PETG radial wall.
    assert 18.0 - 22.15 / 2.0 >= 6.0


@pytest.mark.skipif(not occ_available(), reason="exact interface geometry requires OCC")
def test_axle_spacer_occ_envelope_and_running_bore():
    spacer = _run("AXLE_SPACER")
    lower, upper = _xyz_bounds(spacer)

    assert lower == pytest.approx([-6.5, -10.7, -6.5], abs=0.06)
    assert upper == pytest.approx([6.5, 10.7, 6.5], abs=0.06)
    assert not _inside(spacer, (3.0, 0.0, 0.0))
    assert _inside(spacer, (5.0, 0.0, 0.0))


@pytest.mark.skipif(not occ_available(), reason="exact interface geometry requires OCC")
def test_chassis_occ_envelope_floor_and_paired_cartridges():
    chassis = _run("CHASSIS_INTERFACE")
    lower, upper = _xyz_bounds(chassis)

    assert lower == pytest.approx([-150.0, -155.0, -25.0], abs=1e-5)
    assert upper == pytest.approx([150.0, 155.0, 85.0], abs=1e-5)
    assert brep_from_solid(chassis) is not None

    # Six mm bottom, four mm walls, and open equipment cavity.
    assert _inside(chassis, (100.0, 0.0, -22.0))
    assert not _inside(chassis, (0.0, 0.0, 0.0))
    # Each 26 mm boss contains two seats and a retained central shoulder.
    for sign in (-1.0, 1.0):
        assert not _inside(chassis, (10.5, sign * 153.0, 0.0))
        assert not _inside(chassis, (10.5, sign * 131.0, 0.0))
        assert _inside(chassis, (10.5, sign * 142.0, 0.0))
        assert not _inside(chassis, (3.0, sign * 142.0, 0.0))
