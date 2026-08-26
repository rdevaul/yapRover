# Suspension geometry and range of motion

The first-build suspension retains a 310 mm wheel-center track while keeping
all structural links and axle hardware outside the chassis swept volume.

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

- Front wheels use M8 x 80 bolt envelopes and 21.4 mm spacer tubes.
- Middle and rear wheels use M8 x 65 bolt envelopes and 4.4 mm spacer tubes.
- Each wheel is retained by one outboard washer and nyloc nut.

The rocker pivot's wheel-facing washer and retaining clip are similarly
recessed. Its shaft and key stop at the rocker band's outer face.

Before purchasing hardware, confirm actual head diameter, head thickness,
unthreaded shank length, and thread engagement against the supplier drawing.
The model dimensions are design envelopes, not a substitute for inspection.

## Validated motion

The exact-geometry ROM test samples every independent joint in steps no larger
than 2 degrees:

- rocker relative to chassis: −18° to +18°;
- bogie relative to rocker: −35° to +38° on both sides.

At every sample, transformed bounding boxes screen the complete candidate set.
Pairs that cannot prove separation are promoted to OpenCASCADE common-volume
and minimum-distance checks. The policy includes every wheel against every
foreign shaft, spacer, bearing pack, key, and retainer, plus every modeled axle
stack against chassis material.
