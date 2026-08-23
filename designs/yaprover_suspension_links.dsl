module yaprover_suspension_links

# Geometry study for printable YapRover rocker/bogie links.
#
# Coordinates are local to each suspension pivot: +X forward, +Y left,
# +Z up.  All pivots and axles are +Y axes.  The rocker is deliberately two
# printable pieces: its long front arm and short rear arm occupy adjacent
# 16 mm lateral layers and clamp around the common M8 chassis pivot.

command AXIS_BOSS_BLANK(x: float, y: float, z: float) -> solid:
    let raw: solid = translate(cylinder(15.0, 16.0), 0.0, 0.0, -8.0)
    let along_y: solid = rotate(raw, -90.0, 0.0, 0.0)
    emit translate(along_y, x, y, z)

command AXIS_BOSS_608(x: float, y: float, z: float) -> solid:
    # Ø30 boss, Ø8.4 clearance bore, and Ø22.3 x 7.2 mm one-sided 608 seat.
    let raw: solid = translate(cylinder(15.0, 16.0), 0.0, 0.0, -8.0)
    let boss: solid = rotate(raw, -90.0, 0.0, 0.0)
    let bore_raw: solid = translate(cylinder(4.2, 18.0), 0.0, 0.0, -9.0)
    let bore: solid = rotate(bore_raw, -90.0, 0.0, 0.0)
    let seat_raw: solid = translate(cylinder(11.15, 7.2), 0.0, 0.0, 0.8)
    let seat: solid = rotate(seat_raw, -90.0, 0.0, 0.0)
    let cut: solid = difference(boss, bore, seat)
    emit translate(cut, x, y, z)

command ARM_BLANK(
    length: float, angle_y_deg: float,
    center_x: float, center_y: float, center_z: float
) -> solid:
    let bar: solid = translate(box(length, 16.0, 28.0), 0.0, 0.0, -14.0)
    let aimed: solid = rotate(bar, 0.0, angle_y_deg, 0.0)
    emit translate(aimed, center_x, center_y, center_z)

command ARM_FILLETED(
    length: float, angle_y_deg: float,
    center_x: float, center_y: float, center_z: float
) -> solid:
    # Seven millimetres is below half the 16 mm structural thickness.
    let rounded: solid = fillet(box(length, 16.0, 28.0), 7.0)
    let centered: solid = translate(rounded, 0.0, 0.0, -14.0)
    let aimed: solid = rotate(centered, 0.0, angle_y_deg, 0.0)
    emit translate(aimed, center_x, center_y, center_z)


command ROCKER_FRONT_BLANK() -> solid:
    # C -> F = (190, -75), length 204.267 mm, angle about +Y = 21.541°.
    let arm: solid = ARM_BLANK(204.266982, 21.540976, 95.0, -8.5, -37.5)
    let center: solid = AXIS_BOSS_BLANK(0.0, -8.5, 0.0)
    let front: solid = AXIS_BOSS_BLANK(190.0, -8.5, -75.0)
    emit compound(arm, center, front)

command ROCKER_REAR_BLANK() -> solid:
    # C -> B = (-95, -35), length 101.242 mm, angle about +Y = 159.775°.
    let arm: solid = ARM_BLANK(101.242284, 159.775141, -47.5, 8.5, -17.5)
    let center: solid = AXIS_BOSS_BLANK(0.0, 8.5, 0.0)
    let bogie: solid = AXIS_BOSS_BLANK(-95.0, 8.5, -35.0)
    emit compound(arm, center, bogie)

command ROCKER_FRONT_COMPONENT() -> solid:
    let arm: solid = ARM_FILLETED(204.266982, 21.540976,
                                  95.0, -8.5, -37.5)
    let center: solid = AXIS_BOSS_608(0.0, -8.5, 0.0)
    let front: solid = AXIS_BOSS_608(190.0, -8.5, -75.0)
    emit union(arm, center, front)

command ROCKER_REAR_COMPONENT() -> solid:
    let arm: solid = ARM_FILLETED(101.242284, 159.775141,
                                  -47.5, 8.5, -17.5)
    let center: solid = AXIS_BOSS_608(0.0, 8.5, 0.0)
    let bogie: solid = AXIS_BOSS_608(-95.0, 8.5, -35.0)
    emit union(arm, center, bogie)

@meta(assembly.datums=[
    {"id": "chassis_pivot", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]},
    {"id": "front_axle", "kind": "axis",
     "origin_mm": [190.0, 0.0, -75.0], "direction": [0.0, 1.0, 0.0]},
    {"id": "bogie_pivot", "kind": "axis",
     "origin_mm": [-95.0, 0.0, -35.0], "direction": [0.0, 1.0, 0.0]}
])
command ROCKER_LAYOUT_PROXY() -> solid:
    emit compound(ROCKER_FRONT_BLANK(), ROCKER_REAR_BLANK())

@meta(assembly.datums=[
    {"id": "chassis_pivot", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]},
    {"id": "front_axle", "kind": "axis",
     "origin_mm": [190.0, 0.0, -75.0], "direction": [0.0, 1.0, 0.0]},
    {"id": "bogie_pivot", "kind": "axis",
     "origin_mm": [-95.0, 0.0, -35.0], "direction": [0.0, 1.0, 0.0]}
])
command ROCKER_FINISHED() -> solid:
    emit compound(ROCKER_FRONT_COMPONENT(), ROCKER_REAR_COMPONENT())


command BOGIE_BLANK() -> solid:
    # B -> M/R = (+/-95, -40); both arms are 103.078 mm long.
    let middle_arm: solid = ARM_BLANK(103.077641, 22.833654,
                                      47.5, 0.0, -20.0)
    let rear_arm: solid = ARM_BLANK(103.077641, 157.166346,
                                    -47.5, 0.0, -20.0)
    let pivot: solid = AXIS_BOSS_BLANK(0.0, 0.0, 0.0)
    let middle: solid = AXIS_BOSS_BLANK(95.0, 0.0, -40.0)
    let rear: solid = AXIS_BOSS_BLANK(-95.0, 0.0, -40.0)
    emit compound(middle_arm, rear_arm, pivot, middle, rear)

@meta(assembly.datums=[
    {"id": "rocker_pivot", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]},
    {"id": "middle_axle", "kind": "axis",
     "origin_mm": [95.0, 0.0, -40.0], "direction": [0.0, 1.0, 0.0]},
    {"id": "rear_axle", "kind": "axis",
     "origin_mm": [-95.0, 0.0, -40.0], "direction": [0.0, 1.0, 0.0]}
])
command BOGIE_LAYOUT_PROXY() -> solid:
    emit BOGIE_BLANK()

@meta(assembly.datums=[
    {"id": "rocker_pivot", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]},
    {"id": "middle_axle", "kind": "axis",
     "origin_mm": [95.0, 0.0, -40.0], "direction": [0.0, 1.0, 0.0]},
    {"id": "rear_axle", "kind": "axis",
     "origin_mm": [-95.0, 0.0, -40.0], "direction": [0.0, 1.0, 0.0]}
])
command BOGIE_FINISHED() -> solid:
    let middle_arm: solid = ARM_FILLETED(103.077641, 22.833654,
                                         47.5, 0.0, -20.0)
    let rear_arm: solid = ARM_FILLETED(103.077641, 157.166346,
                                       -47.5, 0.0, -20.0)
    let pivot: solid = AXIS_BOSS_608(0.0, 0.0, 0.0)
    let middle: solid = AXIS_BOSS_608(95.0, 0.0, -40.0)
    let rear: solid = AXIS_BOSS_608(-95.0, 0.0, -40.0)
    emit union(middle_arm, rear_arm, pivot, middle, rear)


command LEFT_WHEEL_CLEARANCE_PROXY() -> solid:
    let centered: solid = translate(cylinder(32.5, 24.0), 0.0, 0.0, -12.0)
    emit translate(rotate(centered, -90.0, 0.0, 0.0), 0.0, 84.0, 0.0)

command RIGHT_WHEEL_CLEARANCE_PROXY() -> solid:
    let centered: solid = translate(cylinder(32.5, 24.0), 0.0, 0.0, -12.0)
    emit translate(rotate(centered, -90.0, 0.0, 0.0), 0.0, -84.0, 0.0)
