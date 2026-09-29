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
test "campus setback moves the door and footprint without rotating geographic axes" {
  town_landmarks_init()
  for
    (id, lon, lat, setback, west) in [
      ("center", 116.4701, 40.1147, 40.0, 20.0),
      ("vision", 116.4754, 40.1245, 55.0, 30.0),
    ] {
    let fitted = town_landmark_find(id).unwrap()
    let original = town_landmark_create(id, "", lon, lat, 134, 80, false)
    assert_eq(
      (fitted.east.x, fitted.east.y),
      (original.east.x, original.east.y),
    )
    assert_eq(
      (fitted.south.x, fitted.south.y),
      (original.south.x, original.south.y),
    )
    assert_true(
      (fitted.origin.x -
      original.origin.x +
      original.south.x * setback +
      original.east.x * west).abs() <
      0.000001,
    )
    assert_true(
      (fitted.origin.y -
      original.origin.y +
      original.south.y * setback +
      original.east.y * west).abs() <
      0.000001,
    )
    assert_true(
      (fitted.door.x - original.door.x - fitted.origin.x + original.origin.x).abs() <
      0.000001,
    )
    assert_true(
      (fitted.door.y - original.door.y - fitted.origin.y + original.origin.y).abs() <
      0.000001,
    )
    // Inner 263 × 151 m courtyard is covered by the legacy-lot reservation.
    assert_true(
      fitted.half_width > 263.0 / 2.0 && fitted.half_depth > 151.0 / 2.0,
    )
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
