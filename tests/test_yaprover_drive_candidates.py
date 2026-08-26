"""Acceptance tests for the optional powered-wheel architecture study."""

from pathlib import Path

import numpy as np
import pytest

from yapcad.brep import has_brep_data, occ_available
from yapcad.dsl import compile_and_run
from yapcad.geom3d import issolid, solidbbox
from yapcad.metadata import get_solid_metadata


EXAMPLE = Path(__file__).resolve().parents[1] / "designs" / "yaprover_drive_candidates.dsl"


pytestmark = [
    pytest.mark.requires_occ,
    pytest.mark.skipif(not occ_available(), reason="pythonocc-core is unavailable"),
]


@pytest.fixture(scope="module")
def source():
    return EXAMPLE.read_text(encoding="utf-8")


def _compile(source, command):
    result = compile_and_run(source, command, {})
    assert result.success, result.error_message
    assert issolid(result.geometry)
    assert has_brep_data(result.geometry)
    return result.geometry


def _extent(solid):
    bounds = solidbbox(solid)
    return np.asarray(bounds[1][:3]) - np.asarray(bounds[0][:3])


def test_candidate_motor_uses_published_25d_envelope_and_cots_metadata(source):
    motor = _compile(source, "POLOLU_25D_99_HP_ENVELOPE")
    np.testing.assert_allclose(_extent(motor), [25.0, 81.5, 25.0], atol=0.02)
    metadata = get_solid_metadata(motor, create=False)
    assert metadata["component"]["disposition"] == "buy"
    assert metadata["procurement"]["vendor"] == "Pololu"
    assert metadata["procurement"]["part_number"] == "4847"


def test_mount_and_supported_axle_are_separate_fabrication_classes(source):
    mount = _compile(source, "POLOLU_25D_SPLIT_CLAMP_MOUNT")
    axle = _compile(source, "POWERED_WHEEL_AXLE")
    assert get_solid_metadata(mount, create=False)["component"]["disposition"] == "make"
    assert get_solid_metadata(axle, create=False)["component"]["disposition"] == "raw_stock"
    assert np.all(_extent(mount) <= [220.0, 220.0, 250.0])
    assert _extent(axle)[1] == pytest.approx(80.0, abs=0.02)


def test_powered_cartridge_supports_axle_independently_of_motor(source):
    cartridge = _compile(source, "DRIVE_BEARING_CARTRIDGE")
    coupler = _compile(source, "DRIVE_COUPLER_4D_TO_8MM")
    cartridge_meta = get_solid_metadata(cartridge, create=False)
    coupler_meta = get_solid_metadata(coupler, create=False)
    assert cartridge_meta["component"]["disposition"] == "make"
    assert coupler_meta["component"]["disposition"] == "buy"
    assert _extent(cartridge)[1] == pytest.approx(26.0, abs=0.02)


def test_candidate_preview_is_analytic_brep(source):
    preview = _compile(source, "DRIVE_MODULE_CANDIDATE_PREVIEW")
    extent = _extent(preview)
    assert extent[0] == pytest.approx(130.0, abs=0.02)
    assert extent[2] == pytest.approx(130.0, abs=0.02)
    assert extent[1] < 160.0
