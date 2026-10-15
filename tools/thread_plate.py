#!/usr/bin/env python3
"""Cut printable 1/4-20 UNC internal threads into the Ø5.2 tap-drill holes of the
rover deck plate (CHASSIS_FINISHED exported as STEP) and write print-ready
STEP + STL.

The optical-breadboard deck is reproducible from this repository alone.  The
DSL models the 1/4-20 holes as plain Ø5.2 tap-drill bores to keep the release
geometry analytic and fast; this post-process adds the helical thread to the
print file only.  It needs pythonocc-core.

usage: python tools/thread_plate.py <input.step> <output_stem>
           [--dsl designs/yaprover_suspension_detailed.dsl]
           [--command BREADBOARD_HOLES]

Hole positions come from the named DSL command (default BREADBOARD_HOLES;
`translate(tap, x, y, 0.0)` lines); each one is verified to be a Ø5.2 vertical
through-hole spanning the full plate in the STEP before it is threaded.  Use
`--dsl designs/yaprover_fit_coupons.dsl --command QUARTER_20_COUPON_HOLES` to
thread the 1/4-20 fit coupon.

Printable thread form (internal, right-hand, axis vertical):
  nominal 1/4-20 UNC: major 6.35, P 1.27, 60 deg flanks
  cut major Ø = 6.35 + 2*CLEAR      (CLEAR = 0.18 radial)  -> 6.71
  minor Ø    = 5.25                 (crest of internal thread)
  groove-bottom flat (root)  = ROOT_FLAT = 0.20 axial
  crest flat at minor        = P - (ROOT_FLAT + 2*depth*tan30)  -> ~0.23
  0.5 x 45 deg entry chamfer at top and bottom faces.
"""
import math, os, re, sys, time, argparse

from OCC.Core.STEPControl import STEPControl_Reader, STEPControl_Writer, STEPControl_AsIs
from OCC.Core.IFSelect import IFSelect_RetDone
from OCC.Core.TopExp import TopExp_Explorer
from OCC.Core.TopAbs import TopAbs_SOLID, TopAbs_FACE, TopAbs_IN, TopAbs_OUT
from OCC.Core.TopoDS import topods
from OCC.Core.TopTools import TopTools_ListOfShape
from OCC.Core.BRep import BRep_Tool
from OCC.Core.BRepAdaptor import BRepAdaptor_Surface
from OCC.Core.GeomAbs import GeomAbs_Cylinder, GeomAbs_C2
from OCC.Core.Bnd import Bnd_Box
from OCC.Core.BRepBndLib import brepbndlib
from OCC.Core.GProp import GProp_GProps
from OCC.Core.BRepGProp import brepgprop
from OCC.Core.BRepCheck import BRepCheck_Analyzer
from OCC.Core.gp import (gp_Pnt, gp_Dir, gp_Ax1, gp_Ax2, gp_Ax3, gp_Pnt2d, gp_Dir2d,
                         gp_Trsf, gp_Vec)
from OCC.Core.Geom import Geom_CylindricalSurface
from OCC.Core.Geom2d import Geom2d_Line
from OCC.Core.BRepBuilderAPI import (BRepBuilderAPI_MakeEdge, BRepBuilderAPI_MakeWire,
                                     BRepBuilderAPI_MakePolygon, BRepBuilderAPI_MakeFace,
                                     BRepBuilderAPI_Transform)
from OCC.Core.BRepLib import breplib
from OCC.Core.BRepOffsetAPI import BRepOffsetAPI_MakePipeShell
from OCC.Core.BRepPrimAPI import BRepPrimAPI_MakeRevol, BRepPrimAPI_MakeBox
from OCC.Core.BRepAlgoAPI import BRepAlgoAPI_Fuse, BRepAlgoAPI_Cut, BRepAlgoAPI_Common
from OCC.Core.ShapeUpgrade import ShapeUpgrade_UnifySameDomain
from OCC.Core.BRepClass3d import BRepClass3d_SolidClassifier
from OCC.Core.BRepMesh import BRepMesh_IncrementalMesh
from OCC.Core.StlAPI import StlAPI_Writer

# ---------------------------------------------------------------- thread form
P = 1.27                       # 20 TPI
MAJOR_NOM = 6.35
CLEAR = 0.18                   # radial clearance on major (printability)
R_MAJ = MAJOR_NOM / 2 + CLEAR  # 3.355  groove bottom radius
R_MIN = 5.25 / 2               # 2.625  internal-thread crest radius
ROOT_FLAT = 0.20               # axial flat at the groove bottom (major)
DEPTH = R_MAJ - R_MIN
TAN30 = math.tan(math.radians(30))
W_MIN = ROOT_FLAT + 2 * DEPTH * TAN30      # groove width at minor radius
CREST_FLAT = P - W_MIN                     # internal-thread crest flat
R_IN = 1.6                     # tooth root buried inside the core cylinder
CHAMFER = 0.5                  # 0.5 x 45 deg at both faces
HOLE_R = 2.6                   # expected tap-drill radius in the STEP
TOL = 1e-3


def log(*a):
    print(*a, flush=True)


def read_step(path):
    r = STEPControl_Reader()
    if r.ReadFile(path) != IFSelect_RetDone:
        sys.exit(f"cannot read {path}")
    r.TransferRoots()
    return r.OneShape()


def solids(shape):
    out, e = [], TopExp_Explorer(shape, TopAbs_SOLID)
    while e.More():
        out.append(topods.Solid(e.Current())); e.Next()
    return out


def volume(s):
    g = GProp_GProps(); brepgprop.VolumeProperties(s, g); return g.Mass()


def bbox(s):
    b = Bnd_Box(); brepbndlib.Add(s, b); return b.Get()


def valid(s):
    return BRepCheck_Analyzer(s).IsValid()


def parse_holes(dsl_path, command="BREADBOARD_HOLES"):
    txt = open(dsl_path).read()
    m = re.search(r"command\s+" + re.escape(command) + r"\(\).*?(?=\ncommand\s|\Z)",
                  txt, re.S)
    if not m:
        sys.exit(f"{command} not found in DSL")
    pts = [(float(x), float(y)) for x, y in
           re.findall(r"translate\(\s*tap\s*,\s*(-?[\d.]+)\s*,\s*(-?[\d.]+)\s*,\s*0(?:\.0)?\s*\)", m.group(0))]
    return pts


def find_tap_holes(shape):
    """Return list of (x, y, zmin, zmax) for vertical cylindrical faces of radius HOLE_R."""
    found, e = [], TopExp_Explorer(shape, TopAbs_FACE)
    while e.More():
        f = topods.Face(e.Current()); e.Next()
        a = BRepAdaptor_Surface(f)
        if a.GetType() != GeomAbs_Cylinder:
            continue
        c = a.Cylinder()
        if abs(c.Radius() - HOLE_R) > 0.01 or abs(abs(c.Axis().Direction().Z()) - 1) > 1e-6:
            continue
        loc = c.Axis().Location()
        b = bbox(f)
        found.append((loc.X(), loc.Y(), b[2], b[5]))
    return found


def classify(solid, p):
    c = BRepClass3d_SolidClassifier(solid, gp_Pnt(*p), 1e-6)
    return c.State()


# ---------------------------------------------------------------- cutter
def make_cutter(zb, zt):
    """Threaded-hole cutter (void) at the origin for a plate spanning zb..zt."""
    # 1) helical tooth: profile in XZ plane at angle 0, swept along a helix of radius R_MIN
    z0 = zb - 1.5 * P
    turns = (zt - zb + 3 * P) / P
    surf = Geom_CylindricalSurface(gp_Ax3(gp_Pnt(0, 0, z0), gp_Dir(0, 0, 1), gp_Dir(1, 0, 0)), R_MIN)
    line = Geom2d_Line(gp_Pnt2d(0, 0), gp_Dir2d(2 * math.pi, P))   # u: angle, v: height -> RH
    seg_len = turns * math.hypot(2 * math.pi, P)
    hedge = BRepBuilderAPI_MakeEdge(line, surf, 0.0, seg_len).Edge()
    breplib.BuildCurves3d(hedge, 1e-6, GeomAbs_C2, 14, 400)
    spine = BRepBuilderAPI_MakeWire(hedge).Wire()

    hw_maj, hw_min = ROOT_FLAT / 2, W_MIN / 2
    prof = [(R_IN, -hw_min), (R_MIN, -hw_min), (R_MAJ, -hw_maj),
            (R_MAJ, hw_maj), (R_MIN, hw_min), (R_IN, hw_min)]
    poly = BRepBuilderAPI_MakePolygon()
    for r, dz in prof:
        poly.Add(gp_Pnt(r, 0, z0 + dz))
    poly.Close()
    pw = poly.Wire()

    ps = BRepOffsetAPI_MakePipeShell(spine)
    ps.SetMode(gp_Dir(0, 0, 1))          # fixed binormal: profile stays in an axial plane
    ps.SetTolerance(1e-5, 1e-5, 1e-3)
    ps.Add(pw, False, False)
    ps.Build()
    if not ps.IsDone():
        raise RuntimeError("pipe shell failed")
    if not ps.MakeSolid():
        raise RuntimeError("pipe shell MakeSolid failed")
    tooth = ps.Shape()
    log(f"  helical tooth: valid={valid(tooth)} vol={volume(tooth):.2f}")
    if volume(tooth) < 0:
        tooth.Reverse()

    # 2) core: minor-diameter bore + 0.5x45 chamfers top & bottom (revolved)
    e = 0.5   # extension past each face
    rc = [(0, zb - e), (R_MIN + CHAMFER + e, zb - e), (R_MIN, zb + CHAMFER),
          (R_MIN, zt - CHAMFER), (R_MIN + CHAMFER + e, zt + e), (0, zt + e)]
    poly = BRepBuilderAPI_MakePolygon()
    for r, z in rc:
        poly.Add(gp_Pnt(r, 0, z))
    poly.Close()
    face = BRepBuilderAPI_MakeFace(poly.Wire(), True).Face()
    core = BRepPrimAPI_MakeRevol(face, gp_Ax1(gp_Pnt(0, 0, 0), gp_Dir(0, 0, 1)), 2 * math.pi).Shape()
    core = solids(core)[0]
    log(f"  core: valid={valid(core)} vol={volume(core):.2f}")

    fu = BRepAlgoAPI_Fuse(tooth, core)
    fu.SetFuzzyValue(1e-5)
    fu.Build()
    if not fu.IsDone():
        raise RuntimeError("cutter fuse failed")
    u = ShapeUpgrade_UnifySameDomain(fu.Shape(), True, True, False); u.Build()
    sl = solids(u.Shape())
    if len(sl) != 1:
        raise RuntimeError(f"cutter has {len(sl)} solids")
    cut = sl[0]
    v = volume(cut)
    ok = valid(cut)
    log(f"  cutter: valid={ok} vol={v:.2f} bbox={[round(x, 3) for x in bbox(cut)]}")
    if not ok or v <= 0:
        raise RuntimeError("cutter invalid")
    return cut


def translated(s, x, y):
    t = gp_Trsf(); t.SetTranslation(gp_Vec(x, y, 0))
    return BRepBuilderAPI_Transform(s, t, True).Shape()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("input_step")
    ap.add_argument("output_stem")
    ap.add_argument("--dsl", default=os.path.join(
        os.path.dirname(os.path.abspath(__file__)), os.pardir, "designs",
        "yaprover_suspension_detailed.dsl"))
    ap.add_argument("--command", default="BREADBOARD_HOLES",
                    help="DSL command whose translate(tap, x, y, 0.0) lines give the holes")
    ap.add_argument("--lin-defl", type=float, default=0.02)
    ap.add_argument("--ang-defl", type=float, default=0.25)
    a = ap.parse_args()
    t0 = time.time()

    log(f"thread form: major {2*R_MAJ:.3f} (nom 6.35 + {CLEAR} radial), minor {2*R_MIN:.3f}, "
        f"P {P}, depth {DEPTH:.3f}, root flat {ROOT_FLAT:.3f}, crest flat {CREST_FLAT:.3f}")
    assert ROOT_FLAT >= 0.15 and CREST_FLAT >= 0.15

    shape = read_step(a.input_step)
    sl = solids(shape)
    if len(sl) != 1:
        sys.exit(f"expected 1 solid, got {len(sl)}")
    plate = sl[0]
    v0 = volume(plate)
    log(f"input: 1 solid, valid={valid(plate)}, vol={v0:.1f} mm3, bbox={[round(x, 2) for x in bbox(plate)]}")

    # ---- holes: DSL positions, verified against STEP geometry
    pts = parse_holes(a.dsl, a.command)
    log(f"DSL {a.command}: {len(pts)} positions")
    found = find_tap_holes(plate)
    holes, zb, zt = [], None, None
    for x, y in pts:
        m = [f for f in found if math.hypot(f[0] - x, f[1] - y) < 0.01]
        if not m:
            sys.exit(f"hole ({x},{y}) not found as Ø{2*HOLE_R} cylinder in STEP")
        hz0, hz1 = min(f[2] for f in m), max(f[3] for f in m)
        zb = hz0 if zb is None else zb
        zt = hz1 if zt is None else zt
        if abs(hz0 - zb) > 1e-3 or abs(hz1 - zt) > 1e-3:
            sys.exit(f"hole ({x},{y}) spans {hz0}..{hz1}, inconsistent with {zb}..{zt}")
        # through + clear above/below (no tower over it), material around it
        zm = (zb + zt) / 2
        if classify(plate, (x, y, zm)) != TopAbs_OUT or classify(plate, (x + 4.0, y, zm)) != TopAbs_IN:
            sys.exit(f"hole ({x},{y}) is not an open bore in solid material")
        for ang in range(0, 360, 45):
            px, py = x + 4.0 * math.cos(math.radians(ang)), y + 4.0 * math.sin(math.radians(ang))
            for z in (zt + 0.3, zt + 2.0, zb - 0.3, zb - 2.0):
                if classify(plate, (px, py, z)) != TopAbs_OUT:
                    sys.exit(f"hole ({x},{y}): material outside plate at z={z}; cutter would hit it")
        holes.append((x, y))
    extra = len(found) - len(holes)
    log(f"verified {len(holes)} Ø{2*HOLE_R} through-holes, z {zb:.3f}..{zt:.3f} "
        f"(other Ø5.2 vertical faces in STEP not threaded: {extra})")

    # ---- cutter
    log("building cutter ...")
    cutter = make_cutter(zb, zt)
    # expected per-hole removal: cutter ∩ plate slab, minus the existing Ø5.2 bore
    slab = BRepPrimAPI_MakeBox(gp_Pnt(-10, -10, zb), gp_Pnt(10, 10, zt)).Shape()
    per_hole = volume(BRepAlgoAPI_Common(cutter, slab).Shape()) - math.pi * HOLE_R ** 2 * (zt - zb)
    log(f"  expected removal per hole {per_hole:.2f} mm3 -> x{len(holes)} = {per_hole*len(holes):.1f}")

    # ---- pattern + single boolean
    log("cutting ...")
    t1 = time.time()
    args = TopTools_ListOfShape(); args.Append(plate)
    tools = TopTools_ListOfShape()
    for x, y in holes:
        tools.Append(translated(cutter, x, y))
    op = BRepAlgoAPI_Cut()
    op.SetArguments(args); op.SetTools(tools)
    op.SetRunParallel(True)
    op.SetFuzzyValue(1e-5)
    op.Build()
    if not op.IsDone():
        sys.exit("boolean cut failed")
    res = op.Shape()
    u = ShapeUpgrade_UnifySameDomain(res, True, True, False); u.Build(); res = u.Shape()
    rs = solids(res)
    log(f"  boolean {time.time()-t1:.0f}s; solids={len(rs)}")
    if len(rs) != 1:
        sys.exit("result is not a single solid")
    res = rs[0]
    ok = valid(res)
    v1 = volume(res)
    dv = v0 - v1
    exp = per_hole * len(holes)
    log(f"result: valid={ok} vol={v1:.1f} dV={dv:.2f} expected={exp:.2f} "
        f"err={100*(dv-exp)/exp:.3f}%")
    if not ok or abs(dv - exp) / exp > 0.01:
        sys.exit("validation failed")

    # ---- probe thread flanks: along a vertical line at r between minor and major,
    # void/material must alternate with period P and phase advancing right-handed
    rp = (R_MIN + R_MAJ) / 2
    zm0, zm1 = zb + CHAMFER + 1.0, zt - CHAMFER - 1.0
    nz = 400
    bad = 0
    for (x, y) in [holes[0], holes[len(holes) // 2], holes[-1]]:
        phases = []
        for ang in (0.0, 90.0):
            th = math.radians(ang)
            st = [classify(res, (x + rp * math.cos(th), y + rp * math.sin(th),
                                 zm0 + (zm1 - zm0) * i / nz)) == TopAbs_OUT for i in range(nz + 1)]
            trans = [zm0 + (zm1 - zm0) * (i + 0.5) / nz for i in range(nz) if st[i] != st[i + 1]]
            void_frac = sum(st) / len(st)
            # void-band centres: first rising edge (in->out) mod P
            ups = [zm0 + (zm1 - zm0) * (i + 0.5) / nz for i in range(nz) if (not st[i]) and st[i + 1]]
            phases.append(ups[0] % P if ups else None)
            # also material at the minor radius-0.05 should be absent (bore), and solid at R_MAJ+0.1
            outer = classify(res, (x + (R_MAJ + 0.1) * math.cos(th), y + (R_MAJ + 0.1) * math.sin(th),
                                   (zm0 + zm1) / 2)) == TopAbs_IN
            n_flanks = len(trans)
            exp_fl = 2 * (zm1 - zm0) / P
            log(f"  probe hole ({x:.0f},{y:.0f}) @{ang:.0f}deg r={rp:.2f}: flanks={n_flanks} "
                f"(expect ~{exp_fl:.1f}), void fraction={void_frac:.2f}, solid beyond major={outer}")
            if abs(n_flanks - exp_fl) > 2 or not outer:
                bad += 1
        if None not in phases:
            d = (phases[1] - phases[0]) % P
            log(f"    rising-edge shift 0->90deg = {d:.3f} mm (RH expects +{P/4:.3f})")
            if abs(d - P / 4) > 0.05:
                bad += 1
    if bad:
        sys.exit("thread probe failed")

    # ---- write
    stem = a.output_stem
    os.makedirs(os.path.dirname(os.path.abspath(stem)), exist_ok=True)
    w = STEPControl_Writer(); w.Transfer(res, STEPControl_AsIs)
    if w.Write(stem + ".step") != IFSelect_RetDone:
        sys.exit("STEP write failed")
    mesh = BRepMesh_IncrementalMesh(res, a.lin_defl, False, a.ang_defl, True)
    mesh.Perform()
    sw = StlAPI_Writer(); sw.SetASCIIMode(False)
    if not sw.Write(res, stem + ".stl"):
        sys.exit("STL write failed")
    for ext in (".step", ".stl"):
        log(f"wrote {stem+ext} ({os.path.getsize(stem+ext)/1e6:.1f} MB)")
    log(f"done in {time.time()-t0:.0f}s")


if __name__ == "__main__":
    main()
