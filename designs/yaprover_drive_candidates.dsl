module yaprover_drive_candidates

# Future coaxial drive study.  This module is intentionally separate from the
# passive first-build assembly and BOM.  Its origin is the wheel axle; +Y points
# outboard.  The suspension cartridge supports the rotating axle so wheel loads
# do not pass through the motor gearbox bearings.


command Y_AXIS_CYLINDER(radius_mm: float, length_mm: float,
                        center_y: float) -> solid:
    let centered: solid = translate(cylinder(radius_mm, length_mm),
                                    0.0, 0.0, -length_mm / 2.0)
    emit translate(rotate(centered, -90.0, 0.0, 0.0),
                   0.0, center_y, 0.0)


command HOLLOW_Y_CYLINDER(outer_radius_mm: float, inner_radius_mm: float,
                          length_mm: float, center_y: float) -> solid:
    emit difference(Y_AXIS_CYLINDER(outer_radius_mm, length_mm, center_y),
                    Y_AXIS_CYLINDER(inner_radius_mm, length_mm + 0.4,
                                    center_y))


@meta(material="steel gearmotor", component.id="pololu_4847",
      component.name="Pololu 99:1 HP 25D gearmotor with encoder",
      component.disposition="buy", procurement.vendor="Pololu",
      procurement.part_number="4847", procurement.specification="12 V, 100 rpm",
      assembly.datums=[
    {"id": "output_axis", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]},
    {"id": "mount_face", "kind": "plane",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command POLOLU_25D_99_HP_ENVELOPE() -> solid:
    # Conservative procurement envelope: Ø25 x 69 mm body plus the 12.5 mm
    # output shaft. Fine mounting details remain vendor-controlled dimensions.
    let body: solid = Y_AXIS_CYLINDER(12.5, 69.0, -34.5)
    let register: solid = Y_AXIS_CYLINDER(5.0, 2.0, 1.0)
    let shaft: solid = Y_AXIS_CYLINDER(2.0, 12.5, 6.25)
    emit compound(body, register, shaft)


@meta(material="PETG", component.id="drive_mount_25d_split_clamp",
      component.name="25D split-clamp motor mount candidate",
      component.disposition="make", manufacturing.process="FDM",
      assembly.datums=[
    {"id": "output_axis", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command POLOLU_25D_SPLIT_CLAMP_MOUNT() -> solid:
    # A body clamp avoids freezing an unverified motor-face bolt pattern into
    # the candidate design. The two feet attach to a future suspension plate.
    let collar: solid = HOLLOW_Y_CYLINDER(17.0, 12.8, 20.0, -38.0)
    let left_foot: solid = translate(fillet(box(9.0, 20.0, 7.0), 1.5),
                                     -17.0, -38.0, -18.5)
    let right_foot: solid = translate(fillet(box(9.0, 20.0, 7.0), 1.5),
                                      17.0, -38.0, -18.5)
    let joined: solid = union(collar, left_foot, right_foot)
    let split: solid = translate(box(4.0, 22.0, 10.0),
                                 0.0, -38.0, 7.0)
    emit difference(joined, split)


@meta(material="PETG", component.id="drive_bearing_cartridge_608",
      component.name="Dual-608 powered axle cartridge candidate",
      component.disposition="make", manufacturing.process="FDM",
      assembly.datums=[
    {"id": "axle", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command DRIVE_BEARING_CARTRIDGE() -> solid:
    let boss: solid = Y_AXIS_CYLINDER(17.0, 26.0, 0.0)
    let bore: solid = Y_AXIS_CYLINDER(4.2, 26.4, 0.0)
    let seat_in: solid = Y_AXIS_CYLINDER(11.15, 7.2, -8.1)
    let seat_out: solid = Y_AXIS_CYLINDER(11.15, 7.2, 8.1)
    let foot: solid = translate(fillet(box(44.0, 26.0, 7.0), 1.5),
                                0.0, 0.0, -20.5)
    emit difference(union(boss, foot), bore, seat_in, seat_out)


@meta(material="8 mm steel rod", component.id="powered_axle_8mm_x_80mm",
      component.name="Powered wheel axle, 8 x 80 mm cut length",
      component.disposition="raw_stock", manufacturing.process="cut_to_length",
      assembly.datums=[
    {"id": "axle", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command POWERED_WHEEL_AXLE() -> solid:
    emit Y_AXIS_CYLINDER(3.95, 80.0, 15.0)


@meta(material="steel / aluminum", component.id="coupler_4d_to_8mm",
      component.name="4 mm D-shaft to 8 mm axle clamp coupler",
      component.disposition="buy",
      procurement.specification="18 mm long, clamp type",
      assembly.datums=[
    {"id": "axis", "kind": "axis",
     "origin_mm": [0.0, 0.0, 0.0], "direction": [0.0, 1.0, 0.0]}
])
command DRIVE_COUPLER_4D_TO_8MM() -> solid:
    # Envelope geometry only; the 4 mm D-flat and clamp screws are supplier
    # dependent. The stepped bores preserve the intended load path.
    let blank: solid = Y_AXIS_CYLINDER(7.0, 18.0, -13.0)
    let motor_bore: solid = Y_AXIS_CYLINDER(2.05, 9.2, -17.5)
    let axle_bore: solid = Y_AXIS_CYLINDER(4.05, 9.2, -8.5)
    emit difference(blank, motor_bore, axle_bore)


command POWERED_WHEEL_PROXY() -> solid:
    let tire: solid = Y_AXIS_CYLINDER(65.0, 36.0, 39.0)
    let hub_bore: solid = Y_AXIS_CYLINDER(4.1, 36.4, 39.0)
    emit difference(tire, hub_bore)


command DRIVE_MODULE_CANDIDATE_PREVIEW() -> solid:
    let motor: solid = translate(POLOLU_25D_99_HP_ENVELOPE(),
                                 0.0, -25.0, 0.0)
    let mount: solid = translate(POLOLU_25D_SPLIT_CLAMP_MOUNT(),
                                 0.0, -25.0, 0.0)
    let coupler: solid = DRIVE_COUPLER_4D_TO_8MM()
    let spacer: solid = HOLLOW_Y_CYLINDER(6.5, 4.15, 8.0, 17.0)
    emit compound(motor, mount, coupler, DRIVE_BEARING_CARTRIDGE(),
                  POWERED_WHEEL_AXLE(), spacer, POWERED_WHEEL_PROXY())
