///|
test "legacy Wenyu snapshot compiles into the renderer-neutral contract" {
  let model = init_model()
  let world = ecosystem_contract_world_for_model(model, 20260727)
  assert_false(ecosystem_contract_world_validation_failed(model, 20260727))
  assert_true(world.places.length() > 50)
  assert_true(world.road_network.nodes.length() > 1000)
  assert_true(world.road_network.segments.length() > 1000)
  assert_eq(world.schema_version, "moontown.energy-valley.compiled.v2")
  assert_true(world.land_blocks.length() > 10)
  assert_true(world.terrain_regions.length() > 0)
  assert_true(world.parcels.length() >= world.land_blocks.length())
  assert_true(world.parcel_programs.length() > 5)
  assert_eq(world.parcel_program_assignments.length(), world.parcels.length())
  assert_true(world.places.any(place => place.parcel_id is Some(_)))
  for place in world.places {
    match place.parcel_id {
      None => ()
      Some(parcel_id) => {
        let program = world.parcel_program_for(parcel_id).unwrap()
        assert_eq(place.program_id, Some(program.id))
        assert_true(
          place.traits.any(place_trait => {
            place_trait ==
            @energy_valley_contract.Signature(program.id.local_key())
          }),
        )
      }
    }
  }
  assert_eq(world.attention_targets.length(), world.places.length())
  assert_true(world.road_network.access_anchor_node_ids.length() > 0)
  assert_true(
    world.road_network.access_anchor_node_ids.length() * 20 <
    world.road_network.nodes.length(),
  )
  let world_issues = @energy_valley_contract.validate_world(world)
  assert_false(@energy_valley_contract.has_errors(world_issues))
}

///|
test "building profiles preserve authored style and floor traits" {
  let model = init_model()
  let source = ecosystem_cached_world_snapshot(model, 20260727)
  let world = ecosystem_contract_world_for_model(model, 20260727)
  let mut checked = 0
  for source_place in source.places {
    if source_place.kind != EcosystemCivicBuilding &&
      source_place.kind != EcosystemAmbientBuilding &&
      source_place.kind != EcosystemCustomBuilding {
      continue
    }
    let place = world
      .find_place(ecosystem_contract_id(source_place.id))
      .unwrap()
    let profile = place.building.unwrap()
    assert_eq(profile.archetype, source_place.style)
    assert_eq(profile.floors, ecosystem_contract_building_floors(source_place))
    checked += 1
  }
  assert_true(checked > 0)
}

///|
test "validation fallback is an empty valid semantic world" {
  let model = init_model()
  let snapshot = ecosystem_cached_world_snapshot(model, 20260727)
  let fallback = ecosystem_contract_safe_empty_world(snapshot, 20260727)
  assert_true(fallback.places.is_empty())
  assert_true(fallback.road_network.nodes.is_empty())
  assert_false(
    @energy_valley_contract.has_errors(
      @energy_valley_contract.validate_world(fallback),
    ),
  )
}

///|
test "blueprint digest changes when spatial facts move without count changes" {
  let model = init_model()
  let snapshot = ecosystem_cached_world_snapshot(model, 20260727)
  let world = ecosystem_contract_world_for_model(model, 20260727)
  let plan : @energy_valley_contract.ParcelPlan = {
    compiler_version: "wenyu-parcel-adapter.v1",
    layout_seed: world.layout_seed,
    land_blocks: world.land_blocks,
    parcels: world.parcels,
    programs: world.parcel_programs,
    assignments: world.parcel_program_assignments,
  }
  let moved_roads = snapshot.roads.copy()
  moved_roads[0] = { ..moved_roads[0], x: moved_roads[0].x + 1 }
  let moved = { ..snapshot, roads: moved_roads }
  assert_eq(moved.roads.length(), snapshot.roads.length())
  assert_eq(moved.places.length(), snapshot.places.length())
  assert_true(
    ecosystem_contract_blueprint_digest(snapshot, plan) !=
    ecosystem_contract_blueprint_digest(moved, plan),
  )
}

///|
test "contract portals reach roads through typed pedestrian spurs without teleporting" {
  let model = init_model()
  let bridge = ecosystem_cached_world_snapshot(model, 20260727)
  let world = ecosystem_contract_world_for_model(model, 20260727)
  let segment_lookup : Map[
    @energy_valley_contract.StableId,
    @energy_valley_contract.RoadSegment,
  ] = Map([])
  for segment in world.road_network.segments {
    segment_lookup[segment.id] = segment
  }
  let mut direct_count = 0
  let mut spur_count = 0
  let mut reachability_checked = false
  for source in bridge.places {
    if source.kind != EcosystemCivicBuilding &&
      source.kind != EcosystemAmbientBuilding &&
      source.kind != EcosystemCustomBuilding {
      continue
    }
    let entrance = bridge.entrances.filter(item => {
        item.place_id == source.id && item.primary
      })[0]
    let frontage = bridge.road_frontages.filter(item => {
        item.entrance_id == entrance.id
      })[0]
    let place = world.find_place(ecosystem_contract_id(source.id)).unwrap()
    let portal = place.primary_entrance().unwrap()
    let portal_node_id = portal.road_node_id.unwrap()
    let shared_road_node_id = ecosystem_contract_id(frontage.road_cell_id)
    if frontage.direct {
      direct_count += 1
      assert_eq(portal_node_id, shared_road_node_id)
    } else {
      spur_count += 1
      let spur = ecosystem_pedestrian_spur_for_entrance(bridge, entrance.id).unwrap()
      assert_eq(portal_node_id, ecosystem_contract_spur_node_id(spur, 0))
      for index in 0..<(spur.path.length() - 1) {
        let segment_id = ecosystem_contract_scoped_id(
          "pedestrian-segment",
          "\{spur.id}-\{index}",
        )
        let segment = segment_lookup[segment_id]
        assert_eq(segment.road_class, @energy_valley_contract.Footpath)
        assert_eq(
          segment.from_node_id,
          ecosystem_contract_spur_node_id(spur, index),
        )
        assert_eq(
          segment.to_node_id,
          if index + 1 == spur.path.length() - 1 {
            shared_road_node_id
          } else {
            ecosystem_contract_spur_node_id(spur, index + 1)
          },
        )
      }
      if !reachability_checked {
        assert_true(
          world.road_network.is_reachable(
            portal_node_id,
            shared_road_node_id,
            mode=@energy_valley_contract.Pedestrian,
          ),
        )
        reachability_checked = true
      }
    }
  }
  assert_true(direct_count > 0)
  assert_true(spur_count > 0)
  assert_true(reachability_checked)
}

///|
test "contract town snapshot carries named resident focus and attention" {
  let model = { ..init_model(), tick: 18 }
  let snapshot = ecosystem_contract_town_snapshot(model, 20260727)
  assert_true(snapshot.attention_signals.length() > 0)
  assert_eq(snapshot.attention_focuses.length(), 12)
  assert_eq(snapshot.actor_presences.length(), 12)
  assert_true(snapshot.place_exchanges.length() > 0)
  for presence in snapshot.actor_presences {
    assert_true(snapshot.world.find_place(presence.place_id) is Some(_))
    match presence.portal_id {
      Some(portal_id) =>
        assert_true(
          snapshot.world.places.any(place => {
            place.entrances.any(portal => portal.id == portal_id)
          }),
        )
      None => ()
    }
  }
  let snapshot_issues = @energy_valley_contract.validate_snapshot(snapshot)
  assert_false(@energy_valley_contract.has_errors(snapshot_issues))
  assert_false(ecosystem_contract_snapshot_validation_failed(model, 20260727))
}

///|
test "ambient semantic ledger remains valid at the opening transition" {
  let model = { ..init_model(), tick: 8 }
  let _ = ecosystem_contract_town_snapshot(model, 20260727)
  assert_false(ecosystem_contract_snapshot_validation_failed(model, 20260727))
}

///|
test "invalid dynamic ledger fails closed without discarding its world" {
  let model = { ..init_model(), tick: 18 }
  let valid = ecosystem_contract_town_snapshot(model, 20260727)
  let presence = valid.actor_presences[0]
  let malformed = @energy_valley_contract.town_snapshot(
    valid.world,
    valid.tick,
    valid.attention_signals,
    valid.attention_focuses,
    actor_presences=[presence, presence],
    place_exchanges=valid.place_exchanges,
  )
  let (safe, invalid) = ecosystem_contract_validated_snapshot(
    malformed, "invalid-ledger-test",
  )
  assert_true(invalid)
  assert_eq(safe.world.blueprint_digest, valid.world.blueprint_digest)
  assert_true(safe.actor_presences.is_empty())
  assert_true(safe.place_exchanges.is_empty())
  assert_false(
    @energy_valley_contract.has_errors(
      @energy_valley_contract.validate_snapshot(safe),
    ),
  )
}

///|
test "live runtime work joins the same semantic presence ledger" {
  let model = runtime_map_routing_live_model()
  let snapshot = ecosystem_contract_town_snapshot(model, 20260727)
  assert_false(ecosystem_contract_snapshot_validation_failed(model, 20260727))
  assert_true(
    snapshot.actor_presences.any(presence => {
      presence.provenance.kind == @energy_valley_contract.RuntimeProjection
    }),
  )
  assert_true(
    snapshot.actor_presences.any(presence => {
      presence.provenance.kind == @energy_valley_contract.Derived
    }),
  )
  let runtime_presence = snapshot.actor_presences.filter(presence => {
      presence.provenance.kind == @energy_valley_contract.RuntimeProjection
    })[0]
  assert_eq(runtime_presence.phase, @energy_valley_contract.Approaching)
  assert_eq(runtime_presence.interaction_slot_id, None)
  assert_eq(runtime_presence.since_tick, 41)
  let later = ecosystem_contract_town_snapshot({ ..model, tick: 81 }, 20260727)
  let later_runtime_presence = later.actor_presences.filter(presence => {
      presence.provenance.kind == @energy_valley_contract.RuntimeProjection
    })[0]
  assert_eq(later_runtime_presence.since_tick, runtime_presence.since_tick)
}

///|
test "repeated runtime transport records compile to one semantic identity" {
  let base = runtime_map_routing_live_model()
  let projection = base.energy_valley_runtime.projection.unwrap()
  let model = {
    ..base,
    energy_valley_runtime: {
      ..base.energy_valley_runtime,
      projection: Some({
        ..projection,
        agents: projection.agents + [projection.agents[0], projection.agents[0]],
      }),
    },
  }
  assert_true(ecosystem_runtime_attention_signals(model, "").length() > 1)
  let snapshot = ecosystem_contract_town_snapshot(model, 20260727)
  assert_false(ecosystem_contract_snapshot_validation_failed(model, 20260727))
  assert_false(
    @energy_valley_contract.has_errors(
      @energy_valley_contract.validate_snapshot(snapshot),
    ),
  )
  assert_eq(
    snapshot.actor_presences
    .filter(presence => {
      presence.provenance.kind == @energy_valley_contract.RuntimeProjection
    })
    .length(),
    1,
  )
  let runtime_signal_ids : Map[@energy_valley_contract.StableId, Bool] = Map([])
  for signal in snapshot.attention_signals {
    if signal.source_id ==
      Some(
        ecosystem_contract_scoped_id(
          "subject",
          "runtime:\{projection.agents[0].id}",
        ),
      ) {
      assert_false(runtime_signal_ids.contains(signal.id))
      runtime_signal_ids[signal.id] = true
    }
  }
  assert_eq(runtime_signal_ids.size(), 1)
}

///|
fn ecosystem_contract_access_test_place() -> EcosystemPlace {
  {
    id: "place/access-test",
    source_id: "access-test",
    name: "Access test",
    kind: EcosystemAmbientBuilding,
    district: "test",
    style: "block",
    footprint: { x: 10, y: 10, width: 3, depth: 3 },
    anchor: ecosystem_point(11, 11),
    traits: [],
    attention: { visual: 0, social: 0, activity: 0, urgency: 0, novelty: 0 },
    runtime: { runtime_key: None },
  }
}

///|
fn ecosystem_contract_access_test_snapshot(
  place : EcosystemPlace,
) -> EcosystemWorldSnapshot {
  let isolated_entrance : EcosystemEntrance = {
    id: "portal/access-test-isolated",
    place_id: place.id,
    label: "main",
    threshold: ecosystem_point(10, 11),
    access_point: ecosystem_point(9, 11),
    direction: "west",
    portal_kind: "building-door",
    primary: true,
    accessible: true,
  }
  let reachable_entrance : EcosystemEntrance = {
    id: "portal/access-test-reachable",
    place_id: place.id,
    label: "secondary",
    threshold: ecosystem_point(13, 11),
    access_point: ecosystem_point(14, 11),
    direction: "east",
    portal_kind: "building-door",
    primary: false,
    accessible: true,
  }
  {
    schema: "access-test.v1",
    seed: 1,
    cols: 24,
    rows: 24,
    places: [place],
    entrances: [isolated_entrance, reachable_entrance],
    road_frontages: [
      {
        id: isolated_entrance.id,
        place_id: place.id,
        entrance_id: isolated_entrance.id,
        road_cell_id: "road-node/isolated",
        road_class: "local",
        road_mask: 0,
        distance: 1,
        direct: true,
      },
      {
        id: reachable_entrance.id,
        place_id: place.id,
        entrance_id: reachable_entrance.id,
        road_cell_id: "road-node/reachable",
        road_class: "local",
        road_mask: 0,
        distance: 1,
        direct: true,
      },
    ],
    pedestrian_spurs: [],
    roads: [],
    road_network: @energy_valley_contract.road_network([], [], []),
    affordances: [
      {
        id: "affordance/access-test-inspect",
        kind: EcosystemInspect,
        place_id: Some(place.id),
        anchor: place.anchor,
        capacity: 1,
        attention_weight: 10,
        enabled: true,
        evidence: "semantic-place",
      },
      {
        id: "affordance/access-test-work",
        kind: EcosystemWork,
        place_id: Some(place.id),
        anchor: place.anchor,
        capacity: 4,
        attention_weight: 40,
        enabled: true,
        evidence: "place-program",
      },
      {
        id: "affordance/access-test-exchange",
        kind: EcosystemExchange,
        place_id: Some(place.id),
        anchor: place.anchor,
        capacity: 4,
        attention_weight: 40,
        enabled: true,
        evidence: "place-program",
      },
    ],
  }
}

///|
test "reachable secondary entrance is promoted when authored primary is sealed" {
  let place = ecosystem_contract_access_test_place()
  let snapshot = ecosystem_contract_access_test_snapshot(place)
  let connected : Map[@energy_valley_contract.StableId, Bool] = Map([])
  connected[ecosystem_contract_id("road-node/reachable")] = true
  let portals = ecosystem_contract_portals(snapshot, place, connected)
  assert_eq(portals.length(), 2)
  assert_eq(portals.filter(portal => portal.primary).length(), 1)
  assert_eq(portals[0].road_node_id, None)
  assert_false(portals[0].primary)
  assert_eq(
    portals[1].road_node_id,
    Some(ecosystem_contract_id("road-node/reachable")),
  )
  assert_true(portals[1].primary)

  let sealed_portals = ecosystem_contract_portals(snapshot, place, Map([]))
  assert_eq(sealed_portals.filter(portal => portal.primary).length(), 1)
  assert_true(sealed_portals[0].primary)
  assert_true(sealed_portals.all(portal => portal.road_node_id is None))
}

///|
test "sealed building keeps inspection but drops indoor compatibility slots" {
  let place = ecosystem_contract_access_test_place()
  let snapshot = ecosystem_contract_access_test_snapshot(place)
  let sealed_slots = ecosystem_contract_slots(snapshot, place, false)
  assert_eq(sealed_slots.length(), 1)
  assert_true(sealed_slots[0].kind is @energy_valley_contract.ServicePoint)
  let accessible_slots = ecosystem_contract_slots(snapshot, place, true)
  assert_eq(accessible_slots.length(), 3)
}
