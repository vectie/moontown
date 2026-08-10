///|
extern "js" fn install_cartoon_road_graph_test_fixture() -> Unit =
  #| () => {
  #|   const points = [
  #|     { id: "a", xMillis: 10000, yMillis: 10000 },
  #|     { id: "b", xMillis: 30000, yMillis: 10000 },
  #|     { id: "c", xMillis: 30000, yMillis: 30000 },
  #|     { id: "d", xMillis: 10000, yMillis: 30000 },
  #|   ];
  #|   const edge = (id, from, to, pathMillis) => ({
  #|     id, from, to, pathMillis, confidence: "high", bridgeSpans: [],
  #|   });
  #|   globalThis.__moontownEnergyValleyOsmBlockGraph = {
  #|     schema: "moontown.energy-valley.osm_block_graph.v1",
  #|     metrics: { intersections: 4 },
  #|     points,
  #|     graph: {
  #|       routingNodes: [],
  #|       edges: [
  #|         edge("ab", "a", "b", [[10000, 10000], [30000, 10000]]),
  #|         edge("bc", "b", "c", [[30000, 10000], [30000, 30000]]),
  #|         edge("cd", "c", "d", [[30000, 30000], [10000, 30000]]),
  #|         edge("da", "d", "a", [[10000, 30000], [10000, 10000]]),
  #|       ],
  #|     },
  #|   };
  #|   globalThis.__moontownEnergyValleyOsmBlockGraphValidated = true;
  #|   delete globalThis.__moontownEnergyValleyCartoonRoadGraph;
  #| }

///|
extern "js" fn clear_cartoon_road_graph_test_fixture() -> Unit =
  #| () => {
  #|   delete globalThis.__moontownEnergyValleyOsmBlockGraph;
  #|   delete globalThis.__moontownEnergyValleyOsmBlockGraphValidated;
  #|   delete globalThis.__moontownEnergyValleyCartoonRoadGraph;
  #| }

///|
test "cartoon graph preserves every reviewed intersection and routed edge" {
  install_cartoon_road_graph_test_fixture()
  assert_eq(reference_osm_cartoon_road_graph_prepare(), true)
  assert_eq(reference_osm_cartoon_road_node_count(), 4)
  assert_eq(reference_osm_cartoon_road_junction_count(), 4)
  assert_eq(reference_osm_cartoon_road_edge_count(), 4)
  assert_eq(reference_osm_cartoon_road_cycle_count(), 1)
  clear_cartoon_road_graph_test_fixture()
}

///|
test "cartoon road hierarchy uses progressive disclosure" {
  assert_eq(energy_valley_cartoon_road_rank_visible("primary", 0.20), true)
  assert_eq(energy_valley_cartoon_road_rank_visible("secondary", 0.33), false)
  assert_eq(energy_valley_cartoon_road_rank_visible("secondary", 0.34), true)
  assert_eq(energy_valley_cartoon_road_rank_visible("local", 0.33), false)
  assert_eq(energy_valley_cartoon_road_rank_visible("local", 0.34), true)
  assert_eq(energy_valley_cartoon_road_rank_visible("unknown", 1.00), false)
}
