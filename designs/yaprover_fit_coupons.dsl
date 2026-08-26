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


@meta(material="PETG", component.id="coupon_key_2mm",
      component.name="2 mm parallel-key slot fit coupon",
      component.disposition="make", manufacturing.process="FDM",
      manufacturing.instructions="Print flat using rover structural profile")
command KEY_2MM_FIT_COUPON() -> solid:
    let plate: solid = fillet(box(110.0, 30.0, 8.0), 2.0)
    let positions: list<float> = [-40.0, -20.0, 0.0, 20.0, 40.0]
    let widths: list<float> = [1.90, 2.00, 2.10, 2.20, 2.30]
    # Slots open through the +Y edge so the same physical key can be tried
    # without trapping it in the coupon.
    let slots: list<solid> = [
        translate(box(widths[i], 18.0, 9.0),
                  positions[i], 8.0, 0.0)
        for i in range(0, 5)
    ]
    let marker: solid = ORIENTATION_MARKER(-52.0, -11.0, 9.0)
    emit difference_all(plate, slots + [marker])


@meta(material="PETG", component.id="coupon_tpu_bumper_socket",
      component.name="TPU bumper-stem socket fit coupon",
      component.disposition="make", manufacturing.process="FDM",
      manufacturing.instructions="Print flat using rover structural profile")
command TPU_BUMPER_SOCKET_FIT_COUPON() -> solid:
    let plate: solid = fillet(box(90.0, 26.0, 8.0), 2.0)
    let positions: list<float> = [-32.0, -16.0, 0.0, 16.0, 32.0]
    let diameters: list<float> = [5.00, 5.15, 5.30, 5.45, 5.60]
    let holes: list<solid> = [
        Z_HOLE(diameters[i], positions[i], 0.0, 9.0)
        for i in range(0, 5)
    ]
    let marker: solid = ORIENTATION_MARKER(-42.0, -9.0, 9.0)
    emit difference_all(plate, holes + [marker])


@meta(material="TPU 95A", component.id="coupon_tpu_bumper_stems",
      component.name="Nominal 5.1 mm TPU bumper test stems",
      component.disposition="make", manufacturing.process="FDM",
      manufacturing.instructions="Print upright using bumper profile")
command TPU_BUMPER_TEST_STEMS() -> solid:
    emit compound(
        translate(cylinder(2.55, 10.0), -24.0, 0.0, 0.0),
        translate(cylinder(2.55, 10.0), -12.0, 0.0, 0.0),
        cylinder(2.55, 10.0),
        translate(cylinder(2.55, 10.0), 12.0, 0.0, 0.0),
        translate(cylinder(2.55, 10.0), 24.0, 0.0, 0.0)
    )


command ALL_FIT_COUPONS_PREVIEW() -> solid:
    emit compound(
        translate(BEARING_608_FIT_COUPON(), 0.0, 55.0, 0.0),
        translate(AXLE_8MM_FIT_COUPON(), 0.0, 15.0, 0.0),
        translate(KEY_2MM_FIT_COUPON(), 0.0, -25.0, 0.0),
        translate(TPU_BUMPER_SOCKET_FIT_COUPON(), 0.0, -65.0, 0.0),
        translate(TPU_BUMPER_TEST_STEMS(), 0.0, -88.0, 0.0)
    )
