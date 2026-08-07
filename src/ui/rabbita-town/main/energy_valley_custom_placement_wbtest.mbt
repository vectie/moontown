///|
fn custom_placement_test_model() -> Model {
  { ..init_model(), energy_tool: ResearchTowerTool }
}

///|
fn custom_placement_test_terrain(
  model : Model,
  seed : Int,
  x : Int,
  y : Int,
) -> String {
  let world = ecosystem_contract_world_for_model(model, seed)
  match golden_valley_semantic_road_node_at(world, x, y) {
    Some(node) =>
      if world.road_network.segments.any(segment => {
          segment.road_class is @energy_valley_contract.Bridge &&
          (segment.from_node_id == node.id || segment.to_node_id == node.id)
        }) {
        "bridge"
      } else {
        "road"
      }
    None =>
      match ecosystem_contract_terrain_kind_at(world, x, y) {
        Some(@energy_valley_contract.Water) => "water"
        Some(@energy_valley_contract.Wetland) => "wetland"
        Some(@energy_valley_contract.Woodland) => "forest"
        Some(@energy_valley_contract.Paving) => "plaza"
        Some(@energy_valley_contract.Restricted) => "restricted"
        Some(@energy_valley_contract.Meadow) => "grass"
        Some(@energy_valley_contract.Custom(label)) => label
        None => "void"
      }
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
test "canonical custom-building policy exposes a parcel-bound roadside lot" {
  let model = custom_placement_test_model()
  let world = ecosystem_contract_world_for_model(
    model,
    active_energy_valley_seed(),
  )
  match first_resolved_custom_placement(model) {
    Some((_, _, building)) => {
      assert_true(golden_valley_custom_placement_clear(model, building))
      assert_true(
        golden_valley_contract_buildable_parcel_for(
          world,
          golden_valley_contract_building_footprint(building),
        )
        is Some(_),
      )
      assert_true(
        golden_valley_custom_building_has_road_access_in_world(world, building),
      )
      for y in building.y..<(building.y + building.depth) {
        for x in building.x..<(building.x + building.width) {
          let terrain = ecosystem_contract_terrain_kind_at(world, x, y)
          assert_false(
            terrain is Some(@energy_valley_contract.Water) ||
            terrain is Some(@energy_valley_contract.Wetland) ||
            terrain is Some(@energy_valley_contract.Restricted),
          )
        }
      }
    }
    None => fail("expected one compiler-approved roadside parcel")
  }
}

///|
test "custom-building placement keeps blockers distinct" {
  let model = custom_placement_test_model()
  let seed = active_energy_valley_seed()
  let water = first_custom_placement_test_tile((x, y) => {
    custom_placement_test_terrain(model, seed, x, y) == "water"
  })
  let wetland = first_custom_placement_test_tile((x, y) => {
    custom_placement_test_terrain(model, seed, x, y) == "wetland"
  })
  let road = first_custom_placement_test_tile((x, y) => {
    let terrain = custom_placement_test_terrain(model, seed, x, y)
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
      let park_model = energy_valley_model_add_park_delta(
        model,
        x,
        y,
        energy_valley_model_budget(model),
      )
      assert_eq(
        golden_valley_tile_placement_block(park_model, x, y),
        Some(PlacementUserPark),
      )
    }
    None => fail("expected canonical open land")
  }
}

///|
test "semantic parcels reject otherwise open terrain outside a land block" {
  let model = custom_placement_test_model()
  let world = ecosystem_contract_world_for_model(
    model,
    active_energy_valley_seed(),
  )
  let mut rejected = None
  for y in 1..<(golden_valley_rows() - 1) {
    for x in 1..<(golden_valley_cols() - 1) {
      let terrain = ecosystem_contract_terrain_kind_at(world, x, y)
      if (
          terrain is Some(@energy_valley_contract.Meadow) ||
          terrain is Some(@energy_valley_contract.Woodland)
        ) &&
        golden_valley_contract_road_node_at(world, x, y) is None &&
        golden_valley_contract_place_at(world, x, y) is None &&
        golden_valley_contract_buildable_parcel_for(
          world,
          golden_valley_contract_tile_footprint(x, y),
        )
        is None {
        rejected = Some((x, y))
        break
      }
    }
    if rejected is Some(_) {
      break
    }
  }
  match rejected {
    Some((x, y)) =>
      assert_eq(
        golden_valley_tile_placement_block_in_world(world, x, y),
        Some(PlacementOutsideBuildableParcel),
      )
    None => fail("expected natural terrain outside a semantic buildable parcel")
  }
}

///|
test "road additions must join the authoritative cardinal graph" {
  let model = custom_placement_test_model()
  let world = ecosystem_contract_world_for_model(
    model,
    active_energy_valley_seed(),
  )
  let mut connected = None
  let mut disconnected = None
  for y in 1..<(golden_valley_rows() - 1) {
    for x in 1..<(golden_valley_cols() - 1) {
      let terrain = ecosystem_contract_terrain_kind_at(world, x, y)
      let allowed = terrain is Some(@energy_valley_contract.Meadow) ||
        terrain is Some(@energy_valley_contract.Woodland) ||
        terrain is Some(@energy_valley_contract.Water)
      if allowed &&
        golden_valley_contract_road_node_at(world, x, y) is None &&
        golden_valley_contract_place_at(world, x, y) is None {
        if golden_valley_contract_road_candidate_connected(world, x, y) {
          if connected is None {
            connected = Some((x, y))
          }
        } else if disconnected is None {
          disconnected = Some((x, y))
        }
      }
    }
    if connected is Some(_) && disconnected is Some(_) {
      break
    }
  }
  match disconnected {
    Some((x, y)) => {
      let rejected = golden_valley_place_road_model(model, x, y)
      assert_true(energy_valley_model_roads(rejected).is_empty())
      assert_eq(
        energy_valley_model_budget(rejected),
        energy_valley_model_budget(model),
      )
      assert_true(rejected.energy_toast.contains("正交相连"))
    }
    None => fail("expected an isolated road candidate")
  }
  match connected {
    Some((x, y)) => {
      let accepted = golden_valley_place_road_model(model, x, y)
      assert_eq(energy_valley_model_roads(accepted), [
        golden_valley_tile_key(x, y),
      ])
      assert_true(
        energy_valley_model_budget(accepted) < energy_valley_model_budget(model),
      )
      assert_true(golden_valley_canonical_road_active(accepted, x, y))
    }
    None => fail("expected a cardinal road-graph extension candidate")
  }
}

///|
test "park additions compile into a parcel-bound semantic Place" {
  let model = custom_placement_test_model()
  let world = ecosystem_contract_world_for_model(
    model,
    active_energy_valley_seed(),
  )
  let mut candidate = None
  for y in 1..<(golden_valley_rows() - 1) {
    for x in 1..<(golden_valley_cols() - 1) {
      if ecosystem_contract_terrain_kind_at(world, x, y)
        is Some(@energy_valley_contract.Meadow) &&
        golden_valley_contract_road_node_at(world, x, y) is None &&
        golden_valley_contract_place_at(world, x, y) is None &&
        golden_valley_contract_buildable_parcel_for(
          world,
          golden_valley_contract_tile_footprint(x, y),
        )
        is Some(_) {
        candidate = Some((x, y))
        break
      }
    }
    if candidate is Some(_) {
      break
    }
  }
  match candidate {
    Some((x, y)) => {
      let planted = golden_valley_place_park_model(model, x, y)
      assert_eq(energy_valley_model_parks(planted), [
        golden_valley_tile_key(x, y),
      ])
      assert_eq(
        energy_valley_model_budget(planted),
        energy_valley_model_budget(model) - 20,
      )
      assert_true(golden_valley_canonical_park_active(planted, x, y))
      let planted_world = ecosystem_contract_world_for_model(
        planted,
        active_energy_valley_seed(),
      )
      match
        planted_world.find_place(
          ecosystem_contract_id(
            ecosystem_scoped_id("place", "public-park-\{x}-\{y}"),
          ),
        ) {
        Some(place) => {
          assert_true(place.kind is @energy_valley_contract.Park)
          assert_true(place.parcel_id is Some(_))
        }
        None => fail("expected the saved park to compile into a Place")
      }
    }
    None => fail("expected a meadow inside a semantic buildable parcel")
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
      let next_buildings = energy_valley_model_buildings(next)
      assert_eq(next_buildings.length(), 1)
      assert_eq(energy_valley_model_budget(next), 1600)
      assert_true(next.energy_toast.contains("已开工"))
      let building = next_buildings[0]
      assert_eq((building.x, building.y), (expected.x, expected.y))
      assert_true(golden_valley_custom_building_has_road_access(next, building))
      assert_true(golden_valley_canonical_building_active(next, building))
      let world = ecosystem_contract_world_for_model(
        next,
        active_energy_valley_seed(),
      )
      match
        world.find_place(
          ecosystem_contract_id(ecosystem_custom_place_id(building)),
        ) {
        Some(place) => {
          assert_true(place.kind is @energy_valley_contract.Building)
          assert_true(place.building is Some(_))
          assert_true(place.parcel_id is Some(_))
          assert_true(place.primary_entrance() is Some(_))
          match
            town_snapshot_canvas_building_at_tile(
              ecosystem_contract_town_snapshot(
                next,
                active_energy_valley_seed(),
              ),
              building.x,
              building.y,
            ) {
            Some(selected) => {
              assert_eq(selected.authored_id, building.authored_id)
              assert_eq((selected.x, selected.y), (building.x, building.y))
            }
            None => fail("expected semantic selection inside the saved Place")
          }
        }
        None => fail("expected the saved building to compile into a Place")
      }
      let occupied = golden_valley_place_road_model(
        next,
        building.x,
        building.y,
      )
      assert_eq(
        energy_valley_model_roads(occupied),
        energy_valley_model_roads(next),
      )
      assert_true(occupied.energy_toast.contains("先拆除建筑或设施"))
      for y in building.y..<(building.y + building.depth) {
        for x in building.x..<(building.x + building.width) {
          assert_eq(
            custom_placement_test_terrain(
              next,
              active_energy_valley_seed(),
              x,
              y,
            ),
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
      custom_placement_test_terrain(model, seed, x, y) == "water"
    }) {
    None => fail("expected canonical water")
    Some((x, y)) => {
      let next = golden_valley_place_custom_building_model(model, x, y)
      assert_true(energy_valley_model_buildings(next).is_empty())
      assert_eq(
        energy_valley_model_budget(next),
        energy_valley_model_budget(model),
      )
      assert_true(next.energy_toast.contains("道路或水域"))
    }
  }
}
