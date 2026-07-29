///|
fn energy_valley_building_access_neighbor_count(
  world : ExactEnergyValleyWorld,
  x : Int,
  y : Int,
) -> Int {
  let mut count = 0
  for direction in [(0, -1), (1, 0), (0, 1), (-1, 0)] {
    match world.terrain_at(x + direction.0, y + direction.1) {
      Some("road") | Some("bridge") => count += 1
      _ => ()
    }
  }
  count
}

///|
test "every civic entrance has a visible spur into the shared road network" {
  let world = exact_energy_valley_generate_default()
  let model = init_model()
  let runtime_buildings = golden_valley_buildings(
    exact_energy_valley_default_seed().reinterpret_as_int(),
  )
  let hub = runtime_buildings[0]
  for index in 0..<world.buildings.length() {
    let building = world.buildings[index]
    match world.terrain_at(building.entrance_x, building.entrance_y) {
      Some("road") | Some("bridge") => ()
      _ => fail("civic entrance must be painted as transport")
    }
    assert_true(
      energy_valley_building_access_neighbor_count(
        world,
        building.entrance_x,
        building.entrance_y,
      ) >
      0,
    )
    let route = golden_valley_building_road_path(
      model,
      exact_energy_valley_default_seed().reinterpret_as_int(),
      hub,
      runtime_buildings[index],
    ).unwrap()
    assert_true(!route.is_empty())
  }
}
