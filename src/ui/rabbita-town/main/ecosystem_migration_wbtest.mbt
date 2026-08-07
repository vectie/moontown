///|
fn ecosystem_migration_cache_road_point(
  seed : Int,
) -> SavedWorldDeltaGridPoint? {
  let world = energy_valley_base_contract_world_for_seed(seed)
  let base_roads = town_life_world_base_road_cells(world)
  for node in world.road_network.nodes {
    let node_key = golden_valley_tile_key(node.grid.column, node.grid.row)
    if !base_roads.contains(node_key) {
      continue
    }
    for delta in [(0, -1), (1, 0), (0, 1), (-1, 0)] {
      let point : SavedWorldDeltaGridPoint = {
        x: node.grid.column + delta.0,
        y: node.grid.row + delta.1,
      }
      let key = golden_valley_tile_key(point.x, point.y)
      if !base_roads.contains(key) &&
        town_life_world_road_point_allowed(world, base_roads, point.x, point.y) &&
        town_life_world_reachable_custom_roads(world, [key]) is Some(_) {
        return Some(point)
      }
    }
  }
  None
}

///|
test "ecosystem snapshot cache invalidates on local map deltas" {
  ecosystem_world_snapshot_cache.clear()
  let model = init_model()
  let seed = 20260727
  let base_key = ecosystem_snapshot_cache_key(model, seed)
  let base = ecosystem_cached_world_snapshot(model, seed)
  assert_eq(base.schema, "moontown.energy-valley.ecosystem.v1")
  assert_eq(ecosystem_world_snapshot_cache.length(), 1)
  let repeated = ecosystem_cached_world_snapshot(model, seed)
  assert_eq(repeated.places.length(), base.places.length())
  assert_eq(ecosystem_world_snapshot_cache.length(), 1)
  let point = ecosystem_migration_cache_road_point(seed).unwrap()
  let road_key = golden_valley_tile_key(point.x, point.y)
  let edited = energy_valley_model_replace_roads_delta(
    model,
    energy_valley_model_roads(model) + [road_key],
    energy_valley_model_budget(model),
  )
  assert_true(energy_valley_model_roads(edited).contains(road_key))
  let edited_key = ecosystem_snapshot_cache_key(edited, seed)
  assert_true(edited_key != base_key)
  let _ = ecosystem_cached_world_snapshot(edited, seed)
  assert_eq(ecosystem_world_snapshot_cache.length(), 1)
}

///|
test "attention actions persist cooldown and open their semantic place" {
  let model = { ..init_model(), tick: 12, energy_status_open: true }
  let signals = ecosystem_attention_candidates(model, 20260727, "")
  guard signals.search_by(signal => signal.provenance is AmbientPreview)
    is Some(index) else {
    fail("expected an ambient resident signal")
  }
  let signal = signals[index]
  let (_, next) = ecosystem_open_attention_update(
    model,
    signal.cooldown_key,
    signal.interaction_target,
  )
  assert_eq(next.ecosystem_attention_receipts.length(), 1)
  assert_eq(
    next.ecosystem_attention_receipts[0].cooldown_key,
    signal.cooldown_key,
  )
  assert_true(next.energy_selected_building is Some(_))
  assert_false(next.energy_status_open)
}

///|
test "preview canvas residents expose named scheduled intentions" {
  let model = { ..init_model(), tick: 18 }
  let intention = ecosystem_preview_canvas_intention(model, 7)
  let profile = ecosystem_preview_resident_profile(7)
  assert_eq(intention.resident_name, profile.name)
  assert_true(!intention.place_id.is_empty())
  assert_true(!intention.short_label.is_empty())
  assert_true(intention.provenance is AmbientPreview)
}
