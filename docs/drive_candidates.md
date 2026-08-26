# Powered-wheel candidate study

The first YapRover build remains passive, but the suspension now has a defined
path to six-wheel direct drive. Candidate geometry is isolated in
`designs/yaprover_drive_candidates.dsl`; it is not included in the baseline
assembly or its BOM.

## Mechanical architecture

The passive wheel uses two 608 bearings in the wheel around a stationary axle.
That arrangement cannot simply accept a coaxial motor: the motor would turn the
shaft while the bearing-supported wheel remained free. A powered station must
instead use this load path:

`motor -> clamp coupler -> rotating 8 mm axle -> keyed wheel insert`

Two 608 bearings move into a suspension-mounted cartridge and support the
rotating axle. Wheel radial and impact loads therefore enter the rocker or
bogie through those bearings rather than through the gearmotor bearings. An
8 mm spacer controls the wheel-to-cartridge stack. The motor mount is modeled
as a split body clamp so an unverified face-hole pattern is not mistaken for a
release-ready mounting interface.

## Baseline candidate

The current envelope models the [Pololu 99:1 HP 25D metal gearmotor with
encoder, item 4847](https://www.pololu.com/product/4847/specs). Its published
envelope is 25 mm diameter by 69 mm long with a 4 mm D output shaft extending
12.5 mm. At 12 V it is rated at 100 rpm no-load; with a 130 mm wheel that is
approximately 0.68 m/s no-load ground speed. The integrated encoder is useful
for low-speed control and future odometry.

Published stall figures are not continuous operating ratings. Each motor must
have current limiting, and the drive should be selected against measured rover
mass, rolling resistance, grade, and obstacle torque before purchase. Six of
these motors add about 624 g before mounts, couplers, and wiring.

The [goBILDA 5203 50.9:1 Yellow Jacket planetary gearmotor](https://www.gobilda.com/5203-series-yellow-jacket-planetary-gear-motor-50-9-1-ratio-24mm-length-8mm-rex-shaft-117-rpm-3-3-5v-encoder/)
is retained only as a heavy-duty comparison envelope. Its native 8 mm output
is attractive, but six 481 g motors would consume roughly 2.9 kg of the current
6 kg rover mass target before mounts or electronics.

## Prototype gates

Before promoting the drive module into the rover package:

1. Weigh the passive prototype and measure wheel starting/running torque on
   representative terrain.
2. Freeze the motor and coupler supplier drawings and replace envelope-only
   geometry with controlled interface dimensions.
3. Add a keyed or clamping wheel insert and verify axle torsion and key bearing
   stress.
4. Sweep suspension motion with the motor, cable bend radius, and connectors
   included in collision checks.
5. Bench-test one station with current limiting, thermal monitoring, and shock
   loading before purchasing six motors.

Passive suspension travel should continue to be constrained by replaceable
hard stops or TPU bumpers at the rocker and bogie pivots. Springs are not part
of this refinement: they would bias the rocker-bogie equalization and can
reduce six-wheel terrain contact if introduced without a full compliance
study.
