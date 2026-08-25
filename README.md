# YapRover

YapRover is an open, conventionally printable rocker-bogie rover designed
with the [yapCAD](https://github.com/rdevaul/yapCAD) procedural CAD system.
It is both a practical rover project and an integration showcase for yapCAD's
DSL, analytic BREP modeling, annotated assembly datums, mate solving,
mechanical joint coupling, manufacturing metadata, and `.ycpkg` packages.

![yapRover isometric assembly view](docs/assets/yapRover.jpg)

The design is currently a pre-alpha engineering prototype. Geometry and
kinematics are under active validation and must not yet be treated as a
production-ready mechanical design.

## Repository layout

- `designs/` contains the yapCAD DSL source of record.
- `src/yaprover/` contains rover-specific kinematic and validation tools.
- `tests/` verifies the numerical oracle, mate-solved assembly, analytic
  geometry, and mechanical clearances.
- `docs/` will contain fabrication and assembly documentation.
- `bom/` and `manufacturing/` will contain sourcing and fabrication data.
- `releases/` is reserved for versioned `.ycpkg` design releases.

## Development environment

OpenCASCADE is required for the authoritative analytic geometry tests. Create
the supported conda environment and install this checkout:

```bash
conda env create -f environment.yml
conda activate yaprover
python -m pip install -e '.[test]'
```

Run the normal test suite:

```bash
pytest -m "not visual and not expensive_geometry"
```

Run the slower exact-geometry tests explicitly:

```bash
pytest -m "expensive_geometry and not visual"
```

## Generate the rover package

Build the level-pose rover as a validated assembly-aware `.ycpkg` from the
repository root:

```bash
python tools/build_ycpkg.py
```

The output is the directory `build/yaprover-0.1.0.ycpkg/`. A `.ycpkg` is a
directory package, not a single STEP file. It contains the `ycpkg-spec-v0.2`
manifest, solved instances and mate/coupling graph, generated BOM, original DSL
source, and `yapcad-geometry-json-v0.2` geometry with embedded analytic BREP.
Expect the current package to occupy roughly 190 MB.

Select another version or preview pose, or replace an existing build, with:

```bash
python tools/build_ycpkg.py --version 0.1.1 \
  --rocker-angle-deg 12 --force
```

Use `--output path/to/name.ycpkg` to choose another destination. Package
generation requires the OpenCASCADE-enabled `yaprover` conda environment and
the editable installation described above. The builder runs strict package
validation before reporting success.

The current generated BOM is a geometry-oriented preview: component
disposition and procurement annotations have not yet been added to the rover
DSL, so modeled bearings and shaft assemblies are presently listed as unique
`make` components. Do not use this BOM for purchasing yet. Component-local
manufacturing STEP/STL exports will be enabled after those COTS and fabricated
component definitions are normalized.

Until yapCAD publishes the next release, `pyproject.toml` pins the exact
upstream commit containing the assembly, coupling, bevel-gear, and packaging
features required by this design. It will be replaced by a released version
constraint once that release is available.

The current [differential cartridge design](docs/differential.md) uses four
spherical-involute miter gears. Its two planet gears are separate parts with
independent running joints on a fixed cross-pin; exact BREP tests verify bore
clearance and all four meshes through a complete tooth pitch.

## License

YapRover is licensed under the MIT License. See [LICENSE](LICENSE).
