from __future__ import annotations

import importlib.util
from pathlib import Path

import numpy as np
import pytest

from yapcad.brep import has_brep_data, occ_available
from yapcad.dsl import compile_and_run
from yapcad.geom3d import solidbbox


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "designs" / "yaprover_fit_coupons.dsl"
TOOL = ROOT / "tools" / "build_fit_coupons.py"
COMMANDS = (
    "BEARING_608_FIT_COUPON",
    "AXLE_8MM_FIT_COUPON",
    "KEY_3MM_FIT_COUPON",
    "QUARTER_20_THREAD_FIT_COUPON",
)


pytestmark = [
    pytest.mark.requires_occ,
    pytest.mark.skipif(not occ_available(), reason="pythonocc-core is unavailable"),
]


@pytest.fixture(scope="module")
def source():
    return SOURCE.read_text(encoding="utf-8")


@pytest.mark.parametrize("command", COMMANDS)
def test_coupon_is_analytic_and_fits_a_220mm_bed(source, command):
    result = compile_and_run(source, command, {})
    assert result.success, result.error_message
    assert has_brep_data(result.geometry)
    lower, upper = solidbbox(result.geometry)
    extent = np.asarray(upper[:3]) - np.asarray(lower[:3])
    assert np.all(extent <= [220.0, 220.0, 250.0])


def test_coupon_source_contains_production_nominals_and_bracketing_sizes(source):
    for value in (
        "22.15", "8.30", "3.10",
        "21.95", "22.35", "8.00", "8.60", "3.00", "3.40",
        "6.60",
    ):
        assert value in source


def test_quarter_20_coupon_holes_are_readable_by_thread_plate_tool():
    spec = importlib.util.spec_from_file_location(
        "thread_plate", ROOT / "tools" / "thread_plate.py"
    )
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    assert module.parse_holes(str(SOURCE), "QUARTER_20_COUPON_HOLES") == [
        (-25.0, 0.0), (0.0, 0.0), (25.0, 0.0),
    ]
    deck = ROOT / "designs" / "yaprover_suspension_detailed.dsl"
    assert len(module.parse_holes(str(deck))) == 42


@pytest.mark.expensive_geometry
def test_coupon_builder_writes_strict_stl_and_step(tmp_path):
    spec = importlib.util.spec_from_file_location("build_fit_coupons", TOOL)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    files = module.build(tmp_path)
    assert len(files) == 2 * len(module.COUPONS)
    assert all(path.stat().st_size > 0 for path in files)
    assert {path.suffix for path in files} == {".stl", ".step"}
