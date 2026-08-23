module yaprover_wheel_chassis_interfaces

# Manufacturable OCC prototype for the YapRover wheel/hub and chassis pivot
# interfaces. Coordinates follow the rover convention: +X forward, +Y left,
# +Z up. Wheel and rocker axes point along +Y.

@meta(
    material="PETG",
    assembly.datums=[
        {"id": "axle", "kind": "axis",
         "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]},
        {"id": "inner_bearing_plane", "kind": "plane",
         "origin_mm": [0.0, -10.8, 0.0], "direction": [0.0, -1.0, 0.0]},
        {"id": "outer_bearing_plane", "kind": "plane",
         "origin_mm": [0.0, 10.8, 0.0], "direction": [0.0, 1.0, 0.0]},
    ],
)
command WHEEL_HUB(
    wheel_od_mm: float = 130.0,
    wheel_width_mm: float = 36.0,
    bearing_seat_d_mm: float = 22.15,
    axle_bore_d_mm: float = 8.3,
) -> solid:
    require wheel_od_mm == 130.0, "prototype wheel OD is frozen at 130 mm"
    require wheel_width_mm == 36.0, "prototype wheel width is frozen at 36 mm"
    require bearing_seat_d_mm >= 22.10 and bearing_seat_d_mm <= 22.20, "bad 608 seat"
    require axle_bore_d_mm >= 8.20 and axle_bore_d_mm <= 8.35, "bad axle bore"

    # Rounded 10 mm radial tread/rim, 8 mm axial web/spokes, and an Ø36 hub.
    # The hub leaves 6.925 mm radial PETG around each Ø22.15 bearing seat.
    let outer: solid = fillet(cylinder(wheel_od_mm / 2.0, wheel_width_mm), 2.5)
    let rim_cutter: solid = translate(cylinder(55.0, wheel_width_mm + 2.0),
                                      0.0, 0.0, -1.0)
    let rim: solid = difference(outer, rim_cutter)
    let hub: solid = cylinder(18.0, wheel_width_mm)
    let spoke: solid = translate(box(112.0, 8.0, 8.0), 0.0, 0.0, 14.0)
    let spoke_angles: list<float> = [0.0, 45.0, 90.0, 135.0]
    let spokes: list<solid> = [rotate(spoke, 0.0, 0.0, a) for a in spoke_angles]
    let blank: solid = union_all([rim, hub] + spokes)

    # Two 7.2 mm deep 608 seats enter from the side faces. A continuous Ø8.3
    # bore supports an M8 axle or an independent metal inner-race spacer.
    let seat_r: float = bearing_seat_d_mm / 2.0
    let seat_depth: float = 7.2
    let left_seat: solid = translate(cylinder(seat_r, seat_depth + 0.2),
                                     0.0, 0.0, -0.1)
    let right_seat: solid = translate(cylinder(seat_r, seat_depth + 0.2),
                                      0.0, 0.0,
                                      wheel_width_mm - seat_depth - 0.1)
    let axle_bore: solid = translate(cylinder(axle_bore_d_mm / 2.0,
                                              wheel_width_mm + 0.4),
                                     0.0, 0.0, -0.2)
    let cut: solid = difference_all(blank, [left_seat, right_seat, axle_bore])

    # cylinder() is +Z; center the 36 mm width and rotate the analytic axis +Y.
    emit rotate(translate(cut, 0.0, 0.0, -wheel_width_mm / 2.0),
                -90.0, 0.0, 0.0)


@meta(
    material="PETG",
    assembly.datums=[
        {"id": "axle", "kind": "axis",
         "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]},
    ],
)
command AXLE_SPACER(
    spacer_length_mm: float = 21.4,
    axle_bore_d_mm: float = 8.3,
) -> solid:
    require spacer_length_mm >= 21.0 and spacer_length_mm <= 21.6, "bad spacer length"
    require axle_bore_d_mm >= 8.20 and axle_bore_d_mm <= 8.35, "bad spacer bore"
    let sleeve: solid = cylinder(6.5, spacer_length_mm)
    let bore: solid = translate(cylinder(axle_bore_d_mm / 2.0,
                                         spacer_length_mm + 0.4),
                                0.0, 0.0, -0.2)
    let cut: solid = difference(sleeve, bore)
    emit rotate(translate(cut, 0.0, 0.0, -spacer_length_mm / 2.0),
                -90.0, 0.0, 0.0)


# Reusable cutter for both 608 seats and the M8 running bore. Applying this
# after boss/bridge union prevents adjacent structural ribs from filling seats.
command CHASSIS_PIVOT_CUTTERS(
    side: int,
    bearing_seat_d_mm: float = 22.15,
    axle_bore_d_mm: float = 8.3,
) -> solid:
    require side == -1 or side == 1, "side must be -1 (right) or +1 (left)"
    require bearing_seat_d_mm >= 22.10 and bearing_seat_d_mm <= 22.20, "bad 608 seat"
    require axle_bore_d_mm >= 8.20 and axle_bore_d_mm <= 8.35, "bad pivot bore"

    let boss_length: float = 26.0
    let seat_r: float = bearing_seat_d_mm / 2.0
    let seat_depth: float = 7.2
    let first_seat: solid = translate(cylinder(seat_r, seat_depth + 0.2),
                                      0.0, 0.0, -0.1)
    let second_seat: solid = translate(cylinder(seat_r, seat_depth + 0.2),
                                       0.0, 0.0, boss_length - seat_depth - 0.1)
    let bore: solid = translate(cylinder(axle_bore_d_mm / 2.0,
                                         boss_length + 0.4),
                                0.0, 0.0, -0.2)
    let cutters: solid = union_all([first_seat, second_seat, bore])
    let centered: solid = translate(cutters, 0.0, 0.0, -boss_length / 2.0)
    let on_y: solid = rotate(centered, -90.0, 0.0, 0.0)
    emit translate(on_y, 0.0, side * 142.0, 0.0)


# One paired-608 chassis cartridge, modeled on +Z then rotated onto +Y. The
# command is reusable by chassis segment/detail drawings; side is -1 or +1.
command CHASSIS_PIVOT_CARTRIDGE(
    side: int,
    bearing_seat_d_mm: float = 22.15,
    axle_bore_d_mm: float = 8.3,
) -> solid:
    require side == -1 or side == 1, "side must be -1 (right) or +1 (left)"
    let boss_length: float = 26.0
    let boss: solid = fillet(cylinder(18.0, boss_length), 1.5)
    let centered: solid = translate(boss, 0.0, 0.0, -boss_length / 2.0)
    let on_y: solid = rotate(centered, -90.0, 0.0, 0.0)
    let placed: solid = translate(on_y, 0.0, side * 142.0, 0.0)
    let cutters: solid = CHASSIS_PIVOT_CUTTERS(side,
                                               bearing_seat_d_mm,
                                               axle_bore_d_mm)
    emit difference(placed, cutters)


@meta(
    material="PETG",
    assembly.datums=[
        {"id": "left_rocker", "kind": "axis",
         "origin_mm": [0.0, 155.0, 0.0], "direction": [0.0, 1.0, 0.0]},
        {"id": "right_rocker", "kind": "axis",
         "origin_mm": [0.0, -155.0, 0.0], "direction": [0.0, 1.0, 0.0]},
        {"id": "payload_frame", "kind": "point",
         "origin_mm": [0.0, 0.0, 85.0]},
    ],
)
command CHASSIS_INTERFACE() -> solid:
    # Pivot origin is 140 mm above level ground. The 6 mm floor bottoms at
    # z=-25, preserving the 115 mm nominal belly clearance; the open tub top
    # is z=+85. Side walls are 4 mm, meeting the >=3.2 mm PETG rule.
    let outer: solid = fillet(translate(box(300.0, 205.0, 110.0),
                                        0.0, 0.0, 30.0), 4.0)
    let cavity: solid = translate(box(292.0, 197.0, 106.0),
                                  0.0, 0.0, 34.0)
    let tub: solid = difference(outer, cavity)

    # Filleted load bridges connect the 205 mm tub to paired-bearing bosses.
    let left_bridge: solid = fillet(translate(box(80.0, 54.0, 45.0),
                                              0.0, 115.5, 0.0), 3.0)
    let right_bridge: solid = fillet(translate(box(80.0, 54.0, 45.0),
                                               0.0, -115.5, 0.0), 3.0)
    let left_cartridge: solid = CHASSIS_PIVOT_CARTRIDGE(1)
    let right_cartridge: solid = CHASSIS_PIVOT_CARTRIDGE(-1)
    let assembled: solid = union_all([tub, left_bridge, right_bridge,
                                      left_cartridge, right_cartridge])
    let left_cutters: solid = CHASSIS_PIVOT_CUTTERS(1)
    let right_cutters: solid = CHASSIS_PIVOT_CUTTERS(-1)
    emit difference_all(assembled, [left_cutters, right_cutters])
