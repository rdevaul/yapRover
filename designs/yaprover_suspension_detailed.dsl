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
    # Ø13.2 x 5.6 mm pocket entering from the negative-Y face of a 16 mm
    # wheel-axis boss, for a DIN 7984 M8 low-head socket screw (head Ø13 x
    # 5 mm), which then sits 0.6 mm below the face.  (Was 4.9 deep, sized
    # for a 4 mm head the real DIN 7984 screw doesn't have.)  Mirroring the
    # finished right-hand link puts the pocket on its positive-Y
    # (chassis-facing) side automatically.
    let raw: solid = translate(cylinder(6.6, 5.9), 0.0, 0.0, -2.95)
    let on_y: solid = rotate(raw, -90.0, 0.0, 0.0)
    emit translate(on_y, x, y - 5.35, z)


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
    # Ø8.2 keyed bore (tighter than the Ø8.4 running bores so the hub
    # cannot rock on the shaft) and a 3.1 x 3.1 keyway for a DIN 6885 3x3
    # key: key spans z=2.2..5.2 in a 1.8 mm-deep shaft slot.
    let raw: solid = translate(cylinder(4.1, 18.0), 0.0, 0.0, -9.0)
    let bore: solid = translate(rotate(raw, -90.0, 0.0, 0.0), x, y, z)
    let keyway: solid = translate(box(3.1, 18.0, 3.1),
                                  x, y, z + 3.75)
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
    # Bogie pivot: R20 boss (was R15) leaves 8.85 mm of wall around the
    # paired 608 seats.
    let raw: solid = translate(cylinder(20.0, 16.0), 0.0, 0.0, -8.0)
    let boss: solid = translate(rotate(raw, -90.0, 0.0, 0.0), x, y, z)
    emit difference(boss, AXIS_DUAL_608_CUTTERS(x, y, z))


command ARM_FILLETED(
    length: float, angle_y_deg: float,
    center_x: float, center_y: float, center_z: float
) -> solid:
    # 45-degree chamfers (not fillets) so the link prints flat, Y vertical,
    # without the near-horizontal underside of a round. Chamfer while
    # axis-aligned to keep OCC edge topology predictable.
    let rounded: solid = chamfer(box(length, 16.0, 28.0), 4.0)
    # box() is centred on the origin, so the blank already straddles the line
    # joining the two boss centres, and every call site passes that midpoint
    # as (center_x, center_z).  An extra translate of -14 mm in z used to be
    # applied here, before the aiming rotation, which pushed each arm a half
    # width off that line (-14*sin(angle) in x, -14*cos(angle) in z).  On the
    # bogie that put the rear arm onto the rocker's upper stop pad at about
    # +33 degrees, ahead of the +38 degree tab stop that is meant to take the
    # load.
    let aimed: solid = rotate(rounded, 0.0, angle_y_deg, 0.0)
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
    # Tapered PET-G fin: 20 mm wide at the root (z=8, inside the hub) on a
    # 1:8 taper, narrowing to 7 mm under an R5 nose on R60.
    #
    # The nose is the intended contact: the stop pads are placed tangent to
    # it at the joint limits (for the bogie, an R6 pad centred on R60.3626
    # is tangent to the R5 nose 10.4867 degrees away, which is exactly where
    # BOGIE_STOP_PADS puts it at -35 and +38 degrees).  An earlier 5.4925
    # degree taper left the fin 10 mm wide at the nose, and the flank just
    # below the nose then passed inside the pad radius and touched first,
    # loading a flat flank instead of the nose and interfering by about
    # 2.6 mm3 at every limit.  Relieving the flank by 1.5 mm per side keeps
    # the nose proud without thinning the root, where the bending moment is.
    let root: solid = translate(box(20.0, 16.0, 52.0), 0.0, center_y, 34.0)
    let face: solid = translate(box(100.0, 18.0, 200.0), 50.0, 0.0, 0.0)
    let left_keep: solid = translate(rotate(face, 0.0, 7.1250, 0.0),
                                     -10.0, center_y, 8.0)
    let right_keep: solid = mirror(left_keep, vector(1.0, 0.0, 0.0))
    let fin: solid = intersection(root, left_keep, right_keep)
    let nose: solid = Y_AXIS_CYLINDER(5.0, 16.0, 0.0, center_y, 60.0)
    emit union(fin, nose)


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
    # PET-G ears, 12 mm thick (was 8), r=8..66 from the bogie pivot, aimed at
    # the R6 stop pads.  They stay in the rocker band; only the pads reach
    # into the bogie band.
    let ear: solid = translate(box(58.0, 16.0, 12.0), 37.0, -8.5, 0.0)
    let lower: solid = translate(rotate(ear, 0.0, -41.5185, 0.0),
                                 -95.0, 0.0, -35.0)
    let upper: solid = translate(rotate(ear, 0.0, -135.4812, 0.0),
                                 -95.0, 0.0, -35.0)
    emit union(lower, upper)


command BOGIE_STOP_PADS() -> solid:
    # Range-of-motion stops for the bogie, printed in place on the rocker
    # rear half (rocker component frame).  R6 pads (were R4 TPU) tangent to
    # the R5 bogie tab nose at the -35 / +38 degree limits.  They point up
    # (+Y) when the rear half prints -Y face down.
    let upper: solid = Y_AXIS_CYLINDER(6.0, 20.5, -95.0 - 43.0421, 6.25, -35.0 + 42.3252)
    let lower: solid = Y_AXIS_CYLINDER(6.0, 20.5, -95.0 + 45.1963, 6.25, -35.0 + 40.0123)
    emit union(upper, lower)


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
    # Half-hub swapped to the +Y layer (y=-8.5..-0.5) so the rear piece can
    # print -Y face down with its in-place limit pads pointing up.  This
    # piece prints +Y face down; the retention recess moves here with it.
    let center: solid = AXIS_BOSS_KEYED_HALF(0.0, -4.5, 0.0)
    let front: solid = AXIS_BOSS_WHEEL_AXLE(190.0, -8.5, -75.0)
    let joined: solid = union(arm, center, front,
                              LIMIT_CONTACT_TAB(-8.5))
    emit difference(joined, AXIS_KEYED_CUTTERS(0.0, -8.5, 0.0),
                    AXIS_BOSS_HALF_BLANK(0.0, -12.5, 0.0),
                    AXIS_OUTBOARD_RETENTION_CUTTER(0.0, -8.5, 0.0),
                    AXIS_BORE_CUTTERS(190.0, -8.5, -75.0),
                    AXIS_LOW_HEAD_CUTTER(190.0, -8.5, -75.0))


command ROCKER_REAR_COMPONENT() -> solid:
    # C -> B = (-95, -35) mm. Complementary 8 mm center half-hubs join the
    # two bed-sized pieces within one 16 mm rocker band.
    let arm: solid = ARM_FILLETED(101.242284, 159.775141,
                                  -47.5, -8.5, -17.5)
    # Half-hub on the -Y layer (y=-16.5..-8.5).  Prints -Y face down; the
    # bogie range-of-motion stop pads are printed in place on the +Y face
    # (formerly separate press-in TPU bumpers).
    let center: solid = AXIS_BOSS_KEYED_HALF(0.0, -12.5, 0.0)
    let bogie: solid = AXIS_BOSS_BORE(-95.0, -8.5, -35.0)
    let joined: solid = union(arm, center, bogie,
                              BOGIE_LIMIT_MOUNT_EARS())
    let cut: solid = difference(joined, AXIS_KEYED_CUTTERS(0.0, -4.5, 0.0),
                                AXIS_BOSS_HALF_BLANK(0.0, -4.5, 0.0),
                                AXIS_BORE_CUTTERS(-95.0, -8.5, -35.0))
    emit union(cut, BOGIE_STOP_PADS())


command ROCKER_ONE_PIECE() -> solid:
    # One-piece rocker (fits a Bambu H2S rotated ~126 deg on the bed, about
    # 161 x 334 mm).  The split version passed each arm's moment between
    # the halves only through the 2 mm key (SF 0.05 in a 3 g bump); one
    # piece balances the arm moments internally, so the shaft key carries
    # only the differential torque.  Full 16 mm R20 keyed hub.  Prints -Y
    # face down with the bogie stop pads pointing up.
    let front_arm: solid = ARM_FILLETED(204.266982, 21.540976,
                                        95.0, -8.5, -37.5)
    let rear_arm: solid = ARM_FILLETED(101.242284, 159.775141,
                                       -47.5, -8.5, -17.5)
    let hub: solid = Y_AXIS_CYLINDER(20.0, 16.0, 0.0, -8.5, 0.0)
    let front: solid = AXIS_BOSS_WHEEL_AXLE(190.0, -8.5, -75.0)
    let bogie: solid = AXIS_BOSS_BORE(-95.0, -8.5, -35.0)
    let joined: solid = union(front_arm, rear_arm, hub, front, bogie,
                              LIMIT_CONTACT_TAB(-8.5),
                              BOGIE_LIMIT_MOUNT_EARS())
    let cut: solid = difference(joined, AXIS_KEYED_CUTTERS(0.0, -8.5, 0.0),
                                AXIS_OUTBOARD_RETENTION_CUTTER(0.0, -8.5, 0.0),
                                AXIS_BORE_CUTTERS(190.0, -8.5, -75.0),
                                AXIS_LOW_HEAD_CUTTER(190.0, -8.5, -75.0),
                                AXIS_BORE_CUTTERS(-95.0, -8.5, -35.0))
    emit union(cut, BOGIE_STOP_PADS())


command FRONT_AXLE_SLEEVE(side: int) -> solid:
    # Printed support sleeve on the outboard face of the rocker's front
    # wheel boss.  The front wheel sits 23 mm outboard of the rocker, so the
    # M8 axle and its 22.8 mm steel spacer used to hang off an 11 mm-long
    # hole in a 16 mm boss: once the PETG under the clamp crept, the hole's
    # clearance let the wheel camber in about 2 deg and the bolt crushed
    # the hole oval in side loads.  The sleeve is the boss's R15 carried out
    # 17.5 mm, keeping the 5 mm wheel-to-structure clearance, bored Ø13.4
    # around the steel spacer (which still carries the clamp to the boss
    # face), so the axle is supported over about 28 mm instead of 11.  Prints pointing up (rocker
    # prints -Y face down) with a 45 deg chamfer at the free end.
    let body: solid = cylinder(15.0, 15.5)
    let chamfer_end: solid = translate(cone(15.0, 13.0, 2.0), 0.0, 0.0, 15.5)
    let raw: solid = union(body, chamfer_end)
    emit translate(rotate(raw, side * -90.0, 0.0, 0.0),
                   190.0, side * -40.5, -75.0)


command FRONT_AXLE_SLEEVE_BORE(side: int) -> solid:
    # Ø13.4 around the Ø13 steel spacer; ends at the original boss face.
    emit Y_AXIS_CYLINDER(6.7, 17.7, 190.0, side * -31.65, -75.0)


command ROCKER_FINISHED(side: int) -> solid:
    require side == -1 or side == 1, "side must be -1 (right) or +1 (left)"
    let placed: solid = translate(ROCKER_ONE_PIECE(), 0.0, side * -40.0, 0.0)
    emit difference(union(placed, FRONT_AXLE_SLEEVE(side)),
                    FRONT_AXLE_SLEEVE_BORE(side))


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


command MARS_GROUSER(angle_deg: float) -> solid:
    # One 3-segment zigzag grouser across the 54 mm tread (z=-18..36): three
    # 18 mm legs alternating +/-20 degrees, vertices at z=0 and z=18.  The
    # zigzag is point-symmetric about the tread centre, so a wheel turned
    # 180 degrees about vertical (the right-hand side) shows the same tread
    # and grips the same both ways -- one wheel part for all six positions.
    # Printed axle-vertical, each leg leans only 20 degrees from vertical.
    # Legs run 20.7 mm (18/cos20 + overlap) so the vertices are solid; the
    # ends are trimmed by the wheel slab.
    let leg_a: solid = rotate(box(3.5, 2.6, 20.7), -20.0, 0.0, 0.0)
    let leg_b: solid = rotate(box(3.5, 2.6, 20.7), 20.0, 0.0, 0.0)
    let zigzag: solid = union(translate(leg_a, 65.75, 0.0, -9.0),
                              translate(leg_b, 65.75, 0.0, 9.0),
                              translate(leg_a, 65.75, 0.0, 27.0))
    emit rotate(zigzag, 0.0, 0.0, angle_deg)


command MARS_SPOKE(angle_deg: float) -> solid:
    # Curiosity-style curved flexure spoke: a 7 mm-wide circular arc
    # (R40 about a point 40 mm off-centre) lying on the inboard face, 9 mm
    # thick.  Both ends are buried -- the inner end inside the R14.5 hub, the
    # outer end inside the R62.5..65 tread skin -- so no corner shows.
    let arc_ring: solid = translate(difference(cylinder(43.5, 9.0),
                                               cylinder(36.5, 9.0)),
                                    40.0, 0.0, -18.0)
    let wheel_band: solid = translate(difference(cylinder(63.5, 9.0),
                                                 cylinder(12.5, 9.0)),
                                      0.0, 0.0, -18.0)
    let upper_half: solid = translate(box(140.0, 70.0, 9.0), 0.0, 35.0, -13.5)
    let spoke: solid = intersection(arc_ring, wheel_band, upper_half)
    emit rotate(spoke, 0.0, 0.0, angle_deg)


command WHEEL_HUB() -> solid:
    # Ø135 (over grousers) x 54 mm Mars-style wheel, supportless FDM:
    # print INBOARD face down (spokes on the bed), open cup up.  The inboard
    # face stays at the original position (5.5 mm bogie clearance); the extra
    # 18 mm of width is outboard, so the wheel spans local z=-18..36.
    # 2.5 mm tread skin, 24 chevron grousers 2.5 mm tall, six 9 mm curved
    # spokes.
    # Hub: short R14.5 x 22.5 mm boss on the spoke face (z=-18..4.5) so the
    # outboard bearing, washer and nut sit near the spokes and are easy to
    # reach through the open 125 mm cup.  Paired 608s at z=-14.2 and +0.5 in
    # Ø22.15 seats (light press in a printed hole), each open to its own
    # face so it presses in from that side; 7.6 mm shoulder between them.
    # The bore step above the bed-side seat is a ~50-degree cone.
    let skin: solid = difference(translate(cylinder(65.0, 54.0), 0.0, 0.0, -18.0),
                                 translate(cylinder(62.5, 56.0), 0.0, 0.0, -19.0))
    let hub: solid = translate(cylinder(14.5, 22.5), 0.0, 0.0, -18.0)
    let grouser_angles: list<float> = [i * 15.0 for i in range(24)]
    let grousers: list<solid> = [MARS_GROUSER(a) for a in grouser_angles]
    let spoke_angles: list<float> = [i * 60.0 for i in range(6)]
    let spokes: list<solid> = [MARS_SPOKE(a) for a in spoke_angles]
    let raw: solid = union_all([skin, hub] + grousers + spokes)
    let slab: solid = translate(cylinder(70.0, 54.0), 0.0, 0.0, -18.0)
    let blank: solid = intersection(raw, slab)
    let inboard_seat: solid = translate(cylinder(11.075, 7.4), 0.0, 0.0, -18.1)
    let seat_lead: solid = translate(cone(9.5, 6.25, 3.9), 0.0, 0.0, -10.75)
    let outboard_seat: solid = translate(cylinder(11.075, 7.6), 0.0, 0.0, -3.0)
    let bore: solid = translate(cylinder(6.25, 22.9), 0.0, 0.0, -18.2)
    let cut: solid = difference_all(blank, [inboard_seat, seat_lead,
                                            outboard_seat, bore])
    emit rotate(cut, -90.0, 0.0, 0.0)


@meta(material="PETG", component.id="wheel_135x54",
      component.name="Printed 135 x 54 mm Mars-style rover wheel",
      component.disposition="make", manufacturing.process="FDM",
      assembly.datums=[
    {"id": "axle", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command LEFT_WHEEL() -> solid:
    # Wheel center lies on the annotated y=+155 mm axle plane, restoring the
    # original 310 mm track while retaining 5.5 mm link-to-wheel clearance.
    emit WHEEL_HUB()


@meta(material="PETG", component.id="wheel_135x54",
      component.name="Printed 135 x 54 mm Mars-style rover wheel",
      component.disposition="make", manufacturing.process="FDM",
      assembly.datums=[
    {"id": "axle", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, -1.0, 0.0]}
])
command RIGHT_WHEEL() -> solid:
    # The SAME part as LEFT_WHEEL (identical geometry and component id).  Its
    # axle datum points -Y, so the mate turns it 180 degrees about vertical:
    # spoke face (print bed face) inboard on this side too, and the
    # point-symmetric zigzag tread reads the same as on the left.
    emit WHEEL_HUB()


# ---------------------------------------------------------------------------
# Metric running hardware: M8 axle bolts, machined pivot shafts, nuts,
# washers, 608-2RS bearings, and metal spacer tubes. Wrapper commands retain
# one named axle datum per part.

command AXLE_SHAFT(length_mm: float, center_y: float) -> solid:
    # Shafts/threads are simplified as Ø7.9 cylinders, providing 0.4 mm
    # diametral clearance in Ø8.3 printed bores. Inspect real journal fits.
    let raw: solid = translate(cylinder(3.95, length_mm),
                               0.0, 0.0, -length_mm / 2.0)
    emit translate(rotate(raw, -90.0, 0.0, 0.0), 0.0, center_y, 0.0)


command SHAFT_KEY(length_mm: float, center_y: float) -> solid:
    # DIN 6885 3 x 3 parallel key seated in a 1.8 mm-deep shaft slot
    # (z=2.2..5.2), engaging the hub keyway by ~1.1 mm.  The old 2 mm key in
    # a 2.7 mm slot could sit below the hub bore and carry no torque.
    emit translate(box(3.0, length_mm, 3.0), 0.0, center_y, 3.7)


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


command M8_NUT(start_y: float, direction: float) -> solid:
    # DIN 985 M8 nylon-insert locknut: 13 mm across flats, 6.0 mm steel hex
    # (corners chamfered 30 deg) plus a Ø12 x 2.0 mm insert collar, 8.0 mm
    # overall -- the envelope of the BOM's 90453A115 or taller.  start_y is
    # the bearing face (on the washer); direction (+1/-1) is the way the
    # collar points along Y.  Exact BREP: a cylinder trimmed by six outside
    # boxes (the library metric_hex_nut dropped out of exported compounds).
    let blank: solid = cylinder(7.5, 6.0)
    let flat: solid = translate(box(10.0, 30.0, 10.0), 11.5, 0.0, 3.0)
    let flats: list<solid> = [rotate(flat, 0.0, 0.0, i * 60.0) for i in range(6)]
    let corner_low: solid = difference(translate(cylinder(9.0, 1.73), 0.0, 0.0, -0.5),
                                       translate(cone(6.0, 9.0, 1.73), 0.0, 0.0, -0.5))
    let corner_high: solid = difference(translate(cylinder(9.0, 1.73), 0.0, 0.0, 4.77),
                                        translate(cone(9.0, 6.0, 1.73), 0.0, 0.0, 4.77))
    let collar: solid = translate(cylinder(6.0, 2.0), 0.0, 0.0, 6.0)
    let bore: solid = translate(cylinder(4.0, 8.4), 0.0, 0.0, -0.2)
    let nut: solid = difference(union(difference_all(blank, flats + [corner_low, corner_high]), collar), bore)
    emit translate(rotate(nut, direction * -90.0, 0.0, 0.0), 0.0, start_y, 0.0)


command M8_LOW_HEAD(underside_y: float) -> solid:
    # DIN 7984 M8 low-head socket cap screw head: Ø13 x 5 mm, 0.5 mm edge
    # chamfer, 5 mm hex socket 3.5 deep.  The head points -Y from underside_y
    # (it sits in the boss counterbore, 0.6 mm below the inboard face).
    let head: solid = chamfer(cylinder(6.5, 5.0), 0.5)
    let hex_blank: solid = translate(cylinder(2.9, 3.7), 0.0, 0.0, -0.1)
    let hex_flat: solid = translate(box(4.0, 12.0, 6.0), 4.5, 0.0, 1.5)
    let hex_flats: list<solid> = [rotate(hex_flat, 0.0, 0.0, i * 60.0) for i in range(6)]
    let socket: solid = difference_all(hex_blank, hex_flats)
    let raw: solid = difference(head, socket)
    # Local z=0 is the socket face; z=5 is the underside.
    emit translate(rotate(raw, -90.0, 0.0, 0.0), 0.0, underside_y - 5.0, 0.0)


command AXLE_SPACER(length_mm: float, center_y: float) -> solid:
    let sleeve: solid = translate(cylinder(6.5, length_mm),
                                  0.0, 0.0, -length_mm / 2.0)
    let bore: solid = translate(cylinder(4.15, length_mm + 0.4),
                                0.0, 0.0, -length_mm / 2.0 - 0.2)
    let cut: solid = difference(sleeve, bore)
    emit translate(rotate(cut, -90.0, 0.0, 0.0), 0.0, center_y, 0.0)


command BEARING_608(center_y: float) -> solid:
    # Nominal 608-2RS: Ø22 x 7 with Ø8 bore. Ring/seal profiles simplified.
    let outer: solid = difference(cylinder(11.0, 7.0),
                                  cylinder(8.0, 7.0))
    let inner: solid = difference(cylinder(6.25, 7.0),
                                  cylinder(4.0, 7.0))
    let shield_blank: solid = translate(cylinder(8.0, 0.5), 0.0, 0.0, 0.25)
    let shield_bore: solid = translate(cylinder(6.25, 0.7),
                                       0.0, 0.0, 0.15)
    let shield: solid = difference(shield_blank, shield_bore)
    let far_shield: solid = translate(shield, 0.0, 0.0, 6.0)
    let bearing: solid = compound(outer, inner, shield, far_shield)
    let centered: solid = translate(bearing, 0.0, 0.0, -3.5)
    emit translate(rotate(centered, -90.0, 0.0, 0.0), 0.0, center_y, 0.0)


command LEFT_WHEEL_AXLE_SHAFT_GEOMETRY() -> solid:
    # DIN 7984 M8 x 70 low-head axle bolt. The modeled shank runs from the
    # recessed head underside at y=-50.9 mm to y=+19.1 mm; the head's socket
    # face is at y=-55.9, 0.6 mm inside the printed link face (y=-56.5).
    emit compound(AXLE_SHAFT(70.0, -15.9), M8_LOW_HEAD(-50.9))


command LEFT_WHEEL_AXLE_SPACER_GEOMETRY() -> solid:
    # Bridges the common suspension band to the wheel's inboard bearing face.
    emit AXLE_SPACER(22.8, -29.1)


command LEFT_BOGIE_WHEEL_AXLE_SHAFT_GEOMETRY() -> solid:
    # The outboard bogie band uses a shorter DIN 7984 M8 x 55.  Its recessed
    # head's socket face is at y=-38.9 (link face -39.5); the shank runs
    # -33.9..+21.1 mm.
    emit compound(AXLE_SHAFT(55.0, -6.4), M8_LOW_HEAD(-33.9))


command LEFT_BOGIE_WHEEL_AXLE_SPACER_GEOMETRY() -> solid:
    # The wheel remains on the common y=155 mm plane, leaving a short spacer
    # between the outboard bogie face and the wheel's inboard bearing.
    emit AXLE_SPACER(5.8, -20.6)


command LEFT_WHEEL_AXLE_HARDWARE_GEOMETRY() -> solid:
    # The recessed bolt head replaces the collision-prone inboard washer/nut.
    # Washer on the outboard bearing's face (z=4.0), nyloc above it.
    emit compound(M8_WASHER(4.8), M8_NUT(5.6, 1.0))


command LEFT_WHEEL_BEARING_GEOMETRY() -> solid:
    emit compound(BEARING_608(-14.2), BEARING_608(0.5))


@meta(material="steel spacer tube", component.id="wheel_inner_spacer_12x8p3x7p7",
      component.name="Wheel inner-race spacer, 12 x 8.3 x 7.7 mm",
      component.disposition="raw_stock", manufacturing.process="cut_to_length",
      manufacturing.instructions="Face to measured bearing shoulder separation; verify free rotation with retention tightened",
      assembly.datums=[
    {"id": "axle", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command WHEEL_INNER_RACE_SPACER() -> solid:
    emit WHEEL_INNER_RACE_SPACER_GEOMETRY()


command WHEEL_INNER_RACE_SPACER_GEOMETRY() -> solid:
    # Seated 7 mm bearings at -14.2 and +0.5 have inner faces at -10.7 and
    # -3.0 mm.  OD12 clears the hub's OD12.5 passage and bears only on the
    # inner rings.
    let blank: solid = Y_AXIS_CYLINDER(6.0, 7.7, 0.0, -6.85, 0.0)
    let bore: solid = Y_AXIS_CYLINDER(4.15, 8.4, 0.0, -6.85, 0.0)
    emit difference(blank, bore)


@meta(material="steel spacer tube", component.id="wheel_inner_spacer_12x8p3x7p7_right",
      component.name="Wheel inner-race spacer, 12 x 8.3 x 7.7 mm (right hand)",
      component.disposition="raw_stock", manufacturing.process="cut_to_length",
      manufacturing.instructions="Face to measured bearing shoulder separation; verify free rotation with retention tightened",
      assembly.datums=[
    {"id": "axle", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command RIGHT_WHEEL_INNER_RACE_SPACER() -> solid:
    emit mirror(WHEEL_INNER_RACE_SPACER_GEOMETRY(), vector(0.0, 1.0, 0.0))


command LEFT_CHASSIS_PIVOT_BEARING_GEOMETRY() -> solid:
    emit compound(BEARING_608(-73.9), BEARING_608(-61.1))


command LEFT_BOGIE_PIVOT_BEARING_GEOMETRY() -> solid:
    # Follow the bogie into its outboard suspension band.
    emit compound(BEARING_608(-36.0), BEARING_608(-27.0))


@meta(material="alloy steel", component.id="wheel_axle_m8x70_low_head",
      component.name="M8 x 70 low-head wheel axle bolt",
      component.disposition="buy", procurement.specification="M8 x 70 low head",
      assembly.datums=[
    {"id": "axle", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command LEFT_WHEEL_AXLE_SHAFT() -> solid:
    emit LEFT_WHEEL_AXLE_SHAFT_GEOMETRY()


@meta(material="alloy steel", component.id="wheel_axle_m8x70_low_head_right",
      component.name="M8 x 70 low-head wheel axle bolt (right hand)",
      component.disposition="buy", procurement.specification="M8 x 70 low head",
      assembly.datums=[
    {"id": "axle", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command RIGHT_WHEEL_AXLE_SHAFT() -> solid:
    emit mirror(LEFT_WHEEL_AXLE_SHAFT_GEOMETRY(), vector(0.0, 1.0, 0.0))


@meta(material="alloy steel", component.id="bogie_wheel_axle_m8x55_low_head",
      component.name="M8 x 55 low-head bogie wheel axle bolt",
      component.disposition="buy", procurement.specification="M8 x 55 low head",
      assembly.datums=[
    {"id": "axle", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command LEFT_BOGIE_WHEEL_AXLE_SHAFT() -> solid:
    emit LEFT_BOGIE_WHEEL_AXLE_SHAFT_GEOMETRY()


@meta(material="alloy steel",
      component.id="bogie_wheel_axle_m8x55_low_head_right",
      component.name="M8 x 55 low-head bogie wheel axle bolt (right hand)",
      component.disposition="buy", procurement.specification="M8 x 55 low head",
      assembly.datums=[
    {"id": "axle", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command RIGHT_BOGIE_WHEEL_AXLE_SHAFT() -> solid:
    emit mirror(LEFT_BOGIE_WHEEL_AXLE_SHAFT_GEOMETRY(),
                vector(0.0, 1.0, 0.0))


@meta(material="steel spacer tube", component.id="wheel_spacer_13x8p3x22p8",
      component.name="Wheel axle spacer, 13 x 8.3 x 22.8 mm",
      component.disposition="raw_stock", manufacturing.process="cut_to_length",
      assembly.datums=[
    {"id": "axle", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command LEFT_WHEEL_AXLE_SPACER() -> solid:
    emit LEFT_WHEEL_AXLE_SPACER_GEOMETRY()


@meta(material="steel spacer tube", component.id="wheel_spacer_13x8p3x22p8_right",
      component.name="Wheel axle spacer, 13 x 8.3 x 22.8 mm (right hand)",
      component.disposition="raw_stock", manufacturing.process="cut_to_length",
      assembly.datums=[
    {"id": "axle", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command RIGHT_WHEEL_AXLE_SPACER() -> solid:
    emit mirror(LEFT_WHEEL_AXLE_SPACER_GEOMETRY(), vector(0.0, 1.0, 0.0))


@meta(material="steel spacer tube", component.id="bogie_wheel_spacer_5p8mm",
      component.name="Bogie wheel axle spacer, 13 x 8.3 x 5.8 mm",
      component.disposition="raw_stock", manufacturing.process="cut_to_length",
      assembly.datums=[
    {"id": "axle", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command LEFT_BOGIE_WHEEL_AXLE_SPACER() -> solid:
    emit LEFT_BOGIE_WHEEL_AXLE_SPACER_GEOMETRY()


@meta(material="steel spacer tube",
      component.id="bogie_wheel_spacer_5p8mm_right",
      component.name="Bogie wheel axle spacer, 13 x 8.3 x 5.8 mm (right hand)",
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
    emit mirror(LEFT_WHEEL_BEARING_GEOMETRY(), vector(0.0, 1.0, 0.0))


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
    let shaft: solid = AXLE_SHAFT(106.5, -93.75)
    # Milled 3.05 mm x 1.8 mm-deep slots for the 3x3 keys; extend past each
    # key end.  The gear key now also runs under the side gear's new hub.
    # The gear slot runs 1 mm out of the shaft's inboard end (shaft spans
    # y = -147.0 .. -40.5).  Closed, it left 3 mm of solid shaft there, and
    # the key then had to be fed in through the carrier 608 against a cross
    # pin that caps overtravel at 4 mm, so it could not be fitted at all.
    let rocker_slot: solid = translate(box(3.05, 14.5, 3.0),
                                         0.0, -50.25, 3.7)
    let gear_slot: solid = translate(box(3.05, 20.5, 3.0),
                                       0.0, -137.75, 3.7)
    emit difference(shaft, rocker_slot, gear_slot)


command LEFT_ROCKER_PIVOT_KEYS_GEOMETRY() -> solid:
    # Stop at the bottom of the recessed washer/clip pocket.
    emit compound(SHAFT_KEY(12.5, -50.25),
                  SHAFT_KEY(14.5, -135.75))


command LEFT_ROCKER_PIVOT_HARDWARE_GEOMETRY() -> solid:
    emit compound(M8_RETAINING_CLIP(-143.8),
                  M8_WASHER(-42.85), M8_RETAINING_CLIP(-41.35))


command LEFT_BOGIE_PIVOT_SHAFT_GEOMETRY() -> solid:
    emit AXLE_SHAFT(51.5, -40.75)


command LEFT_BOGIE_PIVOT_HARDWARE_GEOMETRY() -> solid:
    emit compound(M8_WASHER(-57.4), M8_NUT(-58.2, -1.0),
                  M8_WASHER(-22.6), M8_NUT(-21.8, 1.0))


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


@meta(material="3 mm steel key stock (DIN 6885 A 3x3)", component.disposition="raw_stock",
      manufacturing.process="cut_to_length", assembly.datums=[
    {"id": "axle", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command LEFT_ROCKER_PIVOT_KEYS() -> solid:
    emit LEFT_ROCKER_PIVOT_KEYS_GEOMETRY()


@meta(material="3 mm steel key stock (DIN 6885 A 3x3)", component.disposition="raw_stock",
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


command GEAR_TIP_CHAMFER_ENVELOPE() -> solid:
    # Keep r + z <= 37.65 about the pitch apex.  The blank's flat heel (z=18)
    # meets the 48.4-degree tip cone in a 41.6-degree knife edge at r=20.25;
    # this back-cone cut (perpendicular to the 45-degree pitch cone) trims it
    # to ~93 degrees: 0.6 mm on the heel face x 0.42 mm along the tip, above
    # the 18 mm pitch radius so only addendum (tip relief) is removed.  The
    # face looks up-and-out in the toe-down print pose.  Hubs stay inside it.
    emit cone(37.65, 0.0, 37.65)


command GEAR_BORE_CHAMFERS(top_z: float) -> solid:
    # 0.5 x 45-degree lead-ins on both bore ends: the toe face sits on the
    # bed (counters elephant's foot), the hub end eases the press onto the
    # shaft.  The lower one is a 45-degree overhang, printable.
    emit union(translate(cone(4.7, 4.1, 0.6), 0.0, 0.0, 12.243),
               translate(cone(4.1, 4.7, 0.6), 0.0, 0.0, top_z - 0.5))


command MITER_SIDE_GEAR_Z() -> solid:
    # Ø18 x 9 mm hub on the back face (local z=18..27, clear of the carrier
    # bearing at 28.5) gives the 3x3 key 14.7 mm of engagement instead of
    # 5.7.  After the -90 degree X rotation local -Y becomes chassis +Z, so
    # the keyway sits there.  Print toe (small face) down, hub up.
    let blank: solid = MITER_GEAR_BLANK()
    let hub: solid = translate(cylinder(9.0, 9.0), 0.0, 0.0, 18.0)
    let bore: solid = translate(cylinder(4.1, 16.0), 0.0, 0.0, 12.0)
    let keyway: solid = translate(box(3.1, 3.1, 16.0), 0.0, -3.75, 20.0)
    let body: solid = intersection(union(blank, hub), GEAR_TIP_CHAMFER_ENVELOPE())
    emit difference(body, bore, keyway, GEAR_BORE_CHAMFERS(27.0))


command MITER_PLANET_GEAR_Z() -> solid:
    # Extend the back face into a Ø16 mm thrust hub.  The hub ends 1.5 mm
    # inboard of the carrier tower, leaving room for a 1 mm low-friction
    # washer and 0.5 mm total axial running clearance.
    let blank: solid = MITER_GEAR_BLANK()
    let hub: solid = translate(cylinder(8.0, 9.0), 0.0, 0.0, 17.5)
    let bore: solid = translate(cylinder(4.2, 15.0), 0.0, 0.0, 12.0)
    let body: solid = intersection(union(blank, hub), GEAR_TIP_CHAMFER_ENVELOPE())
    emit difference(body, bore, GEAR_BORE_CHAMFERS(26.5))


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
    # Starts at z=-19 with the rails so the cradle prints upright from one
    # bed plane (it used to hang to z=-29 and start in mid-air); 7.85 mm of
    # wall remains under the seat.  Teardrop seat for the horizontal axis.
    let plate: solid = chamfer(translate(box(60.0, 8.0, 48.0),
                                        0.0, side * 32.0, 5.0), 3.0)
    let cutter: solid = TEARDROP_Y(11.15, 10.0, 0.0, side * 32.0, 0.0)
    emit difference(plate, cutter)


command DIFFERENTIAL_PIN_TOWER(side: int) -> solid:
    require side == -1 or side == 1, "side must be -1 or +1"
    # Starts at z=-19 (was -25, an island); teardrop pin hole.
    let tower: solid = chamfer(translate(box(8.0, 20.0, 44.0),
                                        side * 32.0, 0.0, 3.0), 2.0)
    let cutter: solid = translate(rotate(TEARDROP_Y(4.2, 10.0, 0.0, 0.0, 0.0),
                                         0.0, 0.0, 90.0),
                                  side * 32.0, 0.0, 0.0)
    emit difference(tower, cutter)


command WEDGE_Y(width: float, h: float, cx: float, y0: float, z0: float,
               dir: float) -> solid:
    # 45-degree gusset: right-triangle prism, legs h along +Y*dir and +Z,
    # vertical leg on the plane y=y0, horizontal leg on z=z0, length `width`
    # along X.  Its sloped face looks up, so it prints without support.
    let bounds: solid = translate(box(width, h, h), cx, y0 + dir * h / 2.0,
                                  z0 + h / 2.0)
    let cube: solid = rotate(box(width + 2.0, 4.0 * h, 4.0 * h), 45.0, 0.0, 0.0)
    let keep: solid = translate(cube, cx, y0 - dir * 1.41421356 * h,
                                z0 + h - 1.41421356 * h)
    emit intersection(bounds, keep)


command WEDGE_X(width: float, h: float, x0: float, cy: float, z0: float,
               dir: float) -> solid:
    let along_y: solid = WEDGE_Y(width, h, cy, -x0 * dir, z0, -1.0)
    emit rotate(along_y, 0.0, 0.0, -90.0 * dir)


command DIFFERENTIAL_CRADLE() -> solid:
    # Base frame 120 x 96 x 8 mm (z=-19..-11) with a 52 x 56 gear window,
    # replacing the two rails and four small feet.  45-degree gussets tie
    # the bearing plates and pin towers into it, and eight M4 bolts hold it
    # to the deck (was four).
    let outer: solid = chamfer(translate(box(120.0, 96.0, 8.0), 0.0, 0.0, -15.0), 1.5)
    let window: solid = translate(box(52.0, 56.0, 10.0), 0.0, 0.0, -15.0)
    let base: solid = difference(outer, window)
    # Plate gussets are notched 12 mm wide down to z=-6 so the Ø8 rocker
    # shafts pass out through them with 2 mm clearance (vertical notch walls,
    # open top: still supportless).
    let shaft_notch: solid = compound(translate(box(12.0, 14.0, 12.0), 0.0, 42.0, 0.0),
                                      translate(box(12.0, 14.0, 12.0), 0.0, -42.0, 0.0))
    let plate_gussets: solid = difference(
        union(WEDGE_Y(44.0, 12.0, 0.0, 36.0, -11.0, 1.0),
              WEDGE_Y(44.0, 12.0, 0.0, -36.0, -11.0, -1.0)), shaft_notch)
    # Pin-tower gussets on the outboard X faces are cut flat at z=-9, 1 mm
    # under the cross-pin head (R6.5) and the M8 washer stack (R8) that
    # spaces the 80 mm shoulder screw (92981A230) to the 72 mm tower span;
    # full-height 45-degree
    # gussets on both Y faces of each tower take over the bracing.
    # (difference, not intersection: the latter drops this to a mesh.)
    let above_pin: solid = translate(box(120.0, 30.0, 20.0), 0.0, 0.0, 1.0)
    let x_gussets: solid = difference(
        union(WEDGE_X(20.0, 12.0, 36.0, 0.0, -11.0, 1.0),
              WEDGE_X(20.0, 12.0, -36.0, 0.0, -11.0, -1.0)), above_pin)
    let y_gussets: solid = union(WEDGE_Y(8.0, 12.0, 32.0, 10.0, -11.0, 1.0),
                                 WEDGE_Y(8.0, 12.0, 32.0, -10.0, -11.0, -1.0),
                                 WEDGE_Y(8.0, 12.0, -32.0, 10.0, -11.0, 1.0),
                                 WEDGE_Y(8.0, 12.0, -32.0, -10.0, -11.0, -1.0))
    let tower_gussets: solid = union(x_gussets, y_gussets)
    let frame: solid = union(base, plate_gussets, tower_gussets,
                             DIFFERENTIAL_BEARING_PLATE(1),
                             DIFFERENTIAL_BEARING_PLATE(-1),
                             DIFFERENTIAL_PIN_TOWER(1),
                             DIFFERENTIAL_PIN_TOWER(-1))
    emit difference(frame, DIFFERENTIAL_CRADLE_FASTENER_CUTTERS())


command DIFFERENTIAL_CRADLE_FASTENER_CUTTERS() -> solid:
    let hole: solid = translate(cylinder(2.2, 24.0), 0.0, 0.0, -30.0)
    emit compound(translate(hole, 52.0, 40.0, 0.0),
                  translate(hole, 52.0, 13.0, 0.0),
                  translate(hole, 52.0, -13.0, 0.0),
                  translate(hole, 52.0, -40.0, 0.0),
                  translate(hole, -52.0, 40.0, 0.0),
                  translate(hole, -52.0, 13.0, 0.0),
                  translate(hole, -52.0, -13.0, 0.0),
                  translate(hole, -52.0, -40.0, 0.0))


@meta(material="M4 x 25 steel screw and nyloc nut", component.disposition="buy",
      component.quantity=8.0, procurement.specification="M4 x 25", assembly.datums=[
    {"id": "mount", "kind": "point", "origin_mm": [0.0, 0.0, 0.0]}
])
command DIFFERENTIAL_CRADLE_FASTENERS() -> solid:
    # Head on the cradle foot (z=-11), nyloc under the 10 mm deck (z=-29).
    let shaft: solid = translate(cylinder(2.0, 22.0), 0.0, 0.0, -33.0)
    let head: solid = translate(cylinder(3.5, 3.0), 0.0, 0.0, -11.0)
    let nut: solid = translate(cylinder(4.0, 4.0), 0.0, 0.0, -33.0)
    let fastener: solid = compound(shaft, head, nut)
    emit compound(translate(fastener, 52.0, 40.0, 0.0),
                  translate(fastener, 52.0, 13.0, 0.0),
                  translate(fastener, 52.0, -13.0, 0.0),
                  translate(fastener, 52.0, -40.0, 0.0),
                  translate(fastener, -52.0, 40.0, 0.0),
                  translate(fastener, -52.0, 13.0, 0.0),
                  translate(fastener, -52.0, -13.0, 0.0),
                  translate(fastener, -52.0, -40.0, 0.0))


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


command TEARDROP_Y(radius: float, length: float,
                   cx: float, cy: float, cz: float) -> solid:
    # Horizontal (Y-axis) hole with a 45-degree roof so it prints without
    # support: round below the 45-degree tangent points, peaked above.
    let round: solid = Y_AXIS_CYLINDER(radius, length, cx, cy, cz)
    let diamond: solid = translate(rotate(box(2.0 * radius, length, 2.0 * radius),
                                          0.0, 45.0, 0.0), cx, cy, cz)
    let roof_h: float = 0.70710678 * radius
    let clip: solid = translate(box(4.0 * radius, length, roof_h + 0.01),
                                cx, cy, cz + roof_h * 1.5)
    emit union(round, intersection(diamond, clip))


command CHASSIS_PIVOT_CUTTERS(side: int) -> solid:
    require side == -1 or side == 1, "side must be -1 (right) or +1 (left)"
    # Two 608 seats (open inboard and outboard) and the shaft bore, all with
    # teardrop roofs because the tower prints with this axis horizontal.
    let inner: solid = TEARDROP_Y(11.075, 7.4, 0.0, side * 81.1, 0.0)
    let outer: solid = TEARDROP_Y(11.075, 7.4, 0.0, side * 93.9, 0.0)
    let bore: solid = TEARDROP_Y(4.15, 20.4, 0.0, side * 87.5, 0.0)
    emit union(inner, outer, bore)


command ROCKER_TOWER(side: int) -> solid:
    require side == -1 or side == 1, "side must be -1 (right) or +1 (left)"
    # Pillow block for the paired 608s (R22 boss, 20 mm deep, was R18 in the
    # tub wall) plus an 8 mm goal-post web that carries the rocker
    # range-of-motion bumpers at x=+/-25, z=54.5 on its outboard face, braced
    # by two 6 mm ribs.  Everything is vertical or upward-facing so it prints
    # with the plate, flat, no supports.
    let block: solid = translate(box(44.0, 20.0, 19.0), 0.0, side * 87.5, -9.5)
    let boss: solid = Y_AXIS_CYLINDER(22.0, 20.0, 0.0, side * 87.5, 0.0)
    let web: solid = translate(chamfer(box(70.0, 8.0, 81.0), 3.0),
                               0.0, side * 93.5, 21.5)
    let rib: solid = translate(box(6.0, 20.0, 59.0), 30.0, side * 79.5, 10.5)
    let rib_b: solid = translate(box(6.0, 20.0, 59.0), -30.0, side * 79.5, 10.5)
    # Rocker range-of-motion stops printed in place: R6 pads cantilevered
    # from the web across the rocker band, with a 45-degree chin underneath
    # (inverted teardrop) so they print without support.  Tangent to the R5
    # rocker tab nose at +/-18 degrees.
    let pad: solid = mirror(TEARDROP_Y(6.0, 21.0, 0.0, 0.0, 0.0),
                            vector(0.0, 0.0, 1.0))
    let fore: solid = translate(pad, 28.7887, side * 104.0, 53.0652)
    let aft: solid = translate(pad, -28.7887, side * 104.0, 53.0652)
    # The pads cantilever 17 mm off the web along Y, so the chin's bottom
    # ridge would start in mid-air.  An 8 mm-wide wedge under each pad drops
    # from the pad's far end back to the web face at 45 degrees (sloped face
    # looking down-and-outboard), passing just under the chin point at the
    # tip.  It stays >=3 degrees outside the rocker tab's sweep at +/-18.
    let chin_wedge: solid = mirror(WEDGE_Y(8.0, 27.0, 0.0, side * 96.5, -53.0652, side),
                                   vector(0.0, 0.0, 1.0))
    let chin_clip: solid = translate(box(20.0, 18.0, 40.0), 0.0, side * 105.5, 40.0)
    let chin: solid = intersection(chin_wedge, chin_clip)
    emit union(block, boss, web, rib, rib_b, fore, aft,
               translate(chin, 28.7887, 0.0, 0.0),
               translate(chin, -28.7887, 0.0, 0.0))


command BREADBOARD_HOLES() -> solid:
    # 1/4-20 on a 25 mm optical-breadboard grid, modelled as Ø5.2 tap-drill
    # holes; tools/thread_plate.py cuts printable 1/4-20 UNC threads into
    # them for the print file.  (Ø7.6 holes for 8x8 heat-set inserts were
    # tried earlier in development; printed threads were chosen instead, so the
    # deck needs no insert stock and no heat-set step.)
    let tap: solid = translate(cylinder(2.6, 12.0), 0.0, 0.0, -30.0)
    emit compound(translate(tap, -125.0, -75.0, 0.0),
                  translate(tap, -125.0, -50.0, 0.0),
                  translate(tap, -125.0, -25.0, 0.0),
                  translate(tap, -125.0, 0.0, 0.0),
                  translate(tap, -125.0, 25.0, 0.0),
                  translate(tap, -125.0, 50.0, 0.0),
                  translate(tap, -125.0, 75.0, 0.0),
                  translate(tap, -100.0, -75.0, 0.0),
                  translate(tap, -100.0, -50.0, 0.0),
                  translate(tap, -100.0, -25.0, 0.0),
                  translate(tap, -100.0, 0.0, 0.0),
                  translate(tap, -100.0, 25.0, 0.0),
                  translate(tap, -100.0, 50.0, 0.0),
                  translate(tap, -100.0, 75.0, 0.0),
                  translate(tap, -75.0, -75.0, 0.0),
                  translate(tap, -75.0, -50.0, 0.0),
                  translate(tap, -75.0, -25.0, 0.0),
                  translate(tap, -75.0, 0.0, 0.0),
                  translate(tap, -75.0, 25.0, 0.0),
                  translate(tap, -75.0, 50.0, 0.0),
                  translate(tap, -75.0, 75.0, 0.0),
                  translate(tap, 75.0, -75.0, 0.0),
                  translate(tap, 75.0, -50.0, 0.0),
                  translate(tap, 75.0, -25.0, 0.0),
                  translate(tap, 75.0, 0.0, 0.0),
                  translate(tap, 75.0, 25.0, 0.0),
                  translate(tap, 75.0, 50.0, 0.0),
                  translate(tap, 75.0, 75.0, 0.0),
                  translate(tap, 100.0, -75.0, 0.0),
                  translate(tap, 100.0, -50.0, 0.0),
                  translate(tap, 100.0, -25.0, 0.0),
                  translate(tap, 100.0, 0.0, 0.0),
                  translate(tap, 100.0, 25.0, 0.0),
                  translate(tap, 100.0, 50.0, 0.0),
                  translate(tap, 100.0, 75.0, 0.0),
                  translate(tap, 125.0, -75.0, 0.0),
                  translate(tap, 125.0, -50.0, 0.0),
                  translate(tap, 125.0, -25.0, 0.0),
                  translate(tap, 125.0, 0.0, 0.0),
                  translate(tap, 125.0, 25.0, 0.0),
                  translate(tap, 125.0, 50.0, 0.0),
                  translate(tap, 125.0, 75.0, 0.0))


command BREADBOARD_PLATE() -> solid:
    # 300 x 195 x 10 mm deck replacing the tub.  Its top (z=-19) is the old
    # tub floor top, so the differential cradle is unchanged.
    # Narrowed to y=+/-88 except under the towers (x=+/-45 keeps +/-97.5):
    # the bogie-pivot shaft end and its inboard nut swing on ~R101 about the
    # rocker pivot and would cut through a full-width deck edge.
    let main: solid = chamfer(box(300.0, 176.0, 10.0), 1.0)
    # Full 195 mm width from x=-67 to the front edge carries the body side
    # walls (the bogie-pivot hardware only swings behind x=-80).
    let wall_land: solid = translate(chamfer(box(217.0, 195.0, 10.0), 1.0), 41.5, 0.0, 0.0)
    emit translate(union(main, wall_land), 0.0, 0.0, -24.0)


command CHASSIS_PIVOT_CARTRIDGE(side: int) -> solid:
    let boss: solid = chamfer(cylinder(18.0, 20.0), 1.5)
    let centered: solid = translate(boss, 0.0, 0.0, -10.0)
    let on_y: solid = rotate(centered, -90.0, 0.0, 0.0)
    let placed: solid = translate(on_y, 0.0, side * 87.5, 0.0)
    emit difference(placed, CHASSIS_PIVOT_CUTTERS(side))


command CHASSIS_TUB() -> solid:
    # One 205 x 195 x 110 mm open tub: 4 mm walls and a 6 mm floor.  Its
    # bottom is z=-25, preserving 115 mm belly clearance in the level pose.
    let rounded: solid = chamfer(box(205.0, 195.0, 110.0), 4.0)
    let outer: solid = translate(rounded, 0.0, 0.0, 30.0)
    let cavity: solid = translate(box(197.0, 187.0, 104.0),
                                  0.0, 0.0, 33.0)
    emit difference(outer, cavity)


command DIFFERENTIAL_FLOOR_CLEARANCE() -> solid:
    # Gear clearance through the deck, 88 x 68 mm (was 60 x 44): room under
    # the cradle for larger gears.  The 120 x 96 cradle base frame still
    # bears on 14-16 mm of deck all round, and the M4 holes at x=+/-52 keep
    # ~5.8 mm of deck to the opening edge.
    emit translate(box(88.0, 68.0, 20.0), 0.0, 0.0, -20.0)


command RTG_HALF_PLANE(angle_deg: float) -> solid:
    # Half-space on the counter-clockwise side of a ray from the RTG axis at
    # angle_deg (local frame, axis = Z), long enough for the extended body.
    emit rotate(translate(box(300.0, 300.0, 260.0), 0.0, 150.0, 30.0),
                0.0, 0.0, angle_deg)


command RTG_HX_SEGMENT(a0: float, a1: float) -> solid:
    # One curved heat-exchanger shell: 4 mm (R56..60) spanning a0..a1
    # degrees around the RTG, with five raised "HRS tubing" runs.
    # Shell and runs are parallel to the RTG axis, so after the 45-degree
    # tilt every surface slopes at >= 45 degrees.
    let ring: solid = translate(difference(cylinder(60.0, 170.0),
                                           cylinder(56.0, 170.0)),
                                0.0, 0.0, -70.0)
    let panel: solid = intersection(ring, RTG_HALF_PLANE(a0),
                                    RTG_HALF_PLANE(a1 + 180.0))
    let mid: float = (a0 + a1) / 2.0
    let tube: solid = translate(cylinder(1.8, 170.0), 61.0, 0.0, -70.0)
    let tube_offsets: list<float> = [-40.0, -20.0, 0.0, 20.0, 40.0]
    let tube_list: list<solid> = [rotate(tube, 0.0, 0.0, mid + d) for d in tube_offsets]
    let tubes: solid = union_all(tube_list)
    emit union(panel, tubes)


command MOCK_RTG() -> solid:
    # Mock MMRTG, built along +Z (z=0 is where the axis meets the deck top)
    # and run 70 mm below so the cut against the deck plane anchors it.
    # Ø44 core, eight 3 mm radial fins to R50, end bands, cone cap, and on
    # each side ONE curved heat-exchanger shell (R56..60, 110 degrees) that
    # stands 6 mm clear of the fins, as on Curiosity.  Fins and shells both
    # run down into the base, which anchors them for printing.
    let core: solid = translate(cylinder(22.0, 170.0), 0.0, 0.0, -70.0)
    let fin: solid = translate(box(3.0, 31.0, 170.0), 0.0, 35.5, 15.0)
    let fin_angles: list<float> = [i * 45.0 for i in range(8)]
    let fins: list<solid> = [rotate(fin, 0.0, 0.0, a) for a in fin_angles]
    let lower_band: solid = translate(cylinder(27.0, 6.0), 0.0, 0.0, 4.0)
    let upper_band: solid = translate(cylinder(27.0, 6.0), 0.0, 0.0, 94.0)
    let cap: solid = translate(cone(22.0, 10.0, 12.0), 0.0, 0.0, 100.0)
    let hx: list<solid> = [RTG_HX_SEGMENT(35.0, 145.0), RTG_HX_SEGMENT(215.0, 325.0)]
    let body: solid = union_all([core, lower_band, upper_band, cap] + fins + hx)
    emit intersection(body, translate(cylinder(80.0, 170.0), 0.0, 0.0, -70.0))


@meta(material="PETG", component.disposition="make", manufacturing.process="FDM",
      manufacturing.instructions="Print as modelled (base on the bed), no supports; bolt to deck with 4x 1/4-20 x 1/2 in",
      component.name="Mock MMRTG with HX, base plate and diff-side wall",
      assembly.datums=[
    {"id": "mount", "kind": "point", "origin_mm": [0.0, 0.0, 0.0]}
])
command RTG_ON_PRISM() -> solid:
    # The MMRTG rises 45 degrees up and back from the deck (axis meets the
    # deck top at x=-105) and is cut by the deck plane, so it stands on its
    # own base; it overhangs past the deck's rear edge.  At the front it is
    # cut flush to a 6 mm vertical wall at x=-66..-60 facing the
    # differential -- the start of a future diff cover.  A 6 mm base plate
    # with four 1/4-20 clearance holes on the deck grid holds it down.
    let rtg: solid = translate(rotate(MOCK_RTG(), 0.0, -45.0, 0.0), -105.0, 0.0, -19.0)
    let keep: solid = translate(box(400.0, 300.0, 300.0), -66.0 - 200.0, 0.0, -19.0 + 150.0)
    let trimmed: solid = intersection(rtg, keep)
    # The wall is the body's back wall: 178.4 wide so it nests between the
    # deck's side walls (inner faces y=+/-89.5, 0.3 mm clearance) and 81 mm
    # tall to the same z=62 rim.
    let wall: solid = translate(chamfer(box(6.0, 178.4, 81.0), 1.0), -63.0, 0.0, 21.5)
    let base: solid = translate(chamfer(box(90.0, 170.0, 6.0), 1.0), -105.0, 0.0, -16.0)
    let bolt: solid = translate(cylinder(3.3, 10.0), 0.0, 0.0, -20.0)
    let bolts: solid = compound(translate(bolt, -125.0, 75.0, 0.0),
                                translate(bolt, -75.0, 75.0, 0.0),
                                translate(bolt, -125.0, -75.0, 0.0),
                                translate(bolt, -75.0, -75.0, 0.0))
    emit difference(union(trimmed, wall, base), bolts)


# ---------------------------------------------------------------------------
# Body walls, printed WITH the deck (one H2D/H2S print): two side walls in
# the plane of the rocker-tower webs (inner face y=+/-89.5) so the bearing
# towers and motion stops are part of the wall, and a front wall at the deck
# edge.  Open top with 7 M3 heat-set lid bosses; the back is closed by the
# MMRTG part's wall, which nests between the side walls.  Triangular
# isogrid outside.  Interior x -60..144, y +/-89.5, z -19..62.

command ISOGRID_PANEL(length: float, height: float, rows: int) -> solid:
    # Local frame: inner face y=0, 3 mm skin to y=3, ribs 2 mm proud to y=5,
    # 2 mm wide; x 0..length, z 0..height.  Equilateral triangles: `rows`
    # horizontal bays, diagonals at +/-60 degrees through the row nodes
    # (30 degrees off vertical -- self-supporting).  Horizontal ribs above
    # the bed get 45-degree chins.  Vertical frame ribs at both ends.
    let skin: solid = translate(box(length, 3.0, height), length / 2.0, 1.5, height / 2.0)
    let row_h: float = height / rows
    let side: float = row_h / 0.8660254
    let run: float = height * 0.57735027
    let n: int = floor((length + 2.0 * run) / side) + 3
    let bar_len: float = height / 0.8660254 + 6.0
    let up_bars: list<solid> = [translate(rotate(box(bar_len, 2.0, 2.0), 0.0, -60.0, 0.0),
                                          -run - side + i * side + run / 2.0, 4.0, height / 2.0)
                                for i in range(n)]
    let down_bars: list<solid> = [translate(rotate(box(bar_len, 2.0, 2.0), 0.0, 60.0, 0.0),
                                            -side + i * side + run / 2.0, 4.0, height / 2.0)
                                  for i in range(n)]
    let outside: solid = union(translate(box(200.0, 20.0, height + 40.0), -100.0, 4.0, height / 2.0),
                               translate(box(200.0, 20.0, height + 40.0), length + 100.0, 4.0, height / 2.0),
                               translate(box(length + 400.0, 20.0, 40.0), length / 2.0, 4.0, -20.0),
                               translate(box(length + 400.0, 20.0, 40.0), length / 2.0, 4.0, height + 20.0))
    let diagonals: solid = difference(union_all(up_bars + down_bars), outside)
    let h_ribs: list<solid> = [translate(box(length, 2.0, 2.0), length / 2.0, 4.0,
                                         min(max(j * row_h, 1.0), height - 1.0))
                               for j in range(rows + 1)]
    let chins: list<solid> = [mirror(WEDGE_Y(length, 2.0, length / 2.0, 3.0,
                                             -(min(max(j * row_h, 1.0), height - 1.0) - 1.0), 1.0),
                                     vector(0.0, 0.0, 1.0))
                              for j in range(1, rows + 1)]
    let ends: solid = union(translate(box(2.0, 2.0, height), 1.0, 4.0, height / 2.0),
                            translate(box(2.0, 2.0, height), length - 1.0, 4.0, height / 2.0))
    emit union_all([skin, diagonals, ends] + h_ribs + chins)


command LID_BOSS(cx: float, wall_y: float) -> solid:
    # 10 x 10 x 12 mm block under the rim (z 50..62) against a wall whose
    # inner face is y=wall_y (block on the -y side), M3 heat-set insert hole
    # (Ø4.0 x 8.5 deep) from the top, and a 45-degree wedge under it into
    # the wall so it prints without support.
    let block: solid = translate(box(10.0, 10.0, 12.0), cx, wall_y - 5.0, 56.0)
    let chin: solid = mirror(WEDGE_Y(10.0, 10.0, cx, wall_y, -50.0, -1.0),
                             vector(0.0, 0.0, 1.0))
    let insert: solid = translate(cylinder(2.0, 8.6), cx, wall_y - 5.0, 53.5)
    emit difference(union(block, chin), insert)


command BODY_WALLS() -> solid:
    let side_panel: solid = ISOGRID_PANEL(213.0, 81.0, 3)
    let left: solid = translate(side_panel, -66.0, 89.5, -19.0)
    let right: solid = mirror(left, vector(0.0, 1.0, 0.0))
    # Front: local x -> -y, local y (outward) -> +x; inner face x=144.
    let front: solid = translate(rotate(ISOGRID_PANEL(185.0, 81.0, 3), 0.0, 0.0, -90.0),
                                 144.0, 92.5, -19.0)
    let post: solid = translate(box(5.0, 5.0, 81.0), 146.5, 92.0, 21.5)
    let posts: solid = union(post, mirror(post, vector(0.0, 1.0, 0.0)))
    let left_bosses: solid = union(LID_BOSS(-55.0, 89.5), LID_BOSS(55.0, 89.5),
                                   LID_BOSS(139.0, 89.5))
    let bosses: solid = union(left_bosses, mirror(left_bosses, vector(0.0, 1.0, 0.0)),
                              rotate(LID_BOSS(0.0, 144.0), 0.0, 0.0, -90.0))
    emit union(left, right, front, posts, bosses)

command CHASSIS_CAVITY() -> solid:
    emit translate(box(197.0, 187.0, 104.0), 0.0, 0.0, 33.0)


command CHASSIS_CUT_TUB() -> solid:
    emit difference(CHASSIS_TUB(),
                    CHASSIS_PIVOT_CUTTERS(1),
                    CHASSIS_PIVOT_CUTTERS(-1),
                    DIFFERENTIAL_FLOOR_CLEARANCE(),
                    ROCKER_LIMIT_SOCKET_CUTTERS(),
                    DIFFERENTIAL_CRADLE_FASTENER_CUTTERS())


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
    # Optical-breadboard deck: 300 x 195 x 10 mm plate (fits a Bambu H2S),
    # rocker bearing/limiter towers, differential opening and cradle holes,
    # 1/4-20 grid for walls, batteries and the RTG prism.
    emit difference(union(BREADBOARD_PLATE(), ROCKER_TOWER(1), ROCKER_TOWER(-1),
                          BODY_WALLS()),
                    CHASSIS_PIVOT_CUTTERS(1), CHASSIS_PIVOT_CUTTERS(-1),
                    DIFFERENTIAL_FLOOR_CLEARANCE(),
                    DIFFERENTIAL_CRADLE_FASTENER_CUTTERS(),
                    BREADBOARD_HOLES())


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
    # Mirror so the counterbores, retention recess and front-axle sleeve
    # face the right way.
    emit mirror(ROCKER_FINISHED(1), vector(0.0, 1.0, 0.0))


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
    add_part(rover, WHEEL_INNER_RACE_SPACER(), "left_front_inner_spacer")
    add_part(rover, WHEEL_INNER_RACE_SPACER(), "left_middle_inner_spacer")
    add_part(rover, WHEEL_INNER_RACE_SPACER(), "left_rear_inner_spacer")
    add_part(rover, RIGHT_WHEEL_INNER_RACE_SPACER(), "right_front_inner_spacer")
    add_part(rover, RIGHT_WHEEL_INNER_RACE_SPACER(), "right_middle_inner_spacer")
    add_part(rover, RIGHT_WHEEL_INNER_RACE_SPACER(), "right_rear_inner_spacer")
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
    add_part(rover, RTG_ON_PRISM(), "rtg_prism")
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

    add_named_mate(rover, "left_front_inner_spacer_mount", "rigid",
                   "left_rocker", "front_axle", "left_front_inner_spacer", "axle")
    add_named_mate(rover, "left_middle_inner_spacer_mount", "rigid",
                   "left_bogie", "middle_axle", "left_middle_inner_spacer", "axle")
    add_named_mate(rover, "left_rear_inner_spacer_mount", "rigid",
                   "left_bogie", "rear_axle", "left_rear_inner_spacer", "axle")
    add_named_mate(rover, "right_front_inner_spacer_mount", "rigid",
                   "right_rocker", "front_axle", "right_front_inner_spacer", "axle")
    add_named_mate(rover, "right_middle_inner_spacer_mount", "rigid",
                   "right_bogie", "middle_axle", "right_middle_inner_spacer", "axle")
    add_named_mate(rover, "right_rear_inner_spacer_mount", "rigid",
                   "right_bogie", "rear_axle", "right_rear_inner_spacer", "axle")

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
    add_named_mate(rover, "rtg_prism_mount", "rigid",
                   "chassis", "differential_mount",
                   "rtg_prism", "mount")
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
