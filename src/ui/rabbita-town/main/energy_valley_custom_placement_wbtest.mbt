///|
fn custom_placement_test_model() -> Model {
  {
    ..init_model(),
    energy_build_budget: 2400,
    energy_tool: ResearchTowerTool,
    energy_custom_buildings: [],
    energy_roads: [],
    energy_parks: [],
  }
}

///|
fn first_custom_placement_test_tile(
  predicate : (Int, Int) -> Bool,
) -> (Int, Int)? {
  for y in 1..<(golden_valley_rows() - 1) {
    for x in 1..<(golden_valley_cols() - 1) {
      if predicate(x, y) {
        return Some((x, y))
      }
    }
  }
  None
}

///|
fn first_resolved_custom_placement(
  model : Model,
) -> (Int, Int, GoldenValleyBuilding)? {
  let scale = energy_valley_semantic_cells_per_planning_cell()
  for y in 1..<(golden_valley_rows() - 1) {
    for x in 1..<(golden_valley_cols() - 1) {
      if x % scale != 0 ||
        y % scale != 0 ||
        golden_valley_tile_placement_block(model, x, y) is Some(_) {
        continue
      }
      match golden_valley_custom_building(ResearchTowerTool, x, y, 1) {
        None => ()
        Some(requested) =>
          match golden_valley_resolve_custom_building(model, requested) {
            Some(building) => return Some((x, y, building))
            None => ()
          }
      }
    }
  }
  None
}

///|
test "canonical custom-building policy exposes practical roadside coverage" {
  let model = custom_placement_test_model()
  let scale = energy_valley_semantic_cells_per_planning_cell()
  let mut total = 0
  let mut direct = 0
  let mut resolved = 0
  let mut accepted_natural_ground = false
  for y in 0..<golden_valley_rows() {
    for x in 0..<golden_valley_cols() {
      if x % scale != 0 || y % scale != 0 {
        continue
      }
      total += 1
      match golden_valley_custom_building(ResearchTowerTool, x, y, 1) {
        None => ()
        Some(requested) => {
          if golden_valley_custom_placement_clear(model, requested) {
            direct += 1
            for yy in requested.y..<(requested.y + requested.depth) {
              for xx in requested.x..<(requested.x + requested.width) {
                let terrain = golden_valley_terrain(
                  model,
                  active_energy_valley_seed(),
                  xx,
                  yy,
                )
                if terrain == "forest" || terrain == "field" {
                  accepted_natural_ground = true
                }
              }
            }
          }
          if golden_valley_resolve_custom_building(model, requested) is Some(_) {
            resolved += 1
          }
        }
      }
    }
  }
  assert_true(total > 4000)
  assert_true(direct > 0)
  assert_true(accepted_natural_ground)
  assert_true(resolved > direct)
}

///|
test "custom-building placement keeps blockers distinct" {
  let model = custom_placement_test_model()
  let seed = active_energy_valley_seed()
  let water = first_custom_placement_test_tile((x, y) => {
    golden_valley_terrain(model, seed, x, y) == "water"
  })
  let wetland = first_custom_placement_test_tile((x, y) => {
    golden_valley_terrain(model, seed, x, y) == "wetland"
  })
  let road = first_custom_placement_test_tile((x, y) => {
    let terrain = golden_valley_terrain(model, seed, x, y)
    terrain == "road" || terrain == "bridge"
  })
  let open = first_custom_placement_test_tile((x, y) => {
    golden_valley_tile_placement_block(model, x, y) is None
  })
  match water {
    Some((x, y)) =>
      assert_eq(
        golden_valley_tile_placement_block(model, x, y),
        Some(PlacementTransportOrWater),
      )
    None => fail("expected canonical water")
  }
  match wetland {
    Some((x, y)) =>
      assert_eq(
        golden_valley_tile_placement_block(model, x, y),
        Some(PlacementProtectedWetland),
      )
    None => fail("expected canonical wetland")
  }
  match road {
    Some((x, y)) =>
      assert_eq(
        golden_valley_tile_placement_block(model, x, y),
        Some(PlacementTransportOrWater),
      )
    None => fail("expected canonical road")
  }
  match open {
    Some((x, y)) => {
      let park_model = { ..model, energy_parks: [golden_valley_tile_key(x, y)] }
      assert_eq(
        golden_valley_tile_placement_block(park_model, x, y),
        Some(PlacementUserPark),
      )
    }
    None => fail("expected canonical open land")
  }
}

///|
test "building tool resolves a nearby lot and clears its rendered footprint" {
  let model = custom_placement_test_model()
  match first_resolved_custom_placement(model) {
    None => fail("expected a resolvable roadside lot")
    Some((click_x, click_y, expected)) => {
      let next = golden_valley_place_custom_building_model(
        model, click_x, click_y,
      )
      assert_eq(next.energy_custom_buildings.length(), 1)
      assert_eq(next.energy_build_budget, 1600)
      assert_true(next.energy_toast.contains("已开工"))
      let building = next.energy_custom_buildings[0]
      assert_eq((building.x, building.y), (expected.x, expected.y))
      assert_true(golden_valley_custom_building_has_road_access(next, building))
      for y in building.y..<(building.y + building.depth) {
        for x in building.x..<(building.x + building.width) {
          assert_eq(
            golden_valley_terrain(next, active_energy_valley_seed(), x, y),
            "plaza",
          )
        }
      }
    }
  }
}

///|
test "building tool still rejects a real water click without spending budget" {
  let model = custom_placement_test_model()
  let seed = active_energy_valley_seed()
  match
    first_custom_placement_test_tile((x, y) => {
      golden_valley_terrain(model, seed, x, y) == "water"
    }) {
    None => fail("expected canonical water")
    Some((x, y)) => {
      let next = golden_valley_place_custom_building_model(model, x, y)
      assert_true(next.energy_custom_buildings.is_empty())
      assert_eq(next.energy_build_budget, model.energy_build_budget)
      assert_true(next.energy_toast.contains("道路或水域"))
    }
  }
}
