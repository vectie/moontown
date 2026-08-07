///|
fn world_projection_benchmark_points(
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
fn world_projection_benchmark_state(
  seed : Int,
  count : Int,
) -> TownLifeWorldState {
  let base = town_life_world_empty_state_for_seed(seed)
  let points = world_projection_benchmark_points(seed, count)
  let events : Array[TownLifeWorldEvent] = []
  for index, point in points {
    let sequence = index + 2
    let id = "projection-benchmark:\{sequence}:road-add"
    events.push({
      id,
      dot: { writer_id: "projection-benchmark", sequence },
      stamp: { writer_id: "projection-benchmark", lamport: sequence },
      epoch_id: base.epoch.id,
      kind: WorldRoadCell,
      entity_id: "road-cell-\{point.x}-\{point.y}",
      incarnation_id: id,
      action: WorldAdd(WorldRoadCellPayload(point)),
      budget_delta: 0,
    })
  }
  { ..base, events, }
}

///|
fn world_projection_paid_deleted_chain_state(
  seed : Int,
  count : Int,
) -> TownLifeWorldState {
  let base = town_life_world_empty_state_for_seed(seed)
  let points = world_projection_benchmark_points(seed, count)
  let adds : Array[TownLifeWorldEvent] = []
  let events : Array[TownLifeWorldEvent] = []
  for index, point in points {
    let sequence = index + 2
    let id = "paid-deleted-road:\{sequence}:add"
    let event : TownLifeWorldEvent = {
      id,
      dot: { writer_id: "paid-deleted-road", sequence },
      stamp: { writer_id: "paid-deleted-road", lamport: sequence },
      epoch_id: base.epoch.id,
      kind: WorldRoadCell,
      entity_id: "road-cell-\{point.x}-\{point.y}",
      incarnation_id: id,
      action: WorldAdd(WorldRoadCellPayload(point)),
      budget_delta: -1,
    }
    adds.push(event)
    events.push(event)
  }
  for index, added in adds {
    let sequence = count + index + 2
    events.push({
      id: "paid-deleted-road:\{sequence}:delete",
      dot: { writer_id: "paid-deleted-road", sequence },
      stamp: { writer_id: "paid-deleted-road", lamport: sequence },
      epoch_id: base.epoch.id,
      kind: WorldRoadCell,
      entity_id: added.entity_id,
      incarnation_id: added.incarnation_id,
      action: WorldDelete,
      budget_delta: -1,
    })
  }
  { ..base, events, }
}

///|
fn world_mutation_benchmark_road_point(
  world : @energy_valley_contract.CompiledTownWorld,
) -> SavedWorldDeltaGridPoint? {
  let base_roads = town_life_world_base_road_cells(world)
  for node in world.road_network.nodes {
    if !base_roads.contains(
        golden_valley_tile_key(node.grid.column, node.grid.row),
      ) {
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
fn world_mutation_benchmark_park_point(
  world : @energy_valley_contract.CompiledTownWorld,
) -> SavedWorldDeltaGridPoint? {
  for y in 0..<golden_valley_rows() {
    for x in 0..<golden_valley_cols() {
      if town_life_world_park_base_valid(world, {
          id: energy_valley_saved_park_id(x, y),
          x,
          y,
        }) {
        return Some({ x, y })
      }
    }
  }
  None
}

///|
fn world_mutation_benchmark_building(
  world : @energy_valley_contract.CompiledTownWorld,
) -> GoldenValleyBuilding? {
  let scale = energy_valley_semantic_cells_per_planning_cell()
  for y in 0..<golden_valley_rows() {
    for x in 0..<golden_valley_cols() {
      if x % scale != 0 || y % scale != 0 {
        continue
      }
      match golden_valley_custom_building(WorkshopTool, x, y, 1) {
        Some(building) if golden_valley_custom_placement_block_in_world(
            world, building,
          )
          is None => return Some(building)
        _ => ()
      }
    }
  }
  None
}

///|
test "benchmark: cached 192-cell projection stays interactive" {
  let seed = active_energy_valley_seed()
  let state = world_projection_benchmark_state(seed, 192)
  assert_eq(state.events.length(), 192)
  // Warm seed-scoped blueprint and spatial indexes outside the timed local
  // projection window. Initial page compilation is measured separately.
  let world = energy_valley_base_contract_world_for_seed(seed)
  let base_roads = town_life_world_base_road_cells(world)
  let encoded = state.events.map(event => {
    match town_life_world_action_payload(event.action) {
      Some(WorldRoadCellPayload(point)) => {
        let key = golden_valley_tile_key(point.x, point.y)
        assert_false(base_roads.contains(key))
        key
      }
      _ => fail("benchmark state must contain only custom road Adds")
    }
  })
  assert_eq(encoded.length(), 192)
  assert_true(town_life_world_reachable_custom_roads(world, encoded) is Some(_))
  let cold_started_at = browser_now_ms()
  let warm_projection = town_life_world_projection(state, seed)
  let cold_elapsed_ms = browser_now_ms() - cold_started_at
  assert_eq(warm_projection.active.length(), 192)
  assert_true(warm_projection.validation_passes <= 2)
  let iterations = 3
  let started_at = browser_now_ms()
  let mut checksum = 0
  let mut road_union_checksum = 0
  let mut validation_passes = 0
  for _ in 0..<iterations {
    let projection = town_life_world_projection(state, seed)
    checksum += projection.active.length()
    road_union_checksum += energy_valley_world_delta_projection(
      projection.ledger,
    ).roads.length()
    validation_passes += projection.validation_passes
  }
  let elapsed_ms = browser_now_ms() - started_at
  println(
    "WORLD_PROJECTION_BENCH cold_ms=\{cold_elapsed_ms} warm_iterations=\{iterations} road_cells=192 warm_elapsed_ms=\{elapsed_ms} validation_passes=\{validation_passes}",
  )
  assert_eq(checksum, iterations * 192)
  assert_eq(road_union_checksum, iterations * 192)
  assert_true(validation_passes <= iterations * 2)
  // Three warm local projections should remain comfortably interactive while
  // leaving ample headroom for shared CI runners.
  assert_true(cold_elapsed_ms < 3000.0)
  assert_true(elapsed_ms < 3000.0)
}

///|
test "benchmark: 192 paid deleted road cells replay without recursive blowup" {
  let seed = active_energy_valley_seed()
  let count = 192
  let state = world_projection_paid_deleted_chain_state(seed, count)
  assert_eq(state.events.length(), count * 2)
  ignore(energy_valley_base_contract_world_for_seed(seed))
  ignore(
    town_life_world_projection(
      world_projection_paid_deleted_chain_state(seed, 1),
      seed,
    ),
  )
  let started_at = browser_now_ms()
  let projection = town_life_world_projection(state, seed)
  let elapsed_ms = browser_now_ms() - started_at
  println(
    "WORLD_HISTORICAL_DELETE_BENCH road_cells=\{count} events=\{state.events.length()} elapsed_ms=\{elapsed_ms} validation_passes=\{projection.validation_passes}",
  )
  assert_true(projection.active.is_empty())
  assert_true(
    energy_valley_world_delta_projection(projection.ledger).roads.is_empty(),
  )
  assert_eq(projection.ledger.budget, state.epoch.base_budget - count)
  assert_false(
    projection.rejected.any(rejection => {
      rejection.reason_code == "historical-add-rejected" ||
      rejection.reason_code == "budget-exhausted"
    }),
  )
  assert_true(projection.validation_passes <= count + 1)
  assert_true(elapsed_ms < 3000.0)
}

///|
test "benchmark: road click uses canonical membership without candidate compile" {
  let seed = active_energy_valley_seed()
  let model = { ..init_model(), energy_tool: RoadTool }
  let current_snapshot_key = ecosystem_snapshot_cache_key(model, seed)
  let current_contract_key = ecosystem_contract_world_cache_key(model, seed)
  let world = ecosystem_contract_world_for_model(model, seed)
  let point = world_mutation_benchmark_road_point(world).unwrap()
  assert_true(
    ecosystem_contract_world_cache.get(current_contract_key) is Some(_),
  )
  let started_at = browser_now_ms()
  let candidate = golden_valley_place_road_model(model, point.x, point.y)
  let elapsed_ms = browser_now_ms() - started_at
  let candidate_snapshot_key = ecosystem_snapshot_cache_key(candidate, seed)
  let candidate_contract_key = ecosystem_contract_world_cache_key(
    candidate, seed,
  )
  println("WORLD_MUTATION_BENCH kind=road elapsed_ms=\{elapsed_ms}")
  assert_true(golden_valley_canonical_road_active(candidate, point.x, point.y))
  assert_true(candidate_snapshot_key != current_snapshot_key)
  assert_true(
    ecosystem_contract_world_cache.get(candidate_contract_key) is None,
  )
  assert_true(
    ecosystem_world_snapshot_cache.get(candidate_snapshot_key) is None,
  )
  assert_true(
    ecosystem_contract_world_cache.get(current_contract_key) is Some(_),
  )
  assert_true(elapsed_ms < 3000.0)
}

///|
test "benchmark: park click uses canonical membership without candidate compile" {
  let seed = active_energy_valley_seed()
  let model = { ..init_model(), energy_tool: ParkTool }
  let current_snapshot_key = ecosystem_snapshot_cache_key(model, seed)
  let current_contract_key = ecosystem_contract_world_cache_key(model, seed)
  let world = ecosystem_contract_world_for_model(model, seed)
  let point = world_mutation_benchmark_park_point(world).unwrap()
  assert_true(
    ecosystem_contract_world_cache.get(current_contract_key) is Some(_),
  )
  let started_at = browser_now_ms()
  let candidate = golden_valley_place_park_model(model, point.x, point.y)
  let elapsed_ms = browser_now_ms() - started_at
  let candidate_snapshot_key = ecosystem_snapshot_cache_key(candidate, seed)
  let candidate_contract_key = ecosystem_contract_world_cache_key(
    candidate, seed,
  )
  println("WORLD_MUTATION_BENCH kind=park elapsed_ms=\{elapsed_ms}")
  assert_true(golden_valley_canonical_park_active(candidate, point.x, point.y))
  assert_true(candidate_snapshot_key != current_snapshot_key)
  assert_true(
    ecosystem_contract_world_cache.get(candidate_contract_key) is None,
  )
  assert_true(
    ecosystem_world_snapshot_cache.get(candidate_snapshot_key) is None,
  )
  assert_true(
    ecosystem_contract_world_cache.get(current_contract_key) is Some(_),
  )
  assert_true(elapsed_ms < 3000.0)
}

///|
test "benchmark: building click uses canonical membership without candidate compile" {
  let seed = active_energy_valley_seed()
  let model = { ..init_model(), energy_tool: WorkshopTool }
  let current_snapshot_key = ecosystem_snapshot_cache_key(model, seed)
  let current_contract_key = ecosystem_contract_world_cache_key(model, seed)
  let world = ecosystem_contract_world_for_model(model, seed)
  let requested = world_mutation_benchmark_building(world).unwrap()
  assert_true(
    ecosystem_contract_world_cache.get(current_contract_key) is Some(_),
  )
  let started_at = browser_now_ms()
  let candidate = golden_valley_place_custom_building_model(
    model,
    requested.x,
    requested.y,
  )
  let elapsed_ms = browser_now_ms() - started_at
  let candidate_snapshot_key = ecosystem_snapshot_cache_key(candidate, seed)
  let candidate_contract_key = ecosystem_contract_world_cache_key(
    candidate, seed,
  )
  println("WORLD_MUTATION_BENCH kind=building elapsed_ms=\{elapsed_ms}")
  match candidate.energy_selected_building {
    Some(building) =>
      assert_true(golden_valley_canonical_building_active(candidate, building))
    None => fail("expected accepted building click")
  }
  assert_true(candidate_snapshot_key != current_snapshot_key)
  assert_true(
    ecosystem_contract_world_cache.get(candidate_contract_key) is None,
  )
  assert_true(
    ecosystem_world_snapshot_cache.get(candidate_snapshot_key) is None,
  )
  assert_true(
    ecosystem_contract_world_cache.get(current_contract_key) is Some(_),
  )
  assert_true(elapsed_ms < 3000.0)
}
