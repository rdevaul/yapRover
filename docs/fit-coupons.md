# Prototype fit coupons

Print and inspect the coupons before committing to the full rover print. Use
the same printer, nozzle, material lot, layer height, perimeter count, print
orientation, and dimensional compensation intended for the production parts.

Generate strict BREP-tessellated STL and analytic STEP files with:

```bash
python tools/build_fit_coupons.py
```

Outputs are written to `build/fit-coupons/`. Pass `--force` to replace an
existing set.

Each PET-G coupon has one small orientation-marker hole near its left/front
corner. Read the five test features from left to right when that marker is at
the lower left:

| Coupon | Left-to-right nominal sizes (mm) | Initial design value |
|---|---|---|
| 608 bearing pocket | 21.95, 22.05, 22.15, 22.25, 22.35 | 22.15 wheel / 22.30 structure |
| 8 mm axle hole | 8.00, 8.15, 8.30, 8.45, 8.60 | 8.30 |
| 2 mm key slot | 1.90, 2.00, 2.10, 2.20, 2.30 | 2.20 |
| TPU bumper socket | 5.00, 5.15, 5.30, 5.45, 5.60 | 5.30 |

The TPU file contains five nominal 5.10 mm stems. Use a fresh stem for a final
retention check if repeated insertion has polished or stretched an earlier
sample.

## Acceptance

- A 608 bearing must press fully by hand with a small arbor press or vise and
  must not fall out under its own weight. Reject any pocket that requires
  hammering or visibly splits the coupon.
- The selected axle hole must allow the actual 8 mm shaft or axle screw to
  turn without binding while limiting perceptible radial shake.
- The key must enter with firm thumb pressure and withdraw without damaging
  either the key or coupon. Select a looser slot for maintenance access rather
  than forcing an interference fit.
- A TPU stem must seat fully with firm thumb pressure and resist a 20 N axial
  hand pull. It must remain removable with pliers so the bumper is sacrificial.

Record the selected dimensions, printer, material lot, and slicer profile.
Update the DSL production dimensions only after repeating the winning feature
at least twice; a single coupon is not evidence of printer repeatability.
Wheel hubs and structural pivot seats currently use different starting
allowances, so record and update those two 608 applications independently.
