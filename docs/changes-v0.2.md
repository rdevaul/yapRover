# yapRover v0.2 changes

v0.2 is a structural and printability revision of the release assembly
(`designs/yaprover_suspension_detailed.dsl`) relative to v0.1 (upstream commit
`feb41c8`). The kinematic datums, 310 mm axle-datum track, rocker/bogie pivot
locations, differential closure and joint limits are unchanged; the mate graph
proven by the v0.1 tests still poses the rover.

Contributed by Garrett Kinsman, building on Richard DeVaul's v0.1 design.
Design iteration was assisted by Claude (Anthropic).

## Printing

- Print target is the Bambu H2D single-nozzle volume (325 x 320 x 325 mm,
  which also fits an H2S) instead of a 220 x 220 mm
  bed. The detailed tests check every printed part against that bed with a
  rotation search about its print-vertical axis.
- Floating limit tabs and bogie ears that exported as separate solids are now
  fused to their links.
- Link edges use 4 mm x 45-degree chamfers instead of R7 fillets (all
  `fillet()` calls became `chamfer()`), so the links print flat without
  near-horizontal undersides. Horizontal holes in the towers and cradle use
  teardrop roofs.

## Structure

- **One-piece rocker** (`ROCKER_ONE_PIECE`). The split rocker passed each arm's
  moment between its halves only through the 2 mm shaft key (safety factor
  about 0.05 in a 3 g bump). One piece balances the arm moments internally; the
  key carries only differential torque. Full 16 mm, R20 keyed hub. The split
  `ROCKER_FRONT_COMPONENT` / `ROCKER_REAR_COMPONENT` commands remain in the DSL
  but are not used by the assembly.
- **3 x 3 keys.** DIN 6885 A 3 x 3 keys in 3.05 x 1.8 mm-deep shaft slots,
  Ø8.2 keyed bores with 3.1 x 3.1 keyways. Side gears gain a Ø18 x 9 mm keyed
  hub (14.7 mm of key engagement instead of 5.7 mm).
- **Bogie pivot boss** R20 (was R15).
- **Differential cradle** is a 120 x 96 x 8 mm base frame with 45-degree
  gussets, held by 8x M4 x 25 screws with nylocs under the deck (was 4x
  M4 x 20). The deck gear opening is 60 x 44 mm (was 76 x 90).

## Limit stops

- The four TPU 95A limit-bumper parts (`*_ROCKER_LIMIT_BUMPERS`,
  `*_BOGIE_LIMIT_BUMPERS`) and their mates are removed from the assembly.
- Rocker stops are R6 PET-G pads printed into the chassis `ROCKER_TOWER` webs
  with a 45-degree chin; bogie stops are R6 pads printed onto the rocker
  (`BOGIE_STOP_PADS`) on 12 mm ears.
- Contact tabs are tapered fins (20 mm root to 10 mm) with R5 noses. Contacts
  are tangent at the same limits as v0.1: rocker +/-18 degrees, bogie
  -35/+38 degrees.

## Chassis deck

- The 205 x 195 x 110 mm tub (`CHASSIS_TUB`, `CHASSIS_SIDE_INTERFACE`) is
  replaced by an optical-breadboard deck (`CHASSIS_FINISHED`): 300 x 195 x
  10 mm, narrowed to `y = +/-88 mm` except under the towers, with 42 1/4-20
  holes on a 25 mm grid and two `ROCKER_TOWER` pillow blocks holding the paired
  608 rocker bearings in teardrop seats.
- The 1/4-20 holes are modelled as Ø5.2 tap drills. `tools/thread_plate.py`
  cuts printable threads into the exported STEP.

## Mock RTG

- New part `rtg_prism` (`RTG_ON_PRISM`): a mock MMRTG with fins and curved
  heat-exchanger shells, tilted 45 degrees up and back over the rear of the
  deck, standing on its own base plate and bolted to the deck grid with
  4x 1/4-20 x 1/2 in screws. Its front wall faces the differential as the start
  of a future cover.

## Wheels

- Ø135 (over grousers) x 54 mm Mars-style wheels: 24 chevron grousers, six
  curved flexure spokes on the inboard face, supportless when printed inboard
  face down. The inboard face is unchanged; the extra width is outboard.
- Short R14.5 hub: 608 pair at wheel-local `y = -14.2 / +0.5 mm`, inner-race
  spacer 12 x 8.3 x 7.7 mm (was 21.4 mm), washer and nyloc at `y = 4.8 / 9.0`.
- Axle bolts M8 x 70 front (was x 80) and M8 x 55 middle/rear (was x 65).

## Supporting files

- Tests describe and verify the v0.2 assembly (65 parts, 64 mates), printed
  stops at the joint limits, the wheel bearing stack, and H2S bed fit.
- `bom/prototype-v0.2.json` (revision B) is the default procurement catalog;
  `bom/prototype-v0.1.json` is kept for the v0.1 package
  (`python tools/build_purchase_bom.py --v0.1`).
- Fit coupons: the 2 mm key coupon is now a 3 mm coupon (3.00..3.40 mm), the
  TPU bumper socket/stem coupons are replaced by a 1/4-20 printed-thread coupon.
- Project version 0.2.0; `tools/build_ycpkg.py` defaults to the pyproject
  version.
- `tools/render_geometry_updates.py` and `renders/yapRover_geometry_updates.png`
  are historical v0.1 material and have not been regenerated.
