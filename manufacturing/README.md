# Manufacturing outputs

Source-controlled manufacturing profiles and release-generation scripts live
here. Generated geometry belongs in versioned release artifacts, not routine
source commits.

Prototype fit artifacts are generated from
`designs/yaprover_fit_coupons.dsl` with `tools/build_fit_coupons.py`; their
inspection and selection procedure is documented in
[`docs/fit-coupons.md`](../docs/fit-coupons.md). Purchase and raw-stock cut
lists are generated separately from the built package and the reviewed catalog
as described in [`bom/README.md`](../bom/README.md).

The chassis deck's 1/4-20 breadboard holes are modelled as Ø5.2 tap drills.
Export `CHASSIS_FINISHED` to STEP and run `tools/thread_plate.py` on it to cut
printable 1/4-20 threads into the print file (STEP + STL); see the 1/4-20
section of [`docs/fit-coupons.md`](../docs/fit-coupons.md).
