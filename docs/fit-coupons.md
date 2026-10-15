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

The builder performs strict watertight STL validation through yapCAD's
`meshcheck` extra. A fresh repository install with
`python -m pip install -e '.[test]'` installs the required `trimesh` and
`pymeshfix` packages. If the builder reports that `trimesh` is unavailable,
rerun that install command inside the activated `yaprover` environment.

Each PET-G coupon has one small orientation-marker hole near its left/front
corner. Read the five test features from left to right when that marker is at
the lower left:

| Coupon | Left-to-right nominal sizes (mm) | Initial design value |
|---|---|---|
| 608 bearing pocket | 21.95, 22.05, 22.15, 22.25, 22.35 | 22.15 wheel/chassis / 22.30 bogie |
| 8 mm axle hole | 8.00, 8.15, 8.30, 8.45, 8.60 | 8.30 |
| 3 mm key slot | 3.00, 3.10, 3.20, 3.30, 3.40 | 3.10 (rocker hub and side-gear hub) |
| 1/4-20 printed thread | three threaded holes on the 25 mm deck grid, then one 6.60 clearance hole | Ø5.20 tap drill + printed thread / 6.60 clearance |

The key coupon is sized for DIN 6885 A 3 x 3 key stock (it replaces the v0.1
2 mm coupon). The rover's limit stops are now rigid PET-G pads printed into the
chassis towers and the rocker, so the v0.1 TPU bumper-socket coupon and test
stems are gone.

### 1/4-20 printed threads

The optical-breadboard deck and the thread coupon model their 1/4-20 holes as
plain Ø5.20 tap-drill bores so the release geometry stays analytic. Threads are
cut into the exported STEP afterwards by `tools/thread_plate.py`, which writes a
print-ready threaded STEP and STL. For the coupon:

```bash
python tools/build_fit_coupons.py --force
python tools/thread_plate.py build/fit-coupons/quarter-20-thread-fit.step \
    build/fit-coupons/quarter-20-thread-fit-threaded \
    --dsl designs/yaprover_fit_coupons.dsl --command QUARTER_20_COUPON_HOLES
```

Print `quarter-20-thread-fit-threaded.stl` flat with the deck's slicer profile.
The default thread form adds 0.18 mm radial clearance on the 6.35 mm major
diameter (`CLEAR` in the tool). If a 1/4-20 screw binds or strips, change
`CLEAR` and rethread rather than editing the DSL hole. The deck itself is
threaded the same way from an exported `CHASSIS_FINISHED` STEP (the default
`--dsl`/`--command` read its `BREADBOARD_HOLES`). The plain 6.60 mm hole checks
the clearance used in the RTG base plate.

## Acceptance

- A 608 bearing must press fully by hand with a small arbor press or vise and
  must not fall out under its own weight. Reject any pocket that requires
  hammering or visibly splits the coupon.
- The selected axle hole must allow the actual 8 mm shaft or axle screw to
  turn without binding while limiting perceptible radial shake.
- The key must enter with firm thumb pressure and withdraw without damaging
  either the key or coupon. Select a looser slot for maintenance access rather
  than forcing an interference fit.
- A 1/4-20 x 1/2 in screw must thread fully by hand (or a light driver)
  without cross-threading and hold a firm hand torque without stripping the
  printed flanks. The 1/4-20 screw must pass the 6.60 mm hole freely.

Record the selected dimensions, printer, material lot, and slicer profile.
Update the DSL production dimensions only after repeating the winning feature
at least twice; a single coupon is not evidence of printer repeatability.
Wheel hubs and chassis seats start at 22.15 mm; bogie pivot seats start at
22.30 mm. Record and update each application independently in the release
source, `designs/yaprover_suspension_detailed.dsl`.
