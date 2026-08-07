///|
fn test_id(scope : String, key : String) -> StableId raise {
  match stable_id(scope, key) {
    Ok(id) => id
    Err(_) => fail("test stable identity must be valid")
  }
}

///|
fn test_provenance() -> Provenance {
  provenance("wenyu-reference-labels", "v1", WenyuReference, Fixed)
}

///|
fn test_polygon(x : Double, y : Double, size : Double) -> Polygon {
  polygon([
    world_point(x, y),
    world_point(x + size, y),
    world_point(x + size, y + size),
    world_point(x, y + size),
  ])
}

///|
fn test_world(disconnect_entrance? : Bool = false) -> CompiledTownWorld raise {
  let source = test_provenance()
  let blueprint_id = test_id("blueprint", "wenyu-v1")
  let node_a_id = test_id("road-node", "0-0")
  let node_b_id = test_id("road-node", "10-0")
  let node_c_id = test_id("road-node", "20-0")
  let segment_a_id = test_id("road-segment", "0-0--10-0")
  let segment_b_id = test_id("road-segment", "10-0--20-0")
  let nodes = [
    road_node(node_a_id, grid_position(0, 0), world_point(0.0, 0.0), source),
    road_node(node_b_id, grid_position(10, 0), world_point(10.0, 0.0), source),
    road_node(node_c_id, grid_position(20, 0), world_point(20.0, 0.0), source),
  ]
  let segments = [
    road_segment(
      segment_a_id,
      node_a_id,
      node_b_id,
      [world_point(0.0, 0.0), world_point(10.0, 0.0)],
      Local,
      6.0,
      [Pedestrian, Bicycle],
      source,
    ),
  ]
  if !disconnect_entrance {
    segments.push(
      road_segment(
        segment_b_id,
        node_b_id,
        node_c_id,
        [world_point(10.0, 0.0), world_point(20.0, 0.0)],
        Footpath,
        3.0,
        [Pedestrian],
        source,
      ),
    )
  }
  let network = road_network(nodes, segments, [node_a_id])
  let block_id = test_id("land-block", "energy-core")
  let parcel_id = test_id("parcel", "energy-core-01")
  let block = land_block(
    block_id,
    test_polygon(0.0, 0.0, 40.0),
    Research,
    [parcel_id],
    [segment_a_id],
    Bounded,
    source,
  )
  let parcel = parcel(
    parcel_id,
    block_id,
    test_polygon(10.0, 5.0, 15.0),
    Research,
    [segment_a_id],
    ["knowledge-lab"],
    Bounded,
    source,
  )
  let place_id = test_id("place", "knowledge-lab-01")
  let portal_id = test_id("portal", "knowledge-lab-01-20-0")
  let slot_id = test_id("slot", "knowledge-lab-01-exchange")
  let target_id = test_id("attention-target", "knowledge-lab-01-exchange")
  let work_binding = runtime_binding(
    MoonBook,
    "energy-research-book",
    "research.execute",
  )
  let slot = interaction_slot(
    slot_id,
    ExchangeDesk,
    "Research exchange",
    world_point(18.0, 8.0),
    4,
    Some(target_id),
    Some(work_binding),
  )
  let lab = place(
    place_id,
    "Knowledge Lab",
    Building,
    Some(parcel_id),
    test_polygon(15.0, 5.0, 8.0),
    [
      entrance_portal(
        portal_id,
        world_point(20.0, 1.0),
        Some(node_c_id),
        [Pedestrian],
        primary=true,
      ),
    ],
    [KnowledgeWork, RuntimeWork, Social, Accessible],
    [slot],
    Some(building_profile("knowledge-lab", 4, 18.0, Garden, 41)),
    Some(work_binding),
    source,
  )
  let target = attention_target(
    target_id,
    Some(slot_id),
    InteractionSlot,
    "Research exchange",
    world_point(18.0, 8.0),
    700,
    ["work", "social"],
  )
  compiled_town_world(
    "energy-valley.world.v1",
    blueprint_id,
    "sha256:test-wenyu-blueprint",
    20260727,
    world_bounds(world_point(0.0, 0.0), world_point(100.0, 100.0, z=50.0)),
    [
      terrain_region(
        test_id("terrain", "energy-core"),
        Meadow,
        test_polygon(0.0, 0.0, 80.0),
        true,
        source,
      ),
    ],
    network,
    [block],
    [parcel],
    [lab],
    [target],
  )
}

///|
test "stable IDs canonicalize source keys deterministically" {
  let first = test_id(" Road Node ", "Main Gate #1")
  let second = test_id("road_node", "main---gate 1")
  assert_eq(first, second)
  assert_eq(first.to_string(), "road-node/main-gate-1")
  assert_eq(first.scope(), "road-node")
  assert_eq(first.local_key(), "main-gate-1")
  assert_true(stable_id(" ", "???") is Err(_))
}

///|
test "typed road topology is shared by navigation and portal validation" {
  let world = test_world()
  let anchor = test_id("road-node", "0-0")
  let entrance = test_id("road-node", "20-0")
  assert_true(world.road_network.is_reachable(anchor, entrance))
  assert_true(world.road_network.is_reachable(entrance, anchor))
  assert_false(world.road_network.is_reachable(anchor, entrance, mode=Transit))
  let pedestrian_path = world.road_network
    .shortest_path(anchor, entrance)
    .unwrap()
  assert_eq(pedestrian_path.length(), 3)
  assert_eq(pedestrian_path[0].id, anchor)
  assert_eq(pedestrian_path[2].id, entrance)
  assert_true(
    world.road_network.shortest_path(anchor, entrance, mode=Transit) is None,
  )
  assert_true(validate_world(world).is_empty())
}

///|
test "validation rejects a primary portal disconnected from access anchors" {
  let issues = validate_world(test_world(disconnect_entrance=true))
  assert_true(issues.any(issue => issue.code == UnreachablePortal))
  assert_true(has_errors(issues))
}

///|
test "sealed authored building is preserved without fabricating road access" {
  let source = test_world()
  let sealed_place = {
    ..source.places[0],
    entrances: [],
    traits: [KnowledgeWork],
    interaction_slots: [],
  }
  let sealed_world = { ..source, places: [sealed_place], attention_targets: [] }
  assert_false(has_errors(validate_world(sealed_world)))
  let falsely_accessible = {
    ..sealed_place,
    traits: [KnowledgeWork, Accessible],
  }
  let invalid_world = { ..sealed_world, places: [falsely_accessible] }
  let issues = validate_world(invalid_world)
  assert_true(issues.any(issue => issue.code == MissingPrimaryEntrance))
  assert_true(has_errors(issues))
}

///|
test "snapshot attention is semantic, time-bounded, and target-linked" {
  let world = test_world()
  let target_id = test_id("attention-target", "knowledge-lab-01-exchange")
  let actor_id = test_id("agent", "researcher-01")
  let active = attention_signal(
    test_id("attention-signal", "exchange-opened"),
    target_id,
    Some(actor_id),
    Work,
    850,
    10,
    Some(20),
  )
  let expired = attention_signal(
    test_id("attention-signal", "bell-ended"),
    target_id,
    None,
    Sound,
    400,
    1,
    Some(4),
  )
  let snapshot = town_snapshot(world, 12, [active, expired], [
    attention_focus(actor_id, target_id, 900, 11),
  ])
  assert_eq(snapshot.active_signals().length(), 1)
  assert_eq(snapshot.signals_for(target_id).length(), 1)
  assert_true(validate_snapshot(snapshot).is_empty())
}
