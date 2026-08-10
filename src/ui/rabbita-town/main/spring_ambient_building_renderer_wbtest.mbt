///|
fn spring_ambient_test_building(
  style : String,
  place_key : String,
  interior_seed : Int,
) -> TownCanvasBuilding {
  {
    place_id: ecosystem_contract_scoped_id("place", place_key),
    name: "Ambient fixture",
    style,
    x: 32,
    y: 48,
    width: 7,
    depth: 4,
    entrance_x: None,
    entrance_y: None,
    floors: 3,
    interior_seed,
    module_key: None,
    authored_id: None,
  }
}

///|
test "spring ambient renderer exposes exactly eighty assets" {
  let paths : Map[String, Unit] = {}
  for
    style in [
      "lowrise", "row", "block", "tower", "courtyard", "campus", "civic", "industrial",
    ] {
    for variant in 0..<10 {
      let expected = "/tilemap/buildings/moontown-spring-ambient-v1/\{style}-\{variant}.webp"
      let path = golden_spring_ambient_asset_path_for_variant(style, variant)
      assert_eq(path, Some(expected))
      paths[expected] = ()
    }
  }
  assert_eq(paths.length(), 80)
  assert_eq(golden_spring_ambient_asset_path_for_variant("lowrise", -1), None)
  assert_eq(golden_spring_ambient_asset_path_for_variant("lowrise", 10), None)
  assert_eq(golden_spring_ambient_asset_path_for_variant("unknown", 0), None)
}

///|
test "spring ambient variant is stable style-sensitive and promotion preserving" {
  let building = spring_ambient_test_building("campus", "stable-campus", 17)
  let first = golden_spring_ambient_building_asset_candidate(building, 0.42).unwrap()
  let second = golden_spring_ambient_building_asset_candidate(building, 0.42).unwrap()
  assert_eq(first, second)
  assert_eq(
    first.variant,
    golden_spring_ambient_building_variant(
      building.style,
      building.place_id,
      building.interior_seed,
    ),
  )
  assert_eq(first.variant, 7)
  assert_eq(
    golden_spring_ambient_building_variant(
      "row",
      building.place_id,
      building.interior_seed,
    ),
    2,
  )
  let restyled = { ..building, style: "row" }
  let restyled_first = golden_spring_ambient_building_asset_candidate(
    restyled, 0.42,
  ).unwrap()
  let restyled_second = golden_spring_ambient_building_asset_candidate(
    restyled, 0.42,
  ).unwrap()
  assert_eq(restyled_first, restyled_second)
  assert_eq(restyled_first.variant, 2)
  assert_true(restyled_first.variant != first.variant)
  assert_eq(
    golden_spring_ambient_building_asset_path(building, 0.42),
    Some(first.asset_path),
  )
  let moved = { ..building, x: 91, y: 12, name: "Moved fixture" }
  assert_eq(
    golden_spring_ambient_building_asset_candidate(moved, 1.2),
    Some(first),
  )
}

///|
test "spring ambient promotion map is balanced and preserves eighty percent" {
  let counts : Array[Int] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
  let mut preserved = 0
  for hash in 0..<40 {
    let promotion = energy_valley_mod(hash, 10)
    let previous = energy_valley_mod(hash, 8)
    let variant = golden_spring_ambient_building_variant_from_hash(hash)
    assert_true(variant >= 0)
    assert_true(variant < 10)
    counts[variant] += 1
    if promotion < 8 {
      assert_eq(variant, previous)
      preserved += 1
    } else {
      assert_eq(variant, promotion)
    }
  }
  assert_eq(counts, [4, 4, 4, 4, 4, 4, 4, 4, 4, 4])
  assert_eq(preserved, 32)
}

///|
test "spring ambient eligibility rejects semantic owners and unsupported views" {
  for
    style in [
      "lowrise", "row", "block", "tower", "courtyard", "campus", "civic", "industrial",
    ] {
    let building = spring_ambient_test_building(style, "eligible-\{style}", 9)
    assert_true(
      golden_spring_ambient_building_asset_candidate(building, 0.18) is Some(_),
    )
  }

  let ambient = spring_ambient_test_building("lowrise", "ambient", 9)
  assert_eq(
    golden_spring_ambient_building_asset_candidate(
      { ..ambient, module_key: Some("town-shell") },
      0.5,
    ),
    None,
  )
  assert_eq(
    golden_spring_ambient_building_asset_candidate(
      { ..ambient, authored_id: Some("authored-building-1") },
      0.5,
    ),
    None,
  )
  assert_eq(
    golden_spring_ambient_building_asset_candidate(
      { ..ambient, style: "custom-home" },
      0.5,
    ),
    None,
  )
  assert_eq(
    golden_spring_ambient_building_asset_candidate(ambient, 0.179),
    None,
  )
}

///|
test "spring skin precedence never substitutes ambient art for a landmark" {
  let ambient = spring_ambient_test_building("lowrise", "precedence", 21)
  let landmark = { ..ambient, module_key: Some("town-shell") }
  assert_eq(
    golden_spring_building_asset_path(landmark, 0.5),
    Some("/tilemap/buildings/moontown-spring-civic-v1/town-shell.png"),
  )
  assert_eq(
    golden_spring_building_asset_path(landmark, 0.1),
    Some("/tilemap/buildings/moontown-spring-civic-v1/town-shell.png"),
  )
  assert_eq(
    golden_spring_building_asset_path(
      { ..ambient, module_key: Some("unknown-module") },
      0.5,
    ),
    None,
  )
}
