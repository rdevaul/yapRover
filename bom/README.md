# Bill of materials

`prototype-v0.1.json` is the reviewed procurement overlay for the first passive
prototype. It maps engineering component quantities from a built `.ycpkg` to
orderable line items, adds spares, rounds orders to supplier pack sizes, and
defines cut patterns for raw stock.

From the repository root, first build the current package and then generate the
purchase and cut-list CSV files:

```bash
python tools/build_ycpkg.py --force
python tools/build_purchase_bom.py
```

Outputs are written to `build/procurement/purchase-bom.csv` and
`build/procurement/cut-list.csv`. To create a reviewable snapshot elsewhere,
pass `--output PATH`. The `generated/` directory is the checked-in snapshot
for prototype revision A; regenerate it with `--output bom/generated` whenever
the package or catalog changes. Alternate packages and catalogs can be selected
with `--package` and `--catalog`.

The generated quantities are mechanically derived, but sourcing still requires
human review. Before ordering, open each supplier drawing and verify every
critical dimension. The M8 x 65 and M8 x 80 low-head wheel axles intentionally
use manufacturer-neutral DIN 7984 specifications: confirm head envelope,
unthreaded bearing surface, thread runout, material class, and availability for
the actual product selected. Empty URLs and `CUSTOM` SKUs identify lines that
require fabrication or a supplier decision rather than one-click purchasing.

Do not substitute bearing-pocket, axle, key, or TPU-stem dimensions based only
on nominal catalog values. Run the [fit-coupon procedure](../docs/fit-coupons.md)
with the production printer and material first.
