#!/usr/bin/env python3
from __future__ import annotations

import json
import subprocess
import tempfile
import unittest
from pathlib import Path

import numpy as np


ROOT = Path(__file__).resolve().parent.parent
SCRIPT = ROOT / "scripts/georeference-wenyu-town.py"
CONTROLS = (
    ROOT
    / "src/ui/assets/tilemap/georeference/wenyu-town-control-points-v1.json"
)


class WenyuGeoreferenceTest(unittest.TestCase):
    def test_candidate_controls_fail_closed_and_round_trip(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "report.json"
            qa_image = Path(directory) / "qa.png"
            subprocess.run(
                [
                    "python3",
                    "-B",
                    str(SCRIPT),
                    "--controls",
                    str(CONTROLS),
                    "--output",
                    str(output),
                    "--qa-image",
                    str(qa_image),
                ],
                cwd=ROOT,
                check=True,
                capture_output=True,
                text=True,
            )
            report = json.loads(output.read_text(encoding="utf-8"))
            self.assertEqual(report["schema"], "moontown.wenyu_georeference.v1")
            self.assertEqual(report["qa"]["status"], "candidate")
            self.assertFalse(report["qa"]["runtimeEligible"])
            self.assertTrue(report["qa"]["reviewGates"]["sourceAssetDigests"])
            self.assertFalse(report["qa"]["reviewGates"]["minimumConfirmedFitControls"])
            self.assertFalse(
                report["qa"]["reviewGates"]["minimumIndependentNonStationGroups"]
            )
            self.assertEqual(
                {item["kind"] for item in report["candidateModels"]},
                {"similarity", "affine"},
            )
            self.assertEqual(report["selectedModel"]["kind"], "similarity")
            confirmed_fit = [
                item
                for item in report["controls"]
                if item["role"] == "fit" and item["reviewStatus"] == "confirmed"
            ]
            active_holdouts = [
                item
                for item in report["controls"]
                if item["role"] == "holdout" and item["reviewStatus"] != "rejected"
            ]
            self.assertEqual(len(confirmed_fit), 4)
            self.assertEqual(len(active_holdouts), 2)
            self.assertEqual(
                {
                    item["id"]
                    for item in confirmed_fit
                },
                {
                    "gcp-qinbei-river-crossing",
                    "gcp-future-science-city-road-bridge",
                    "gcp-future-science-city-east-road-bridge",
                    "gcp-jingcheng-wenyu-crossing",
                },
            )
            baidu_controls = [
                item for item in confirmed_fit if "baiduReference" in item
            ]
            self.assertEqual(len(baidu_controls), 2)
            self.assertEqual(
                {item["baiduReference"]["coordinateSystem"] for item in baidu_controls},
                {"BD09MC"},
            )
            self.assertAlmostEqual(
                report["qa"]["fitMetrics"]["tiles"]["rms"],
                0.476397,
                places=6,
            )
            self.assertGreater(
                report["qa"]["holdoutMetrics"]["tiles"]["p95"],
                20.0,
            )
            self.assertEqual(
                report["provenance"]["calibrationScope"]["kind"],
                "local-transport-registration",
            )
            self.assertTrue(qa_image.is_file())
            self.assertGreater(qa_image.stat().st_size, 10_000)

            model = report["selectedModel"]
            forward = np.array(model["forward"]["matrix"])
            forward_translation = np.array(model["forward"]["translation"])
            inverse = np.array(model["inverse"]["matrix"])
            inverse_translation = np.array(model["inverse"]["translation"])
            grid = np.array([[0.0, 0.0], [128.0, 72.0], [256.0, 144.0]])
            projected = grid @ forward.T + forward_translation
            restored = projected @ inverse.T + inverse_translation
            self.assertLess(float(np.max(np.abs(restored - grid))), 1.0e-5)


if __name__ == "__main__":
    unittest.main()
