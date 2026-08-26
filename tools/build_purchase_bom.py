#!/usr/bin/env python3
"""Generate the prototype purchase BOM and cut list from a built .ycpkg."""

from __future__ import annotations

import argparse
import csv
import json
import math
from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_PACKAGE = ROOT / "build" / "yaprover-0.1.0.ycpkg"
DEFAULT_CATALOG = ROOT / "bom" / "prototype-v0.1.json"
DEFAULT_OUTPUT = ROOT / "build" / "procurement"


def _load(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def _engineering_quantities(package: Path) -> dict[str, float]:
    bom_path = package / "metadata" / "bom.json"
    if not bom_path.is_file():
        raise ValueError(f"package BOM not found: {bom_path}")
    data = _load(bom_path)
    if data.get("schema") != "yapcad-bom-v0.1":
        raise ValueError(f"unsupported package BOM schema: {data.get('schema')!r}")
    return {item["component"]: float(item["quantity"]) for item in data["items"]}


def _required(line: dict, quantities: dict[str, float]) -> float:
    if "fixedRequired" in line:
        return float(line["fixedRequired"])
    return sum(
        quantities.get(component, 0.0) * float(factor)
        for component, factor in line.get("componentFactors", {}).items()
    )


def _display_number(value: float) -> int | float:
    return int(value) if float(value).is_integer() else round(value, 3)


def generate(package: Path, catalog_path: Path, output: Path) -> tuple[Path, Path]:
    quantities = _engineering_quantities(package)
    catalog = _load(catalog_path)
    if catalog.get("schema") != "yaprover-procurement-v0.1":
        raise ValueError(f"unsupported procurement schema: {catalog.get('schema')!r}")
    output.mkdir(parents=True, exist_ok=True)

    purchase_path = output / "purchase-bom.csv"
    with purchase_path.open("w", newline="", encoding="utf-8") as stream:
        fields = [
            "line", "id", "description", "supplier", "sku", "required",
            "spares", "order_quantity", "unit", "pack_quantity", "url",
            "critical_dimensions",
        ]
        writer = csv.DictWriter(stream, fieldnames=fields, lineterminator="\n")
        writer.writeheader()
        for number, line in enumerate(catalog["purchaseLines"], start=1):
            required = _required(line, quantities)
            if required <= 0:
                missing = ", ".join(line.get("componentFactors", {}))
                raise ValueError(
                    f"purchase line {line['id']} has no package demand; mapped: {missing}"
                )
            spares = float(line.get("spares", 0))
            pack = int(line.get("packQuantity", 1))
            order_quantity = math.ceil((required + spares) / pack) * pack
            writer.writerow({
                "line": number,
                "id": line["id"],
                "description": line["description"],
                "supplier": line["supplier"],
                "sku": line["sku"],
                "required": _display_number(required),
                "spares": _display_number(spares),
                "order_quantity": order_quantity,
                "unit": line["unit"],
                "pack_quantity": pack,
                "url": line.get("url", ""),
                "critical_dimensions": line.get("criticalDimensions", ""),
            })

    cut_path = output / "cut-list.csv"
    with cut_path.open("w", newline="", encoding="utf-8") as stream:
        fields = [
            "stock_id", "supplier", "sku", "piece", "quantity",
            "finished_length_mm", "tolerance_mm", "process", "url",
        ]
        writer = csv.DictWriter(stream, fieldnames=fields, lineterminator="\n")
        writer.writeheader()
        for stock in catalog["stockLines"]:
            pieces: list[tuple[str, int, float]] = []
            for component, length in stock.get("cuts", {}).items():
                quantity = quantities.get(component, 0.0)
                if not quantity.is_integer() or quantity <= 0:
                    raise ValueError(
                        f"stock cut {stock['id']} maps invalid quantity {quantity} "
                        f"for {component}"
                    )
                pieces.append((component, int(quantity), float(length)))
            pattern = stock.get("piecePatternMm")
            if pattern:
                for component in stock.get("componentIds", []):
                    quantity = quantities.get(component, 0.0)
                    if not quantity.is_integer() or quantity <= 0:
                        raise ValueError(
                            f"stock pattern {stock['id']} maps invalid quantity "
                            f"{quantity} for {component}"
                        )
                    for index, length in enumerate(pattern, start=1):
                        pieces.append((f"{component}_{index}", int(quantity), float(length)))
            used = sum(quantity * length for _, quantity, length in pieces)
            cuts = sum(quantity for _, quantity, _ in pieces)
            required_stock = used + max(0, cuts - 1) * float(stock.get("kerfMm", 0))
            if required_stock > float(stock["orderLengthMm"]) + 1e-9:
                raise ValueError(
                    f"stock {stock['id']} needs {required_stock:.1f} mm but only "
                    f"{stock['orderLengthMm']} mm is specified"
                )
            for piece, quantity, length in pieces:
                writer.writerow({
                    "stock_id": stock["id"],
                    "supplier": stock["supplier"],
                    "sku": stock["sku"],
                    "piece": piece,
                    "quantity": quantity,
                    "finished_length_mm": _display_number(length),
                    "tolerance_mm": 0.1,
                    "process": "saw, deburr, face square",
                    "url": stock.get("url", ""),
                })
    return purchase_path, cut_path


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--package", type=Path, default=DEFAULT_PACKAGE)
    parser.add_argument("--catalog", type=Path, default=DEFAULT_CATALOG)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    try:
        purchase, cuts = generate(args.package, args.catalog, args.output)
    except (OSError, ValueError, KeyError, json.JSONDecodeError) as error:
        print(f"BOM generation failed: {error}", file=sys.stderr)
        return 1
    print(f"Created {purchase}")
    print(f"Created {cuts}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
