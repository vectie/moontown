///|
test "scene road widths share one world scale with clearance" {
  assert_eq(town_scene_road_width("primary"), 1.50)
  assert_eq(town_scene_road_width("secondary"), 1.15)
  assert_eq(town_scene_road_width("local"), 0.80)
  install_cartoon_road_graph_test_fixture()
  assert_true(reference_osm_cartoon_road_graph_prepare())
  assert_true(reference_osm_cartoon_road_corridor_cell_at(15, 9))
  // The centerline is y=10. Its northern curb must also reserve cell y=9.
  assert_false(reference_osm_cartoon_road_lot_valid(14, 4, 5, 5, 1))
  assert_true(reference_osm_cartoon_road_lot_valid(14, 3, 5, 5, 1))
  assert_eq(reference_osm_cartoon_road_node_count(), 4)
  assert_eq(reference_osm_cartoon_road_edge_count(), 4)
  clear_cartoon_road_graph_test_fixture()
}

///|
test "scene infill visits every stratum once without northern bias" {
  let sites : Map[String, Bool] = Map([])
  let quadrants : Map[String, Bool] = Map([])
  for index in 0..<(32 * 18) {
    let (x, y) = town_scene_infill_site(index, 0, 0)
    let key = town_canvas_road_key(x, y)
    assert_false(sites.contains(key))
    sites[key] = true
    if index < 16 {
      quadrants["\{x / 128}:\{y / 72}"] = true
    }
  }
  assert_eq(sites.length(), 576)
  assert_eq(quadrants.length(), 4)
}

///|
test "scene neighborhoods prefer related low silhouettes with rare towers" {
  let mut towers = 0
  for index in 0..<576 {
    let (x, y) = town_scene_infill_site(index, 0, 0)
    let style = town_scene_neighborhood_style(x, y)
    assert_true(golden_spring_ambient_style_supported(style))
    if style == "tower" {
      towers += 1
    }
    assert_eq(style, town_scene_neighborhood_style(x, y))
  }
  assert_true(towers > 0 && towers < 24)
}

///|
test "scene infill masses and aprons scale together" {
  assert_eq(town_scene_building_span("lowrise"), 3)
  assert_eq(town_scene_building_span("courtyard"), 4)
  assert_eq(town_scene_building_span("campus"), 5)
  for span in [3, 4, 5] {
    let building = intersection_preview_test_building(
      40,
      50,
      span,
      span,
      90 + span * 2,
    )
    assert_true(intersection_road_preview_building_geometry_valid(building))
    let lots = intersection_road_preview_building_land_cells(
      Map::from_array([(building.depth_key, [building])]),
      "scene-span-\{span}",
    )
    assert_eq(lots.length(), (span + 2) * (span + 2))
  }
}

///|
test "scene terrain has bounded low-frequency variation and stable tree density" {
  let mut trees = 0
  for y in 0..<30 {
    for x in 0..<30 {
      let value = town_scene_ground_variation(x, y)
      assert_true(value >= 0.0 && value <= 1.0)
      assert_true((value - town_scene_ground_variation(x + 1, y)).abs() < 0.03)
      if town_scene_background_tree_visible(x, y) {
        trees += 1
      }
    }
  }
  assert_eq(trees, 300)
}

///|
test "scene cache keys contain actual blueprint identity instead of placeholders" {
  let snapshot = ecosystem_contract_town_snapshot(init_model(), 20260727)
  let key = intersection_road_preview_cache_key(snapshot)
  assert_true(key.contains(snapshot.world.blueprint_digest))
  assert_false(key.contains("{snapshot."))
  assert_false(key.contains("{intersection_"))
}
