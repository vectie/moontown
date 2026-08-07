///|
test "canvas road projection is exactly the accepted source road nodes" {
  let model = init_model()
  let snapshot = ecosystem_contract_town_snapshot(model, 20260727)
  let roads = town_snapshot_canvas_roads(snapshot)
  let source_count = snapshot.world.road_network.nodes
    .filter(node => node.id.scope() == "road-node")
    .length()
  assert_eq(roads.length(), source_count)
  for road in roads {
    assert_true(
      golden_valley_semantic_road_node_at(snapshot.world, road.x, road.y)
      is Some(_),
    )
  }
}

///|
test "canvas road masks require an authoritative segment not coordinate adjacency" {
  let snapshot = ecosystem_contract_town_snapshot(init_model(), 20260727)
  let provenance = snapshot.world.road_network.nodes[0].provenance
  let left_id = ecosystem_contract_scoped_id("road-node", "mask-test-left")
  let right_id = ecosystem_contract_scoped_id("road-node", "mask-test-right")
  let left = @energy_valley_contract.road_node(
    left_id,
    @energy_valley_contract.grid_position(10, 10),
    @energy_valley_contract.world_point(10.5, 10.5),
    provenance,
  )
  let right = @energy_valley_contract.road_node(
    right_id,
    @energy_valley_contract.grid_position(11, 10),
    @energy_valley_contract.world_point(11.5, 10.5),
    provenance,
  )
  let disconnected = {
    ..snapshot,
    world: {
      ..snapshot.world,
      road_network: @energy_valley_contract.road_network([left, right], [], []),
    },
  }
  let disconnected_roads = town_snapshot_canvas_roads(disconnected)
  assert_eq(disconnected_roads.length(), 2)
  assert_true(disconnected_roads.all(road => road.mask == 0))
  let segment = @energy_valley_contract.road_segment(
    ecosystem_contract_scoped_id("road-segment", "mask-test"),
    left_id,
    right_id,
    [
      @energy_valley_contract.world_point(10.5, 10.5),
      @energy_valley_contract.world_point(11.5, 10.5),
    ],
    @energy_valley_contract.Collector,
    12.0,
    [@energy_valley_contract.Pedestrian],
    provenance,
  )
  let connected = {
    ..snapshot,
    world: {
      ..snapshot.world,
      road_network: @energy_valley_contract.road_network(
        [left, right],
        [segment],
        [],
      ),
    },
  }
  let connected_roads = town_snapshot_canvas_roads(connected)
  let left_road = connected_roads.filter(road => road.node_id == left_id)[0]
  let right_road = connected_roads.filter(road => road.node_id == right_id)[0]
  assert_eq(left_road.mask, 2)
  assert_eq(right_road.mask, 8)
}

///|
test "canvas building projection comes only from semantic places" {
  let model = init_model()
  let snapshot = ecosystem_contract_town_snapshot(model, 20260727)
  let buildings = town_snapshot_canvas_buildings(snapshot)
  assert_true(!buildings.is_empty())
  for building in buildings {
    guard snapshot.world.find_place(building.place_id) is Some(place) else {
      fail("projected building must retain its Place identity")
    }
    assert_true(place.kind is @energy_valley_contract.Building)
    assert_true(place.building is Some(_))
    assert_true(building.width > 0 && building.depth > 0)
    assert_eq(
      town_snapshot_place_for_visual_building(snapshot, building.visual()).map(value => {
        value.id
      }),
      Some(building.place_id),
    )
  }
}
