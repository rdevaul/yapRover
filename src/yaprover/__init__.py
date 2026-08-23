"""YapRover design support built on yapCAD."""

from .kinematics import (
    BrepClearanceReport,
    BrepPairMeasurement,
    RockerBogieGeometry,
    RockerBogiePose,
    apply_terrain_pose,
    audit_positioned_breps,
    canonical_pair,
    canonical_pairs,
    measure_brep_pair,
    measure_brep_volume,
    solve_terrain_pose,
    wheel_centers,
)

__version__ = "0.1.0"

__all__ = [
    "BrepClearanceReport",
    "BrepPairMeasurement",
    "RockerBogieGeometry",
    "RockerBogiePose",
    "apply_terrain_pose",
    "audit_positioned_breps",
    "canonical_pair",
    "canonical_pairs",
    "measure_brep_pair",
    "measure_brep_volume",
    "solve_terrain_pose",
    "wheel_centers",
]
