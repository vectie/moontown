///|
fn ecosystem_cache_test_world(
  digest : String,
  kind : @energy_valley_contract.TerrainKind,
  walkable : Bool,
) -> @energy_valley_contract.CompiledTownWorld {
  let provenance = @energy_valley_contract.provenance(
    "cache-bound-test",
    digest,
    @energy_valley_contract.Derived,
    @energy_valley_contract.Bounded,
  )
  let boundary = @energy_valley_contract.polygon([
    @energy_valley_contract.world_point(0.0, 0.0),
    @energy_valley_contract.world_point(2.0, 0.0),
    @energy_valley_contract.world_point(2.0, 2.0),
    @energy_valley_contract.world_point(0.0, 2.0),
  ])
  @energy_valley_contract.compiled_town_world(
    "moontown.energy-valley.compiled.cache-test",
    ecosystem_contract_scoped_id("blueprint", digest),
    digest,
    ecosystem_stable_hash(digest),
    @energy_valley_contract.world_bounds(
      @energy_valley_contract.world_point(0.0, 0.0),
      @energy_valley_contract.world_point(2.0, 2.0),
    ),
    [
      @energy_valley_contract.terrain_region(
        ecosystem_contract_scoped_id("terrain-region", digest),
        kind,
        boundary,
        walkable,
        provenance,
      ),
    ],
    @energy_valley_contract.road_network([], [], []),
    [],
    [],
    [],
    [],
  )
}

///|
fn ecosystem_cache_test_clear() -> Unit {
  ecosystem_contract_terrain_kind_lookup_cache.clear()
  ecosystem_contract_terrain_walkable_lookup_cache.clear()
  ecosystem_contract_world_cache.clear()
  ecosystem_contract_world_validation_failed_cache.clear()
  ecosystem_contract_world_validation_summary_cache.clear()
  ecosystem_contract_world_validation_issues_cache.clear()
  ecosystem_contract_snapshot_validation_failed_cache.clear()
  ecosystem_contract_snapshot_validation_summary_cache.clear()
}

///|
test "terrain lookup retains one coherent compiled grid" {
  ecosystem_cache_test_clear()
  let meadow = ecosystem_cache_test_world(
    "terrain-cache-meadow",
    @energy_valley_contract.Meadow,
    true,
  )
  let water = ecosystem_cache_test_world(
    "terrain-cache-water",
    @energy_valley_contract.Water,
    false,
  )
  assert_eq(
    ecosystem_contract_terrain_kind_at(meadow, 0, 0),
    Some(@energy_valley_contract.Meadow),
  )
  assert_eq(ecosystem_contract_terrain_walkable_at(meadow, 0, 0), Some(true))
  assert_eq(ecosystem_contract_terrain_kind_lookup_cache.length(), 1)
  assert_eq(ecosystem_contract_terrain_walkable_lookup_cache.length(), 1)
  assert_eq(
    ecosystem_contract_terrain_kind_at(water, 0, 0),
    Some(@energy_valley_contract.Water),
  )
  assert_eq(ecosystem_contract_terrain_walkable_at(water, 0, 0), Some(false))
  assert_eq(ecosystem_contract_terrain_kind_lookup_cache.length(), 1)
  assert_eq(ecosystem_contract_terrain_walkable_lookup_cache.length(), 1)
  assert_false(
    ecosystem_contract_terrain_kind_lookup_cache.contains(
      meadow.blueprint_digest,
    ),
  )
  assert_false(
    ecosystem_contract_terrain_walkable_lookup_cache.contains(
      meadow.blueprint_digest,
    ),
  )
  assert_true(
    ecosystem_contract_terrain_kind_lookup_cache.contains(
      water.blueprint_digest,
    ),
  )
  assert_true(
    ecosystem_contract_terrain_walkable_lookup_cache.contains(
      water.blueprint_digest,
    ),
  )
  ecosystem_cache_test_clear()
}

///|
test "partial terrain cache loss rebuilds both lookup halves" {
  ecosystem_cache_test_clear()
  let water = ecosystem_cache_test_world(
    "terrain-cache-partial",
    @energy_valley_contract.Water,
    false,
  )
  assert_eq(ecosystem_contract_terrain_walkable_at(water, 1, 1), Some(false))
  ecosystem_contract_terrain_kind_lookup_cache.clear()
  assert_eq(ecosystem_contract_terrain_kind_lookup_cache.length(), 0)
  assert_eq(ecosystem_contract_terrain_walkable_lookup_cache.length(), 1)
  assert_eq(
    ecosystem_contract_terrain_kind_at(water, 1, 1),
    Some(@energy_valley_contract.Water),
  )
  assert_eq(ecosystem_contract_terrain_walkable_at(water, 1, 1), Some(false))
  assert_eq(ecosystem_contract_terrain_kind_lookup_cache.length(), 1)
  assert_eq(ecosystem_contract_terrain_walkable_lookup_cache.length(), 1)
  ecosystem_cache_test_clear()
}

///|
test "published world validation metadata follows one authority" {
  ecosystem_cache_test_clear()
  let first = ecosystem_cache_test_world(
    "validation-cache-first",
    @energy_valley_contract.Meadow,
    true,
  )
  let second = ecosystem_cache_test_world(
    "validation-cache-second",
    @energy_valley_contract.Water,
    false,
  )
  ecosystem_contract_publish_world_cache(
    "world-key-first",
    first,
    false,
    "first",
    [],
  )
  ecosystem_contract_publish_world_cache(
    "world-key-second",
    second,
    true,
    "second",
    [],
  )
  assert_eq(ecosystem_contract_world_cache.length(), 1)
  assert_eq(ecosystem_contract_world_validation_failed_cache.length(), 1)
  assert_eq(ecosystem_contract_world_validation_summary_cache.length(), 1)
  assert_eq(ecosystem_contract_world_validation_issues_cache.length(), 1)
  assert_false(ecosystem_contract_world_cache.contains("world-key-first"))
  assert_false(
    ecosystem_contract_world_validation_failed_cache.contains("world-key-first"),
  )
  assert_false(
    ecosystem_contract_world_validation_summary_cache.contains(
      "world-key-first",
    ),
  )
  assert_true(ecosystem_contract_world_cache.contains("world-key-second"))
  assert_eq(
    ecosystem_contract_world_validation_failed_cache.get("world-key-second"),
    Some(true),
  )
  assert_eq(
    ecosystem_contract_world_validation_summary_cache.get("world-key-second"),
    Some("second"),
  )
  assert_true(
    ecosystem_contract_world_validation_issues_cache.contains(
      ecosystem_contract_world_validation_identity(second),
    ),
  )
  assert_false(
    ecosystem_contract_world_validation_issues_cache.contains(
      ecosystem_contract_world_validation_identity(first),
    ),
  )
  ecosystem_cache_test_clear()
}

///|
test "synthetic validation cannot evict current world evidence" {
  ecosystem_cache_test_clear()
  let authority = ecosystem_cache_test_world(
    "validation-authority",
    @energy_valley_contract.Meadow,
    true,
  )
  let synthetic = ecosystem_cache_test_world(
    "validation-synthetic",
    @energy_valley_contract.Water,
    false,
  )
  ecosystem_contract_publish_world_cache(
    "world-key-authority",
    authority,
    false,
    "",
    [],
  )
  ignore(ecosystem_contract_world_validation_issues(synthetic))
  assert_eq(ecosystem_contract_world_validation_issues_cache.length(), 1)
  assert_true(
    ecosystem_contract_world_validation_issues_cache.contains(
      ecosystem_contract_world_validation_identity(authority),
    ),
  )
  assert_false(
    ecosystem_contract_world_validation_issues_cache.contains(
      ecosystem_contract_world_validation_identity(synthetic),
    ),
  )
  ecosystem_contract_world_cache.clear()
  ecosystem_contract_world_validation_issues_cache.clear()
  ignore(ecosystem_contract_world_validation_issues(authority))
  ignore(ecosystem_contract_world_validation_issues(synthetic))
  assert_eq(ecosystem_contract_world_validation_issues_cache.length(), 1)
  assert_false(
    ecosystem_contract_world_validation_issues_cache.contains(
      ecosystem_contract_world_validation_identity(authority),
    ),
  )
  assert_true(
    ecosystem_contract_world_validation_issues_cache.contains(
      ecosystem_contract_world_validation_identity(synthetic),
    ),
  )
  ecosystem_cache_test_clear()
}

///|
test "snapshot validation status and summary share one key" {
  ecosystem_cache_test_clear()
  let first_world = ecosystem_cache_test_world(
    "snapshot-cache-first",
    @energy_valley_contract.Meadow,
    true,
  )
  let second_world = ecosystem_cache_test_world(
    "snapshot-cache-second",
    @energy_valley_contract.Water,
    false,
  )
  let first = @energy_valley_contract.town_snapshot(first_world, 1, [], [])
  let second = @energy_valley_contract.town_snapshot(second_world, 2, [], [])
  let (_, first_invalid) = ecosystem_contract_validated_snapshot(
    first, "snapshot-key-first",
  )
  assert_false(first_invalid)
  let (_, second_invalid) = ecosystem_contract_validated_snapshot(
    second, "snapshot-key-second",
  )
  assert_false(second_invalid)
  assert_eq(ecosystem_contract_snapshot_validation_failed_cache.length(), 1)
  assert_eq(ecosystem_contract_snapshot_validation_summary_cache.length(), 1)
  assert_false(
    ecosystem_contract_snapshot_validation_failed_cache.contains(
      "snapshot-key-first",
    ),
  )
  assert_false(
    ecosystem_contract_snapshot_validation_summary_cache.contains(
      "snapshot-key-first",
    ),
  )
  assert_eq(
    ecosystem_contract_snapshot_validation_failed_cache.get(
      "snapshot-key-second",
    ),
    Some(false),
  )
  assert_true(
    ecosystem_contract_snapshot_validation_summary_cache.contains(
      "snapshot-key-second",
    ),
  )
  ecosystem_cache_test_clear()
}
