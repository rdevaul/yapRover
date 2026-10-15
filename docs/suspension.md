# Suspension geometry and range of motion

The v0.2 suspension keeps the proven 310 mm axle-datum track, the
rocker/bogie pivot geometry and the joint limits of v0.1, while keeping all
structural links and axle hardware outside the chassis swept volume. Every
printed part fits the Bambu H2D single-nozzle volume (325 x 320 x 325 mm),
which also fits an H2S; the one-piece rocker uses the bed diagonal. See
[the v0.2 change notes](changes-v0.2.md) for what changed relative to v0.1.

## Optical-breadboard chassis deck

The release chassis (`CHASSIS_FINISHED`) is one connected print: a flat deck
with two integral rocker towers.

- Deck: 300 x 195 x 10 mm, top at `z = -19 mm` (the old tub floor top, so the
  differential cradle datum is unchanged), underside at `z = -29 mm`. The deck
  is narrowed to `y = +/-88 mm` except for 90 mm-long lands under the towers,
  because the bogie-pivot shaft end and its inboard nut swing on about R101
  around the rocker pivot and would cut a full-width deck edge.
- 42 x 1/4-20 holes on a 25 mm optical-breadboard grid at
  `x = +/-75, +/-100, +/-125 mm` and `y = -75..+75 mm`, for walls, batteries,
  payload and the mock RTG. No holes are placed under the differential cradle
  or the towers. The DSL models them as Ø5.2 tap-drill bores; printable
  threads are cut into the exported deck STEP afterwards by
  `tools/thread_plate.py` (see [fit coupons](fit-coupons.md)).
- 60 x 44 mm differential gear opening and eight Ø4.4 mm cradle-screw holes.
- `ROCKER_TOWER` pillow blocks: an R22 x 20 mm boss holding the paired 608
  rocker-pivot bearings in teardrop-roofed seats (`y = +/-81.1` and
  `+/-93.9 mm`), an 8 mm goal-post web on the outboard face, and two 6 mm ribs.

Everything is vertical or upward-facing, so the deck prints flat, top up,
without supports. Its finished envelope including towers and printed stops is
300 x 229 x 91 mm. Exact CAD connectivity and bed fit do not establish print
strength; validate the chosen PET-G profile.

## Mock MMRTG

`rtg_prism` (`RTG_ON_PRISM`) is a separate printed part: a Curiosity-style
MMRTG with a Ø44 mm core, eight radial fins to R50, end bands, a cone cap and
one curved heat-exchanger shell per side (R56..60, 110 degrees, with raised
tubing runs) standing 6 mm clear of the fins. Its axis rises 45 degrees up and
back from the deck top at `x = -105 mm` and overhangs the rear deck edge. The
front is cut flush to a 6 mm wall at `x = -66..-60 mm` facing the
differential, the start of a future differential cover. A 90 x 170 x 6 mm base
plate with four Ø6.6 mm clearance holes bolts to the deck grid at
`(x, y) = (-125, +/-75)` and `(-75, +/-75)` with 4x 1/4-20 x 1/2 in screws.
It prints as modelled, base on the bed, without supports.

## Lateral stack

On the left side, measured outward from the chassis centerline:

- tower web outer face: `y = 97.5 mm`;
- rocker band: `y = 98.5..114.5 mm`;
- bogie band: `y = 115.5..131.5 mm`;
- wheel inboard (spoke) face: `y = 137.0 mm`;
- wheel axle datum: `y = 155.0 mm` (310 mm track between axle datums);
- wheel geometric centre: `y = 164.0 mm`; outboard rim `y = 191.0 mm`.

The right side is an exact mirror. This provides 1 mm between the moving
rocker and bogie bands and 5.5 mm between the bogie and wheel. The 54 mm wheel
keeps its v0.1 inboard face and grows outboard only.

## One-piece rocker

`ROCKER_ONE_PIECE` replaces the v0.1 front/rear split rocker. In the split
design each arm's bending moment passed between the halves only through the
shaft key (safety factor about 0.05 in a 3 g bump); the one-piece rocker
balances the arm moments internally so the key carries only the differential
torque. It has a full 16 mm, R20 keyed hub and prints `-Y` face down with the
bogie stop pads pointing up. Laid flat it measures about 351 x 165 mm, which
overruns the 325 mm bed axis, so it has to sit on the diagonal; a rotation of
roughly 60 degrees brings the footprint to about 264 x 259 mm.
`test_every_printed_component_fits_h2s_bed` searches for a fitting rotation
rather than assuming one. `ROCKER_FRONT_COMPONENT` and
`ROCKER_REAR_COMPONENT` remain in the DSL for reference but are no longer used
by the release assembly.

All link arms use 4 mm x 45-degree edge chamfers instead of R7 fillets so the
links print flat (joint axis vertical) without a near-horizontal underside. The
bogie pivot boss is R20 (was R15), leaving 8.85 mm of wall around the paired
608 seats.

## Keys and shafts

- Rocker hubs and side gears are keyed to the rocker shafts with DIN 6885 A
  3 x 3 mm parallel keys (was 2 x 2 mm): 12.5 mm long in the rocker hub and
  14.5 mm long under the side gear.
- Keyed bores are Ø8.2 mm (tighter than the Ø8.4 mm running bores so the hub
  cannot rock on the shaft) with 3.1 x 3.1 mm keyways.
- The shaft slots are 3.05 mm wide and 1.8 mm deep from the 8 mm OD (key spans
  `z = 2.2..5.2 mm`), engaging the hub keyway by about 1.1 mm. The v0.1 2 mm key
  in a 2.7 mm-deep slot could sit below the hub bore and carry no torque.
- Each differential side gear has a Ø18 x 9 mm keyed hub on its back face,
  giving the key 14.7 mm of engagement instead of 5.7 mm.

The procurement cut list includes the milling operation. Bogie shaft ends
require M8 x 1.25 threads, 9.5 mm at the inboard end and 7 mm at the outboard
end, keeping the bearing journals smooth. Threads remain simplified in CAD.
Verify journal fits, key fit (see the 3 mm key coupon), and push-on retainer
holding force on real stock.

## Wheels and axles

The wheel (`WHEEL_HUB`) is a Ø135 mm (over grousers) x 54 mm Mars-style wheel:
a 2.5 mm tread skin, 24 chevron grousers 2.5 mm tall, and six 9 mm-thick curved
flexure spokes on the inboard face. It prints inboard face down with the open
cup up and needs no supports. The right wheel is mirrored so its spokes are
inboard too.

The hub is a short R14.5 x 22.5 mm boss on the spoke face, so the outboard
bearing, washer and nut sit near the spokes and are reachable through the open
125 mm cup. In wheel-local coordinates (`y` outward from the axle datum):

| Item | y range (mm) |
|---|---|
| Wheel inboard face / hub | -18.0 .. +4.5 |
| Inboard 608 (Ø22.15 seat, open inboard) | -17.7 .. -10.7 |
| Wheel shoulder / inner-race spacer 12 x 8.3 x 7.7 | -10.7 .. -3.0 |
| Outboard 608 (Ø22.15 seat, open outboard) | -3.0 .. +4.0 |
| M8 washer | +4.0 .. +5.6 |
| M8 nyloc (centre) | +9.0 |

The seats are a light press in a printed hole, each open to its own face so
the bearing presses in from that side; the bore step above the bed-side seat
is a roughly 50-degree cone so it prints without support.

All wheel-axis bosses have chassis-facing counterbores for recessed Ø12.8 mm
low-profile M8 heads. Nothing projects past the inner printed-link face.

- Front wheels use M8 x 70 low-head bolt envelopes (was x 80) and 22.8 mm
  external spacer tubes between the rocker boss and the inboard bearing.
- Middle and rear wheels use M8 x 55 low-head bolt envelopes (was x 65) and
  5.8 mm external spacers.
- Every wheel contains a 12 mm OD / 8.3 mm ID metal inner-race spacer,
  7.7 mm long (was 21.4 mm), bearing only on the inner rings.
- Each wheel is retained by one outboard washer and nyloc nut.

The external spacer, both inner rings, the internal spacer and the outboard
washer form a continuous metal clamp path, so tightening the nut cannot pinch
the rotating printed hub. The bearing bore is modeled at its real nominal 8 mm
diameter; simplified shaft envelopes remain 7.9 mm and do not specify a
journal manufacturing tolerance.

Face the internal spacer to the actual seated-bearing separation, initially
targeting +/-0.02 mm. Confirm free rotation and acceptable end play after
tightening the retention hardware; do not use a loose axle nut to compensate
for a short spacer. Before purchasing hardware, confirm actual head diameter,
head thickness, unthreaded shank length, and thread engagement against the
supplier drawing. The model dimensions are design envelopes, not a substitute
for inspection.

## Printed joint limits

Each rocker and bogie carries an integral PET-G contact tab: a tapered fin
20 mm wide at its root inside the hub, narrowing to 10 mm under an R5 nose on a
60 mm radius about the joint axis. The limits are rigid R6 PET-G pads printed
into the parent part, so there are no separate bumper parts:

- Rocker stops: two R6 pads cantilevered from each chassis tower web across the
  rocker band (at `x = +/-28.8 mm`, `z = 53.1 mm`), with a 45-degree chin
  underneath so they print with the deck. They are tangent to the rocker tab
  nose at `-18/+18 degrees`.
- Bogie stops: two R6 pads printed onto the rocker on 12 mm-thick ears
  (`r = 8..66 mm` from the bogie pivot), reaching into the bogie band. They are
  tangent to the bogie tab nose at `-35/+38 degrees`.

The limit angles are unchanged from v0.1. The v0.1 TPU 95A press-in bumpers,
their sockets, and the TPU filament line are removed. A hard impact now loads a
structural part rather than a sacrificial pad; inspect the stops and tabs after
rough testing.

## Validated motion

The exact-geometry ROM test samples every independent joint in steps no larger
than 2 degrees:

- rocker relative to chassis: −18° to +18°;
- bogie relative to rocker: −35° to +38° on both sides.

These are CAD +Y right-hand-rule angles. The terrain oracle uses the opposite,
nose-up-positive convention, so its bogie limits are −38° to +35°.

At every sample, transformed bounding boxes screen the complete candidate set.
Pairs that cannot prove separation are promoted to OpenCASCADE common-volume
and minimum-distance checks. The policy includes every wheel against every
link, the chassis and the RTG, every wheel against every foreign shaft, spacer,
bearing pack, key, and retainer, plus every modeled axle stack against chassis
material. Only the moving member and the part carrying its printed stops
(rocker/chassis, bogie/rocker) may touch, and only at their corresponding
joint-limit endpoint; every other positive common volume is a test failure. A
dedicated test bounds the endpoint contact (at most 0.5 mm³ of numerical
common volume and 0.02 mm distance at the limit) and requires more than
0.05 mm clearance two degrees inside each limit.

Additional exact tests cover all eight combinations of the three independent
joint-range endpoints and samples along four terrain-driven paths on the
detailed assembly. These supplement the individual sweeps; they are sampled
checks, not a continuous collision proof or a wheel-load/stability analysis.
