# Bill of materials

`prototype-v0.2.json` (revision B) is the reviewed procurement overlay for the
v0.2 passive prototype. It maps engineering component quantities from a built
`.ycpkg` to orderable line items, adds spares, rounds orders to supplier pack
sizes, and defines cut patterns for raw stock.

Revision B relative to `prototype-v0.1.json` (revision A, kept for the v0.1
package):

- wheel axles M8 x 70 (front) and M8 x 55 (middle/rear), were x 80 / x 65;
- wheel inner-race spacers cut to 7.7 mm (were 21.4 mm);
- DIN 6885 A 3 x 3 key stock, 12.5 and 14.5 mm pieces (was 2 x 2 mm,
  12.5 and 8.5 mm), and 3.05 mm x 1.80 mm-deep rocker-shaft keyways;
- eight M4 x 25 differential-cradle screws and nylocs (were four M4 x 20);
- four 1/4-20 x 1/2 in socket-head screws for the mock RTG;
- no TPU filament (the limit stops are printed PET-G); the PET-G estimate is
  four 1 kg spools (about 2.4 L / 3.0 kg of modelled solid volume, dominated by
  the deck and the RTG).

The 1/4-20 holes in the deck are printed threads cut by
`tools/thread_plate.py`; no taps or inserts are listed.

From the repository root, first build the current package and then generate the
purchase and cut-list CSV files:

```bash
python tools/build_ycpkg.py --force
python tools/build_purchase_bom.py
```

`build_purchase_bom.py` reads `build/yaprover-0.2.0.ycpkg` and
`prototype-v0.2.json` by default. Pass `--v0.1` to use revision A with
`build/yaprover-0.1.0.ycpkg`.

Outputs are written to `build/procurement/purchase-bom.csv` and
`build/procurement/cut-list.csv`. To create a reviewable snapshot elsewhere,
pass `--output PATH`. The `generated/` directory is the checked-in snapshot;
it still reflects prototype revision A and must be regenerated with
`--output bom/generated` from the v0.2 release package once that is built.
Alternate packages and catalogs can be selected with `--package` and
`--catalog`.

The generated quantities are mechanically derived, but sourcing still requires
human review. Before ordering, open each supplier drawing and verify every
critical dimension. The M8 x 55 and M8 x 70 low-head wheel axles intentionally
use manufacturer-neutral DIN 7984 specifications: confirm head envelope,
unthreaded bearing surface, thread runout, material class, and availability for
the actual product selected. Empty URLs and `CUSTOM` SKUs identify lines that
require fabrication or a supplier decision rather than one-click purchasing.

Do not substitute bearing-pocket, axle, key, or 1/4-20 thread dimensions based only
on nominal catalog values. Run the [fit-coupon procedure](../docs/fit-coupons.md)
with the production printer and material first.
