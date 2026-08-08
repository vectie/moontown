///|
fn world_compaction_fixture_add(
  state : TownLifeWorldState,
  building : GoldenValleyBuilding,
) -> TownLifeWorldEvent {
  adversarial_world_event(
    state.epoch,
    "compact-writer",
    1,
    2,
    "world-building-add",
    WorldBuilding,
    "compact-building",
    "compact-writer:1:world-building-add",
    WorldAdd(
      WorldBuildingPayload({ ..building, authored_id: Some("compact-building") }),
    ),
    -120,
  )
}

///|
fn world_compaction_fixture_move(
  state : TownLifeWorldState,
  add : TownLifeWorldEvent,
  building : GoldenValleyBuilding,
  sequence : Int,
) -> TownLifeWorldEvent {
  adversarial_world_event(
    state.epoch,
    "compact-writer",
    sequence,
    sequence + 1,
    "world-move",
    WorldBuilding,
    add.entity_id,
    add.incarnation_id,
    WorldMove(
      WorldBuildingPayload({ ..building, authored_id: Some(add.entity_id) }),
    ),
    0,
  )
}

///|
test "world normalization compacts dominated moves and stale replay is harmless" {
  let seed = active_energy_valley_seed()
  let state = town_life_world_empty_state_for_seed(seed)
  let building = adversarial_world_valid_building().unwrap()
  let add = world_compaction_fixture_add(state, building)
  let first = world_compaction_fixture_move(state, add, building, 2)
  let second = world_compaction_fixture_move(state, add, building, 3)
  let latest = world_compaction_fixture_move(state, add, building, 4)
  let compacted = town_life_world_normalize_state({
    ..state,
    events: [second, add, latest, first],
  })
  assert_eq(compacted.events.length(), 2)
  assert_true(compacted.events.any(event => event.id == add.id))
  assert_true(compacted.events.any(event => event.id == latest.id))
  let replayed = town_life_world_merge_state(compacted, {
    ..state,
    events: [add, first, second],
  })
  assert_eq(replayed.events.length(), 2)
  assert_true(replayed.events.any(event => event.id == latest.id))
  assert_eq(
    ToJson::to_json(replayed).stringify(),
    ToJson::to_json(town_life_world_merge_state(replayed, compacted)).stringify(),
  )
  let a = { ..state, events: [add, first] }
  let b = { ..state, events: [second] }
  let c = { ..state, events: [latest] }
  assert_eq(
    ToJson::to_json(town_life_world_merge_state(a, b)).stringify(),
    ToJson::to_json(town_life_world_merge_state(b, a)).stringify(),
  )
  assert_eq(
    ToJson::to_json(
      town_life_world_merge_state(town_life_world_merge_state(a, b), c),
    ).stringify(),
    ToJson::to_json(
      town_life_world_merge_state(a, town_life_world_merge_state(c, b)),
    ).stringify(),
  )
}

///|
test "world normalization retains earliest deletion across stale shards" {
  let seed = active_energy_valley_seed()
  let state = town_life_world_empty_state_for_seed(seed)
  let building = adversarial_world_valid_building().unwrap()
  let add = world_compaction_fixture_add(state, building)
  let first_delete = adversarial_world_event(
    state.epoch,
    "compact-writer",
    2,
    3,
    "world-delete",
    WorldBuilding,
    add.entity_id,
    add.incarnation_id,
    WorldDelete,
    60,
  )
  let later_delete = adversarial_world_event(
    state.epoch,
    "stale-writer",
    9,
    9,
    "world-delete",
    WorldBuilding,
    add.entity_id,
    add.incarnation_id,
    WorldDelete,
    60,
  )
  let compacted = town_life_world_normalize_state({
    ..state,
    events: [later_delete, first_delete, add],
  })
  let resolved = town_life_world_resolve_incarnations(compacted)
  assert_eq(resolved.length(), 1)
  assert_eq(resolved[0].deletion.unwrap().id, first_delete.id)
  let replayed = town_life_world_merge_state(compacted, {
    ..state,
    events: [add],
  })
  assert_true(town_life_world_projection(replayed, seed).active.is_empty())
  assert_eq(
    town_life_world_resolve_incarnations(replayed)[0].deletion.unwrap().id,
    first_delete.id,
  )
}

///|
test "orphan transition compaction remains safe when Add arrives late" {
  let seed = active_energy_valley_seed()
  let state = town_life_world_empty_state_for_seed(seed)
  let building = adversarial_world_valid_building().unwrap()
  let add = world_compaction_fixture_add(state, building)
  let first_move = world_compaction_fixture_move(state, add, building, 2)
  let first_delete = adversarial_world_event(
    state.epoch,
    "compact-writer",
    3,
    4,
    "world-delete",
    WorldBuilding,
    add.entity_id,
    add.incarnation_id,
    WorldDelete,
    60,
  )
  let later_delete = adversarial_world_event(
    state.epoch,
    "compact-writer",
    4,
    5,
    "world-delete",
    WorldBuilding,
    add.entity_id,
    add.incarnation_id,
    WorldDelete,
    60,
  )
  let latest_move = world_compaction_fixture_move(state, add, building, 5)
  let orphan = town_life_world_normalize_state({
    ..state,
    events: [later_delete, first_move, latest_move, first_delete],
  })
  assert_eq(orphan.events.length(), 3)
  assert_true(orphan.events.any(event => event.id == latest_move.id))
  assert_true(orphan.events.any(event => event.id == first_delete.id))
  assert_true(orphan.events.any(event => event.id == later_delete.id))
  let completed = town_life_world_merge_state(orphan, { ..state, events: [add] })
  let direct = town_life_world_normalize_state({
    ..state,
    events: [add, first_move, first_delete, later_delete, latest_move],
  })
  assert_eq(
    ToJson::to_json(completed).stringify(),
    ToJson::to_json(direct).stringify(),
  )
  let resolved = town_life_world_resolve_incarnations(completed)
  assert_eq(resolved[0].movement.unwrap().id, latest_move.id)
  assert_eq(resolved[0].deletion.unwrap().id, first_delete.id)
}

///|
test "noncanonical valid transitions stay outside semantic compaction" {
  let seed = active_energy_valley_seed()
  let state = town_life_world_empty_state_for_seed(seed)
  let building = adversarial_world_valid_building().unwrap()
  let add = world_compaction_fixture_add(state, building)
  let manual = adversarial_world_event(
    state.epoch,
    "compact-writer",
    2,
    3,
    "manual-move",
    WorldBuilding,
    add.entity_id,
    add.incarnation_id,
    WorldMove(
      WorldBuildingPayload({ ..building, authored_id: Some(add.entity_id) }),
    ),
    0,
  )
  let latest = world_compaction_fixture_move(state, add, building, 3)
  assert_false(town_life_world_event_compaction_eligible(manual))
  assert_true(town_life_world_event_compaction_eligible(latest))
  let normalized = town_life_world_normalize_state({
    ..state,
    events: [latest, manual, add],
  })
  assert_eq(normalized.events.length(), 3)
  assert_true(normalized.events.any(event => event.id == manual.id))
}

///|
test "malformed by-dot winner fences lower valid stale replay" {
  let state = town_life_world_empty_state_for_seed(active_energy_valley_seed())
  let building = adversarial_world_valid_building().unwrap()
  let valid = adversarial_world_event(
    state.epoch,
    "same-dot-writer",
    2,
    2,
    "event",
    WorldBuilding,
    "same-dot-site",
    "same-dot-writer:2:event",
    WorldAdd(
      WorldBuildingPayload({ ..building, authored_id: Some("same-dot-site") }),
    ),
    -120,
  )
  let malformed = adversarial_world_event(
    state.epoch,
    "same-dot-writer",
    2,
    2,
    "event",
    WorldBuilding,
    "same-dot-site",
    "zzzz-invalid-incarnation",
    WorldAdd(
      WorldBuildingPayload({ ..building, authored_id: Some("same-dot-site") }),
    ),
    -120,
  )
  assert_eq(
    town_life_world_prefer_event(valid, malformed).incarnation_id,
    malformed.incarnation_id,
  )
  let compacted = town_life_world_normalize_state({
    ..state,
    events: [malformed],
  })
  assert_eq(compacted.events.length(), 1)
  assert_eq(compacted.events[0].incarnation_id, malformed.incarnation_id)
  let replayed = town_life_world_merge_state(compacted, {
    ..state,
    events: [valid],
  })
  assert_eq(replayed.events.length(), 1)
  assert_eq(replayed.events[0].incarnation_id, malformed.incarnation_id)
  assert_true(
    town_life_world_projection(replayed, active_energy_valley_seed()).active.is_empty(),
  )
  assert_eq(
    ToJson::to_json(replayed).stringify(),
    ToJson::to_json(town_life_world_merge_state(replayed, compacted)).stringify(),
  )
}

///|
test "late Add between orphan Deletes cannot resurrect an incarnation" {
  let seed = active_energy_valley_seed()
  let state = town_life_world_empty_state_for_seed(seed)
  let building = adversarial_world_valid_building().unwrap()
  let add = adversarial_world_event(
    state.epoch,
    "late-add-writer",
    3,
    3,
    "world-building-add",
    WorldBuilding,
    "late-add-site",
    "late-add-writer:3:world-building-add",
    WorldAdd(
      WorldBuildingPayload({ ..building, authored_id: Some("late-add-site") }),
    ),
    -120,
  )
  let before = adversarial_world_event(
    state.epoch,
    "delete-before-writer",
    1,
    1,
    "world-delete",
    WorldBuilding,
    add.entity_id,
    add.incarnation_id,
    WorldDelete,
    60,
  )
  let after = adversarial_world_event(
    state.epoch,
    "delete-after-writer",
    5,
    5,
    "world-delete",
    WorldBuilding,
    add.entity_id,
    add.incarnation_id,
    WorldDelete,
    60,
  )
  let orphan = town_life_world_normalize_state({
    ..state,
    events: [after, before],
  })
  assert_eq(orphan.events.length(), 2)
  let completed = town_life_world_merge_state(orphan, { ..state, events: [add] })
  let direct = town_life_world_normalize_state({
    ..state,
    events: [before, add, after],
  })
  assert_eq(
    ToJson::to_json(completed).stringify(),
    ToJson::to_json(direct).stringify(),
  )
  assert_true(town_life_world_projection(completed, seed).active.is_empty())
  assert_eq(
    town_life_world_resolve_incarnations(completed)[0].deletion.unwrap().id,
    after.id,
  )
}
