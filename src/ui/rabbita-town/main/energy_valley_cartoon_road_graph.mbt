///|
/// Build the one display graph used by the MoonTown map from the validated OSM
/// reference. OSM remains immutable evidence: the display preserves all 338
/// reviewed intersections, every routed edge, and the original path vertices.
/// Only color/width/LOD are cartoon presentation. The result is cached by asset
/// identity and never becomes semantic/pathfinding authority.
extern "js" fn reference_osm_cartoon_road_graph_prepare() -> Bool =
  #| () => {
  #|   const source = globalThis.__moontownEnergyValleyOsmBlockGraph;
  #|   if (globalThis.__moontownEnergyValleyOsmBlockGraphValidated !== true ||
  #|     source?.schema !== "moontown.energy-valley.osm_block_graph.v1" ||
  #|     !Array.isArray(source?.points) ||
  #|     !Array.isArray(source?.graph?.routingNodes) ||
  #|     !Array.isArray(source?.graph?.edges)
  #|   ) return false;
  #|   const existing = globalThis.__moontownEnergyValleyCartoonRoadGraph;
  #|   if (existing?.source === source && existing?.version === 2) return true;
  #|
  #|   const endpoints = new Map();
  #|   for (const node of [...source.points, ...source.graph.routingNodes]) {
  #|     endpoints.set(node.id, {
  #|       id: node.id,
  #|       x: node.xMillis,
  #|       y: node.yMillis,
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
  #|   const endpointIds = [...new Set(sourceEdges.flatMap(edge => [
  #|     edge.from,
  #|     edge.to,
  #|   ]))].sort();
  #|   if (!endpointIds.length) return false;
  #|
  #|   const parents = endpointIds.map((_, index) => index);
  #|   const find = value => {
  #|     let cursor = value;
  #|     while (parents[cursor] !== cursor) {
  #|       parents[cursor] = parents[parents[cursor]];
  #|       cursor = parents[cursor];
  #|     }
  #|     return cursor;
  #|   };
  #|   const unite = (left, right) => {
  #|     const a = find(left);
  #|     const b = find(right);
  #|     if (a !== b) parents[b] = a;
  #|   };
  #|   // A zero-radius strict comparison preserves even coincident reviewed
  #|   // intersections as separate records. They are evidence, not candidates
  #|   // for display-time topology contraction.
  #|   const mergeRadiusMillis = 0;
  #|   const mergeRadiusSquared = mergeRadiusMillis * mergeRadiusMillis;
  #|   for (let left = 0; left < endpointIds.length; left += 1) {
  #|     const a = endpoints.get(endpointIds[left]);
  #|     for (let right = left + 1; right < endpointIds.length; right += 1) {
  #|       const b = endpoints.get(endpointIds[right]);
  #|       const dx = a.x - b.x;
  #|       const dy = a.y - b.y;
  #|       if (dx * dx + dy * dy < mergeRadiusSquared) unite(left, right);
  #|     }
  #|   }
  #|
  #|   const membersByRoot = new Map();
  #|   for (let index = 0; index < endpointIds.length; index += 1) {
  #|     const root = find(index);
  #|     if (!membersByRoot.has(root)) membersByRoot.set(root, []);
  #|     membersByRoot.get(root).push(endpointIds[index]);
  #|   }
  #|   const groups = [...membersByRoot.values()].map(members => {
  #|     const values = members.map(id => endpoints.get(id));
  #|     const x = values.reduce((sum, value) => sum + value.x, 0) /
  #|       values.length;
  #|     const y = values.reduce((sum, value) => sum + value.y, 0) /
  #|       values.length;
  #|     return {
  #|       members,
  #|       x: Math.round(x),
  #|       y: Math.round(y),
  #|       boundary: values.some(value => value.boundary),
  #|     };
  #|   }).sort((left, right) => left.y - right.y || left.x - right.x ||
  #|     left.members[0].localeCompare(right.members[0]));
  #|   const clusterByEndpoint = new Map();
  #|   const clusteredNodes = groups.map((group, index) => {
  #|     const id = `cartoon-node-${String(index).padStart(3, "0")}`;
  #|     for (const member of group.members) clusterByEndpoint.set(member, id);
  #|     return { id, xMillis: group.x, yMillis: group.y,
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
  #|   const candidatesByPair = new Map();
  #|   for (const edge of sourceEdges) {
  #|     const from = clusterByEndpoint.get(edge.from);
  #|     const to = clusterByEndpoint.get(edge.to);
  #|     if (!from || !to || from === to) continue;
  #|     const first = nodeById.get(from);
  #|     const last = nodeById.get(to);
  #|     const raw = edge.pathMillis.map(point => [point[0], point[1]]);
  #|     raw[0] = [first.xMillis, first.yMillis];
  #|     raw[raw.length - 1] = [last.xMillis, last.yMillis];
  #|     const pathMillis = raw;
  #|     const bridgePaths = (edge.bridgeSpans || []).map(span => {
  #|       const slice = edge.pathMillis.slice(span.fromIndex, span.toIndex + 1)
  #|         .map(point => [point[0], point[1]]);
  #|       return slice;
  #|     }).filter(path => path.length >= 2);
  #|     const pair = edge.id;
  #|     const candidate = {
  #|       from,
  #|       to,
  #|       pathMillis,
  #|       bridgePaths,
  #|       confidence: edge.confidence,
  #|       length: pathLength(pathMillis),
  #|     };
  #|     const existingCandidate = candidatesByPair.get(pair);
  #|     const rank = value => value === "high" ? 0 :
  #|       value === "medium" ? 1 : 2;
  #|     if (!existingCandidate ||
  #|       rank(candidate.confidence) < rank(existingCandidate.confidence) ||
  #|       (candidate.confidence === existingCandidate.confidence &&
  #|         candidate.length < existingCandidate.length)) {
  #|       candidatesByPair.set(pair, candidate);
  #|     }
  #|   }
  #|   let edges = [...candidatesByPair.values()];
  #|
  #|   const componentSets = edgeList => {
  #|     const used = new Set(edgeList.flatMap(edge => [edge.from, edge.to]));
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
  #|   const active = new Set(edges.flatMap(edge => [edge.from, edge.to]));
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
  #|   for (const edge of edges) {
  #|     for (let index = 1; index < edge.pathMillis.length; index += 1) {
  #|       const start = edge.pathMillis[index - 1];
  #|       const end = edge.pathMillis[index];
  #|       const steps = Math.max(1, Math.ceil(Math.max(
  #|         Math.abs(end[0] - start[0]),
  #|         Math.abs(end[1] - start[1]),
  #|       ) / 250));
  #|       for (let step = 0; step <= steps; step += 1) {
  #|         const ratio = step / steps;
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
  #|     version: 2,
  #|     nodes,
  #|     junctions,
  #|     edges,
  #|     cells,
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
  #|   return true;
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
  #|   if (!(cartoon?.cells instanceof Set)) return false;
  #|   const cells = cartoon.cells;
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
fn energy_valley_cartoon_road_rank_visible(
  rank : String,
  zoom : Double,
) -> Bool {
  match rank {
    "primary" => true
    "secondary" => zoom >= 0.34
    "local" => zoom >= 0.34
    _ => false
  }
}
