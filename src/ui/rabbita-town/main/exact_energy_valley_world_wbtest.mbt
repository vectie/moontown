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
fn exact_energy_valley_count_structure(
  world : ExactEnergyValleyWorld,
  structure : String,
) -> Int {
  let mut count = 0
  for row in world.tiles {
    for tile in row {
      if tile.structure == Some(structure) {
        count += 1
      }
    }
  }
  count
}

///|
fn exact_energy_valley_structure_floor_sum(
  world : ExactEnergyValleyWorld,
) -> Int {
  let mut floors = 0
  for row in world.tiles {
    for tile in row {
      match tile.structure_floors {
        Some(value) => floors += value
        None => ()
      }
    }
  }
  floors
}

///|
fn exact_energy_valley_building_signature(
  building : ExactEnergyValleyBuilding,
) -> String {
  "\{building.module_key}:\{building.archetype}@\{building.x},\{building.y}/\{building.width}x\{building.depth}"
}

///|
test "exact Energy Valley Mulberry32 matches preserved JavaScript bits" {
  let default_random : ExactEnergyValleyRandom = { state: 20260727U }
  let default_expected : Array[UInt] = [
    2577721268U, 1799220241U, 3008992074U, 1149792506U, 1760247048U, 3552962523U,
    4225036269U, 3418685256U, 4226992601U, 1397937867U, 3141629168U, 1124798345U,
    2382391260U, 64177641U, 3231606880U, 3411815218U,
  ]
  for expected in default_expected {
    assert_eq(default_random.next_u32(), expected)
  }
  let seed_one_random : ExactEnergyValleyRandom = { state: 1U }
  let seed_one_expected : Array[UInt] = [
    2693262067U, 11749833U, 2265367787U, 4213581821U, 4159151403U, 1207330352U, 2632122864U,
    3095568220U, 1828783984U, 4272732017U, 1955374602U, 2099329838U, 596715197U,
    1734070562U, 1063107040U, 663542962U,
  ]
  for expected in seed_one_expected {
    assert_eq(seed_one_random.next_u32(), expected)
  }
}

///|
test "exact Energy Valley default seed matches preserved world" {
  let world = exact_energy_valley_generate_default()
  assert_eq(world.seed, 20260727U)
  assert_eq(world.cols, 56)
  assert_eq(world.rows, 52)
  assert_eq(world.tiles.length(), 52)
  assert_eq(world.tiles[0].length(), 56)
  assert_eq(world.buildings.length(), 13)
  assert_eq(world.landmarks.civic_core_x, 21)
  assert_eq(world.landmarks.civic_core_y, 22)
  assert_eq(world.landmarks.bridge_rows, [11, 27, 43])
  assert_true(
    (world.landmarks.main_river_mean_x - 43.9817156533245).abs() <
    0.000000000001,
  )
  assert_true(
    (world.landmarks.lake_x - 29.065508878976107).abs() < 0.000000000001,
  )
  assert_true(
    (world.landmarks.lake_y - 32.452520224032924).abs() < 0.000000000001,
  )
  let expected_buildings = [
    "town-shell:town-shell@17,23/3x3", "vitality-tower:vitality@24,15/2x2", "policy-hall:policy@13,24/2x2",
    "contest-express:contest@19,14/2x2", "story-radar:radar@10,9/2x2", "resident-twins:twins@9,30/2x2",
    "resident-twins-b:twins@11,36/2x2", "ai-garden:ai-garden@20,28/3x3", "social-square:social@34,39/3x3",
    "energy-lab:c-lab@33,28/2x2", "talent-avenue:talent@24,40/3x2", "valley-market:market@28,40/3x2",
    "talent-flat:c-home@38,39/2x2",
  ]
  for index in 0..<expected_buildings.length() {
    assert_eq(
      exact_energy_valley_building_signature(world.buildings[index]),
      expected_buildings[index],
    )
  }
  assert_true(
    (world.buildings[0].vitality - 71.34263656567782).abs() < 0.000000000001,
  )
  assert_true(
    (world.buildings[7].vitality - 67.28747681248933).abs() < 0.000000000001,
  )
  assert_true(
    (world.buildings[12].vitality - 84.40938349114731).abs() < 0.000000000001,
  )
  assert_eq(exact_energy_valley_count_terrain(world, "bridge"), 11)
  assert_eq(exact_energy_valley_count_terrain(world, "field"), 70)
  assert_eq(exact_energy_valley_count_terrain(world, "forest"), 671)
  assert_eq(exact_energy_valley_count_terrain(world, "grass"), 773)
  assert_eq(exact_energy_valley_count_terrain(world, "meadow"), 189)
  assert_eq(exact_energy_valley_count_terrain(world, "plaza"), 95)
  assert_eq(exact_energy_valley_count_terrain(world, "road"), 429)
  assert_eq(exact_energy_valley_count_terrain(world, "urban"), 147)
  assert_eq(exact_energy_valley_count_terrain(world, "water"), 371)
  assert_eq(exact_energy_valley_count_terrain(world, "wetland"), 156)
  assert_eq(exact_energy_valley_count_structure(world, "campus"), 12)
  assert_eq(exact_energy_valley_count_structure(world, "courtyard"), 22)
  assert_eq(exact_energy_valley_count_structure(world, "lowrise"), 69)
  assert_eq(exact_energy_valley_count_structure(world, "row"), 33)
  assert_eq(exact_energy_valley_count_structure(world, "tower"), 11)
  assert_eq(exact_energy_valley_structure_floor_sum(world), 338)
  assert_eq(world.tiles[0][0].terrain, "forest")
  assert_true(
    (world.tiles[0][0].variation - 0.8033072350081056).abs() < 0.000000000000001,
  )
  assert_eq(world.tiles[11][11].terrain, "road")
  assert_eq(world.tiles[11][11].road_mask, Some(10))
  assert_eq(world.tiles[32][29].terrain, "water")
  assert_eq(world.tiles[23][17].building_id, Some("civic-town-shell"))
  assert_eq(world.tiles[28][20].building_id, Some("civic-ai-garden"))
  assert_eq(world.structure_at(15, 5), Some(("row", 3)))
  assert_eq(world.tiles[11][43].terrain, "bridge")
  assert_eq(world.tiles[11][43].road_mask, Some(10))
}

///|
test "exact Energy Valley seed one preserves grammar and safe civic placement" {
  let world = exact_energy_valley_generate(1U)
  assert_eq(world.seed, 1U)
  assert_eq(world.landmarks.civic_core_x, 20)
  assert_eq(world.landmarks.civic_core_y, 23)
  assert_eq(world.landmarks.bridge_rows, [12, 25, 42])
  assert_true(
    (world.landmarks.main_river_mean_x - 42.34331050887704).abs() <
    0.000000000001,
  )
  assert_true(
    (world.landmarks.lake_x - 28.794675308093428).abs() < 0.000000000001,
  )
  assert_true(
    (world.landmarks.lake_y - 30.777390856295824).abs() < 0.000000000001,
  )
  let expected_buildings = [
    "town-shell:town-shell@16,19/3x3", "vitality-tower:vitality@24,18/2x2", "policy-hall:policy@12,26/2x2",
    "contest-express:contest@17,14/2x2", "story-radar:radar@10,10/2x2", "resident-twins:twins@9,31/2x2",
    "resident-twins-b:twins@11,36/2x2", "ai-garden:ai-garden@19,29/3x3", "social-square:social@26,35/3x3",
    "energy-lab:c-lab@32,26/2x2", "talent-avenue:talent@24,40/3x2", "valley-market:market@32,40/3x2",
    "talent-flat:c-home@33,36/2x2",
  ]
  for index in 0..<expected_buildings.length() {
    assert_eq(
      exact_energy_valley_building_signature(world.buildings[index]),
      expected_buildings[index],
    )
  }
  assert_true(
    (world.buildings[0].vitality - 78.4578698547557).abs() < 0.000000000001,
  )
  assert_true(
    (world.buildings[7].vitality - 74.13718328345567).abs() < 0.000000000001,
  )
  assert_true(
    (world.buildings[12].vitality - 70.20165189635009).abs() < 0.000000000001,
  )
  assert_eq(exact_energy_valley_count_terrain(world, "bridge"), 13)
  assert_eq(exact_energy_valley_count_terrain(world, "field"), 92)
  assert_eq(exact_energy_valley_count_terrain(world, "forest"), 643)
  assert_eq(exact_energy_valley_count_terrain(world, "grass"), 823)
  assert_eq(exact_energy_valley_count_terrain(world, "meadow"), 187)
  assert_eq(exact_energy_valley_count_terrain(world, "plaza"), 83)
  assert_eq(exact_energy_valley_count_terrain(world, "road"), 422)
  assert_eq(exact_energy_valley_count_terrain(world, "urban"), 136)
  assert_eq(exact_energy_valley_count_terrain(world, "water"), 358)
  assert_eq(exact_energy_valley_count_terrain(world, "wetland"), 155)
  assert_eq(exact_energy_valley_count_structure(world, "campus"), 13)
  assert_eq(exact_energy_valley_count_structure(world, "courtyard"), 12)
  assert_eq(exact_energy_valley_count_structure(world, "lowrise"), 79)
  assert_eq(exact_energy_valley_count_structure(world, "row"), 26)
  assert_eq(exact_energy_valley_count_structure(world, "tower"), 6)
  assert_eq(exact_energy_valley_structure_floor_sum(world), 292)
  assert_eq(world.tiles[0][0].terrain, "grass")
  assert_true(
    (world.tiles[0][0].variation - 0.763514569029212).abs() < 0.000000000000001,
  )
  assert_eq(world.tiles[12][12].terrain, "road")
  assert_eq(world.tiles[12][12].road_mask, Some(15))
  assert_eq(world.tiles[31][29].terrain, "water")
  assert_eq(world.tiles[19][16].building_id, Some("civic-town-shell"))
  assert_eq(world.tiles[29][19].building_id, Some("civic-ai-garden"))
  assert_eq(world.structure_at(15, 5), Some(("row", 2)))
  assert_eq(world.tiles[12][44].terrain, "bridge")
  assert_eq(world.tiles[12][44].road_mask, Some(10))
}

///|
test "zero seed normalizes to canonical Energy Valley" {
  let world = exact_energy_valley_generate(0U)
  assert_eq(world.seed, exact_energy_valley_default_seed())
  assert_eq(
    world
    .building_for_module("ai-garden")
    .map(fn(building) { (building.x, building.y) }),
    Some((20, 28)),
  )
  assert_eq(world.terrain_at(-1, 0), None)
  assert_eq(world.variation_at(56, 0), None)
  assert_eq(world.structure_at(0, 0), None)
  let negative = exact_energy_valley_generate_int(-1)
  assert_eq(negative.seed, 1U)
  assert_eq(
    negative
    .building_for_module("ai-garden")
    .map(fn(building) { (building.x, building.y) }),
    Some((19, 29)),
  )
}
