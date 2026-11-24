///|
test "landmark campus and bridge registration preserves geographic axes" {
  town_landmarks_init()
  assert_eq(town_landmark_registry.length(), 4)
  for l in town_landmark_registry {
    assert_true(
      l.origin.x > 0 && l.origin.x < 256 && l.origin.y > 0 && l.origin.y < 144,
    )
    assert_true(l.east.x * l.south.y - l.east.y * l.south.x > 0)
    assert_true(l.elevation > 0 && l.elevation < 2)
  }
  let bridge = town_landmark_find("arch-bridge").unwrap()
  let a = town_bearing_geo_to_ground(116.4622087, 40.1215482)
  let b = town_bearing_geo_to_ground(116.4624858, 40.1241235)
  let cross = bridge.east.x * (b.y - a.y) - bridge.east.y * (b.x - a.x)
  assert_true(cross.abs() < 0.0001)
  assert_true(bridge.east.x * (b.x - a.x) + bridge.east.y * (b.y - a.y) > 0)
}

///|
test "Vision town origin shares the A21 imagery anchor with the regional model" {
  town_landmarks_init()
  let vision = town_landmark_find("vision").unwrap()
  let anchor = town_bearing_geo_to_ground(116.47495692, 40.12507434)
  assert_eq((vision.origin.x, vision.origin.y), (anchor.x, anchor.y))
  for (x, z) in [(-116.0, 28.0), (-44.0, -55.0), (57.0, -32.0), (75.0, 73.0)] {
    let point = town_landmark_at(vision, x, z)
    assert_true(town_landmark_reserved(point.x, point.y, 0))
  }
}

///|
test "enlarged bridge preserves main crossing axis and includes approach shoulders" {
  town_landmarks_init()
  let b = town_landmark_find("east-bridge").unwrap()
  let a = town_bearing_geo_to_ground(116.4685401, 40.1199473)
  let c = town_bearing_geo_to_ground(116.4713797, 40.1234322)
  let cross = b.east.x * (c.y - a.y) - b.east.y * (c.x - a.x)
  assert_true(cross.abs() < 0.0001)
  let baseline = town_landmark_create(
    "", "", 116.46990605, 40.1217185, 176, 18, false,
  )
  assert_true((b.elevation / baseline.elevation - 1.18).abs() < 0.000001)
  assert_eq(b.half_width, 204.0)
  assert_true(b.half_depth >= 18.0)
  assert_eq((b.door.x, b.door.y), (b.origin.x, b.origin.y))
}

///|
test "compound campus reserves its seven independent volumes and releases the old west block" {
  town_landmarks_init()
  assert_eq(town_landmark_volumes.length(), 10)
  for unit in future_center_buildings {
    assert_true(town_landmark_reserved(unit.origin.x, unit.origin.y, 0))
    assert_true(
      town_landmark_find(unit.id) is Some(found) &&
      found.component == unit.component,
    )
    assert_false(town_landmark_reserved(unit.door.x, unit.door.y, 0))
  }
  assert_false(town_landmark_reserved(197.59375, 101.15625, 0))
  let center = town_landmark_find("center").unwrap()
  assert_true(town_landmark_arrival({ nodes: [], edges: [], }, center) is None)
}
