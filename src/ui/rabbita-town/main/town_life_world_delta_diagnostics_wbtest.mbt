///|
test "Map Lab exposes rejected TownLife world events as contract diagnostics" {
  let seed = active_energy_valley_seed()
  let base_world = energy_valley_base_contract_world_for_seed(seed)
  let road_entry = town_life_world_base_road_cells(base_world).to_array()[0]
  let (x, y) = energy_valley_parse_saved_tile(road_entry.0).unwrap()
  let state = town_life_world_empty_state_for_seed(seed)
  let id = "diagnostic-writer:2:world-road-add"
  let event : TownLifeWorldEvent = {
    id,
    dot: { writer_id: "diagnostic-writer", sequence: 2 },
    stamp: { writer_id: "diagnostic-writer", lamport: 2 },
    epoch_id: state.epoch.id,
    kind: WorldRoadCell,
    entity_id: "road-cell-\{x}-\{y}",
    incarnation_id: id,
    action: WorldAdd(WorldRoadCellPayload({ x, y })),
    budget_delta: -3000,
  }
  let model = town_life_world_reproject_model(
    { ..init_model(), town_life_world_states: [{ ..state, events: [event] }] },
    seed,
  )
  let snapshot = ecosystem_contract_town_snapshot(model, seed)
  let matching = snapshot.world.diagnostics.filter(diagnostic => {
    diagnostic.stage == @energy_valley_contract.DeltaApplication &&
    diagnostic.code == @energy_valley_contract.DeltaConflict &&
    diagnostic.message.contains("budget-exhausted") &&
    diagnostic.evidence_id == Some(id)
  })
  assert_eq(matching.length(), 1)
  let page = map_lab_visible_entities(snapshot, "budget-exhausted")
  assert_true(page.rows.any(row => row.category == "world diagnostic"))
  assert_eq(
    map_lab_counts(snapshot).diagnostics,
    snapshot.world.diagnostics.length(),
  )
}

///|
test "duplicate external event ids still produce unique valid diagnostics" {
  let seed = active_energy_valley_seed()
  let state = town_life_world_empty_state_for_seed(seed)
  let shared_id = "duplicated-external-event-id"
  let first : TownLifeWorldEvent = {
    id: shared_id,
    dot: { writer_id: "duplicate-a", sequence: 2 },
    stamp: { writer_id: "duplicate-a", lamport: 2 },
    epoch_id: state.epoch.id,
    kind: WorldRoadCell,
    entity_id: "road-cell-4-4",
    incarnation_id: shared_id,
    action: WorldAdd(WorldRoadCellPayload({ x: 4, y: 5 })),
    budget_delta: 0,
  }
  let second : TownLifeWorldEvent = {
    id: shared_id,
    dot: { writer_id: "duplicate-b", sequence: 2 },
    stamp: { writer_id: "duplicate-b", lamport: 2 },
    epoch_id: state.epoch.id,
    kind: WorldRoadCell,
    entity_id: "road-cell-7-7",
    incarnation_id: shared_id,
    action: WorldAdd(WorldRoadCellPayload({ x: 7, y: 8 })),
    budget_delta: 0,
  }
  let model = town_life_world_reproject_model(
    {
      ..init_model(),
      town_life_world_states: [{ ..state, events: [first, second] }],
    },
    seed,
  )
  let world = ecosystem_contract_world_for_model(model, seed)
  let matching = world.diagnostics.filter(diagnostic => {
    diagnostic.stage == @energy_valley_contract.DeltaApplication &&
    diagnostic.evidence_id == Some(shared_id)
  })
  assert_eq(matching.length(), 2)
  assert_true(matching[0].id != matching[1].id)
  assert_false(
    @energy_valley_contract.has_errors(
      @energy_valley_contract.validate_world(world),
    ),
  )
}
