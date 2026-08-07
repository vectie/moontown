///|
/// Energy Valley Canvas focused behavior tests
///
/// Validates that the golden valley world generation produces
/// expected building counts, tile data, and seed stability.

///|
fn setup_world() -> ExactEnergyValleyWorld {
  golden_valley_world(42)
}

///|
test "golden_valley_world produces expected building count" {
  let world = setup_world()
  let building_count = world.buildings.length()
  // Expect at least 1 building (Town Hall) and at most 64
  assert_true(building_count >= 1)
  assert_true(building_count <= 64)
}

///|
test "golden_valley_world produces tile grid" {
  let world = setup_world()
  assert_true(world.tiles.length() > 0)
  assert_eq(world.tiles.length(), world.rows)
  // Every row matches the declared column count
  let mut consistent = true
  for row in world.tiles {
    if row.length() != world.cols {
      consistent = false
    }
  }
  assert_true(consistent)
}

///|
test "golden_valley_world seed stability" {
  let world1 = golden_valley_world(42)
  let world2 = golden_valley_world(42)
  assert_eq(world1.buildings.length(), world2.buildings.length())
  assert_eq(world1.rows, world2.rows)
  assert_eq(world1.cols, world2.cols)
}

///|
test "golden_valley_world accepts different seeds" {
  let world1 = golden_valley_world(1)
  let world2 = golden_valley_world(2)
  assert_true(world1.buildings.length() >= 0)
  assert_true(world2.buildings.length() >= 0)
  assert_true(world1.rows > 0)
  assert_true(world2.cols > 0)
}

///|
test "golden_valley_world buildings have required fields" {
  let world = setup_world()
  let all_valid = world.buildings.all(fn(b) {
    b.name.length() > 0 && b.x >= 0 && b.y >= 0
  })
  assert_true(all_valid)
}

///|
test "public realm night predicate has explicit dusk boundaries" {
  assert_true(golden_public_realm_is_night(5.9))
  assert_false(golden_public_realm_is_night(12.0))
  assert_true(golden_public_realm_is_night(18.5))
}

///|
test "street furniture placement is deterministic and road constrained" {
  let seed = 20260727
  let mut lights = 0
  let mut trees = 0
  for y in 0..<40 {
    for x in 0..<40 {
      let light = golden_public_realm_streetlight_at(
        seed, x, y, "road", 5, true,
      )
      assert_eq(
        light,
        golden_public_realm_streetlight_at(seed, x, y, "road", 5, true),
      )
      if light {
        lights += 1
      }
      if golden_public_realm_street_tree_at(seed, x, y, "road", 10) {
        trees += 1
      }
    }
  }
  assert_true(lights > 0 && lights < 400)
  assert_true(trees > 0 && trees < 250)
  assert_false(
    golden_public_realm_streetlight_at(seed, 12, 12, "plaza", 5, true),
  )
  assert_false(golden_public_realm_street_tree_at(seed, 12, 12, "road", 0))
}

///|
test "plaza furniture never occupies buildings or non plaza terrain" {
  let seed = 20260727
  assert_eq(golden_public_realm_plaza_feature(seed, 4, 8, "road", false), 0)
  assert_eq(golden_public_realm_plaza_feature(seed, 4, 8, "plaza", true), 0)
  let mut furniture = 0
  for y in 0..<80 {
    for x in 0..<80 {
      if golden_public_realm_plaza_feature(seed, x, y, "plaza", false) != 0 {
        furniture += 1
      }
    }
  }
  assert_true(furniture > 0 && furniture < 400)
}

///|
test "boardwalk follows typed waterfront edges only" {
  assert_eq(
    golden_public_realm_boardwalk_mask(
      "grass", "civic-core", "water", "grass", "water", "road",
    ),
    5,
  )
  assert_eq(
    golden_public_realm_boardwalk_mask(
      "road", "civic-core", "water", "water", "water", "water",
    ),
    0,
  )
  assert_eq(
    golden_public_realm_boardwalk_mask(
      "grass", "north-innovation", "water", "water", "water", "water",
    ),
    0,
  )
}

///|
test "boardwalk strokes stay proportional at whole-map zoom" {
  assert_eq(golden_public_realm_boardwalk_casing_width(0.07), 0.8)
  assert_eq(golden_public_realm_boardwalk_deck_width(0.07), 0.5)
  assert_eq(golden_public_realm_boardwalk_shadow_offset(0.07), 0.25)
  assert_eq(golden_public_realm_boardwalk_casing_width(1.0), 8.0)
  assert_eq(golden_public_realm_boardwalk_deck_width(1.0), 6.0)
  // The shortest allowed overview edge is about 2.5px; its casing must no
  // longer be wider than the segment it represents.
  assert_true(golden_public_realm_boardwalk_casing_width(0.07) < 2.5)
}

///|
test "generated Wenyu world exposes a real central waterfront promenade" {
  let snapshot = ecosystem_contract_town_snapshot(init_model(), 20260727)
  let mut boardwalk_edges = 0
  for installation in snapshot.world.installations {
    if installation.kind is @energy_valley_contract.Boardwalk {
      boardwalk_edges += 1
      assert_true(installation.geometry is @energy_valley_contract.AlongPath(_))
    }
  }
  assert_true(boardwalk_edges > 20)
}

///|
test "metro stations materialize all typed exits" {
  assert_eq(metro_line17_station_exit_count(), 4)
  let stations = metro_line17_stations()
  assert_eq(
    metro_station_exit_summary(stations[0]),
    "A / B 口 · 能源谷核心区",
  )
  assert_eq(
    metro_station_exit_summary(stations[1]),
    "C / D 口 · 英才北一街",
  )
}

///|
test "semantic metro alignment stays inside the compiled Wenyu world" {
  let snapshot = ecosystem_contract_town_snapshot(init_model(), 20260727)
  let alignments = snapshot.world.installations.filter(installation => {
    installation.kind is @energy_valley_contract.MetroAlignment
  })
  guard alignments is [alignment] else {
    fail("expected exactly one semantic Line 17 alignment")
  }
  guard alignment.geometry is @energy_valley_contract.AlongPath(points) else {
    fail("Line 17 alignment must remain a semantic path")
  }
  assert_eq(points.length(), metro_line17_path().length())
  for point in points {
    assert_true(snapshot.world.bounds.contains(point))
  }
  let stations = metro_line17_stations()
  assert_eq(stations.length(), 2)
  for station in stations {
    assert_true(
      snapshot.world.find_place(
        ecosystem_contract_id(ecosystem_metro_station_id(station)),
      )
      is Some(_),
    )
  }
  let issues = @energy_valley_contract.validate_snapshot(snapshot)
  assert_false(
    issues.any(issue => {
      issue.code is @energy_valley_contract.PositionOutsideBounds
    }),
  )
}
