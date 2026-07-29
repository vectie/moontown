///|
fn exact_energy_valley_count_terrain(
  world : ExactEnergyValleyWorld,
  terrain : String,
) -> Int {
  let mut count = 0
  for row in world.tiles {
    for tile in row {
      if tile.terrain == terrain {
        count += 1
      }
    }
  }
  count
}

///|
fn exact_energy_valley_is_water_or_bridge(
  world : ExactEnergyValleyWorld,
  x : Int,
  y : Int,
) -> Bool {
  match world.terrain_at(x, y) {
    Some("water") | Some("bridge") => true
    _ => false
  }
}

///|
fn exact_energy_valley_has_water_near(
  world : ExactEnergyValleyWorld,
  x : Int,
  y : Int,
  radius : Int,
) -> Bool {
  for yy in (y - radius)..<=(y + radius) {
    for xx in (x - radius)..<=(x + radius) {
      if exact_energy_valley_is_water_or_bridge(world, xx, yy) {
        return true
      }
    }
  }
  false
}

///|
fn exact_energy_valley_building_has_road(
  world : ExactEnergyValleyWorld,
  building : ExactEnergyValleyBuilding,
) -> Bool {
  for x in (building.x - 1)..<=(building.x + building.width) {
    for y in (building.y - 1)..<=(building.y + building.depth) {
      let edge = x == building.x - 1 ||
        x == building.x + building.width ||
        y == building.y - 1 ||
        y == building.y + building.depth
      if edge {
        match world.terrain_at(x, y) {
          Some("road") | Some("bridge") => return true
          _ => ()
        }
      }
    }
  }
  false
}

///|
test "Wenyu building kinds bridge into new-system structure types" {
  let source_profiles = [
    (WenyuLowrise, "lowrise"),
    (WenyuRow, "row"),
    (WenyuBlock, "block"),
    (WenyuTower, "tower"),
    (WenyuCourtyard, "courtyard"),
    (WenyuCampus, "campus"),
    (WenyuCivic, "civic"),
    (WenyuIndustrial, "industrial"),
  ]
  for index in 0..<source_profiles.length() {
    let (source_kind, expected) = source_profiles[index]
    let cell : WenyuReferenceBuildingCell = {
      source_kind,
      component_index: index,
      anchor_x: 120 + index,
      anchor_y: 70,
    }
    match
      wenyu_reference_structure_for_cell(
        20260727,
        if index < 5 {
          "urban-dense"
        } else {
          "campus"
        },
        cell,
      ) {
      Some((kind, floors)) => {
        assert_eq(kind, expected)
        assert_true(floors >= 1)
      }
      None => fail("expected typed Wenyu structure bridge")
    }
  }
  let non_buildable : WenyuReferenceBuildingCell = {
    source_kind: WenyuBlock,
    component_index: 1,
    anchor_x: 120,
    anchor_y: 70,
  }
  assert_eq(
    wenyu_reference_structure_for_cell(20260727, "road-major", non_buildable),
    None,
  )
}

///|
test "procedural fallback remains available beyond the Wenyu reference seed" {
  let profiles = [
    ("urban-dense", ["tower", "block", "row", "courtyard"]),
    ("urban", ["lowrise", "row", "courtyard"]),
    ("campus", ["campus", "civic", "industrial"]),
  ]
  for profile in profiles {
    let mut generated = 0
    for y in 0..<18 {
      for x in 0..<18 {
        match
          exact_energy_valley_procedural_structure(20260727, x, y, profile.0) {
          Some((kind, floors)) => {
            assert_true(profile.1.contains(kind))
            assert_true(floors >= 1)
            generated += 1
          }
          None => ()
        }
      }
    }
    assert_true(generated > 0)
  }
  assert_eq(
    exact_energy_valley_procedural_structure(20260727, 120, 70, "road-major"),
    None,
  )
  assert_eq(
    exact_energy_valley_procedural_structure(20260727, 121, 71, "urban-dense"),
    exact_energy_valley_procedural_structure(20260727, 121, 71, "urban-dense"),
  )
}

///|
fn exact_energy_valley_assert_aligned_buildings(
  world : ExactEnergyValleyWorld,
) -> Unit raise {
  let mut ambient_count = 0
  for row in world.tiles {
    for tile in row {
      if tile.structure is Some(_) {
        ambient_count += 1
        assert_true(tile.terrain == "urban" || tile.terrain == "plaza")
        assert_true(tile.building_id is Some(_))
        assert_true(tile.structure_width.unwrap_or(0) >= 3)
        assert_true(tile.structure_depth.unwrap_or(0) >= 3)
      }
    }
  }
  assert_true(ambient_count >= 20)
  assert_true(ambient_count <= 300)
  for building in world.buildings {
    for y in building.y..<(building.y + building.depth) {
      for x in building.x..<(building.x + building.width) {
        let tile = world.tiles[y][x]
        assert_eq(tile.terrain, "plaza")
        assert_eq(tile.base_terrain, "campus")
        assert_eq(tile.generated_terrain, "campus")
        assert_eq(tile.building_id, Some(building.id))
        assert_eq(tile.structure, None)
        assert_eq(tile.structure_floors, None)
        assert_eq(tile.structure_width, None)
        assert_eq(tile.structure_depth, None)
      }
    }
  }
}

///|
test "Wenyu semantic evidence compiles into readable gameplay parcels" {
  let world = exact_energy_valley_generate_default()
  let mut footprint_count = 0
  for y in 0..<world.rows {
    for x in 0..<world.cols {
      match world.structure_footprint_at(x, y) {
        None => ()
        Some((kind, floors, width, depth)) => {
          footprint_count += 1
          assert_true(
            [
              "lowrise", "row", "block", "tower", "courtyard", "campus", "civic",
              "industrial",
            ].contains(kind),
          )
          assert_true(floors >= 1)
          assert_true(width >= 3)
          assert_true(depth >= 3)
          let id = world.tiles[y][x].building_id
          assert_true(id is Some(_))
          for yy in y..<(y + depth) {
            for xx in x..<(x + width) {
              let tile = world.tiles[yy][xx]
              assert_eq(tile.building_id, id)
              assert_true(tile.terrain == "urban" || tile.terrain == "plaza")
            }
          }
        }
      }
    }
  }
  assert_true(footprint_count >= 40)
  assert_true(footprint_count <= 300)
}

///|
test "editor buildings snap old two-cell lots onto the planning lattice" {
  match golden_valley_custom_building(ResearchTowerTool, 17, 22, 1) {
    Some(building) => {
      assert_eq((building.x, building.y), (15, 21))
      assert_eq((building.width, building.depth), (6, 6))
    }
    None => fail("expected custom building")
  }
}

///|
test "default canvas world preserves the large Wenyu reference topology" {
  let world = exact_energy_valley_generate_default()
  assert_eq(world.seed, 20260727U)
  assert_eq((world.cols, world.rows), (256, 144))
  assert_eq(world.tiles.length(), 144)
  assert_eq(world.tiles[0].length(), 256)
  assert_eq(world.buildings.length(), 16)
  assert_true(
    world.landmarks.river_crossing_y >= 70 &&
    world.landmarks.river_crossing_y <= 74,
  )
  assert_true(
    world.landmarks.feeder_head_x >= 0 &&
    world.landmarks.feeder_head_x < world.cols,
  )
  assert_true(world.landmarks.bridge_columns.length() > 0)
  assert_true(
    world.landmarks.south_arterial_y >= 104 &&
    world.landmarks.south_arterial_y <= 108,
  )
  for y in [12, 40, 72, 106, 136] {
    let river_x = energy_valley_main_river_center_x(20260727, y)
    assert_true(exact_energy_valley_has_water_near(world, river_x, y, 2))
  }
  assert_true(
    exact_energy_valley_has_water_near(
      world,
      world.landmarks.feeder_head_x,
      7,
      2,
    ),
  )
  let bridge_x = world.landmarks.bridge_columns[0]
  assert_true(
    world.terrain_at(bridge_x, world.landmarks.river_crossing_y) ==
    Some("bridge"),
  )
  for x in [116, 140, 168, 190] {
    assert_eq(
      world.terrain_at(x, world.landmarks.south_arterial_y),
      Some("road"),
    )
  }
  assert_true(exact_energy_valley_count_terrain(world, "water") > 1000)
  assert_true(exact_energy_valley_count_terrain(world, "forest") > 500)
  for building in world.buildings {
    assert_true(exact_energy_valley_building_has_road(world, building))
  }
  exact_energy_valley_assert_aligned_buildings(world)
}

///|
test "Wenyu road compiler repairs only one-cell gaps in the source pattern" {
  assert_true(
    energy_valley_road_gap_from_neighbors(
      false, true, true, false, false, false, false, false, false,
    ),
  )
  assert_true(
    energy_valley_road_gap_from_neighbors(
      false, false, false, false, false, true, true, false, false,
    ),
  )
  assert_false(
    energy_valley_road_gap_from_neighbors(
      true, true, true, true, true, true, true, true, true,
    ),
  )
  assert_false(
    energy_valley_road_gap_from_neighbors(
      false, true, false, true, false, false, false, false, false,
    ),
  )
}

///|
test "seeds vary the large plan without losing Wenyu spatial invariants" {
  let canonical = exact_energy_valley_generate_default()
  let variant = exact_energy_valley_generate(1U)
  assert_eq(variant.buildings.length(), 16)
  assert_true(
    canonical.landmarks.river_crossing_y != variant.landmarks.river_crossing_y ||
    canonical.landmarks.civic_core_x != variant.landmarks.civic_core_x ||
    canonical.landmarks.south_arterial_y != variant.landmarks.south_arterial_y ||
    canonical.buildings[0].x != variant.buildings[0].x ||
    canonical.buildings[0].y != variant.buildings[0].y,
  )
  for y in [12, 40, 72, 106, 136] {
    let river_x = energy_valley_main_river_center_x(1, y)
    assert_true(exact_energy_valley_has_water_near(variant, river_x, y, 2))
  }
  for building in variant.buildings {
    assert_true(exact_energy_valley_building_has_road(variant, building))
  }
  for seed in [2U, 7U, 42U, 2026U] {
    let generated = exact_energy_valley_generate(seed)
    assert_eq(generated.buildings.length(), 16)
    for y in [12, 72, 136] {
      let river_x = energy_valley_main_river_center_x(
        seed.reinterpret_as_int(),
        y,
      )
      assert_true(exact_energy_valley_has_water_near(generated, river_x, y, 2))
    }
    for building in generated.buildings {
      assert_true(exact_energy_valley_building_has_road(generated, building))
    }
    exact_energy_valley_assert_aligned_buildings(generated)
  }
}

///|
test "zero and signed seeds retain normalization behavior" {
  let world = exact_energy_valley_generate(0U)
  assert_eq(world.seed, exact_energy_valley_default_seed())
  assert_eq(world.terrain_at(-1, 0), None)
  assert_eq(world.variation_at(256, 0), None)
  let negative = exact_energy_valley_generate_int(-1)
  assert_eq(negative.seed, 1U)
  assert_eq(negative.buildings.length(), 16)
}
