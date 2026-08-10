#!/usr/bin/env python3
"""Derive source-authored Wenyu road intersections without enabling GIS runtime.

The illustrated masterplan is the topology authority. Independent semantic
M/R/b samples only grade confidence because their 256x144 down-sampling is
intentionally sparse and disconnected. The saved georeference is copied as
authoring calibration metadata; it is never applied to the points.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
from collections import Counter, defaultdict, deque
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw


GRID_WIDTH = 256
GRID_HEIGHT = 144
NEUTRAL_SPREAD_MAX = 18
ROAD_VALUE_MIN = 175
ROAD_VALUE_MAX = 240
JUNCTION_DILATION_PIXELS = 7
EXTERNAL_ARM_MARGIN_PIXELS = 28
DEDUP_DISTANCE_MILLIS = 2250
ROOF_BLOB_HALF_WIDTH_MIN = 12
SEMANTIC_HIGH_DISTANCE_MILLIS = 750
SEMANTIC_MEDIUM_DISTANCE_MILLIS = 2000
EIGHT_NEIGHBORS = (
    (-1, -1),
    (0, -1),
    (1, -1),
    (-1, 0),
    (1, 0),
    (-1, 1),
    (0, 1),
    (1, 1),
)
SEMANTIC_ROAD_CODES = frozenset("MRb")
WATER_CODES = frozenset("rlw")
FOUR_NEIGHBORS = ((-1, 0), (1, 0), (0, -1), (0, 1))
FORWARD_EIGHT_NEIGHBORS = ((1, 0), (0, 1), (1, 1), (-1, 1))
PREVIEW_GRAPH_METHOD = (
    "exact-seed 8-neighbor source-skeleton geodesics, unique-segment union, "
    "degree-not-two routing-node compression"
)
CONFIDENCE_RANK = {"high": 0, "medium": 1, "review": 2}

EXPECTED_SOURCE_SHA256 = (
    "10d09f3fb45da0e6dbcfb89dee19051df23d8be4b6b5e28aafbd51817c64d93b"
)
EXPECTED_LABELS_SHA256 = (
    "9b93cc1b9c55aa26ec5e2e21b177aea4cba97940e2a78fea06d36d04d84f6d89"
)
EXPECTED_ROTATION_DEGREES = 22.924436871
EXPECTED_METERS_PER_TILE = 37.86186326908114
EXPECTED_FIT_RMS_TILES = 0.476397


def file_sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def road_surface_candidates(rgb: np.ndarray) -> np.ndarray:
    channels = rgb.astype(np.int16)
    spread = channels.max(axis=2) - channels.min(axis=2)
    value = channels.mean(axis=2)
    return (
        (spread <= NEUTRAL_SPREAD_MAX)
        & (value >= ROAD_VALUE_MIN)
        & (value <= ROAD_VALUE_MAX)
    )


def largest_border_component(mask: np.ndarray) -> np.ndarray:
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
            for dx, dy in EIGHT_NEIGHBORS:
                next_x = x + dx
                next_y = y + dy
                if (
                    0 <= next_x < width
                    and 0 <= next_y < height
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
    skeleton = surface.copy()
    for _ in range(max(surface.shape)):
        removed = thinning_pass(skeleton, 0) + thinning_pass(skeleton, 1)
        if removed == 0:
            return skeleton
    raise RuntimeError("Road skeletonization did not converge")


def survival_depth(surface: np.ndarray, max_depth: int = 12) -> np.ndarray:
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


def crossing_number(skeleton: np.ndarray, y: int, x: int) -> int:
    values = [
        skeleton[y - 1, x],
        skeleton[y - 1, x + 1],
        skeleton[y, x + 1],
        skeleton[y + 1, x + 1],
        skeleton[y + 1, x],
        skeleton[y + 1, x - 1],
        skeleton[y, x - 1],
        skeleton[y - 1, x - 1],
    ]
    values.append(values[0])
    return sum(
        values[index] == 0 and values[index + 1] == 1
        for index in range(8)
    )


def dilate(mask: np.ndarray, radius: int) -> np.ndarray:
    height, width = mask.shape
    result = np.zeros(mask.shape, dtype=bool)
    for y, x in zip(*np.nonzero(mask)):
        y0 = max(0, int(y) - radius)
        y1 = min(height, int(y) + radius + 1)
        x0 = max(0, int(x) - radius)
        x1 = min(width, int(x) + radius + 1)
        result[y0:y1, x0:x1] = True
    return result


def components(mask: np.ndarray) -> list[list[tuple[int, int]]]:
    height, width = mask.shape
    seen = np.zeros(mask.shape, dtype=bool)
    result: list[list[tuple[int, int]]] = []
    for start_y, start_x in zip(*np.nonzero(mask)):
        if seen[start_y, start_x]:
            continue
        queue = deque([(int(start_y), int(start_x))])
        seen[start_y, start_x] = True
        component: list[tuple[int, int]] = []
        while queue:
            y, x = queue.popleft()
            component.append((y, x))
            for dx, dy in EIGHT_NEIGHBORS:
                next_x = x + dx
                next_y = y + dy
                if (
                    0 <= next_x < width
                    and 0 <= next_y < height
                    and mask[next_y, next_x]
                    and not seen[next_y, next_x]
                ):
                    seen[next_y, next_x] = True
                    queue.append((next_y, next_x))
        result.append(component)
    return result


def external_arm_count(
    skeleton: np.ndarray,
    junction_region: list[tuple[int, int]],
    margin: int = EXTERNAL_ARM_MARGIN_PIXELS,
) -> int:
    height, width = skeleton.shape
    region = set(junction_region)
    ys = [point[0] for point in junction_region]
    xs = [point[1] for point in junction_region]
    y0 = max(0, min(ys) - margin)
    y1 = min(height, max(ys) + margin + 1)
    x0 = max(0, min(xs) - margin)
    x1 = min(width, max(xs) + margin + 1)
    local = skeleton[y0:y1, x0:x1].astype(bool).copy()
    for y, x in region:
        local[y - y0, x - x0] = False
    arms = 0
    for component in components(local):
        touches_region = False
        for local_y, local_x in component:
            y = local_y + y0
            x = local_x + x0
            if any(
                (y + dy, x + dx) in region for dx, dy in EIGHT_NEIGHBORS
            ):
                touches_region = True
                break
        if touches_region:
            arms += 1
    return arms


def native_millis(source_coordinate: int, source_size: int, grid_size: int) -> int:
    numerator = (2 * source_coordinate + 1) * grid_size * 1000
    denominator = 2 * source_size
    return (numerator + denominator // 2) // denominator


def native_distance_below(
    first: dict, second: dict, source_width: int, source_height: int
) -> bool:
    delta_x = (first["sourceX"] - second["sourceX"]) * GRID_WIDTH
    delta_y = (first["sourceY"] - second["sourceY"]) * GRID_HEIGHT
    numerator = (
        delta_x * delta_x * source_height * source_height
        + delta_y * delta_y * source_width * source_width
    )
    denominator = source_width * source_width * source_height * source_height
    return 1_000_000 * numerator < DEDUP_DISTANCE_MILLIS**2 * denominator


def nearest_semantic_evidence(
    source_x: int,
    source_y: int,
    source_width: int,
    source_height: int,
    semantic_points: list[tuple[int, int, str]],
) -> dict:
    x_denominator = 2 * source_width
    y_denominator = 2 * source_height
    common_denominator = (
        x_denominator * x_denominator * y_denominator * y_denominator
    )
    nearest: tuple[int, int, int, str] | None = None
    for tile_x, tile_y, code in semantic_points:
        delta_x = (
            (2 * source_x + 1) * GRID_WIDTH
            - (2 * tile_x + 1) * source_width
        )
        delta_y = (
            (2 * source_y + 1) * GRID_HEIGHT
            - (2 * tile_y + 1) * source_height
        )
        squared_numerator = (
            delta_x * delta_x * y_denominator * y_denominator
            + delta_y * delta_y * x_denominator * x_denominator
        )
        candidate = (squared_numerator, tile_y, tile_x, code)
        if nearest is None or candidate < nearest:
            nearest = candidate
    if nearest is None:
        raise RuntimeError("Semantic labels contain no M/R/b evidence")
    squared_numerator, tile_y, tile_x, code = nearest
    distance_millis = int(
        math.floor(
            math.sqrt(squared_numerator / common_denominator) * 1000 + 0.5
        )
    )
    if 16 * squared_numerator <= 9 * common_denominator:
        confidence = "high"
    elif squared_numerator <= 4 * common_denominator:
        confidence = "medium"
    else:
        confidence = "review"
    return {
        "nearestDistanceMillis": distance_millis,
        "confidence": confidence,
        "nearestCell": {"x": tile_x, "y": tile_y, "code": code},
    }


def kind_for_arms(arms: int) -> str:
    if arms == 3:
        return "t"
    if arms == 4:
        return "cross"
    return "complex"


def derive_points(
    rgb: np.ndarray, semantic_rows: list[str]
) -> tuple[list[dict], dict]:
    candidates = road_surface_candidates(rgb)
    surface = largest_border_component(candidates)
    skeleton = skeletonize(surface)
    depth = survival_depth(surface)
    height, width = skeleton.shape
    raw = np.zeros(skeleton.shape, dtype=bool)
    crossing = np.zeros(skeleton.shape, dtype=np.uint8)
    for y, x in zip(*np.nonzero(skeleton)):
        if y == 0 or x == 0 or y == height - 1 or x == width - 1:
            continue
        number = crossing_number(skeleton, int(y), int(x))
        crossing[y, x] = number
        if number >= 3 and depth[y, x] >= 1:
            raw[y, x] = True

    branch_clusters: list[dict] = []
    expanded = dilate(raw, JUNCTION_DILATION_PIXELS)
    expanded_components = components(expanded)
    for component in expanded_components:
        core = [(y, x) for y, x in component if raw[y, x]]
        if not core:
            continue
        arms = external_arm_count(skeleton, component)
        if arms < 3:
            continue
        center_y = sum(y for y, _ in core) / len(core)
        center_x = sum(x for _, x in core) / len(core)
        y, x = min(
            core,
            key=lambda point: (
                -int(crossing[point[0], point[1]]),
                -int(depth[point[0], point[1]]),
                (point[0] - center_y) ** 2 + (point[1] - center_x) ** 2,
                point[0],
                point[1],
            ),
        )
        branch_clusters.append(
            {
                "sourceX": x,
                "sourceY": y,
                "externalArms": arms,
                "sourceHalfWidthPixels": int(depth[y, x]),
                "junctionCorePixels": len(core),
            }
        )

    branch_clusters.sort(
        key=lambda point: (
            -point["externalArms"],
            -point["sourceHalfWidthPixels"],
            point["sourceY"],
            point["sourceX"],
        )
    )
    deduplicated: list[dict] = []
    for point in branch_clusters:
        if any(
            native_distance_below(point, kept, width, height)
            for kept in deduplicated
        ):
            continue
        deduplicated.append(point)
    roof_blobs = [
        point
        for point in deduplicated
        if point["sourceHalfWidthPixels"] >= ROOF_BLOB_HALF_WIDTH_MIN
    ]
    kept = [
        point
        for point in deduplicated
        if point["sourceHalfWidthPixels"] < ROOF_BLOB_HALF_WIDTH_MIN
    ]
    kept.sort(key=lambda point: (point["sourceY"], point["sourceX"]))

    semantic_points = [
        (x, y, code)
        for y, row in enumerate(semantic_rows)
        for x, code in enumerate(row)
        if code in SEMANTIC_ROAD_CODES
    ]
    result: list[dict] = []
    for index, point in enumerate(kept):
        evidence = nearest_semantic_evidence(
            point["sourceX"],
            point["sourceY"],
            width,
            height,
            semantic_points,
        )
        result.append(
            {
                "id": f"junction-{index:03d}",
                "xMillis": native_millis(point["sourceX"], width, GRID_WIDTH),
                "yMillis": native_millis(point["sourceY"], height, GRID_HEIGHT),
                "sourcePixel": {
                    "x": point["sourceX"],
                    "y": point["sourceY"],
                },
                "kind": kind_for_arms(point["externalArms"]),
                "externalArms": point["externalArms"],
                "sourceHalfWidthPixels": point["sourceHalfWidthPixels"],
                "junctionCorePixels": point["junctionCorePixels"],
                "semanticEvidence": evidence,
            }
        )

    metrics = {
        "neutralCandidatePixels": int(candidates.sum()),
        "largestBorderConnectedSurfacePixels": int(surface.sum()),
        "sourceSkeletonPixels": int(skeleton.sum()),
        "rawJunctionPixels": int(raw.sum()),
        "expandedCandidateComponents": len(expanded_components),
        "branchVerifiedClusters": len(branch_clusters),
        "deduplicatedBeforeRoofFilter": len(deduplicated),
        "roofBlobsDiscarded": len(roof_blobs),
        "points": len(result),
        "tJunctions": sum(point["kind"] == "t" for point in result),
        "crossIntersections": sum(
            point["kind"] == "cross" for point in result
        ),
        "complexIntersections": sum(
            point["kind"] == "complex" for point in result
        ),
        "externalArmCounts": {
            str(arms): count
            for arms, count in sorted(
                Counter(point["externalArms"] for point in result).items()
            )
        },
        "semanticConfidence": {
            confidence: sum(
                point["semanticEvidence"]["confidence"] == confidence
                for point in result
            )
            for confidence in ("high", "medium", "review")
        },
    }
    return result, metrics


def exact_seed_geodesic_routes(
    skeleton: np.ndarray, points: list[dict]
) -> dict[tuple[int, int], list[tuple[int, int]]]:
    """Connect source-pinned nodes through the skeleton without shortcuts."""
    height, width = skeleton.shape
    unreachable = np.iinfo(np.int32).max
    distance = np.full(skeleton.shape, unreachable, dtype=np.int32)
    label = np.full(skeleton.shape, -1, dtype=np.int16)
    queue: deque[tuple[int, int]] = deque()
    for index, point in enumerate(points):
        source_x = point["sourcePixel"]["x"]
        source_y = point["sourcePixel"]["y"]
        if not skeleton[source_y, source_x]:
            raise RuntimeError(f"{point['id']} does not lie on source skeleton")
        distance[source_y, source_x] = 0
        label[source_y, source_x] = index
        queue.append((source_y, source_x))

    while queue:
        y, x = queue.popleft()
        next_distance = int(distance[y, x]) + 1
        source_label = int(label[y, x])
        for delta_x, delta_y in EIGHT_NEIGHBORS:
            next_x = x + delta_x
            next_y = y + delta_y
            if not (
                0 <= next_x < width
                and 0 <= next_y < height
                and skeleton[next_y, next_x]
            ):
                continue
            if next_distance < distance[next_y, next_x] or (
                next_distance == distance[next_y, next_x]
                and source_label < label[next_y, next_x]
            ):
                distance[next_y, next_x] = next_distance
                label[next_y, next_x] = source_label
                queue.append((next_y, next_x))

    pair_candidates: dict[tuple[int, int], tuple[int, int, int, int, int]] = {}
    for y, x in zip(*np.nonzero(skeleton)):
        y = int(y)
        x = int(x)
        first_label = int(label[y, x])
        if first_label < 0:
            continue
        for delta_x, delta_y in FORWARD_EIGHT_NEIGHBORS:
            next_x = x + delta_x
            next_y = y + delta_y
            if not (
                0 <= next_x < width
                and 0 <= next_y < height
                and skeleton[next_y, next_x]
            ):
                continue
            second_label = int(label[next_y, next_x])
            if second_label < 0 or first_label == second_label:
                continue
            pair = tuple(sorted((first_label, second_label)))
            score = int(distance[y, x]) + int(distance[next_y, next_x]) + 1
            candidate = (score, y, x, next_y, next_x)
            if pair not in pair_candidates or candidate < pair_candidates[pair]:
                pair_candidates[pair] = candidate

    def trace_to_seed(
        start: tuple[int, int], node_index: int
    ) -> list[tuple[int, int]]:
        route = [start]
        current = start
        while int(distance[current]) > 0:
            y, x = current
            candidates: list[tuple[int, int]] = []
            for delta_x, delta_y in EIGHT_NEIGHBORS:
                next_x = x + delta_x
                next_y = y + delta_y
                if not (0 <= next_x < width and 0 <= next_y < height):
                    continue
                if int(label[next_y, next_x]) != node_index:
                    continue
                if int(distance[next_y, next_x]) != int(distance[y, x]) - 1:
                    continue
                candidates.append((next_y, next_x))
            if not candidates:
                raise RuntimeError("Geodesic route could not descend to its seed")
            current = min(candidates)
            route.append(current)
        seed = points[node_index]["sourcePixel"]
        if route[-1] != (seed["y"], seed["x"]):
            raise RuntimeError("Geodesic route ended at a synthetic region seed")
        return route

    routes: dict[tuple[int, int], list[tuple[int, int]]] = {}
    for pair, (_, y, x, next_y, next_x) in sorted(pair_candidates.items()):
        first_label = int(label[y, x])
        second_label = int(label[next_y, next_x])
        left = trace_to_seed((y, x), first_label)
        right = trace_to_seed((next_y, next_x), second_label)
        route = list(reversed(left)) + right
        expected_start = points[pair[0]]["sourcePixel"]
        if route[0] != (expected_start["y"], expected_start["x"]):
            route.reverse()
        expected_end = points[pair[1]]["sourcePixel"]
        if route[0] != (expected_start["y"], expected_start["x"]) or route[-1] != (
            expected_end["y"],
            expected_end["x"],
        ):
            raise RuntimeError("Geodesic route endpoints changed")
        for first, second in zip(route, route[1:]):
            if first == second or max(
                abs(first[0] - second[0]), abs(first[1] - second[1])
            ) != 1:
                raise RuntimeError("Geodesic route contains a non-neighbor step")
            if not skeleton[first] or not skeleton[second]:
                raise RuntimeError("Geodesic route left the source skeleton")
        routes[pair] = route
    return routes


def source_segment_key(
    first: tuple[int, int], second: tuple[int, int]
) -> tuple[tuple[int, int], tuple[int, int]]:
    return (first, second) if first < second else (second, first)


def confidence_for_point_pair(pair: tuple[int, int], points: list[dict]) -> str:
    return max(
        (
            points[index]["semanticEvidence"]["confidence"]
            for index in pair
        ),
        key=lambda confidence: CONFIDENCE_RANK[confidence],
    )


def compress_geodesic_union(
    routes: dict[tuple[int, int], list[tuple[int, int]]],
    points: list[dict],
    source_width: int,
    source_height: int,
) -> tuple[list[dict], list[dict], dict[str, int], int]:
    """Partition the route union into unique, non-overlapping physical edges."""
    segment_confidence: dict[
        tuple[tuple[int, int], tuple[int, int]], set[str]
    ] = defaultdict(set)
    adjacency: dict[tuple[int, int], set[tuple[int, int]]] = defaultdict(set)
    point_at_source = {
        (point["sourcePixel"]["y"], point["sourcePixel"]["x"]): index
        for index, point in enumerate(points)
    }
    if len(point_at_source) != len(points):
        raise RuntimeError("Preview graph point sources are not unique")

    for pair, route in sorted(routes.items()):
        confidence = confidence_for_point_pair(pair, points)
        for first, second in zip(route, route[1:]):
            key = source_segment_key(first, second)
            segment_confidence[key].add(confidence)
            adjacency[first].add(second)
            adjacency[second].add(first)

    anchors = set(point_at_source)
    anchors.update(
        source_point
        for source_point, neighbors in adjacency.items()
        if len(neighbors) != 2
    )
    seen: set[tuple[int, int]] = set()
    for start in sorted(adjacency):
        if start in seen:
            continue
        stack = [start]
        seen.add(start)
        component: list[tuple[int, int]] = []
        while stack:
            current = stack.pop()
            component.append(current)
            for neighbor in adjacency[current]:
                if neighbor not in seen:
                    seen.add(neighbor)
                    stack.append(neighbor)
        if not any(source_point in anchors for source_point in component):
            anchors.add(min(component))

    routing_sources = sorted(
        source_point for source_point in anchors if source_point not in point_at_source
    )
    routing_index = {
        source_point: index for index, source_point in enumerate(routing_sources)
    }

    def anchor_id(source_point: tuple[int, int]) -> str:
        if source_point in point_at_source:
            return points[point_at_source[source_point]]["id"]
        return f"routing-{routing_index[source_point]:03d}"

    visited_segments: set[
        tuple[tuple[int, int], tuple[int, int]]
    ] = set()
    compressed: list[dict] = []
    for anchor in sorted(anchors):
        for neighbor in sorted(adjacency[anchor]):
            first_key = source_segment_key(anchor, neighbor)
            if first_key in visited_segments:
                continue
            visited_segments.add(first_key)
            path = [anchor, neighbor]
            previous = anchor
            current = neighbor
            while current not in anchors:
                candidates = sorted(adjacency[current] - {previous})
                if len(candidates) != 1:
                    raise RuntimeError("Degree-two corridor changed during compression")
                next_point = candidates[0]
                key = source_segment_key(current, next_point)
                if key in visited_segments:
                    raise RuntimeError("Compressed preview edge reused a source segment")
                visited_segments.add(key)
                path.append(next_point)
                previous, current = current, next_point
            confidences: set[str] = set()
            for first, second in zip(path, path[1:]):
                confidences.update(
                    segment_confidence[source_segment_key(first, second)]
                )
            from_id = anchor_id(path[0])
            to_id = anchor_id(path[-1])
            if from_id == to_id:
                raise RuntimeError("Compressed preview graph contains a self-loop")
            if from_id > to_id:
                from_id, to_id = to_id, from_id
                path.reverse()
            compressed.append(
                {
                    "from": from_id,
                    "to": to_id,
                    "sourcePath": path,
                    "confidence": max(
                        confidences,
                        key=lambda confidence: CONFIDENCE_RANK[confidence],
                    ),
                }
            )

    if visited_segments != set(segment_confidence):
        raise RuntimeError("Compressed preview graph did not partition its union")
    compressed.sort(
        key=lambda edge: (
            edge["from"],
            edge["to"],
            edge["sourcePath"],
        )
    )
    endpoint_pairs = [
        (edge["from"], edge["to"])
        for edge in compressed
    ]
    if len(set(endpoint_pairs)) != len(endpoint_pairs):
        raise RuntimeError("Compressed preview graph contains parallel edges")

    routing_nodes = []
    for index, (source_y, source_x) in enumerate(routing_sources):
        routing_nodes.append(
            {
                "id": f"routing-{index:03d}",
                "xMillis": native_millis(source_x, source_width, GRID_WIDTH),
                "yMillis": native_millis(source_y, source_height, GRID_HEIGHT),
                "reason": "source-branch",
            }
        )

    degrees = Counter()
    for edge in compressed:
        degrees[edge["from"]] += 1
        degrees[edge["to"]] += 1
    for point in points:
        if degrees[point["id"]] > point["externalArms"]:
            raise RuntimeError(
                f"{point['id']} preview degree exceeds verified external arms"
            )
    unrepresented_arms = sum(
        point["externalArms"] - degrees[point["id"]]
        for point in points
    )
    return routing_nodes, compressed, dict(degrees), unrepresented_arms


def terminal_corridor_count(
    skeleton: np.ndarray, surface: np.ndarray, points: list[dict]
) -> int:
    """Count source corridor components that touch one verified node region."""
    height, width = skeleton.shape
    raw = np.zeros(skeleton.shape, dtype=bool)
    depth = survival_depth(surface)
    for y, x in zip(*np.nonzero(skeleton)):
        y = int(y)
        x = int(x)
        if y == 0 or x == 0 or y == height - 1 or x == width - 1:
            continue
        if crossing_number(skeleton, y, x) >= 3 and depth[y, x] >= 1:
            raw[y, x] = True
    expanded_components = components(dilate(raw, JUNCTION_DILATION_PIXELS))
    node_by_source = {
        (point["sourcePixel"]["y"], point["sourcePixel"]["x"]): index
        for index, point in enumerate(points)
    }
    owner = np.full(skeleton.shape, -1, dtype=np.int16)
    for component in expanded_components:
        contained = sorted(
            node_by_source[source_point]
            for source_point in component
            if source_point in node_by_source
        )
        if len(contained) > 1:
            raise RuntimeError("Verified node regions overlap")
        if not contained:
            continue
        for y, x in component:
            owner[y, x] = contained[0]

    remaining = skeleton.astype(bool) & (owner < 0)
    terminals = 0
    for component in components(remaining):
        touches: set[int] = set()
        for y, x in component:
            for delta_x, delta_y in EIGHT_NEIGHBORS:
                next_x = x + delta_x
                next_y = y + delta_y
                if 0 <= next_x < width and 0 <= next_y < height:
                    node = int(owner[next_y, next_x])
                    if node >= 0:
                        touches.add(node)
        if len(touches) == 1:
            terminals += 1
    return terminals


def repair_diagonal_grid_joins(roads: np.ndarray) -> np.ndarray:
    repaired = roads.copy()
    changed = True
    while changed:
        changed = False
        for y in range(GRID_HEIGHT - 1):
            for x in range(GRID_WIDTH - 1):
                northwest = repaired[y, x]
                northeast = repaired[y, x + 1]
                southwest = repaired[y + 1, x]
                southeast = repaired[y + 1, x + 1]
                if northwest and southeast and not northeast and not southwest:
                    repaired[y, x + 1] = True
                    changed = True
                elif southwest and northeast and not northwest and not southeast:
                    repaired[y, x] = True
                    changed = True
    return repaired


def enclosed_grid_blocks(roads: np.ndarray) -> int:
    land = ~roads
    seen = np.zeros(land.shape, dtype=bool)
    enclosed = 0
    for start_y, start_x in zip(*np.nonzero(land)):
        start_y = int(start_y)
        start_x = int(start_x)
        if seen[start_y, start_x]:
            continue
        queue = deque([(start_y, start_x)])
        seen[start_y, start_x] = True
        touches_border = False
        while queue:
            y, x = queue.popleft()
            touches_border = touches_border or (
                x == 0
                or y == 0
                or x == GRID_WIDTH - 1
                or y == GRID_HEIGHT - 1
            )
            for delta_x, delta_y in FOUR_NEIGHBORS:
                next_x = x + delta_x
                next_y = y + delta_y
                if (
                    0 <= next_x < GRID_WIDTH
                    and 0 <= next_y < GRID_HEIGHT
                    and land[next_y, next_x]
                    and not seen[next_y, next_x]
                ):
                    seen[next_y, next_x] = True
                    queue.append((next_y, next_x))
        if not touches_border:
            enclosed += 1
    return enclosed


def preview_graph_components(edges: list[dict], node_ids: set[str]) -> int:
    adjacency: dict[str, set[str]] = {node_id: set() for node_id in node_ids}
    for edge in edges:
        adjacency[edge["from"]].add(edge["to"])
        adjacency[edge["to"]].add(edge["from"])
    seen: set[str] = set()
    count = 0
    for start in sorted(node_ids):
        if start in seen:
            continue
        count += 1
        queue = [start]
        seen.add(start)
        while queue:
            current = queue.pop()
            for neighbor in adjacency[current]:
                if neighbor not in seen:
                    seen.add(neighbor)
                    queue.append(neighbor)
    return count


def derive_preview_graph(
    rgb: np.ndarray, semantic_rows: list[str], points: list[dict]
) -> dict:
    candidates = road_surface_candidates(rgb)
    surface = largest_border_component(candidates)
    skeleton = skeletonize(surface)
    source_height, source_width = skeleton.shape
    routes = exact_seed_geodesic_routes(skeleton, points)
    routing_nodes, compressed, degrees, unrepresented_arms = (
        compress_geodesic_union(
            routes, points, source_width, source_height
        )
    )

    bridge_evidence = np.asarray(
        [[code == "b" for code in row] for row in semantic_rows],
        dtype=bool,
    )
    near_bridge = np.zeros(bridge_evidence.shape, dtype=bool)
    for y, x in zip(*np.nonzero(bridge_evidence)):
        y = int(y)
        x = int(x)
        near_bridge[
            max(0, y - 2) : min(GRID_HEIGHT, y + 3),
            max(0, x - 2) : min(GRID_WIDTH, x + 3),
        ] = True

    edges: list[dict] = []
    bridge_count = 0
    bridge_evidence_vertices = 0
    bridge_span_vertices = 0
    water_conflicts = 0
    road_grid = np.zeros((GRID_HEIGHT, GRID_WIDTH), dtype=bool)
    endpoint_millis = {
        point["id"]: (point["xMillis"], point["yMillis"])
        for point in points
    }
    endpoint_millis.update(
        {
            node["id"]: (node["xMillis"], node["yMillis"])
            for node in routing_nodes
        }
    )
    for index, edge in enumerate(compressed):
        path_millis: list[list[int]] = []
        path_codes: list[str] = []
        path_cells: list[tuple[int, int]] = []
        for source_y, source_x in edge["sourcePath"]:
            x_millis = native_millis(source_x, source_width, GRID_WIDTH)
            y_millis = native_millis(source_y, source_height, GRID_HEIGHT)
            path_millis.append([x_millis, y_millis])
            grid_x = min(
                GRID_WIDTH - 1, source_x * GRID_WIDTH // source_width
            )
            grid_y = min(
                GRID_HEIGHT - 1, source_y * GRID_HEIGHT // source_height
            )
            road_grid[grid_y, grid_x] = True
            path_cells.append((grid_x, grid_y))
            path_codes.append(semantic_rows[grid_y][grid_x])
        if tuple(path_millis[0]) != endpoint_millis[edge["from"]] or tuple(
            path_millis[-1]
        ) != endpoint_millis[edge["to"]]:
            raise RuntimeError("Compressed edge endpoints changed during projection")
        for first, second in zip(path_millis, path_millis[1:]):
            delta_x = abs(first[0] - second[0])
            delta_y = abs(first[1] - second[1])
            if (delta_x == 0 and delta_y == 0) or delta_x > 154 or delta_y > 154:
                raise RuntimeError("Serialized graph contains a non-source step")

        bridge_indexes: list[int] = []
        for path_index, ((grid_x, grid_y), code) in enumerate(
            zip(path_cells, path_codes)
        ):
            if code in WATER_CODES and not near_bridge[grid_y, grid_x]:
                water_conflicts += 1
            if code == "b" or code in WATER_CODES:
                bridge_indexes.append(path_index)
            if code == "b":
                bridge_evidence_vertices += 1
        spans: list[dict] = []
        for path_index in bridge_indexes:
            if not spans or path_index > spans[-1]["toIndex"] + 1:
                spans.append(
                    {"fromIndex": path_index, "toIndex": path_index}
                )
            else:
                spans[-1]["toIndex"] = path_index
        expanded_spans: list[dict] = []
        for span in spans:
            if span["fromIndex"] == span["toIndex"]:
                evidence_index = span["fromIndex"]
                span = {
                    "fromIndex": max(0, evidence_index - 1),
                    "toIndex": min(len(path_millis) - 1, evidence_index + 1),
                }
            if span["fromIndex"] >= span["toIndex"]:
                raise RuntimeError("Bridge evidence cannot form a drawable span")
            if expanded_spans and span["fromIndex"] <= expanded_spans[-1]["toIndex"]:
                expanded_spans[-1]["toIndex"] = max(
                    expanded_spans[-1]["toIndex"], span["toIndex"]
                )
            else:
                expanded_spans.append(span)
        spans = expanded_spans
        for span in spans:
            if not any(
                path_codes[path_index] == "b"
                for path_index in range(
                    span["fromIndex"], span["toIndex"] + 1
                )
            ):
                water_conflicts += 1
        bridge_count += len(spans)
        bridge_span_vertices += sum(
            span["toIndex"] - span["fromIndex"] + 1 for span in spans
        )
        edges.append(
            {
                "id": f"edge-{index:03d}",
                "from": edge["from"],
                "to": edge["to"],
                "pathMillis": path_millis,
                "sourceLengthPixels": len(path_millis) - 1,
                "confidence": edge["confidence"],
                "bridgeSpans": spans,
            }
        )

    if water_conflicts:
        raise RuntimeError(
            f"Preview graph has {water_conflicts} unreviewed water conflicts"
        )
    node_ids = {point["id"] for point in points} | {
        node["id"] for node in routing_nodes
    }
    components_count = preview_graph_components(edges, node_ids)
    repaired_grid = repair_diagonal_grid_joins(road_grid)
    metrics = {
        "nodes": len(points),
        "routingNodes": len(routing_nodes),
        "totalGraphNodes": len(node_ids),
        "edges": len(edges),
        "components": components_count,
        "cycleRank": len(edges) - len(node_ids) + components_count,
        "terminalsOmitted": terminal_corridor_count(skeleton, surface, points),
        "unrepresentedVerifiedArms": unrepresented_arms,
        "bridges": bridge_count,
        "bridgeEvidenceVertices": bridge_evidence_vertices,
        "bridgeSpanVertices": bridge_span_vertices,
        "waterConflicts": water_conflicts,
        "sourceSegments": sum(edge["sourceLengthPixels"] for edge in edges),
        "enclosedBlocks": enclosed_grid_blocks(repaired_grid),
    }
    expected = {
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
    }
    if metrics != expected:
        raise RuntimeError(f"Preview graph acceptance changed: {metrics}")
    if len(degrees) != len(node_ids):
        raise RuntimeError("Preview graph contains an unreferenced node")
    return {
        "method": PREVIEW_GRAPH_METHOD,
        "metrics": metrics,
        "routingNodes": routing_nodes,
        "edges": edges,
    }


def load_calibration(path: Path) -> dict:
    payload = json.loads(path.read_text())
    selected = payload["selectedModel"]
    diagnostics = selected["diagnostics"]
    rotation = diagnostics["rotationDegrees"]
    meters_per_tile = diagnostics["singularValuesMetersPerTile"][0]
    fit_rms = selected["metrics"]["tiles"]["rms"]
    actual = (rotation, meters_per_tile, fit_rms)
    expected = (
        EXPECTED_ROTATION_DEGREES,
        EXPECTED_METERS_PER_TILE,
        EXPECTED_FIT_RMS_TILES,
    )
    if actual != expected:
        raise RuntimeError(f"Authoring calibration changed: {actual} != {expected}")
    return {
        "source": "asset://tilemap/georeference/wenyu-town-georef-v1.json",
        "model": "similarity",
        "rotationDegrees": rotation,
        "metersPerTile": meters_per_tile,
        "fitRmsTiles": fit_rms,
        "runtimeEligible": False,
        "appliedToPoints": False,
        "scope": "authoring calibration only; no point transform or transport activation",
    }


def build_payload(
    source_path: Path, labels_path: Path, georef_path: Path
) -> dict:
    source_digest = file_sha256(source_path)
    labels_digest = file_sha256(labels_path)
    if source_digest != EXPECTED_SOURCE_SHA256:
        raise RuntimeError("Wenyu source image digest changed")
    if labels_digest != EXPECTED_LABELS_SHA256:
        raise RuntimeError("Wenyu semantic labels digest changed")
    image = Image.open(source_path).convert("RGB")
    rgb = np.asarray(image)
    labels = json.loads(labels_path.read_text())
    rows = labels["rows"]
    if len(rows) != GRID_HEIGHT or any(len(row) != GRID_WIDTH for row in rows):
        raise RuntimeError("Semantic labels are not a 256x144 grid")
    points, metrics = derive_points(rgb, rows)
    if (
        metrics["points"],
        metrics["tJunctions"],
        metrics["crossIntersections"],
        metrics["complexIntersections"],
        metrics["roofBlobsDiscarded"],
    ) != (145, 84, 55, 6, 2):
        raise RuntimeError(f"Intersection acceptance changed: {metrics}")
    preview_graph = derive_preview_graph(rgb, rows, points)
    return {
        "schema": "moontown.wenyu_reference_intersections.v2",
        "runtimeEligible": False,
        "tileGrid": {
            "width": GRID_WIDTH,
            "height": GRID_HEIGHT,
            "coordinateUnit": "millitile",
        },
        "source": {
            "image": {
                "path": "asset://tilemap/wenyu_topdown_semantic.png",
                "sha256": f"sha256:{source_digest}",
                "width": image.width,
                "height": image.height,
            },
            "semanticLabels": {
                "path": "asset://tilemap/wenyu_reference_labels.json",
                "sha256": f"sha256:{labels_digest}",
                "schema": labels["schema"],
                "role": "independent confidence only; never a point filter",
                "roadCodes": ["M", "R", "b"],
            },
        },
        "detector": {
            "method": (
                "neutral border-connected source surface, Zhang-Suen skeleton, "
                "crossing-number branch pixels, external-arm tracing, native "
                "distance deduplication, and wide neutral roof rejection"
            ),
            "neutralRgbSpreadMax": NEUTRAL_SPREAD_MAX,
            "roadValueMin": ROAD_VALUE_MIN,
            "roadValueMax": ROAD_VALUE_MAX,
            "crossingNumberMinimum": 3,
            "junctionDilationPixels": JUNCTION_DILATION_PIXELS,
            "externalArmMarginPixels": EXTERNAL_ARM_MARGIN_PIXELS,
            "externalArmMinimum": 3,
            "dedupDistanceMillis": DEDUP_DISTANCE_MILLIS,
            "roofBlobHalfWidthMinimumPixels": ROOF_BLOB_HALF_WIDTH_MIN,
            "semanticConfidenceThresholdsMillis": {
                "highMaximum": SEMANTIC_HIGH_DISTANCE_MILLIS,
                "mediumMaximum": SEMANTIC_MEDIUM_DISTANCE_MILLIS,
            },
        },
        "authoringCalibration": load_calibration(georef_path),
        "metrics": metrics,
        "points": points,
        "previewGraph": preview_graph,
    }


def render_preview(payload: dict, source_path: Path, output_path: Path) -> None:
    image = Image.open(source_path).convert("RGB")
    draw = ImageDraw.Draw(image)
    for point in payload["points"]:
        x = point["sourcePixel"]["x"]
        y = point["sourcePixel"]["y"]
        color = (255, 185, 41) if point["kind"] == "t" else (255, 58, 119)
        draw.ellipse(
            (x - 7, y - 7, x + 7, y + 7),
            fill=(255, 255, 255),
            outline=(30, 30, 30),
            width=2,
        )
        draw.ellipse((x - 3, y - 3, x + 3, y + 3), fill=color)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    image.save(output_path)


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    tilemap = root / "src/ui/assets/tilemap"
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--source", type=Path, default=tilemap / "wenyu_topdown_semantic.png"
    )
    parser.add_argument(
        "--semantic", type=Path, default=tilemap / "wenyu_reference_labels.json"
    )
    parser.add_argument(
        "--georef",
        type=Path,
        default=tilemap / "georeference/wenyu-town-georef-v1.json",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=tilemap / "wenyu_reference_intersections.json",
    )
    parser.add_argument("--preview", type=Path)
    args = parser.parse_args()
    payload = build_payload(args.source, args.semantic, args.georef)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n")
    if args.preview is not None:
        render_preview(payload, args.source, args.preview)
    print(json.dumps(payload["metrics"], indent=2))
    print(f"Wrote {args.output}")


if __name__ == "__main__":
    main()
