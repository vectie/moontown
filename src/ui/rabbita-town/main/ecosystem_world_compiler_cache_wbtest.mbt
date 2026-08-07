///|
fn ecosystem_cache_rejected_park_model(
  seed : Int,
  writer : String,
  entity_id : String,
) -> (Model, String) {
  let model = init_model()
  let state = town_life_world_empty_state_for_seed(seed)
  let event_id = "\{writer}:2:add"
  let event : TownLifeWorldEvent = {
    id: event_id,
    dot: { writer_id: writer, sequence: 2 },
    stamp: { writer_id: writer, lamport: 2 },
    epoch_id: state.epoch.id,
    kind: WorldPark,
    entity_id,
    incarnation_id: event_id,
    action: WorldAdd(WorldParkPayload({ id: entity_id, x: -1, y: -1 })),
    budget_delta: 0,
  }
  let next = town_life_world_reproject_model(
    { ..model, town_life_world_states: [{ ..state, events: [event] }] },
    seed,
  )
  (next, event_id)
}

///|
test "compiler cache keys the full rejected projection content" {
  let seed = active_energy_valley_seed()
  let (left, left_event_id) = ecosystem_cache_rejected_park_model(
    seed, "cache-left", "cache-left-invalid-park",
  )
  let (right, right_event_id) = ecosystem_cache_rejected_park_model(
    seed, "cache-right", "cache-right-invalid-park",
  )
  assert_eq(left.energy_world_delta.revision, right.energy_world_delta.revision)
  assert_eq(
    ToJson::to_json(left.energy_world_delta).stringify(),
    ToJson::to_json(right.energy_world_delta).stringify(),
  )
  let left_projection = town_life_world_projection_for_states(
    left.town_life_world_states,
    seed,
  )
  let right_projection = town_life_world_projection_for_states(
    right.town_life_world_states,
    seed,
  )
  assert_eq(left_projection.rejected.length(), 1)
  assert_eq(right_projection.rejected.length(), 1)
  assert_true(
    left_projection.rejected[0].event_id !=
    right_projection.rejected[0].event_id,
  )
  let left_geometry_key = ecosystem_snapshot_cache_key(left, seed)
  let right_geometry_key = ecosystem_snapshot_cache_key(right, seed)
  assert_eq(left_geometry_key, right_geometry_key)
  let left_contract_key = ecosystem_contract_world_cache_key(left, seed)
  let right_contract_key = ecosystem_contract_world_cache_key(right, seed)
  assert_true(left_contract_key != right_contract_key)
  ecosystem_world_snapshot_cache.clear()
  ecosystem_contract_world_cache.clear()
  let left_world = ecosystem_contract_world_for_model(left, seed)
  assert_true(ecosystem_world_snapshot_cache.contains(left_geometry_key))
  assert_true(
    left_world.diagnostics.any(diagnostic => {
      diagnostic.evidence_id == Some(left_event_id)
    }),
  )
  let right_world = ecosystem_contract_world_for_model(right, seed)
  assert_true(ecosystem_world_snapshot_cache.contains(right_geometry_key))
  assert_eq(ecosystem_world_snapshot_cache.length(), 1)
  assert_true(
    right_world.diagnostics.any(diagnostic => {
      diagnostic.evidence_id == Some(right_event_id)
    }),
  )
  assert_false(
    right_world.diagnostics.any(diagnostic => {
      diagnostic.evidence_id == Some(left_event_id)
    }),
  )
}
