module yaprover_suspension_detailed

# OCC-backed, FDM-oriented geometry for the YapRover suspension showcase.
#
# Coordinates follow the kinematic proof: +X forward, +Y left, +Z up.  All
# wheel and suspension axes point +Y.  Geometry is moved laterally around the
# unchanged datum axes so the proven mate graph remains the source of pose.


command AXIS_BOSS_608(x: float, y: float, z: float) -> solid:
    let raw: solid = translate(cylinder(15.0, 16.0), 0.0, 0.0, -8.0)
    let boss: solid = rotate(raw, -90.0, 0.0, 0.0)
    let bore_raw: solid = translate(cylinder(4.2, 18.0), 0.0, 0.0, -9.0)
    let bore: solid = rotate(bore_raw, -90.0, 0.0, 0.0)
    let seat_raw: solid = translate(cylinder(11.15, 7.2), 0.0, 0.0, 0.8)
    let seat: solid = rotate(seat_raw, -90.0, 0.0, 0.0)
    emit translate(difference(boss, bore, seat), x, y, z)


command AXIS_BOSS_CUTTERS(x: float, y: float, z: float) -> solid:
    # Reapply after arm/boss union so overlapping arm stock cannot refill the
    # running bore or one-sided bearing pocket.
    let bore_raw: solid = translate(cylinder(4.2, 18.0), 0.0, 0.0, -9.0)
    let bore: solid = rotate(bore_raw, -90.0, 0.0, 0.0)
    let seat_raw: solid = translate(cylinder(11.15, 7.2), 0.0, 0.0, 0.8)
    let seat: solid = rotate(seat_raw, -90.0, 0.0, 0.0)
    emit translate(union(bore, seat), x, y, z)


command AXIS_BOSS_BLANK(x: float, y: float, z: float) -> solid:
    let raw: solid = translate(cylinder(15.0, 16.0), 0.0, 0.0, -8.0)
    emit translate(rotate(raw, -90.0, 0.0, 0.0), x, y, z)


command AXIS_BORE_CUTTERS(x: float, y: float, z: float) -> solid:
    let raw: solid = translate(cylinder(4.2, 18.0), 0.0, 0.0, -9.0)
    emit translate(rotate(raw, -90.0, 0.0, 0.0), x, y, z)


command AXIS_LOW_HEAD_CUTTER(x: float, y: float, z: float) -> solid:
    # Ø13.2 x 4.9 mm pocket entering from the negative-Y face of a 16 mm
    # wheel-axis boss. Mirroring the finished right-hand link puts the pocket
    # on its positive-Y (chassis-facing) side automatically.
    let raw: solid = translate(cylinder(6.6, 4.9), 0.0, 0.0, -2.45)
    let on_y: solid = rotate(raw, -90.0, 0.0, 0.0)
    emit translate(on_y, x, y - 5.85, z)


command AXIS_OUTBOARD_RETENTION_CUTTER(
    x: float, y: float, z: float
) -> solid:
    # Ø16.4 x 3.4 mm recess entering the positive-Y face of a 16 mm boss.
    # It houses a washer and retaining clip without projecting toward the
    # middle wheel. Mirroring moves it to the correct right-hand face.
    let raw: solid = translate(cylinder(8.2, 3.4), 0.0, 0.0, -1.7)
    let on_y: solid = rotate(raw, -90.0, 0.0, 0.0)
    emit translate(on_y, x, y + 6.5, z)


command AXIS_KEYED_CUTTERS(x: float, y: float, z: float) -> solid:
    let bore: solid = AXIS_BORE_CUTTERS(x, y, z)
    let keyway: solid = translate(box(2.2, 18.0, 2.2),
                                  x, y, z + 3.8)
    emit union(bore, keyway)


command AXIS_DUAL_608_CUTTERS(x: float, y: float, z: float) -> solid:
    let bore: solid = AXIS_BORE_CUTTERS(x, y, z)
    let first_raw: solid = translate(cylinder(11.15, 7.2),
                                     0.0, 0.0, -8.1)
    let second_raw: solid = translate(cylinder(11.15, 7.2),
                                      0.0, 0.0, 0.9)
    let first: solid = rotate(first_raw, -90.0, 0.0, 0.0)
    let second: solid = rotate(second_raw, -90.0, 0.0, 0.0)
    emit union(bore, translate(first, x, y, z),
               translate(second, x, y, z))


command AXIS_BOSS_BORE(x: float, y: float, z: float) -> solid:
    emit difference(AXIS_BOSS_BLANK(x, y, z),
                    AXIS_BORE_CUTTERS(x, y, z))


command AXIS_BOSS_WHEEL_AXLE(x: float, y: float, z: float) -> solid:
    emit difference(AXIS_BOSS_BLANK(x, y, z),
                    AXIS_BORE_CUTTERS(x, y, z),
                    AXIS_LOW_HEAD_CUTTER(x, y, z))


command AXIS_BOSS_KEYED(x: float, y: float, z: float) -> solid:
    emit difference(AXIS_BOSS_BLANK(x, y, z),
                    AXIS_KEYED_CUTTERS(x, y, z))


command AXIS_BOSS_HALF_BLANK(x: float, y: float, z: float) -> solid:
    # An 8 mm axial half-hub lets the two bed-sized rocker pieces share one
    # 16 mm suspension band instead of occupying separate lateral layers.
    let raw: solid = translate(cylinder(15.0, 8.0), 0.0, 0.0, -4.0)
    emit translate(rotate(raw, -90.0, 0.0, 0.0), x, y, z)


command AXIS_BOSS_KEYED_HALF(x: float, y: float, z: float) -> solid:
    emit difference(AXIS_BOSS_HALF_BLANK(x, y, z),
                    AXIS_KEYED_CUTTERS(x, y, z))


command AXIS_BOSS_DUAL_608(x: float, y: float, z: float) -> solid:
    emit difference(AXIS_BOSS_BLANK(x, y, z),
                    AXIS_DUAL_608_CUTTERS(x, y, z))


command ARM_FILLETED(
    length: float, angle_y_deg: float,
    center_x: float, center_y: float, center_z: float
) -> solid:
    # Fillet while axis-aligned to keep OCC edge topology predictable.
    let rounded: solid = fillet(box(length, 16.0, 28.0), 7.0)
    let centered: solid = translate(rounded, 0.0, 0.0, -14.0)
    let aimed: solid = rotate(centered, 0.0, angle_y_deg, 0.0)
    emit translate(aimed, center_x, center_y, center_z)


command Y_AXIS_CYLINDER(
    radius: float, length: float,
    center_x: float, center_y: float, center_z: float
) -> solid:
    let centered: solid = translate(cylinder(radius, length),
                                      0.0, 0.0, -length / 2.0)
    emit translate(rotate(centered, -90.0, 0.0, 0.0),
                   center_x, center_y, center_z)


command LIMIT_CONTACT_TAB(center_y: float) -> solid:
    # A compact PET-G radial tongue with a rounded contact nose.  The nose
    # center follows a 60 mm radius above its joint axis, away from both
    # downward-sloping suspension arms.
    let bridge: solid = translate(box(6.0, 16.0, 45.0),
                                  0.0, center_y, 37.5)
    let nose: solid = Y_AXIS_CYLINDER(3.0, 16.0,
                                      0.0, center_y, 60.0)
    emit union(bridge, nose)


command ROCKER_LIMIT_SOCKET_CUTTERS() -> solid:
    # Press-fit sockets through both chassis side walls. The bumper centers
    # flank an upward-pointing moving nose and become tangent at the solver's
    # +/-18 degree rocker limits.
    let upper_left: solid = Y_AXIS_CYLINDER(2.65, 6.0,
                                            -25.06, 96.5, 54.52)
    let lower_left: solid = Y_AXIS_CYLINDER(2.65, 6.0,
                                            25.06, 96.5, 54.52)
    let left: solid = compound(upper_left, lower_left)
    emit compound(left, mirror(left, vector(0.0, 1.0, 0.0)))


command LEFT_ROCKER_LIMIT_BUMPER_GEOMETRY() -> solid:
    let upper_pad: solid = Y_AXIS_CYLINDER(4.0, 16.0,
                                           -25.06, -48.5, 54.52)
    let lower_pad: solid = Y_AXIS_CYLINDER(4.0, 16.0,
                                           25.06, -48.5, 54.52)
    let upper_stem: solid = Y_AXIS_CYLINDER(2.55, 5.0,
                                            -25.06, -59.0, 54.52)
    let lower_stem: solid = Y_AXIS_CYLINDER(2.55, 5.0,
                                            25.06, -59.0, 54.52)
    emit compound(union(upper_pad, upper_stem),
                  union(lower_pad, lower_stem))


command BOGIE_LIMIT_SOCKET_CUTTERS() -> solid:
    # Coordinates are in the unsifted rocker component frame. After the
    # rocker is moved into its lateral band these sockets accept stems from
    # the bumper pair that is rigidly located at the bogie-pivot datum.
    let upper: solid = Y_AXIS_CYLINDER(2.65, 7.0,
                                       -134.85, -3.0, 9.85)
    let lower: solid = Y_AXIS_CYLINDER(2.65, 7.0,
                                       -52.80, -3.0, 7.65)
    emit compound(upper, lower)


command BOGIE_LIMIT_MOUNT_EARS() -> solid:
    # PET-G ears carry the replaceable pads out beyond the pivot boss. They
    # stay in the rocker band; only the TPU pads occupy the bogie band.
    let lower_raw: solid = translate(box(45.0, 16.0, 8.0),
                                      37.5, -8.5, 0.0)
    let lower: solid = translate(rotate(lower_raw, 0.0, -45.31, 0.0),
                                  -95.0, 0.0, -35.0)
    let upper_raw: solid = translate(box(45.0, 16.0, 8.0),
                                      37.5, -8.5, 0.0)
    let upper: solid = translate(rotate(upper_raw, 0.0, -131.69, 0.0),
                                  -95.0, 0.0, -35.0)
    emit union(lower, upper)


command LEFT_BOGIE_UPPER_LIMIT_BUMPER_GEOMETRY() -> solid:
    let upper_pad: solid = Y_AXIS_CYLINDER(4.0, 16.0,
                                           -39.85, -31.5, 44.85)
    let upper_stem: solid = Y_AXIS_CYLINDER(2.55, 7.0,
                                            -39.85, -43.0, 44.85)
    emit union(upper_pad, upper_stem)


command LEFT_BOGIE_LOWER_LIMIT_BUMPER_GEOMETRY() -> solid:
    let lower_pad: solid = Y_AXIS_CYLINDER(4.0, 16.0,
                                           42.20, -31.5, 42.65)
    let lower_stem: solid = Y_AXIS_CYLINDER(2.55, 7.0,
                                            42.20, -43.0, 42.65)
    emit union(lower_pad, lower_stem)


command LEFT_BOGIE_LIMIT_BUMPER_GEOMETRY() -> solid:
    # The unequal +/- limit angles are intentional: -35 and +38 degrees.
    emit compound(LEFT_BOGIE_UPPER_LIMIT_BUMPER_GEOMETRY(),
                  LEFT_BOGIE_LOWER_LIMIT_BUMPER_GEOMETRY())


command ROCKER_FRONT_COMPONENT() -> solid:
    # C -> F = (+190, -75) mm.  This 204.3 mm component fits a 220 mm bed.
    let arm: solid = ARM_FILLETED(204.266982, 21.540976,
                                  95.0, -8.5, -37.5)
    let center: solid = AXIS_BOSS_KEYED_HALF(0.0, -12.5, 0.0)
    let front: solid = AXIS_BOSS_WHEEL_AXLE(190.0, -8.5, -75.0)
    let joined: solid = union(arm, center, front,
                              LIMIT_CONTACT_TAB(-8.5))
    emit difference(joined, AXIS_KEYED_CUTTERS(0.0, -8.5, 0.0),
                    AXIS_BOSS_HALF_BLANK(0.0, -4.5, 0.0),
                    AXIS_BORE_CUTTERS(190.0, -8.5, -75.0),
                    AXIS_LOW_HEAD_CUTTER(190.0, -8.5, -75.0))


command ROCKER_REAR_COMPONENT() -> solid:
    # C -> B = (-95, -35) mm. Complementary 8 mm center half-hubs join the
    # two bed-sized pieces within one 16 mm rocker band.
    let arm: solid = ARM_FILLETED(101.242284, 159.775141,
                                  -47.5, -8.5, -17.5)
    let center: solid = AXIS_BOSS_KEYED_HALF(0.0, -4.5, 0.0)
    let bogie: solid = AXIS_BOSS_BORE(-95.0, -8.5, -35.0)
    let joined: solid = union(arm, center, bogie,
                              BOGIE_LIMIT_MOUNT_EARS())
    emit difference(joined, AXIS_KEYED_CUTTERS(0.0, -4.5, 0.0),
                    AXIS_BOSS_HALF_BLANK(0.0, -12.5, 0.0),
                    AXIS_OUTBOARD_RETENTION_CUTTER(0.0, -8.5, 0.0),
                    BOGIE_LIMIT_SOCKET_CUTTERS(),
                    AXIS_BORE_CUTTERS(-95.0, -8.5, -35.0))


command ROCKER_FINISHED(side: int) -> solid:
    require side == -1 or side == 1, "side must be -1 (right) or +1 (left)"
    # Both split halves share the chassis-adjacent band y=98.5..114.5 mm on
    # the left. Their complementary half-hubs form one full-width pivot.
    let assembled: solid = compound(ROCKER_FRONT_COMPONENT(),
                                     ROCKER_REAR_COMPONENT())
    emit translate(assembled, 0.0, side * -40.0, 0.0)


command BOGIE_FINISHED(side: int) -> solid:
    require side == -1 or side == 1, "side must be -1 (right) or +1 (left)"
    let middle_arm: solid = ARM_FILLETED(103.077641, 22.833654,
                                         47.5, 0.0, -20.0)
    let rear_arm: solid = ARM_FILLETED(103.077641, 157.166346,
                                       -47.5, 0.0, -20.0)
    let pivot: solid = AXIS_BOSS_DUAL_608(0.0, 0.0, 0.0)
    let middle: solid = AXIS_BOSS_WHEEL_AXLE(95.0, 0.0, -40.0)
    let rear: solid = AXIS_BOSS_WHEEL_AXLE(-95.0, 0.0, -40.0)
    let joined: solid = union(middle_arm, rear_arm, pivot, middle, rear,
                              LIMIT_CONTACT_TAB(0.0))
    let assembled: solid = difference(
        joined,
        AXIS_DUAL_608_CUTTERS(0.0, 0.0, 0.0),
        AXIS_BORE_CUTTERS(95.0, 0.0, -40.0),
        AXIS_BORE_CUTTERS(-95.0, 0.0, -40.0),
        AXIS_LOW_HEAD_CUTTER(95.0, 0.0, -40.0),
        AXIS_LOW_HEAD_CUTTER(-95.0, 0.0, -40.0)
    )
    # Put the bogie in the adjacent outboard band. On the left it occupies
    # y=115.5..131.5 mm, with 1 mm rocker clearance and 5.5 mm wheel clearance.
    emit translate(assembled, 0.0, side * -31.5, 0.0)


command WHEEL_HUB() -> solid:
    # Ø130 x 36 mm rounded wheel with 10 mm rim, four crossing spokes,
    # paired 608 seats, and an Ø8.3 running bore.
    let outer: solid = fillet(cylinder(65.0, 36.0), 2.5)
    let rim_cutter: solid = translate(cylinder(55.0, 38.0), 0.0, 0.0, -1.0)
    let rim: solid = difference(outer, rim_cutter)
    let hub: solid = cylinder(18.0, 36.0)
    let spoke: solid = translate(box(112.0, 8.0, 8.0), 0.0, 0.0, 14.0)
    let angles: list<float> = [0.0, 45.0, 90.0, 135.0]
    let spokes: list<solid> = [rotate(spoke, 0.0, 0.0, a) for a in angles]
    let blank: solid = union_all([rim, hub] + spokes)
    let left_seat: solid = translate(cylinder(11.075, 7.4), 0.0, 0.0, -0.1)
    let right_seat: solid = translate(cylinder(11.075, 7.4),
                                      0.0, 0.0, 28.7)
    let bore: solid = translate(cylinder(4.15, 36.4), 0.0, 0.0, -0.2)
    let cut: solid = difference_all(blank, [left_seat, right_seat, bore])
    emit rotate(translate(cut, 0.0, 0.0, -18.0), -90.0, 0.0, 0.0)


@meta(material="PETG", component.id="wheel_130x36",
      component.name="Printed 130 x 36 mm rover wheel",
      component.disposition="make", manufacturing.process="FDM",
      assembly.datums=[
    {"id": "axle", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command LEFT_WHEEL() -> solid:
    # Wheel center lies on the annotated y=+155 mm axle plane, restoring the
    # original 310 mm track while retaining 5.5 mm link-to-wheel clearance.
    emit WHEEL_HUB()


@meta(material="PETG", component.id="wheel_130x36",
      component.name="Printed 130 x 36 mm rover wheel",
      component.disposition="make", manufacturing.process="FDM",
      assembly.datums=[
    {"id": "axle", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command RIGHT_WHEEL() -> solid:
    emit WHEEL_HUB()


# ---------------------------------------------------------------------------
# Metric running hardware.  The repeated BOM is deliberately compact: M8
# threaded rod, M8 nuts and washers, 608-2RS bearings, and 13 mm OD / 8.3 mm
# ID spacer tube. Wrapper commands retain one named axle datum per part.

command AXLE_SHAFT(length_mm: float, center_y: float) -> solid:
    # Threads are simplified as Ø7.9 cylinders, providing 0.2 mm diametral
    # running clearance in the Ø8.3 printed bores.
    let raw: solid = translate(cylinder(3.95, length_mm),
                               0.0, 0.0, -length_mm / 2.0)
    emit translate(rotate(raw, -90.0, 0.0, 0.0), 0.0, center_y, 0.0)


command SHAFT_KEY(length_mm: float, center_y: float) -> solid:
    # A 2 mm parallel key engages both split rocker halves but stops before
    # the inboard chassis bearing cartridge.
    emit translate(box(2.0, length_mm, 2.0), 0.0, center_y, 3.8)


command M8_WASHER(center_y: float) -> solid:
    let blank: solid = translate(cylinder(8.0, 1.6), 0.0, 0.0, -0.8)
    let bore: solid = translate(cylinder(4.2, 2.0), 0.0, 0.0, -1.0)
    emit translate(rotate(difference(blank, bore), -90.0, 0.0, 0.0),
                   0.0, center_y, 0.0)


command M8_RETAINING_CLIP(center_y: float) -> solid:
    let blank: solid = translate(cylinder(6.0, 1.2), 0.0, 0.0, -0.6)
    let bore: solid = translate(cylinder(4.1, 1.6), 0.0, 0.0, -0.8)
    let ring: solid = difference(blank, bore)
    emit translate(rotate(ring, -90.0, 0.0, 0.0), 0.0, center_y, 0.0)


command M8_NUT(center_y: float) -> solid:
    let centered: solid = translate(metric_hex_nut("M8"), 0.0, 0.0, -3.4)
    emit translate(rotate(centered, -90.0, 0.0, 0.0), 0.0, center_y, 0.0)


command M8_LOW_HEAD(center_y: float) -> solid:
    # Simplified Ø12.8 x 4 mm low-profile socket head. It sits 0.5 mm below
    # the link's inboard face in the matching Ø13.2 x 4.9 mm counterbore.
    let centered: solid = translate(cylinder(6.4, 4.0), 0.0, 0.0, -2.0)
    emit translate(rotate(centered, -90.0, 0.0, 0.0),
                   0.0, center_y, 0.0)


command AXLE_SPACER(length_mm: float, center_y: float) -> solid:
    let sleeve: solid = translate(cylinder(6.5, length_mm),
                                  0.0, 0.0, -length_mm / 2.0)
    let bore: solid = translate(cylinder(4.15, length_mm + 0.4),
                                0.0, 0.0, -length_mm / 2.0 - 0.2)
    let cut: solid = difference(sleeve, bore)
    emit translate(rotate(cut, -90.0, 0.0, 0.0), 0.0, center_y, 0.0)


command BEARING_608(center_y: float) -> solid:
    # Simplified but dimensionally faithful 608-2RS: Ø22 x 7 with Ø8.2 bore.
    let outer: solid = difference(cylinder(11.0, 7.0),
                                  cylinder(8.0, 7.0))
    let inner: solid = difference(cylinder(6.25, 7.0),
                                  cylinder(4.1, 7.0))
    let shield_blank: solid = translate(cylinder(8.0, 0.5), 0.0, 0.0, 0.25)
    let shield_bore: solid = translate(cylinder(6.25, 0.7),
                                       0.0, 0.0, 0.15)
    let shield: solid = difference(shield_blank, shield_bore)
    let far_shield: solid = translate(shield, 0.0, 0.0, 6.0)
    let bearing: solid = compound(outer, inner, shield, far_shield)
    let centered: solid = translate(bearing, 0.0, 0.0, -3.5)
    emit translate(rotate(centered, -90.0, 0.0, 0.0), 0.0, center_y, 0.0)


command LEFT_WHEEL_AXLE_SHAFT_GEOMETRY() -> solid:
    # Common M8 x 80 low-head axle bolt. The modeled shank runs from the
    # recessed head underside at y=-52 mm to y=+28 mm; no material projects
    # inboard of y=-56 mm, 0.5 mm inside the printed link face.
    emit compound(AXLE_SHAFT(80.0, -12.0), M8_LOW_HEAD(-54.0))


command LEFT_WHEEL_AXLE_SPACER_GEOMETRY() -> solid:
    # Bridges the common suspension band to the wheel's inboard bearing face.
    emit AXLE_SPACER(21.4, -29.25)


command LEFT_BOGIE_WHEEL_AXLE_SHAFT_GEOMETRY() -> solid:
    # The outboard bogie band uses a shorter standard M8 x 65 envelope.
    # Its recessed head starts at y=-39 mm and the shank ends at y=+30 mm.
    emit compound(AXLE_SHAFT(65.0, -2.5), M8_LOW_HEAD(-37.0))


command LEFT_BOGIE_WHEEL_AXLE_SPACER_GEOMETRY() -> solid:
    # The wheel remains on the common y=155 mm plane, leaving a short spacer
    # between the outboard bogie face and the wheel's inboard bearing.
    emit AXLE_SPACER(4.4, -20.75)


command LEFT_WHEEL_AXLE_HARDWARE_GEOMETRY() -> solid:
    # The recessed bolt head replaces the collision-prone inboard washer/nut.
    emit compound(M8_WASHER(18.9), M8_NUT(23.1))


command LEFT_WHEEL_BEARING_GEOMETRY() -> solid:
    emit compound(BEARING_608(-14.35), BEARING_608(14.35))


command LEFT_CHASSIS_PIVOT_BEARING_GEOMETRY() -> solid:
    emit compound(BEARING_608(-73.9), BEARING_608(-61.1))


command LEFT_BOGIE_PIVOT_BEARING_GEOMETRY() -> solid:
    # Follow the bogie into its outboard suspension band.
    emit compound(BEARING_608(-36.0), BEARING_608(-27.0))


@meta(material="alloy steel", component.id="wheel_axle_m8x80_low_head",
      component.name="M8 x 80 low-head wheel axle bolt",
      component.disposition="buy", procurement.specification="M8 x 80 low head",
      assembly.datums=[
    {"id": "axle", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command LEFT_WHEEL_AXLE_SHAFT() -> solid:
    emit LEFT_WHEEL_AXLE_SHAFT_GEOMETRY()


@meta(material="alloy steel", component.id="wheel_axle_m8x80_low_head_right",
      component.name="M8 x 80 low-head wheel axle bolt (right hand)",
      component.disposition="buy", procurement.specification="M8 x 80 low head",
      assembly.datums=[
    {"id": "axle", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command RIGHT_WHEEL_AXLE_SHAFT() -> solid:
    emit mirror(LEFT_WHEEL_AXLE_SHAFT_GEOMETRY(), vector(0.0, 1.0, 0.0))


@meta(material="alloy steel", component.id="bogie_wheel_axle_m8x65_low_head",
      component.name="M8 x 65 low-head bogie wheel axle bolt",
      component.disposition="buy", procurement.specification="M8 x 65 low head",
      assembly.datums=[
    {"id": "axle", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command LEFT_BOGIE_WHEEL_AXLE_SHAFT() -> solid:
    emit LEFT_BOGIE_WHEEL_AXLE_SHAFT_GEOMETRY()


@meta(material="alloy steel",
      component.id="bogie_wheel_axle_m8x65_low_head_right",
      component.name="M8 x 65 low-head bogie wheel axle bolt (right hand)",
      component.disposition="buy", procurement.specification="M8 x 65 low head",
      assembly.datums=[
    {"id": "axle", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command RIGHT_BOGIE_WHEEL_AXLE_SHAFT() -> solid:
    emit mirror(LEFT_BOGIE_WHEEL_AXLE_SHAFT_GEOMETRY(),
                vector(0.0, 1.0, 0.0))


@meta(material="steel spacer tube", component.id="wheel_spacer_13x8p3x21p4",
      component.name="Wheel axle spacer, 13 x 8.3 x 21.4 mm",
      component.disposition="raw_stock", manufacturing.process="cut_to_length",
      assembly.datums=[
    {"id": "axle", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command LEFT_WHEEL_AXLE_SPACER() -> solid:
    emit LEFT_WHEEL_AXLE_SPACER_GEOMETRY()


@meta(material="steel spacer tube", component.id="wheel_spacer_13x8p3x21p4_right",
      component.name="Wheel axle spacer, 13 x 8.3 x 21.4 mm (right hand)",
      component.disposition="raw_stock", manufacturing.process="cut_to_length",
      assembly.datums=[
    {"id": "axle", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command RIGHT_WHEEL_AXLE_SPACER() -> solid:
    emit mirror(LEFT_WHEEL_AXLE_SPACER_GEOMETRY(), vector(0.0, 1.0, 0.0))


@meta(material="steel spacer tube", component.id="bogie_wheel_spacer_4p4mm",
      component.name="Bogie wheel axle spacer, 13 x 8.3 x 4.4 mm",
      component.disposition="raw_stock", manufacturing.process="cut_to_length",
      assembly.datums=[
    {"id": "axle", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command LEFT_BOGIE_WHEEL_AXLE_SPACER() -> solid:
    emit LEFT_BOGIE_WHEEL_AXLE_SPACER_GEOMETRY()


@meta(material="steel spacer tube",
      component.id="bogie_wheel_spacer_4p4mm_right",
      component.name="Bogie wheel axle spacer, 13 x 8.3 x 4.4 mm (right hand)",
      component.disposition="raw_stock", manufacturing.process="cut_to_length",
      assembly.datums=[
    {"id": "axle", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command RIGHT_BOGIE_WHEEL_AXLE_SPACER() -> solid:
    emit mirror(LEFT_BOGIE_WHEEL_AXLE_SPACER_GEOMETRY(),
                vector(0.0, 1.0, 0.0))


@meta(material="zinc-plated steel", component.id="wheel_axle_retention_m8",
      component.name="M8 wheel axle washer and nyloc retention set",
      component.disposition="buy", procurement.specification="M8 metric",
      assembly.datums=[
    {"id": "axle", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command LEFT_WHEEL_AXLE_HARDWARE() -> solid:
    emit LEFT_WHEEL_AXLE_HARDWARE_GEOMETRY()


@meta(material="zinc-plated steel", component.id="wheel_axle_retention_m8_right",
      component.name="M8 wheel axle washer and nyloc retention set (right hand)",
      component.disposition="buy", procurement.specification="M8 metric",
      assembly.datums=[
    {"id": "axle", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command RIGHT_WHEEL_AXLE_HARDWARE() -> solid:
    emit mirror(LEFT_WHEEL_AXLE_HARDWARE_GEOMETRY(), vector(0.0, 1.0, 0.0))


@meta(material="608-2RS steel / rubber", component.id="bearing_608_wheel_pair",
      component.name="608-2RS wheel bearing pair", component.disposition="buy",
      component.quantity=2.0, procurement.specification="608-2RS",
      assembly.datums=[
    {"id": "axle", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command LEFT_WHEEL_BEARINGS() -> solid:
    emit LEFT_WHEEL_BEARING_GEOMETRY()


@meta(material="608-2RS steel / rubber", component.disposition="buy",
      component.quantity=2.0, procurement.specification="608-2RS", assembly.datums=[
    {"id": "axle", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command RIGHT_WHEEL_BEARINGS() -> solid:
    emit LEFT_WHEEL_BEARING_GEOMETRY()


@meta(material="608-2RS steel / rubber", component.disposition="buy",
      component.quantity=2.0, procurement.specification="608-2RS", assembly.datums=[
    {"id": "axle", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command LEFT_CHASSIS_PIVOT_BEARINGS() -> solid:
    emit LEFT_CHASSIS_PIVOT_BEARING_GEOMETRY()


@meta(material="608-2RS steel / rubber", component.disposition="buy",
      component.quantity=2.0, procurement.specification="608-2RS", assembly.datums=[
    {"id": "axle", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command RIGHT_CHASSIS_PIVOT_BEARINGS() -> solid:
    emit mirror(LEFT_CHASSIS_PIVOT_BEARING_GEOMETRY(),
                vector(0.0, 1.0, 0.0))


@meta(material="608-2RS steel / rubber", component.disposition="buy",
      component.quantity=2.0, procurement.specification="608-2RS", assembly.datums=[
    {"id": "axle", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command LEFT_BOGIE_PIVOT_BEARINGS() -> solid:
    emit LEFT_BOGIE_PIVOT_BEARING_GEOMETRY()


@meta(material="608-2RS steel / rubber", component.disposition="buy",
      component.quantity=2.0, procurement.specification="608-2RS", assembly.datums=[
    {"id": "axle", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command RIGHT_BOGIE_PIVOT_BEARINGS() -> solid:
    emit mirror(LEFT_BOGIE_PIVOT_BEARING_GEOMETRY(),
                vector(0.0, 1.0, 0.0))


command LEFT_ROCKER_PIVOT_SHAFT_GEOMETRY() -> solid:
    # Ends flush with the recessed outboard clip stack at the single rocker
    # band's outer face; the middle wheel is another 22.5 mm outboard.
    emit AXLE_SHAFT(106.5, -93.75)


command LEFT_ROCKER_PIVOT_KEYS_GEOMETRY() -> solid:
    # Stop at the bottom of the recessed washer/clip pocket.
    emit compound(SHAFT_KEY(12.5, -50.25),
                  SHAFT_KEY(8.5, -138.75))


command LEFT_ROCKER_PIVOT_HARDWARE_GEOMETRY() -> solid:
    emit compound(M8_RETAINING_CLIP(-143.8),
                  M8_WASHER(-42.85), M8_RETAINING_CLIP(-41.35))


command LEFT_BOGIE_PIVOT_SHAFT_GEOMETRY() -> solid:
    emit AXLE_SHAFT(51.5, -40.75)


command LEFT_BOGIE_PIVOT_HARDWARE_GEOMETRY() -> solid:
    emit compound(M8_WASHER(-57.4), M8_NUT(-61.6),
                  M8_WASHER(-22.6), M8_NUT(-18.4))


@meta(material="8 mm steel rod", component.disposition="raw_stock",
      manufacturing.process="cut_to_length", assembly.datums=[
    {"id": "axle", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command LEFT_ROCKER_PIVOT_SHAFT() -> solid:
    emit LEFT_ROCKER_PIVOT_SHAFT_GEOMETRY()


@meta(material="8 mm steel rod", component.disposition="raw_stock",
      manufacturing.process="cut_to_length", assembly.datums=[
    {"id": "axle", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command RIGHT_ROCKER_PIVOT_SHAFT() -> solid:
    emit mirror(LEFT_ROCKER_PIVOT_SHAFT_GEOMETRY(), vector(0.0, 1.0, 0.0))


@meta(material="8 mm steel rod", component.disposition="raw_stock",
      manufacturing.process="cut_to_length", assembly.datums=[
    {"id": "axle", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command LEFT_BOGIE_PIVOT_SHAFT() -> solid:
    emit LEFT_BOGIE_PIVOT_SHAFT_GEOMETRY()


@meta(material="8 mm steel rod", component.disposition="raw_stock",
      manufacturing.process="cut_to_length", assembly.datums=[
    {"id": "axle", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command RIGHT_BOGIE_PIVOT_SHAFT() -> solid:
    emit mirror(LEFT_BOGIE_PIVOT_SHAFT_GEOMETRY(), vector(0.0, 1.0, 0.0))


@meta(material="2 mm steel key stock", component.disposition="raw_stock",
      manufacturing.process="cut_to_length", assembly.datums=[
    {"id": "axle", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command LEFT_ROCKER_PIVOT_KEYS() -> solid:
    emit LEFT_ROCKER_PIVOT_KEYS_GEOMETRY()


@meta(material="2 mm steel key stock", component.disposition="raw_stock",
      manufacturing.process="cut_to_length", assembly.datums=[
    {"id": "axle", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command RIGHT_ROCKER_PIVOT_KEYS() -> solid:
    emit mirror(LEFT_ROCKER_PIVOT_KEYS_GEOMETRY(), vector(0.0, 1.0, 0.0))


@meta(material="zinc-plated steel", component.disposition="buy",
      procurement.specification="M8 metric", assembly.datums=[
    {"id": "axle", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command LEFT_ROCKER_PIVOT_HARDWARE() -> solid:
    emit LEFT_ROCKER_PIVOT_HARDWARE_GEOMETRY()


@meta(material="zinc-plated steel", component.disposition="buy",
      procurement.specification="M8 metric", assembly.datums=[
    {"id": "axle", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command RIGHT_ROCKER_PIVOT_HARDWARE() -> solid:
    emit mirror(LEFT_ROCKER_PIVOT_HARDWARE_GEOMETRY(), vector(0.0, 1.0, 0.0))


@meta(material="zinc-plated steel", component.disposition="buy",
      procurement.specification="M8 metric", assembly.datums=[
    {"id": "axle", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command LEFT_BOGIE_PIVOT_HARDWARE() -> solid:
    emit LEFT_BOGIE_PIVOT_HARDWARE_GEOMETRY()


@meta(material="zinc-plated steel", component.disposition="buy",
      procurement.specification="M8 metric", assembly.datums=[
    {"id": "axle", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command RIGHT_BOGIE_PIVOT_HARDWARE() -> solid:
    emit mirror(LEFT_BOGIE_PIVOT_HARDWARE_GEOMETRY(), vector(0.0, 1.0, 0.0))


# ---------------------------------------------------------------------------
# Compact spherical-involute straight-bevel differential. All four gears share
# one pitch apex at the chassis origin. The side gears are keyed to the rocker
# shafts; each planet has a plain running bore and its own revolute joint on the
# fixed cross-pin. The 0.25 mm backlash is the printable PET-G starting value.

command MITER_GEAR_BLANK() -> solid:
    emit miter_gear(
        teeth=24,
        outer_module_mm=1.5,
        face_width_mm=8.0,
        pressure_angle_deg=20.0,
        backlash_mm=0.25,
        bore_diameter_mm=8.4,
        generation_type="spherical_involute"
    )


command MITER_SIDE_GEAR_Z() -> solid:
    let blank: solid = MITER_GEAR_BLANK()
    # After the -90 degree X rotation used by the side-gear wrappers, local
    # -Y becomes chassis +Z.  Center the 2.2 mm keyway there so it clears the
    # 2.0 mm parallel key on the rocker shaft by 0.1 mm per side.  The bevel
    # gear body occupies local Z=12.3..18.0 mm, so the cutter spans that full
    # axial interval rather than stopping short of the gear.
    let keyway: solid = translate(box(2.2, 2.2, 12.0),
                                  0.0, -3.8, 15.0)
    emit difference(blank, keyway)


command MITER_PLANET_GEAR_Z() -> solid:
    # Extend the back face into a Ø16 mm thrust hub.  The hub ends 1.5 mm
    # inboard of the carrier tower, leaving room for a 1 mm low-friction
    # washer and 0.5 mm total axial running clearance.
    let blank: solid = MITER_GEAR_BLANK()
    let hub: solid = translate(cylinder(8.0, 9.0), 0.0, 0.0, 17.5)
    let bore: solid = translate(cylinder(4.2, 15.0), 0.0, 0.0, 12.0)
    emit difference(union(blank, hub), bore)


command LEFT_DIFFERENTIAL_SIDE_GEAR_GEOMETRY() -> solid:
    # The part datum is solved to y=+155. Translate the pitch apex back to the
    # chassis origin and point the gear body outward along +Y.
    let on_y: solid = rotate(MITER_SIDE_GEAR_Z(), -90.0, 0.0, 0.0)
    emit translate(on_y, 0.0, -155.0, 0.0)


command FRONT_DIFFERENTIAL_PLANET_GEAR_GEOMETRY() -> solid:
    # Core pair convention: the +X mate is phased by half a tooth pitch.
    let on_x: solid = rotate(MITER_PLANET_GEAR_Z(), 0.0, 90.0, 0.0)
    emit rotate(on_x, 7.5, 0.0, 0.0)


command REAR_DIFFERENTIAL_PLANET_GEAR_GEOMETRY() -> solid:
    emit mirror(FRONT_DIFFERENTIAL_PLANET_GEAR_GEOMETRY(),
                vector(1.0, 0.0, 0.0))


@meta(material="PETG replaceable gear", component.disposition="make",
      manufacturing.process="FDM", assembly.datums=[
    {"id": "axis", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command LEFT_DIFFERENTIAL_SIDE_GEAR() -> solid:
    emit LEFT_DIFFERENTIAL_SIDE_GEAR_GEOMETRY()


@meta(material="PETG replaceable gear", component.disposition="make",
      manufacturing.process="FDM", assembly.datums=[
    {"id": "axis", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command RIGHT_DIFFERENTIAL_SIDE_GEAR() -> solid:
    emit mirror(LEFT_DIFFERENTIAL_SIDE_GEAR_GEOMETRY(),
                vector(0.0, 1.0, 0.0))


@meta(material="PETG replaceable gear", component.disposition="make",
      manufacturing.process="FDM", assembly.datums=[
    {"id": "axis", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [1.0, 0.0, 0.0]}
])
command FRONT_DIFFERENTIAL_PLANET_GEAR() -> solid:
    emit FRONT_DIFFERENTIAL_PLANET_GEAR_GEOMETRY()


@meta(material="PETG replaceable gear", component.disposition="make",
      manufacturing.process="FDM", assembly.datums=[
    {"id": "axis", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [1.0, 0.0, 0.0]}
])
command REAR_DIFFERENTIAL_PLANET_GEAR() -> solid:
    emit REAR_DIFFERENTIAL_PLANET_GEAR_GEOMETRY()


@meta(material="608-2RS steel / rubber", component.disposition="buy",
      component.quantity=2.0, procurement.specification="608-2RS", assembly.datums=[
    {"id": "axis", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command DIFFERENTIAL_CARRIER_BEARINGS() -> solid:
    emit compound(BEARING_608(32.0), BEARING_608(-32.0))


@meta(material="8 mm shoulder screw and locknut", component.disposition="buy",
      procurement.specification="M8 shoulder bolt", assembly.datums=[
    {"id": "axis", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [1.0, 0.0, 0.0]}
])
command DIFFERENTIAL_CROSS_PIN() -> solid:
    # A smooth Ø7.9 x 72 mm shoulder carries the planet gears.  The modeled
    # head and locknut bear only on the outside faces of the carrier towers,
    # so tightening the pin cannot clamp either rotating planet.
    let raw: solid = translate(cylinder(3.95, 72.0), 0.0, 0.0, -36.0)
    let head: solid = translate(cylinder(6.5, 5.0), 0.0, 0.0, -41.0)
    let thread: solid = translate(cylinder(3.0, 5.0), 0.0, 0.0, 36.0)
    let locknut: solid = translate(cylinder(5.5, 5.0), 0.0, 0.0, 36.0)
    emit rotate(compound(raw, head, thread, locknut), 0.0, 90.0, 0.0)


@meta(material="M8 low-friction thrust washer", component.disposition="buy",
      component.quantity=2.0, procurement.specification="M8 thrust washer",
      assembly.datums=[
    {"id": "axis", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [1.0, 0.0, 0.0]}
])
command DIFFERENTIAL_PLANET_THRUST_WASHERS() -> solid:
    let disk: solid = difference(cylinder(8.0, 1.0),
                                 cylinder(4.15, 1.0))
    let centered: solid = translate(disk, 0.0, 0.0, -0.5)
    let on_x: solid = rotate(centered, 0.0, 90.0, 0.0)
    emit compound(translate(on_x, 27.2, 0.0, 0.0),
                  translate(on_x, -27.2, 0.0, 0.0))


command DIFFERENTIAL_BEARING_PLATE(side: int) -> solid:
    require side == -1 or side == 1, "side must be -1 or +1"
    let plate: solid = fillet(translate(box(60.0, 8.0, 58.0),
                                        0.0, side * 32.0, 0.0), 3.0)
    let cutter_raw: solid = translate(cylinder(11.15, 10.0),
                                      0.0, 0.0, -5.0)
    let cutter: solid = translate(
        rotate(cutter_raw, -90.0, 0.0, 0.0),
        0.0, side * 32.0, 0.0
    )
    emit difference(plate, cutter)


command DIFFERENTIAL_PIN_TOWER(side: int) -> solid:
    require side == -1 or side == 1, "side must be -1 or +1"
    let tower: solid = fillet(translate(box(8.0, 20.0, 50.0),
                                        side * 32.0, 0.0, 0.0), 2.0)
    let cutter_raw: solid = translate(cylinder(4.2, 10.0),
                                      0.0, 0.0, -5.0)
    let cutter: solid = translate(
        rotate(cutter_raw, 0.0, 90.0, 0.0),
        side * 32.0, 0.0, 0.0
    )
    emit difference(tower, cutter)


command DIFFERENTIAL_CRADLE() -> solid:
    let left_rail: solid = fillet(translate(box(12.0, 80.0, 8.0),
                                            -32.0, 0.0, -15.0), 2.0)
    let right_rail: solid = fillet(translate(box(12.0, 80.0, 8.0),
                                             32.0, 0.0, -15.0), 2.0)
    # Four outboard feet bridge from the rails onto intact chassis floor
    # outside the central cartridge opening.
    let foot: solid = fillet(translate(box(12.0, 16.0, 8.0),
                                       44.0, 28.0, -15.0), 2.0)
    let frame: solid = union(left_rail, right_rail,
                             foot,
                             mirror(foot, vector(0.0, 1.0, 0.0)),
                             mirror(foot, vector(1.0, 0.0, 0.0)),
                             mirror(mirror(foot, vector(1.0, 0.0, 0.0)),
                                    vector(0.0, 1.0, 0.0)),
                             DIFFERENTIAL_BEARING_PLATE(1),
                             DIFFERENTIAL_BEARING_PLATE(-1),
                             DIFFERENTIAL_PIN_TOWER(1),
                             DIFFERENTIAL_PIN_TOWER(-1))
    emit difference(frame, DIFFERENTIAL_CRADLE_FASTENER_CUTTERS())


command DIFFERENTIAL_CRADLE_FASTENER_CUTTERS() -> solid:
    let hole: solid = translate(cylinder(2.2, 24.0), 0.0, 0.0, -30.0)
    emit compound(translate(hole, 44.0, 28.0, 0.0),
                  translate(hole, 44.0, -28.0, 0.0),
                  translate(hole, -44.0, 28.0, 0.0),
                  translate(hole, -44.0, -28.0, 0.0))


@meta(material="M4 x 20 steel screw and nyloc nut", component.disposition="buy",
      component.quantity=4.0, procurement.specification="M4 x 20", assembly.datums=[
    {"id": "mount", "kind": "point", "origin_mm": [0.0, 0.0, 0.0]}
])
command DIFFERENTIAL_CRADLE_FASTENERS() -> solid:
    let shaft: solid = translate(cylinder(2.0, 18.0), 0.0, 0.0, -29.0)
    let head: solid = translate(cylinder(3.5, 3.0), 0.0, 0.0, -11.0)
    let nut: solid = translate(cylinder(4.0, 4.0), 0.0, 0.0, -29.0)
    let fastener: solid = compound(shaft, head, nut)
    emit compound(translate(fastener, 44.0, 28.0, 0.0),
                  translate(fastener, 44.0, -28.0, 0.0),
                  translate(fastener, -44.0, 28.0, 0.0),
                  translate(fastener, -44.0, -28.0, 0.0))


@meta(material="PETG", component.disposition="make",
      manufacturing.process="FDM", assembly.datums=[
    {"id": "mount", "kind": "point", "origin_mm": [0.0, 0.0, 0.0]},
    {"id": "differential_axis", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]},
    {"id": "planet_axis", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [1.0, 0.0, 0.0]}
])
command DIFFERENTIAL_CRADLE_FINISHED() -> solid:
    emit DIFFERENTIAL_CRADLE()


command CHASSIS_PIVOT_CUTTERS(side: int) -> solid:
    require side == -1 or side == 1, "side must be -1 (right) or +1 (left)"
    let first: solid = translate(cylinder(11.075, 7.4), 0.0, 0.0, -0.1)
    let second: solid = translate(cylinder(11.075, 7.4), 0.0, 0.0, 12.7)
    let bore: solid = translate(cylinder(4.15, 20.4), 0.0, 0.0, -0.2)
    let centered: solid = translate(union(first, second, bore),
                                    0.0, 0.0, -10.0)
    let on_y: solid = rotate(centered, -90.0, 0.0, 0.0)
    emit translate(on_y, 0.0, side * 87.5, 0.0)


command CHASSIS_PIVOT_CARTRIDGE(side: int) -> solid:
    let boss: solid = fillet(cylinder(18.0, 20.0), 1.5)
    let centered: solid = translate(boss, 0.0, 0.0, -10.0)
    let on_y: solid = rotate(centered, -90.0, 0.0, 0.0)
    let placed: solid = translate(on_y, 0.0, side * 87.5, 0.0)
    emit difference(placed, CHASSIS_PIVOT_CUTTERS(side))


command CHASSIS_TUB() -> solid:
    # One 205 x 195 x 110 mm open tub: 4 mm walls and a 6 mm floor.  Its
    # bottom is z=-25, preserving 115 mm belly clearance in the level pose.
    let rounded: solid = fillet(box(205.0, 195.0, 110.0), 4.0)
    let outer: solid = translate(rounded, 0.0, 0.0, 30.0)
    let cavity: solid = translate(box(197.0, 187.0, 104.0),
                                  0.0, 0.0, 33.0)
    emit difference(outer, cavity)


command DIFFERENTIAL_FLOOR_CLEARANCE() -> solid:
    # Clear the full carrier plates below the gear axis. Outboard feet at
    # x=+/-44 mm land on intact floor beyond this 76 mm opening.
    emit translate(box(76.0, 90.0, 20.0), 0.0, 0.0, -20.0)


command CHASSIS_CUT_TUB() -> solid:
    emit difference(CHASSIS_TUB(),
                    CHASSIS_PIVOT_CUTTERS(1),
                    CHASSIS_PIVOT_CUTTERS(-1),
                    DIFFERENTIAL_FLOOR_CLEARANCE(),
                    ROCKER_LIMIT_SOCKET_CUTTERS(),
                    DIFFERENTIAL_CRADLE_FASTENER_CUTTERS())


command CHASSIS_FRONT_SEGMENT() -> solid:
    let halfspace: solid = translate(box(102.5, 200.0, 120.0),
                                     51.25, 0.0, 30.0)
    emit intersection(CHASSIS_CUT_TUB(), halfspace)


command CHASSIS_REAR_SEGMENT() -> solid:
    let halfspace: solid = translate(box(102.5, 200.0, 120.0),
                                     -51.25, 0.0, 30.0)
    emit intersection(CHASSIS_CUT_TUB(), halfspace)


command CHASSIS_SPLICE_KEYS() -> solid:
    # Keep the keys flush with the outer wall (y=+/-97.5) so the rocker
    # limit tongue retains the designed 1 mm nominal lateral clearance.
    let left_low: solid = fillet(translate(box(30.0, 8.0, 12.0),
                                           0.0, 93.5, 25.0), 2.0)
    let left_high: solid = translate(left_low, 0.0, 0.0, 30.0)
    let right_low: solid = mirror(left_low, vector(0.0, 1.0, 0.0))
    let right_high: solid = mirror(left_high, vector(0.0, 1.0, 0.0))
    emit compound(left_low, left_high, right_low, right_high)


command CHASSIS_SIDE_INTERFACE(side: int) -> solid:
    require side == -1 or side == 1, "side must be -1 (right) or +1 (left)"
    # The paired-bearing cartridge is supported at the tub wall.  A future
    # M8 shaft runs from here to the annotated pivot at y=+/-155; keeping the
    # printed housing inboard avoids the middle wheel envelope entirely.
    emit CHASSIS_PIVOT_CARTRIDGE(side)


@meta(
    material="PETG",
    component.disposition="make",
    manufacturing.process="FDM",
    assembly.datums=[
        {"id": "left_rocker", "kind": "axis",
         "origin_mm": [0.0, 155.0, 0.0], "direction": [0.0, 1.0, 0.0]},
        {"id": "right_rocker", "kind": "axis",
         "origin_mm": [0.0, -155.0, 0.0], "direction": [0.0, 1.0, 0.0]},
        {"id": "payload_frame", "kind": "point",
         "origin_mm": [0.0, 0.0, 85.0]},
        {"id": "differential_axis", "kind": "axis",
         "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]},
        {"id": "planet_axis", "kind": "axis",
         "origin_mm": [0.0, 0.0, 0.0], "direction": [1.0, 0.0, 0.0]},
        {"id": "differential_mount", "kind": "point",
         "origin_mm": [0.0, 0.0, 0.0]}
    ]
)
command CHASSIS_FINISHED() -> solid:
    emit compound(CHASSIS_FRONT_SEGMENT(), CHASSIS_REAR_SEGMENT(),
                  CHASSIS_SIDE_INTERFACE(1), CHASSIS_SIDE_INTERFACE(-1),
                  CHASSIS_SPLICE_KEYS())


@meta(material="TPU 95A", component.id="left_rocker_limit_bumper_pair",
      component.name="Left rocker replaceable limit-bumper pair",
      component.disposition="make", manufacturing.process="FDM",
      manufacturing.instructions="Print solid in TPU 95A; press stems into chassis sockets",
      assembly.datums=[
    {"id": "joint_axis", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command LEFT_ROCKER_LIMIT_BUMPERS() -> solid:
    emit LEFT_ROCKER_LIMIT_BUMPER_GEOMETRY()


@meta(material="TPU 95A", component.id="right_rocker_limit_bumper_pair",
      component.name="Right rocker replaceable limit-bumper pair",
      component.disposition="make", manufacturing.process="FDM",
      manufacturing.instructions="Print solid in TPU 95A; press stems into chassis sockets",
      assembly.datums=[
    {"id": "joint_axis", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command RIGHT_ROCKER_LIMIT_BUMPERS() -> solid:
    emit mirror(LEFT_ROCKER_LIMIT_BUMPER_GEOMETRY(),
                vector(0.0, 1.0, 0.0))


@meta(material="TPU 95A", component.id="left_bogie_limit_bumper_pair",
      component.name="Left bogie replaceable limit-bumper pair",
      component.disposition="make", manufacturing.process="FDM",
      manufacturing.instructions="Print solid in TPU 95A; press stems into rocker sockets",
      assembly.datums=[
    {"id": "joint_axis", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command LEFT_BOGIE_LIMIT_BUMPERS() -> solid:
    emit LEFT_BOGIE_LIMIT_BUMPER_GEOMETRY()


@meta(material="TPU 95A", component.id="right_bogie_limit_bumper_pair",
      component.name="Right bogie replaceable limit-bumper pair",
      component.disposition="make", manufacturing.process="FDM",
      manufacturing.instructions="Print solid in TPU 95A; press stems into rocker sockets",
      assembly.datums=[
    {"id": "joint_axis", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command RIGHT_BOGIE_LIMIT_BUMPERS() -> solid:
    emit mirror(LEFT_BOGIE_LIMIT_BUMPER_GEOMETRY(),
                vector(0.0, 1.0, 0.0))


command DIFFERENTIAL_CARTRIDGE_PREVIEW() -> solid:
    # The gear and shaft part definitions are local to their rocker datums.
    # Place them at the chassis pivot locations here so the removable cradle
    # can be inspected and exported without the surrounding rover obscuring it.
    let left_gear: solid = translate(
        LEFT_DIFFERENTIAL_SIDE_GEAR_GEOMETRY(), 0.0, 155.0, 0.0
    )
    let right_gear: solid = translate(
        mirror(LEFT_DIFFERENTIAL_SIDE_GEAR_GEOMETRY(),
               vector(0.0, 1.0, 0.0)),
        0.0, -155.0, 0.0
    )
    let left_shaft: solid = translate(
        LEFT_ROCKER_PIVOT_SHAFT_GEOMETRY(), 0.0, 155.0, 0.0
    )
    let right_shaft: solid = translate(
        mirror(LEFT_ROCKER_PIVOT_SHAFT_GEOMETRY(),
               vector(0.0, 1.0, 0.0)),
        0.0, -155.0, 0.0
    )
    emit compound(DIFFERENTIAL_CRADLE(), DIFFERENTIAL_CRADLE_FASTENERS(),
                  DIFFERENTIAL_CARRIER_BEARINGS(),
                  DIFFERENTIAL_CROSS_PIN(),
                  DIFFERENTIAL_PLANET_THRUST_WASHERS(),
                  FRONT_DIFFERENTIAL_PLANET_GEAR_GEOMETRY(),
                  REAR_DIFFERENTIAL_PLANET_GEAR_GEOMETRY(),
                  left_gear, right_gear, left_shaft, right_shaft)


@meta(material="PETG", component.disposition="make", manufacturing.process="FDM",
      assembly.datums=[
    {"id": "chassis_pivot", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]},
    {"id": "front_axle", "kind": "axis",
     "origin_mm": [190.0, 0.0, -75.0], "direction": [0.0, 1.0, 0.0]},
    {"id": "bogie_pivot", "kind": "axis",
     "origin_mm": [-95.0, 0.0, -35.0], "direction": [0.0, 1.0, 0.0]}
])
command LEFT_ROCKER() -> solid:
    emit ROCKER_FINISHED(1)


@meta(material="PETG", component.disposition="make", manufacturing.process="FDM",
      assembly.datums=[
    {"id": "chassis_pivot", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]},
    {"id": "front_axle", "kind": "axis",
     "origin_mm": [190.0, 0.0, -75.0], "direction": [0.0, 1.0, 0.0]},
    {"id": "bogie_pivot", "kind": "axis",
     "origin_mm": [-95.0, 0.0, -35.0], "direction": [0.0, 1.0, 0.0]}
])
command RIGHT_ROCKER() -> solid:
    # Mirror the keyed front/rear layers as well as moving the link inboard;
    # translating alone would reverse their intended axial stack on this side.
    let assembled: solid = compound(ROCKER_FRONT_COMPONENT(),
                                     ROCKER_REAR_COMPONENT())
    let mirrored: solid = mirror(assembled, vector(0.0, 1.0, 0.0))
    emit translate(mirrored, 0.0, 40.0, 0.0)


@meta(material="PETG", component.disposition="make", manufacturing.process="FDM",
      assembly.datums=[
    {"id": "rocker_pivot", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]},
    {"id": "middle_axle", "kind": "axis",
     "origin_mm": [95.0, 0.0, -40.0], "direction": [0.0, 1.0, 0.0]},
    {"id": "rear_axle", "kind": "axis",
     "origin_mm": [-95.0, 0.0, -40.0], "direction": [0.0, 1.0, 0.0]}
])
command LEFT_BOGIE() -> solid:
    emit BOGIE_FINISHED(1)


@meta(material="PETG", component.disposition="make", manufacturing.process="FDM",
      assembly.datums=[
    {"id": "rocker_pivot", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]},
    {"id": "middle_axle", "kind": "axis",
     "origin_mm": [95.0, 0.0, -40.0], "direction": [0.0, 1.0, 0.0]},
    {"id": "rear_axle", "kind": "axis",
     "origin_mm": [-95.0, 0.0, -40.0], "direction": [0.0, 1.0, 0.0]}
])
command RIGHT_BOGIE() -> solid:
    # Mirror the left-hand finished part so its recessed axle heads remain on
    # the chassis-facing side; translation alone would leave both pockets on
    # negative Y.
    emit mirror(BOGIE_FINISHED(1), vector(0.0, 1.0, 0.0))


command BUILD_DETAILED_SUSPENSION(rocker_angle: float = 0.0) -> solid:
    let rover: assembly = assembly("yaprover_suspension_detailed")
    add_part(rover, CHASSIS_FINISHED(), "chassis")
    add_part(rover, LEFT_ROCKER(), "left_rocker")
    add_part(rover, RIGHT_ROCKER(), "right_rocker")
    add_part(rover, LEFT_BOGIE(), "left_bogie")
    add_part(rover, RIGHT_BOGIE(), "right_bogie")
    add_part(rover, LEFT_ROCKER_LIMIT_BUMPERS(),
             "left_rocker_limit_bumpers")
    add_part(rover, RIGHT_ROCKER_LIMIT_BUMPERS(),
             "right_rocker_limit_bumpers")
    add_part(rover, LEFT_BOGIE_LIMIT_BUMPERS(),
             "left_bogie_limit_bumpers")
    add_part(rover, RIGHT_BOGIE_LIMIT_BUMPERS(),
             "right_bogie_limit_bumpers")
    add_part(rover, LEFT_WHEEL(), "left_front_wheel")
    add_part(rover, LEFT_WHEEL(), "left_middle_wheel")
    add_part(rover, LEFT_WHEEL(), "left_rear_wheel")
    add_part(rover, RIGHT_WHEEL(), "right_front_wheel")
    add_part(rover, RIGHT_WHEEL(), "right_middle_wheel")
    add_part(rover, RIGHT_WHEEL(), "right_rear_wheel")
    add_part(rover, LEFT_WHEEL_AXLE_SHAFT(), "left_front_shaft")
    add_part(rover, LEFT_BOGIE_WHEEL_AXLE_SHAFT(), "left_middle_shaft")
    add_part(rover, LEFT_BOGIE_WHEEL_AXLE_SHAFT(), "left_rear_shaft")
    add_part(rover, RIGHT_WHEEL_AXLE_SHAFT(), "right_front_shaft")
    add_part(rover, RIGHT_BOGIE_WHEEL_AXLE_SHAFT(), "right_middle_shaft")
    add_part(rover, RIGHT_BOGIE_WHEEL_AXLE_SHAFT(), "right_rear_shaft")
    add_part(rover, LEFT_WHEEL_AXLE_SPACER(), "left_front_spacer")
    add_part(rover, LEFT_BOGIE_WHEEL_AXLE_SPACER(), "left_middle_spacer")
    add_part(rover, LEFT_BOGIE_WHEEL_AXLE_SPACER(), "left_rear_spacer")
    add_part(rover, RIGHT_WHEEL_AXLE_SPACER(), "right_front_spacer")
    add_part(rover, RIGHT_BOGIE_WHEEL_AXLE_SPACER(), "right_middle_spacer")
    add_part(rover, RIGHT_BOGIE_WHEEL_AXLE_SPACER(), "right_rear_spacer")
    add_part(rover, LEFT_WHEEL_AXLE_HARDWARE(), "left_front_axle_hardware")
    add_part(rover, LEFT_WHEEL_AXLE_HARDWARE(), "left_middle_axle_hardware")
    add_part(rover, LEFT_WHEEL_AXLE_HARDWARE(), "left_rear_axle_hardware")
    add_part(rover, RIGHT_WHEEL_AXLE_HARDWARE(), "right_front_axle_hardware")
    add_part(rover, RIGHT_WHEEL_AXLE_HARDWARE(), "right_middle_axle_hardware")
    add_part(rover, RIGHT_WHEEL_AXLE_HARDWARE(), "right_rear_axle_hardware")
    add_part(rover, LEFT_WHEEL_BEARINGS(), "left_front_bearings")
    add_part(rover, LEFT_WHEEL_BEARINGS(), "left_middle_bearings")
    add_part(rover, LEFT_WHEEL_BEARINGS(), "left_rear_bearings")
    add_part(rover, RIGHT_WHEEL_BEARINGS(), "right_front_bearings")
    add_part(rover, RIGHT_WHEEL_BEARINGS(), "right_middle_bearings")
    add_part(rover, RIGHT_WHEEL_BEARINGS(), "right_rear_bearings")
    add_part(rover, LEFT_CHASSIS_PIVOT_BEARINGS(),
             "left_chassis_pivot_bearings")
    add_part(rover, RIGHT_CHASSIS_PIVOT_BEARINGS(),
             "right_chassis_pivot_bearings")
    add_part(rover, LEFT_BOGIE_PIVOT_BEARINGS(),
             "left_bogie_pivot_bearings")
    add_part(rover, RIGHT_BOGIE_PIVOT_BEARINGS(),
             "right_bogie_pivot_bearings")
    add_part(rover, LEFT_ROCKER_PIVOT_SHAFT(), "left_rocker_pivot_shaft")
    add_part(rover, RIGHT_ROCKER_PIVOT_SHAFT(), "right_rocker_pivot_shaft")
    add_part(rover, LEFT_ROCKER_PIVOT_KEYS(), "left_rocker_pivot_keys")
    add_part(rover, RIGHT_ROCKER_PIVOT_KEYS(), "right_rocker_pivot_keys")
    add_part(rover, LEFT_ROCKER_PIVOT_HARDWARE(),
             "left_rocker_pivot_hardware")
    add_part(rover, RIGHT_ROCKER_PIVOT_HARDWARE(),
             "right_rocker_pivot_hardware")
    add_part(rover, LEFT_BOGIE_PIVOT_SHAFT(), "left_bogie_pivot_shaft")
    add_part(rover, RIGHT_BOGIE_PIVOT_SHAFT(), "right_bogie_pivot_shaft")
    add_part(rover, LEFT_BOGIE_PIVOT_HARDWARE(),
             "left_bogie_pivot_hardware")
    add_part(rover, RIGHT_BOGIE_PIVOT_HARDWARE(),
             "right_bogie_pivot_hardware")
    add_part(rover, LEFT_DIFFERENTIAL_SIDE_GEAR(),
             "left_differential_side_gear")
    add_part(rover, RIGHT_DIFFERENTIAL_SIDE_GEAR(),
             "right_differential_side_gear")
    add_part(rover, FRONT_DIFFERENTIAL_PLANET_GEAR(),
             "front_differential_planet_gear")
    add_part(rover, REAR_DIFFERENTIAL_PLANET_GEAR(),
             "rear_differential_planet_gear")
    add_part(rover, DIFFERENTIAL_CRADLE_FINISHED(),
             "differential_cradle")
    add_part(rover, DIFFERENTIAL_CRADLE_FASTENERS(),
             "differential_cradle_fasteners")
    add_part(rover, DIFFERENTIAL_CARRIER_BEARINGS(),
             "differential_carrier_bearings")
    add_part(rover, DIFFERENTIAL_CROSS_PIN(), "differential_cross_pin")
    add_part(rover, DIFFERENTIAL_PLANET_THRUST_WASHERS(),
             "differential_planet_thrust_washers")

    add_named_mate(rover, "left_rocker_pivot", "revolute",
                   "chassis", "left_rocker", "left_rocker", "chassis_pivot")
    add_named_mate(rover, "right_rocker_pivot", "revolute",
                   "chassis", "right_rocker", "right_rocker", "chassis_pivot")
    add_named_mate(rover, "left_bogie_pivot", "revolute",
                   "left_rocker", "bogie_pivot", "left_bogie", "rocker_pivot")
    add_named_mate(rover, "right_bogie_pivot", "revolute",
                   "right_rocker", "bogie_pivot", "right_bogie", "rocker_pivot")
    add_named_mate(rover, "left_front_axle", "revolute",
                   "left_rocker", "front_axle", "left_front_wheel", "axle")
    add_named_mate(rover, "left_middle_axle", "revolute",
                   "left_bogie", "middle_axle", "left_middle_wheel", "axle")
    add_named_mate(rover, "left_rear_axle", "revolute",
                   "left_bogie", "rear_axle", "left_rear_wheel", "axle")
    add_named_mate(rover, "right_front_axle", "revolute",
                   "right_rocker", "front_axle", "right_front_wheel", "axle")
    add_named_mate(rover, "right_middle_axle", "revolute",
                   "right_bogie", "middle_axle", "right_middle_wheel", "axle")
    add_named_mate(rover, "right_rear_axle", "revolute",
                   "right_bogie", "rear_axle", "right_rear_wheel", "axle")

    # TPU bumper pairs are fixed to each joint's parent. The PET-G contact
    # noses are integral with the rotating child and meet the pads only at
    # the declared joint limits.
    add_named_mate(rover, "left_rocker_limit_bumper_mount", "rigid",
                   "chassis", "left_rocker",
                   "left_rocker_limit_bumpers", "joint_axis")
    add_named_mate(rover, "right_rocker_limit_bumper_mount", "rigid",
                   "chassis", "right_rocker",
                   "right_rocker_limit_bumpers", "joint_axis")
    add_named_mate(rover, "left_bogie_limit_bumper_mount", "rigid",
                   "left_rocker", "bogie_pivot",
                   "left_bogie_limit_bumpers", "joint_axis")
    add_named_mate(rover, "right_bogie_limit_bumper_mount", "rigid",
                   "right_rocker", "bogie_pivot",
                   "right_bogie_limit_bumpers", "joint_axis")

    # Shafts and spacers are fixed to their supporting links. Bearing packs
    # are fixed to the wheel hubs, so their outer races follow wheel rotation.
    add_named_mate(rover, "left_front_shaft_mount", "rigid",
                   "left_rocker", "front_axle", "left_front_shaft", "axle")
    add_named_mate(rover, "left_middle_shaft_mount", "rigid",
                   "left_bogie", "middle_axle", "left_middle_shaft", "axle")
    add_named_mate(rover, "left_rear_shaft_mount", "rigid",
                   "left_bogie", "rear_axle", "left_rear_shaft", "axle")
    add_named_mate(rover, "right_front_shaft_mount", "rigid",
                   "right_rocker", "front_axle", "right_front_shaft", "axle")
    add_named_mate(rover, "right_middle_shaft_mount", "rigid",
                   "right_bogie", "middle_axle", "right_middle_shaft", "axle")
    add_named_mate(rover, "right_rear_shaft_mount", "rigid",
                   "right_bogie", "rear_axle", "right_rear_shaft", "axle")
    add_named_mate(rover, "left_front_spacer_mount", "rigid",
                   "left_rocker", "front_axle", "left_front_spacer", "axle")
    add_named_mate(rover, "left_middle_spacer_mount", "rigid",
                   "left_bogie", "middle_axle", "left_middle_spacer", "axle")
    add_named_mate(rover, "left_rear_spacer_mount", "rigid",
                   "left_bogie", "rear_axle", "left_rear_spacer", "axle")
    add_named_mate(rover, "right_front_spacer_mount", "rigid",
                   "right_rocker", "front_axle", "right_front_spacer", "axle")
    add_named_mate(rover, "right_middle_spacer_mount", "rigid",
                   "right_bogie", "middle_axle", "right_middle_spacer", "axle")
    add_named_mate(rover, "right_rear_spacer_mount", "rigid",
                   "right_bogie", "rear_axle", "right_rear_spacer", "axle")
    add_named_mate(rover, "left_front_axle_hardware_mount", "rigid",
                   "left_rocker", "front_axle", "left_front_axle_hardware", "axle")
    add_named_mate(rover, "left_middle_axle_hardware_mount", "rigid",
                   "left_bogie", "middle_axle", "left_middle_axle_hardware", "axle")
    add_named_mate(rover, "left_rear_axle_hardware_mount", "rigid",
                   "left_bogie", "rear_axle", "left_rear_axle_hardware", "axle")
    add_named_mate(rover, "right_front_axle_hardware_mount", "rigid",
                   "right_rocker", "front_axle", "right_front_axle_hardware", "axle")
    add_named_mate(rover, "right_middle_axle_hardware_mount", "rigid",
                   "right_bogie", "middle_axle", "right_middle_axle_hardware", "axle")
    add_named_mate(rover, "right_rear_axle_hardware_mount", "rigid",
                   "right_bogie", "rear_axle", "right_rear_axle_hardware", "axle")
    add_named_mate(rover, "left_front_bearing_mount", "rigid",
                   "left_front_wheel", "axle", "left_front_bearings", "axle")
    add_named_mate(rover, "left_middle_bearing_mount", "rigid",
                   "left_middle_wheel", "axle", "left_middle_bearings", "axle")
    add_named_mate(rover, "left_rear_bearing_mount", "rigid",
                   "left_rear_wheel", "axle", "left_rear_bearings", "axle")
    add_named_mate(rover, "right_front_bearing_mount", "rigid",
                   "right_front_wheel", "axle", "right_front_bearings", "axle")
    add_named_mate(rover, "right_middle_bearing_mount", "rigid",
                   "right_middle_wheel", "axle", "right_middle_bearings", "axle")
    add_named_mate(rover, "right_rear_bearing_mount", "rigid",
                   "right_rear_wheel", "axle", "right_rear_bearings", "axle")
    add_named_mate(rover, "left_chassis_bearing_mount", "rigid",
                   "chassis", "left_rocker",
                   "left_chassis_pivot_bearings", "axle")
    add_named_mate(rover, "right_chassis_bearing_mount", "rigid",
                   "chassis", "right_rocker",
                   "right_chassis_pivot_bearings", "axle")
    add_named_mate(rover, "left_bogie_bearing_mount", "rigid",
                   "left_bogie", "rocker_pivot",
                   "left_bogie_pivot_bearings", "axle")
    add_named_mate(rover, "right_bogie_bearing_mount", "rigid",
                   "right_bogie", "rocker_pivot",
                   "right_bogie_pivot_bearings", "axle")
    add_named_mate(rover, "left_rocker_shaft_mount", "rigid",
                   "left_rocker", "chassis_pivot",
                   "left_rocker_pivot_shaft", "axle")
    add_named_mate(rover, "right_rocker_shaft_mount", "rigid",
                   "right_rocker", "chassis_pivot",
                   "right_rocker_pivot_shaft", "axle")
    add_named_mate(rover, "left_rocker_key_mount", "rigid",
                   "left_rocker", "chassis_pivot",
                   "left_rocker_pivot_keys", "axle")
    add_named_mate(rover, "right_rocker_key_mount", "rigid",
                   "right_rocker", "chassis_pivot",
                   "right_rocker_pivot_keys", "axle")
    add_named_mate(rover, "left_rocker_hardware_mount", "rigid",
                   "left_rocker", "chassis_pivot",
                   "left_rocker_pivot_hardware", "axle")
    add_named_mate(rover, "right_rocker_hardware_mount", "rigid",
                   "right_rocker", "chassis_pivot",
                   "right_rocker_pivot_hardware", "axle")
    add_named_mate(rover, "left_bogie_shaft_mount", "rigid",
                   "left_rocker", "bogie_pivot", "left_bogie_pivot_shaft", "axle")
    add_named_mate(rover, "right_bogie_shaft_mount", "rigid",
                   "right_rocker", "bogie_pivot", "right_bogie_pivot_shaft", "axle")
    add_named_mate(rover, "left_bogie_hardware_mount", "rigid",
                   "left_rocker", "bogie_pivot",
                   "left_bogie_pivot_hardware", "axle")
    add_named_mate(rover, "right_bogie_hardware_mount", "rigid",
                   "right_rocker", "bogie_pivot",
                   "right_bogie_pivot_hardware", "axle")
    add_named_mate(rover, "left_side_gear_mount", "rigid",
                   "left_rocker", "chassis_pivot",
                   "left_differential_side_gear", "axis")
    add_named_mate(rover, "right_side_gear_mount", "rigid",
                   "right_rocker", "chassis_pivot",
                   "right_differential_side_gear", "axis")
    add_named_mate(rover, "differential_cradle_mount", "rigid",
                   "chassis", "differential_mount",
                   "differential_cradle", "mount")
    add_named_mate(rover, "differential_fastener_mount", "rigid",
                   "differential_cradle", "mount",
                   "differential_cradle_fasteners", "mount")
    add_named_mate(rover, "differential_bearing_mount", "rigid",
                   "differential_cradle", "differential_axis",
                   "differential_carrier_bearings", "axis")
    add_named_mate(rover, "differential_cross_pin_mount", "rigid",
                   "differential_cradle", "planet_axis",
                   "differential_cross_pin", "axis")
    add_named_mate(rover, "differential_thrust_washer_mount", "rigid",
                   "differential_cradle", "planet_axis",
                   "differential_planet_thrust_washers", "axis")
    add_named_mate(rover, "front_planet_pivot", "revolute",
                   "differential_cross_pin", "axis",
                   "front_differential_planet_gear", "axis")
    add_named_mate(rover, "rear_planet_pivot", "revolute",
                   "differential_cross_pin", "axis",
                   "rear_differential_planet_gear", "axis")

    set_mate_limits(rover, "left_rocker_pivot", radians(-18.0), radians(18.0))
    set_mate_limits(rover, "right_rocker_pivot", radians(-18.0), radians(18.0))
    set_mate_limits(rover, "left_bogie_pivot", radians(-35.0), radians(38.0))
    set_mate_limits(rover, "right_bogie_pivot", radians(-35.0), radians(38.0))
    add_joint_coupling(rover, "rocker_differential", "right_rocker_pivot",
                       ["left_rocker_pivot"], [-1.0], 0.0)
    add_joint_coupling(rover, "front_planet_differential",
                       "front_planet_pivot",
                       ["left_rocker_pivot"], [-1.0], 0.0)
    add_joint_coupling(rover, "rear_planet_differential",
                       "rear_planet_pivot",
                       ["left_rocker_pivot"], [1.0], 0.0)
    solve_assembly(rover, "chassis")
    set_joint_position(rover, "left_rocker_pivot", rocker_angle)
    emit assembly_compound(rover)
