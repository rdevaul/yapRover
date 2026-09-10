# Suspension geometry and range of motion

The first-build suspension retains a 310 mm wheel-center track while keeping
all structural links and axle hardware outside the chassis swept volume.

## One-piece chassis

The release chassis is a single fused tub with integral bearing housings.
Its finished envelope is 205 x 195 x 110 mm. With the floor on the bed, a
5 mm brim requires 215 x 205 mm of usable area. Check bed clips and the
printer's actual printable area before using a nominal 220 x 220 mm machine.
The former split halves and overlapping splice keys are retired from the
release source; no adhesive chassis seam is required.

Slice with the open top upward and inspect support requirements around the
horizontal bearing pockets and the cartridge opening. Exact CAD connectivity
and bed fit do not establish print strength; validate the chosen PET-G profile.

## Lateral stack

On the left side, measured outward from the chassis centerline:

- chassis outer wall: `y = 97.5 mm`;
- split rocker band: `y = 98.5..114.5 mm`;
- bogie band: `y = 115.5..131.5 mm`;
- wheel inner face: `y = 137.0 mm`;
- wheel center: `y = 155.0 mm`.

The right side is an exact mirror. This provides 1 mm between the moving
rocker and bogie bands and 5.5 mm between the bogie and wheel.

The front and rear rocker pieces share one 16 mm band. Complementary 8 mm
half-hubs meet at the chassis pivot, allowing both pieces to fit a 220 mm print
bed without placing either rocker arm in the bogie's swept layer. An exact BREP
test rejects positive overlap between the two printable pieces.

## Wheel axles

All wheel-axis bosses have chassis-facing counterbores for recessed Ø12.8 mm
low-profile M8 heads. Nothing projects past the inner printed-link face.

- Front wheels use M8 x 80 bolt envelopes and 22.8 mm external spacer tubes.
- Middle and rear wheels use M8 x 65 bolt envelopes and 5.8 mm external spacers.
- Every wheel contains a 12 mm OD / 8.3 mm ID metal inner-race spacer,
  nominally 21.4 mm long, in a 12.5 mm hub clearance passage.
- Each wheel is retained by one outboard washer and nyloc nut.

The 7 mm-wide bearings seat at wheel-local `y = +/-14.2 mm`. Their inner
faces are at `+/-10.7 mm`, matching the spacer ends and wheel shoulders.
The external spacer and outboard washer contact the outward inner-ring faces
at `+/-17.7 mm`, closing the axial clamp path through metal. The bearing bore
is modeled at its real nominal 8 mm diameter; simplified shaft envelopes
remain 7.9 mm and do not specify a journal manufacturing tolerance.

Face the internal spacer to the actual seated-bearing separation, initially
targeting +/-0.02 mm. Confirm free rotation and acceptable end play after
tightening the retention hardware; do not use a loose axle nut to compensate
for a short spacer. Check washer and spacer contact against the actual
bearing inner-ring and seal geometry.

The rocker pivot's wheel-facing washer and retaining clip are similarly
recessed. Its shaft and key stop at the rocker band's outer face.

Before purchasing hardware, confirm actual head diameter, head thickness,
unthreaded shank length, and thread engagement against the supplier drawing.
The model dimensions are design envelopes, not a substitute for inspection.

The rocker shafts now contain modeled keyways: 2.05 mm wide, 1.20 mm deep
from the modeled OD, with 1 mm extra length at each end of each key.
The procurement cut list includes the milling operation. Bogie shaft ends
require M8 x 1.25 threads, 9.5 mm at the inboard end and 7 mm at the outboard
end, keeping the bearing journals smooth. Threads remain simplified in CAD.
Verify journal fits, key fit, and push-on retainer holding force on real stock.

## Replaceable joint limits

Each rocker and bogie carries an integral PET-G contact tongue whose rounded
nose follows a 60 mm radius about the joint axis. Paired TPU 95A pads establish
the mechanical limits at rocker `-18/+18 degrees` and bogie `-35/+38 degrees`.
The pads use nominal 5.10 mm press-fit stems in 5.30 mm modeled sockets and are
separate package components so a hard impact replaces a bumper rather than a
structural link.

At each exact endpoint the analytic model permits only a small intentional TPU
preload (no more than 2 cubic millimetres of common volume). Two degrees inside
each limit, the contact pair has approximately 2 mm clearance; at the level
pose the nearest pads are more than 18 mm from their moving noses. The
one-piece outer tub wall retains 1 mm nominal clearance to the rocker tongue.

Print the TPU socket/stem coupon and perform its 20 N retention check before a
full build. The modeled interference is a calibration starting point, not a
universal FDM press-fit allowance.

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
foreign shaft, spacer, bearing pack, key, and retainer, plus every modeled axle
stack against chassis material. Only the four named moving-member/TPU-bumper
pairs may contact, and only at their corresponding hard-stop endpoint; every
other positive common volume is a test failure.

Additional exact tests cover all eight combinations of the three independent
joint-range endpoints and samples along four terrain-driven paths on the
detailed assembly. These supplement the individual sweeps; they are sampled
checks, not a continuous collision proof or a wheel-load/stability analysis.
