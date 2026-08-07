///|
fn energy_valley_test_module(
  id : String,
  district : String,
  grid_x : Int,
  grid_y : Int,
  footprint_w : Int,
  footprint_h : Int,
) -> WenyuTownModule {
  {
    id,
    enabled: true,
    title: id,
    book_id: id,
    district,
    building_kind: "pavilion",
    grid_x,
    grid_y,
    footprint_w,
    footprint_h,
    display_w: 180,
    display_h: 150,
    entrance_x: grid_x,
    entrance_y: grid_y + footprint_h,
    interior_kind: "test",
    style_family: "white-tech",
    asset_base: "base.png",
    protocol_pattern: "signal-watch",
    use_case: "test",
    agent_flow: "arrive / work / review / depart",
    summary: "procedural placement fixture",
  }
}

///|
fn energy_valley_test_modules() -> Array[WenyuTownModule] {
  [
    energy_valley_test_module("town-shell", "civic-core", 128, 72, 8, 6),
    energy_valley_test_module("policy-hall", "civic-core", 114, 66, 7, 5),
    energy_valley_test_module("vitality", "civic-core", 142, 65, 5, 5),
    energy_valley_test_module("contest", "north-innovation", 101, 57, 7, 5),
    energy_valley_test_module("broadcast", "north-innovation", 111, 50, 5, 5),
    energy_valley_test_module("resident", "west-community", 97, 84, 7, 5),
    energy_valley_test_module("ai-garden", "lake-learning", 112, 87, 7, 6),
    energy_valley_test_module("social", "lake-exchange", 131, 87, 8, 6),
    energy_valley_test_module("robotics", "lake-exchange", 122, 104, 8, 6),
    energy_valley_test_module(
      "research-ai-agents", "lake-exchange", 138, 101, 7, 6,
    ),
    energy_valley_test_module("talent", "south-showcase", 154, 92, 10, 5),
    energy_valley_test_module("market", "south-showcase", 168, 108, 8, 5),
    energy_valley_test_module("physical", "east-river", 179, 80, 8, 5),
    energy_valley_test_module("opc", "west-research", 85, 70, 6, 5),
    energy_valley_test_module("llm", "north-research", 142, 51, 8, 6),
    energy_valley_test_module("hardware", "east-research", 155, 71, 8, 6),
  ]
}

///|
fn energy_valley_terrain_signature(seed : Int) -> String {
  let mut signature = ""
  for grid_y in 0..<tilemap_grid_height() {
    for grid_x in 0..<tilemap_grid_width() {
      if grid_x % 7 == 0 && grid_y % 5 == 0 {
        signature = signature +
          energy_valley_tile_kind_at(seed, grid_x, grid_y) +
          ";"
      }
    }
  }
  signature
}

///|
fn energy_valley_module_signature(modules : Array[WenyuTownModule]) -> String {
  let mut signature = ""
  for civic in modules {
    signature = signature +
      civic.id +
      ":" +
      civic.grid_x.to_string() +
      "," +
      civic.grid_y.to_string() +
      "@" +
      civic.entrance_x.to_string() +
      "," +
      civic.entrance_y.to_string() +
      ";"
  }
  signature
}

///|
test "energy valley seeds are normalized and labeled deterministically" {
  assert_eq(normalized_energy_valley_seed(0), default_energy_valley_seed)
  assert_eq(normalized_energy_valley_seed(-99173), 99173)
  assert_eq(energy_valley_seed_label(99173).length(), 6)
  assert_eq(energy_valley_seed_label(-99173), energy_valley_seed_label(99173))
}

///|
test "energy valley terrain is deterministic and seed-sensitive" {
  let first = energy_valley_terrain_signature(20260727)
  assert_eq(first, energy_valley_terrain_signature(20260727))
  assert_true(first != energy_valley_terrain_signature(20260728))
  let mut water_count = 0
  let mut road_count = 0
  let mut bridge_count = 0
  for grid_y in 0..<tilemap_grid_height() {
    for grid_x in 0..<tilemap_grid_width() {
      if energy_valley_water_at(20260727, grid_x, grid_y) {
        water_count = water_count + 1
      }
      if energy_valley_road_at(20260727, grid_x, grid_y) {
        road_count = road_count + 1
      }
      if energy_valley_bridge_at(20260727, grid_x, grid_y) {
        bridge_count = bridge_count + 1
      }
    }
  }
  assert_true(water_count > 1000)
  assert_true(road_count > 1000)
  assert_true(bridge_count > 0)
}

///|
test "energy valley module placement is deterministic and seed-sensitive" {
  let templates = energy_valley_test_modules()
  let first = procedural_energy_valley_modules(templates, 20260727)
  let repeat = procedural_energy_valley_modules(templates, 20260727)
  let alternate = procedural_energy_valley_modules(templates, 20260728)
  assert_eq(
    energy_valley_module_signature(first),
    energy_valley_module_signature(repeat),
  )
  assert_true(
    energy_valley_module_signature(first) !=
    energy_valley_module_signature(alternate),
  )
}

///|
test "energy valley module placement preserves spatial invariants" {
  for seed in [20260727, 20260728, 17, 99173, 812381] {
    let road_network = energy_valley_authoritative_road_network(seed)
    let road_nodes = ecosystem_road_network_node_lookup(road_network)
    let modules = procedural_energy_valley_modules(
      energy_valley_test_modules(),
      seed,
    )
    assert_eq(modules.length(), energy_valley_test_modules().length())
    assert_true(energy_valley_modules_are_collision_free(modules))
    for civic in modules {
      assert_true(
        energy_valley_footprint_in_bounds(
          civic.grid_x,
          civic.grid_y,
          civic.footprint_w,
          civic.footprint_h,
        ),
      )
      assert_true(
        energy_valley_footprint_is_buildable(
          seed,
          road_nodes,
          civic,
          civic.grid_x,
          civic.grid_y,
        ),
      )
      assert_true(energy_valley_module_has_road_entrance(road_network, civic))
    }
  }
}
