#!/usr/bin/env python3
"""Build MoonTown's display-only Energy Valley transport overlay from OSM.

This is an authoring tool, not a runtime dependency. It projects real road
geometry and Beijing Subway Line 17 into the existing 256 x 144 MoonTown
coordinate frame. The generated asset deliberately contains no terrain,
buildings, modules, parcels, or semantic road cells: those remain owned by the
original town generator and its pathfinding graph.

OpenStreetMap data is © OpenStreetMap contributors and is available under the
Open Database License: https://www.openstreetmap.org/copyright
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path
from typing import Any, Iterable


COLS = 256
ROWS = 144
WEST = 116.390
SOUTH = 40.090
EAST = 116.520
NORTH = 40.145
COORDINATE_SCALE = 1000

# The wide WGS84 crop is the authoritative source frame. MoonTown's restored
# art is deliberately stylized rather than georegistered, so one similarity
# fit maps the two real Line 17 stations onto their long-standing town anchors.
# The same transform is applied to every road, bridge, alignment, station, and
# entrance; relative OSM geometry is never warped independently by feature.
FIT_REAL = 0.8817364910
FIT_IMAGINARY = -0.1526026344
FIT_TRANSLATE_X = -7.698386279
FIT_TRANSLATE_Y = 38.405074113
FIT_SCALE = 0.8948445695
FIT_ROTATION_DEGREES = -9.818947
FIT_ANCHORS = [
    {
        "name": "未来科学城北站",
        "sourceMillis": [143529, 40259],
        "targetMillis": [125000, 52000],
    },
    {
        "name": "未来科学城站",
        "sourceMillis": [138320, 80186],
        "targetMillis": [126500, 88000],
    },
]

SOURCES = {
    "roads": "roads.json",
    "rail": "rail.json",
    "stations": "stations.json",
}

ROAD_CLASSES = {
    "motorway": "arterial",
    "motorway_link": "arterial",
    "trunk": "arterial",
    "trunk_link": "arterial",
    "primary": "arterial",
    "primary_link": "arterial",
    "secondary": "collector",
    "secondary_link": "collector",
    "tertiary": "collector",
    "tertiary_link": "collector",
    "residential": "local",
}

RAMP_HIGHWAYS = {
    "motorway_link",
    "trunk_link",
    "primary_link",
    "secondary_link",
    "tertiary_link",
}

CLASS_ORDER = {"arterial": 0, "collector": 1, "local": 2}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--source-dir",
        type=Path,
        required=True,
        help="Directory containing roads/rail/stations Overpass JSON",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=Path("src/ui/assets/tilemap/energy-valley-transport-v1.json"),
    )
    return parser.parse_args()


def load_extracts(source_dir: Path) -> dict[str, Any]:
    result: dict[str, Any] = {}
    for key, filename in SOURCES.items():
        with (source_dir / filename).open("r", encoding="utf-8") as handle:
            result[key] = json.load(handle)
    return result


def project_source(lon: float, lat: float) -> tuple[float, float]:
    return (
        (lon - WEST) / (EAST - WEST) * (COLS - 1),
        (NORTH - lat) / (NORTH - SOUTH) * (ROWS - 1),
    )


def fit_presentation(point: tuple[float, float]) -> tuple[float, float]:
    x, y = point
    return (
        FIT_REAL * x - FIT_IMAGINARY * y + FIT_TRANSLATE_X,
        FIT_IMAGINARY * x + FIT_REAL * y + FIT_TRANSLATE_Y,
    )


def project(lon: float, lat: float) -> tuple[float, float]:
    return fit_presentation(project_source(lon, lat))


def geometry_points(element: dict[str, Any]) -> list[tuple[float, float]]:
    return [project(point["lon"], point["lat"]) for point in element.get("geometry", [])]


def clip_segment(
    start: tuple[float, float], end: tuple[float, float]
) -> tuple[tuple[float, float], tuple[float, float]] | None:
    """Clip one segment to the town grid with the Liang-Barsky algorithm."""
    x0, y0 = start
    x1, y1 = end
    dx = x1 - x0
    dy = y1 - y0
    lower = 0.0
    upper = 1.0
    for p, q in (
        (-dx, x0),
        (dx, (COLS - 1) - x0),
        (-dy, y0),
        (dy, (ROWS - 1) - y0),
    ):
        if p == 0.0:
            if q < 0.0:
                return None
            continue
        ratio = q / p
        if p < 0.0:
            lower = max(lower, ratio)
        else:
            upper = min(upper, ratio)
        if lower > upper:
            return None
    return (
        (x0 + lower * dx, y0 + lower * dy),
        (x0 + upper * dx, y0 + upper * dy),
    )


def nearly_equal(a: tuple[float, float], b: tuple[float, float]) -> bool:
    return abs(a[0] - b[0]) < 1.0e-7 and abs(a[1] - b[1]) < 1.0e-7


def clipped_polyline_runs(
    points: list[tuple[float, float]],
) -> list[list[tuple[float, float]]]:
    runs: list[list[tuple[float, float]]] = []
    current: list[tuple[float, float]] = []
    for start, end in zip(points, points[1:]):
        clipped = clip_segment(start, end)
        if clipped is None:
            if len(current) >= 2:
                runs.append(current)
            current = []
            continue
        clipped_start, clipped_end = clipped
        if not current:
            current = [clipped_start, clipped_end]
        elif nearly_equal(current[-1], clipped_start):
            if not nearly_equal(current[-1], clipped_end):
                current.append(clipped_end)
        else:
            if len(current) >= 2:
                runs.append(current)
            current = [clipped_start, clipped_end]
    if len(current) >= 2:
        runs.append(current)
    return runs


def perpendicular_distance(
    point: tuple[float, float],
    start: tuple[float, float],
    end: tuple[float, float],
) -> float:
    if nearly_equal(start, end):
        return math.dist(point, start)
    dx = end[0] - start[0]
    dy = end[1] - start[1]
    numerator = abs(dy * point[0] - dx * point[1] + end[0] * start[1] - end[1] * start[0])
    return numerator / math.hypot(dx, dy)


def simplify_polyline(
    points: list[tuple[float, float]], tolerance: float = 0.16
) -> list[tuple[float, float]]:
    if len(points) <= 2:
        return points
    furthest_index = 0
    furthest_distance = 0.0
    for index, point in enumerate(points[1:-1], start=1):
        distance = perpendicular_distance(point, points[0], points[-1])
        if distance > furthest_distance:
            furthest_distance = distance
            furthest_index = index
    if furthest_distance <= tolerance:
        return [points[0], points[-1]]
    before = simplify_polyline(points[: furthest_index + 1], tolerance)
    after = simplify_polyline(points[furthest_index:], tolerance)
    return before[:-1] + after


def endpoint_key(point: tuple[float, float]) -> tuple[int, int]:
    return (round(point[0] * 1_000_000), round(point[1] * 1_000_000))


def merge_connected_runs(
    runs: Iterable[list[tuple[float, float]]],
) -> list[list[tuple[float, float]]]:
    """Join OSM way fragments only where their exact endpoints agree."""
    pending = [run for run in runs if len(run) >= 2]
    changed = True
    while changed:
        changed = False
        endpoint_to_index: dict[tuple[int, int], tuple[int, bool]] = {}
        for index, run in enumerate(pending):
            endpoint_to_index.setdefault(endpoint_key(run[0]), (index, True))
            endpoint_to_index.setdefault(endpoint_key(run[-1]), (index, False))
        for index, run in enumerate(pending):
            match = endpoint_to_index.get(endpoint_key(run[-1]))
            if match is None or match[0] == index:
                continue
            other_index, other_at_start = match
            other = pending[other_index]
            joined = run + (other[1:] if other_at_start else list(reversed(other[:-1])))
            first = min(index, other_index)
            second = max(index, other_index)
            pending[first] = joined
            pending.pop(second)
            changed = True
            break
    return pending


def road_record_bounds(points: list[tuple[float, float]]) -> list[int]:
    return [
        round(min(point[0] for point in points) * COORDINATE_SCALE),
        round(min(point[1] for point in points) * COORDINATE_SCALE),
        round(max(point[0] for point in points) * COORDINATE_SCALE),
        round(max(point[1] for point in points) * COORDINATE_SCALE),
    ]


def encode_points(points: list[tuple[float, float]]) -> list[list[int]]:
    encoded: list[list[int]] = []
    for x, y in points:
        point = [
            min(COLS * COORDINATE_SCALE - 1, max(0, round(x * COORDINATE_SCALE))),
            min(ROWS * COORDINATE_SCALE - 1, max(0, round(y * COORDINATE_SCALE))),
        ]
        if not encoded or encoded[-1] != point:
            encoded.append(point)
    return encoded


def make_display_transport(
    extract: dict[str, Any]
) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    grouped: dict[tuple[str, str, bool, str], list[list[tuple[float, float]]]] = {}
    group_ids: dict[tuple[str, str, bool, str], list[int]] = {}
    for element in extract["roads"].get("elements", []):
        tags = element.get("tags", {})
        highway = tags.get("highway", "")
        road_class = ROAD_CLASSES.get(highway)
        name = tags.get("name", "").strip()
        if road_class is None or tags.get("tunnel") in {"yes", "building_passage"}:
            continue
        # Anonymous residential/service access is the source of the previous
        # overview lace. Named residential streets remain available at deep
        # zoom; motorway/primary/secondary/tertiary links stay for continuity.
        if road_class == "local" and not name:
            continue
        detail = "ramp" if highway in RAMP_HIGHWAYS else "mainline"
        bridge = tags.get("bridge") not in {None, "", "no"}
        group_name = name if name else f"link-{element['id']}"
        key = (road_class, detail, bridge, group_name)
        for run in clipped_polyline_runs(geometry_points(element)):
            grouped.setdefault(key, []).append(run)
            group_ids.setdefault(key, []).append(element["id"])

    records: list[dict[str, Any]] = []
    bridge_records: list[dict[str, Any]] = []
    ordered = sorted(
        grouped,
        key=lambda key: (
            CLASS_ORDER[key[0]],
            key[1],
            key[2],
            key[3],
            min(group_ids[key]),
        ),
    )
    for key in ordered:
        road_class, detail, bridge, group_name = key
        display_name = "" if group_name.startswith("link-") else group_name
        for run in merge_connected_runs(grouped[key]):
            points = encode_points(simplify_polyline(run))
            if len(points) < 2:
                continue
            target = bridge_records if bridge else records
            target.append(
                {
                    "id": f"{'bridge' if bridge else 'road'}-{len(target):04d}",
                    "class": road_class,
                    "detail": detail,
                    "name": display_name,
                    "bounds": road_record_bounds(
                        [(point[0] / COORDINATE_SCALE, point[1] / COORDINATE_SCALE) for point in points]
                    ),
                    "points": points,
                }
            )
    return records, bridge_records


def make_metro(extract: dict[str, Any]) -> dict[str, Any]:
    named = [
        element
        for element in extract["rail"].get("elements", [])
        if element.get("tags", {}).get("name") == "北京地铁17号线北段"
        and element.get("tags", {}).get("railway") == "subway"
    ]
    if not named:
        raise RuntimeError("No Line 17 northern alignment")
    source = max(named, key=lambda element: len(element.get("geometry", [])))
    runs = clipped_polyline_runs(geometry_points(source))
    if not runs:
        raise RuntimeError("No in-bounds Line 17 alignment")
    points = max(runs, key=len)
    simplified = simplify_polyline(points, tolerance=0.12)
    if simplified[0][1] > simplified[-1][1]:
        simplified.reverse()

    station_nodes: dict[str, dict[str, Any]] = {}
    for element in extract["stations"].get("elements", []):
        tags = element.get("tags", {})
        name = tags.get("name", "")
        if name not in {"未来科学城北", "未来科学城"}:
            continue
        previous = station_nodes.get(name)
        if previous is None or tags.get("public_transport") == "station":
            station_nodes[name] = element

    station_specs = [
        ("未来科学城北", "未来科学城北站", "英才北一街"),
        ("未来科学城", "未来科学城站", "英才南一街"),
    ]
    projected_stations = {
        source_name: project(station_nodes[source_name]["lon"], station_nodes[source_name]["lat"])
        for source_name, _, _ in station_specs
    }
    for (source_name, display_name, _), anchor in zip(station_specs, FIT_ANCHORS):
        if display_name != anchor["name"]:
            raise RuntimeError("Line 17 calibration anchor order drifted")
        encoded_station = [
            round(projected_stations[source_name][0] * COORDINATE_SCALE),
            round(projected_stations[source_name][1] * COORDINATE_SCALE),
        ]
        if encoded_station != anchor["targetMillis"]:
            raise RuntimeError(
                f"Line 17 calibration drift for {display_name}: {encoded_station}"
            )
    entrances: dict[str, list[dict[str, Any]]] = {
        source_name: [] for source_name, _, _ in station_specs
    }
    for element in extract["stations"].get("elements", []):
        tags = element.get("tags", {})
        if tags.get("railway") != "subway_entrance" or not tags.get("ref"):
            continue
        exit_x, exit_y = project(element["lon"], element["lat"])
        nearest = min(
            projected_stations,
            key=lambda name: math.dist((exit_x, exit_y), projected_stations[name]),
        )
        entrances[nearest].append(
            {
                "label": tags["ref"],
                "sourceNodeId": element["id"],
                "xMillis": round(exit_x * COORDINATE_SCALE),
                "yMillis": round(exit_y * COORDINATE_SCALE),
            }
        )

    stations: list[dict[str, Any]] = []
    for source_name, display_name, destination in station_specs:
        x, y = projected_stations[source_name]
        exits = sorted(entrances[source_name], key=lambda exit: exit["label"])
        if not exits:
            raise RuntimeError(f"No OSM subway entrances for {display_name}")
        for exit in exits:
            exit["destination"] = destination
        stations.append(
            {
                "name": display_name,
                "xMillis": round(x * COORDINATE_SCALE),
                "yMillis": round(y * COORDINATE_SCALE),
                "exits": exits,
            }
        )
    return {
        "lineId": "beijing-metro-line-17",
        "path": encode_points(simplified),
        "stations": stations,
    }


def stable_json(value: Any) -> str:
    return json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":"))


def main() -> None:
    args = parse_args()
    extract = load_extracts(args.source_dir)
    display_roads, bridges = make_display_transport(extract)
    metro = make_metro(extract)
    payload = {
        "grid": {
            "width": COLS,
            "height": ROWS,
            "bboxWgs84": {
                "west": WEST,
                "south": SOUTH,
                "east": EAST,
                "north": NORTH,
            },
            "sourceCrs": "EPSG:4326",
            "coordinateScale": COORDINATE_SCALE,
            "presentationTransform": {
                "type": "similarity",
                "sourceProjection": "wide-bbox-linear",
                "coefficient": {
                    "real": FIT_REAL,
                    "imaginary": FIT_IMAGINARY,
                },
                "translation": {
                    "x": FIT_TRANSLATE_X,
                    "y": FIT_TRANSLATE_Y,
                },
                "scale": FIT_SCALE,
                "rotationDegrees": FIT_ROTATION_DEGREES,
                "anchors": FIT_ANCHORS,
            },
        },
        "displayRoads": display_roads,
        "bridges": bridges,
        "metro": metro,
    }
    digest = hashlib.sha256(stable_json(payload).encode("utf-8")).hexdigest()
    transport = {
        "schema": "moontown.energy-valley.transport.v1",
        "datasetId": "energy-valley-osm-transport-2026-08-09-fit-v2",
        "revision": 2,
        "payloadSha256": f"sha256:{digest}",
        "provenance": {
            "source": "OpenStreetMap",
            "sourceUrl": "https://www.openstreetmap.org/#map=14/40.1175/116.4550",
            "license": "ODbL-1.0",
            "attribution": "© OpenStreetMap contributors",
            "officialTransitReference": "Beijing MTR Line 17",
            "officialTransitUrl": "https://www.mtr.bj.cn/service/line/line-17.html",
            "generatedBy": "scripts/generate-energy-valley-transport.py",
            "scope": "Display roads, bridge spans, and Line 17 only; town world unchanged",
        },
        **payload,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        json.dumps(transport, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(
        f"wrote {args.output}: {len(display_roads)} display roads, "
        f"{len(bridges)} bridge spans, {len(metro['path'])} metro points, "
        f"digest {digest}"
    )


if __name__ == "__main__":
    main()
