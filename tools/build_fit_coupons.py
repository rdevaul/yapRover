#!/usr/bin/env python3
"""Build strict STL and analytic STEP artifacts for rover fit coupons."""

from __future__ import annotations

import argparse
from pathlib import Path
import sys

from yapcad.brep import has_brep_data
from yapcad.dsl import compile_and_run
from yapcad.io import write_stl_brep
from yapcad.io.step import write_step_analytic


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "designs" / "yaprover_fit_coupons.dsl"
DEFAULT_OUTPUT = ROOT / "build" / "fit-coupons"
COUPONS = {
    "bearing-608-fit": "BEARING_608_FIT_COUPON",
    "axle-8mm-fit": "AXLE_8MM_FIT_COUPON",
    "key-2mm-fit": "KEY_2MM_FIT_COUPON",
    "tpu-bumper-socket-fit": "TPU_BUMPER_SOCKET_FIT_COUPON",
    "tpu-bumper-test-stems": "TPU_BUMPER_TEST_STEMS",
}


def build(output: Path, *, force: bool = False) -> list[Path]:
    source = SOURCE.read_text(encoding="utf-8")
    output.mkdir(parents=True, exist_ok=True)
    targets = [
        output / f"{name}.{suffix}"
        for name in COUPONS for suffix in ("stl", "step")
    ]
    existing = [path for path in targets if path.exists()]
    if existing and not force:
        raise FileExistsError(
            f"{existing[0]} exists; pass --force to replace coupon artifacts"
        )

    written: list[Path] = []
    for name, command in COUPONS.items():
        result = compile_and_run(source, command, {})
        if not result.success:
            raise RuntimeError(f"{command} failed: {result.error_message}")
        solid = result.geometry
        if not has_brep_data(solid):
            raise RuntimeError(f"{command} did not preserve analytic BREP")
        stl = output / f"{name}.stl"
        step = output / f"{name}.step"
        write_stl_brep(
            solid, str(stl), fallback_to_mesh=False, validate_watertight=True
        )
        analytic = write_step_analytic(
            solid, str(step), name=name, fallback_to_faceted=False
        )
        if not analytic:
            raise RuntimeError(f"{command} used a faceted STEP fallback")
        written.extend((stl, step))
    return written


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--force", action="store_true")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    try:
        written = build(args.output, force=args.force)
    except (OSError, RuntimeError, FileExistsError) as error:
        print(f"Fit-coupon generation failed: {error}", file=sys.stderr)
        return 1
    print(f"Created {len(written)} files in {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
