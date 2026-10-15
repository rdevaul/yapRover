# Prototype assembly order and printed fits

The v0.2 prototype can only be assembled in one order: several bearing seats
are open on one face only, and the differential side gears must be backed out
of mesh before the planets will drop in. This note records that order and the
printed fits it depends on, so the sequence does not have to be rediscovered
on the bench.

Dimensions below are the modelled (as-drawn) values from
`designs/yaprover_suspension_detailed.dsl`. Printed holes typically come out
0.1 to 0.2 mm under their drawn diameter on a well-tuned FDM machine, which is
what the press fits rely on; check the printed [fit
coupons](fit-coupons.md) before committing to a full set of parts.

## Assembly order

1. **Wheel bearings.** Press the inboard 608 in from the spoke face, drop the
   inner-race spacer in from the cup side, then press the outboard 608 in from
   the cup. The inner-race spacer must be in place first: once both bearings
   are seated there is no access to it.
2. **Bogie pivot bearings.** One 608 from each face of the bogie boss.
3. **Rocker tower bearings.** Press the tower 608s with an M8 draw-bolt and a
   pair of Ø21 discs, *before* the differential cradle goes on. The cradle
   covers the inboard tower faces.
4. **Differential cradle.** 8x M4 x 25 screws, hex key from above, 7 mm wrench
   on the nylocs under the deck.
5. **Side gears.** Set each side gear at its final axial position, then slide
   it 6 to 8 mm outboard so its hub enters the empty carrier-bearing seat.
   This is what frees up axial room for the planets.
6. **Planet gears.** Drop the planets into mesh, fit the 1 mm thrust washers
   into the 1.5 mm gaps, and pass the cross pin in from +X. (From -X it fouls
   the mock RTG's wall, so install the cross pin before the RTG if working
   from that side.)
7. **Close the differential.** Slide the side gears back into mesh, press the
   carrier 608s in from outboard, and fit the Ø8.4 x 12 x 1.4 shims.
8. **Rocker shafts and gear keys.** Grease the gear key into the side-gear
   keyway from the toe end; it tilts in from above at `x = 0`. Feed the 8 mm
   shaft in from outboard through both tower 608s, the carrier 608 and the
   gear. Fit the inboard retaining clip from above.
9. **Bogies onto rockers.** Drop the rocker key into the exposed slot, slide
   the bogie on from outboard (at 0 degrees the limit tab passes between the
   tower stop pads), then fit the washer and retaining clip.
10. **Wheels.** Axle spacer, M8 low-head screw in from the link's inboard
    face, wheel, Ø12 shim, nyloc. A 13 mm socket reaches the nut through the
    wheel cup.
11. **Mock RTG.** Four 1/4-20 screws into the deck grid; vertical access is
    clear with the rover otherwise assembled.

## Printed fits

| Feature | Drawn | Notes |
| --- | --- | --- |
| Wheel and tower 608 seats | Ø22.15 | Light press onto a 22.00 mm bearing OD. |
| Bogie and cradle 608 seats | Ø22.15 | Same seat diameter throughout; earlier revisions used Ø22.30, which printed loose. |
| Keyed bores | Ø8.2 | On 8 h9 shaft stock this leaves little clearance and may need reaming. |
| Hub keyway | 3.1 x 3.1 | For a DIN 6885 3 x 3 key. Tight: a keyway printing 0.1 to 0.2 mm under can interfere with a nominal 3 mm key. Dress the keyway or select keys on the low side. |
| Shaft key slots | 3.05 wide x 1.8 deep | Milled, not printed. |
| Plain shaft bores | Ø8.4 | Clearance fit on 8 mm shaft. |
| Tower teardrop bore | Ø8.3 | Teardrop so the overhang stays printable. |
| Low-head screw counterbore | Ø13.2 x 5.9 deep | For a DIN 7984 M8 head (Ø13 x 5). Only 0.2 mm nominal diametral clearance, so a counterbore printing under size will need clearing before the head seats. |
| M4 clearance | Ø4.4 | |
| 1/4-20 deck holes | Ø5.2 tap drill | Threads are cut into the print file by `tools/thread_plate.py`, not printed as modelled geometry. |
| Retention recess | Ø16.4 | Clears a Ø16 washer. |

## Shims and spacers

- **Rocker shaft axial location.** A 1 mm Ø12 shim between the rocker hub and
  the outer 608 inner race, with the retaining clip outboard of it. The
  hub-to-tower gap is only about 1.1 mm, so the shim sets the axial position.
- **Bogie pivot.** A Ø8.4 x 12 x 1 shim takes up the rocker-to-inner-race gap.
  Snug the nuts only; this is a running joint.
- **Washer choice.** Ø16 washers and the Ø18 gear hub both bear on the 608
  seals if fitted directly. Use Ø12 shims against the inner races instead.
- **Wheel inner-race spacer.** The bearing shoulders sit 7.6 mm apart; cut the
  spacer to 7.6 mm rather than the nominal 7.7 mm.

## Range of motion

The rocker and bogie travel is limited by printed stop pads, not by hardware.
Only those pads may touch at the limits; see
[the suspension notes](suspension.md) for the validated travel and
`tests/test_yaprover_suspension_detailed.py::test_printed_stops_meet_moving_tabs_at_joint_limits`
for the check that enforces it.
