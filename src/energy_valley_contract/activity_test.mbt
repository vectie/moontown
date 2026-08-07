///|
test "town snapshot owns presence and exchange truth" {
  let world = test_world()
  let actor_id = test_id("resident", "zhihé")
  let place_id = test_id("place", "knowledge-lab-01")
  let portal_id = test_id("portal", "knowledge-lab-01-20-0")
  let other_place_id = test_id("place", "social-square")
  let source = provenance("moontown-ambient-resident", "v1", Derived, Bounded)
  let presence = actor_presence(
    actor_id,
    place_id,
    Some(portal_id),
    None,
    Inside,
    "核对证据边界",
    10,
    Some(18),
    source,
    activity_kind=ActorReview,
  )
  let profile = actor_profile(
    actor_id,
    "知河",
    "知识守护",
    "keeper",
    1,
    0,
    AmbientSimulation,
    ActorStateActive,
    source,
  )
  let exchange = place_exchange(
    test_id("exchange", "zhihé-knowledge-to-square"),
    place_id,
    other_place_id,
    Some(actor_id),
    Knowledge,
    "带一张证据卡去广场",
    720,
    9,
    Some(20),
    source,
  )
  let snapshot = town_snapshot(
    world,
    12,
    [],
    [],
    actor_profiles=[profile],
    actor_presences=[presence],
    place_exchanges=[exchange],
  )
  assert_eq(snapshot.find_actor_profile(actor_id), Some(profile))
  assert_eq(presence.activity_kind, ActorReview)
  assert_eq(snapshot.active_presences().length(), 1)
  assert_eq(snapshot.presences_at(place_id).length(), 1)
  assert_eq(snapshot.active_exchanges().length(), 1)
  assert_eq(snapshot.exchanges_for(place_id).length(), 1)
  assert_eq(snapshot.exchanges_for(other_place_id).length(), 1)
  let later = town_snapshot(world, 22, [], [], actor_presences=[presence], place_exchanges=[
    exchange,
  ])
  assert_true(later.active_presences().is_empty())
  assert_true(later.active_exchanges().is_empty())
}

///|
test "snapshot validation rejects malformed actor descriptors" {
  let world = test_world()
  let actor_id = test_id("resident", "missing-theme")
  let source = provenance("ambient", "v1", Derived, Bounded)
  let malformed = actor_profile(
    actor_id,
    "",
    "",
    "",
    -1,
    -1,
    RuntimeEvidence,
    ActorStateIdle,
    source,
  )
  let issues = validate_snapshot(
    town_snapshot(world, 1, [], [], actor_profiles=[malformed]),
  )
  assert_true(issues.any(issue => issue.code == InvalidActorProfile))
}

///|
test "snapshot validation rejects route metadata that disagrees with RoadNetwork" {
  let world = test_world()
  let source = provenance("runtime", "v1", RuntimeProjection, Free)
  let actor_id = test_id("runtime-agent", "misrouted")
  let presence = actor_presence(
    actor_id,
    test_id("place", "knowledge-lab-01"),
    Some(test_id("portal", "knowledge-lab-01-20-0")),
    None,
    Approaching,
    "walk",
    1,
    Some(10),
    source,
    route_position=Some(
      actor_route_position(
        world_point(5.0, 0.0),
        500,
        road_segment_id=Some(test_id("road-segment", "0-0--10-0")),
        origin_node_id=Some(test_id("road-node", "0-0")),
        destination_node_id=Some(test_id("road-node", "20-0")),
        heading_degrees=Some(0.0),
      ),
    ),
    activity_kind=ActorWalk,
  )
  let issues = validate_snapshot(
    town_snapshot(world, 2, [], [], actor_presences=[presence]),
  )
  assert_true(issues.any(issue => issue.code == InvalidActorRoutePosition))
}

///|
test "presence rendering resolves portals outside and slots inside" {
  let world = test_world()
  let actor_id = test_id("resident", "threshold-test")
  let place_id = test_id("place", "knowledge-lab-01")
  let portal_id = test_id("portal", "knowledge-lab-01-20-0")
  let slot_id = test_id("slot", "knowledge-lab-01-exchange")
  let source = provenance("ambient", "v1", Derived, Bounded)
  let at_entrance = actor_presence(
    actor_id,
    place_id,
    Some(portal_id),
    Some(slot_id),
    AtEntrance,
    "arrive",
    1,
    Some(4),
    source,
  )
  let inside = { ..at_entrance, phase: Inside }
  assert_eq(
    at_entrance.render_position(world),
    Some(
      world.find_place(place_id).unwrap().primary_entrance().unwrap().position,
    ),
  )
  assert_eq(
    inside.render_position(world),
    Some(world.find_interaction_slot(slot_id).unwrap().position),
  )
}

///|
test "snapshot validation rejects dangling ecosystem activity" {
  let world = test_world()
  let source = provenance("test-activity", "v1", Derived, Bounded)
  let missing_place = test_id("place", "missing")
  let actor = test_id("resident", "wanderer")
  let invalid_presence = actor_presence(
    actor,
    missing_place,
    None,
    None,
    Inside,
    "lost",
    1,
    Some(4),
    source,
  )
  let valid_place = test_id("place", "knowledge-lab-01")
  let invalid_exchange = place_exchange(
    test_id("exchange", "missing-endpoint"),
    valid_place,
    missing_place,
    Some(actor),
    Social,
    "cannot resolve",
    1200,
    1,
    Some(1),
    source,
  )
  let issues = validate_snapshot(
    town_snapshot(world, 2, [], [], actor_presences=[invalid_presence], place_exchanges=[
      invalid_exchange,
    ]),
  )
  assert_true(issues.any(issue => issue.code == MissingPresencePlace))
  assert_true(issues.any(issue => issue.code == MissingExchangePlace))
  assert_true(issues.any(issue => issue.code == InvalidExchangeRange))
  assert_true(issues.any(issue => issue.code == InvalidExchangeLifetime))
}

///|
test "world validation rejects spatial ownership contradictions" {
  let base = test_world()
  let parcel_id = test_id("parcel", "energy-core-01")
  let block_id = test_id("land-block", "energy-core")
  let invalid_parcel = parcel(
    parcel_id,
    block_id,
    test_polygon(35.0, 35.0, 10.0),
    Residential,
    [test_id("road-segment", "0-0--10-0")],
    ["street-homes"],
    Bounded,
    test_provenance(),
  )
  let invalid_world = compiled_town_world(
    base.schema_version,
    base.blueprint_id,
    base.blueprint_digest,
    base.layout_seed,
    base.bounds,
    base.terrain_regions,
    base.road_network,
    base.land_blocks,
    [invalid_parcel],
    base.places,
    base.attention_targets,
  )
  let issues = validate_world(invalid_world)
  assert_true(issues.any(issue => issue.code == ParcelOutsideLandBlock))
  assert_true(issues.any(issue => issue.code == ParcelLandUseMismatch))
  assert_true(issues.any(issue => issue.code == PlaceOutsideParcel))
}

///|
test "snapshot validation enforces one active place per actor" {
  let world = test_world()
  let actor_id = test_id("resident", "double-booked")
  let place_id = test_id("place", "knowledge-lab-01")
  let source = provenance("test-activity", "v1", Derived, Bounded)
  let first = actor_presence(
    actor_id,
    place_id,
    None,
    None,
    Inside,
    "first claim",
    1,
    Some(10),
    source,
  )
  let second = actor_presence(
    actor_id,
    place_id,
    None,
    None,
    Approaching,
    "second claim",
    2,
    Some(9),
    source,
  )
  let expired = actor_presence(
    actor_id,
    place_id,
    None,
    None,
    Departing,
    "old claim",
    0,
    Some(2),
    source,
  )
  let issues = validate_snapshot(
    town_snapshot(world, 5, [], [], actor_presences=[first, second, expired]),
  )
  assert_eq(
    issues.filter(issue => issue.code == DuplicateActivePresence).length(),
    1,
  )
}

///|
test "snapshot validation enforces active inside slot capacity" {
  let world = test_world()
  let place_id = test_id("place", "knowledge-lab-01")
  let slot_id = test_id("slot", "knowledge-lab-01-exchange")
  let source = provenance("test-activity", "v1", Derived, Bounded)
  let presences : Array[ActorPresence] = []
  for index in 0..<5 {
    presences.push(
      actor_presence(
        test_id("resident", "capacity-\{index}"),
        place_id,
        None,
        Some(slot_id),
        Inside,
        "using exchange desk",
        1,
        Some(10),
        source,
      ),
    )
  }
  let issues = validate_snapshot(
    town_snapshot(world, 5, [], [], actor_presences=presences),
  )
  assert_true(
    issues.any(issue => issue.code == InteractionSlotCapacityExceeded),
  )
}
