# Rocker differential cartridge

The passive chassis-leveling differential is an open, four-gear miter
differential centered on the rocker axis. Its fixed carrier is the chassis,
the two side gears are rigidly keyed to the rocker shafts, and two planet
gears turn on a fixed cross-pin.

## Prototype geometry

- Four 24-tooth, module 1.5 spherical-involute straight bevel gears
- 90-degree shaft angle and 20-degree pressure angle
- 8 mm face width
- 0.25 mm nominal tooth backlash
- 8.4 mm plain planet bores on a 7.9 mm steel cross-pin
- Shared pitch apex at the chassis origin

The front and rear planets are separate printed parts. Each has its own
revolute mate to the cross-pin; neither is keyed, clamped, or rigidly coupled
to the other planet. Their opposite coupling signs are a coordinate consequence
of mirroring the rear gear across the chassis center plane, not a physical
connection between the parts.

At the level pose, with chassis-relative rocker angles `q_left` and `q_right`,
the differential closure is:

```text
q_left + q_right = 0
q_front_planet = -q_left
q_rear_planet  =  q_left
```

The cross-pin is retained by the chassis carrier while leaving both planet
gears free to rotate. The first printable cartridge should use thin thrust
washers or replaceable printed thrust faces so pin retention cannot apply an
axial clamp load to either gear.

## Acceptance contract

The automated OpenCASCADE checks require:

- independent planet transforms when the tooth couplings are omitted;
- one revolute mate per planet and a rigid cross-pin mount;
- 0.25 ± 0.02 mm radial running clearance at both planet bores;
- no positive BREP intersection in any of the four tooth meshes through one
  complete 15-degree tooth pitch; and
- no unexpected gearbox collision throughout the rocker articulation sweep.

The PET-G gear set remains a replaceable prototype wear item. A future metal
miter-gear cartridge must preserve the same pitch-apex, shaft, and mate datums.
