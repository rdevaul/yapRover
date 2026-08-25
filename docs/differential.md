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
- Integral Ø16 mm planet thrust hubs
- Two Ø16 x Ø8.3 x 1 mm low-friction thrust washers
- 0.20 mm nominal gear-to-washer axial running clearance
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

The cross-pin is modeled as a smooth 72 mm shoulder with a head and locknut
outside the carrier towers. Tightening it clamps only the two tower faces.
Each planet's integral hub stops 1.5 mm short of its tower; a 1 mm
low-friction washer leaves 0.20 mm clearance at the gear and 0.30 mm at the
tower. The planets therefore remain independently rotatable and cannot be
axially clamped by the retained pin.

The printed cradle is a separate assembly component rather than fused into
the chassis. Four M4 x 20 screw/nyloc stacks locate it on the chassis floor,
allowing the complete gear, bearing, and cross-pin cartridge to be removed
through the open top without disturbing either suspension side.

## Prototype assembly order

1. Press the two carrier bearings into the cradle side plates.
2. Install both rocker shafts and side gears, with their common pitch apex at
   the cartridge center.
3. Place the front planet, front thrust washer, rear planet, and rear thrust
   washer between the pin towers.
4. Pass the shoulder pin through both towers, washers, and planet bores.
5. Tighten the pin locknut against the tower only; confirm both planets turn
   independently by hand before installing the cartridge.
6. Fasten the cradle to the chassis floor with the four M4 fastener stacks,
   then verify the rocker differential moves through its full ±18° range.

## Acceptance contract

The automated OpenCASCADE checks require:

- independent planet transforms when the tooth couplings are omitted;
- one revolute mate per planet and a rigid cross-pin mount;
- 0.25 ± 0.02 mm radial running clearance at both planet bores;
- 0.20 ± 0.03 mm planet-to-thrust-washer axial clearance;
- positive cross-pin retention without axial clamp load on either planet;
- no positive BREP intersection in any of the four tooth meshes through one
  complete 15-degree tooth pitch; and
- no unexpected gearbox collision throughout the rocker articulation sweep.

The PET-G gear set remains a replaceable prototype wear item. A future metal
miter-gear cartridge must preserve the same pitch-apex, shaft, and mate datums.
