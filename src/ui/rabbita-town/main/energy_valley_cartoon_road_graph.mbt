///|
/// Build the one display graph used by the MoonTown map from the validated OSM
/// reference. OSM remains immutable evidence: the display preserves all 338
/// reviewed intersections and every routed edge. Exact source coordinates are
/// retained alongside the derived design-space geometry. Terrain is the target,
/// never warped to accommodate OSM. Cached by source and design registration
/// identity and never becomes semantic/pathfinding authority.
fn reference_osm_cartoon_road_graph_prepare() -> Bool {
  town_design_registration_prepare()
  reference_osm_cartoon_road_graph_prepare_with_widths(
    town_scene_road_width("primary"),
    town_scene_road_width("secondary"),
    town_scene_road_width("local"),
    town_scene_registration_valid,
  )
}

///|
extern "js" fn reference_osm_cartoon_road_graph_prepare_with_widths(
  primary : Double,
  secondary : Double,
  local : Double,
  audit : () -> Bool,
) -> Bool =
  #| (primary, secondary, local, audit) => {
  #|   const source = globalThis.__moontownEnergyValleyOsmBlockGraph;
  #|   if (globalThis.__moontownEnergyValleyOsmBlockGraphValidated !== true ||
  #|     source?.schema !== "moontown.energy-valley.osm_block_graph.v1" ||
  #|     !Array.isArray(source?.points) ||
  #|     !Array.isArray(source?.graph?.routingNodes) ||
  #|     !Array.isArray(source?.graph?.edges)
  #|   ) return false;
  #|   const existing = globalThis.__moontownEnergyValleyCartoonRoadGraph;
  #|   const registration = globalThis.__moontownDesignRegistration;
  #|   if (existing?.source === source && existing?.version === 6 && existing?.designRegistration === registration && existing?.registrationValid === true) return true;
  #|   const copyPoint = point => [point[0], point[1]];
  #|   const projectPoint = point => registration
  #|     ? [registration.project(point[0], point[1], 0), registration.project(point[0], point[1], 1)]
  #|     : copyPoint(point);
  #|   const projectPath = path => {
  #|     const points = [projectPoint(path[0])], indices = [0];
  #|     for (let i = 1; i < path.length; i++) {
  #|       const segment = registration
  #|         ? JSON.parse(registration.segment(...path[i-1], ...path[i]))
  #|         : [copyPoint(path[i-1]), copyPoint(path[i])];
  #|       points.push(...segment.slice(1));
  #|       indices.push(points.length - 1);
  #|     }
  #|     return {points, indices};
  #|   };
  #|
  #|   const endpoints = new Map();
  #|   for (const node of [...source.points, ...source.graph.routingNodes]) {
  #|     const [x, y] = projectPoint([node.xMillis, node.yMillis]);
  #|     endpoints.set(node.id, {
  #|       id: node.id,
  #|       x,
  #|       y,
  #|       sourceXMillis: node.xMillis,
  #|       sourceYMillis: node.yMillis,
  #|       boundary: node.reason === "map-boundary",
  #|     });
  #|   }
  #|   // Every reviewed OSM edge contributes its complete routed geometry.
  #|   // Confidence controls only the resulting display hierarchy.
  #|   const sourceEdges = source.graph.edges.filter(edge =>
  #|     (edge?.confidence === "high" || edge?.confidence === "medium" ||
  #|       edge?.confidence === "review") && Array.isArray(edge?.pathMillis) &&
  #|       edge.pathMillis.length >= 2 && endpoints.has(edge.from) &&
  #|       endpoints.has(edge.to)
  #|   );
  #|   if (sourceEdges.length !== source.graph.edges.length) return false;
  #|   const endpointIds = [...endpoints.keys()].sort();
  #|   if (!endpointIds.length) return false;
  #|
  #|   // One display node per source node, even when coordinates coincide.
  #|   // Never cluster junctions, snap endpoints, or contract parallel streets.
  #|   const groups = endpointIds.map(id => ({
  #|     ...endpoints.get(id), members: [id],
  #|   })).sort((left, right) => left.y - right.y || left.x - right.x ||
  #|     left.members[0].localeCompare(right.members[0]));
  #|   const clusterByEndpoint = new Map();
  #|   const clusteredNodes = groups.map((group, index) => {
  #|     const id = `cartoon-node-${String(index).padStart(3, "0")}`;
  #|     for (const member of group.members) clusterByEndpoint.set(member, id);
  #|     return { id, xMillis: group.x, yMillis: group.y,
  #|       sourceXMillis: group.sourceXMillis, sourceYMillis: group.sourceYMillis,
  #|       boundary: group.boundary, members: group.members };
  #|   });
  #|   const nodeById = new Map(clusteredNodes.map(node => [node.id, node]));
  #|
  #|   const pathLength = path => {
  #|     let total = 0;
  #|     for (let index = 1; index < path.length; index += 1) {
  #|       total += Math.hypot(
  #|         path[index][0] - path[index - 1][0],
  #|         path[index][1] - path[index - 1][1],
  #|       );
  #|     }
  #|     return total;
  #|   };
  #|   let edges = sourceEdges.map(edge => {
  #|     const from = clusterByEndpoint.get(edge.from);
  #|     const to = clusterByEndpoint.get(edge.to);
  #|     const mapped = projectPath(edge.pathMillis);
  #|     const pathMillis = mapped.points;
  #|     const bridgePaths = (edge.bridgeSpans || []).map(span => {
  #|       const slice = pathMillis.slice(mapped.indices[span.fromIndex], mapped.indices[span.toIndex] + 1).map(copyPoint);
  #|       return slice;
  #|     }).filter(path => path.length >= 2);
  #|     const designConflicts = [];
  #|     const terrainRows = registration?.terrain?.rows;
  #|     if (terrainRows) {
  #|       const protectedSegments = new Set();
  #|       for (const span of edge.bridgeSpans || []) {
  #|         for (let i = mapped.indices[span.fromIndex] + 1; i <= mapped.indices[span.toIndex]; i++) protectedSegments.add(i);
  #|       }
  #|       for (let i = 1; i < pathMillis.length; i++) {
  #|         if (protectedSegments.has(i)) continue;
  #|         const a = pathMillis[i-1], b = pathMillis[i];
  #|         const steps = Math.max(1, Math.ceil(Math.max(Math.abs(a[0]-b[0]), Math.abs(a[1]-b[1])) / 100));
  #|         for (let step = 0; step < steps; step++) {
  #|           const t = (step + 0.5) / steps;
  #|           const x = Math.round((a[0] + (b[0]-a[0])*t)/1000);
  #|           const y = Math.round((a[1] + (b[1]-a[1])*t)/1000);
  #|           if ('rlb'.includes(terrainRows[y]?.[x] || ' ')) {
  #|             designConflicts.push([a,b]);
  #|             break;
  #|           }
  #|         }
  #|       }
  #|     }
  #|     return {
  #|       sourceEdgeId: edge.id,
  #|       sourceFrom: edge.from,
  #|       sourceTo: edge.to,
  #|       sourcePathMillis: edge.pathMillis.map(copyPoint),
  #|       sourceVertexIndices: mapped.indices,
  #|       designConflicts,
  #|       from,
  #|       to,
  #|       pathMillis,
  #|       bridgePaths,
  #|       confidence: edge.confidence,
  #|       length: pathLength(pathMillis),
  #|     };
  #|   });
  #|
  #|   const componentSets = edgeList => {
  #|     const used = new Set(clusteredNodes.map(node => node.id));
  #|     const adjacency = new Map([...used].map(id => [id, []]));
  #|     for (const edge of edgeList) {
  #|       adjacency.get(edge.from).push(edge.to);
  #|       adjacency.get(edge.to).push(edge.from);
  #|     }
  #|     const seen = new Set();
  #|     const components = [];
  #|     for (const start of [...used].sort()) {
  #|       if (seen.has(start)) continue;
  #|       const queue = [start];
  #|       seen.add(start);
  #|       for (let cursor = 0; cursor < queue.length; cursor += 1) {
  #|         for (const neighbor of adjacency.get(queue[cursor]) || []) {
  #|           if (!seen.has(neighbor)) {
  #|             seen.add(neighbor);
  #|             queue.push(neighbor);
  #|           }
  #|         }
  #|       }
  #|       components.push(new Set(queue));
  #|     }
  #|     return components.sort((left, right) => right.size - left.size ||
  #|       [...left][0].localeCompare([...right][0]));
  #|   };
  #|   const active = new Set(clusteredNodes.map(node => node.id));
  #|   if (!edges.length) return false;
  #|
  #|   const adjacency = new Map([...active].map(id => [id, []]));
  #|   for (let index = 0; index < edges.length; index += 1) {
  #|     const edge = edges[index];
  #|     adjacency.get(edge.from).push({ node: edge.to, edge: index });
  #|     adjacency.get(edge.to).push({ node: edge.from, edge: index });
  #|   }
  #|   // Unweighted Brandes centrality gives the cartoon map a genuine visual
  #|   // hierarchy even though the immutable v1 payload retained only broad OSM
  #|   // confidence tiers rather than individual highway tags.
  #|   const centrality = edges.map(() => 0);
  #|   for (const start of [...active]) {
  #|     const stack = [];
  #|     const predecessors = new Map([...active].map(id => [id, []]));
  #|     const paths = new Map([...active].map(id => [id, 0]));
  #|     const distance = new Map([...active].map(id => [id, -1]));
  #|     paths.set(start, 1);
  #|     distance.set(start, 0);
  #|     const queue = [start];
  #|     for (let cursor = 0; cursor < queue.length; cursor += 1) {
  #|       const node = queue[cursor];
  #|       stack.push(node);
  #|       for (const next of adjacency.get(node)) {
  #|         if (distance.get(next.node) < 0) {
  #|           distance.set(next.node, distance.get(node) + 1);
  #|           queue.push(next.node);
  #|         }
  #|         if (distance.get(next.node) === distance.get(node) + 1) {
  #|           paths.set(next.node, paths.get(next.node) + paths.get(node));
  #|           predecessors.get(next.node).push({ node, edge: next.edge });
  #|         }
  #|       }
  #|     }
  #|     const dependency = new Map([...active].map(id => [id, 0]));
  #|     while (stack.length) {
  #|       const node = stack.pop();
  #|       for (const previous of predecessors.get(node)) {
  #|         const share = paths.get(node) === 0 ? 0 :
  #|           paths.get(previous.node) / paths.get(node) *
  #|             (1 + dependency.get(node));
  #|         centrality[previous.edge] += share;
  #|         dependency.set(previous.node,
  #|           dependency.get(previous.node) + share);
  #|       }
  #|     }
  #|   }
  #|   const orderedCentrality = [...centrality].sort((left, right) =>
  #|     left - right);
  #|   const primaryThreshold = orderedCentrality[
  #|     Math.floor((orderedCentrality.length - 1) * 0.68)
  #|   ];
  #|   edges = edges.map((edge, index) => ({
  #|     ...edge,
  #|     id: `cartoon-edge-${String(index).padStart(3, "0")}`,
  #|     rank: edge.bridgePaths.length ||
  #|       (edge.confidence === "high" &&
  #|         centrality[index] >= primaryThreshold)
  #|       ? "primary"
  #|       : edge.confidence === "high" || centrality[index] >= primaryThreshold
  #|         ? "secondary" : "local",
  #|   }));
  #|   const degree = new Map([...active].map(id => [id, 0]));
  #|   for (const edge of edges) {
  #|     degree.set(edge.from, degree.get(edge.from) + 1);
  #|     degree.set(edge.to, degree.get(edge.to) + 1);
  #|   }
  #|   const nodes = [...active].sort().map(id => ({
  #|     ...nodeById.get(id),
  #|     degree: degree.get(id),
  #|   }));
  #|   const reviewedPointIds = new Set(source.points.map(point => point.id));
  #|   const junctions = nodes.filter(node =>
  #|     node.members.some(member => reviewedPointIds.has(member)));
  #|   const cells = new Set();
  #|   const corridorCells = new Set();
  #|   const widths = { primary, secondary, local };
  #|   for (const edge of edges) {
  #|     // Conservative 1/4-tile sampling, including the curb and contact edge.
  #|     // The same world widths drive rasterization and drawing. Centerlines
  #|     // alone cannot prevent a wide street from cutting through a valid lot.
  #|     const radius = (widths[edge.rank] + 0.10) / 2 + 0.18;
  #|     for (let index = 1; index < edge.pathMillis.length; index += 1) {
  #|       const start = edge.pathMillis[index - 1];
  #|       const end = edge.pathMillis[index];
  #|       const steps = Math.max(1, Math.ceil(Math.max(
  #|         Math.abs(end[0] - start[0]),
  #|         Math.abs(end[1] - start[1]),
  #|       ) / 250));
  #|       for (let step = 0; step <= steps; step += 1) {
  #|         const ratio = step / steps;
  #|         const px = (start[0] + (end[0] - start[0]) * ratio) / 1000;
  #|         const py = (start[1] + (end[1] - start[1]) * ratio) / 1000;
  #|         for (let cy = Math.floor(py - radius); cy <= Math.floor(py + radius); cy += 1) {
  #|           for (let cx = Math.floor(px - radius); cx <= Math.floor(px + radius); cx += 1) {
  #|             if (cx >= 0 && cx < 256 && cy >= 0 && cy < 144) corridorCells.add(`${cx},${cy}`);
  #|           }
  #|         }
  #|         const x = Math.floor((start[0] + (end[0] - start[0]) * ratio) /
  #|           1000);
  #|         const y = Math.floor((start[1] + (end[1] - start[1]) * ratio) /
  #|           1000);
  #|         if (x >= 0 && x < 256 && y >= 0 && y < 144) {
  #|           cells.add(`${x},${y}`);
  #|         }
  #|       }
  #|     }
  #|   }
  #|   globalThis.__moontownEnergyValleyCartoonRoadGraph = {
  #|     source,
  #|     version: 6,
  #|     registration: registration ? "design-corridor-fit-v1" : "source-geography-v1",
  #|     designRegistration: registration,
  #|     projectPoint,
  #|     projectPath,
  #|     nodes,
  #|     junctions,
  #|     edges,
  #|     cells,
  #|     corridorCells,
  #|     metrics: {
  #|       sourceIntersections: source.metrics.intersections,
  #|       nodes: nodes.length,
  #|       junctions: junctions.length,
  #|       edges: edges.length,
  #|       components: componentSets(edges).length,
  #|       cycleRank: edges.length - nodes.length + componentSets(edges).length,
  #|       bridges: edges.reduce((sum, edge) =>
  #|         sum + edge.bridgePaths.length, 0),
  #|       primary: edges.filter(edge => edge.rank === "primary").length,
  #|       secondary: edges.filter(edge => edge.rank === "secondary").length,
  #|       local: edges.filter(edge => edge.rank === "local").length,
  #|     },
  #|   };
  #|   const root = globalThis.document?.documentElement;
  #|   if (root) {
  #|     root.dataset.townGroundRegistration = registration ? "design-corridor-fit-v1" : "source-geography-v1";
  #|     delete root.dataset.townSourceYawDegrees;
  #|   }
  #|   return audit();
  #| }

///|
extern "js" fn reference_osm_cartoon_road_junction_count() -> Int =
  #| () => globalThis.__moontownEnergyValleyCartoonRoadGraph?.junctions?.length ?? 0

///|
extern "js" fn reference_osm_cartoon_road_node_count() -> Int =
  #| () => globalThis.__moontownEnergyValleyCartoonRoadGraph?.nodes?.length ?? 0

///|
extern "js" fn reference_osm_cartoon_road_edge_count() -> Int =
  #| () => globalThis.__moontownEnergyValleyCartoonRoadGraph?.edges?.length ?? 0

///|
extern "js" fn reference_osm_cartoon_road_cycle_count() -> Int =
  #| () => globalThis.__moontownEnergyValleyCartoonRoadGraph?.metrics?.cycleRank ?? 0

///|
extern "js" fn reference_osm_cartoon_road_bridge_count() -> Int =
  #| () => globalThis.__moontownEnergyValleyCartoonRoadGraph?.metrics?.bridges ?? 0

///|
/// Validate the displayed-road portion of one complete building lot in a
/// single graph query. Land, water, and inter-building checks stay in MoonBit.
extern "js" fn reference_osm_cartoon_road_lot_valid(
  x : Int,
  y : Int,
  width : Int,
  depth : Int,
  apron : Int,
) -> Bool =
  #| (x, y, width, depth, apron) => {
  #|   const cartoon = globalThis.__moontownEnergyValleyCartoonRoadGraph;
  #|   if (!(cartoon?.corridorCells instanceof Set)) return false;
  #|   const cells = cartoon.corridorCells;
  #|   const lotMinX = x - apron;
  #|   const lotMaxX = x + width - 1 + apron;
  #|   const lotMinY = y - apron;
  #|   const lotMaxY = y + depth - 1 + apron;
  #|   for (let row = lotMinY; row <= lotMaxY; row += 1) {
  #|     for (let col = lotMinX; col <= lotMaxX; col += 1) {
  #|       if (cells.has(`${col},${row}`)) return false;
  #|     }
  #|   }
  #|   const frontageMinX = lotMinX - 1;
  #|   const frontageMaxX = lotMaxX + 1;
  #|   const frontageMinY = lotMinY - 1;
  #|   const frontageMaxY = lotMaxY + 1;
  #|   for (let row = frontageMinY; row <= frontageMaxY; row += 1) {
  #|     for (let col = frontageMinX; col <= frontageMaxX; col += 1) {
  #|       const onRing = col === frontageMinX || col === frontageMaxX ||
  #|         row === frontageMinY || row === frontageMaxY;
  #|       if (onRing && cells.has(`${col},${row}`)) return true;
  #|     }
  #|   }
  #|   return false;
  #| }

///|
extern "js" fn reference_osm_cartoon_road_corridor_cell_at(
  x : Int,
  y : Int,
) -> Bool =
  #| (x, y) => globalThis.__moontownEnergyValleyCartoonRoadGraph?.corridorCells?.has(`${x},${y}`) === true

///|
fn energy_valley_cartoon_road_rank_visible(
  rank : String,
  _zoom : Double,
) -> Bool {
  match rank {
    "primary" | "secondary" | "local" => true
    _ => false
  }
}
