///|
/// Audit retained source evidence AND the design-space mapping independently.
/// A design fit intentionally changes visible coordinates, never source values
/// or connectivity. Extra vertices may only split at mesh boundaries.
extern "js" fn town_scene_registration_valid() -> Bool =
  #| () => {
  #|   const graph = globalThis.__moontownEnergyValleyCartoonRoadGraph;
  #|   const source = globalThis.__moontownEnergyValleyOsmBlockGraph;
  #|   if (!graph || !source) return false;
  #|   const sourceNodes = [...source.points, ...source.graph.routingNodes];
  #|   const sourceEdges = source.graph.edges;
  #|   const nodes = new Map(graph.nodes.flatMap(node =>
  #|     node.members.map(id => [id, node])));
  #|   const samePath = (left, right) => left.length === right.length &&
  #|     left.every((point, index) => Math.abs(point[0] - right[index][0]) < 0.000001 &&
  #|       Math.abs(point[1] - right[index][1]) < 0.000001);
  #|   const nodeErrors = sourceNodes.filter(node => {
  #|     const displayed = nodes.get(node.id);
  #|     const expected = graph.projectPoint([node.xMillis, node.yMillis]);
  #|     return !displayed || displayed.members.length !== 1 ||
  #|       displayed.sourceXMillis !== node.xMillis || displayed.sourceYMillis !== node.yMillis ||
  #|       Math.abs(displayed.xMillis - expected[0]) > 0.000001 || Math.abs(displayed.yMillis - expected[1]) > 0.000001;
  #|   }).length;
  #|   const edgeErrors = sourceEdges.filter((edge, index) => {
  #|     const displayed = graph.edges[index];
  #|     const expected = graph.projectPath(edge.pathMillis);
  #|     const bridges = (edge.bridgeSpans || []).map(span =>
  #|       expected.points.slice(expected.indices[span.fromIndex], expected.indices[span.toIndex] + 1));
  #|     return !displayed || displayed.sourceEdgeId !== edge.id ||
  #|       displayed.sourceFrom !== edge.from || displayed.sourceTo !== edge.to ||
  #|       displayed.from !== nodes.get(edge.from)?.id ||
  #|       displayed.to !== nodes.get(edge.to)?.id ||
  #|       JSON.stringify(displayed.sourcePathMillis) !== JSON.stringify(edge.pathMillis) ||
  #|       !samePath(displayed.pathMillis, expected.points) ||
  #|       JSON.stringify(displayed.sourceVertexIndices) !== JSON.stringify(expected.indices) ||
  #|       displayed.bridgePaths.length !== bridges.length ||
  #|       bridges.some((path, i) => !samePath(displayed.bridgePaths[i], path));
  #|   }).length;
  #|   const exact = nodeErrors === 0 && edgeErrors === 0 &&
  #|     graph.nodes.length === sourceNodes.length && graph.edges.length === sourceEdges.length;
  #|   graph.registrationValid = exact;
  #|   graph.sourceGeometryExact = exact && !graph.designRegistration;
  #|   const root = globalThis.document?.documentElement;
  #|   if (root) {
  #|     root.dataset.townSourceGeometryExact = String(graph.sourceGeometryExact);
  #|     root.dataset.townSourceEvidencePreserved = String(exact);
  #|     root.dataset.townDesignRegistrationValid = String(exact);
  #|     root.dataset.townRoadNodeMismatches = String(nodeErrors);
  #|     root.dataset.townRoadEdgeMismatches = String(edgeErrors);
  #|     root.dataset.townRoadSourceNodes = String(sourceNodes.length);
  #|     root.dataset.townRoadSourceEdges = String(sourceEdges.length);
  #|     root.dataset.townRoadDisplayNodes = String(graph.nodes.length);
  #|     root.dataset.townRoadDisplayEdges = String(graph.edges.length);
  #|     root.dataset.townRoadPathVertices = String(sourceEdges.reduce((n, edge) => n + edge.pathMillis.length, 0));
  #|     root.dataset.townRoadBridgeSpans = String(graph.metrics.bridges);
  #|   }
  #|   return exact;
  #| }
