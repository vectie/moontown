///|
fn runtime_agent_test_map_positions(
  model : Model,
  viewport_width : Int,
  viewport_height : Int,
) -> Array[RuntimeAgentMapPosition] {
  if !energy_valley_runtime_can_claim_active_work(model.energy_valley_runtime) {
    return []
  }
  golden_valley_runtime_agent_map_positions_from_snapshot(
    ecosystem_contract_town_snapshot(model, active_energy_valley_seed()),
    town_snapshot_selected_actor_id(model.selection),
    viewport_width,
    viewport_height,
  )
}

///|
fn runtime_agent_test_hit(
  model : Model,
  viewport_width : Int,
  viewport_height : Int,
  pointer_x : Int,
  pointer_y : Int,
) -> String? {
  if !energy_valley_runtime_can_claim_active_work(model.energy_valley_runtime) {
    return None
  }
  golden_valley_runtime_agent_hit_test_from_snapshot(
    ecosystem_contract_town_snapshot(model, active_energy_valley_seed()),
    town_snapshot_selected_actor_id(model.selection),
    viewport_width,
    viewport_height,
    pointer_x,
    pointer_y,
    golden_valley_camera_zoom(),
  )
}

///|
test "runtime agent hit geometry follows the rendered sprite body" {
  // At overview zoom the renderer clamps the sprite to roughly 20 px tall;
  // the interaction target remains large enough for a deliberate click.
  assert_true(
    golden_valley_runtime_agent_hit_score(100.0, 88.0, 100.0, 100.0, 0.1)
    is Some(_),
  )
  assert_true(
    golden_valley_runtime_agent_hit_score(117.9, 104.0, 100.0, 100.0, 0.1)
    is Some(_),
  )
  assert_true(
    golden_valley_runtime_agent_hit_score(118.1, 100.0, 100.0, 100.0, 0.1)
    is None,
  )
  assert_true(
    golden_valley_runtime_agent_hit_score(100.0, 73.4, 100.0, 100.0, 0.1)
    is None,
  )
  assert_true(
    golden_valley_runtime_agent_hit_score(100.0, 112.1, 100.0, 100.0, 0.1)
    is None,
  )
}

///|
test "runtime agent hit geometry grows with a focused camera" {
  assert_true(
    golden_valley_runtime_agent_hit_score(125.0, 55.0, 100.0, 100.0, 1.2)
    is Some(_),
  )
  assert_true(
    golden_valley_runtime_agent_hit_score(130.0, 55.0, 100.0, 100.0, 1.2)
    is None,
  )
}

///|
test "runtime agent route speeds stay aligned with role choreography" {
  let base : EnergyValleyRuntimeAgent = {
    id: "agent-1",
    name: "Agent 1",
    role: "researcher",
    avatarRef: None,
    status: "working",
    buildingModuleKey: Some("social-square"),
    workItemId: None,
    runId: None,
    bookId: None,
    activityKind: None,
    activityLabel: None,
    originBuildingModuleKey: None,
    destinationBuildingModuleKey: None,
  }
  assert_eq(golden_valley_runtime_agent_route_speed(base), 1.7)
  assert_eq(
    golden_valley_runtime_agent_route_speed({ ..base, role: "mayor" }),
    2.0,
  )
  assert_eq(
    golden_valley_runtime_agent_route_speed({ ..base, role: "worker" }),
    2.6,
  )
}

///|
test "stale runtime residents cannot receive map clicks" {
  let stale = { ..energy_valley_runtime_loading_state(), phase: Stale }
  let model = { ..init_model(), energy_valley_runtime: stale }
  assert_true(runtime_agent_test_map_positions(model, 1280, 720).is_empty())
  assert_eq(runtime_agent_test_hit(model, 1280, 720, 640, 360), None)
}

///|
fn runtime_map_routing_test_task(
  origin_id : String,
  destination_id : String,
) -> EnergyValleyRuntimeWorkItem {
  {
    id: "routing-task",
    title: "Route a real resident",
    status: "running",
    buildingModuleKey: destination_id,
    agentId: Some("routing-agent"),
    agentName: Some("Road Scout"),
    role: Some("worker"),
    runId: Some("routing-run"),
    bookId: Some(origin_id),
    summary: None,
    updatedAt: None,
    requestId: None,
    standingGoalId: None,
    correlationId: None,
    artifacts: [],
    resultLinks: None,
    collaboration: None,
    progress: None,
    activityKind: Some("walking"),
    activityLabel: Some("Walking to the work building"),
    originBuildingModuleKey: Some(origin_id),
    destinationBuildingModuleKey: Some(destination_id),
    source: "town-runtime",
  }
}

///|
fn runtime_map_routing_test_agent(
  origin_id : String,
  destination_id : String,
) -> EnergyValleyRuntimeAgent {
  {
    id: "routing-agent",
    name: "Road Scout",
    role: "worker",
    avatarRef: None,
    status: "running",
    buildingModuleKey: Some(destination_id),
    workItemId: Some("routing-task"),
    runId: Some("routing-run"),
    bookId: Some(origin_id),
    activityKind: Some("walking"),
    activityLabel: Some("Walking to the work building"),
    originBuildingModuleKey: Some(origin_id),
    destinationBuildingModuleKey: Some(destination_id),
  }
}

///|
fn runtime_map_routing_live_model() -> Model {
  let origin_id = "town-shell"
  let destination_id = "social-square"
  let agent = runtime_map_routing_test_agent(origin_id, destination_id)
  let projection : EnergyValleyRuntimeProjection = {
    schema: energy_valley_runtime_schema(),
    mode: "live",
    observedAt: "2026-08-06T12:00:00.000Z",
    knowledgeCatalogDigest: None,
    tick: Some(41),
    tasks: [runtime_map_routing_test_task(origin_id, destination_id)],
    history: None,
    agents: [agent],
    message: None,
  }
  {
    ..init_model(),
    tick: 80,
    energy_valley_runtime: {
      phase: Live,
      projection: Some(projection),
      version: 1,
      fresh_at_ms: 1.0,
      presence_started_at_tick: 41,
      // A missing per-journey clock safely starts at zero. The lifecycle helper
      // itself is tested with explicit elapsed values below.
      presence_clocks: [],
      error: "",
    },
    energy_tool: InspectTool,
  }
}

///|
fn runtime_map_routing_test_building(
  name : String,
  module_key : String,
  x : Int,
  y : Int,
) -> GoldenValleyBuilding {
  {
    authored_id: None,
    module_key: Some(module_key),
    name,
    style: "custom-lab",
    x,
    y,
    width: 1,
    depth: 1,
    entrance_x: Some(x),
    entrance_y: Some(y),
    floors: 1,
  }
}

///|
fn runtime_map_routing_overlap_candidate(
  model : Model,
  position : RuntimeAgentMapPosition,
) -> (GoldenValleyBuilding, Int, Int)? {
  let center_x = position.screen_x.floor().to_int()
  let center_y = position.screen_y.floor().to_int()
  let seen_tiles : Map[String, Bool] = Map([])
  for dy in -72..<=8 {
    if dy % 4 != 0 {
      continue
    }
    for dx in -24..<=24 {
      if dx % 4 != 0 {
        continue
      }
      let pointer_x = center_x + dx
      let pointer_y = center_y + dy
      if golden_valley_runtime_agent_hit_score(
          pointer_x.to_double(),
          pointer_y.to_double(),
          position.screen_x,
          position.screen_y,
          golden_valley_camera_zoom(),
        )
        is None {
        continue
      }
      let tile = golden_valley_screen_to_tile(pointer_x, pointer_y)
      let tile_key = golden_valley_tile_key(tile.0, tile.1)
      if seen_tiles.contains(tile_key) {
        continue
      }
      seen_tiles[tile_key] = true
      let candidate = runtime_map_routing_test_building(
        "Routing overlap building",
        "routing-overlap-building",
        tile.0,
        tile.1,
      )
      if golden_valley_custom_placement_clear(model, candidate) {
        return Some((candidate, pointer_x, pointer_y))
      }
    }
  }
  None
}

///|
fn runtime_map_accept_fixture_frame(
  model : Model,
) -> @energy_valley_contract.TownSnapshot {
  let snapshot = ecosystem_contract_town_snapshot(
    model,
    active_energy_valley_seed(),
  )
  golden_valley_accept_canvas_frame(snapshot)
  snapshot
}

///|
test "runtime Agents use semantic Place portals and the typed pedestrian road graph" {
  let model = runtime_map_routing_live_model()
  let seed = active_energy_valley_seed()
  let agent = model.energy_valley_runtime.projection.unwrap().agents[0]
  let path = golden_valley_runtime_agent_semantic_path(model, seed, agent).unwrap()
  assert_true(path.length() > 2)
  let buildings = golden_valley_buildings(seed)
  let origin = golden_valley_runtime_agent_origin(
    model.energy_valley_runtime,
    buildings,
    agent,
  )
  let destination = golden_valley_runtime_agent_destination(
    model.energy_valley_runtime,
    buildings,
    agent,
  ).unwrap()
  let world = ecosystem_contract_world_for_model(model, seed)
  let source_place_id = golden_valley_runtime_agent_semantic_place_id(
    world, origin,
  ).unwrap()
  let target_place_id = golden_valley_runtime_agent_semantic_place_id(
    world, destination,
  ).unwrap()
  let source_portal = world
    .find_place(source_place_id)
    .unwrap()
    .primary_entrance()
    .unwrap()
  let target_portal = world
    .find_place(target_place_id)
    .unwrap()
    .primary_entrance()
    .unwrap()
  assert_eq(path[0], (source_portal.position.x, source_portal.position.y))
  assert_eq(
    path[path.length() - 1],
    (target_portal.position.x, target_portal.position.y),
  )
  let source_node = source_portal.road_node_id.unwrap()
  let target_node = target_portal.road_node_id.unwrap()
  assert_true(
    world.road_network.shortest_path(
      source_node,
      target_node,
      mode=@energy_valley_contract.Pedestrian,
    )
    is Some(_),
  )
}

///|
test "runtime route lifecycle travels, arrives, then moves presence inside" {
  let model = runtime_map_routing_live_model()
  let seed = active_energy_valley_seed()
  let agent = model.energy_valley_runtime.projection.unwrap().agents[0]
  let path = golden_valley_runtime_agent_semantic_path(model, seed, agent).unwrap()
  let route_distance = (path.length() - 1).to_double()
  let speed = golden_valley_runtime_agent_route_speed(agent)
  let traveling = golden_valley_runtime_agent_journey_at(
    model, seed, agent, 0.0,
  )
  assert_true(traveling.phase is RuntimeRouteTraveling)
  assert_true(traveling.position is Some(_))
  let arriving = golden_valley_runtime_agent_journey_at(
    model,
    seed,
    agent,
    (route_distance - 0.5) / speed,
  )
  assert_true(arriving.phase is RuntimeRouteArriving)
  assert_true(arriving.position is Some(_))
  let inside = golden_valley_runtime_agent_journey_at(
    model,
    seed,
    agent,
    route_distance / speed + 0.01,
  )
  assert_true(inside.phase is RuntimeRouteInside)
  assert_true(inside.position is None)
  assert_eq(inside.progress_per_mille, 1000)
  assert_true(
    golden_valley_runtime_agent_world_position_at(
      model,
      seed,
      agent,
      route_distance / speed + 0.01,
    )
    is None,
  )
}

///|
test "unresolved runtime destination stays explicitly unreachable" {
  let base = runtime_map_routing_live_model()
  let projection = base.energy_valley_runtime.projection.unwrap()
  let missing = "missing-semantic-place"
  let task = {
    ..projection.tasks[0],
    buildingModuleKey: missing,
    bookId: Some("town-shell"),
    destinationBuildingModuleKey: Some(missing),
  }
  let agent = {
    ..projection.agents[0],
    buildingModuleKey: Some(missing),
    destinationBuildingModuleKey: Some(missing),
  }
  let model = {
    ..base,
    energy_valley_runtime: {
      ..base.energy_valley_runtime,
      projection: Some({ ..projection, tasks: [task], agents: [agent] }),
    },
  }
  let journey = golden_valley_runtime_agent_journey_at(
    model,
    active_energy_valley_seed(),
    agent,
    100000.0,
  )
  assert_true(journey.phase is RuntimeRouteUnreachable)
  assert_true(journey.path.is_empty())
  assert_true(journey.position is None)
  assert_eq(journey.progress_per_mille, 0)
}

///|
test "runtime presence evidence tick is stable across animation ticks" {
  let base = runtime_map_routing_live_model()
  let agent = base.energy_valley_runtime.projection.unwrap().agents[0]
  assert_eq(golden_valley_runtime_agent_presence_since_tick(base, agent), 41)
  assert_eq(
    golden_valley_runtime_agent_presence_since_tick(
      { ..base, tick: base.tick + 200 },
      agent,
    ),
    41,
  )
  let projection = base.energy_valley_runtime.projection.unwrap()
  let without_source_tick = {
    ..base,
    energy_valley_runtime: {
      ..base.energy_valley_runtime,
      projection: Some({ ..projection, tick: None }),
      version: 7,
      presence_started_at_tick: 7,
    },
  }
  assert_eq(
    golden_valley_runtime_agent_presence_since_tick(without_source_tick, agent),
    7,
  )
  assert_eq(
    golden_valley_runtime_agent_presence_since_tick(
      { ..without_source_tick, tick: without_source_tick.tick + 200 },
      agent,
    ),
    7,
  )
}

///|
fn runtime_map_routing_agent_click_fixture() -> (Model, Int, Int) raise {
  let base = runtime_map_routing_live_model()
  let projection = base.energy_valley_runtime.projection.unwrap()
  let route = golden_valley_runtime_agent_semantic_path(
    base,
    active_energy_valley_seed(),
    projection.agents[0],
  ).unwrap()
  golden_focus_building_camera(route[0].0, route[0].1)
  let positions = runtime_agent_test_map_positions(base, 1280, 720)
  guard positions is [position, ..] else {
    fail("expected the live routing resident to be visible")
  }
  let (overlap, pointer_x, pointer_y) = match
    runtime_map_routing_overlap_candidate(base, position) {
    Some(value) => value
    None => fail("expected a canonical roadside tile inside the Agent hitbox")
  }
  let (model, identified) = energy_valley_model_add_building_delta_with_identity(
    base,
    overlap,
    energy_valley_model_budget(base),
    energy_valley_model_next_authored_building_sequence(base),
  )
  guard golden_valley_canonical_building_active(model, identified) else {
    fail("expected the overlap building Add to survive canonical projection")
  }
  let tile = golden_valley_screen_to_tile(pointer_x, pointer_y)
  let snapshot = runtime_map_accept_fixture_frame(model)
  guard town_snapshot_canvas_building_at_tile(snapshot, tile.0, tile.1)
    is Some(_) else {
    fail("expected the accepted Canvas frame to contain the overlap building")
  }
  guard golden_valley_runtime_agent_hit_test_from_snapshot(
      snapshot,
      town_snapshot_selected_actor_id(model.selection),
      1280,
      720,
      pointer_x,
      pointer_y,
      golden_valley_camera_zoom(),
    ) ==
    Some("routing-agent") else {
    fail("expected the chosen building pointer to remain inside the Agent body")
  }
  (model, pointer_x, pointer_y)
}

///|
fn runtime_map_routing_building_fallback_fixture() -> (Model, Int, Int) raise {
  let base = runtime_map_routing_live_model()
  let agent = base.energy_valley_runtime.projection.unwrap().agents[0]
  let route = golden_valley_runtime_agent_semantic_path(
    base,
    active_energy_valley_seed(),
    agent,
  ).unwrap()
  let route_x = route[0].0.floor().to_int()
  let route_y = route[0].1.floor().to_int()
  let scale = energy_valley_semantic_cells_per_planning_cell()
  for y in 1..<(golden_valley_rows() - 1) {
    for x in 1..<(golden_valley_cols() - 1) {
      if x % scale != 0 ||
        y % scale != 0 ||
        abs_int(x - route_x) + abs_int(y - route_y) < 48 {
        continue
      }
      let candidate = runtime_map_routing_test_building(
        "Routing fallback building", "routing-fallback-building", x, y,
      )
      if !golden_valley_custom_placement_clear(base, candidate) {
        continue
      }
      golden_focus_building_camera(
        candidate.x.to_double() + 0.5,
        candidate.y.to_double() + 0.5,
      )
      let pointer_x = golden_screen_x(
          candidate.x.to_double() + 0.5,
          candidate.y.to_double() + 0.5,
          1280,
        )
        .floor()
        .to_int()
      let pointer_y = golden_screen_y(
          candidate.x.to_double() + 0.5,
          candidate.y.to_double() + 0.5,
          720,
        )
        .floor()
        .to_int()
      if runtime_agent_test_hit(base, 1280, 720, pointer_x, pointer_y)
        is Some(_) {
        continue
      }
      let (model, identified) = energy_valley_model_add_building_delta_with_identity(
        base,
        candidate,
        energy_valley_model_budget(base),
        energy_valley_model_next_authored_building_sequence(base),
      )
      guard golden_valley_canonical_building_active(model, identified) else {
        fail(
          "expected the fallback building Add to survive canonical projection",
        )
      }
      let snapshot = runtime_map_accept_fixture_frame(model)
      guard town_snapshot_canvas_building_at_tile(snapshot, x, y) is Some(_) else {
        fail(
          "expected the accepted Canvas frame to contain the fallback building",
        )
      }
      return (model, pointer_x, pointer_y)
    }
  }
  fail("expected a canonical fallback building outside the live Agent hitbox")
}

///|
test "canvas inspect gives a live runtime agent priority over an overlapping building" {
  let (model, pointer_x, pointer_y) = runtime_map_routing_agent_click_fixture()
  let tile = golden_valley_screen_to_tile(pointer_x, pointer_y)
  let snapshot = ecosystem_contract_town_snapshot(
    model,
    active_energy_valley_seed(),
  )
  golden_valley_accept_canvas_frame(snapshot)
  assert_true(
    town_snapshot_canvas_building_at_tile(snapshot, tile.0, tile.1) is Some(_),
  )
  let positions = golden_valley_runtime_agent_map_positions_from_snapshot(
    snapshot,
    town_snapshot_selected_actor_id(model.selection),
    1280,
    720,
  )
  assert_eq(positions.length(), 1)
  assert_eq(
    runtime_agent_test_hit(model, 1280, 720, pointer_x, pointer_y),
    Some("routing-agent"),
  )
  let (_, next) = energy_canvas_click_routed(model, pointer_x, pointer_y)
  assert_true(next.selection is Agent("routing-agent"))
  assert_true(next.energy_selected_building is None)
}

///|
test "canvas walk mode has priority over a live runtime agent hit" {
  let (base, pointer_x, pointer_y) = runtime_map_routing_agent_click_fixture()
  let player : PlayerAvatar = {
    name: "Walker",
    persona: "researcher",
    color: 0,
    sprite_index: 0,
    title: "New resident",
  }
  let model = { ..base, walk_mode: true, player: Some(player) }
  let (_, next) = energy_canvas_click_routed(model, pointer_x, pointer_y)
  assert_false(next.selection is Agent(_))
  assert_true(next.walk_mode)
  // The deliberately overlapping building makes this target impassable. This
  // walk-only feedback proves the click returned before Agent inspection.
  assert_true(next.life_toast.contains("那里过不去"))
}

///|
test "stale runtime agent falls through to the building under the pointer" {
  let (live, pointer_x, pointer_y) = runtime_map_routing_agent_click_fixture()
  let model = {
    ..live,
    energy_valley_runtime: { ..live.energy_valley_runtime, phase: Stale },
  }
  assert_eq(
    runtime_agent_test_hit(model, 1280, 720, pointer_x, pointer_y),
    None,
  )
  // The stale Model becomes interaction truth only after its own frame has
  // completed drawing; the fixture explicitly accepts that exact frame.
  ignore(runtime_map_accept_fixture_frame(model))
  let (_, next) = energy_canvas_click_routed(model, pointer_x, pointer_y)
  guard next.energy_selected_building is Some(building) else {
    fail("expected stale Agent data to fall through to building inspection")
  }
  assert_eq(building.name, "Routing overlap building")
  assert_true(next.selection is Overview)
}

///|
test "canvas inspect keeps normal building fallback outside a live agent hitbox" {
  let (model, pointer_x, pointer_y) = runtime_map_routing_building_fallback_fixture()
  assert_eq(
    runtime_agent_test_hit(model, 1280, 720, pointer_x, pointer_y),
    None,
  )
  let (_, next) = energy_canvas_click_routed(model, pointer_x, pointer_y)
  guard next.energy_selected_building is Some(building) else {
    fail("expected normal building inspection fallback")
  }
  assert_eq(building.name, "Routing fallback building")
}

///|
test "selected runtime resident is visibly marked in the shared sprite record" {
  let base = runtime_map_routing_live_model()
  let unselected_snapshot = ecosystem_contract_town_snapshot(
    base,
    active_energy_valley_seed(),
  )
  let unselected = town_snapshot_canvas_agents(
    unselected_snapshot,
    0.0,
    false,
    None,
  ).filter(agent => !agent.preview)
  assert_eq(unselected.length(), 1)
  assert_false(unselected[0].selected)
  let selected_model = { ..base, selection: Agent("routing-agent") }
  let selected_snapshot = ecosystem_contract_town_snapshot(
    selected_model,
    active_energy_valley_seed(),
  )
  let selected = town_snapshot_canvas_agents(
    selected_snapshot,
    0.0,
    false,
    town_snapshot_selected_actor_id(selected_model.selection),
  ).filter(agent => !agent.preview)
  assert_eq(selected.length(), 1)
  assert_true(selected[0].selected)
}
