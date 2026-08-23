"""Exact BREP collision and clearance checks for positioned mechanisms.

This module is intentionally independent of assembly solving.  Callers pass
already-positioned, in-memory yapCAD solids; the helper extracts their OCC
BREPs and reports pairwise intersection volume and minimum separation.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from itertools import combinations
from typing import Dict, Iterable, Mapping, Optional, Set, Tuple

from yapcad.brep import brep_from_solid, require_occ


PartPair = Tuple[str, str]


def measure_brep_volume(solid) -> float:
    """Return the authoritative analytic BREP volume of a yapCAD solid."""
    require_occ()
    from OCC.Core.BRepGProp import brepgprop
    from OCC.Core.GProp import GProp_GProps

    brep = brep_from_solid(solid)
    if brep is None:
        raise ValueError("Solid has no in-memory analytic BREP")
    properties = GProp_GProps()
    brepgprop.VolumeProperties(brep.shape, properties)
    return abs(float(properties.Mass()))


def canonical_pair(part_a: str, part_b: str) -> PartPair:
    """Return an order-independent part-pair key."""
    if part_a == part_b:
        raise ValueError("A clearance pair must contain two different parts")
    return tuple(sorted((part_a, part_b)))


def canonical_pairs(pairs: Iterable[PartPair]) -> Set[PartPair]:
    """Normalize an iterable of order-independent part pairs."""
    return {canonical_pair(part_a, part_b) for part_a, part_b in pairs}


@dataclass(frozen=True)
class BrepPairMeasurement:
    """Exact overlap and separation metrics for one positioned part pair."""

    part_a: str
    part_b: str
    intersection_volume: float
    clearance: float
    intended_contact: bool = False


@dataclass
class BrepClearanceReport:
    """Pair measurements plus collision and minimum-clearance violations."""

    measurements: Dict[PartPair, BrepPairMeasurement] = field(default_factory=dict)
    collision_violations: Dict[PartPair, float] = field(default_factory=dict)
    clearance_violations: Dict[PartPair, Tuple[float, float]] = field(
        default_factory=dict
    )

    @property
    def success(self) -> bool:
        return not self.collision_violations and not self.clearance_violations


def measure_brep_pair(
    part_a: str,
    solid_a,
    part_b: str,
    solid_b,
    *,
    intended_contact: bool = False,
) -> BrepPairMeasurement:
    """Measure exact intersection volume and minimum BREP distance."""
    require_occ()
    from OCC.Core.BRepAlgoAPI import BRepAlgoAPI_Common
    from OCC.Core.BRepExtrema import BRepExtrema_DistShapeShape
    from OCC.Core.BRepGProp import brepgprop
    from OCC.Core.GProp import GProp_GProps

    brep_a = brep_from_solid(solid_a)
    brep_b = brep_from_solid(solid_b)
    if brep_a is None or brep_b is None:
        missing = part_a if brep_a is None else part_b
        raise ValueError(f"Part '{missing}' has no in-memory analytic BREP")

    common = BRepAlgoAPI_Common(brep_a.shape, brep_b.shape)
    common.Build()
    if not common.IsDone():
        raise RuntimeError(f"BREP intersection failed for {part_a} and {part_b}")
    properties = GProp_GProps()
    brepgprop.VolumeProperties(common.Shape(), properties)
    intersection_volume = abs(float(properties.Mass()))

    distance = BRepExtrema_DistShapeShape(brep_a.shape, brep_b.shape)
    distance.Perform()
    if not distance.IsDone():
        raise RuntimeError(f"BREP distance failed for {part_a} and {part_b}")

    return BrepPairMeasurement(
        part_a=part_a,
        part_b=part_b,
        intersection_volume=intersection_volume,
        clearance=max(0.0, float(distance.Value())),
        intended_contact=intended_contact,
    )


def audit_positioned_breps(
    positioned_solids: Mapping[str, object],
    *,
    intended_contacts: Iterable[PartPair] = (),
    minimum_clearances: Optional[Mapping[PartPair, float]] = None,
    intersection_tolerance: float = 1e-7,
    pairs: Optional[Iterable[PartPair]] = None,
) -> BrepClearanceReport:
    """Audit exact collisions and selected minimum clearances.

    Positive intersection volume is rejected unless the pair is explicitly in
    ``intended_contacts``.  The allowlist is exact; it never uses part-name
    substrings or broad categories.
    """
    allowed = canonical_pairs(intended_contacts)
    requirements = {
        canonical_pair(*pair): float(clearance)
        for pair, clearance in (minimum_clearances or {}).items()
    }
    selected = canonical_pairs(pairs) if pairs is not None else {
        canonical_pair(a, b) for a, b in combinations(positioned_solids, 2)
    }
    missing = {
        name for pair in selected | set(requirements)
        for name in pair if name not in positioned_solids
    }
    if missing:
        raise KeyError(f"No positioned geometry for: {', '.join(sorted(missing))}")

    report = BrepClearanceReport()
    for pair in sorted(selected | set(requirements)):
        part_a, part_b = pair
        measurement = measure_brep_pair(
            part_a, positioned_solids[part_a],
            part_b, positioned_solids[part_b],
            intended_contact=pair in allowed,
        )
        report.measurements[pair] = measurement
        if (measurement.intersection_volume > intersection_tolerance and
                pair not in allowed):
            report.collision_violations[pair] = measurement.intersection_volume
        required = requirements.get(pair)
        if required is not None and measurement.clearance + 1e-9 < required:
            report.clearance_violations[pair] = (
                measurement.clearance, required,
            )
    return report


__all__ = [
    "BrepClearanceReport",
    "BrepPairMeasurement",
    "PartPair",
    "audit_positioned_breps",
    "canonical_pair",
    "canonical_pairs",
    "measure_brep_pair",
    "measure_brep_volume",
]
