#!/usr/bin/env python3
import json
import subprocess
import sys
import tempfile
import unittest
from collections import Counter
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts/derive-wenyu-intersections.py"
ASSET = ROOT / "src/ui/assets/tilemap/wenyu_reference_intersections.json"


class WenyuIntersectionDerivationTest(unittest.TestCase):
    def test_checked_in_asset_replays_byte_for_byte(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "intersections.json"
            preview = Path(directory) / "preview.png"
            subprocess.run(
                [
                    sys.executable,
                    str(SCRIPT),
                    "--output",
                    str(output),
                    "--preview",
                    str(preview),
                ],
                cwd=ROOT,
                check=True,
                capture_output=True,
                text=True,
            )
            self.assertEqual(output.read_bytes(), ASSET.read_bytes())
            with Image.open(preview) as rendered:
                self.assertEqual(rendered.size, (1672, 941))

    def test_source_points_and_disabled_calibration_are_pinned(self) -> None:
        payload = json.loads(ASSET.read_text())
        self.assertEqual(
            payload["schema"], "moontown.wenyu_reference_intersections.v2"
        )
        self.assertFalse(payload["runtimeEligible"])
        self.assertEqual(payload["tileGrid"]["width"], 256)
        self.assertEqual(payload["tileGrid"]["height"], 144)
        self.assertEqual(payload["tileGrid"]["coordinateUnit"], "millitile")
        self.assertEqual(
            payload["source"]["image"]["sha256"],
            "sha256:10d09f3fb45da0e6dbcfb89dee19051df23d8be4b6b5e28aafbd51817c64d93b",
        )
        calibration = payload["authoringCalibration"]
        self.assertEqual(calibration["rotationDegrees"], 22.924436871)
        self.assertEqual(calibration["metersPerTile"], 37.86186326908114)
        self.assertEqual(calibration["fitRmsTiles"], 0.476397)
        self.assertFalse(calibration["runtimeEligible"])
        self.assertFalse(calibration["appliedToPoints"])

        points = payload["points"]
        self.assertEqual(len(points), 145)
        self.assertEqual(
            Counter(point["kind"] for point in points),
            {"t": 84, "cross": 55, "complex": 6},
        )
        self.assertEqual(
            Counter(point["semanticEvidence"]["confidence"] for point in points),
            {"high": 31, "medium": 62, "review": 52},
        )
        self.assertTrue(
            all(point["sourceHalfWidthPixels"] < 12 for point in points)
        )
        self.assertEqual(payload["metrics"]["roofBlobsDiscarded"], 2)

    def test_preview_graph_is_exact_connected_source_topology(self) -> None:
        payload = json.loads(ASSET.read_text())
        points = payload["points"]
        graph = payload["previewGraph"]
        self.assertEqual(
            graph["method"],
            "exact-seed 8-neighbor source-skeleton geodesics, "
            "unique-segment union, degree-not-two routing-node compression",
        )
        self.assertEqual(
            graph["metrics"],
            {
                "nodes": 145,
                "routingNodes": 38,
                "totalGraphNodes": 183,
                "edges": 216,
                "components": 1,
                "cycleRank": 34,
                "terminalsOmitted": 160,
                "unrepresentedVerifiedArms": 193,
                "bridges": 5,
                "bridgeEvidenceVertices": 66,
                "bridgeSpanVertices": 68,
                "waterConflicts": 0,
                "sourceSegments": 14141,
                "enclosedBlocks": 34,
            },
        )

        routing_nodes = graph["routingNodes"]
        self.assertEqual(len(routing_nodes), 38)
        point_by_id = {point["id"]: point for point in points}
        coordinate_by_id = {
            point["id"]: (point["xMillis"], point["yMillis"])
            for point in points
        }
        for index, node in enumerate(routing_nodes):
            self.assertEqual(node["id"], f"routing-{index:03d}")
            self.assertEqual(node["reason"], "source-branch")
            self.assertTrue(0 <= node["xMillis"] < 256000)
            self.assertTrue(0 <= node["yMillis"] < 144000)
            coordinate_by_id[node["id"]] = (
                node["xMillis"],
                node["yMillis"],
            )

        edges = graph["edges"]
        self.assertEqual(len(edges), 216)
        degrees = Counter()
        physical_segments = set()
        endpoint_pairs = set()
        bridge_spans = 0
        bridge_span_vertices = 0
        confidence_counts = Counter()
        for index, edge in enumerate(edges):
            self.assertEqual(edge["id"], f"edge-{index:03d}")
            self.assertIn(edge["from"], coordinate_by_id)
            self.assertIn(edge["to"], coordinate_by_id)
            self.assertLess(edge["from"], edge["to"])
            pair = (edge["from"], edge["to"])
            self.assertNotIn(pair, endpoint_pairs)
            endpoint_pairs.add(pair)
            degrees[edge["from"]] += 1
            degrees[edge["to"]] += 1
            path = edge["pathMillis"]
            self.assertEqual(tuple(path[0]), coordinate_by_id[edge["from"]])
            self.assertEqual(tuple(path[-1]), coordinate_by_id[edge["to"]])
            self.assertEqual(edge["sourceLengthPixels"], len(path) - 1)
            self.assertIn(edge["confidence"], {"high", "medium", "review"})
            confidence_counts[edge["confidence"]] += 1
            for first, second in zip(path, path[1:]):
                delta_x = abs(first[0] - second[0])
                delta_y = abs(first[1] - second[1])
                self.assertIn(delta_x, {0, 153, 154})
                self.assertIn(delta_y, {0, 153, 154})
                self.assertNotEqual((delta_x, delta_y), (0, 0))
                segment = tuple(sorted((tuple(first), tuple(second))))
                self.assertNotIn(segment, physical_segments)
                physical_segments.add(segment)
            previous_end = -1
            for span in edge["bridgeSpans"]:
                self.assertGreater(span["fromIndex"], previous_end)
                self.assertLess(span["fromIndex"], span["toIndex"])
                self.assertLess(span["toIndex"], len(path))
                previous_end = span["toIndex"]
                bridge_spans += 1
                bridge_span_vertices += span["toIndex"] - span["fromIndex"] + 1

        self.assertEqual(len(physical_segments), 14141)
        self.assertEqual(bridge_spans, 5)
        self.assertEqual(bridge_span_vertices, 68)
        self.assertEqual(confidence_counts, {"high": 11, "medium": 79, "review": 126})
        self.assertEqual(set(degrees), set(coordinate_by_id))
        self.assertEqual(
            len(edges) - len(coordinate_by_id) + graph["metrics"]["components"],
            graph["metrics"]["cycleRank"],
        )
        for point_id, point in point_by_id.items():
            self.assertLessEqual(degrees[point_id], point["externalArms"])
        self.assertEqual(
            sum(
                point["externalArms"] - degrees[point["id"]]
                for point in points
            ),
            graph["metrics"]["unrepresentedVerifiedArms"],
        )


if __name__ == "__main__":
    unittest.main()
