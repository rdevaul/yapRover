from __future__ import annotations

import csv
import importlib.util
import json
from pathlib import Path

import pytest


ROOT = Path(__file__).resolve().parents[1]
TOOL = ROOT / "tools" / "build_purchase_bom.py"
CATALOG = ROOT / "bom" / "prototype-v0.1.json"


def _tool_module():
    spec = importlib.util.spec_from_file_location("build_purchase_bom", TOOL)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


def _fake_package(tmp_path: Path) -> Path:
    package = tmp_path / "rover.ycpkg"
    metadata = package / "metadata"
    metadata.mkdir(parents=True)
    catalog = json.loads(CATALOG.read_text(encoding="utf-8"))
    components = {
        component
        for line in catalog["purchaseLines"]
        for component in line.get("componentFactors", {})
    }
    components.update(
        component
        for stock in catalog["stockLines"]
        for component in stock.get("cuts", {})
    )
    components.update(
        component
        for stock in catalog["stockLines"]
        for component in stock.get("componentIds", [])
    )
    quantities = {component: 1 for component in components}
    quantities.update({
        "bearing_608_wheel_pair": 6,
        "right_front_bearings": 2,
        "right_middle_bearings": 2,
        "right_rear_bearings": 2,
        "left_chassis_pivot_bearings": 2,
        "right_chassis_pivot_bearings": 2,
        "left_bogie_pivot_bearings": 2,
        "right_bogie_pivot_bearings": 2,
        "differential_carrier_bearings": 2,
        "bogie_wheel_axle_m8x65_low_head": 2,
        "bogie_wheel_axle_m8x65_low_head_right": 2,
        "wheel_axle_retention_m8": 3,
        "wheel_axle_retention_m8_right": 3,
        "differential_cradle_fasteners": 4,
        "differential_planet_thrust_washers": 2,
        "bogie_wheel_spacer_4p4mm": 2,
        "bogie_wheel_spacer_4p4mm_right": 2,
    })
    payload = {
        "schema": "yapcad-bom-v0.1",
        "items": [
            {"component": component, "quantity": quantity}
            for component, quantity in sorted(quantities.items())
        ],
    }
    (metadata / "bom.json").write_text(json.dumps(payload), encoding="utf-8")
    return package


def test_catalog_maps_every_nonfixed_line_to_package_components():
    catalog = json.loads(CATALOG.read_text(encoding="utf-8"))
    ids = [line["id"] for line in catalog["purchaseLines"]]
    assert len(ids) == len(set(ids))
    assert all(
        line.get("componentFactors") or line.get("fixedRequired")
        for line in catalog["purchaseLines"]
    )


def test_generator_aggregates_bearings_and_rounds_to_supplier_packs(tmp_path):
    output = tmp_path / "out"
    purchase, cuts = _tool_module().generate(_fake_package(tmp_path), CATALOG, output)
    rows = {row["id"]: row for row in csv.DictReader(purchase.open())}

    assert rows["BRG-608-2RS"]["required"] == "22"
    assert rows["BRG-608-2RS"]["order_quantity"] == "24"
    assert rows["NUT-M8-NYLOC-LOW"]["required"] == "10"
    assert rows["NUT-M8-NYLOC-LOW"]["order_quantity"] == "15"
    assert rows["FIL-PETG"]["order_quantity"] == "3"
    assert cuts.is_file()


def test_cut_list_uses_actual_component_multiplicity(tmp_path):
    _, cuts = _tool_module().generate(
        _fake_package(tmp_path), CATALOG, tmp_path / "out"
    )
    rows = list(csv.DictReader(cuts.open()))
    short_spacers = [
        row for row in rows
        if row["stock_id"] == "STOCK-SPACER-13X8P3"
        and row["finished_length_mm"] == "4.4"
    ]
    assert sum(int(row["quantity"]) for row in short_spacers) == 4
    keys = [row for row in rows if row["stock_id"] == "STOCK-KEY-2MM"]
    assert sorted(float(row["finished_length_mm"]) for row in keys) == [8.5, 8.5, 12.5, 12.5]


def test_generator_rejects_undersized_stock_length(tmp_path):
    catalog = json.loads(CATALOG.read_text(encoding="utf-8"))
    catalog["stockLines"][0]["orderLengthMm"] = 100
    bad = tmp_path / "catalog.json"
    bad.write_text(json.dumps(catalog), encoding="utf-8")
    with pytest.raises(ValueError, match="only 100 mm"):
        _tool_module().generate(_fake_package(tmp_path), bad, tmp_path / "out")
