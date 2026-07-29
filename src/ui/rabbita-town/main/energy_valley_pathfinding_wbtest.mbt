///|
test "Energy Valley runtime routes remain on roads and bridges" {
  let model = init_model()
  let buildings = golden_valley_buildings(20260727)
  let path = golden_valley_building_road_path(
    model,
    20260727,
    buildings[0],
    buildings[3],
  ).unwrap()
  assert_true(path.length() > 1)
  for point in path {
    assert_true(
      golden_valley_walkable(
        model,
        20260727,
        point.0.floor().to_int(),
        point.1.floor().to_int(),
      ),
    )
  }
}

///|
test "Energy Valley nearest road follows reference perimeter order" {
  let model = init_model()
  let hall = golden_valley_buildings(20260727)[0]
  let road = golden_valley_nearest_road(model, 20260727, hall).unwrap()
  assert_true(golden_valley_walkable(model, 20260727, road.0, road.1))
}

///|
test "every civic module is connected to the shared framework road graph" {
  let model = init_model()
  let buildings = golden_valley_buildings(20260727)
  let hub = buildings[0]
  for building in buildings {
    let entrance = golden_valley_nearest_road(model, 20260727, building).unwrap()
    assert_true(
      energy_valley_framework_road_at(20260727, entrance.0, entrance.1),
    )
    let path = golden_valley_building_road_path(model, 20260727, hub, building).unwrap()
    assert_true(!path.is_empty())
  }
}

///|
test "runtime route enters its destination instead of looping" {
  let path = [(0.5, 0.5), (1.5, 0.5), (2.5, 0.5)]
  assert_eq(golden_valley_path_point(path, 0.5), Some((1.0, 0.5)))
  assert_eq(golden_valley_path_point(path, 2.0), None)
  assert_eq(golden_valley_path_point(path, 20.0), None)
}

///|
test "commute motion alternates road travel with building dwell" {
  let path = [(0.5, 0.5), (1.5, 0.5), (2.5, 0.5)]
  assert_eq(
    golden_valley_commute_point(path, 0.5, 1.0, 0.0, 2.0),
    Some((1.0, 0.5)),
  )
  assert_eq(golden_valley_commute_point(path, 2.5, 1.0, 0.0, 2.0), None)
  assert_eq(
    golden_valley_commute_point(path, 4.5, 1.0, 0.0, 2.0),
    Some((2.0, 0.5)),
  )
}
