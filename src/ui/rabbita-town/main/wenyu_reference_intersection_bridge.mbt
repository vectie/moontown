///|
extern "js" fn reference_osm_block_graph_ready() -> Bool =
  #| () => globalThis.__moontownEnergyValleyOsmBlockGraphValidated === true &&
  #|   globalThis.__moontownEnergyValleyOsmBlockGraph?.schema ===
  #|     "moontown.energy-valley.osm_block_graph.v1" &&
  #|   globalThis.__moontownEnergyValleyOsmBlockGraph?.metrics?.intersections ===
  #|     338

///|
/// Candidate intersections are authoring evidence only. The JavaScript loader
/// validates the complete immutable payload before exposing this bridge; this
/// guard deliberately also requires `runtimeEligible: false` so the points can
/// never masquerade as the accepted semantic road graph.
extern "js" fn reference_intersection_snapshot_ready() -> Bool =
  #| () => {
  #|   const osm = globalThis.__moontownEnergyValleyOsmBlockGraph;
  #|   if (globalThis.__moontownEnergyValleyOsmBlockGraphValidated === true) {
  #|     return osm?.schema === "moontown.energy-valley.osm_block_graph.v1" &&
  #|       osm?.tileGrid?.width === 256 && osm?.tileGrid?.height === 144 &&
  #|       osm?.metrics?.intersections === 338 &&
  #|       Array.isArray(osm?.points) && osm.points.length === 338;
  #|   }
  #|   const value = globalThis.__wenyuReferenceIntersections;
  #|   return globalThis.__wenyuReferenceIntersectionsValidated === true &&
  #|     (value?.schema === "moontown.wenyu_reference_intersections.v1" ||
  #|       value?.schema === "moontown.wenyu_reference_intersections.v2") &&
  #|     value?.tileGrid?.width === 256 && value?.tileGrid?.height === 144 &&
  #|     value?.runtimeEligible === false &&
  #|     value?.authoringCalibration?.runtimeEligible === false &&
  #|     value?.authoringCalibration?.appliedToPoints === false &&
  #|     value?.metrics?.points === 145 &&
  #|     Array.isArray(value?.points) && value.points.length === 145;
  #| }

///|
/// A graph becomes drawable only after the JavaScript loader validates the
/// complete v2 topology. Point readiness remains independent so a rejected
/// graph can fall back to the canonical map plus calibration markers.
extern "js" fn reference_intersection_preview_graph_ready() -> Bool =
  #| () => {
  #|   const osm = globalThis.__moontownEnergyValleyOsmBlockGraph;
  #|   if (globalThis.__moontownEnergyValleyOsmBlockGraphValidated === true) {
  #|     return osm?.schema === "moontown.energy-valley.osm_block_graph.v1" &&
  #|       osm?.metrics?.intersections === 338 &&
  #|       osm?.metrics?.edges === 775 &&
  #|       Array.isArray(osm?.graph?.edges) &&
  #|       osm.graph.edges.length === 775;
  #|   }
  #|   const value = globalThis.__wenyuReferenceIntersections;
  #|   return globalThis.__wenyuReferenceIntersectionPreviewGraphValidated ===
  #|       true &&
  #|     value?.schema === "moontown.wenyu_reference_intersections.v2" &&
  #|     value?.runtimeEligible === false &&
  #|     value?.previewGraph?.method ===
  #|       "exact-seed 8-neighbor source-skeleton geodesics, unique-segment union, degree-not-two routing-node compression" &&
  #|     value?.previewGraph?.metrics?.nodes === 145 &&
  #|     value?.previewGraph?.metrics?.routingNodes === 38 &&
  #|     value?.previewGraph?.metrics?.totalGraphNodes === 183 &&
  #|     value?.previewGraph?.metrics?.edges === 216 &&
  #|     value?.previewGraph?.metrics?.components === 1 &&
  #|     value?.previewGraph?.metrics?.cycleRank === 34 &&
  #|     value?.previewGraph?.metrics?.terminalsOmitted === 160 &&
  #|     value?.previewGraph?.metrics?.unrepresentedVerifiedArms === 193 &&
  #|     value?.previewGraph?.metrics?.bridges === 5 &&
  #|     value?.previewGraph?.metrics?.bridgeEvidenceVertices === 66 &&
  #|     value?.previewGraph?.metrics?.bridgeSpanVertices === 68 &&
  #|     value?.previewGraph?.metrics?.sourceSegments === 14141 &&
  #|     value?.previewGraph?.metrics?.enclosedBlocks === 34 &&
  #|     value?.previewGraph?.metrics?.waterConflicts === 0 &&
  #|     Array.isArray(value?.previewGraph?.routingNodes) &&
  #|     value.previewGraph.routingNodes.length === 38 &&
  #|     Array.isArray(value?.previewGraph?.edges) &&
  #|     value.previewGraph.edges.length === 216;
  #| }

///|
extern "js" fn reference_intersection_count() -> Int =
  #| () => {
  #|   if (globalThis.__moontownEnergyValleyOsmBlockGraphValidated === true) {
  #|     return globalThis.__moontownEnergyValleyCartoonRoadGraph?.junctions
  #|       ?.length ?? 0;
  #|   }
  #|   const value = globalThis.__wenyuReferenceIntersections;
  #|   const verified = value?.points?.length ?? 0;
  #|   if (!globalThis.__wenyuReferenceIntersectionPreviewGraphValidated) {
  #|     return verified;
  #|   }
  #|   return verified + (value?.previewGraph?.routingNodes?.length ?? 0);
  #| }

///|
extern "js" fn reference_intersection_x_millis(index : Int) -> Int =
  #| index => {
  #|   if (globalThis.__moontownEnergyValleyOsmBlockGraphValidated === true) {
  #|     return globalThis.__moontownEnergyValleyCartoonRoadGraph
  #|       ?.junctions?.[index]
  #|       ?.xMillis ?? 0;
  #|   }
  #|   const value = globalThis.__wenyuReferenceIntersections;
  #|   const verified = value?.points?.length ?? 0;
  #|   if (index < verified) return value?.points?.[index]?.xMillis ?? 0;
  #|   if (!globalThis.__wenyuReferenceIntersectionPreviewGraphValidated) {
  #|     return 0;
  #|   }
  #|   return value?.previewGraph?.routingNodes?.[index - verified]
  #|     ?.xMillis ?? 0;
  #| }

///|
extern "js" fn reference_intersection_y_millis(index : Int) -> Int =
  #| index => {
  #|   if (globalThis.__moontownEnergyValleyOsmBlockGraphValidated === true) {
  #|     return globalThis.__moontownEnergyValleyCartoonRoadGraph
  #|       ?.junctions?.[index]
  #|       ?.yMillis ?? 0;
  #|   }
  #|   const value = globalThis.__wenyuReferenceIntersections;
  #|   const verified = value?.points?.length ?? 0;
  #|   if (index < verified) return value?.points?.[index]?.yMillis ?? 0;
  #|   if (!globalThis.__wenyuReferenceIntersectionPreviewGraphValidated) {
  #|     return 0;
  #|   }
  #|   return value?.previewGraph?.routingNodes?.[index - verified]
  #|     ?.yMillis ?? 0;
  #| }

///|
extern "js" fn reference_intersection_kind(index : Int) -> String =
  #| index => {
  #|   if (globalThis.__moontownEnergyValleyOsmBlockGraphValidated === true) {
  #|     const degree = globalThis.__moontownEnergyValleyCartoonRoadGraph
  #|       ?.junctions?.[index]?.degree ?? 0;
  #|     return degree === 3 ? "t" : degree === 4 ? "cross" : "complex";
  #|   }
  #|   const value = globalThis.__wenyuReferenceIntersections;
  #|   const verified = value?.points?.length ?? 0;
  #|   if (index < verified) return value?.points?.[index]?.kind || "";
  #|   if (!globalThis.__wenyuReferenceIntersectionPreviewGraphValidated) {
  #|     return "";
  #|   }
  #|   const routing = value?.previewGraph?.routingNodes?.[index - verified];
  #|   if (!routing) return "";
  #|   let cached = globalThis.__moontownWenyuIntersectionRoutingDegrees;
  #|   if (cached?.source !== value || !(cached?.values instanceof Map)) {
  #|     const degrees = new Map();
  #|     for (const edge of value?.previewGraph?.edges ?? []) {
  #|       degrees.set(edge.from, (degrees.get(edge.from) ?? 0) + 1);
  #|       degrees.set(edge.to, (degrees.get(edge.to) ?? 0) + 1);
  #|     }
  #|     cached = { source: value, values: degrees };
  #|     globalThis.__moontownWenyuIntersectionRoutingDegrees = cached;
  #|   }
  #|   const degree = cached.values.get(routing.id) ?? 0;
  #|   return degree === 3 ? "t" : degree === 4 ? "cross" : "complex";
  #| }

///|
extern "js" fn reference_intersection_confidence(index : Int) -> String =
  #| index => {
  #|   if (globalThis.__moontownEnergyValleyOsmBlockGraphValidated === true) {
  #|     return globalThis.__moontownEnergyValleyCartoonRoadGraph
  #|       ?.junctions?.[index] ? "cartoon" : "";
  #|   }
  #|   const value = globalThis.__wenyuReferenceIntersections;
  #|   const verified = value?.points?.length ?? 0;
  #|   if (index < verified) {
  #|     return value?.points?.[index]?.semanticEvidence?.confidence || "";
  #|   }
  #|   return globalThis.__wenyuReferenceIntersectionPreviewGraphValidated &&
  #|     value?.previewGraph?.routingNodes?.[index - verified]
  #|     ? "review" : "";
  #| }

///|
extern "js" fn reference_intersection_high_count() -> Int =
  #| () => globalThis.__moontownEnergyValleyOsmBlockGraphValidated === true
  #|   ? globalThis.__moontownEnergyValleyOsmBlockGraph?.metrics?.confidence
  #|       ?.high ?? 0
  #|   : globalThis.__wenyuReferenceIntersections?.metrics
  #|       ?.semanticConfidence?.high ?? 0

///|
extern "js" fn reference_intersection_medium_count() -> Int =
  #| () => globalThis.__moontownEnergyValleyOsmBlockGraphValidated === true
  #|   ? globalThis.__moontownEnergyValleyOsmBlockGraph?.metrics?.confidence
  #|       ?.medium ?? 0
  #|   : globalThis.__wenyuReferenceIntersections?.metrics
  #|       ?.semanticConfidence?.medium ?? 0

///|
extern "js" fn reference_intersection_review_count() -> Int =
  #| () => {
  #|   if (globalThis.__moontownEnergyValleyOsmBlockGraphValidated === true) {
  #|     return globalThis.__moontownEnergyValleyOsmBlockGraph?.metrics
  #|       ?.confidence?.review ?? 0;
  #|   }
  #|   const value = globalThis.__wenyuReferenceIntersections;
  #|   const verified = value?.metrics?.semanticConfidence?.review ?? 0;
  #|   if (!globalThis.__wenyuReferenceIntersectionPreviewGraphValidated) {
  #|     return verified;
  #|   }
  #|   return verified + (value?.previewGraph?.routingNodes?.length ?? 0);
  #| }

///|
extern "js" fn reference_intersection_source_branch_count() -> Int =
  #| () => globalThis.__moontownEnergyValleyOsmBlockGraphValidated === true
  #|   ? globalThis.__moontownEnergyValleyOsmBlockGraph?.metrics?.routingNodes ?? 0
  #|   : globalThis.__wenyuReferenceIntersectionPreviewGraphValidated
  #|     ? globalThis.__wenyuReferenceIntersections?.previewGraph?.routingNodes
  #|         ?.length ?? 0
  #|     : 0

///|
extern "js" fn reference_intersection_preview_node_count() -> Int =
  #| () => globalThis.__moontownEnergyValleyOsmBlockGraphValidated === true
  #|   ? globalThis.__moontownEnergyValleyCartoonRoadGraph?.metrics?.junctions ?? 0
  #|   : globalThis.__wenyuReferenceIntersections?.previewGraph?.metrics
  #|       ?.totalGraphNodes ?? 0

///|
extern "js" fn reference_intersection_preview_edge_count() -> Int =
  #| () => globalThis.__moontownEnergyValleyOsmBlockGraphValidated === true
  #|   ? globalThis.__moontownEnergyValleyCartoonRoadGraph?.metrics?.edges ?? 0
  #|   : globalThis.__wenyuReferenceIntersections?.previewGraph?.metrics
  #|       ?.edges ?? 0

///|
extern "js" fn reference_intersection_preview_bridge_count() -> Int =
  #| () => globalThis.__moontownEnergyValleyOsmBlockGraphValidated === true
  #|   ? globalThis.__moontownEnergyValleyCartoonRoadGraph?.metrics?.bridges ?? 0
  #|   : globalThis.__wenyuReferenceIntersections?.previewGraph?.metrics
  #|       ?.bridges ?? 0

///|
/// Presentation-only cell lookup for deterministic building frontage checks.
/// The checked-in graph remains immutable; this cached set only answers
/// whether a candidate footprint or one-tile apron touches its reviewed path.
extern "js" fn reference_intersection_preview_graph_cell_at(
  x : Int,
  y : Int,
) -> Bool =
  #| (x, y) => {
  #|   const osmReady =
  #|     globalThis.__moontownEnergyValleyOsmBlockGraphValidated === true;
  #|   const legacyReady =
  #|     globalThis.__wenyuReferenceIntersectionPreviewGraphValidated === true;
  #|   if (!osmReady && !legacyReady) {
  #|     return false;
  #|   }
  #|   const value = osmReady
  #|     ? globalThis.__moontownEnergyValleyOsmBlockGraph
  #|     : globalThis.__wenyuReferenceIntersections;
  #|   if (osmReady) {
  #|     const cartoon = globalThis.__moontownEnergyValleyCartoonRoadGraph;
  #|     return cartoon?.source === value && cartoon?.cells instanceof Set &&
  #|       cartoon.cells.has(`${x},${y}`);
  #|   }
  #|   const edges = value?.previewGraph?.edges;
  #|   if (!Array.isArray(edges)) return false;
  #|   let cache = globalThis.__moontownWenyuIntersectionGraphCells;
  #|   if (cache?.source !== value || !(cache?.cells instanceof Set)) {
  #|     const cells = new Set();
  #|     for (const edge of edges) {
  #|       const path = edge.pathMillis ?? [];
  #|       for (let index = 0; index < path.length; index++) {
  #|         const point = path[index];
  #|         if (!Array.isArray(point) || point.length !== 2) continue;
  #|         const previous = path[index - 1] ?? point;
  #|         const steps = Math.max(
  #|           1,
  #|           Math.ceil(Math.max(
  #|             Math.abs(point[0] - previous[0]),
  #|             Math.abs(point[1] - previous[1]),
  #|           ) / 250),
  #|         );
  #|         for (let step = 0; step <= steps; step++) {
  #|           const ratio = step / steps;
  #|           const cellX = Math.floor(
  #|             (previous[0] + (point[0] - previous[0]) * ratio) / 1000,
  #|           );
  #|           const cellY = Math.floor(
  #|             (previous[1] + (point[1] - previous[1]) * ratio) / 1000,
  #|           );
  #|           if (cellX >= 0 && cellX < 256 && cellY >= 0 && cellY < 144) {
  #|             cells.add(`${cellX},${cellY}`);
  #|           }
  #|         }
  #|       }
  #|     }
  #|     cache = { source: value, cells };
  #|     globalThis.__moontownWenyuIntersectionGraphCells = cache;
  #|   }
  #|   return cache.cells.has(`${x},${y}`);
  #| }
