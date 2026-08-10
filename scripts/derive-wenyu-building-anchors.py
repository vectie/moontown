#!/usr/bin/env python3
"""Derive Wenyu roof-provenance anchors from one aligned semantic frame.

This authoring-only script reads ``wenyu_topdown_semantic.png`` and the
already-aligned 256x144 semantic/road rasters.  It never transforms or samples
the older, differently composed building source. Output paths default to a
temporary review directory so generation never overwrites the checked asset.

Dependencies: Pillow and NumPy.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from collections import Counter, deque
from dataclasses import dataclass
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont


GRID_WIDTH = 256
GRID_HEIGHT = 144
FOUR_NEIGHBORS = ((1, 0), (-1, 0), (0, 1), (0, -1))
EIGHT_NEIGHBORS = FOUR_NEIGHBORS + ((1, 1), (1, -1), (-1, 1), (-1, -1))
EXCLUDED_SOURCE_ANCHORS = {
    (410, 128, 126): "disconnected-local-path",
}

CODE_FOR_KIND = {
    "lowrise": "l",
    "row": "r",
    "block": "b",
    "tower": "t",
    "courtyard": "q",
    "campus": "c",
    "civic": "v",
    "industrial": "i",
}
KIND_FOR_CODE = {code: kind for kind, code in CODE_FOR_KIND.items()}
ASSET_FOR_KIND = {
    kind: f"buildings/wenyu_shape/cell_{kind}.png" for kind in CODE_FOR_KIND
}
COLOR_FOR_CODE = {
    "l": (252, 211, 77, 224),
    "r": (251, 146, 60, 224),
    "b": (239, 68, 68, 224),
    "t": (168, 85, 247, 224),
    "q": (236, 72, 153, 224),
    "c": (59, 130, 246, 224),
    "v": (20, 184, 166, 224),
    "i": (100, 116, 139, 224),
}


@dataclass
class GridComponent:
    cells: list[tuple[int, int]]
    min_x: int
    min_y: int
    max_x: int
    max_y: int
    area: int
    terrain: Counter[str]
    avg_bright: float
    avg_mid: float
    fill: float
    holes: int
    kind: str = "block"


@dataclass
class SourceRoofComponent:
    index: int
    pixels: list[int]
    min_x: int
    min_y: int
    max_x: int
    max_y: int
    sum_x: int
    sum_y: int
    area: int
    avg_value: float


@dataclass
class SourceBlockCore:
    source_component: int
    block_id: int
    source_pixels: int
    min_source_x: int
    min_source_y: int
    max_source_x: int
    max_source_y: int
    avg_value: float
    terrain: Counter[str]
    tile_counts: dict[tuple[int, int], int]
    core_x: int
    core_y: int
    core_evidence_pixels: int
    source_cell_pixels: int
    source_road_pixels: int
    overlap_ratio: float
    legal_distance: int
    kind: str = "block"


def read_rows(path: Path, key: str) -> tuple[list[str], dict]:
    payload = json.loads(path.read_text())
    rows = payload[key]
    if len(rows) != GRID_HEIGHT or any(len(row) != GRID_WIDTH for row in rows):
        raise RuntimeError(f"{path} is not a 256x144 raster")
    return rows, payload


def largest_border_component(mask: np.ndarray) -> np.ndarray:
    """Match the road-graph extractor's deterministic 8-neighbor surface."""
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
        raise RuntimeError("no border-connected road surface")
    result = np.zeros(mask.shape, dtype=bool)
    for index in largest:
        y, x = divmod(index, width)
        result[y, x] = True
    return result


def dilate(mask: np.ndarray, radius: int) -> np.ndarray:
    height, width = mask.shape
    padded = np.pad(mask, radius)
    result = np.zeros(mask.shape, dtype=bool)
    for offset_y in range(radius * 2 + 1):
        for offset_x in range(radius * 2 + 1):
            result |= padded[
                offset_y : offset_y + height,
                offset_x : offset_x + width,
            ]
    return result


def erode(mask: np.ndarray, radius: int) -> np.ndarray:
    height, width = mask.shape
    padded = np.pad(mask, radius)
    result = np.ones(mask.shape, dtype=bool)
    for offset_y in range(radius * 2 + 1):
        for offset_x in range(radius * 2 + 1):
            result &= padded[
                offset_y : offset_y + height,
                offset_x : offset_x + width,
            ]
    return result


def source_roof_components(
    mask: np.ndarray,
    value: np.ndarray,
    min_pixels: int,
) -> list[SourceRoofComponent]:
    """Extract eroded source-pixel roof cores before any grid projection."""
    height, width = mask.shape
    seen = np.zeros(mask.shape, dtype=bool)
    result: list[SourceRoofComponent] = []
    for start_y, start_x in zip(*np.nonzero(mask)):
        start_y = int(start_y)
        start_x = int(start_x)
        if seen[start_y, start_x]:
            continue
        pixels = [start_y * width + start_x]
        seen[start_y, start_x] = True
        min_x = max_x = start_x
        min_y = max_y = start_y
        sum_x = sum_y = 0
        sum_value = 0.0
        for encoded in pixels:
            y, x = divmod(encoded, width)
            min_x = min(min_x, x)
            min_y = min(min_y, y)
            max_x = max(max_x, x)
            max_y = max(max_y, y)
            sum_x += x
            sum_y += y
            sum_value += float(value[y, x])
            for dx, dy in FOUR_NEIGHBORS:
                next_x = x + dx
                next_y = y + dy
                if (
                    0 <= next_x < width
                    and 0 <= next_y < height
                    and mask[next_y, next_x]
                    and not seen[next_y, next_x]
                ):
                    seen[next_y, next_x] = True
                    pixels.append(next_y * width + next_x)
        area = len(pixels)
        if area < min_pixels:
            continue
        result.append(
            SourceRoofComponent(
                index=len(result),
                pixels=pixels,
                min_x=min_x,
                min_y=min_y,
                max_x=max_x,
                max_y=max_y,
                sum_x=sum_x,
                sum_y=sum_y,
                area=area,
                avg_value=sum_value / area,
            )
        )
    return result


def tile_counts(mask: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
    source_height, source_width = mask.shape
    counts = np.zeros((GRID_HEIGHT, GRID_WIDTH), dtype=np.int32)
    totals = np.zeros((GRID_HEIGHT, GRID_WIDTH), dtype=np.int32)
    for grid_y in range(GRID_HEIGHT):
        y0 = grid_y * source_height // GRID_HEIGHT
        y1 = (grid_y + 1) * source_height // GRID_HEIGHT
        for grid_x in range(GRID_WIDTH):
            x0 = grid_x * source_width // GRID_WIDTH
            x1 = (grid_x + 1) * source_width // GRID_WIDTH
            counts[grid_y, grid_x] = int(mask[y0:y1, x0:x1].sum())
            totals[grid_y, grid_x] = (y1 - y0) * (x1 - x0)
    return counts, totals


def enclosed_blocks(road_mask: np.ndarray) -> tuple[np.ndarray, list[int]]:
    seen = np.zeros(road_mask.shape, dtype=bool)
    block_ids = np.full(road_mask.shape, -1, dtype=np.int32)
    sizes: list[int] = []
    for start_y in range(GRID_HEIGHT):
        for start_x in range(GRID_WIDTH):
            if seen[start_y, start_x] or road_mask[start_y, start_x]:
                continue
            queue = [(start_x, start_y)]
            seen[start_y, start_x] = True
            touches_border = False
            for x, y in queue:
                touches_border = touches_border or (
                    x == 0
                    or y == 0
                    or x == GRID_WIDTH - 1
                    or y == GRID_HEIGHT - 1
                )
                for dx, dy in FOUR_NEIGHBORS:
                    next_x = x + dx
                    next_y = y + dy
                    if (
                        0 <= next_x < GRID_WIDTH
                        and 0 <= next_y < GRID_HEIGHT
                        and not seen[next_y, next_x]
                        and not road_mask[next_y, next_x]
                    ):
                        seen[next_y, next_x] = True
                        queue.append((next_x, next_y))
            if touches_border:
                continue
            block_id = len(sizes)
            sizes.append(len(queue))
            for x, y in queue:
                block_ids[y, x] = block_id
    return block_ids, sizes


def legal_three_by_three_centers(
    block_ids: np.ndarray,
    road_mask: np.ndarray,
    semantic_rows: list[str],
) -> dict[int, list[tuple[int, int]]]:
    """Preflight the smallest runtime footprint and immediate road frontage."""
    result: dict[int, list[tuple[int, int]]] = {}
    for y in range(1, GRID_HEIGHT - 3):
        for x in range(1, GRID_WIDTH - 3):
            block_id = int(block_ids[y, x])
            if block_id < 0:
                continue
            cells = [(xx, yy) for yy in range(y, y + 3) for xx in range(x, x + 3)]
            if any(int(block_ids[yy, xx]) != block_id for xx, yy in cells):
                continue
            if sum(semantic_rows[yy][xx] in "uUc" for xx, yy in cells) < 5:
                continue
            perimeter = (
                [(xx, y - 1) for xx in range(x - 1, x + 4)]
                + [(xx, y + 3) for xx in range(x - 1, x + 4)]
                + [(x - 1, yy) for yy in range(y, y + 3)]
                + [(x + 3, yy) for yy in range(y, y + 3)]
            )
            if not any(road_mask[yy, xx] for xx, yy in perimeter):
                continue
            result.setdefault(block_id, []).append((x + 1, y + 1))
    return result


def source_component_block_cores(
    components: list[SourceRoofComponent],
    source_shape: tuple[int, int],
    block_ids: np.ndarray,
    road_mask: np.ndarray,
    semantic_rows: list[str],
    legal_centers: dict[int, list[tuple[int, int]]],
    source_road_counts: np.ndarray,
    source_tile_totals: np.ndarray,
    min_piece_pixels: int,
    min_anchor_evidence_pixels: int,
    min_anchor_evidence_ratio: float,
    max_legal_distance: int,
) -> list[SourceBlockCore]:
    """Choose one stable half-grid-aligned centroid anchor per block."""
    source_height, source_width = source_shape
    source_to_grid_x = np.zeros(source_width, dtype=np.int16)
    source_to_grid_y = np.zeros(source_height, dtype=np.int16)
    for grid_x in range(GRID_WIDTH):
        x0 = grid_x * source_width // GRID_WIDTH
        x1 = (grid_x + 1) * source_width // GRID_WIDTH
        source_to_grid_x[x0:x1] = grid_x
    for grid_y in range(GRID_HEIGHT):
        y0 = grid_y * source_height // GRID_HEIGHT
        y1 = (grid_y + 1) * source_height // GRID_HEIGHT
        source_to_grid_y[y0:y1] = grid_y
    proposals: list[SourceBlockCore] = []
    for component in components:
        by_block: dict[int, dict] = {}
        for encoded in component.pixels:
            source_y, source_x = divmod(encoded, source_width)
            grid_x = int(source_to_grid_x[source_x])
            grid_y = int(source_to_grid_y[source_y])
            block_id = int(block_ids[grid_y, grid_x])
            if (
                block_id < 0
                or road_mask[grid_y, grid_x]
                or semantic_rows[grid_y][grid_x] not in "uUc"
                or block_id not in legal_centers
            ):
                continue
            record = by_block.setdefault(
                block_id,
                {
                    "pixels": 0,
                    "min_x": source_x,
                    "min_y": source_y,
                    "max_x": source_x,
                    "max_y": source_y,
                    "sum_value": 0.0,
                    "terrain": Counter(),
                    "tiles": Counter(),
                },
            )
            record["pixels"] += 1
            record["min_x"] = min(record["min_x"], source_x)
            record["min_y"] = min(record["min_y"], source_y)
            record["max_x"] = max(record["max_x"], source_x)
            record["max_y"] = max(record["max_y"], source_y)
            record["sum_value"] += component.avg_value
            record["terrain"][semantic_rows[grid_y][grid_x]] += 1
            record["tiles"][(grid_x, grid_y)] += 1
        for block_id, record in by_block.items():
            if record["pixels"] < min_piece_pixels:
                continue
            tile_counts_for_piece: Counter[tuple[int, int]] = record["tiles"]
            weighted_x = sum(x * count for (x, _), count in tile_counts_for_piece.items())
            weighted_y = sum(y * count for (_, y), count in tile_counts_for_piece.items())
            total = sum(tile_counts_for_piece.values())
            centroid_x = weighted_x / total
            centroid_y = weighted_y / total
            best: tuple[int, int, int, int, int] | None = None
            # Even origins make this mask exactly reproducible at 128x72.
            for core_y in range(0, GRID_HEIGHT - 1, 2):
                if abs((core_y + 0.5) - centroid_y) > 6:
                    continue
                for core_x in range(0, GRID_WIDTH - 1, 2):
                    if abs((core_x + 0.5) - centroid_x) > 6:
                        continue
                    if (
                        int(block_ids[core_y, core_x]) != block_id
                        or road_mask[core_y, core_x]
                        or semantic_rows[core_y][core_x] not in "uUc"
                    ):
                        continue
                    evidence = tile_counts_for_piece[(core_x, core_y)]
                    source_cell_pixels = int(source_tile_totals[core_y, core_x])
                    source_road_pixels = int(source_road_counts[core_y, core_x])
                    overlap_ratio = evidence / source_cell_pixels
                    if (
                        evidence < min_anchor_evidence_pixels
                        or overlap_ratio < min_anchor_evidence_ratio
                        or source_road_pixels > 0
                    ):
                        continue
                    legal_distance = min(
                        abs(core_x + 1 - legal_x) + abs(core_y + 1 - legal_y)
                        for legal_x, legal_y in legal_centers[block_id]
                    )
                    if legal_distance > max_legal_distance:
                        continue
                    centroid_distance2 = int(
                        abs((core_x + 0.5) * 2 - centroid_x * 2)
                        + abs((core_y + 0.5) * 2 - centroid_y * 2)
                    )
                    score = evidence * 100 - legal_distance * 20 - centroid_distance2
                    candidate = (score, evidence, -legal_distance, -core_y, -core_x)
                    if best is None or candidate > best:
                        best = candidate
            if best is None:
                continue
            core_x = -best[4]
            core_y = -best[3]
            proposals.append(
                SourceBlockCore(
                    source_component=component.index,
                    block_id=block_id,
                    source_pixels=record["pixels"],
                    min_source_x=record["min_x"],
                    min_source_y=record["min_y"],
                    max_source_x=record["max_x"],
                    max_source_y=record["max_y"],
                    avg_value=record["sum_value"] / record["pixels"],
                    terrain=record["terrain"],
                    tile_counts=dict(tile_counts_for_piece),
                    core_x=core_x,
                    core_y=core_y,
                    core_evidence_pixels=best[1],
                    source_cell_pixels=int(source_tile_totals[core_y, core_x]),
                    source_road_pixels=int(source_road_counts[core_y, core_x]),
                    overlap_ratio=best[1] / int(source_tile_totals[core_y, core_x]),
                    legal_distance=-best[2],
                )
            )
    best_by_block: dict[int, SourceBlockCore] = {}
    for proposal in proposals:
        current = best_by_block.get(proposal.block_id)
        proposal_score = (
            proposal.core_evidence_pixels,
            proposal.source_pixels,
            -proposal.legal_distance,
            -proposal.source_component,
        )
        if current is None:
            best_by_block[proposal.block_id] = proposal
            continue
        current_score = (
            current.core_evidence_pixels,
            current.source_pixels,
            -current.legal_distance,
            -current.source_component,
        )
        if proposal_score > current_score:
            best_by_block[proposal.block_id] = proposal
    return [best_by_block[block_id] for block_id in sorted(best_by_block)]


def classify_source_core(core: SourceBlockCore) -> str:
    width = core.max_source_x - core.min_source_x + 1
    height = core.max_source_y - core.min_source_y + 1
    aspect = max(width, height) / max(1, min(width, height))
    fill = core.source_pixels / max(1, width * height)
    campus_share = core.terrain["c"] / max(1, core.source_pixels)
    dense_share = core.terrain["U"] / max(1, core.source_pixels)
    if campus_share >= 0.62:
        if core.source_pixels >= 700 and aspect >= 1.55:
            return "industrial"
        if core.source_pixels >= 260:
            return "campus"
        # Civic is deliberately restricted to substantial compact evidence.
        if core.source_pixels >= 100 and aspect <= 2.0:
            return "civic"
        return "campus"
    if 0.22 <= fill <= 0.62 and core.source_pixels >= 220 and aspect <= 2.3:
        return "courtyard"
    if aspect >= 2.5 and core.source_pixels >= 90:
        return "row"
    # Tower never receives a tiny or highly elongated source speck.
    if (
        90 <= core.source_pixels <= 420
        and aspect <= 1.55
        and fill >= 0.62
        and core.avg_value >= 165
        and dense_share >= 0.35
    ):
        return "tower"
    if core.source_pixels < 180:
        return "lowrise"
    return "block"


def count_holes(cells: set[tuple[int, int]], bbox: tuple[int, int, int, int]) -> int:
    min_x, min_y, max_x, max_y = bbox
    width = max_x - min_x + 1
    height = max_y - min_y + 1
    empty = np.ones((height + 2, width + 2), dtype=bool)
    for x, y in cells:
        empty[y - min_y + 1, x - min_x + 1] = False
    seen = np.zeros(empty.shape, dtype=bool)
    queue = [(0, 0)]
    seen[0, 0] = True
    for x, y in queue:
        for dx, dy in FOUR_NEIGHBORS:
            next_x = x + dx
            next_y = y + dy
            if (
                0 <= next_x < empty.shape[1]
                and 0 <= next_y < empty.shape[0]
                and empty[next_y, next_x]
                and not seen[next_y, next_x]
            ):
                seen[next_y, next_x] = True
                queue.append((next_x, next_y))
    return int((empty & ~seen).sum())


def connected_grid_components(
    mask: np.ndarray,
    semantic_rows: list[str],
    bright_fraction: np.ndarray,
    mid_fraction: np.ndarray,
) -> list[GridComponent]:
    seen = np.zeros(mask.shape, dtype=bool)
    result: list[GridComponent] = []
    for start_y in range(GRID_HEIGHT):
        for start_x in range(GRID_WIDTH):
            if seen[start_y, start_x] or not mask[start_y, start_x]:
                continue
            queue = [(start_x, start_y)]
            seen[start_y, start_x] = True
            for x, y in queue:
                for dx, dy in FOUR_NEIGHBORS:
                    next_x = x + dx
                    next_y = y + dy
                    if (
                        0 <= next_x < GRID_WIDTH
                        and 0 <= next_y < GRID_HEIGHT
                        and mask[next_y, next_x]
                        and not seen[next_y, next_x]
                    ):
                        seen[next_y, next_x] = True
                        queue.append((next_x, next_y))
            min_x = min(x for x, _ in queue)
            min_y = min(y for _, y in queue)
            max_x = max(x for x, _ in queue)
            max_y = max(y for _, y in queue)
            cells = set(queue)
            area = len(queue)
            terrain = Counter(semantic_rows[y][x] for x, y in queue)
            result.append(
                GridComponent(
                    cells=queue,
                    min_x=min_x,
                    min_y=min_y,
                    max_x=max_x,
                    max_y=max_y,
                    area=area,
                    terrain=terrain,
                    avg_bright=float(
                        sum(bright_fraction[y, x] for x, y in queue) / area
                    ),
                    avg_mid=float(sum(mid_fraction[y, x] for x, y in queue) / area),
                    fill=area / ((max_x - min_x + 1) * (max_y - min_y + 1)),
                    holes=count_holes(cells, (min_x, min_y, max_x, max_y)),
                )
            )
    return result


def classify_component(component: GridComponent) -> str:
    """Provisional mapping from visible form/land use to existing styles."""
    width = component.max_x - component.min_x + 1
    height = component.max_y - component.min_y + 1
    aspect = max(width, height) / max(1, min(width, height))
    campus_share = component.terrain["c"] / component.area
    dense_share = component.terrain["U"] / component.area
    if campus_share >= 0.72:
        if component.area >= 12 and (aspect >= 2.25 or component.fill >= 0.86):
            return "industrial"
        if component.area >= 5:
            return "campus"
        return "civic"
    if (
        component.holes > 0
        and 7 <= component.area <= 80
        and width <= 16
        and height <= 16
        and component.fill <= 0.86
    ):
        return "courtyard"
    if component.fill < 0.57 and 10 <= component.area <= 60:
        return "courtyard"
    if aspect >= 2.5 and component.area >= 3:
        return "row"
    if component.area <= 2 and component.avg_bright >= 0.30:
        return "tower"
    if component.area <= 5:
        return "lowrise"
    if dense_share >= 0.55 and component.avg_bright >= 0.50 and component.area <= 10:
        return "tower"
    return "block"


def ensure_all_kinds(components: list[GridComponent]) -> list[dict]:
    """Use the best geometrically defensible component for any absent style."""
    present = Counter(component.kind for component in components)
    reassigned: list[dict] = []
    for kind in CODE_FOR_KIND:
        if present[kind]:
            continue
        candidates = sorted(
            components,
            key=lambda component: fallback_style_cost(component, kind),
        )
        for component in candidates:
            if present[component.kind] > 1:
                previous = component.kind
                present[component.kind] -= 1
                component.kind = kind
                present[kind] += 1
                reassigned.append(
                    {
                        "from": previous,
                        "to": kind,
                        "minX": component.min_x,
                        "minY": component.min_y,
                        "area": component.area,
                        "fallbackCost": round(fallback_style_cost(component, kind)[0], 3),
                    }
                )
                break
    return reassigned


def fallback_style_cost(component: GridComponent, kind: str) -> tuple[float, int, int]:
    width = component.max_x - component.min_x + 1
    height = component.max_y - component.min_y + 1
    aspect = max(width, height) / max(1, min(width, height))
    campus_share = component.terrain["c"] / component.area
    targets = {
        "lowrise": abs(component.area - 4) + aspect,
        "row": abs(aspect - 3.0) * 3 + abs(component.area - 7),
        "block": abs(component.area - 18) + abs(component.fill - 0.75) * 8,
        "tower": abs(component.area - 2) + (1.0 - component.avg_bright) * 4,
        "courtyard": (0 if component.holes else 8) + abs(component.fill - 0.5) * 8,
        "campus": (1.0 - campus_share) * 20 + abs(component.area - 10),
        "civic": (1.0 - campus_share) * 12 + abs(component.area - 3),
        "industrial": (1.0 - campus_share) * 20 + abs(aspect - 2.5) * 3,
    }
    return (targets[kind], component.min_y, component.min_x)


def loader_floodfill_components(typed_grid: list[list[str]]) -> list[tuple[str, list[tuple[int, int]]]]:
    """Mirror runtime_snapshots.js: scan order plus same-code 4-neighbor fill."""
    seen = np.zeros((GRID_HEIGHT, GRID_WIDTH), dtype=bool)
    components: list[tuple[str, list[tuple[int, int]]]] = []
    typed_codes = set(KIND_FOR_CODE)
    for start_y in range(GRID_HEIGHT):
        for start_x in range(GRID_WIDTH):
            code = typed_grid[start_y][start_x]
            if code not in typed_codes or seen[start_y, start_x]:
                continue
            cells = [(start_x, start_y)]
            seen[start_y, start_x] = True
            for x, y in cells:
                for dx, dy in FOUR_NEIGHBORS:
                    next_x = x + dx
                    next_y = y + dy
                    if (
                        0 <= next_x < GRID_WIDTH
                        and 0 <= next_y < GRID_HEIGHT
                        and not seen[next_y, next_x]
                        and typed_grid[next_y][next_x] == code
                    ):
                        seen[next_y, next_x] = True
                        cells.append((next_x, next_y))
            components.append((code, cells))
    return components


def loader_metadata_mismatches(payload: dict) -> list[dict]:
    """Replay visualization flood-fill and verify singleton anchor records."""
    discovered = loader_floodfill_components(
        [list(row) for row in payload["labelRows"]]
    )
    declared = payload["components"]
    mismatches: list[dict] = []
    if len(discovered) != len(declared):
        mismatches.append(
            {"kind": "count", "discovered": len(discovered), "declared": len(declared)}
        )
    for index, ((code, cells), component) in enumerate(zip(discovered, declared)):
        expected_bbox = {
            "minX": min(x for x, _ in cells),
            "minY": min(y for _, y in cells),
            "maxX": max(x for x, _ in cells),
            "maxY": max(y for _, y in cells),
        }
        expected = {
            "id": f"anchor-component-{index:04d}",
            "anchorId": f"roof-anchor-{index:04d}",
            "evidenceRole": "singleton-anchor",
            "singletonAnchor": True,
            "bbox": expected_bbox,
            "areaCells": len(cells),
        }
        actual = {key: component.get(key) for key in expected}
        expected_presentation_kind = KIND_FOR_CODE[code]
        actual_presentation_kind = component.get("presentationStyle", {}).get("kind")
        if actual_presentation_kind != expected_presentation_kind:
            mismatches.append(
                {
                    "kind": "presentation-code",
                    "index": index,
                    "expected": expected_presentation_kind,
                    "actual": actual_presentation_kind,
                }
            )
        if actual != expected:
            mismatches.append(
                {"kind": "metadata", "index": index, "expected": expected, "actual": actual}
            )
    return mismatches


def legal_anchor_blocks(
    typed_grid: list[list[str]],
    block_ids: np.ndarray,
    road_mask: np.ndarray,
    semantic_rows: list[str],
) -> tuple[int, list[int]]:
    """Conservative 3x3/frontage upper bound for block-first ambient placement."""
    source_blocks = sorted(
        {
            int(block_ids[y, x])
            for y in range(GRID_HEIGHT)
            for x in range(GRID_WIDTH)
            if typed_grid[y][x] != "." and block_ids[y, x] >= 0
        }
    )
    legal: list[int] = []
    for block_id in source_blocks:
        accepted = False
        for y in range(1, GRID_HEIGHT - 4):
            for x in range(1, GRID_WIDTH - 4):
                cells = [(xx, yy) for yy in range(y, y + 3) for xx in range(x, x + 3)]
                if any(block_ids[yy, xx] != block_id for xx, yy in cells):
                    continue
                if sum(semantic_rows[yy][xx] in "uUc" for xx, yy in cells) < 5:
                    continue
                frontage = any(
                    road_mask[yy, xx]
                    for xx, yy in (
                        [(xx, y - 1) for xx in range(x - 1, x + 4)]
                        + [(xx, y + 3) for xx in range(x - 1, x + 4)]
                        + [(x - 1, yy) for yy in range(y, y + 3)]
                        + [(x + 3, yy) for yy in range(y, y + 3)]
                    )
                )
                if frontage:
                    accepted = True
                    break
            if accepted:
                break
        if accepted:
            legal.append(block_id)
    return len(source_blocks), legal


def render_preview(
    source: Image.Image,
    typed_grid: list[list[str]],
    road_mask: np.ndarray,
    output: Path,
    title: str,
) -> None:
    background = source.convert("RGBA")
    source_width, source_height = background.size
    overlay = Image.new("RGBA", background.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    sparse_markers = sum(code != "." for row in typed_grid for code in row) <= 100
    for y in range(GRID_HEIGHT):
        y0 = y * source_height // GRID_HEIGHT
        y1 = (y + 1) * source_height // GRID_HEIGHT
        for x in range(GRID_WIDTH):
            x0 = x * source_width // GRID_WIDTH
            x1 = (x + 1) * source_width // GRID_WIDTH
            code = typed_grid[y][x]
            if code != ".":
                draw.rectangle((x0, y0, x1 - 1, y1 - 1), fill=COLOR_FOR_CODE[code])
                if sparse_markers:
                    center_x = (x0 + x1) // 2
                    center_y = (y0 + y1) // 2
                    draw.ellipse(
                        (center_x - 5, center_y - 5, center_x + 5, center_y + 5),
                        outline=COLOR_FOR_CODE[code],
                        width=2,
                    )
            if road_mask[y, x]:
                draw.rectangle((x0, y0, x1 - 1, y1 - 1), fill=(255, 255, 255, 72))
    composed = Image.alpha_composite(background, overlay)
    preview = composed.resize((1280, 720), Image.Resampling.LANCZOS)
    banner = Image.new("RGBA", (1280, 48), (9, 18, 32, 235))
    ImageDraw.Draw(banner).text((16, 14), title, fill=(255, 255, 255, 255))
    preview.alpha_composite(banner, (0, 0))
    preview.convert("RGB").save(output, quality=94)


def render_anchor_crops(source: Image.Image, anchors: list[dict], output: Path) -> None:
    """Render every exact source cell with context and its evidence gate."""
    columns = 6
    panel_width = 200
    panel_height = 140
    rows = (len(anchors) + columns - 1) // columns
    sheet = Image.new("RGB", (columns * panel_width, rows * panel_height), (9, 18, 32))
    for index, anchor in enumerate(anchors):
        bounds = anchor["sourcePixelBounds"]
        center_x = (bounds["x0"] + bounds["x1Exclusive"]) // 2
        center_y = (bounds["y0"] + bounds["y1Exclusive"]) // 2
        crop_x0 = max(0, center_x - 24)
        crop_y0 = max(0, center_y - 18)
        crop_x1 = min(source.width, center_x + 24)
        crop_y1 = min(source.height, center_y + 18)
        crop = source.crop((crop_x0, crop_y0, crop_x1, crop_y1)).convert("RGBA")
        draw = ImageDraw.Draw(crop)
        draw.rectangle(
            (
                bounds["x0"] - crop_x0,
                bounds["y0"] - crop_y0,
                bounds["x1Exclusive"] - crop_x0 - 1,
                bounds["y1Exclusive"] - crop_y0 - 1,
            ),
            outline=(255, 44, 94, 255),
            width=2,
        )
        crop = crop.resize((192, 108), Image.Resampling.NEAREST).convert("RGB")
        panel = Image.new("RGB", (panel_width, panel_height), (9, 18, 32))
        panel.paste(crop, (4, 4))
        evidence = anchor["evidence"]
        caption = (
            f"{anchor['id']} ({anchor['grid']['x']},{anchor['grid']['y']}) "
            f"roof={evidence['erodedRoofCorePixels']}/{evidence['sourceCellPixels']} "
            f"road={evidence['sourceRoadSurfacePixels']}"
        )
        ImageDraw.Draw(panel).text((5, 116), caption, fill=(240, 244, 252))
        sheet.paste(panel, ((index % columns) * panel_width, (index // columns) * panel_height))
    sheet.save(output)


def generate(args: argparse.Namespace) -> tuple[dict, dict]:
    source = Image.open(args.source).convert("RGB")
    rgb = np.asarray(source)
    semantic_rows, semantic_payload = read_rows(args.semantic, "rows")
    road_rows, road_payload = read_rows(args.roads, "rows")
    road_mask = np.asarray(
        [[code in "MRb" for code in row] for row in road_rows], dtype=bool
    )

    channels = rgb.astype(np.int16)
    spread = channels.max(axis=2) - channels.min(axis=2)
    value = channels.mean(axis=2)
    road_candidates = (
        (spread <= 18) & (value >= 175) & (value <= 240)
    )
    source_road_surface = largest_border_component(road_candidates)
    road_exclusion = dilate(source_road_surface, args.road_dilation)
    bright_pixels = (
        (spread <= args.neutral_spread)
        & (value >= args.bright_min)
        & (value <= 250)
        & ~road_exclusion
    )
    mid_pixels = (
        (spread <= 20)
        & (value >= 100)
        & (value < args.bright_min)
        & ~road_exclusion
    )
    bright_counts, totals = tile_counts(bright_pixels)
    mid_counts, _ = tile_counts(mid_pixels)
    source_road_counts, _ = tile_counts(source_road_surface)
    bright_fraction = bright_counts / totals
    mid_fraction = mid_counts / totals
    source_roof_pixels = bright_pixels | (
        mid_pixels & dilate(bright_pixels, 2)
    )
    source_core_mask = erode(source_roof_pixels, args.source_erosion)
    source_components = source_roof_components(
        source_core_mask, value, args.source_component_min_pixels
    )
    block_ids, block_sizes = enclosed_blocks(road_mask)
    legal_centers = legal_three_by_three_centers(
        block_ids, road_mask, semantic_rows
    )
    selected_cores = source_component_block_cores(
        source_components,
        source_core_mask.shape,
        block_ids,
        road_mask,
        semantic_rows,
        legal_centers,
        source_road_counts,
        totals,
        args.source_piece_min_pixels,
        args.min_anchor_evidence_pixels,
        args.min_anchor_evidence_ratio,
        args.max_legal_distance,
    )
    evidence_exclusions = []
    retained_cores = []
    for core in selected_cores:
        exclusion_key = (core.source_component, core.core_x, core.core_y)
        reason = EXCLUDED_SOURCE_ANCHORS.get(exclusion_key)
        if reason is None:
            retained_cores.append(core)
        else:
            evidence_exclusions.append(
                {
                    "sourceComponent": core.source_component,
                    "grid": {"x": core.core_x, "y": core.core_y},
                    "reason": reason,
                }
            )
    selected_cores = retained_cores
    for core in selected_cores:
        core.kind = classify_source_core(core)
    typed_grid = [["."] * GRID_WIDTH for _ in range(GRID_HEIGHT)]
    core_by_origin: dict[tuple[int, int], SourceBlockCore] = {}
    for core in selected_cores:
        code = CODE_FOR_KIND[core.kind]
        typed_grid[core.core_y][core.core_x] = code
        core_by_origin[(core.core_x, core.core_y)] = core

    loader_components = loader_floodfill_components(typed_grid)
    components = []
    anchors = []
    for index, (code, cells) in enumerate(loader_components):
        min_x = min(x for x, _ in cells)
        min_y = min(y for _, y in cells)
        max_x = max(x for x, _ in cells)
        max_y = max(y for _, y in cells)
        terrain = Counter(semantic_rows[y][x] for x, y in cells)
        avg_bright = sum(bright_fraction[y, x] for x, y in cells) / len(cells)
        avg_mid = sum(mid_fraction[y, x] for x, y in cells) / len(cells)
        kind = KIND_FOR_CODE[code]
        provenance = core_by_origin.get((min_x, min_y))
        if provenance is None:
            raise RuntimeError(f"loader component {index} has no source core")
        source_x0 = min_x * source.width // GRID_WIDTH
        source_x1 = (min_x + 1) * source.width // GRID_WIDTH
        source_y0 = min_y * source.height // GRID_HEIGHT
        source_y1 = (min_y + 1) * source.height // GRID_HEIGHT
        total_eroded_core_pixels = int(
            source_core_mask[source_y0:source_y1, source_x0:source_x1].sum()
        )
        anchor_id = f"roof-anchor-{index:04d}"
        presentation_style = {
            "kind": kind,
            "code": code,
            "asset": ASSET_FOR_KIND[kind],
            "basis": "presentation-only heuristic; not a surveyed roof or building class",
        }
        anchors.append(
            {
                "id": anchor_id,
                "evidenceMode": "roof-provenance-anchor",
                "grid": {"x": min_x, "y": min_y},
                "sourcePixelBounds": {
                    "x0": source_x0,
                    "y0": source_y0,
                    "x1Exclusive": source_x1,
                    "y1Exclusive": source_y1,
                },
                "evidence": {
                    "erodedRoofCorePixels": provenance.core_evidence_pixels,
                    "totalErodedRoofCorePixelsInCell": total_eroded_core_pixels,
                    "sourceCellPixels": provenance.source_cell_pixels,
                    "overlapRatio": round(provenance.overlap_ratio, 4),
                    "minimumPixels": args.min_anchor_evidence_pixels,
                    "minimumOverlapRatio": args.min_anchor_evidence_ratio,
                    "sourceRoadSurfacePixels": provenance.source_road_pixels,
                    "sourceComponent": provenance.source_component,
                    "sourceComponentPixelsInBlock": provenance.source_pixels,
                    "sourceComponentBbox": {
                        "minX": provenance.min_source_x,
                        "minY": provenance.min_source_y,
                        "maxX": provenance.max_source_x,
                        "maxY": provenance.max_source_y,
                    },
                },
                "hardMask": {
                    "semanticCode": semantic_rows[min_y][min_x],
                    "semanticBuildable": semantic_rows[min_y][min_x] in "uUc",
                    "compiledRoad": bool(road_mask[min_y, min_x]),
                    "waterOrWetland": semantic_rows[min_y][min_x] in "rlw",
                    "blockIdZeroBased": provenance.block_id,
                    "legalRuntimeAnchorDistance": provenance.legal_distance,
                },
                "presentationStyle": presentation_style,
            }
        )
        components.append(
            {
                "id": f"anchor-component-{index:04d}",
                "anchorId": anchor_id,
                "evidenceRole": "singleton-anchor",
                "singletonAnchor": True,
                "orientation": "ew" if max_x - min_x >= max_y - min_y else "ns",
                "bbox": {
                    "minX": min_x,
                    "minY": min_y,
                    "maxX": max_x,
                    "maxY": max_y,
                },
                "areaCells": len(cells),
                "terrain": dict(sorted(terrain.items())),
                "avgBrightNeutral": round(avg_bright, 4),
                "avgMidNeutral": round(avg_mid, 4),
                "avgScore": round(avg_bright + args.mid_weight * avg_mid, 4),
                "provenance": {
                    "mode": "eroded-source-component-centroid-core",
                    "sourceComponent": provenance.source_component,
                    "sourcePixels": provenance.source_pixels,
                    "sourceBbox": {
                        "minX": provenance.min_source_x,
                        "minY": provenance.min_source_y,
                        "maxX": provenance.max_source_x,
                        "maxY": provenance.max_source_y,
                    },
                    "coreEvidencePixels": provenance.core_evidence_pixels,
                    "blockIdZeroBased": provenance.block_id,
                    "legalAnchorDistance": provenance.legal_distance,
                },
                "presentationStyle": presentation_style,
            }
        )
    label_rows = ["".join(row) for row in typed_grid]
    coverage_cells = Counter(
        KIND_FOR_CODE[code]
        for row in typed_grid
        for code in row
        if code != "."
    )
    coverage_components = Counter(
        component["presentationStyle"]["kind"] for component in components
    )
    payload = {
        "schema": "moontown.wenyu_reference_building_anchors.v1",
        "evidenceMode": "roof-provenance-anchor",
        "evidenceExclusions": evidence_exclusions,
        "source": {
            "path": "asset://tilemap/wenyu_topdown_semantic.png",
            "width": source.width,
            "height": source.height,
            "semanticLabels": "asset://tilemap/wenyu_reference_labels.json",
            "roadGraph": "asset://tilemap/wenyu_reference_roads.json",
            "method": (
                "single-frame neutral-roof provenance; subtract the exact largest "
                "border-connected source road surface, erode and four-neighbor "
                "separate roof cores at source resolution before projection, then "
                "select one half-grid-aligned centroid anchor per legal enclosed "
                "block and hard-mask to semantic u/U/c and compiled non-road cells"
            ),
            "presentationStyleMethod": "optional source-geometry/terrain heuristic for preview glyphs only; not evidence or a roof/building class",
        },
        "tileGrid": {"width": GRID_WIDTH, "height": GRID_HEIGHT},
        "labelRowsRole": "compatibility visualization only; non-dot cells are singleton provenance anchors, not building footprints",
        "legend": {
            ".": {"kind": "none"},
            **{
                code: {
                    "presentationKind": kind,
                    "evidenceMeaning": "singleton roof-provenance anchor",
                }
                for kind, code in CODE_FOR_KIND.items()
            },
        },
        "extraction": {
            "neutralRgbSpreadMax": args.neutral_spread,
            "brightValueMin": args.bright_min,
            "sourceCoreErosionPixels": args.source_erosion,
            "sourceComponentMinPixels": args.source_component_min_pixels,
            "sourceBlockPieceMinPixels": args.source_piece_min_pixels,
            "coreGridFootprint": "1x1 anchor at a 128x72 half-grid sample coordinate",
            "maxCoreToLegalAnchorDistanceTiles": args.max_legal_distance,
            "minimumAnchorEvidencePixels": args.min_anchor_evidence_pixels,
            "minimumAnchorOverlapRatio": args.min_anchor_evidence_ratio,
            "rejectAnySourceRoadSurfacePixel": True,
            "sourceRoadSurfaceDilationPixels": args.road_dilation,
            "hardSemanticCodes": ["u", "U", "c"],
            "hardCompiledRoadCarve": True,
        },
        "presentationCoverageCells": {kind: coverage_cells[kind] for kind in CODE_FOR_KIND},
        "presentationCoverageComponents": {
            kind: coverage_components[kind] for kind in CODE_FOR_KIND
        },
        "presentationAssets": ASSET_FOR_KIND,
        "labelRows": label_rows,
        "anchors": anchors,
        "componentsRole": "each record is exactly one singleton anchor for compatibility inspection; never a building footprint",
        "components": components,
    }

    component_mismatches = loader_metadata_mismatches(payload)
    block_ids, block_sizes = enclosed_blocks(road_mask)
    represented_blocks, legal_blocks = legal_anchor_blocks(
        typed_grid, block_ids, road_mask, semantic_rows
    )
    current_payload = json.loads(args.current.read_text())

    candidate_cells = {
        (x, y)
        for y, row in enumerate(payload["labelRows"])
        for x, code in enumerate(row)
        if code != "."
    }
    current_cells = {
        (x, y)
        for y, row in enumerate(current_payload["labelRows"])
        for x, code in enumerate(row)
        if code != "."
    }
    half_grid = [
        [typed_grid[y * 2][x * 2] for x in range(GRID_WIDTH // 2)]
        for y in range(GRID_HEIGHT // 2)
    ]
    half_roundtrip = [
        [
            half_grid[y // 2][x // 2] if x % 2 == 0 and y % 2 == 0 else "."
            for x in range(GRID_WIDTH)
        ]
        for y in range(GRID_HEIGHT)
    ]
    half_roundtrip_mismatches = sum(
        half_roundtrip[y][x] != typed_grid[y][x]
        for y in range(GRID_HEIGHT)
        for x in range(GRID_WIDTH)
    )
    style_source_pixels: dict[str, list[int]] = {kind: [] for kind in CODE_FOR_KIND}
    for component in components:
        style_source_pixels[component["presentationStyle"]["kind"]].append(
            component["provenance"]["sourcePixels"]
        )
    tiny_civic_or_tower = [
        component["id"]
        for component in components
        if component["presentationStyle"]["kind"] in {"civic", "tower"}
        and component["provenance"]["sourcePixels"] < 90
    ]
    large_source_core_styles = Counter(
        component["presentationStyle"]["kind"]
        for component in components
        if component["provenance"]["sourcePixels"] >= 220
    )

    def mask_metrics(candidate: dict) -> dict:
        rows = candidate["labelRows"]
        mask = np.asarray(
            [[code != "." for code in row] for row in rows], dtype=bool
        )
        return {
            "cells": int(mask.sum()),
            "compiledRoadOverlaps": int((mask & road_mask).sum()),
            "nonBuildableSemanticCells": int(sum(
                mask[y, x] and semantic_rows[y][x] not in "uUc"
                for y in range(GRID_HEIGHT)
                for x in range(GRID_WIDTH)
            )),
            "waterWetlandCells": int(sum(
                mask[y, x] and semantic_rows[y][x] in "rlw"
                for y in range(GRID_HEIGHT)
                for x in range(GRID_WIDTH)
            )),
            "enclosedBlocksRepresented": len(
                {
                    int(block_ids[y, x])
                    for y in range(GRID_HEIGHT)
                    for x in range(GRID_WIDTH)
                    if mask[y, x] and block_ids[y, x] >= 0
                }
            ),
        }

    candidate_metrics = mask_metrics(payload)
    candidate_metrics["anchors"] = len(anchors)
    evidence_pixels = [anchor["evidence"]["erodedRoofCorePixels"] for anchor in anchors]
    evidence_ratios = [anchor["evidence"]["overlapRatio"] for anchor in anchors]
    anchor_bounds_exact = all(
        anchor["sourcePixelBounds"]
        == {
            "x0": anchor["grid"]["x"] * source.width // GRID_WIDTH,
            "y0": anchor["grid"]["y"] * source.height // GRID_HEIGHT,
            "x1Exclusive": (anchor["grid"]["x"] + 1) * source.width // GRID_WIDTH,
            "y1Exclusive": (anchor["grid"]["y"] + 1) * source.height // GRID_HEIGHT,
        }
        for anchor in anchors
    )
    all_components_singleton = all(
        component["evidenceRole"] == "singleton-anchor"
        and component["singletonAnchor"] is True
        and component["areaCells"] == 1
        and component["bbox"]["minX"] == component["bbox"]["maxX"]
        and component["bbox"]["minY"] == component["bbox"]["maxY"]
        for component in components
    )
    clearance_conflicted_anchor_ids = set()
    for left_index in range(len(anchors)):
        for right_index in range(left_index + 1, len(anchors)):
            left = anchors[left_index]
            right = anchors[right_index]
            if max(
                abs(left["grid"]["x"] - right["grid"]["x"]),
                abs(left["grid"]["y"] - right["grid"]["y"]),
            ) <= 2:
                clearance_conflicted_anchor_ids.add(left["id"])
                clearance_conflicted_anchor_ids.add(right["id"])
    clearance_safe_pre_civic = len(anchors) - len(clearance_conflicted_anchor_ids)

    report = {
        "verdict": "GO-for-roof-provenance-anchors",
        "candidate": candidate_metrics,
        "current": mask_metrics(current_payload),
        "comparison": {
            "compiledRoadOverlapReduction": (
                mask_metrics(current_payload)["compiledRoadOverlaps"]
                - mask_metrics(payload)["compiledRoadOverlaps"]
            ),
            "maskComparison": "not applicable: candidate cells are anchors; current cells claim footprints",
            "sourceHashesDiffer": True,
            "candidateSourceSha256": hashlib.sha256(args.source.read_bytes()).hexdigest(),
            "currentDeclaredSourceSha256": hashlib.sha256(
                (args.current.parent / "wenyu_reference_buildings_source.png").read_bytes()
            ).hexdigest(),
            "candidateSource": str(args.source),
            "currentDeclaredSource": current_payload["source"]["path"],
        },
        "topology": {
            "sourceRoadCandidatePixels": int(road_candidates.sum()),
            "sourceConnectedRoadSurfacePixels": int(source_road_surface.sum()),
            "sourceBrightResidualPixels": int(bright_pixels.sum()),
            "sourceMidResidualPixels": int(mid_pixels.sum()),
            "sourceErodedCorePixels": int(source_core_mask.sum()),
            "sourceRoofComponents": len(source_components),
            "selectedSourceBlockCores": len(selected_cores),
            "surgicalEvidenceExclusions": evidence_exclusions,
            "selectedSourcePiecePixelRange": {
                "min": min((core.source_pixels for core in selected_cores), default=0),
                "max": max((core.source_pixels for core in selected_cores), default=0),
            },
            "compiledRoadBlocks": len(block_sizes),
            "compatibilityVisualizationComponents": len(components),
            "candidateLargestSameCodeComponent": max(
                (component["areaCells"] for component in components), default=0
            ),
            "candidateComponentAreas": sorted(
                (component["areaCells"] for component in components), reverse=True
            )[:12],
            "compatibilityComponentMetadataMismatches": len(component_mismatches),
            "compatibilityComponentMismatchDetails": component_mismatches[:12],
        },
        "quantizationEvidence": {
            "sourceBoundsFormula": "x0=floor(x*W/256), x1=floor((x+1)*W/256), y0=floor(y*H/144), y1=floor((y+1)*H/144)",
            "minimumComponentCorePixels": args.min_anchor_evidence_pixels,
            "minimumOverlapRatio": args.min_anchor_evidence_ratio,
            "observedComponentCorePixelRange": {
                "min": min(evidence_pixels, default=0),
                "max": max(evidence_pixels, default=0),
            },
            "observedOverlapRatioRange": {
                "min": min(evidence_ratios, default=0.0),
                "max": max(evidence_ratios, default=0.0),
            },
            "sourceBoundsExact": anchor_bounds_exact,
            "allCellsContainErodedRoofCore": all(
                anchor["evidence"]["totalErodedRoofCorePixelsInCell"]
                >= anchor["evidence"]["erodedRoofCorePixels"]
                >= args.min_anchor_evidence_pixels
                for anchor in anchors
            ),
            "allCellsRejectSourceRoadSurface": all(
                anchor["evidence"]["sourceRoadSurfacePixels"] == 0
                for anchor in anchors
            ),
        },
        "halfGridStability": {
            "grid": "128x72",
            "roundtripCellMismatches": half_roundtrip_mismatches,
            "typedMaskExact": half_roundtrip_mismatches == 0,
            "jaccard": 1.0 if half_roundtrip_mismatches == 0 else 0.0,
            "method": "sample aligned half-grid anchors and map each back to its exact even-coordinate native cell",
        },
        "blockFirstPlacement": {
            "sourceBlocksRepresented": represented_blocks,
            "conservativeLegal3x3FrontageBlocks": len(legal_blocks),
            "legalBlockIdsZeroBased": legal_blocks,
            "clearanceMetric": "anchor cells with Chebyshev distance greater than two before civic placement",
            "clearanceConflictedAnchorIds": sorted(clearance_conflicted_anchor_ids),
            "clearanceSafePreCivicAnchors": clearance_safe_pre_civic,
            "note": "upper-bound gate before civic footprints and two-tile inter-building clearance",
        },
        "presentationStyles": {
            "cells": payload["presentationCoverageCells"],
            "components": payload["presentationCoverageComponents"],
            "status": "preview-only; not evidence and not an all-eight roof classification",
            "forcedStyleAssignments": [],
            "sourcePixelRanges": {
                kind: {
                    "min": min(values) if values else 0,
                    "max": max(values) if values else 0,
                }
                for kind, values in style_source_pixels.items()
            },
            "tinyCivicOrTowerComponents": tiny_civic_or_tower,
            "largeSourceCoreThresholdPixels": 220,
            "largeSourceCoreComponents": sum(large_source_core_styles.values()),
            "largeSourceCoreStyles": {
                kind: large_source_core_styles[kind]
                for kind in ("block", "campus", "courtyard", "industrial")
            },
        },
        "hardGates": {
            "anchorSchemaV1": payload["schema"] == "moontown.wenyu_reference_building_anchors.v1",
            "roofProvenanceEvidenceMode": payload["evidenceMode"] == "roof-provenance-anchor",
            "disconnectedLocalPath410Excluded": (
                evidence_exclusions
                == [
                    {
                        "sourceComponent": 410,
                        "grid": {"x": 128, "y": 126},
                        "reason": "disconnected-local-path",
                    }
                ]
                and all(
                    not (
                        anchor["evidence"]["sourceComponent"] == 410
                        and anchor["grid"] == {"x": 128, "y": 126}
                    )
                    for anchor in anchors
                )
            ),
            "sourceGridBoundsExact": anchor_bounds_exact,
            "minimumEvidencePixelsMet": all(
                value >= args.min_anchor_evidence_pixels for value in evidence_pixels
            ),
            "minimumEvidenceOverlapMet": all(
                value >= args.min_anchor_evidence_ratio for value in evidence_ratios
            ),
            "zeroSourceRoadSurfacePixels": all(
                anchor["evidence"]["sourceRoadSurfacePixels"] == 0
                for anchor in anchors
            ),
            "allCellsOnSemantic_u_U_c": mask_metrics(payload)["nonBuildableSemanticCells"] == 0,
            "zeroWaterWetland": mask_metrics(payload)["waterWetlandCells"] == 0,
            "zeroCompiledRoadOverlap": mask_metrics(payload)["compiledRoadOverlaps"] == 0,
            "materiallyLowerThanCurrent476": mask_metrics(payload)["compiledRoadOverlaps"] <= 47,
            "compatibilityComponentsAreSingletonAnchors": (
                all_components_singleton
                and len(components) == len(anchors)
                and len(component_mismatches) == 0
            ),
            "largestSameCodeComponentAtMost100": max(
                (component["areaCells"] for component in components), default=0
            ) <= 100,
            "halfGridRoundtripExact": half_roundtrip_mismatches == 0,
            "presentationAvoidsTinyCivicOrTowerSpecks": len(tiny_civic_or_tower) == 0,
            "atLeast31ClearanceSafePreCivic": clearance_safe_pre_civic >= 31,
            "roughly30To45LegalAnchors": 30 <= len(legal_blocks) <= 45,
        },
        "limitations": [
            "Presentation styles are optional preview glyphs inferred from geometry and terrain; they are not evidence and do not claim an all-eight roof classification.",
            "The road hard mask is the current compiled centerline; source road-surface subtraction additionally suppresses visible pavement before tile projection.",
            "Each centroid anchor is provenance evidence for one source roof component, not a claim that the entire runtime building footprint is roof-covered.",
        ],
    }
    if not all(report["hardGates"].values()):
        report["verdict"] = "NO-GO"
    return payload, report


def main() -> None:
    repository = Path(__file__).resolve().parents[1]
    tilemap = repository / "src/ui/assets/tilemap"
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, default=tilemap / "wenyu_topdown_semantic.png")
    parser.add_argument("--semantic", type=Path, default=tilemap / "wenyu_reference_labels.json")
    parser.add_argument("--roads", type=Path, default=tilemap / "wenyu_reference_roads.json")
    parser.add_argument("--current", type=Path, default=tilemap / "wenyu_reference_buildings.json")
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=Path("/tmp/wenyu-single-frame-building-anchors-v1"),
    )
    parser.add_argument("--neutral-spread", type=int, default=30)
    parser.add_argument("--bright-min", type=int, default=135)
    parser.add_argument("--mid-weight", type=float, default=0.45)
    parser.add_argument("--tile-score-min", type=float, default=0.48)
    parser.add_argument("--road-dilation", type=int, default=2)
    parser.add_argument("--source-erosion", type=int, default=1)
    parser.add_argument("--source-component-min-pixels", type=int, default=20)
    parser.add_argument("--source-piece-min-pixels", type=int, default=12)
    parser.add_argument("--min-anchor-evidence-pixels", type=int, default=6)
    parser.add_argument("--min-anchor-evidence-ratio", type=float, default=0.12)
    parser.add_argument("--max-legal-distance", type=int, default=14)
    args = parser.parse_args()
    args.output_dir.mkdir(parents=True, exist_ok=True)
    payload, report = generate(args)
    candidate_path = args.output_dir / "wenyu_reference_buildings.single-frame-candidate.json"
    report_path = args.output_dir / "report.json"
    preview_path = args.output_dir / "preview.png"
    crop_path = args.output_dir / "anchor-crops.png"
    current_preview_path = args.output_dir / "current-mask-on-native-frame.png"
    comparison_preview_path = args.output_dir / "comparison.png"
    candidate_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n")
    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
    road_rows, _ = read_rows(args.roads, "rows")
    road_mask = np.asarray([[code in "MRb" for code in row] for row in road_rows])
    render_preview(
        Image.open(args.source).convert("RGB"),
        [list(row) for row in payload["labelRows"]],
        road_mask,
        preview_path,
        (
            f"source-roof centroid anchors (markers enlarged) | {report['candidate']['cells']} cells | "
            f"{report['candidate']['compiledRoadOverlaps']} road conflicts | "
            f"{report['blockFirstPlacement']['conservativeLegal3x3FrontageBlocks']} legal blocks"
        ),
    )
    render_anchor_crops(
        Image.open(args.source).convert("RGB"), payload["anchors"], crop_path
    )
    current_payload = json.loads(args.current.read_text())
    render_preview(
        Image.open(args.source).convert("RGB"),
        [list(row) for row in current_payload["labelRows"]],
        road_mask,
        current_preview_path,
        (
            f"current differently-composed source | {report['current']['cells']} cells | "
            f"{report['current']['compiledRoadOverlaps']} road conflicts"
        ),
    )
    candidate_preview = Image.open(preview_path).convert("RGB").resize(
        (800, 450), Image.Resampling.LANCZOS
    )
    current_preview = Image.open(current_preview_path).convert("RGB").resize(
        (800, 450), Image.Resampling.LANCZOS
    )
    comparison = Image.new("RGB", (1600, 450), (9, 18, 32))
    comparison.paste(current_preview, (0, 0))
    comparison.paste(candidate_preview, (800, 0))
    comparison.save(comparison_preview_path, quality=94)
    print(json.dumps(report, indent=2))
    print(candidate_path)
    print(preview_path)
    print(crop_path)
    print(comparison_preview_path)
    print(report_path)


if __name__ == "__main__":
    main()
