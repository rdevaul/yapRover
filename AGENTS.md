# AGENTS.md — working on yapRover with an AI agent

This file is for coding/CAD agents (Claude Code etc.) working in this repo.
Humans: see `README.md` and `docs/`.

## What this is

A 6-wheel rocker-bogie rover, fully parametric in the **yapCAD DSL**:

- `designs/yaprover_suspension_detailed.dsl`: the design and the assembly
  (`BUILD_DETAILED_SUSPENSION`). Every part is a `command` with `@meta`
  (material, `component.id`, disposition make/buy/raw_stock, procurement)
  and `assembly.datums`; parts are placed by **datum mates**, never by fixed
  transforms.
- `designs/yaprover_fit_coupons.dsl`: print-fit test coupons.
- `bom/prototype-v0.2.json`: purchase catalog (vendor lines, McMaster PNs,
  stock cut lists). `tools/build_purchase_bom.py` turns a built package into
  a purchase BOM and cut list.
- `tools/build_ycpkg.py`: builds and validates the `.ycpkg` package
  (`build/yaprover-<version>.ycpkg`): manifest, geometry, instances, datums,
  `metadata/bom.json`.

## Environment

- Python with yapCAD + pythonocc-core. yapCAD may be installed editable from
  a local checkout; if so, treat that checkout as shared and do not edit it
  from this repo.
- Check: `python -m yapcad.dsl check designs/yaprover_suspension_detailed.dsl`
- Fast tests: `pytest -q -m "not expensive_geometry"` (about 3 to 9 min).
  The marker is `expensive_geometry`; `-m "not expensive"` runs everything.
- Full tests (exact BREP clearance, package build): `pytest -q`.

## Design rules

- **Printer: Bambu H2D/H2S.** Every printed part must fit 325 x 320 x 325 mm
  (`H2S_BED` in the tests is set to the H2D single-nozzle volume).
- **Supportless FDM only.** Overhangs no shallower than 45°: chamfers, not
  fillets; teardrop horizontal holes; 45° chins under ribs, pads and bosses.
  Check new geometry with an overhang scan, not just by eye.
- Chamfer gear tooth tips (back-cone cut) and bore entries.
- 1/4-20 deck holes are **printed threads**: the model has Ø5.2 tap holes and
  `tools/thread_plate.py <deck.step> <stem>` cuts the threads into the print
  file. Always ship the threaded file. The lid uses M3 heat-set inserts (Ø4.0).
- Bearings: 608-2RS in printed Ø22.15 seats (light press).
- Wheel axles: DIN 7984 M8 low-head socket screw (head Ø13 x 5) in a Ø13.2 x
  5.6 counterbore, steel spacer, the wheel's two 608s with an inner-race
  spacer, DIN 125 washer and DIN 985 nyloc. The rocker's front boss carries
  a printed sleeve around the long spacer. Keep 5 mm wheel-to-structure
  clearance (test_level_pose_has_five_mm_wheel_to_structure_clearance).
- One part where possible: all six wheels are the same `wheel_135x54`. The
  right side is flipped by giving its axle datum direction -Y, not by
  mirroring geometry. A `component.id` must have identical local geometry
  everywhere it's used (the package build enforces this).

## yapCAD DSL gotchas

- No `int()`: use `floor()`/`ceil()`/`round()`.
- `shell` is a reserved word.
- `intersection(rotated_solid, box)` can silently drop to a **mesh**
  (no BREP). Prefer `difference` with outside boxes, then confirm with
  `brep_from_solid(...)` or the capture's `analytic_step` flag.
- `python -m yapcad.dsl run ... -o x.step` writes a **faceted** STEP. For
  analytic STEP use `compile_and_run` + `yapcad.brep.brep_from_solid`.
- `WEDGE_X(width, h, x0, cy, z0, dir)` places the wedge at x in
  [-x0-h, -x0] (sign-flipped) with y center -cy. Check the bbox.

## Verification loop (do this before you claim it works)

1. DSL check, then build the package with `tools/build_ycpkg.py` (or compile
   the assembly directly with `yapcad.dsl.compile_and_run`).
2. Every part `analytic_step: true`.
3. Pairwise interference **per solid** (compound parts give false overlaps):
   expect zero.
4. Rocker limit poses (±18°): only the printed stop pads may touch.
5. Overhang scan of changed printed parts in their print orientation.
6. Fast test suite green.
