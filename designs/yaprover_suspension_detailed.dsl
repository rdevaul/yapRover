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


command AXIS_BOSS_KEYED(x: float, y: float, z: float) -> solid:
    emit difference(AXIS_BOSS_BLANK(x, y, z),
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


command ROCKER_FRONT_COMPONENT() -> solid:
    # C -> F = (+190, -75) mm.  This 204.3 mm component fits a 220 mm bed.
    let arm: solid = ARM_FILLETED(204.266982, 21.540976,
                                  95.0, -8.5, -37.5)
    let center: solid = AXIS_BOSS_KEYED(0.0, -8.5, 0.0)
    let front: solid = AXIS_BOSS_BORE(190.0, -8.5, -75.0)
    let joined: solid = union(arm, center, front)
    emit difference(joined, AXIS_KEYED_CUTTERS(0.0, -8.5, 0.0),
                    AXIS_BORE_CUTTERS(190.0, -8.5, -75.0))


command ROCKER_REAR_COMPONENT() -> solid:
    # C -> B = (-95, -35) mm.  The adjacent layer forms a keyed split rocker.
    let arm: solid = ARM_FILLETED(101.242284, 159.775141,
                                  -47.5, 8.5, -17.5)
    let center: solid = AXIS_BOSS_KEYED(0.0, 8.5, 0.0)
    let bogie: solid = AXIS_BOSS_BORE(-95.0, 8.5, -35.0)
    let joined: solid = union(arm, center, bogie)
    emit difference(joined, AXIS_KEYED_CUTTERS(0.0, 8.5, 0.0),
                    AXIS_BORE_CUTTERS(-95.0, 8.5, -35.0))


command ROCKER_FINISHED(side: int) -> solid:
    require side == -1 or side == 1, "side must be -1 (right) or +1 (left)"
    # Occupy the middle lateral band between the inboard bogie and wheel.
    let assembled: solid = compound(ROCKER_FRONT_COMPONENT(),
                                     ROCKER_REAR_COMPONENT())
    emit translate(assembled, 0.0, side * -23.0, 0.0)


command BOGIE_FINISHED(side: int) -> solid:
    require side == -1 or side == 1, "side must be -1 (right) or +1 (left)"
    let middle_arm: solid = ARM_FILLETED(103.077641, 22.833654,
                                         47.5, 0.0, -20.0)
    let rear_arm: solid = ARM_FILLETED(103.077641, 157.166346,
                                       -47.5, 0.0, -20.0)
    let pivot: solid = AXIS_BOSS_DUAL_608(0.0, 0.0, 0.0)
    let middle: solid = AXIS_BOSS_BORE(95.0, 0.0, -40.0)
    let rear: solid = AXIS_BOSS_BORE(-95.0, 0.0, -40.0)
    let joined: solid = union(middle_arm, rear_arm, pivot, middle, rear)
    let assembled: solid = difference(
        joined,
        AXIS_DUAL_608_CUTTERS(0.0, 0.0, 0.0),
        AXIS_BORE_CUTTERS(95.0, 0.0, -40.0),
        AXIS_BORE_CUTTERS(-95.0, 0.0, -40.0)
    )
    # Put the bogie inboard of the rocker's rear layer.  The one-millimetre
    # axial gap at their shared pivot is swept by the clearance tests.
    emit translate(assembled, 0.0, side * -48.5, 0.0)


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


@meta(material="PETG", assembly.datums=[
    {"id": "axle", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command LEFT_WHEEL() -> solid:
    # Axial placement along the same infinite mate axis gives a 343 mm wheel-
    # plane track and room for three independent printed suspension layers.
    emit translate(WHEEL_HUB(), 0.0, 16.5, 0.0)


@meta(material="PETG", assembly.datums=[
    {"id": "axle", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command RIGHT_WHEEL() -> solid:
    emit translate(WHEEL_HUB(), 0.0, -16.5, 0.0)


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


command LEFT_FRONT_AXLE_GEOMETRY() -> solid:
    let shaft: solid = AXLE_SHAFT(92.0, -2.5)
    let spacer: solid = AXLE_SPACER(20.8, -12.5)
    emit compound(shaft, spacer,
                  M8_WASHER(-40.4), M8_NUT(-44.6),
                  M8_WASHER(35.4), M8_NUT(39.6))


command LEFT_BOGIE_AXLE_GEOMETRY() -> solid:
    let shaft: solid = AXLE_SHAFT(110.0, -11.0)
    let spacer: solid = AXLE_SPACER(37.8, -21.0)
    emit compound(shaft, spacer,
                  M8_WASHER(-57.4), M8_NUT(-61.6),
                  M8_WASHER(35.4), M8_NUT(39.6))


command LEFT_WHEEL_BEARING_GEOMETRY() -> solid:
    emit compound(BEARING_608(2.15), BEARING_608(30.85))


command LEFT_CHASSIS_PIVOT_BEARING_GEOMETRY() -> solid:
    emit compound(BEARING_608(-73.9), BEARING_608(-61.1))


command LEFT_BOGIE_PIVOT_BEARING_GEOMETRY() -> solid:
    emit compound(BEARING_608(-53.0), BEARING_608(-44.0))


@meta(material="steel / spacer tube", assembly.datums=[
    {"id": "axle", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command LEFT_FRONT_AXLE() -> solid:
    emit LEFT_FRONT_AXLE_GEOMETRY()


@meta(material="steel / spacer tube", assembly.datums=[
    {"id": "axle", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command RIGHT_FRONT_AXLE() -> solid:
    emit mirror(LEFT_FRONT_AXLE_GEOMETRY(), vector(0.0, 1.0, 0.0))


@meta(material="steel / spacer tube", assembly.datums=[
    {"id": "axle", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command LEFT_BOGIE_AXLE() -> solid:
    emit LEFT_BOGIE_AXLE_GEOMETRY()


@meta(material="steel / spacer tube", assembly.datums=[
    {"id": "axle", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command RIGHT_BOGIE_AXLE() -> solid:
    emit mirror(LEFT_BOGIE_AXLE_GEOMETRY(), vector(0.0, 1.0, 0.0))


@meta(material="608-2RS steel / rubber", assembly.datums=[
    {"id": "axle", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command LEFT_WHEEL_BEARINGS() -> solid:
    emit LEFT_WHEEL_BEARING_GEOMETRY()


@meta(material="608-2RS steel / rubber", assembly.datums=[
    {"id": "axle", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command RIGHT_WHEEL_BEARINGS() -> solid:
    emit mirror(LEFT_WHEEL_BEARING_GEOMETRY(), vector(0.0, 1.0, 0.0))


@meta(material="608-2RS steel / rubber", assembly.datums=[
    {"id": "axle", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command LEFT_CHASSIS_PIVOT_BEARINGS() -> solid:
    emit LEFT_CHASSIS_PIVOT_BEARING_GEOMETRY()


@meta(material="608-2RS steel / rubber", assembly.datums=[
    {"id": "axle", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command RIGHT_CHASSIS_PIVOT_BEARINGS() -> solid:
    emit mirror(LEFT_CHASSIS_PIVOT_BEARING_GEOMETRY(),
                vector(0.0, 1.0, 0.0))


@meta(material="608-2RS steel / rubber", assembly.datums=[
    {"id": "axle", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command LEFT_BOGIE_PIVOT_BEARINGS() -> solid:
    emit LEFT_BOGIE_PIVOT_BEARING_GEOMETRY()


@meta(material="608-2RS steel / rubber", assembly.datums=[
    {"id": "axle", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command RIGHT_BOGIE_PIVOT_BEARINGS() -> solid:
    emit mirror(LEFT_BOGIE_PIVOT_BEARING_GEOMETRY(),
                vector(0.0, 1.0, 0.0))


command LEFT_ROCKER_PIVOT_SHAFT_GEOMETRY() -> solid:
    emit compound(AXLE_SHAFT(151.5, -71.25),
                  SHAFT_KEY(34.5, -22.75),
                  SHAFT_KEY(8.5, -138.75),
                  M8_RETAINING_CLIP(-143.8),
                  M8_WASHER(-5.6), M8_NUT(-1.4))


command LEFT_BOGIE_PIVOT_SHAFT_GEOMETRY() -> solid:
    emit compound(AXLE_SHAFT(70.0, -31.5),
                  M8_WASHER(-57.4), M8_NUT(-61.6),
                  M8_WASHER(-5.6), M8_NUT(-1.4))


@meta(material="8 mm steel rod", assembly.datums=[
    {"id": "axle", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command LEFT_ROCKER_PIVOT_SHAFT() -> solid:
    emit LEFT_ROCKER_PIVOT_SHAFT_GEOMETRY()


@meta(material="8 mm steel rod", assembly.datums=[
    {"id": "axle", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command RIGHT_ROCKER_PIVOT_SHAFT() -> solid:
    emit mirror(LEFT_ROCKER_PIVOT_SHAFT_GEOMETRY(), vector(0.0, 1.0, 0.0))


@meta(material="8 mm steel rod", assembly.datums=[
    {"id": "axle", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command LEFT_BOGIE_PIVOT_SHAFT() -> solid:
    emit LEFT_BOGIE_PIVOT_SHAFT_GEOMETRY()


@meta(material="8 mm steel rod", assembly.datums=[
    {"id": "axle", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command RIGHT_BOGIE_PIVOT_SHAFT() -> solid:
    emit mirror(LEFT_BOGIE_PIVOT_SHAFT_GEOMETRY(), vector(0.0, 1.0, 0.0))


# ---------------------------------------------------------------------------
# Compact straight-bevel differential. The tooth form is a printable,
# replaceable 24-tooth approximation around an analytic conical gear body;
# the shaft and carrier datums preserve a future purchased-metal gear swap.

command MITER_GEAR_BLANK() -> solid:
    let body: solid = cone(19.5, 13.5, 8.0)
    let tooth: solid = translate(box(4.0, 2.4, 4.0), 18.0, 0.0, 1.5)
    let teeth: list<solid> = [
        rotate(tooth, 0.0, 0.0, i * 15.0) for i in range(24)
    ]
    emit union_all([body] + teeth)


command MITER_SIDE_GEAR_Z() -> solid:
    let blank: solid = MITER_GEAR_BLANK()
    let bore: solid = translate(cylinder(4.2, 10.0), 0.0, 0.0, -1.0)
    let keyway: solid = translate(box(2.2, 2.2, 10.0),
                                  0.0, 3.8, 4.0)
    emit difference(blank, bore, keyway)


command MITER_PLANET_GEAR_Z() -> solid:
    let bore: solid = translate(cylinder(4.2, 10.0), 0.0, 0.0, -1.0)
    emit difference(MITER_GEAR_BLANK(), bore)


command LEFT_DIFFERENTIAL_SIDE_GEAR_GEOMETRY() -> solid:
    # With the child datum solved to y=+155, this gear occupies y=12..20.
    let on_y: solid = rotate(MITER_SIDE_GEAR_Z(), 90.0, 0.0, 0.0)
    emit translate(on_y, 0.0, -135.0, 0.0)


command PLANET_GEAR_PAIR_GEOMETRY() -> solid:
    let positive: solid = translate(
        rotate(MITER_PLANET_GEAR_Z(), 0.0, -90.0, 0.0),
        20.0, 0.0, 0.0
    )
    let negative: solid = mirror(positive, vector(1.0, 0.0, 0.0))
    emit compound(positive, negative)


@meta(material="PETG replaceable gear", assembly.datums=[
    {"id": "axis", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command LEFT_DIFFERENTIAL_SIDE_GEAR() -> solid:
    emit LEFT_DIFFERENTIAL_SIDE_GEAR_GEOMETRY()


@meta(material="PETG replaceable gear", assembly.datums=[
    {"id": "axis", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command RIGHT_DIFFERENTIAL_SIDE_GEAR() -> solid:
    emit mirror(LEFT_DIFFERENTIAL_SIDE_GEAR_GEOMETRY(),
                vector(0.0, 1.0, 0.0))


@meta(material="PETG replaceable gear", assembly.datums=[
    {"id": "axis", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [1.0, 0.0, 0.0]}
])
command DIFFERENTIAL_PLANET_PAIR() -> solid:
    emit PLANET_GEAR_PAIR_GEOMETRY()


@meta(material="608-2RS steel / rubber", assembly.datums=[
    {"id": "axis", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command DIFFERENTIAL_CARRIER_BEARINGS() -> solid:
    emit compound(BEARING_608(32.0), BEARING_608(-32.0))


@meta(material="8 mm steel rod", assembly.datums=[
    {"id": "axis", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [1.0, 0.0, 0.0]}
])
command DIFFERENTIAL_CROSS_PIN() -> solid:
    let raw: solid = translate(cylinder(3.95, 72.0), 0.0, 0.0, -36.0)
    emit rotate(raw, 0.0, 90.0, 0.0)


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
    emit union(left_rail, right_rail,
               DIFFERENTIAL_BEARING_PLATE(1),
               DIFFERENTIAL_BEARING_PLATE(-1),
               DIFFERENTIAL_PIN_TOWER(1),
               DIFFERENTIAL_PIN_TOWER(-1))


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
    # Remove only the center floor beneath the 41 mm gear envelope. The cradle
    # rails land on intact floor strips immediately outside this opening.
    emit translate(box(48.0, 90.0, 20.0), 0.0, 0.0, -20.0)


command CHASSIS_CUT_TUB() -> solid:
    emit difference(CHASSIS_TUB(),
                    CHASSIS_PIVOT_CUTTERS(1),
                    CHASSIS_PIVOT_CUTTERS(-1),
                    DIFFERENTIAL_FLOOR_CLEARANCE())


command CHASSIS_FRONT_SEGMENT() -> solid:
    let halfspace: solid = translate(box(102.5, 200.0, 120.0),
                                     51.25, 0.0, 30.0)
    emit intersection(CHASSIS_CUT_TUB(), halfspace)


command CHASSIS_REAR_SEGMENT() -> solid:
    let halfspace: solid = translate(box(102.5, 200.0, 120.0),
                                     -51.25, 0.0, 30.0)
    emit intersection(CHASSIS_CUT_TUB(), halfspace)


command CHASSIS_SPLICE_KEYS() -> solid:
    let left_low: solid = fillet(translate(box(30.0, 8.0, 12.0),
                                           0.0, 95.0, 25.0), 2.0)
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
         "origin_mm": [0.0, 0.0, 0.0], "direction": [1.0, 0.0, 0.0]}
    ]
)
command CHASSIS_FINISHED() -> solid:
    emit compound(CHASSIS_FRONT_SEGMENT(), CHASSIS_REAR_SEGMENT(),
                  CHASSIS_SIDE_INTERFACE(1), CHASSIS_SIDE_INTERFACE(-1),
                  DIFFERENTIAL_CRADLE(), CHASSIS_SPLICE_KEYS())


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
    emit compound(DIFFERENTIAL_CRADLE(), DIFFERENTIAL_CARRIER_BEARINGS(),
                  DIFFERENTIAL_CROSS_PIN(), PLANET_GEAR_PAIR_GEOMETRY(),
                  left_gear, right_gear, left_shaft, right_shaft)


@meta(assembly.datums=[
    {"id": "chassis_pivot", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]},
    {"id": "front_axle", "kind": "axis",
     "origin_mm": [190.0, 0.0, -75.0], "direction": [0.0, 1.0, 0.0]},
    {"id": "bogie_pivot", "kind": "axis",
     "origin_mm": [-95.0, 0.0, -35.0], "direction": [0.0, 1.0, 0.0]}
])
command LEFT_ROCKER() -> solid:
    emit ROCKER_FINISHED(1)


@meta(assembly.datums=[
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
    emit translate(mirrored, 0.0, 23.0, 0.0)


@meta(assembly.datums=[
    {"id": "rocker_pivot", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]},
    {"id": "middle_axle", "kind": "axis",
     "origin_mm": [95.0, 0.0, -40.0], "direction": [0.0, 1.0, 0.0]},
    {"id": "rear_axle", "kind": "axis",
     "origin_mm": [-95.0, 0.0, -40.0], "direction": [0.0, 1.0, 0.0]}
])
command LEFT_BOGIE() -> solid:
    emit BOGIE_FINISHED(1)


@meta(assembly.datums=[
    {"id": "rocker_pivot", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]},
    {"id": "middle_axle", "kind": "axis",
     "origin_mm": [95.0, 0.0, -40.0], "direction": [0.0, 1.0, 0.0]},
    {"id": "rear_axle", "kind": "axis",
     "origin_mm": [-95.0, 0.0, -40.0], "direction": [0.0, 1.0, 0.0]}
])
command RIGHT_BOGIE() -> solid:
    emit BOGIE_FINISHED(-1)


command BUILD_DETAILED_SUSPENSION(rocker_angle: float = 0.0) -> solid:
    let rover: assembly = assembly("yaprover_suspension_detailed")
    add_part(rover, CHASSIS_FINISHED(), "chassis")
    add_part(rover, LEFT_ROCKER(), "left_rocker")
    add_part(rover, RIGHT_ROCKER(), "right_rocker")
    add_part(rover, LEFT_BOGIE(), "left_bogie")
    add_part(rover, RIGHT_BOGIE(), "right_bogie")
    add_part(rover, LEFT_WHEEL(), "left_front_wheel")
    add_part(rover, LEFT_WHEEL(), "left_middle_wheel")
    add_part(rover, LEFT_WHEEL(), "left_rear_wheel")
    add_part(rover, RIGHT_WHEEL(), "right_front_wheel")
    add_part(rover, RIGHT_WHEEL(), "right_middle_wheel")
    add_part(rover, RIGHT_WHEEL(), "right_rear_wheel")
    add_part(rover, LEFT_FRONT_AXLE(), "left_front_shaft")
    add_part(rover, LEFT_BOGIE_AXLE(), "left_middle_shaft")
    add_part(rover, LEFT_BOGIE_AXLE(), "left_rear_shaft")
    add_part(rover, RIGHT_FRONT_AXLE(), "right_front_shaft")
    add_part(rover, RIGHT_BOGIE_AXLE(), "right_middle_shaft")
    add_part(rover, RIGHT_BOGIE_AXLE(), "right_rear_shaft")
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
    add_part(rover, LEFT_BOGIE_PIVOT_SHAFT(), "left_bogie_pivot_shaft")
    add_part(rover, RIGHT_BOGIE_PIVOT_SHAFT(), "right_bogie_pivot_shaft")
    add_part(rover, LEFT_DIFFERENTIAL_SIDE_GEAR(),
             "left_differential_side_gear")
    add_part(rover, RIGHT_DIFFERENTIAL_SIDE_GEAR(),
             "right_differential_side_gear")
    add_part(rover, DIFFERENTIAL_PLANET_PAIR(), "differential_planet_pair")
    add_part(rover, DIFFERENTIAL_CARRIER_BEARINGS(),
             "differential_carrier_bearings")
    add_part(rover, DIFFERENTIAL_CROSS_PIN(), "differential_cross_pin")

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
    add_named_mate(rover, "left_bogie_shaft_mount", "rigid",
                   "left_rocker", "bogie_pivot", "left_bogie_pivot_shaft", "axle")
    add_named_mate(rover, "right_bogie_shaft_mount", "rigid",
                   "right_rocker", "bogie_pivot", "right_bogie_pivot_shaft", "axle")
    add_named_mate(rover, "left_side_gear_mount", "rigid",
                   "left_rocker", "chassis_pivot",
                   "left_differential_side_gear", "axis")
    add_named_mate(rover, "right_side_gear_mount", "rigid",
                   "right_rocker", "chassis_pivot",
                   "right_differential_side_gear", "axis")
    add_named_mate(rover, "differential_bearing_mount", "rigid",
                   "chassis", "differential_axis",
                   "differential_carrier_bearings", "axis")
    add_named_mate(rover, "differential_cross_pin_mount", "rigid",
                   "chassis", "planet_axis", "differential_cross_pin", "axis")
    add_named_mate(rover, "planet_pair_pivot", "revolute",
                   "chassis", "planet_axis", "differential_planet_pair", "axis")

    set_mate_limits(rover, "left_rocker_pivot", radians(-18.0), radians(18.0))
    set_mate_limits(rover, "right_rocker_pivot", radians(-18.0), radians(18.0))
    set_mate_limits(rover, "left_bogie_pivot", radians(-35.0), radians(38.0))
    set_mate_limits(rover, "right_bogie_pivot", radians(-35.0), radians(38.0))
    add_joint_coupling(rover, "rocker_differential", "right_rocker_pivot",
                       ["left_rocker_pivot"], [-1.0], 0.0)
    add_joint_coupling(rover, "planet_differential", "planet_pair_pivot",
                       ["left_rocker_pivot"], [-1.0], 0.0)
    solve_assembly(rover, "chassis")
    set_joint_position(rover, "left_rocker_pivot", rocker_angle)
    emit assembly_compound(rover)
