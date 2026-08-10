#!/usr/bin/env python3
"""Calibrate the illustrated Wenyu town grid against reviewed real features.

This is an offline authoring tool. It never enables runtime transport. A
calibration becomes runtime-eligible only when every review and numerical gate
passes; otherwise the report is explicitly candidate or rejected.

Dependencies: Pillow and NumPy. The tool performs no network requests.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path
from typing import Any

import numpy as np
from PIL import Image, ImageDraw, ImageFont


SCHEMA = "moontown.wenyu_georeference.v1"
CONTROL_SCHEMA = "moontown.wenyu_georeference_controls.v1"
UTM_ZONE = 50
UTM_EPSG = "EPSG:32650"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--controls",
        type=Path,
        default=Path(
            "src/ui/assets/tilemap/georeference/"
            "wenyu-town-control-points-v1.json"
        ),
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=Path(
            "src/ui/assets/tilemap/georeference/"
            "wenyu-town-georef-v1.json"
        ),
    )
    parser.add_argument(
        "--qa-image",
        type=Path,
        default=Path("tmp/georeference/wenyu-town-georef-v1-qa.png"),
    )
    return parser.parse_args()


def load_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def canonical_json(value: Any) -> bytes:
    return json.dumps(
        value,
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    ).encode("utf-8")


def sha256_bytes(value: bytes) -> str:
    return f"sha256:{hashlib.sha256(value).hexdigest()}"


def sha256_file(path: Path) -> str:
    with path.open("rb") as handle:
        return sha256_bytes(handle.read())


def wgs84_to_utm50n(lon: float, lat: float) -> tuple[float, float]:
    """Project WGS84 to UTM zone 50N without a runtime GIS dependency."""
    semi_major = 6378137.0
    flattening = 1.0 / 298.257223563
    eccentricity_sq = flattening * (2.0 - flattening)
    second_eccentricity_sq = eccentricity_sq / (1.0 - eccentricity_sq)
    scale = 0.9996
    central_meridian = math.radians((UTM_ZONE - 1) * 6 - 180 + 3)
    phi = math.radians(lat)
    lam = math.radians(lon)
    sin_phi = math.sin(phi)
    cos_phi = math.cos(phi)
    tan_phi = math.tan(phi)
    n = semi_major / math.sqrt(1.0 - eccentricity_sq * sin_phi * sin_phi)
    t = tan_phi * tan_phi
    c = second_eccentricity_sq * cos_phi * cos_phi
    a = cos_phi * (lam - central_meridian)
    e4 = eccentricity_sq * eccentricity_sq
    e6 = e4 * eccentricity_sq
    meridian = semi_major * (
        (1.0 - eccentricity_sq / 4.0 - 3.0 * e4 / 64.0 - 5.0 * e6 / 256.0)
        * phi
        - (3.0 * eccentricity_sq / 8.0 + 3.0 * e4 / 32.0 + 45.0 * e6 / 1024.0)
        * math.sin(2.0 * phi)
        + (15.0 * e4 / 256.0 + 45.0 * e6 / 1024.0) * math.sin(4.0 * phi)
        - 35.0 * e6 / 3072.0 * math.sin(6.0 * phi)
    )
    easting = scale * n * (
        a
        + (1.0 - t + c) * a**3 / 6.0
        + (5.0 - 18.0 * t + t * t + 72.0 * c - 58.0 * second_eccentricity_sq)
        * a**5
        / 120.0
    ) + 500000.0
    northing = scale * (
        meridian
        + n
        * tan_phi
        * (
            a * a / 2.0
            + (5.0 - t + 9.0 * c + 4.0 * c * c) * a**4 / 24.0
            + (
                61.0
                - 58.0 * t
                + t * t
                + 600.0 * c
                - 330.0 * second_eccentricity_sq
            )
            * a**6
            / 720.0
        )
    )
    return easting, northing


def weighted_rows(
    controls: list[dict[str, Any]],
) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    grid = np.array([[item["grid"]["x"], item["grid"]["y"]] for item in controls])
    target = np.array(
        [wgs84_to_utm50n(item["wgs84"]["lon"], item["wgs84"]["lat"]) for item in controls]
    )
    weights = np.sqrt(np.array([float(item.get("weight", 1.0)) for item in controls]))
    return grid, target, weights


def fit_affine(controls: list[dict[str, Any]]) -> dict[str, Any]:
    grid, target, weights = weighted_rows(controls)
    design = np.column_stack([grid, np.ones(len(grid))])
    solved, _, _, _ = np.linalg.lstsq(
        design * weights[:, None], target * weights[:, None], rcond=None
    )
    matrix = solved[:2, :].T
    translation = solved[2, :]
    return model_payload("affine", matrix, translation, controls)


def fit_similarity(controls: list[dict[str, Any]]) -> dict[str, Any]:
    grid, target, weights = weighted_rows(controls)
    rows: list[list[float]] = []
    values: list[float] = []
    row_weights: list[float] = []
    for (x, y), (easting, northing), weight in zip(grid, target, weights):
        # Grid y increases south/down while UTM northing increases north/up.
        # This is a reflected similarity, not an orientation-preserving screen
        # transform: E=a*x+b*y+tx and N=b*x-a*y+ty.
        rows.extend([[x, y, 1.0, 0.0], [-y, x, 0.0, 1.0]])
        values.extend([easting, northing])
        row_weights.extend([weight, weight])
    design = np.array(rows)
    weighted = np.array(row_weights)
    solved, _, _, _ = np.linalg.lstsq(
        design * weighted[:, None], np.array(values) * weighted, rcond=None
    )
    real, imaginary, translate_e, translate_n = solved
    matrix = np.array([[real, imaginary], [imaginary, -real]])
    translation = np.array([translate_e, translate_n])
    return model_payload("similarity", matrix, translation, controls)


def apply_model(model: dict[str, Any], points: np.ndarray) -> np.ndarray:
    matrix = np.array(model["forward"]["matrix"])
    translation = np.array(model["forward"]["translation"])
    return points @ matrix.T + translation


def apply_inverse(model: dict[str, Any], points: np.ndarray) -> np.ndarray:
    matrix = np.array(model["inverse"]["matrix"])
    translation = np.array(model["inverse"]["translation"])
    return points @ matrix.T + translation


def model_payload(
    kind: str,
    matrix: np.ndarray,
    translation: np.ndarray,
    controls: list[dict[str, Any]],
) -> dict[str, Any]:
    inverse_matrix = np.linalg.inv(matrix)
    inverse_translation = -(inverse_matrix @ translation)
    singular_values = np.linalg.svd(matrix, compute_uv=False)
    determinant = float(np.linalg.det(matrix))
    canonical_matrix = matrix @ np.diag([1.0, -1.0])
    rotation = math.degrees(
        math.atan2(
            canonical_matrix[1, 0] - canonical_matrix[0, 1],
            canonical_matrix[0, 0] + canonical_matrix[1, 1],
        )
    )
    columns = [matrix[:, 0], matrix[:, 1]]
    column_cosine = float(
        abs(np.dot(columns[0], columns[1]))
        / (np.linalg.norm(columns[0]) * np.linalg.norm(columns[1]))
    )
    payload: dict[str, Any] = {
        "kind": kind,
        "forward": {
            "formula": "[E,N] = matrix * [gridX,gridY] + translation",
            "matrix": rounded_matrix(matrix),
            "translation": rounded_vector(translation),
        },
        "inverse": {
            "formula": "[gridX,gridY] = matrix * [E,N] + translation",
            "matrix": rounded_matrix(inverse_matrix),
            "translation": rounded_vector(inverse_translation),
        },
        "diagnostics": {
            "determinant": round(determinant, 9),
            "singularValuesMetersPerTile": rounded_vector(singular_values),
            "scaleRatio": round(float(max(singular_values) / min(singular_values)), 9),
            "rotationDegrees": round(rotation, 9),
            "axisNonOrthogonalityCosine": round(column_cosine, 9),
            "expectedDeterminantSign": "negative because grid y points south/down",
        },
    }
    attach_residuals(payload, controls)
    return payload


def rounded_vector(value: np.ndarray) -> list[float]:
    # Coefficients need more precision than human-facing diagnostics: the UTM
    # translation is about 4.4 million metres, so nine decimal places on the
    # inverse can still accumulate millitile round-trip error.
    return [round(float(item), 15) for item in value]


def rounded_matrix(value: np.ndarray) -> list[list[float]]:
    return [rounded_vector(row) for row in value]


def percentile(values: list[float], value: float) -> float | None:
    if not values:
        return None
    return round(float(np.percentile(np.array(values), value)), 6)


def summarize(values: list[float]) -> dict[str, float | None]:
    if not values:
        return {"count": 0, "rms": None, "median": None, "p95": None, "max": None}
    array = np.array(values)
    return {
        "count": len(values),
        "rms": round(float(math.sqrt(np.mean(array * array))), 6),
        "median": percentile(values, 50),
        "p95": percentile(values, 95),
        "max": round(float(max(values)), 6),
    }


def attach_residuals(model: dict[str, Any], controls: list[dict[str, Any]]) -> None:
    if not controls:
        model["residuals"] = []
        model["metrics"] = {
            "meters": summarize([]),
            "tiles": summarize([]),
        }
        return
    grid, target, _ = weighted_rows(controls)
    predicted = apply_model(model, grid)
    residuals = np.linalg.norm(predicted - target, axis=1)
    meters_per_tile = float(
        np.mean(model["diagnostics"]["singularValuesMetersPerTile"])
    )
    model["residuals"] = [
        {
            "controlId": item["id"],
            "meters": round(float(distance), 6),
            "tiles": round(float(distance / meters_per_tile), 6),
        }
        for item, distance in zip(controls, residuals)
    ]
    model["metrics"] = {
        "meters": summarize([float(value) for value in residuals]),
        "tiles": summarize([float(value / meters_per_tile) for value in residuals]),
    }


def convex_hull(points: list[tuple[float, float]]) -> list[tuple[float, float]]:
    unique = sorted(set(points))
    if len(unique) <= 1:
        return unique

    def cross(
        origin: tuple[float, float],
        first: tuple[float, float],
        second: tuple[float, float],
    ) -> float:
        return (first[0] - origin[0]) * (second[1] - origin[1]) - (
            first[1] - origin[1]
        ) * (second[0] - origin[0])

    lower: list[tuple[float, float]] = []
    for point in unique:
        while len(lower) >= 2 and cross(lower[-2], lower[-1], point) <= 0:
            lower.pop()
        lower.append(point)
    upper: list[tuple[float, float]] = []
    for point in reversed(unique):
        while len(upper) >= 2 and cross(upper[-2], upper[-1], point) <= 0:
            upper.pop()
        upper.append(point)
    return lower[:-1] + upper[:-1]


def polygon_area(points: list[tuple[float, float]]) -> float:
    if len(points) < 3:
        return 0.0
    return abs(
        sum(
            first[0] * second[1] - second[0] * first[1]
            for first, second in zip(points, points[1:] + points[:1])
        )
    ) / 2.0


def leave_one_out(
    model_kind: str,
    controls: list[dict[str, Any]],
) -> dict[str, Any]:
    if len(controls) < 4:
        return {
            "meters": summarize([]),
            "tiles": summarize([]),
        }
    distances: list[float] = []
    tile_distances: list[float] = []
    for index, omitted in enumerate(controls):
        retained = controls[:index] + controls[index + 1 :]
        model = fit_similarity(retained) if model_kind == "similarity" else fit_affine(retained)
        target = np.array(
            [wgs84_to_utm50n(omitted["wgs84"]["lon"], omitted["wgs84"]["lat"])]
        )
        predicted = apply_model(
            model,
            np.array([[omitted["grid"]["x"], omitted["grid"]["y"]]]),
        )
        distance = float(np.linalg.norm(predicted[0] - target[0]))
        scale = float(np.mean(model["diagnostics"]["singularValuesMetersPerTile"]))
        distances.append(distance)
        tile_distances.append(distance / scale)
    return {"meters": summarize(distances), "tiles": summarize(tile_distances)}


def verify_asset_digests(config: dict[str, Any], repo_root: Path) -> list[str]:
    failures: list[str] = []
    for asset in config["grid"]["sourceAssets"]:
        path = repo_root / asset["path"]
        if not path.is_file():
            failures.append(f"missing source asset: {asset['path']}")
            continue
        actual = sha256_file(path)
        if actual != asset["sha256"]:
            failures.append(
                f"source digest mismatch: {asset['path']} expected {asset['sha256']} got {actual}"
            )
    return failures


def control_validation(config: dict[str, Any]) -> list[str]:
    failures: list[str] = []
    if config.get("schema") != CONTROL_SCHEMA:
        failures.append(f"schema must be {CONTROL_SCHEMA}")
    width = config["grid"]["width"]
    height = config["grid"]["height"]
    seen: set[str] = set()
    for item in config.get("controls", []):
        if item["id"] in seen:
            failures.append(f"duplicate control id: {item['id']}")
        seen.add(item["id"])
        if item["reviewStatus"] not in {"candidate", "confirmed", "rejected"}:
            failures.append(f"invalid review status: {item['id']}")
        if item["role"] not in {"fit", "holdout"}:
            failures.append(f"invalid role: {item['id']}")
        x = item["grid"]["x"]
        y = item["grid"]["y"]
        if not (0.0 <= x <= width and 0.0 <= y <= height):
            failures.append(f"grid point out of bounds: {item['id']}")
        lon = item["wgs84"]["lon"]
        lat = item["wgs84"]["lat"]
        if not (116.3 <= lon <= 116.6 and 40.0 <= lat <= 40.3):
            failures.append(f"WGS84 point outside Future Science City: {item['id']}")
    return failures


def choose_model(
    models: list[dict[str, Any]],
    policy: dict[str, Any],
    fit_control_count: int,
) -> dict[str, Any]:
    similarity, affine = models
    if fit_control_count < policy["minimumAffineFitControls"]:
        return similarity
    similarity_rms = similarity["metrics"]["tiles"]["rms"]
    affine_rms = affine["metrics"]["tiles"]["rms"]
    improvement = 0.0 if not similarity_rms else 1.0 - affine_rms / similarity_rms
    affine_safe = (
        affine["diagnostics"]["scaleRatio"] <= policy["maximumScaleRatio"]
        and affine["diagnostics"]["axisNonOrthogonalityCosine"]
        <= policy["maximumAxisNonOrthogonalityCosine"]
        and affine["diagnostics"]["determinant"] < 0.0
    )
    if affine_safe and improvement >= policy["minimumAffineRmsImprovement"]:
        return affine
    return similarity


def evaluate(
    config: dict[str, Any],
    selected: dict[str, Any],
    fit_controls: list[dict[str, Any]],
    holdouts: list[dict[str, Any]],
    asset_failures: list[str],
) -> dict[str, Any]:
    policy = config["acceptancePolicy"]
    confirmed_fit = [item for item in fit_controls if item["reviewStatus"] == "confirmed"]
    confirmed_holdouts = [item for item in holdouts if item["reviewStatus"] == "confirmed"]
    confirmed_all = confirmed_fit + confirmed_holdouts
    non_station_groups = {
        item["independentGroup"]
        for item in confirmed_all
        if item["featureType"] != "station"
    }
    station_count = sum(item["featureType"] == "station" for item in confirmed_all)
    quadrants = {
        (item["grid"]["x"] >= config["grid"]["width"] / 2.0,
         item["grid"]["y"] >= config["grid"]["height"] / 2.0)
        for item in confirmed_all
    }
    hull = convex_hull(
        [(item["grid"]["x"], item["grid"]["y"]) for item in confirmed_all]
    )
    coverage = polygon_area(hull) / (config["grid"]["width"] * config["grid"]["height"])
    holdout_model = dict(selected)
    attach_residuals(holdout_model, holdouts)
    loo = leave_one_out(selected["kind"], fit_controls)
    metrics = selected["metrics"]["tiles"]
    holdout_metrics = holdout_model["metrics"]["tiles"]
    review_gates = {
        "minimumConfirmedFitControls": len(confirmed_fit) >= policy["minimumFitControls"],
        "minimumIndependentNonStationGroups": len(non_station_groups)
        >= policy["minimumIndependentNonStationGroups"],
        "maximumStationControls": station_count <= policy["maximumStationControls"],
        "minimumSourceQuadrants": len(quadrants) >= policy["minimumSourceQuadrants"],
        "minimumConfirmedHoldouts": len(confirmed_holdouts)
        >= policy["minimumHoldoutControls"],
        "sourceHullCoverage": coverage >= policy["minimumSourceHullCoverage"],
        "sourceAssetDigests": not asset_failures,
    }
    numerical_gates = {
        "fitRmsTiles": metrics["rms"] is not None and metrics["rms"] <= policy["maximumRmsTiles"],
        "fitP95Tiles": metrics["p95"] is not None and metrics["p95"] <= policy["maximumP95Tiles"],
        "fitMaxTiles": metrics["max"] is not None and metrics["max"] <= policy["maximumMaxTiles"],
        "holdoutP95Tiles": holdout_metrics["p95"] is not None
        and holdout_metrics["p95"] <= policy["maximumHoldoutTiles"],
        "leaveOneOutP95Tiles": loo["tiles"]["p95"] is not None
        and loo["tiles"]["p95"] <= policy["maximumLeaveOneOutTiles"],
        "axisOrientationMatched": selected["diagnostics"]["determinant"] < 0.0,
        "boundedScaleRatio": selected["diagnostics"]["scaleRatio"]
        <= policy["maximumScaleRatio"],
    }
    reviews_complete = all(review_gates.values()) and all(
        item["reviewStatus"] == "confirmed" for item in fit_controls + holdouts
    )
    if not reviews_complete:
        status = "candidate"
    elif all(numerical_gates.values()):
        status = "accepted"
    else:
        status = "rejected"
    return {
        "status": status,
        "runtimeEligible": status == "accepted",
        "reason": (
            "Calibration remains authoring-only until independent controls and holdouts are confirmed."
            if status == "candidate"
            else "All review and numerical gates pass."
            if status == "accepted"
            else "Reviewed controls do not support the requested map accuracy without warping."
        ),
        "reviewGates": review_gates,
        "numericalGates": numerical_gates,
        "sourceHullCoverage": round(coverage, 9),
        "assetFailures": asset_failures,
        "fitMetrics": selected["metrics"],
        "holdoutMetrics": holdout_model["metrics"],
        "leaveOneOutMetrics": loo,
    }


def build_report(config: dict[str, Any], controls_path: Path) -> dict[str, Any]:
    repo_root = Path(__file__).resolve().parent.parent
    failures = control_validation(config)
    asset_failures = verify_asset_digests(config, repo_root)
    active = [item for item in config["controls"] if item["reviewStatus"] != "rejected"]
    fit_controls = [item for item in active if item["role"] == "fit"]
    holdouts = [item for item in active if item["role"] == "holdout"]
    if len(fit_controls) < 3:
        raise ValueError("at least three non-rejected fit controls are required")
    models = [fit_similarity(fit_controls), fit_affine(fit_controls)]
    selected = choose_model(
        models,
        config["acceptancePolicy"],
        len(fit_controls),
    )
    qa = evaluate(config, selected, fit_controls, holdouts, asset_failures + failures)
    report = {
        "schema": SCHEMA,
        "datasetId": config["datasetId"],
        "revision": config["revision"],
        "controlSetSha256": sha256_bytes(canonical_json(config)),
        "grid": config["grid"],
        "targetCrs": {
            "source": "EPSG:4326",
            "projected": UTM_EPSG,
            "axisOrder": ["easting", "northing"],
        },
        "selectedModel": selected,
        "candidateModels": models,
        "controls": config["controls"],
        "qa": qa,
        "runtimePolicy": {
            "failClosed": True,
            "requiredQaStatus": "accepted",
            "note": "This report is not loaded by the game while runtimeEligible is false.",
        },
        "provenance": config["provenance"],
    }
    digest_payload = dict(report)
    report["payloadSha256"] = sha256_bytes(canonical_json(digest_payload))
    return report


def render_qa(
    config: dict[str, Any],
    report: dict[str, Any],
    output: Path,
) -> None:
    repo_root = Path(__file__).resolve().parent.parent
    preview = Image.open(repo_root / config["grid"]["previewPath"]).convert("RGBA")
    preview = preview.resize((1024, 576), Image.Resampling.NEAREST)
    canvas = Image.new("RGBA", (1400, 680), (18, 28, 31, 255))
    canvas.alpha_composite(preview, (0, 104))
    draw = ImageDraw.Draw(canvas)
    font = ImageFont.load_default()
    selected = report["selectedModel"]
    qa = report["qa"]
    draw.text((20, 15), "Wenyu town georeference — authoring QA", fill=(242, 247, 242), font=font)
    draw.text(
        (20, 38),
        f"status={qa['status']}  runtimeEligible={str(qa['runtimeEligible']).lower()}  model={selected['kind']}",
        fill=(255, 196, 92) if qa["status"] != "accepted" else (105, 226, 166),
        font=font,
    )
    fit_tiles = qa["fitMetrics"]["tiles"]
    holdout_tiles = qa["holdoutMetrics"]["tiles"]
    draw.text(
        (20, 61),
        f"fit RMS={fit_tiles['rms']} tiles  p95={fit_tiles['p95']}  holdout p95={holdout_tiles['p95']}",
        fill=(221, 228, 221),
        font=font,
    )
    draw.text(
        (20, 82),
        "Orange=candidate fit, cyan=holdout; line ends at coordinate implied by the fitted inverse.",
        fill=(174, 189, 183),
        font=font,
    )
    matrix = np.array(selected["inverse"]["matrix"])
    translation = np.array(selected["inverse"]["translation"])
    residual_by_id = {item["controlId"]: item for item in selected["residuals"]}
    legend_y = 126
    for marker_index, item in enumerate(config["controls"], start=1):
        if item["reviewStatus"] == "rejected":
            continue
        target = np.array(
            [wgs84_to_utm50n(item["wgs84"]["lon"], item["wgs84"]["lat"])]
        )
        implied = target @ matrix.T + translation
        actual = np.array([[item["grid"]["x"], item["grid"]["y"]]])
        start = (actual[0, 0] * 4.0, actual[0, 1] * 4.0 + 104.0)
        end = (implied[0, 0] * 4.0, implied[0, 1] * 4.0 + 104.0)
        color = (255, 166, 69, 245) if item["role"] == "fit" else (74, 221, 235, 245)
        draw.line([start, end], fill=color, width=3)
        radius = 6
        draw.ellipse(
            [start[0] - radius, start[1] - radius, start[0] + radius, start[1] + radius],
            outline=color,
            fill=(15, 28, 32, 220),
            width=2,
        )
        draw.text((start[0] - 3, start[1] - 5), str(marker_index), fill=color, font=font)
        error = residual_by_id.get(item["id"], {}).get("tiles")
        suffix = "" if error is None else f"  {error:.2f} tiles"
        draw.text(
            (1044, legend_y),
            f"{marker_index}. {item['id']}{suffix}",
            fill=color,
            font=font,
        )
        draw.text(
            (1060, legend_y + 15),
            f"{item['role']} / {item['reviewStatus']}",
            fill=(174, 189, 183),
            font=font,
        )
        legend_y += 48
    output.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(output)


def main() -> None:
    args = parse_args()
    config = load_json(args.controls)
    report = build_report(config, args.controls)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        json.dumps(report, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    render_qa(config, report, args.qa_image)
    print(
        json.dumps(
            {
                "status": report["qa"]["status"],
                "runtimeEligible": report["qa"]["runtimeEligible"],
                "selectedModel": report["selectedModel"]["kind"],
                "fitRmsTiles": report["qa"]["fitMetrics"]["tiles"]["rms"],
                "holdoutP95Tiles": report["qa"]["holdoutMetrics"]["tiles"]["p95"],
                "output": str(args.output),
                "qaImage": str(args.qa_image),
            },
            ensure_ascii=False,
        )
    )


if __name__ == "__main__":
    main()
