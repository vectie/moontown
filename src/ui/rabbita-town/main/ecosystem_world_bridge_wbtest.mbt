///|
fn ecosystem_test_runtime_agent(
  building_key : String,
) -> EnergyValleyRuntimeAgent {
  {
    id: "ecosystem-agent",
    name: "Evidence Scout",
    role: "worker",
    avatarRef: None,
    status: "running",
    buildingModuleKey: Some(building_key),
    workItemId: Some("ecosystem-work"),
    runId: Some("ecosystem-run"),
    bookId: None,
    activityKind: Some("researching"),
    activityLabel: Some("Checking evidence"),
    originBuildingModuleKey: Some("town-shell"),
    destinationBuildingModuleKey: Some(building_key),
  }
}

///|
fn ecosystem_test_live_runtime(
  building_key : String,
) -> EnergyValleyRuntimeState {
  let agent = ecosystem_test_runtime_agent(building_key)
  let projection : EnergyValleyRuntimeProjection = {
    schema: energy_valley_runtime_schema(),
    mode: "live",
    observedAt: "2026-08-07T12:00:00.000Z",
    knowledgeCatalogDigest: None,
    tick: Some(1),
    tasks: [],
    history: None,
    agents: [agent],
    message: None,
  }
  {
    phase: Live,
    projection: Some(projection),
    version: 1,
    fresh_at_ms: 1.0,
    presence_started_at_tick: 1,
    presence_clocks: [],
    error: "",
  }
}

///|
test "ecosystem snapshot is deterministic and preserves stable semantic identities" {
  let world = exact_energy_valley_generate_default()
  let first = ecosystem_world_snapshot(world, [], [], [])
  let second = ecosystem_world_snapshot(world, [], [], [])
  assert_eq(first, second)
  assert_eq(first.schema, ecosystem_world_schema())
  assert_true(first.roads.length() > 100)
  assert_true(
    first.places.any(place => {
      place.id == "place/civic-town-shell" &&
      place.kind == EcosystemCivicBuilding
    }),
  )
  assert_true(first.places.any(place => place.kind == EcosystemAmbientBuilding))
  assert_eq(
    first.places.filter(place => place.kind == EcosystemMetroStation).length(),
    2,
  )
}

///|
test "semantic building entrances link to the exact typed road cells" {
  let snapshot = ecosystem_world_snapshot(
    exact_energy_valley_generate_default(),
    [],
    [],
    [],
  )
  let buildings = snapshot.places.filter(place => {
    place.kind == EcosystemCivicBuilding ||
    place.kind == EcosystemAmbientBuilding
  })
  assert_true(!buildings.is_empty())
  for place in buildings {
    let frontages = ecosystem_frontages_for_place(snapshot, place.id)
    assert_true(!frontages.is_empty())
    for frontage in frontages {
      assert_true(snapshot.roads.any(road => road.id == frontage.road_cell_id))
      let graph_node = snapshot.road_network
        .find_node(ecosystem_contract_id(frontage.road_cell_id))
        .unwrap()
      let entrance = snapshot.entrances.filter(entrance => {
          entrance.id == frontage.entrance_id && entrance.place_id == place.id
        })[0]
      assert_eq(graph_node.grid.column, entrance.access_point.x)
      assert_eq(graph_node.grid.row, entrance.access_point.y)
      assert_true(frontage.distance >= 1)
    }
    assert_true(
      ecosystem_affordances_for_place(snapshot, place.id).any(affordance => {
        affordance.kind == EcosystemEnter && affordance.enabled
      }),
    )
  }
}

///|
test "every accepted entrance frontage and spur endpoint belongs to the precompiled road graph" {
  let snapshot = ecosystem_world_snapshot(
    exact_energy_valley_generate_default(),
    [],
    [],
    [],
  )
  assert_true(!snapshot.road_frontages.is_empty())
  for entrance in snapshot.entrances {
    if entrance.accessible {
      let frontages = snapshot.road_frontages.filter(frontage => {
        frontage.entrance_id == entrance.id
      })
      assert_eq(frontages.length(), 1)
      let node = snapshot.road_network
        .find_node(ecosystem_contract_id(frontages[0].road_cell_id))
        .unwrap()
      assert_eq(node.grid.column, entrance.access_point.x)
      assert_eq(node.grid.row, entrance.access_point.y)
    }
  }
  for frontage in snapshot.road_frontages {
    let entrance = snapshot.entrances.filter(entrance => {
        entrance.id == frontage.entrance_id
      })[0]
    let node = snapshot.road_network
      .find_node(ecosystem_contract_id(frontage.road_cell_id))
      .unwrap()
    assert_eq(node.grid.column, entrance.access_point.x)
    assert_eq(node.grid.row, entrance.access_point.y)
  }
  for spur in snapshot.pedestrian_spurs {
    let node = snapshot.road_network
      .find_node(ecosystem_contract_id(spur.road_cell_id))
      .unwrap()
    let endpoint = spur.path[spur.path.length() - 1]
    assert_eq(node.grid.column, endpoint.x)
    assert_eq(node.grid.row, endpoint.y)
    let entrance = snapshot.entrances.filter(entrance => {
        entrance.id == spur.entrance_id
      })[0]
    assert_eq(endpoint, entrance.access_point)
  }
}

///|
test "entrance discovery never promotes exact terrain roads outside the authoritative graph" {
  let world = exact_energy_valley_generate_default()
  let snapshot = ecosystem_world_snapshot(world, [], [], [])
  let road_nodes = ecosystem_road_network_node_lookup(snapshot.road_network)
  let directly_served = snapshot.places.filter(place => {
    ecosystem_direct_frontage_candidates(road_nodes, place.footprint).length() >
    0
  })
  assert_true(!directly_served.is_empty())
  let footprint = directly_served[0].footprint
  let empty_network = @energy_valley_contract.road_network([], [], [])
  let empty_nodes = ecosystem_road_network_node_lookup(empty_network)
  assert_true(
    ecosystem_direct_frontage_candidates(empty_nodes, footprint).is_empty(),
  )
  let access = ecosystem_building_access(
    world,
    empty_network,
    empty_nodes,
    [],
    [],
    [],
    "place/test-no-road-graph",
    footprint,
    None,
  )
  assert_true(access.0.is_empty())
  assert_true(access.1.is_empty())
  assert_true(access.2.is_empty())
}

///|
test "indirect building frontages compile short cardinal pedestrian spurs" {
  let world = exact_energy_valley_generate_default()
  let snapshot = ecosystem_world_snapshot(world, [], [], [])
  let buildings = snapshot.places.filter(place => {
    place.kind == EcosystemCivicBuilding ||
    place.kind == EcosystemAmbientBuilding ||
    place.kind == EcosystemCustomBuilding
  })
  let road_nodes = ecosystem_road_network_node_lookup(snapshot.road_network)
  let mut indirect_primary_count = 0
  for place in buildings {
    let primary = snapshot.entrances.filter(entrance => {
      entrance.place_id == place.id && entrance.primary
    })
    assert_eq(primary.length(), 1)
    let frontage = snapshot.road_frontages.filter(link => {
      link.entrance_id == primary[0].id
    })
    assert_eq(frontage.length(), 1)
    match ecosystem_pedestrian_spur_for_entrance(snapshot, primary[0].id) {
      None => assert_true(frontage[0].direct)
      Some(spur) => {
        indirect_primary_count += 1
        assert_false(frontage[0].direct)
        assert_eq(spur.place_id, place.id)
        assert_eq(spur.road_cell_id, frontage[0].road_cell_id)
        assert_eq(spur.path[0], primary[0].threshold)
        assert_eq(spur.path[spur.path.length() - 1], primary[0].access_point)
        assert_eq(spur.distance, spur.path.length() - 1)
        assert_eq(spur.distance, frontage[0].distance)
        for index in 0..<(spur.path.length() - 1) {
          let from = spur.path[index]
          let to = spur.path[index + 1]
          assert_eq(
            ecosystem_int_abs(to.x - from.x) + ecosystem_int_abs(to.y - from.y),
            1,
          )
        }
        for index in 1..<spur.path.length() {
          let cell = spur.path[index]
          assert_true(
            ecosystem_spur_cell_can_cross(
              world,
              road_nodes,
              [],
              [],
              [],
              place.footprint,
              cell.x,
              cell.y,
            ),
          )
        }
      }
    }
  }
  assert_true(indirect_primary_count > 0)
  for spur in snapshot.pedestrian_spurs {
    assert_true(snapshot.roads.any(road => road.id == spur.road_cell_id))
  }
}

///|
test "player deltas join the same place entrance and road contracts" {
  let world = exact_energy_valley_generate_default()
  let building : GoldenValleyBuilding = {
    authored_id: None,
    module_key: None,
    name: "测试实验室",
    style: "custom-lab",
    x: 20,
    y: 20,
    width: 6,
    depth: 6,
    entrance_x: None,
    entrance_y: None,
    floors: 2,
  }
  let snapshot = ecosystem_world_snapshot(
    world,
    [building],
    [golden_valley_tile_key(20, 26)],
    [],
  )
  let id = ecosystem_custom_place_id(building)
  let place = ecosystem_place_by_id(snapshot, id).unwrap()
  assert_eq(place.kind, EcosystemCustomBuilding)
  assert_true(
    place.traits.any(item => {
      item.key == "source" && item.value == "player-delta"
    }),
  )
  assert_true(
    ecosystem_frontages_for_place(snapshot, id).any(frontage => {
      frontage.road_cell_id == ecosystem_road_cell_id(20, 26) && frontage.direct
    }),
  )
  assert_true(
    snapshot.road_network.find_node(
      ecosystem_contract_id(ecosystem_road_cell_id(20, 26)),
    )
    is Some(_),
  )
  assert_true(
    ecosystem_affordances_for_place(snapshot, id).any(affordance => {
      affordance.kind == EcosystemPublish
    }),
  )
}

///|
test "runtime projection never mutates compatibility place facts" {
  let base = init_model()
  let live = {
    ..base,
    energy_valley_runtime: ecosystem_test_live_runtime("policy-hall"),
  }
  let stale = {
    ..live,
    energy_valley_runtime: { ..live.energy_valley_runtime, phase: Stale },
  }
  let live_snapshot = ecosystem_world_snapshot_for_model(live, 20260727)
  let stale_snapshot = ecosystem_world_snapshot_for_model(stale, 20260727)
  assert_eq(live_snapshot, stale_snapshot)
  let policy = ecosystem_place_by_id(live_snapshot, "place/civic-policy-hall").unwrap()
  assert_eq(policy.runtime.runtime_key, Some("policy-hall"))
  assert_false(
    policy.traits.any(item => {
      item.key == "runtime" ||
      item.key == "recorded-work" ||
      item.key == "known-residents"
    }),
  )
  assert_eq(policy.attention.activity, 48)
  assert_eq(
    ecosystem_affordances_for_place(live_snapshot, policy.id).filter(item => {
      item.kind == EcosystemWork
    })[0].evidence,
    "place-program",
  )
}

///|
test "metro and public realm details expose typed interactions" {
  let snapshot = ecosystem_world_snapshot(
    exact_energy_valley_generate_default(),
    [],
    [],
    [],
  )
  let metro = ecosystem_place_by_id(
    snapshot, "place/metro-line17-future-science-city",
  ).unwrap()
  assert_eq(
    snapshot.entrances
    .filter(entrance => {
      entrance.place_id == metro.id && entrance.portal_kind == "metro-exit"
    })
    .length(),
    2,
  )
  assert_true(
    ecosystem_affordances_for_place(snapshot, metro.id).any(affordance => {
      affordance.kind == EcosystemTravel
    }),
  )
  assert_true(
    snapshot.affordances.any(affordance => {
      affordance.evidence == "wenyu-water-edge" &&
      affordance.kind == EcosystemObserve
    }),
  )
  assert_true(snapshot.roads.any(road => road.streetlight || road.street_tree))
}
