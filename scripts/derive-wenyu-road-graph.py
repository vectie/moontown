#!/usr/bin/env python3
"""Derive a connected 256x144 road graph from the Wenyu masterplan raster.

The semantic terrain JSON is useful for land use, but its M/R/b road samples
are disconnected after down-sampling.  The source raster still contains a
single connected, neutral-gray road surface.  This authoring tool extracts
that surface, thins it to a centerline, projects it onto the gameplay grid,
and repairs diagonal-only joins so MoonTown can route with four neighbors.

Dependencies: Pillow and NumPy.  The script intentionally does not fetch live
map data; its output must be reproducible.  OpenStreetMap is a topology review
reference, not a hidden build dependency, because the Wenyu illustration has
no georeferencing transform.
"""

from __future__ import annotations

import argparse
import json
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image


GRID_WIDTH = 256
GRID_HEIGHT = 144
NEUTRAL_SPREAD_MAX = 18
ROAD_VALUE_MIN = 175
ROAD_VALUE_MAX = 240
MAJOR_HALF_WIDTH_MIN = 3
RECTILINEAR_CORRIDOR_STRIDE = 10
RECTILINEAR_MAX_DEVIATION = 3

FOUR_NEIGHBORS = ((1, 0), (-1, 0), (0, 1), (0, -1))
EIGHT_NEIGHBORS = FOUR_NEIGHBORS + (
    (1, 1),
    (1, -1),
    (-1, 1),
    (-1, -1),
)


def road_surface_candidates(rgb: np.ndarray) -> np.ndarray:
    """Return neutral, light surface pixels that contain the road network."""
    channels = rgb.astype(np.int16)
    spread = channels.max(axis=2) - channels.min(axis=2)
    value = channels.mean(axis=2)
    return (
        (spread <= NEUTRAL_SPREAD_MAX)
        & (value >= ROAD_VALUE_MIN)
        & (value <= ROAD_VALUE_MAX)
    )


def largest_border_component(mask: np.ndarray) -> np.ndarray:
    """Keep the largest eight-connected candidate component touching an edge."""
    height, width = mask.shape
    seen = np.zeros(mask.shape, dtype=np.uint8)
    largest: list[int] = []

    for start_y, start_x in zip(*np.nonzero(mask)):
        if seen[start_y, start_x]:
            continue
        component = [int(start_y) * width + int(start_x)]
        seen[start_y, start_x] = 1
        touches_border = False
        for index in component:
            y, x = divmod(index, width)
            touches_border = touches_border or (
                x == 0 or y == 0 or x == width - 1 or y == height - 1
            )
            for dy, dx in EIGHT_NEIGHBORS:
                next_y = y + dy
                next_x = x + dx
                if (
                    0 <= next_y < height
                    and 0 <= next_x < width
                    and mask[next_y, next_x]
                    and not seen[next_y, next_x]
                ):
                    seen[next_y, next_x] = 1
                    component.append(next_y * width + next_x)
        if touches_border and len(component) > len(largest):
            largest = component

    if not largest:
        raise RuntimeError("No border-connected neutral road surface found")

    result = np.zeros(mask.shape, dtype=np.uint8)
    for index in largest:
        y, x = divmod(index, width)
        result[y, x] = 1
    return result


def thinning_pass(skeleton: np.ndarray, phase: int) -> int:
    """Apply one phase of deterministic Zhang-Suen skeletonization."""
    padded = np.pad(skeleton, 1)
    p2 = padded[:-2, 1:-1]
    p3 = padded[:-2, 2:]
    p4 = padded[1:-1, 2:]
    p5 = padded[2:, 2:]
    p6 = padded[2:, 1:-1]
    p7 = padded[2:, :-2]
    p8 = padded[1:-1, :-2]
    p9 = padded[:-2, :-2]
    neighbors = p2 + p3 + p4 + p5 + p6 + p7 + p8 + p9
    sequence = (p2, p3, p4, p5, p6, p7, p8, p9, p2)
    transitions = sum(
        ((sequence[index] == 0) & (sequence[index + 1] == 1)).astype(
            np.uint8
        )
        for index in range(8)
    )
    if phase == 0:
        topology_guard = (p2 * p4 * p6 == 0) & (p4 * p6 * p8 == 0)
    else:
        topology_guard = (p2 * p4 * p8 == 0) & (p2 * p6 * p8 == 0)
    removable = (
        (skeleton == 1)
        & (neighbors >= 2)
        & (neighbors <= 6)
        & (transitions == 1)
        & topology_guard
    )
    removed = int(removable.sum())
    skeleton[removable] = 0
    return removed


def skeletonize(surface: np.ndarray) -> np.ndarray:
    """Thin a connected surface without changing its eight-neighbor topology."""
    skeleton = surface.copy()
    for _ in range(max(surface.shape)):
        removed = thinning_pass(skeleton, 0) + thinning_pass(skeleton, 1)
        if removed == 0:
            return skeleton
    raise RuntimeError("Road skeletonization did not converge")


def survival_depth(surface: np.ndarray, max_depth: int = 12) -> np.ndarray:
    """Approximate half-width by repeated eight-neighbor erosion."""
    height, width = surface.shape
    current = surface.astype(bool)
    depth = np.zeros(surface.shape, dtype=np.uint8)
    for level in range(1, max_depth + 1):
        padded = np.pad(current, 1)
        eroded = padded[1:-1, 1:-1].copy()
        for offset_y in range(3):
            for offset_x in range(3):
                eroded &= padded[
                    offset_y : offset_y + height,
                    offset_x : offset_x + width,
                ]
        depth[eroded] = level
        current = eroded
        if not current.any():
            break
    return depth


def project_centerline(
    skeleton: np.ndarray, width_depth: np.ndarray
) -> tuple[np.ndarray, np.ndarray]:
    """Project source centerline pixels and their width class to the tile grid."""
    source_height, source_width = skeleton.shape
    roads = np.zeros((GRID_HEIGHT, GRID_WIDTH), dtype=bool)
    major = np.zeros((GRID_HEIGHT, GRID_WIDTH), dtype=bool)
    for source_y, source_x in zip(*np.nonzero(skeleton)):
        grid_y = min(GRID_HEIGHT - 1, source_y * GRID_HEIGHT // source_height)
        grid_x = min(GRID_WIDTH - 1, source_x * GRID_WIDTH // source_width)
        roads[grid_y, grid_x] = True
        if width_depth[source_y, source_x] >= MAJOR_HALF_WIDTH_MIN:
            major[grid_y, grid_x] = True
    return roads, major


def repair_diagonal_joins(
    roads: np.ndarray, major: np.ndarray
) -> tuple[np.ndarray, np.ndarray]:
    """Turn diagonal-only joins into deterministic four-neighbor elbows."""
    repaired_roads = roads.copy()
    repaired_major = major.copy()
    changed = True
    while changed:
        changed = False
        for y in range(GRID_HEIGHT - 1):
            for x in range(GRID_WIDTH - 1):
                northwest = repaired_roads[y, x]
                northeast = repaired_roads[y, x + 1]
                southwest = repaired_roads[y + 1, x]
                southeast = repaired_roads[y + 1, x + 1]
                if northwest and southeast and not northeast and not southwest:
                    repaired_roads[y, x + 1] = True
                    repaired_major[y, x + 1] = (
                        repaired_major[y, x] and repaired_major[y + 1, x + 1]
                    )
                    changed = True
                elif southwest and northeast and not northwest and not southeast:
                    repaired_roads[y, x] = True
                    repaired_major[y, x] = (
                        repaired_major[y + 1, x] and repaired_major[y, x + 1]
                    )
                    changed = True
    return repaired_roads, repaired_major


def transfer_nearby_classification(
    roads: np.ndarray, source_class: np.ndarray, radius: int
) -> np.ndarray:
    """Transfer a source classification onto nearby cells of a revised graph."""
    transferred = np.zeros(roads.shape, dtype=bool)
    for y, x in zip(*np.nonzero(roads)):
        y0 = max(0, int(y) - radius)
        y1 = min(GRID_HEIGHT, int(y) + radius + 1)
        x0 = max(0, int(x) - radius)
        x1 = min(GRID_WIDTH, int(x) + radius + 1)
        transferred[y, x] = bool(source_class[y0:y1, x0:x1].any())
    return transferred


def cardinal_neighbors(
    point: tuple[int, int], road_points: set[tuple[int, int]]
) -> list[tuple[int, int]]:
    x, y = point
    return [
        (x + dx, y + dy)
        for dx, dy in FOUR_NEIGHBORS
        if (x + dx, y + dy) in road_points
    ]


def edge_key(
    first: tuple[int, int], second: tuple[int, int]
) -> tuple[tuple[int, int], tuple[int, int]]:
    return (first, second) if first < second else (second, first)


def cardinal_route(
    start: tuple[int, int],
    end: tuple[int, int],
    horizontal_first: bool,
) -> list[tuple[int, int]]:
    """Return the one-bend Manhattan route between two graph cells."""
    x, y = start
    end_x, end_y = end
    result = [start]
    axes = ("x", "y") if horizontal_first else ("y", "x")
    for axis in axes:
        if axis == "x":
            while x != end_x:
                x += 1 if end_x > x else -1
                result.append((x, y))
        else:
            while y != end_y:
                y += 1 if end_y > y else -1
                result.append((x, y))
    return result


def route_deviation(
    route: list[tuple[int, int]], source: list[tuple[int, int]]
) -> tuple[int, int]:
    distances = [
        min(abs(x - source_x) + abs(y - source_y) for source_x, source_y in source)
        for x, y in route
    ]
    return max(distances, default=0), sum(distances)


def foreign_route_contacts(
    route: list[tuple[int, int]],
    source_segment: set[tuple[int, int]],
    all_roads: set[tuple[int, int]],
) -> tuple[int, int]:
    """Count crossings and side contacts with roads outside this corridor."""
    endpoints = {route[0], route[-1]}
    crossings = sum(
        point in all_roads and point not in source_segment and point not in endpoints
        for point in route
    )
    side_contacts = 0
    for index, (x, y) in enumerate(route):
        if index <= 1 or index >= len(route) - 2:
            continue
        for dx, dy in FOUR_NEIGHBORS:
            neighbor = (x + dx, y + dy)
            if neighbor in all_roads and neighbor not in source_segment:
                side_contacts += 1
    return crossings, side_contacts


def simplify_rectilinear_corridors(
    roads: np.ndarray,
    stride: int = RECTILINEAR_CORRIDOR_STRIDE,
    max_deviation: int = RECTILINEAR_MAX_DEVIATION,
) -> np.ndarray:
    """Replace raster stair-steps with deterministic straight corridor runs.

    Junctions and endpoints remain fixed. Degree-two corridors are processed
    in short sections so curved source streets retain their overall course,
    while each section becomes a clean horizontal/vertical route. Candidates
    that would cross, touch, or drift too far from another street are rejected.
    """
    road_points = {
        (int(x), int(y)) for y, x in zip(*np.nonzero(roads))
    }
    anchors = {
        point
        for point in road_points
        if len(cardinal_neighbors(point, road_points)) != 2
    }
    visited_edges: set[tuple[tuple[int, int], tuple[int, int]]] = set()
    chains: list[list[tuple[int, int]]] = []
    covered_points = set(anchors)
    for anchor in sorted(anchors):
        for neighbor in cardinal_neighbors(anchor, road_points):
            first_edge = edge_key(anchor, neighbor)
            if first_edge in visited_edges:
                continue
            visited_edges.add(first_edge)
            chain = [anchor, neighbor]
            previous = anchor
            current = neighbor
            while current not in anchors:
                next_points = [
                    point
                    for point in cardinal_neighbors(current, road_points)
                    if point != previous
                ]
                if not next_points:
                    break
                next_point = next_points[0]
                visited_edges.add(edge_key(current, next_point))
                chain.append(next_point)
                previous, current = current, next_point
            chains.append(chain)
            covered_points.update(chain)

    # A connected road graph normally has anchors. Preserve any pure degree-two
    # cycle or otherwise uncovered source cell rather than guessing its shape.
    simplified = set(anchors)
    simplified.update(road_points - covered_points)
    for chain in chains:
        if len(chain) <= 3:
            simplified.update(chain)
            continue
        index = 0
        while index < len(chain) - 1:
            end_index = min(len(chain) - 1, index + stride)
            source = chain[index : end_index + 1]
            source_set = set(source)
            candidates = [
                cardinal_route(source[0], source[-1], True),
                cardinal_route(source[0], source[-1], False),
            ]
            scored = []
            for candidate in candidates:
                crossings, side_contacts = foreign_route_contacts(
                    candidate, source_set, road_points
                )
                maximum_deviation, total_deviation = route_deviation(
                    candidate, source
                )
                score = (
                    crossings * 100_000
                    + side_contacts * 10_000
                    + maximum_deviation * 100
                    + total_deviation
                )
                scored.append(
                    (
                        score,
                        crossings,
                        side_contacts,
                        maximum_deviation,
                        candidate,
                    )
                )
            best = min(scored, key=lambda candidate: candidate[0])
            if best[1] > 0 or best[2] > 0 or best[3] > max_deviation:
                simplified.update(source)
            else:
                simplified.update(best[4])
            index = end_index

    result = np.zeros(roads.shape, dtype=bool)
    for x, y in simplified:
        result[y, x] = True
    return result


def bend_metrics(roads: np.ndarray) -> dict[str, int]:
    """Count straight and turning degree-two cells for regression checks."""
    road_points = {
        (int(x), int(y)) for y, x in zip(*np.nonzero(roads))
    }
    straight = 0
    turns = 0
    for point in road_points:
        neighbors = cardinal_neighbors(point, road_points)
        if len(neighbors) != 2:
            continue
        first_dx = neighbors[0][0] - point[0]
        first_dy = neighbors[0][1] - point[1]
        second_dx = neighbors[1][0] - point[0]
        second_dy = neighbors[1][1] - point[1]
        if first_dx + second_dx == 0 and first_dy + second_dy == 0:
            straight += 1
        else:
            turns += 1
    total = straight + turns
    return {
        "degreeTwoStraightTiles": straight,
        "degreeTwoTurnTiles": turns,
        "degreeTwoTurnPermille": turns * 1000 // max(1, total),
    }


def parse_semantic_rows(path: Path) -> tuple[list[str], dict]:
    payload = json.loads(path.read_text())
    rows = payload["rows"]
    if len(rows) != GRID_HEIGHT or any(len(row) != GRID_WIDTH for row in rows):
        raise RuntimeError("Wenyu semantic labels are not a 256x144 grid")
    return rows, payload


def near_code(rows: list[str], x: int, y: int, code: str, radius: int) -> bool:
    for candidate_y in range(max(0, y - radius), min(GRID_HEIGHT, y + radius + 1)):
        for candidate_x in range(
            max(0, x - radius), min(GRID_WIDTH, x + radius + 1)
        ):
            if rows[candidate_y][candidate_x] == code:
                return True
    return False


def classify_rows(
    roads: np.ndarray, major: np.ndarray, semantic_rows: list[str]
) -> tuple[list[str], dict[str, int]]:
    """Encode centerlines as M/R/b, using JSON only for hierarchy evidence."""
    encoded: list[str] = []
    counts = {"road-major": 0, "road": 0, "bridge": 0}
    for y in range(GRID_HEIGHT):
        row: list[str] = []
        for x in range(GRID_WIDTH):
            if not roads[y, x]:
                row.append(".")
            elif near_code(semantic_rows, x, y, "b", 2):
                row.append("b")
                counts["bridge"] += 1
            elif major[y, x] or near_code(semantic_rows, x, y, "M", 1):
                row.append("M")
                counts["road-major"] += 1
            else:
                row.append("R")
                counts["road"] += 1
        encoded.append("".join(row))
    return encoded, counts


def component_sizes(mask: np.ndarray, neighbors: tuple[tuple[int, int], ...]) -> list[int]:
    seen = np.zeros(mask.shape, dtype=bool)
    sizes: list[int] = []
    for start_y, start_x in zip(*np.nonzero(mask)):
        if seen[start_y, start_x]:
            continue
        queue = deque([(int(start_y), int(start_x))])
        seen[start_y, start_x] = True
        size = 0
        while queue:
            y, x = queue.popleft()
            size += 1
            for dy, dx in neighbors:
                next_y = y + dy
                next_x = x + dx
                if (
                    0 <= next_y < GRID_HEIGHT
                    and 0 <= next_x < GRID_WIDTH
                    and mask[next_y, next_x]
                    and not seen[next_y, next_x]
                ):
                    seen[next_y, next_x] = True
                    queue.append((next_y, next_x))
        sizes.append(size)
    return sorted(sizes, reverse=True)


def enclosed_block_sizes(roads: np.ndarray) -> list[int]:
    """Measure non-road regions enclosed by the compiled street graph."""
    land = ~roads
    seen = np.zeros(land.shape, dtype=bool)
    enclosed: list[int] = []
    for start_y, start_x in zip(*np.nonzero(land)):
        if seen[start_y, start_x]:
            continue
        queue = deque([(int(start_y), int(start_x))])
        seen[start_y, start_x] = True
        size = 0
        touches_border = False
        while queue:
            y, x = queue.popleft()
            size += 1
            touches_border = touches_border or (
                x == 0
                or y == 0
                or x == GRID_WIDTH - 1
                or y == GRID_HEIGHT - 1
            )
            for dy, dx in FOUR_NEIGHBORS:
                next_y = y + dy
                next_x = x + dx
                if (
                    0 <= next_y < GRID_HEIGHT
                    and 0 <= next_x < GRID_WIDTH
                    and land[next_y, next_x]
                    and not seen[next_y, next_x]
                ):
                    seen[next_y, next_x] = True
                    queue.append((next_y, next_x))
        if not touches_border:
            enclosed.append(size)
    return sorted(enclosed, reverse=True)


def generate(source_path: Path, semantic_path: Path) -> dict:
    rgb = np.asarray(Image.open(source_path).convert("RGB"))
    semantic_rows, semantic_payload = parse_semantic_rows(semantic_path)
    candidates = road_surface_candidates(rgb)
    surface = largest_border_component(candidates)
    skeleton = skeletonize(surface)
    depth = survival_depth(surface)
    roads, major = project_centerline(skeleton, depth)
    roads = skeletonize(roads.astype(np.uint8)).astype(bool)
    major = transfer_nearby_classification(roads, major, 1)
    roads, major = repair_diagonal_joins(roads, major)
    roads = simplify_rectilinear_corridors(roads)
    major = transfer_nearby_classification(roads, major, 2)
    components4 = component_sizes(roads, FOUR_NEIGHBORS)
    if len(components4) != 1:
        raise RuntimeError(
            f"Compiled road graph is not four-connected: {components4[:10]}"
        )
    rows, class_counts = classify_rows(roads, major, semantic_rows)
    blocks = enclosed_block_sizes(roads)
    raw_roads = np.asarray(
        [[code in "MRb" for code in row] for row in semantic_rows],
        dtype=bool,
    )
    raw_components4 = component_sizes(raw_roads, FOUR_NEIGHBORS)

    return {
        "schema": "moontown.wenyu_road_graph.v1",
        "source": {
            "path": f"asset://tilemap/{source_path.name}",
            "semanticLabels": f"asset://tilemap/{semantic_path.name}",
            "semanticSchema": semantic_payload.get("schema"),
            "method": (
                "neutral road-surface segmentation, largest border-connected "
                "component, Zhang-Suen centerline, 256x144 projection, "
                "four-neighbor elbow repair, and topology-safe rectilinear "
                "corridor simplification"
            ),
        },
        "tileGrid": {"width": GRID_WIDTH, "height": GRID_HEIGHT},
        "legend": {
            ".": {"kind": "not-road"},
            "M": {"kind": "road-major"},
            "R": {"kind": "road"},
            "b": {"kind": "bridge"},
        },
        "extraction": {
            "neutralRgbSpreadMax": NEUTRAL_SPREAD_MAX,
            "roadValueMin": ROAD_VALUE_MIN,
            "roadValueMax": ROAD_VALUE_MAX,
            "majorHalfWidthMinSourcePixels": MAJOR_HALF_WIDTH_MIN,
            "rectilinearCorridorStrideTiles": RECTILINEAR_CORRIDOR_STRIDE,
            "rectilinearMaxDeviationTiles": RECTILINEAR_MAX_DEVIATION,
            "bridgeEvidenceRadiusTiles": 2,
            "majorEvidenceRadiusTiles": 1,
        },
        "metrics": {
            "sourceCandidatePixels": int(candidates.sum()),
            "sourceConnectedRoadPixels": int(surface.sum()),
            "sourceCenterlinePixels": int(skeleton.sum()),
            "roadTiles": int(roads.sum()),
            **class_counts,
            "connectedComponents4": len(components4),
            "largestComponent4": components4[0],
            "enclosedLandBlocks": len(blocks),
            "largestEnclosedLandBlocks": blocks[:12],
            **bend_metrics(roads),
            "rawSemanticRoadTiles": int(raw_roads.sum()),
            "rawSemanticConnectedComponents4": len(raw_components4),
            "rawSemanticLargestComponent4": raw_components4[0],
        },
        "openMapReview": {
            "provider": "OpenStreetMap",
            "role": (
                "topology and real-world hierarchy review only; not embedded "
                "because the Wenyu raster has no georeferencing transform"
            ),
            "energyValleyCenter": {"lat": 40.112, "lon": 116.4515},
            "url": "https://www.openstreetmap.org/#map=15/40.1120/116.4515",
        },
        "rows": rows,
    }


def main() -> None:
    repository = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--source",
        type=Path,
        default=repository
        / "src/ui/assets/tilemap/wenyu_topdown_semantic.png",
    )
    parser.add_argument(
        "--semantic",
        type=Path,
        default=repository
        / "src/ui/assets/tilemap/wenyu_reference_labels.json",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=repository
        / "src/ui/assets/tilemap/wenyu_reference_roads.json",
    )
    arguments = parser.parse_args()
    payload = generate(arguments.source, arguments.semantic)
    arguments.output.parent.mkdir(parents=True, exist_ok=True)
    arguments.output.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n"
    )
    print(json.dumps(payload["metrics"], indent=2))
    print(f"Wrote {arguments.output}")


if __name__ == "__main__":
    main()
