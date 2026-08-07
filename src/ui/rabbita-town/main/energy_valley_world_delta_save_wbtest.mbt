///|
test "v3 WorldDelta save roundtrips typed authored operations" {
  let legacy : EnergyValleySave = {
    budget: 1700,
    buildings: [
      {
        authored_id: Some("authored-building-9"),
        module_key: None,
        name: "Delta Lab",
        style: "custom-lab",
        x: 30,
        y: 40,
        width: 6,
        depth: 6,
        entrance_x: Some(30),
        entrance_y: Some(39),
        floors: 2,
      },
    ],
    roads: ["20:21"],
    parks: ["22:23"],
    next_authored_building_sequence: Some(10),
  }
  let delta = energy_valley_world_delta_from_projection(
    legacy, 7, "fixture-base-digest",
  )
  let text = ToJson::to_json(delta).stringify()
  let decoded = decode_energy_valley_world_delta_save(text).unwrap()
  let restored = energy_valley_world_delta_projection(decoded)
  assert_eq(decoded.revision, 7)
  assert_eq(decoded.operations.length(), 3)
  assert_eq(restored.budget, legacy.budget)
  assert_eq(
    ToJson::to_json(restored.buildings).stringify(),
    ToJson::to_json(legacy.buildings).stringify(),
  )
  assert_eq(restored.roads, legacy.roads)
  assert_eq(restored.parks, legacy.parks)
  assert_eq(
    restored.next_authored_building_sequence,
    legacy.next_authored_building_sequence,
  )
  assert_true(!text.contains("\"roads\":["))
  assert_true(!text.contains("\"parks\":["))
}

///|
test "UI deltas target and validate against the exact base blueprint" {
  let seed = 20260727
  let ledger = energy_valley_world_delta_from_projection(
    {
      budget: 2400,
      buildings: [],
      roads: ["20:21", "21:21"],
      parks: ["22:23"],
      next_authored_building_sequence: Some(1),
    },
    4,
    energy_valley_base_blueprint_digest_for_seed(seed),
  )
  let model = { ..init_model(), energy_world_delta: ledger }
  let base = ecosystem_contract_world_from_snapshot(
    ecosystem_world_snapshot(golden_valley_world(seed), [], [], []),
    seed,
  )
  let delta = energy_valley_contract_world_delta_for_model(model, seed)
  assert_true(delta.targets(base))
  assert_true(
    @energy_valley_contract.validate_world_delta(delta, base_world=Some(base)).is_empty(),
  )
  let projected = energy_valley_project_contract_world_delta(delta)
  assert_eq(projected.roads, ["20:21", "21:21"])
  assert_eq(projected.parks, ["22:23"])
}

///|
fn energy_valley_world_delta_test_valid_labs(
  seed : Int,
  count : Int,
) -> Array[GoldenValleyBuilding] {
  let world = energy_valley_base_contract_world_for_seed(seed)
  let scale = energy_valley_semantic_cells_per_planning_cell()
  let result : Array[GoldenValleyBuilding] = []
  for y in 1..<(golden_valley_rows() - 1) {
    for x in 1..<(golden_valley_cols() - 1) {
      if x % scale != 0 || y % scale != 0 {
        continue
      }
      match
        golden_valley_custom_building(LaboratoryTool, x, y, result.length() + 1) {
        Some(building) if golden_valley_custom_placement_block_in_world(
            world, building,
          )
          is None => {
          result.push(building)
          if result.length() == count {
            return result
          }
        }
        _ => ()
      }
    }
  }
  result
}

///|
test "TownLife Add Move Delete stays canonical after compiler caches warm" {
  let seed = active_energy_valley_seed()
  let base = {
    ..init_model(),
    energy_world_delta: energy_valley_empty_world_delta_for_seed(seed),
    town_life_world_states: [],
    town_life_writer_counters: [],
  }
  // This is intentionally run after both renderer caches are populated. A
  // mutation must use the same canonical parcel/frontage truth regardless of
  // test or UI call order.
  ignore(ecosystem_cached_world_snapshot(base, seed))
  ignore(ecosystem_contract_world_for_model(base, seed))
  let sites = energy_valley_world_delta_test_valid_labs(seed, 2)
  assert_eq(sites.length(), 2)
  let building : GoldenValleyBuilding = {
    ..sites[0],
    authored_id: Some("authored-building-41"),
    module_key: Some("book/community-energy"),
    name: "Community Energy Lab",
    style: "custom-lab",
    floors: 2,
  }
  let (added, identified) = energy_valley_model_add_building_delta_with_identity(
    base, building, 1900, 42,
  )
  let physical_id = golden_valley_nonempty_authored_id(identified).unwrap()
  assert_true(physical_id.has_prefix("authored-building-v3-"))
  assert_eq(energy_valley_model_buildings(added).length(), 1)
  let destination = sites[1]
  let moved = energy_valley_model_append_delta_operations(
    added,
    [
      MoveBuilding({
        id: physical_id,
        x: destination.x,
        y: destination.y,
        width: destination.width,
        depth: destination.depth,
        entrance_x: destination.entrance_x,
        entrance_y: destination.entrance_y,
      }),
    ],
    1900,
    42,
  )
  let moved_buildings = energy_valley_model_buildings(moved)
  assert_eq(moved_buildings.length(), 1)
  let restored = moved_buildings[0]
  assert_eq(restored.authored_id, identified.authored_id)
  assert_eq(restored.module_key, building.module_key)
  assert_eq(restored.name, building.name)
  assert_eq(restored.style, building.style)
  assert_eq((restored.x, restored.y), (destination.x, destination.y))
  assert_eq(
    (restored.width, restored.depth),
    (destination.width, destination.depth),
  )
  assert_eq(
    (restored.entrance_x, restored.entrance_y),
    (destination.entrance_x, destination.entrance_y),
  )
  let deleted = energy_valley_model_delete_building_delta(moved, restored, 2150)
  assert_true(energy_valley_model_buildings(deleted).is_empty())
  // Even when reference readiness deferred persistence and Model has no world
  // state, the mutation path materializes/observes genesis before allocation.
  assert_true(
    added.energy_world_delta.revision > base.energy_world_delta.revision,
  )
  assert_true(
    moved.energy_world_delta.revision > added.energy_world_delta.revision,
  )
  assert_true(
    deleted.energy_world_delta.revision > moved.energy_world_delta.revision,
  )
  assert_eq(
    town_life_world_state_for_seed(deleted.town_life_world_states, seed).events.length(),
    3,
  )
  let reloaded = decode_energy_valley_world_delta_save(
    ToJson::to_json(deleted.energy_world_delta).stringify(),
  ).unwrap()
  assert_eq(reloaded.revision, deleted.energy_world_delta.revision)
  // The compatibility ledger is a canonical current-state adapter; immutable
  // Add/Move/Delete history remains in TownLife world events above.
  assert_true(reloaded.operations.is_empty())
  assert_eq(
    energy_valley_contract_world_delta(reloaded).revision,
    deleted.energy_world_delta.revision,
  )
}

///|
test "mismatched blueprint delta is rejected instead of rebound" {
  let seed = 20260727
  let valid = energy_valley_empty_world_delta_for_seed(seed)
  let stale = { ..valid, base_blueprint_digest: "sha256:stale-blueprint" }
  assert_false(energy_valley_world_delta_targets_seed(stale, seed))
  assert_false(energy_valley_world_delta_valid_for_seed(stale, seed))
  let model = { ..init_model(), energy_world_delta: stale }
  let projected = energy_valley_validated_world_delta_projection(model, seed)
  assert_true(projected.buildings.is_empty())
  assert_true(projected.roads.is_empty())
  assert_true(projected.parks.is_empty())
  assert_eq(stale.base_blueprint_digest, "sha256:stale-blueprint")
}

///|
test "legacy v2 arrays migrate once into a v3 typed ledger" {
  let seed = 20260727
  let legacy : EnergyValleySave = {
    budget: 1700,
    buildings: [
      {
        authored_id: None,
        module_key: Some("legacy-module"),
        name: "Legacy Lab",
        style: "custom-lab",
        x: 30,
        y: 40,
        width: 6,
        depth: 6,
        entrance_x: Some(30),
        entrance_y: Some(39),
        floors: 2,
      },
    ],
    roads: [],
    parks: [],
    next_authored_building_sequence: None,
  }
  let migrated = decode_legacy_energy_valley_v2(
    ToJson::to_json(legacy).stringify(),
    seed,
  ).unwrap()
  assert_eq(migrated.schema_version, energy_valley_world_delta_schema())
  assert_eq(migrated.revision, 1)
  let persisted = ToJson::to_json(migrated).stringify()
  assert_true(decode_energy_valley_world_delta_save(persisted) is Some(_))
  assert_true(decode_legacy_energy_valley_v2(persisted, seed) is None)
  let buildings = energy_valley_world_delta_projection(migrated).buildings
  assert_eq(buildings.length(), 1)
  assert_true(golden_valley_nonempty_authored_id(buildings[0]) is Some(_))
  assert_eq(buildings[0].module_key, Some("legacy-module"))
  assert_eq(
    (buildings[0].entrance_x, buildings[0].entrance_y),
    (Some(30), Some(39)),
  )
}

///|
test "all nine saved operations convert and project exhaustively" {
  let seed = 20260727
  let base = energy_valley_empty_world_delta_for_seed(seed)
  let building : GoldenValleyBuilding = {
    authored_id: Some("authored-building-70"),
    module_key: Some("nine-ops"),
    name: "Nine operation lab",
    style: "custom-lab",
    x: 20,
    y: 20,
    width: 4,
    depth: 4,
    entrance_x: Some(21),
    entrance_y: Some(19),
    floors: 2,
  }
  let operations : Array[SavedWorldDeltaOperation] = [
    AddBuilding({ id: "authored-building-70", building }),
    MoveBuilding({
      id: "authored-building-70",
      x: 24,
      y: 25,
      width: 4,
      depth: 4,
      entrance_x: Some(25),
      entrance_y: Some(24),
    }),
    DeleteBuilding({ id: "authored-building-70" }),
    AddRoad({
      id: "authored-road-component-20-20",
      path: [{ x: 20, y: 20 }, { x: 21, y: 20 }],
    }),
    MoveRoad({
      id: "authored-road-component-20-20",
      path: [{ x: 20, y: 20 }, { x: 21, y: 20 }, { x: 22, y: 20 }],
    }),
    DeleteRoad({ id: "authored-road-component-20-20" }),
    AddPark({ id: "authored-park-30-30", x: 30, y: 30 }),
    MovePark({ id: "authored-park-30-30", x: 31, y: 32 }),
    DeletePark({ id: "authored-park-30-30" }),
  ]
  let ledger : EnergyValleyWorldDeltaLedger = {
    ..base,
    revision: 10,
    operations,
    content_digest: Some(energy_valley_saved_operations_digest(operations)),
  }
  let contract = energy_valley_contract_world_delta(ledger)
  assert_eq(contract.operations.length(), 9)
  assert_true(contract.operations[0] is @energy_valley_contract.AddBuilding(_))
  assert_true(contract.operations[1] is @energy_valley_contract.MoveBuilding(_))
  assert_true(
    contract.operations[2] is @energy_valley_contract.DeleteBuilding(_),
  )
  assert_true(contract.operations[3] is @energy_valley_contract.AddRoad(_))
  assert_true(contract.operations[4] is @energy_valley_contract.MoveRoad(_))
  assert_true(contract.operations[5] is @energy_valley_contract.DeleteRoad(_))
  assert_true(contract.operations[6] is @energy_valley_contract.AddPark(_))
  assert_true(contract.operations[7] is @energy_valley_contract.MovePark(_))
  assert_true(contract.operations[8] is @energy_valley_contract.DeletePark(_))
  assert_false(
    @energy_valley_contract.has_errors(
      @energy_valley_contract.validate_world_delta(contract),
    ),
  )
  let projected = energy_valley_project_contract_world_delta(contract)
  assert_true(projected.buildings.is_empty())
  assert_true(projected.roads.is_empty())
  assert_true(projected.parks.is_empty())
}
