from __future__ import annotations

from pathlib import Path
import tomllib


ROOT = Path(__file__).resolve().parents[1]


def test_runtime_yapcad_dependency_includes_strict_mesh_validation():
    project = tomllib.loads(
        (ROOT / "pyproject.toml").read_text(encoding="utf-8")
    )["project"]
    yapcad = [
        dependency for dependency in project["dependencies"]
        if dependency.lower().startswith("yapcad")
    ]

    assert len(yapcad) == 1
    assert yapcad[0].startswith("yapCAD[meshcheck] @ ")
