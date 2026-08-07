///|
fn world_projection_isolation_add(
  epoch : TownLifeWorldEpoch,
  writer : String,
  sequence : Int,
  kind : TownLifeWorldKind,
  entity_id : String,
  payload : TownLifeWorldPayload,
) -> TownLifeWorldEvent {
  let id = "\{writer}:\{sequence}:add"
  {
    id,
    dot: { writer_id: writer, sequence },
    stamp: { writer_id: writer, lamport: sequence },
    epoch_id: epoch.id,
    kind,
    entity_id,
    incarnation_id: id,
    action: WorldAdd(payload),
    budget_delta: 0,
  }
}

///|
fn world_projection_isolation_delete_road(
  epoch : TownLifeWorldEpoch,
  writer : String,
  sequence : Int,
  added : TownLifeWorldEvent,
) -> TownLifeWorldEvent {
  {
    id: "\{writer}:\{sequence}:delete",
    dot: { writer_id: writer, sequence },
    stamp: { writer_id: writer, lamport: sequence },
    epoch_id: epoch.id,
    kind: WorldRoadCell,
    entity_id: added.entity_id,
    incarnation_id: added.incarnation_id,
    action: WorldDelete,
    budget_delta: 0,
  }
}

///|
fn world_projection_isolation_move_park(
  epoch : TownLifeWorldEpoch,
  writer : String,
  sequence : Int,
  added : TownLifeWorldEvent,
  target : SavedWorldDeltaGridPoint,
) -> TownLifeWorldEvent {
  let id = "\{writer}:\{sequence}:move"
  {
    id,
    dot: { writer_id: writer, sequence },
    stamp: { writer_id: writer, lamport: sequence },
    epoch_id: epoch.id,
    kind: WorldPark,
    entity_id: added.entity_id,
    incarnation_id: added.incarnation_id,
    action: WorldMove(
      WorldParkPayload({ id: added.entity_id, x: target.x, y: target.y }),
    ),
    budget_delta: 0,
  }
}

///|
fn world_projection_isolation_connected_extension(
  world : @energy_valley_contract.CompiledTownWorld,
) -> SavedWorldDeltaGridPoint? {
  let base_roads = town_life_world_base_road_cells(world)
  for node in world.road_network.nodes {
    let base_key = golden_valley_tile_key(node.grid.column, node.grid.row)
    if !base_roads.contains(base_key) {
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
fn world_projection_isolation_dependent_chain(
  world : @energy_valley_contract.CompiledTownWorld,
) -> (SavedWorldDeltaGridPoint, SavedWorldDeltaGridPoint)? {
  let base_roads = town_life_world_base_road_cells(world)
  for node in world.road_network.nodes {
    if !base_roads.contains(
        golden_valley_tile_key(node.grid.column, node.grid.row),
      ) {
      continue
    }
    for first_delta in [(0, -1), (1, 0), (0, 1), (-1, 0)] {
      let first : SavedWorldDeltaGridPoint = {
        x: node.grid.column + first_delta.0,
        y: node.grid.row + first_delta.1,
      }
      let first_key = golden_valley_tile_key(first.x, first.y)
      if base_roads.contains(first_key) ||
        !town_life_world_road_point_allowed(world, base_roads, first.x, first.y) ||
        town_life_world_reachable_custom_roads(world, [first_key]) is None {
        continue
      }
      for second_delta in [(0, -1), (1, 0), (0, 1), (-1, 0)] {
        let second : SavedWorldDeltaGridPoint = {
          x: first.x + second_delta.0,
          y: first.y + second_delta.1,
        }
        let second_key = golden_valley_tile_key(second.x, second.y)
        if second_key != first_key &&
          !base_roads.contains(second_key) &&
          town_life_world_road_point_allowed(
            world,
            base_roads,
            second.x,
            second.y,
          ) &&
          town_life_world_reachable_custom_roads(world, [second_key]) is None &&
          town_life_world_reachable_custom_roads(world, [first_key, second_key])
          is Some(_) {
          return Some((first, second))
        }
      }
    }
  }
  None
}

///|
fn world_projection_isolation_unrelated_extension(
  world : @energy_valley_contract.CompiledTownWorld,
  excluded : ArrayView[String],
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
      if !excluded.contains(key) &&
        !base_roads.contains(key) &&
        town_life_world_road_point_allowed(world, base_roads, point.x, point.y) &&
        town_life_world_reachable_custom_roads(world, [key]) is Some(_) {
        return Some(point)
      }
    }
  }
  None
}

///|
fn world_projection_isolation_detached_park_cell(
  world : @energy_valley_contract.CompiledTownWorld,
  away_from? : SavedWorldDeltaGridPoint,
) -> SavedWorldDeltaGridPoint? {
  let base_roads = town_life_world_base_road_cells(world)
  for y in 0..<golden_valley_rows() {
    for x in 0..<golden_valley_cols() {
      let key = golden_valley_tile_key(x, y)
      let far_enough = match away_from {
        None => true
        Some(point) => (point.x - x).abs() + (point.y - y).abs() > 1
      }
      if far_enough &&
        ecosystem_contract_terrain_kind_at(world, x, y) ==
        Some(@energy_valley_contract.Meadow) &&
        golden_valley_tile_placement_block_in_world(world, x, y) is None &&
        town_life_world_road_point_allowed(world, base_roads, x, y) &&
        town_life_world_reachable_custom_roads(world, [key]) is None {
        return Some({ x, y })
      }
    }
  }
  None
}

///|
fn world_projection_isolation_active(
  projection : TownLifeWorldProjection,
  kind : TownLifeWorldKind,
  entity_id : String,
) -> Bool {
  projection.active.any(incarnation => {
    incarnation.kind == kind && incarnation.entity_id == entity_id
  })
}

///|
fn world_projection_isolation_valid_building(
  world : @energy_valley_contract.CompiledTownWorld,
) -> GoldenValleyBuilding? {
  let base_roads = town_life_world_base_road_cells(world)
  let custom_roads : Map[String, Bool] = Map([])
  for y in 1..<(golden_valley_rows() - 1) {
    for x in 1..<(golden_valley_cols() - 1) {
      let fixture : GoldenValleyBuilding = {
        authored_id: None,
        module_key: None,
        name: "Projection budget fixture",
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
        return Some(fixture)
      }
    }
  }
  None
}

///|
test "invalid detached road cannot suppress a valid colliding park" {
  let seed = active_energy_valley_seed()
  let world = energy_valley_base_contract_world_for_seed(seed)
  let base = town_life_world_empty_state_for_seed(seed)
  let point = world_projection_isolation_detached_park_cell(world).unwrap()
  let road_id = "road-cell-\{point.x}-\{point.y}"
  let park_id = energy_valley_saved_park_id(point.x, point.y)
  let road = world_projection_isolation_add(
    base.epoch,
    "invalid-road",
    2,
    WorldRoadCell,
    road_id,
    WorldRoadCellPayload(point),
  )
  let park = world_projection_isolation_add(
    base.epoch,
    "valid-park",
    3,
    WorldPark,
    park_id,
    WorldParkPayload({ id: park_id, x: point.x, y: point.y }),
  )
  let projection = town_life_world_projection(
    { ..base, events: [road, park] },
    seed,
  )
  assert_false(
    world_projection_isolation_active(projection, WorldRoadCell, road_id),
  )
  assert_true(world_projection_isolation_active(projection, WorldPark, park_id))
}

///|
test "detached road component cannot suppress an unrelated connected extension" {
  let seed = active_energy_valley_seed()
  let world = energy_valley_base_contract_world_for_seed(seed)
  let base = town_life_world_empty_state_for_seed(seed)
  let connected = world_projection_isolation_connected_extension(world).unwrap()
  let detached = world_projection_isolation_detached_park_cell(
    world,
    away_from=connected,
  ).unwrap()
  let connected_id = "road-cell-\{connected.x}-\{connected.y}"
  let detached_id = "road-cell-\{detached.x}-\{detached.y}"
  let connected_event = world_projection_isolation_add(
    base.epoch,
    "connected-road",
    2,
    WorldRoadCell,
    connected_id,
    WorldRoadCellPayload(connected),
  )
  let detached_event = world_projection_isolation_add(
    base.epoch,
    "detached-road",
    3,
    WorldRoadCell,
    detached_id,
    WorldRoadCellPayload(detached),
  )
  let projection = town_life_world_projection(
    { ..base, events: [connected_event, detached_event] },
    seed,
  )
  assert_true(
    world_projection_isolation_active(projection, WorldRoadCell, connected_id),
  )
  assert_false(
    world_projection_isolation_active(projection, WorldRoadCell, detached_id),
  )
}

///|
test "malformed building cannot reserve a valid park cell" {
  let seed = active_energy_valley_seed()
  let world = energy_valley_base_contract_world_for_seed(seed)
  let base = town_life_world_empty_state_for_seed(seed)
  let point = world_projection_isolation_detached_park_cell(world).unwrap()
  let building_id = "malformed-zero-footprint"
  let park_id = energy_valley_saved_park_id(point.x, point.y)
  let malformed = world_projection_isolation_add(
    base.epoch,
    "invalid-building",
    2,
    WorldBuilding,
    building_id,
    WorldBuildingPayload({
      authored_id: Some(building_id),
      module_key: None,
      name: "invalid",
      style: "custom-lab",
      x: point.x,
      y: point.y,
      width: 0,
      depth: 0,
      entrance_x: None,
      entrance_y: None,
      floors: 1,
    }),
  )
  let park = world_projection_isolation_add(
    base.epoch,
    "valid-park-after-invalid-building",
    3,
    WorldPark,
    park_id,
    WorldParkPayload({ id: park_id, x: point.x, y: point.y }),
  )
  let projection = town_life_world_projection(
    { ..base, events: [malformed, park] },
    seed,
  )
  assert_false(
    world_projection_isolation_active(projection, WorldBuilding, building_id),
  )
  assert_true(world_projection_isolation_active(projection, WorldPark, park_id))
}

///|
test "connector deletion is rejected without resurrecting an unrelated deletion" {
  let seed = active_energy_valley_seed()
  let world = energy_valley_base_contract_world_for_seed(seed)
  let base = town_life_world_empty_state_for_seed(seed)
  let (connector, downstream) = world_projection_isolation_dependent_chain(
    world,
  ).unwrap()
  let connector_key = golden_valley_tile_key(connector.x, connector.y)
  let downstream_key = golden_valley_tile_key(downstream.x, downstream.y)
  let unrelated = world_projection_isolation_unrelated_extension(world, [
    connector_key, downstream_key,
  ]).unwrap()
  let unrelated_key = golden_valley_tile_key(unrelated.x, unrelated.y)
  let connector_add = world_projection_isolation_add(
    base.epoch,
    "dependent-chain",
    2,
    WorldRoadCell,
    "road-cell-\{connector.x}-\{connector.y}",
    WorldRoadCellPayload(connector),
  )
  let downstream_add = world_projection_isolation_add(
    base.epoch,
    "dependent-chain",
    3,
    WorldRoadCell,
    "road-cell-\{downstream.x}-\{downstream.y}",
    WorldRoadCellPayload(downstream),
  )
  let unrelated_add = world_projection_isolation_add(
    base.epoch,
    "unrelated-branch",
    4,
    WorldRoadCell,
    "road-cell-\{unrelated.x}-\{unrelated.y}",
    WorldRoadCellPayload(unrelated),
  )
  let connector_delete = world_projection_isolation_delete_road(
    base.epoch,
    "dependent-chain-delete",
    5,
    connector_add,
  )
  let unrelated_delete = world_projection_isolation_delete_road(
    base.epoch,
    "unrelated-branch-delete",
    6,
    unrelated_add,
  )
  let projection = town_life_world_projection(
    {
      ..base,
      events: [
        connector_add, downstream_add, unrelated_add, connector_delete, unrelated_delete,
      ],
    },
    seed,
  )
  assert_true(
    world_projection_isolation_active(
      projection,
      WorldRoadCell,
      connector_add.entity_id,
    ),
  )
  assert_true(
    world_projection_isolation_active(
      projection,
      WorldRoadCell,
      downstream_add.entity_id,
    ),
  )
  assert_false(
    world_projection_isolation_active(
      projection,
      WorldRoadCell,
      unrelated_add.entity_id,
    ),
  )
  assert_true(
    projection.rejected.any(rejection => {
      rejection.event_id == connector_delete.id &&
      rejection.reason_code == "road-delete-dependency"
    }),
  )
  assert_false(
    projection.rejected.any(rejection => {
      rejection.event_id == unrelated_delete.id &&
      rejection.reason_code == "road-delete-dependency"
    }),
  )
  let roads = energy_valley_world_delta_projection(projection.ledger).roads
  assert_eq(roads.length(), 2)
  assert_true(roads.contains(connector_key))
  assert_true(roads.contains(downstream_key))
  assert_false(
    unrelated_key == connector_key || unrelated_key == downstream_key,
  )
}

///|
test "colliding move is rejected while both original park sites survive" {
  let seed = active_energy_valley_seed()
  let world = energy_valley_base_contract_world_for_seed(seed)
  let base = town_life_world_empty_state_for_seed(seed)
  let first = world_projection_isolation_detached_park_cell(world).unwrap()
  let second = world_projection_isolation_detached_park_cell(
    world,
    away_from=first,
  ).unwrap()
  let first_id = energy_valley_saved_park_id(first.x, first.y)
  let second_id = energy_valley_saved_park_id(second.x, second.y)
  let first_add = world_projection_isolation_add(
    base.epoch,
    "move-source",
    2,
    WorldPark,
    first_id,
    WorldParkPayload({ id: first_id, x: first.x, y: first.y }),
  )
  let second_add = world_projection_isolation_add(
    base.epoch,
    "move-target",
    3,
    WorldPark,
    second_id,
    WorldParkPayload({ id: second_id, x: second.x, y: second.y }),
  )
  let movement = world_projection_isolation_move_park(
    base.epoch,
    "move-source",
    4,
    first_add,
    second,
  )
  let projection = town_life_world_projection(
    { ..base, events: [first_add, second_add, movement] },
    seed,
  )
  assert_true(
    world_projection_isolation_active(projection, WorldPark, first_id),
  )
  assert_true(
    world_projection_isolation_active(projection, WorldPark, second_id),
  )
  let parks = energy_valley_world_delta_projection(projection.ledger).parks
  assert_eq(parks.length(), 2)
  assert_true(parks.contains(golden_valley_tile_key(first.x, first.y)))
  assert_true(parks.contains(golden_valley_tile_key(second.x, second.y)))
  assert_true(
    projection.rejected.any(rejection => {
      rejection.event_id == movement.id &&
      rejection.reason_code == "move-rejected"
    }),
  )
}

///|
test "later downstream Add cannot resurrect an already deleted connector" {
  let seed = active_energy_valley_seed()
  let world = energy_valley_base_contract_world_for_seed(seed)
  let base = town_life_world_empty_state_for_seed(seed)
  let (connector, downstream) = world_projection_isolation_dependent_chain(
    world,
  ).unwrap()
  let connector_add = world_projection_isolation_add(
    base.epoch,
    "inverse-chain",
    2,
    WorldRoadCell,
    "road-cell-\{connector.x}-\{connector.y}",
    WorldRoadCellPayload(connector),
  )
  let connector_delete = world_projection_isolation_delete_road(
    base.epoch,
    "inverse-chain-delete",
    3,
    connector_add,
  )
  let downstream_add = world_projection_isolation_add(
    base.epoch,
    "inverse-downstream",
    4,
    WorldRoadCell,
    "road-cell-\{downstream.x}-\{downstream.y}",
    WorldRoadCellPayload(downstream),
  )
  let projection = town_life_world_projection(
    { ..base, events: [connector_add, connector_delete, downstream_add] },
    seed,
  )
  assert_false(
    world_projection_isolation_active(
      projection,
      WorldRoadCell,
      connector_add.entity_id,
    ),
  )
  assert_false(
    world_projection_isolation_active(
      projection,
      WorldRoadCell,
      downstream_add.entity_id,
    ),
  )
  assert_true(
    energy_valley_world_delta_projection(projection.ledger).roads.is_empty(),
  )
  assert_true(
    projection.rejected.any(rejection => {
      rejection.event_id == downstream_add.id &&
      rejection.reason_code == "detached-road-cell"
    }),
  )
  assert_false(
    projection.rejected.any(rejection => {
      rejection.event_id == connector_delete.id &&
      rejection.reason_code == "road-delete-dependency"
    }),
  )
}

///|
test "valid Move cannot launder an invalid Add into spatial authority" {
  let seed = active_energy_valley_seed()
  let world = energy_valley_base_contract_world_for_seed(seed)
  let base = town_life_world_empty_state_for_seed(seed)
  let target = world_projection_isolation_detached_park_cell(world).unwrap()
  let entity_id = "laundered-park"
  let invalid_add = {
    ..world_projection_isolation_add(
      base.epoch,
      "invalid-add",
      2,
      WorldPark,
      entity_id,
      WorldParkPayload({ id: entity_id, x: -1, y: -1 }),
    ),
    budget_delta: -20,
  }
  let movement = world_projection_isolation_move_park(
    base.epoch,
    "valid-move",
    3,
    invalid_add,
    target,
  )
  let projection = town_life_world_projection(
    { ..base, events: [invalid_add, movement] },
    seed,
  )
  assert_false(
    world_projection_isolation_active(projection, WorldPark, entity_id),
  )
  assert_true(
    energy_valley_world_delta_projection(projection.ledger).parks.is_empty(),
  )
  assert_eq(projection.ledger.budget, base.epoch.base_budget)
  assert_true(
    projection.rejected.any(rejection => {
      rejection.event_id == invalid_add.id &&
      rejection.reason_code == "contract-rejected"
    }),
  )
}

///|
test "spatially invalid Add cannot starve a later valid full-budget Add" {
  let seed = active_energy_valley_seed()
  let world = energy_valley_base_contract_world_for_seed(seed)
  let base = town_life_world_empty_state_for_seed(seed)
  let valid_building = world_projection_isolation_valid_building(world).unwrap()
  let invalid_id = "budget-invalid-site"
  let valid_id = "budget-valid-site"
  let invalid_add = {
    ..world_projection_isolation_add(
      base.epoch,
      "budget-order",
      2,
      WorldBuilding,
      invalid_id,
      WorldBuildingPayload({
        ..valid_building,
        authored_id: Some(invalid_id),
        x: -100,
        y: -100,
      }),
    ),
    budget_delta: -base.epoch.base_budget,
  }
  let valid_add = {
    ..world_projection_isolation_add(
      base.epoch,
      "budget-order",
      3,
      WorldBuilding,
      valid_id,
      WorldBuildingPayload({ ..valid_building, authored_id: Some(valid_id) }),
    ),
    budget_delta: -base.epoch.base_budget,
  }
  let projection = town_life_world_projection(
    { ..base, events: [invalid_add, valid_add] },
    seed,
  )
  assert_false(
    world_projection_isolation_active(projection, WorldBuilding, invalid_id),
  )
  assert_true(
    world_projection_isolation_active(projection, WorldBuilding, valid_id),
  )
  assert_eq(projection.ledger.budget, 0)
  assert_true(
    projection.rejected.any(rejection => {
      rejection.event_id == invalid_add.id &&
      rejection.reason_code == "contract-rejected"
    }),
  )
  assert_false(
    projection.rejected.any(rejection => {
      rejection.event_id == valid_add.id &&
      rejection.reason_code == "budget-exhausted"
    }),
  )
}
