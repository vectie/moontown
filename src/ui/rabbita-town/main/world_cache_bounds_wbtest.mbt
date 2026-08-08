///|
fn world_cache_bounds_clear() -> Unit {
  golden_valley_world_cache.clear()
  energy_valley_base_contract_world_cache.clear()
  town_life_world_base_road_cells_cache.clear()
}

///|
test "generated and compiled world caches retain only the current seed" {
  world_cache_bounds_clear()
  let first_seed = 20260727
  let second_seed = 20260728
  ignore(golden_valley_world(first_seed))
  assert_true(golden_valley_world_cache.contains(first_seed))
  ignore(golden_valley_world(second_seed))
  assert_eq(golden_valley_world_cache.length(), 1)
  assert_false(golden_valley_world_cache.contains(first_seed))
  assert_true(golden_valley_world_cache.contains(second_seed))

  world_cache_bounds_clear()
  let first = energy_valley_base_contract_world_for_seed(first_seed)
  let second = energy_valley_base_contract_world_for_seed(second_seed)
  assert_true(first.blueprint_digest != second.blueprint_digest)
  assert_eq(energy_valley_base_contract_world_cache.length(), 1)
  assert_false(energy_valley_base_contract_world_cache.contains(first_seed))
  assert_true(energy_valley_base_contract_world_cache.contains(second_seed))
  assert_eq(
    energy_valley_base_contract_world_for_seed(second_seed).blueprint_digest,
    second.blueprint_digest,
  )
  world_cache_bounds_clear()
}

///|
test "base-road index cache retains only the current blueprint digest" {
  world_cache_bounds_clear()
  let first = energy_valley_base_contract_world_for_seed(20260727)
  let first_cells = town_life_world_base_road_cells(first)
  assert_true(first_cells.length() > 0)
  assert_true(
    town_life_world_base_road_cells_cache.contains(first.blueprint_digest),
  )

  let second = energy_valley_base_contract_world_for_seed(20260728)
  let second_cells = town_life_world_base_road_cells(second)
  assert_true(second_cells.length() > 0)
  assert_eq(town_life_world_base_road_cells_cache.length(), 1)
  assert_false(
    town_life_world_base_road_cells_cache.contains(first.blueprint_digest),
  )
  assert_true(
    town_life_world_base_road_cells_cache.contains(second.blueprint_digest),
  )
  assert_eq(
    town_life_world_base_road_cells(second).length(),
    second_cells.length(),
  )
  world_cache_bounds_clear()
}
