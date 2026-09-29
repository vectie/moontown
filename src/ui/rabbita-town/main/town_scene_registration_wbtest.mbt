///|
extern "js" fn install_scene_registration_details() -> Unit =
  #| () => {
  #|   const source = globalThis.__moontownEnergyValleyOsmBlockGraph;
  #|   source.calibration = { rotationDegrees: 22.924436871 };
  #|   // Slightly different endpoint geometry must not be snapped to the node.
  #|   source.graph.edges[0].pathMillis = [[10001,10002],[20000,12000],[30000,10000]];
  #|   source.graph.edges[0].bridgeSpans = [{fromIndex:0,toIndex:2}];
  #|   source.graph.edges.push({id:'parallel-ab',from:'a',to:'b',confidence:'review',
  #|     pathMillis:[[10000,10000],[15000,14000],[22000,14500],[30000,10000]],bridgeSpans:[]});
  #|   source.graph.edges.push({id:'loop-a',from:'a',to:'a',confidence:'medium',
  #|     pathMillis:[[10000,10000],[8000,10000],[8000,8000],[10000,10000]],bridgeSpans:[]});
  #|   // Coincident nodes and isolated reviewed points are still distinct.
  #|   source.points.push({id:'isolated',xMillis:10000,yMillis:10000});
  #|   source.metrics.intersections = 5;
  #|   globalThis.__sceneRegistrationTestSource = JSON.stringify(source);
  #| }

///|
extern "js" fn scene_registration_source_unchanged() -> Bool =
  #| () => JSON.stringify(globalThis.__moontownEnergyValleyOsmBlockGraph) === globalThis.__sceneRegistrationTestSource

///|
extern "js" fn clear_scene_registration_fixture() -> Unit =
  #| () => { delete globalThis.__sceneRegistrationTestSource; }

///|
extern "js" fn corrupt_scene_registration_fixture(kind : String) -> Unit =
  #| kind => {
  #|   const graph = globalThis.__moontownEnergyValleyCartoonRoadGraph;
  #|   if (kind === 'node') graph.nodes[0].xMillis += 1;
  #|   if (kind === 'vertex') graph.edges[0].pathMillis[1][0] += 1;
  #|   if (kind === 'bridge') graph.edges[0].bridgePaths[0][1][0] += 1;
  #|   if (kind === 'edge') graph.edges.pop();
  #|   if (kind === 'source') graph.edges[0].sourcePathMillis[1][0] += 1;
  #| }

///|
test "calibration metadata never moves registered geography or simplifies topology" {
  install_cartoon_road_graph_test_fixture()
  install_scene_registration_details()
  assert_true(reference_osm_cartoon_road_graph_prepare())
  assert_true(town_scene_registration_valid())
  assert_eq(reference_osm_cartoon_road_node_count(), 5)
  assert_eq(reference_osm_cartoon_road_junction_count(), 5)
  assert_eq(reference_osm_cartoon_road_edge_count(), 6)
  assert_eq(reference_osm_cartoon_road_cycle_count(), 3)
  assert_eq(reference_osm_cartoon_road_bridge_count(), 1)
  assert_true(reference_osm_cartoon_road_corridor_cell_at(20, 12))
  assert_true(reference_osm_cartoon_road_graph_prepare())
  assert_true(town_scene_registration_valid())
  assert_true(scene_registration_source_unchanged())
  clear_scene_registration_fixture()
  clear_cartoon_road_graph_test_fixture()
}

///|
test "source audit detects node drift vertex drift missing edges and bridge drift" {
  for kind in ["node", "vertex", "edge", "bridge", "source"] {
    install_cartoon_road_graph_test_fixture()
    install_scene_registration_details()
    assert_true(reference_osm_cartoon_road_graph_prepare())
    corrupt_scene_registration_fixture(kind)
    assert_false(town_scene_registration_valid())
    assert_true(scene_registration_source_unchanged())
    // A failed parity check invalidates the derived cache.
    assert_true(reference_osm_cartoon_road_graph_prepare())
    assert_true(town_scene_registration_valid())
    clear_scene_registration_fixture()
    clear_cartoon_road_graph_test_fixture()
  }
}

///|
extern "js" fn install_actual_design_registration_fixture() -> Unit =
  #| () => {
  #|   const fs = process.getBuiltinModule('fs');
  #|   const read = name => JSON.parse(fs.readFileSync('../assets/tilemap/' + name, 'utf8'));
  #|   globalThis.__moontownEnergyValleyOsmBlockGraph = read('energy-valley-osm-block-graph-v1.json');
  #|   globalThis.__wenyuReferenceRoadGraph = read('wenyu_reference_roads.json');
  #|   globalThis.__wenyuReferenceLabels = read('wenyu_reference_labels.json');
  #|   globalThis.__moontownEnergyValleyOsmBlockGraphValidated = true;
  #|   globalThis.__sceneRegistrationTestSource = JSON.stringify(globalThis.__moontownEnergyValleyOsmBlockGraph);
  #|   globalThis.__sceneRegistrationTestDesign = JSON.stringify([globalThis.__wenyuReferenceRoadGraph, globalThis.__wenyuReferenceLabels]);
  #|   delete globalThis.__moontownEnergyValleyCartoonRoadGraph;
  #| }

///|
extern "js" fn actual_design_registration_consistent() -> Bool =
  #| () => {
  #|   const graph = globalThis.__moontownEnergyValleyCartoonRoadGraph;
  #|   const fit = globalThis.__moontownDesignRegistration;
  #|   const nodes = new Map(graph.nodes.map(node => [node.id, node]));
  #|   const near = (a, b) => Math.abs(a-b) < 0.000001;
  #|   return fit.conflictsAfter < fit.conflictsBefore && fit.area >= 0.4 &&
  #|     graph.registration === 'design-corridor-fit-v1' &&
  #|     JSON.stringify([globalThis.__wenyuReferenceRoadGraph, globalThis.__wenyuReferenceLabels]) === globalThis.__sceneRegistrationTestDesign &&
  #|     graph.edges.every(edge => {
  #|       const from = nodes.get(edge.from), to = nodes.get(edge.to);
  #|       const a = edge.pathMillis[0], b = edge.pathMillis.at(-1);
  #|       return near(a[0], from.xMillis) && near(a[1], from.yMillis) && near(b[0], to.xMillis) && near(b[1], to.yMillis) &&
  #|         edge.sourceVertexIndices.length === edge.sourcePathMillis.length;
  #|     });
  #| }

///|
extern "js" fn clear_actual_design_registration_fixture() -> Unit =
  #| () => {
  #|   delete globalThis.__wenyuReferenceRoadGraph;
  #|   delete globalThis.__wenyuReferenceLabels;
  #|   delete globalThis.__moontownDesignRegistration;
  #|   delete globalThis.__sceneRegistrationTestDesign;
  #| }

///|
test "actual OSM graph fits toward immutable design with every edge and shared endpoint retained" {
  install_actual_design_registration_fixture()
  assert_true(reference_osm_cartoon_road_graph_prepare())
  assert_true(town_scene_registration_valid())
  assert_true(actual_design_registration_consistent())
  assert_true(scene_registration_source_unchanged())
  assert_eq(reference_osm_cartoon_road_edge_count(), 775)
  assert_eq(reference_osm_cartoon_road_node_count(), 495)
  assert_eq(reference_osm_cartoon_road_cycle_count(), 291)
  assert_eq(reference_osm_cartoon_road_bridge_count(), 22)
  let revision = town_design_registration_revision()
  assert_true(reference_osm_cartoon_road_graph_prepare())
  assert_eq(town_design_registration_revision(), revision)
  clear_actual_design_registration_fixture()
  clear_scene_registration_fixture()
  clear_cartoon_road_graph_test_fixture()
}
