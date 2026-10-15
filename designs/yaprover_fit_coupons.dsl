module yaprover_fit_coupons

# Calibration artifacts for the first physical build. Print these with the
# same machine, nozzle, material, layer height, perimeter count, and extrusion
# compensation intended for the rover components.

command Z_HOLE(diameter: float, x: float, y: float, depth: float) -> solid:
    emit translate(cylinder(diameter / 2.0, depth),
                   x, y, -depth / 2.0)


command ORIENTATION_MARKER(x: float, y: float, depth: float) -> solid:
    emit Z_HOLE(3.0, x, y, depth)


@meta(material="PETG", component.id="coupon_bearing_608",
      component.name="608 bearing-pocket fit coupon",
      component.disposition="make", manufacturing.process="FDM",
      manufacturing.instructions="Print flat using rover structural profile")
command BEARING_608_FIT_COUPON() -> solid:
    let plate: solid = fillet(box(150.0, 32.0, 7.2), 2.0)
    let positions: list<float> = [-60.0, -30.0, 0.0, 30.0, 60.0]
    let diameters: list<float> = [21.95, 22.05, 22.15, 22.25, 22.35]
    let holes: list<solid> = [
        Z_HOLE(diameters[i], positions[i], 0.0, 8.0)
        for i in range(0, 5)
    ]
    let marker: solid = ORIENTATION_MARKER(-72.0, -12.0, 8.0)
    emit difference_all(plate, holes + [marker])


@meta(material="PETG", component.id="coupon_axle_8mm",
      component.name="8 mm axle running-fit coupon",
      component.disposition="make", manufacturing.process="FDM",
      manufacturing.instructions="Print flat using rover structural profile")
command AXLE_8MM_FIT_COUPON() -> solid:
    let plate: solid = fillet(box(110.0, 28.0, 8.0), 2.0)
    let positions: list<float> = [-40.0, -20.0, 0.0, 20.0, 40.0]
    let diameters: list<float> = [8.00, 8.15, 8.30, 8.45, 8.60]
    let holes: list<solid> = [
        Z_HOLE(diameters[i], positions[i], 0.0, 9.0)
        for i in range(0, 5)
    ]
    let marker: solid = ORIENTATION_MARKER(-52.0, -10.0, 9.0)
    emit difference_all(plate, holes + [marker])


@meta(material="PETG", component.id="coupon_key_3mm",
      component.name="3 mm parallel-key slot fit coupon",
      component.disposition="make", manufacturing.process="FDM",
      manufacturing.instructions="Print flat using rover structural profile")
command KEY_3MM_FIT_COUPON() -> solid:
    # Brackets the 3.10 mm keyway used in the rocker hub and side-gear hub for
    # the DIN 6885 A 3 x 3 keys.
    let plate: solid = fillet(box(110.0, 30.0, 8.0), 2.0)
    let positions: list<float> = [-40.0, -20.0, 0.0, 20.0, 40.0]
    let widths: list<float> = [3.00, 3.10, 3.20, 3.30, 3.40]
    # Slots open through the +Y edge so the same physical key can be tried
    # without trapping it in the coupon.
    let slots: list<solid> = [
        translate(box(widths[i], 18.0, 9.0),
                  positions[i], 8.0, 0.0)
        for i in range(0, 5)
    ]
    let marker: solid = ORIENTATION_MARKER(-52.0, -11.0, 9.0)
    emit difference_all(plate, slots + [marker])


command QUARTER_20_COUPON_HOLES() -> solid:
    # Ø5.2 tap-drill bores on the deck's 25 mm grid, through the deck's 10 mm
    # thickness.  tools/thread_plate.py reads these translate(tap, ...) lines
    # (--command QUARTER_20_COUPON_HOLES) to cut printable 1/4-20 threads.
    let tap: solid = translate(cylinder(2.6, 12.0), 0.0, 0.0, -6.0)
    emit compound(translate(tap, -25.0, 0.0, 0.0),
                  translate(tap, 0.0, 0.0, 0.0),
                  translate(tap, 25.0, 0.0, 0.0))


@meta(material="PETG", component.id="coupon_quarter_20_thread",
      component.name="1/4-20 printed-thread fit coupon",
      component.disposition="make", manufacturing.process="FDM",
      manufacturing.instructions="Thread with tools/thread_plate.py, then print flat using the deck profile")
command QUARTER_20_THREAD_FIT_COUPON() -> solid:
    # A 10 mm slice of the optical-breadboard deck: three 1/4-20 holes on the
    # 25 mm grid plus one Ø6.60 clearance hole matching the RTG base plate.
    # The modelled holes are plain Ø5.20 tap drills; printable threads are
    # added to the exported STEP by tools/thread_plate.py.
    let plate: solid = chamfer(box(110.0, 28.0, 10.0), 1.0)
    let clearance: solid = Z_HOLE(6.60, 45.0, 0.0, 11.0)
    let marker: solid = ORIENTATION_MARKER(-48.0, -10.0, 11.0)
    emit difference(plate, QUARTER_20_COUPON_HOLES(), clearance, marker)


command ALL_FIT_COUPONS_PREVIEW() -> solid:
    emit compound(
        translate(BEARING_608_FIT_COUPON(), 0.0, 55.0, 0.0),
        translate(AXLE_8MM_FIT_COUPON(), 0.0, 15.0, 0.0),
        translate(KEY_3MM_FIT_COUPON(), 0.0, -25.0, 0.0),
        translate(QUARTER_20_THREAD_FIT_COUPON(), 0.0, -65.0, 0.0)
    )
