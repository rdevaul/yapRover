#!/usr/bin/env python3
"""Build and validate the YapRover assembly package."""

from __future__ import annotations

import argparse
import math
from importlib.metadata import PackageNotFoundError, version as package_version
from pathlib import Path
import sys

from yapcad.dsl.packaging import package_from_dsl
from yapcad.package import validate_package


REPOSITORY_ROOT = Path(__file__).resolve().parents[1]
DSL_SOURCE = REPOSITORY_ROOT / "designs" / "yaprover_suspension_detailed.dsl"


def _default_version() -> str:
    try:
        return package_version("yapRover")
    except PackageNotFoundError:
        return "0.1.0"


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Build the solved YapRover assembly as a .ycpkg directory."
    )
    parser.add_argument("--version", default=_default_version())
    parser.add_argument(
        "--output",
        type=Path,
        help="Output directory (default: build/yaprover-<version>.ycpkg)",
    )
    parser.add_argument(
        "--rocker-angle-deg",
        type=float,
        default=0.0,
        help="Left rocker preview angle in degrees (default: 0)",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Overwrite files in an existing package directory",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    output = args.output or (
        REPOSITORY_ROOT / "build" / f"yaprover-{args.version}.ycpkg"
    )
    if not output.is_absolute():
        output = Path.cwd() / output

    result = package_from_dsl(
        DSL_SOURCE.read_text(encoding="utf-8"),
        "BUILD_DETAILED_SUSPENSION",
        {"rocker_angle": math.radians(args.rocker_angle_deg)},
        output,
        name="yaprover",
        version=args.version,
        description="YapRover printable rocker-bogie prototype",
        overwrite=args.force,
    )
    if not result.success:
        print(f"Package generation failed: {result.error_message}", file=sys.stderr)
        return 1

    ok, messages = validate_package(result.manifest.root, strict=True)
    if not ok:
        for message in messages:
            print(message, file=sys.stderr)
        return 1

    warnings = [message for message in messages if message.startswith("WARNING:")]
    for message in messages:
        if message.startswith("OK:"):
            print(message)
    if warnings:
        print(
            f"Validation reported {len(warnings)} known metadata warnings; "
            "see the package-generation notes in README.md.",
            file=sys.stderr,
        )

    manifest = result.manifest.data
    print(
        f"Created {result.manifest.root} "
        f"({len(manifest.get('components', []))} components, "
        f"{len(manifest.get('instances', []))} instances)"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
