#!/usr/bin/env python3
"""Regression test for deterministic Wenyu roof-anchor generation."""

from __future__ import annotations

import json
import subprocess
import tempfile
from pathlib import Path


def main() -> None:
    repository = Path(__file__).resolve().parents[1]
    generator = repository / "scripts/derive-wenyu-building-anchors.py"
    checked_asset = (
        repository / "src/ui/assets/tilemap/wenyu_reference_buildings.json"
    )
    with tempfile.TemporaryDirectory(prefix="wenyu-building-anchors-") as temp:
        output_dir = Path(temp)
        subprocess.run(
            [
                "python3",
                str(generator),
                "--output-dir",
                str(output_dir),
            ],
            cwd=repository,
            check=True,
            capture_output=True,
            text=True,
        )
        generated = output_dir / "wenyu_reference_buildings.single-frame-candidate.json"
        report = json.loads((output_dir / "report.json").read_text())
        assert generated.read_bytes() == checked_asset.read_bytes()
        assert report["verdict"] == "GO-for-roof-provenance-anchors"
        assert report["candidate"]["anchors"] == 33
        assert all(report["hardGates"].values())


if __name__ == "__main__":
    main()
