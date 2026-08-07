///|
fn adversarial_world_event(
  epoch : TownLifeWorldEpoch,
  writer : String,
  sequence : Int,
  lamport : Int,
  label : String,
  kind : TownLifeWorldKind,
  entity_id : String,
  incarnation_id : String,
  action : TownLifeWorldAction,
  budget_delta : Int,
) -> TownLifeWorldEvent {
  {
    id: "\{writer}:\{sequence}:\{label}",
    dot: { writer_id: writer, sequence },
    stamp: { writer_id: writer, lamport },
    epoch_id: epoch.id,
    kind,
    entity_id,
    incarnation_id,
    action,
    budget_delta,
  }
}

///|
fn adversarial_world_road_event(
  epoch : TownLifeWorldEpoch,
  writer : String,
  sequence : Int,
  lamport : Int,
  label : String,
  point : SavedWorldDeltaGridPoint,
) -> TownLifeWorldEvent {
  let entity_id = "road-cell-\{point.x}-\{point.y}"
  adversarial_world_event(
    epoch,
    writer,
    sequence,
    lamport,
    label,
    WorldRoadCell,
    entity_id,
    "\{writer}:\{sequence}:\{label}",
    WorldAdd(WorldRoadCellPayload(point)),
    0,
  )
}

///|
fn adversarial_world_reachable_road_points(
  seed : Int,
  count : Int,
) -> Array[SavedWorldDeltaGridPoint] {
  let world = energy_valley_base_contract_world_for_seed(seed)
  let result : Array[SavedWorldDeltaGridPoint] = []
  let seen : Map[String, Bool] = Map([])
  for node in world.road_network.nodes {
    let key = golden_valley_tile_key(node.grid.column, node.grid.row)
    if !seen.contains(key) &&
      world.road_network.is_reachable_from_anchor(
        node.id,
        mode=@energy_valley_contract.ServiceVehicle,
      ) {
      seen[key] = true
      result.push({ x: node.grid.column, y: node.grid.row })
      if result.length() >= count {
        return result
      }
    }
  }
  result
}

///|
fn adversarial_world_custom_road_stroke(
  seed : Int,
  count : Int,
) -> Array[SavedWorldDeltaGridPoint] {
  if count <= 0 {
    return []
  }
  let world = energy_valley_base_contract_world_for_seed(seed)
  let base_roads = town_life_world_base_road_cells(world)
  let candidates : Map[String, SavedWorldDeltaGridPoint] = Map([])
  for y in 0..<golden_valley_rows() {
    for x in 0..<golden_valley_cols() {
      let key = golden_valley_tile_key(x, y)
      if !base_roads.contains(key) &&
        town_life_world_road_point_allowed(world, base_roads, x, y) {
        candidates[key] = { x, y }
      }
    }
  }
  let roots = candidates.to_array()
  roots.sort_by((left, right) => left.0.compare(right.0))
  let visited : Map[String, Bool] = Map([])
  for root in roots {
    if visited.contains(root.0) {
      continue
    }
    let touches_base = [(0, -1), (1, 0), (0, 1), (-1, 0)].any(delta => {
      base_roads.contains(
        golden_valley_tile_key(root.1.x + delta.0, root.1.y + delta.1),
      )
    })
    if !touches_base {
      continue
    }
    let component : Array[SavedWorldDeltaGridPoint] = []
    let queue : Array[SavedWorldDeltaGridPoint] = [root.1]
    visited[root.0] = true
    let mut cursor = 0
    while cursor < queue.length() {
      let point = queue[cursor]
      cursor += 1
      component.push(point)
      for delta in [(0, -1), (1, 0), (0, 1), (-1, 0)] {
        let key = golden_valley_tile_key(point.x + delta.0, point.y + delta.1)
        match candidates.get(key) {
          Some(next) if !visited.contains(key) => {
            visited[key] = true
            queue.push(next)
          }
          _ => ()
        }
      }
    }
    if component.length() >= count {
      let stroke : Array[SavedWorldDeltaGridPoint] = []
      for index in 0..<count {
        stroke.push(component[index])
      }
      return stroke
    }
  }
  []
}

///|
let adversarial_world_valid_building_cache : Array[GoldenValleyBuilding] = []

///|
fn adversarial_world_valid_building() -> GoldenValleyBuilding? {
  if !adversarial_world_valid_building_cache.is_empty() {
    return Some(adversarial_world_valid_building_cache[0])
  }
  let world = energy_valley_base_contract_world_for_seed(
    active_energy_valley_seed(),
  )
  let base_roads = town_life_world_base_road_cells(world)
  let custom_roads : Map[String, Bool] = Map([])
  for y in 1..<(golden_valley_rows() - 1) {
    for x in 1..<(golden_valley_cols() - 1) {
      let fixture : GoldenValleyBuilding = {
        authored_id: None,
        module_key: None,
        name: "Adversarial world fixture",
        style: "custom-tower",
        x,
        y,
        width: 1,
        depth: 1,
        entrance_x: Some(x),
        entrance_y: Some(y),
        floors: 1,
      }
      if town_life_world_building_base_valid(
          world, base_roads, custom_roads, fixture,
        ) {
        adversarial_world_valid_building_cache.push(fixture)
        return Some(fixture)
      }
    }
  }
  None
}

///|
fn adversarial_world_three_cell_dependent_chain(
  world : @energy_valley_contract.CompiledTownWorld,
) -> (
  SavedWorldDeltaGridPoint,
  SavedWorldDeltaGridPoint,
  SavedWorldDeltaGridPoint,
)? {
  let (connector, middle) = match
    world_projection_isolation_dependent_chain(world) {
    Some(value) => value
    None => return None
  }
  let base_roads = town_life_world_base_road_cells(world)
  let connector_key = golden_valley_tile_key(connector.x, connector.y)
  let middle_key = golden_valley_tile_key(middle.x, middle.y)
  for delta in [(0, -1), (1, 0), (0, 1), (-1, 0)] {
    let far : SavedWorldDeltaGridPoint = {
      x: middle.x + delta.0,
      y: middle.y + delta.1,
    }
    let far_key = golden_valley_tile_key(far.x, far.y)
    if far_key != connector_key &&
      far_key != middle_key &&
      !base_roads.contains(far_key) &&
      town_life_world_road_point_allowed(world, base_roads, far.x, far.y) &&
      town_life_world_reachable_custom_roads(world, [far_key]) is None &&
      town_life_world_reachable_custom_roads(world, [middle_key, far_key])
      is None &&
      town_life_world_reachable_custom_roads(world, [
        connector_key, middle_key, far_key,
      ])
      is Some(_) {
      return Some((connector, middle, far))
    }
  }
  None
}

///|
fn adversarial_world_diagonal_frontage_fixture(
  seed : Int,
) -> (GoldenValleyBuilding, SavedWorldDeltaGridPoint)? {
  ignore(seed)
  Some(
    (
      {
        authored_id: None,
        module_key: None,
        name: "Diagonal frontage probe",
        style: "custom-tower",
        x: 100,
        y: 59,
        width: 1,
        depth: 1,
        entrance_x: Some(100),
        entrance_y: Some(59),
        floors: 1,
      },
      { x: 101, y: 58 },
    ),
  )
}

///|
fn adversarial_world_state_json(state : TownLifeWorldState) -> String {
  ToJson::to_json(town_life_world_normalize_state(state)).stringify()
}

///|
fn adversarial_world_projection_json(
  projection : TownLifeWorldProjection,
) -> String {
  ToJson::to_json(projection.ledger).stringify()
}

///|
test "world CRDT merge and projection are commutative associative idempotent" {
  let seed = active_energy_valley_seed()
  let points = adversarial_world_reachable_road_points(seed, 3)
  assert_true(points.length() >= 3)
  let base = town_life_world_empty_state_for_seed(seed)
  let a = adversarial_world_road_event(
    base.epoch,
    "writer-a",
    2,
    2,
    "add-a",
    points[0],
  )
  let b = adversarial_world_road_event(
    base.epoch,
    "writer-b",
    2,
    2,
    "add-b",
    points[1],
  )
  // Same dot, deliberately conflicting payload. Normalization must choose one
  // payload deterministically, independent of shard order.
  let conflicting_a = adversarial_world_road_event(
    base.epoch,
    "writer-a",
    2,
    2,
    "zz-conflict",
    points[2],
  )
  let left = { ..base, events: [a] }
  let right = { ..base, events: [b] }
  let conflict = {
    ..base,
    epoch: { ..base.epoch, base_budget: base.epoch.base_budget - 1 },
    events: [conflicting_a],
  }
  assert_eq(
    adversarial_world_state_json(town_life_world_merge_state(left, right)),
    adversarial_world_state_json(town_life_world_merge_state(right, left)),
  )
  let first = town_life_world_merge_state(
    town_life_world_merge_state(left, right),
    conflict,
  )
  let second = town_life_world_merge_state(
    left,
    town_life_world_merge_state(right, conflict),
  )
  let third = town_life_world_merge_state(
    conflict,
    town_life_world_merge_state(right, left),
  )
  assert_eq(
    adversarial_world_state_json(first),
    adversarial_world_state_json(second),
  )
  assert_eq(
    adversarial_world_state_json(first),
    adversarial_world_state_json(third),
  )
  assert_eq(
    adversarial_world_state_json(first),
    adversarial_world_state_json(town_life_world_merge_state(first, first)),
  )
  let first_projection = town_life_world_projection(first, seed)
  for candidate in [second, third, town_life_world_merge_state(first, first)] {
    let projected = town_life_world_projection(candidate, seed)
    assert_eq(
      adversarial_world_projection_json(first_projection),
      adversarial_world_projection_json(projected),
    )
    assert_eq(first_projection.rejected, projected.rejected)
  }
}

///|
test "pre-Add move and delete cannot suppress or charge the later Add" {
  let seed = active_energy_valley_seed()
  let points = adversarial_world_reachable_road_points(seed, 1)
  assert_eq(points.length(), 1)
  let base = town_life_world_empty_state_for_seed(seed)
  let point = points[0]
  let entity_id = "road-cell-\{point.x}-\{point.y}"
  let incarnation_id = "writer-z:10:add"
  let add = adversarial_world_event(
    base.epoch,
    "writer-z",
    10,
    10,
    "add",
    WorldRoadCell,
    entity_id,
    incarnation_id,
    WorldAdd(WorldRoadCellPayload(point)),
    0,
  )
  let movement = adversarial_world_event(
    base.epoch,
    "writer-a",
    5,
    5,
    "move-before-add",
    WorldRoadCell,
    entity_id,
    incarnation_id,
    WorldMove(WorldRoadCellPayload(point)),
    0,
  )
  let deletion = adversarial_world_event(
    base.epoch,
    "writer-b",
    6,
    6,
    "delete-before-add",
    WorldRoadCell,
    entity_id,
    incarnation_id,
    WorldDelete,
    999,
  )
  let projection = town_life_world_projection(
    { ..base, events: [add, deletion, movement] },
    seed,
  )
  assert_eq(projection.active.length(), 1)
  assert_eq(projection.ledger.budget, base.epoch.base_budget)
  assert_eq(
    projection.rejected
    .filter(value => value.reason_code == "pre-add-transition")
    .length(),
    2,
  )
}

///|
test "delete wins once, paid Add refunds half, free Add cannot mint, and reset cuts off replay" {
  let seed = active_energy_valley_seed()
  match adversarial_world_valid_building() {
    None => fail("expected one compiler-approved building fixture")
    Some(building) => {
      let base = town_life_world_empty_state_for_seed(seed)
      let entity_id = "adversarial-refund-site"
      let add_one = adversarial_world_event(
        base.epoch,
        "economic",
        2,
        2,
        "paid-add",
        WorldBuilding,
        entity_id,
        "economic:2:paid-add",
        WorldAdd(WorldBuildingPayload(building)),
        -800,
      )
      let delete_one = adversarial_world_event(
        base.epoch,
        "economic",
        3,
        3,
        "paid-delete",
        WorldBuilding,
        entity_id,
        "economic:2:paid-add",
        WorldDelete,
        999,
      )
      let add_free = adversarial_world_event(
        base.epoch,
        "economic",
        4,
        4,
        "free-add",
        WorldBuilding,
        entity_id,
        "economic:4:free-add",
        WorldAdd(WorldBuildingPayload(building)),
        0,
      )
      let delete_free = adversarial_world_event(
        base.epoch,
        "economic",
        5,
        5,
        "free-delete",
        WorldBuilding,
        entity_id,
        "economic:4:free-add",
        WorldDelete,
        999,
      )
      let add_fresh = adversarial_world_event(
        base.epoch,
        "economic",
        6,
        6,
        "fresh-add",
        WorldBuilding,
        entity_id,
        "economic:6:fresh-add",
        WorldAdd(WorldBuildingPayload(building)),
        -500,
      )
      let complete = {
        ..base,
        events: [add_fresh, delete_free, add_free, delete_one, add_one],
      }
      let projected = town_life_world_projection(complete, seed)
      assert_eq(projected.active.length(), 1)
      assert_eq(projected.active[0].incarnation_id, "economic:6:fresh-add")
      assert_eq(projected.ledger.budget, 1500)
      assert_false(
        projected.rejected.any(value => {
          (value.event_id == add_one.id || value.event_id == add_fresh.id) &&
          value.reason_code == "historical-add-rejected"
        }),
      )
      let stale = { ..base, events: [add_one] }
      let stale_replay = town_life_world_projection(
        town_life_world_merge_state(stale, complete),
        seed,
      )
      assert_eq(
        adversarial_world_projection_json(projected),
        adversarial_world_projection_json(stale_replay),
      )
      let reset_epoch : TownLifeWorldEpoch = {
        id: "reset-writer:100:world-reset",
        dot: { writer_id: "reset-writer", sequence: 100 },
        stamp: { writer_id: "reset-writer", lamport: 100 },
        base_budget: 2400,
        base_next_authored_sequence: 1,
      }
      let reset = { ..base, epoch: reset_epoch, events: [] }
      let after_reset = town_life_world_merge_state(complete, reset)
      let after_stale_replay = town_life_world_merge_state(after_reset, stale)
      assert_eq(
        adversarial_world_state_json(after_reset),
        adversarial_world_state_json(after_stale_replay),
      )
      let reset_projection = town_life_world_projection(
        after_stale_replay, seed,
      )
      assert_true(reset_projection.active.is_empty())
      assert_eq(reset_projection.ledger.budget, 2400)
    }
  }
}

///|
test "a 192-cell road union projects in the fixed fast-path pass bound" {
  let seed = active_energy_valley_seed()
  let points = adversarial_world_custom_road_stroke(seed, 192)
  assert_eq(points.length(), 192)
  let base = town_life_world_empty_state_for_seed(seed)
  let events : Array[TownLifeWorldEvent] = []
  for index, point in points {
    events.push(
      adversarial_world_road_event(
        base.epoch,
        "road-stroke",
        index + 2,
        index + 2,
        "stroke",
        point,
      ),
    )
  }
  let state = { ..base, events, }
  let projection = town_life_world_projection(state, seed)
  assert_eq(projection.active.length(), 192)
  assert_true(
    projection.validation_passes <=
    town_life_world_fast_path_validation_pass_bound(state),
  )
  assert_true(projection.validation_passes <= 2)
  assert_eq(
    energy_valley_world_delta_projection(projection.ledger).roads.length(),
    192,
  )
}

///|
test "legacy import preserves identity budget and sequence while real V3 state wins a race" {
  let seed = active_energy_valley_seed()
  let points = adversarial_world_reachable_road_points(seed, 3)
  assert_true(points.length() >= 3)
  match adversarial_world_valid_building() {
    None => fail("expected one compiler-approved building fixture")
    Some(raw_building) => {
      let building = {
        ..raw_building,
        authored_id: Some("legacy-stable-building"),
      }
      let operations : Array[SavedWorldDeltaOperation] = [
        AddBuilding({ id: "legacy-stable-building", building }),
        AddRoad({ id: "legacy-road-component", path: [points[0], points[1]] }),
      ]
      let ledger : EnergyValleyWorldDeltaLedger = {
        ..energy_valley_empty_world_delta_for_seed(seed),
        revision: 77,
        budget: 1337,
        operations,
        content_digest: Some(energy_valley_saved_operations_digest(operations)),
        next_authored_building_sequence: 91,
      }
      let imported = town_life_world_import_legacy_ledger(ledger, seed)
      let import_projection = town_life_world_projection(imported, seed)
      assert_eq(import_projection.ledger.budget, 1337)
      assert_eq(import_projection.ledger.next_authored_building_sequence, 91)
      assert_true(
        energy_valley_world_delta_projection(import_projection.ledger).buildings.any(value => {
            golden_valley_nonempty_authored_id(value) ==
            Some("legacy-stable-building")
          },
        ),
      )
      let real_base = town_life_world_empty_state_for_seed(seed)
      let real_event = adversarial_world_road_event(
        real_base.epoch,
        "real-v3-writer",
        2,
        2,
        "real-edit",
        points[2],
      )
      let real = { ..real_base, events: [real_event] }
      let merged = town_life_world_merge_state(imported, real)
      let reverse = town_life_world_merge_state(real, imported)
      assert_eq(
        adversarial_world_state_json(merged),
        adversarial_world_state_json(reverse),
      )
      assert_eq(merged.epoch.id, real_base.epoch.id)
      assert_eq(merged.events.length(), 1)
      let winner = town_life_world_projection(merged, seed)
      assert_false(
        energy_valley_world_delta_projection(winner.ledger).buildings.any(value => {
          golden_valley_nonempty_authored_id(value) ==
          Some("legacy-stable-building")
        }),
      )
      let other_seed_state = town_life_world_state_for_seed(
        [imported],
        seed + 1,
      )
      assert_true(other_seed_state.events.is_empty())
      assert_true(
        other_seed_state.blueprint_digest != imported.blueprint_digest,
      )
    }
  }
}

///|
fn adversarial_collected_post(
  id : String,
  building_id : String,
  writer : String,
) -> KnowledgePost {
  {
    id,
    building_id: Some(building_id),
    incarnation_id: Some("\{writer}:post-incarnation"),
    created_stamp: Some({ writer_id: writer, lamport: 3 }),
    updated_stamp: Some({ writer_id: writer, lamport: 3 }),
    reset_epoch: None,
    building_name: "Concurrent collected building",
    topic: "Atomic physical and knowledge convergence",
    author: writer,
    spark: 8,
    published: true,
    collected: true,
    mine: false,
  }
}

///|
test "projected collected posts never outlive a spatially rejected building" {
  let seed = active_energy_valley_seed()
  match adversarial_world_valid_building() {
    None => fail("expected one compiler-approved building fixture")
    Some(building) => {
      let base = town_life_world_empty_state_for_seed(seed)
      let first_id = "collected-building-a"
      let second_id = "collected-building-b"
      let first_event = adversarial_world_event(
        base.epoch,
        "collector-a",
        2,
        2,
        "collect",
        WorldBuilding,
        first_id,
        "collector-a:2:collect",
        WorldAdd(WorldBuildingPayload(building)),
        0,
      )
      let second_event = adversarial_world_event(
        base.epoch,
        "collector-b",
        2,
        2,
        "collect",
        WorldBuilding,
        second_id,
        "collector-b:2:collect",
        WorldAdd(WorldBuildingPayload(building)),
        0,
      )
      let left : TownLifeSave = {
        ..town_life_default_save(),
        posts: [adversarial_collected_post("post-a", first_id, "collector-a")],
        world_states: Some([{ ..base, events: [first_event] }]),
      }
      let right : TownLifeSave = {
        ..town_life_default_save(),
        posts: [adversarial_collected_post("post-b", second_id, "collector-b")],
        world_states: Some([{ ..base, events: [second_event] }]),
      }
      let merged = town_life_reconcile_save(left, right)
      let projected = town_life_model_with_save(init_model(), merged)
      let active_ids : Array[String] = []
      for active in energy_valley_model_buildings(projected) {
        match golden_valley_nonempty_authored_id(active) {
          Some(id) => active_ids.push(id)
          None => ()
        }
      }
      assert_eq(active_ids.length(), 1)
      for post in projected.posts {
        if town_life_post_is_map_bound(post) {
          match post.building_id {
            Some(id) => assert_true(active_ids.contains(id))
            None => fail("new collected post lost its exact building identity")
          }
        }
      }
      assert_eq(projected.posts.filter(town_life_post_is_map_bound).length(), 1)
    }
  }
}

///|
test "invalid Move is rejected without discarding its valid Add" {
  let seed = active_energy_valley_seed()
  match adversarial_world_valid_building() {
    None => fail("expected one compiler-approved building fixture")
    Some(building) => {
      let base = town_life_world_empty_state_for_seed(seed)
      let add = adversarial_world_event(
        base.epoch,
        "move-writer",
        2,
        2,
        "add",
        WorldBuilding,
        "move-preserves-add",
        "move-writer:2:add",
        WorldAdd(WorldBuildingPayload(building)),
        -500,
      )
      let movement = adversarial_world_event(
        base.epoch,
        "move-writer",
        3,
        3,
        "invalid-move",
        WorldBuilding,
        "move-preserves-add",
        add.id,
        WorldMove(WorldBuildingPayload({ ..building, x: -100, y: -100 })),
        0,
      )
      let projection = town_life_world_projection(
        { ..base, events: [movement, add] },
        seed,
      )
      let buildings = energy_valley_world_delta_projection(projection.ledger).buildings
      assert_eq(buildings.length(), 1)
      assert_eq((buildings[0].x, buildings[0].y), (building.x, building.y))
      assert_true(
        projection.rejected.any(value => {
          value.event_id == movement.id && value.reason_code == "move-rejected"
        }),
      )
      assert_eq(projection.ledger.budget, 1900)
    }
  }
}

///|
test "later duplicate Add cannot resurrect a deleted incarnation" {
  let seed = active_energy_valley_seed()
  match adversarial_world_valid_building() {
    None => fail("expected one compiler-approved building fixture")
    Some(building) => {
      let base = town_life_world_empty_state_for_seed(seed)
      let add = adversarial_world_event(
        base.epoch,
        "duplicate-writer",
        2,
        2,
        "add",
        WorldBuilding,
        "duplicate-site",
        "duplicate-writer:2:add",
        WorldAdd(WorldBuildingPayload(building)),
        -600,
      )
      let deletion = adversarial_world_event(
        base.epoch,
        "duplicate-writer",
        3,
        3,
        "delete",
        WorldBuilding,
        "duplicate-site",
        add.id,
        WorldDelete,
        300,
      )
      // An Add cannot claim an old incarnation: Add identity is its own event
      // id. Even if it sorts after Delete, this malformed replay is inert.
      let malformed_late_add = adversarial_world_event(
        base.epoch,
        "duplicate-writer",
        4,
        4,
        "late-duplicate",
        WorldBuilding,
        "duplicate-site",
        add.id,
        WorldAdd(WorldBuildingPayload(building)),
        -600,
      )
      let complete = { ..base, events: [add, deletion, malformed_late_add] }
      let projection = town_life_world_projection(complete, seed)
      assert_true(projection.active.is_empty())
      assert_eq(projection.ledger.budget, 2100)
      assert_true(
        projection.rejected.any(value => {
          value.event_id == malformed_late_add.id &&
          value.reason_code == "invalid-payload"
        }),
      )
      let replay = town_life_world_projection(
        town_life_world_merge_state(complete, { ..base, events: [add] }),
        seed,
      )
      assert_true(replay.active.is_empty())
      assert_eq(replay.ledger.budget, 2100)
    }
  }
}

///|
test "road-cell delete removes only its cell and stale replay cannot restore it" {
  let seed = active_energy_valley_seed()
  let points = adversarial_world_reachable_road_points(seed, 2)
  assert_eq(points.length(), 2)
  let base = town_life_world_empty_state_for_seed(seed)
  let first = adversarial_world_road_event(
    base.epoch,
    "road-a",
    2,
    2,
    "add",
    points[0],
  )
  let second = adversarial_world_road_event(
    base.epoch,
    "road-b",
    2,
    3,
    "add",
    points[1],
  )
  let deletion = adversarial_world_event(
    base.epoch,
    "road-delete",
    4,
    4,
    "delete",
    WorldRoadCell,
    first.entity_id,
    first.id,
    WorldDelete,
    0,
  )
  let stale = { ..base, events: [first, second] }
  let complete = { ..base, events: [first, second, deletion] }
  let merged = town_life_world_merge_state(stale, complete)
  let projection = town_life_world_projection(merged, seed)
  assert_eq(projection.active.length(), 1)
  assert_eq(projection.active[0].entity_id, second.entity_id)
  assert_eq(energy_valley_world_delta_projection(projection.ledger).roads, [
    golden_valley_tile_key(points[1].x, points[1].y),
  ])
}

///|
extern "js" fn adversarial_world_install_storage_harness() -> Unit =
  #| () => {
  #|   const descriptor = Object.getOwnPropertyDescriptor(globalThis, "localStorage");
  #|   const rows = new Map();
  #|   globalThis.__moontownWorldFenceAdversarial = { descriptor, rows };
  #|   Object.defineProperty(globalThis, "localStorage", {
  #|     configurable: true,
  #|     writable: true,
  #|     value: {
  #|       get length() { return rows.size; },
  #|       key(index) { return [...rows.keys()][index] ?? null; },
  #|       getItem(key) { return rows.get(String(key)) ?? null; },
  #|       setItem(key, value) { rows.set(String(key), String(value)); },
  #|       removeItem(key) { rows.delete(String(key)); },
  #|     },
  #|   });
  #| }

///|
extern "js" fn adversarial_world_remove_storage_harness() -> Unit =
  #| () => {
  #|   const harness = globalThis.__moontownWorldFenceAdversarial;
  #|   if (!harness) return;
  #|   if (harness.descriptor) {
  #|     Object.defineProperty(globalThis, "localStorage", harness.descriptor);
  #|   } else {
  #|     delete globalThis.localStorage;
  #|   }
  #|   delete globalThis.__moontownWorldFenceAdversarial;
  #| }

///|
test "legacy spatial source fence is global across seed A to seed B" {
  adversarial_world_install_storage_harness()
  let before_a = browser_energy_world_town_life_migration_fenced("digest-a")
  let before_b = browser_energy_world_town_life_migration_fenced("digest-b")
  browser_fence_energy_world_town_life_migration("digest-a")
  let after_a = browser_energy_world_town_life_migration_fenced("digest-a")
  let after_b = browser_energy_world_town_life_migration_fenced("digest-b")
  adversarial_world_remove_storage_harness()
  assert_false(before_a)
  assert_false(before_b)
  assert_true(after_a)
  assert_true(after_b)
}

///|
test "canonical budget order accepts one concurrent spender independent of merge order" {
  let seed = active_energy_valley_seed()
  match adversarial_world_valid_building() {
    None => fail("expected one compiler-approved building fixture")
    Some(building) => {
      let base = town_life_world_empty_state_for_seed(seed)
      let first = adversarial_world_event(
        base.epoch,
        "budget-a",
        2,
        2,
        "add",
        WorldBuilding,
        "budget-site-a",
        "budget-a:2:add",
        WorldAdd(WorldBuildingPayload(building)),
        -1600,
      )
      let second = adversarial_world_event(
        base.epoch,
        "budget-b",
        2,
        2,
        "add",
        WorldBuilding,
        "budget-site-b",
        "budget-b:2:add",
        WorldAdd(WorldBuildingPayload(building)),
        -1600,
      )
      let left = { ..base, events: [first] }
      let right = { ..base, events: [second] }
      let forward = town_life_world_projection(
        town_life_world_merge_state(left, right),
        seed,
      )
      let reverse = town_life_world_projection(
        town_life_world_merge_state(right, left),
        seed,
      )
      assert_eq(
        adversarial_world_projection_json(forward),
        adversarial_world_projection_json(reverse),
      )
      assert_eq(forward.active.length(), 1)
      assert_eq(forward.active[0].entity_id, "budget-site-a")
      assert_eq(forward.ledger.budget, 800)
      assert_true(
        forward.rejected.any(value => {
          value.event_id == second.id && value.reason_code == "budget-exhausted"
        }),
      )
    }
  }
}

///|
test "invalid deleted Add has no debit and cannot manufacture a refund" {
  let seed = active_energy_valley_seed()
  match adversarial_world_valid_building() {
    None => fail("expected one compiler-approved building fixture")
    Some(valid) => {
      let base = town_life_world_empty_state_for_seed(seed)
      let invalid = { ..valid, x: -100, y: -100 }
      let add = adversarial_world_event(
        base.epoch,
        "mint-attack",
        2,
        2,
        "invalid-add",
        WorldBuilding,
        "invalid-refund-site",
        "mint-attack:2:invalid-add",
        WorldAdd(WorldBuildingPayload(invalid)),
        -800,
      )
      let deletion = adversarial_world_event(
        base.epoch,
        "mint-attack",
        3,
        3,
        "delete",
        WorldBuilding,
        "invalid-refund-site",
        add.id,
        WorldDelete,
        999,
      )
      let projection = town_life_world_projection(
        { ..base, events: [add, deletion] },
        seed,
      )
      assert_true(projection.active.is_empty())
      assert_eq(projection.ledger.budget, base.epoch.base_budget)
      assert_true(
        projection.rejected.any(value => {
          value.event_id == add.id &&
          value.reason_code == "historical-add-rejected"
        }),
      )
    }
  }
}

///|
test "diagonal-only custom road contact does not provide building frontage" {
  let seed = active_energy_valley_seed()
  match adversarial_world_diagonal_frontage_fixture(seed) {
    None =>
      fail("expected a buildable site with only diagonal custom-road contact")
    Some((building, point)) => {
      let base = town_life_world_empty_state_for_seed(seed)
      let world = energy_valley_base_contract_world_for_seed(seed)
      let base_roads = town_life_world_base_road_cells(world)
      let custom_roads = town_life_world_reachable_custom_roads(world, [
        golden_valley_tile_key(point.x, point.y),
      ])
      assert_true(custom_roads is Some(_))
      assert_false(
        town_life_world_building_has_access(
          building,
          base_roads,
          custom_roads.unwrap(),
        ),
      )
      let road = adversarial_world_road_event(
        base.epoch,
        "diagonal-frontage",
        1,
        1,
        "road",
        point,
      )
      let add = adversarial_world_event(
        base.epoch,
        "diagonal-frontage",
        2,
        2,
        "building",
        WorldBuilding,
        "diagonal-frontage-site",
        "diagonal-frontage:2:building",
        WorldAdd(WorldBuildingPayload(building)),
        0,
      )
      let projection = town_life_world_projection(
        { ..base, events: [road, add] },
        seed,
      )
      assert_true(projection.active.any(value => value.add.id == road.id))
      assert_true(!projection.active.any(value => value.add.id == add.id))
      assert_true(
        projection.rejected.any(value => {
          value.event_id == add.id && value.reason_code == "contract-rejected"
        }),
      )
    }
  }
}

///|
test "budget retry rechecks topology and keeps the affordable connector" {
  let seed = active_energy_valley_seed()
  let world = energy_valley_base_contract_world_for_seed(seed)
  let base = town_life_world_empty_state_for_seed(seed)
  let epoch = { ..base.epoch, base_budget: 30 }
  let (connector, far) = world_projection_isolation_dependent_chain(world).unwrap()
  let far_add = adversarial_world_event(
    epoch,
    "road-budget",
    2,
    2,
    "far",
    WorldRoadCell,
    "road-cell-\{far.x}-\{far.y}",
    "road-budget:2:far",
    WorldAdd(WorldRoadCellPayload(far)),
    -30,
  )
  let connector_add = adversarial_world_event(
    epoch,
    "road-budget",
    3,
    3,
    "connector",
    WorldRoadCell,
    "road-cell-\{connector.x}-\{connector.y}",
    "road-budget:3:connector",
    WorldAdd(WorldRoadCellPayload(connector)),
    -30,
  )
  let projection = town_life_world_projection(
    { ..base, epoch, events: [far_add, connector_add] },
    seed,
  )
  assert_false(projection.active.any(value => value.add.id == far_add.id))
  assert_true(projection.active.any(value => value.add.id == connector_add.id))
  assert_eq(projection.ledger.budget, 0)
  assert_eq(energy_valley_world_delta_projection(projection.ledger).roads, [
    golden_valley_tile_key(connector.x, connector.y),
  ])
}

///|
test "budget topology retry keeps the maximal affordable anchored road prefix" {
  let seed = active_energy_valley_seed()
  let world = energy_valley_base_contract_world_for_seed(seed)
  let base = town_life_world_empty_state_for_seed(seed)
  let epoch = { ..base.epoch, base_budget: 60 }
  let (connector, middle, far) = adversarial_world_three_cell_dependent_chain(
    world,
  ).unwrap()
  let far_add = adversarial_world_event(
    epoch,
    "road-budget-prefix",
    2,
    2,
    "far",
    WorldRoadCell,
    "road-cell-\{far.x}-\{far.y}",
    "road-budget-prefix:2:far",
    WorldAdd(WorldRoadCellPayload(far)),
    -30,
  )
  let middle_add = adversarial_world_event(
    epoch,
    "road-budget-prefix",
    3,
    3,
    "middle",
    WorldRoadCell,
    "road-cell-\{middle.x}-\{middle.y}",
    "road-budget-prefix:3:middle",
    WorldAdd(WorldRoadCellPayload(middle)),
    -30,
  )
  let connector_add = adversarial_world_event(
    epoch,
    "road-budget-prefix",
    4,
    4,
    "connector",
    WorldRoadCell,
    "road-cell-\{connector.x}-\{connector.y}",
    "road-budget-prefix:4:connector",
    WorldAdd(WorldRoadCellPayload(connector)),
    -30,
  )
  let projection = town_life_world_projection(
    { ..base, epoch, events: [far_add, middle_add, connector_add] },
    seed,
  )
  assert_false(projection.active.any(value => value.add.id == far_add.id))
  assert_true(projection.active.any(value => value.add.id == middle_add.id))
  assert_true(projection.active.any(value => value.add.id == connector_add.id))
  assert_eq(projection.active.length(), 2)
  assert_eq(projection.ledger.budget, 0)
  let roads = energy_valley_world_delta_projection(projection.ledger).roads
  assert_eq(roads.length(), 2)
  assert_true(roads.contains(golden_valley_tile_key(middle.x, middle.y)))
  assert_true(roads.contains(golden_valley_tile_key(connector.x, connector.y)))
}

///|
test "paid connector and dependent road remain charged after both are deleted" {
  let seed = active_energy_valley_seed()
  let world = energy_valley_base_contract_world_for_seed(seed)
  let base = town_life_world_empty_state_for_seed(seed)
  let (connector, dependent) = world_projection_isolation_dependent_chain(world).unwrap()
  let connector_add = adversarial_world_event(
    base.epoch,
    "paid-road-history",
    2,
    2,
    "connector",
    WorldRoadCell,
    "road-cell-\{connector.x}-\{connector.y}",
    "paid-road-history:2:connector",
    WorldAdd(WorldRoadCellPayload(connector)),
    -10,
  )
  let dependent_add = adversarial_world_event(
    base.epoch,
    "paid-road-history",
    3,
    3,
    "dependent",
    WorldRoadCell,
    "road-cell-\{dependent.x}-\{dependent.y}",
    "paid-road-history:3:dependent",
    WorldAdd(WorldRoadCellPayload(dependent)),
    -10,
  )
  let dependent_delete = adversarial_world_event(
    base.epoch,
    "paid-road-history",
    4,
    4,
    "delete-dependent",
    WorldRoadCell,
    dependent_add.entity_id,
    dependent_add.id,
    WorldDelete,
    0,
  )
  let connector_delete = adversarial_world_event(
    base.epoch,
    "paid-road-history",
    5,
    5,
    "delete-connector",
    WorldRoadCell,
    connector_add.entity_id,
    connector_add.id,
    WorldDelete,
    0,
  )
  let left = { ..base, events: [connector_add, dependent_delete] }
  let right = { ..base, events: [dependent_add, connector_delete] }
  let forward = town_life_world_projection(
    town_life_world_merge_state(left, right),
    seed,
  )
  let reverse = town_life_world_projection(
    town_life_world_merge_state(right, left),
    seed,
  )
  assert_eq(
    adversarial_world_projection_json(forward),
    adversarial_world_projection_json(reverse),
  )
  assert_eq(forward.rejected, reverse.rejected)
  assert_true(forward.active.is_empty())
  assert_eq(forward.ledger.budget, base.epoch.base_budget - 20)
  assert_false(
    forward.rejected.any(value => {
      (value.event_id == connector_add.id || value.event_id == dependent_add.id) &&
      value.reason_code == "historical-add-rejected"
    }),
  )
}

///|
test "later connector makes an earlier paid dependent road historically valid" {
  let seed = active_energy_valley_seed()
  let world = energy_valley_base_contract_world_for_seed(seed)
  let base = town_life_world_empty_state_for_seed(seed)
  let (connector, dependent) = world_projection_isolation_dependent_chain(world).unwrap()
  let dependent_add = adversarial_world_event(
    base.epoch,
    "late-connector-history",
    2,
    2,
    "dependent",
    WorldRoadCell,
    "road-cell-\{dependent.x}-\{dependent.y}",
    "late-connector-history:2:dependent",
    WorldAdd(WorldRoadCellPayload(dependent)),
    -10,
  )
  let connector_add = adversarial_world_event(
    base.epoch,
    "late-connector-history",
    3,
    3,
    "connector",
    WorldRoadCell,
    "road-cell-\{connector.x}-\{connector.y}",
    "late-connector-history:3:connector",
    WorldAdd(WorldRoadCellPayload(connector)),
    -10,
  )
  let dependent_delete = adversarial_world_event(
    base.epoch,
    "late-connector-history",
    4,
    4,
    "delete-dependent",
    WorldRoadCell,
    dependent_add.entity_id,
    dependent_add.id,
    WorldDelete,
    0,
  )
  let connector_delete = adversarial_world_event(
    base.epoch,
    "late-connector-history",
    5,
    5,
    "delete-connector",
    WorldRoadCell,
    connector_add.entity_id,
    connector_add.id,
    WorldDelete,
    0,
  )
  let projection = town_life_world_projection(
    {
      ..base,
      events: [dependent_add, connector_add, dependent_delete, connector_delete],
    },
    seed,
  )
  assert_true(projection.active.is_empty())
  assert_eq(projection.ledger.budget, base.epoch.base_budget - 20)
  assert_false(
    projection.rejected.any(value => {
      value.event_id == dependent_add.id &&
      value.reason_code == "historical-add-rejected"
    }),
  )
}

///|
test "historical replay preserves topology-aware budget rejection" {
  let seed = active_energy_valley_seed()
  let world = energy_valley_base_contract_world_for_seed(seed)
  let base = town_life_world_empty_state_for_seed(seed)
  let epoch = { ..base.epoch, base_budget: 30 }
  let (connector, dependent) = world_projection_isolation_dependent_chain(world).unwrap()
  let dependent_add = adversarial_world_event(
    epoch,
    "historical-budget",
    2,
    2,
    "dependent",
    WorldRoadCell,
    "road-cell-\{dependent.x}-\{dependent.y}",
    "historical-budget:2:dependent",
    WorldAdd(WorldRoadCellPayload(dependent)),
    -30,
  )
  let connector_add = adversarial_world_event(
    epoch,
    "historical-budget",
    3,
    3,
    "connector",
    WorldRoadCell,
    "road-cell-\{connector.x}-\{connector.y}",
    "historical-budget:3:connector",
    WorldAdd(WorldRoadCellPayload(connector)),
    -20,
  )
  let live = town_life_world_projection(
    { ..base, epoch, events: [dependent_add, connector_add] },
    seed,
  )
  assert_false(live.active.any(value => value.add.id == dependent_add.id))
  assert_true(live.active.any(value => value.add.id == connector_add.id))
  assert_eq(live.ledger.budget, 10)
  assert_true(
    live.rejected.any(value => {
      value.event_id == dependent_add.id &&
      value.reason_code == "detached-road-cell"
    }),
  )
  let dependent_delete = adversarial_world_event(
    epoch,
    "historical-budget",
    4,
    4,
    "delete-dependent",
    WorldRoadCell,
    dependent_add.entity_id,
    dependent_add.id,
    WorldDelete,
    0,
  )
  let connector_delete = adversarial_world_event(
    epoch,
    "historical-budget",
    5,
    5,
    "delete-connector",
    WorldRoadCell,
    connector_add.entity_id,
    connector_add.id,
    WorldDelete,
    0,
  )
  let deleted = town_life_world_projection(
    {
      ..base,
      epoch,
      events: [dependent_add, connector_add, dependent_delete, connector_delete],
    },
    seed,
  )
  assert_true(deleted.active.is_empty())
  assert_eq(deleted.ledger.budget, 10)
  assert_true(deleted.rejected.any(value => value.event_id == dependent_add.id))
}

///|
test "detached deleted paid road is economically inert under merge order" {
  let seed = active_energy_valley_seed()
  let world = energy_valley_base_contract_world_for_seed(seed)
  let base = town_life_world_empty_state_for_seed(seed)
  let (_, detached) = world_projection_isolation_dependent_chain(world).unwrap()
  let add = adversarial_world_event(
    base.epoch,
    "never-valid-road",
    2,
    2,
    "add",
    WorldRoadCell,
    "road-cell-\{detached.x}-\{detached.y}",
    "never-valid-road:2:add",
    WorldAdd(WorldRoadCellPayload(detached)),
    -10,
  )
  let deletion = adversarial_world_event(
    base.epoch,
    "never-valid-road",
    3,
    3,
    "delete",
    WorldRoadCell,
    add.entity_id,
    add.id,
    WorldDelete,
    0,
  )
  let forward = town_life_world_projection(
    town_life_world_merge_state({ ..base, events: [add] }, {
      ..base,
      events: [deletion],
    }),
    seed,
  )
  let reverse = town_life_world_projection(
    town_life_world_merge_state({ ..base, events: [deletion] }, {
      ..base,
      events: [add],
    }),
    seed,
  )
  assert_eq(
    adversarial_world_projection_json(forward),
    adversarial_world_projection_json(reverse),
  )
  assert_eq(forward.rejected, reverse.rejected)
  assert_true(forward.active.is_empty())
  assert_eq(forward.ledger.budget, base.epoch.base_budget)
  assert_true(forward.rejected.any(value => value.event_id == add.id))
}

///|
test "twenty sequential paid demolition histories replay in interactive time" {
  let seed = active_energy_valley_seed()
  let base = town_life_world_empty_state_for_seed(seed)
  let building = adversarial_world_valid_building().unwrap()
  let events : Array[TownLifeWorldEvent] = []
  let pair_count = 20
  for index in 0..<pair_count {
    let add_sequence = index * 2 + 2
    let delete_sequence = add_sequence + 1
    let add = adversarial_world_event(
      base.epoch,
      "historical-depth",
      add_sequence,
      add_sequence,
      "add",
      WorldBuilding,
      "historical-depth-site",
      "historical-depth:\{add_sequence}:add",
      WorldAdd(WorldBuildingPayload(building)),
      -2,
    )
    events.push(add)
    events.push(
      adversarial_world_event(
        base.epoch,
        "historical-depth",
        delete_sequence,
        delete_sequence,
        "delete",
        WorldBuilding,
        "historical-depth-site",
        add.id,
        WorldDelete,
        1,
      ),
    )
  }
  let started_at = browser_now_ms()
  let projection = town_life_world_projection({ ..base, events, }, seed)
  let elapsed_ms = browser_now_ms() - started_at
  println(
    "WORLD_HISTORICAL_REPLAY pairs=\{pair_count} elapsed_ms=\{elapsed_ms}",
  )
  assert_true(projection.active.is_empty())
  assert_eq(projection.ledger.budget, base.epoch.base_budget - pair_count)
  assert_false(
    projection.rejected.any(value => {
      value.reason_code == "historical-add-rejected"
    }),
  )
  assert_true(elapsed_ms < 3000.0)
}
