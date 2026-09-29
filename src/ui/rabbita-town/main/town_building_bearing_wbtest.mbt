///|
test "geographic building frame reproduces the unshifted road calibration" {
  // Equal-longitude OSM road vertices from the retained source dataset.
  let p = town_bearing_geo_to_ground(116.4313664, 40.1222835)
  let q = town_bearing_geo_to_ground(116.4313664, 40.1220297)
  let gentle = fn(x : Double, y : Double) {
    let w = 1.0 + 0.01 * ((x - 256.0) / 256.0 - y / 144.0)
    WenyuScenePoint::{ x: 256.0 + (x - 256.0) / w, y: y / w, }
  }
  let expected = gentle(131.60115668811503, 64.1662752365329)
  assert_true((p.x - expected.x).abs() < 0.000001)
  assert_true((p.y - expected.y).abs() < 0.000001)
  let dx = 32.0 * (p.x - q.x - (p.y - q.y))
  let dy = 16.0 * (p.x - q.x + (p.y - q.y))
  let angle = @math.atan2(dx, -dy) * 180.0 / @math.PI
  assert_true((angle - 78.2658).abs() < 0.01)
  let b = town_bearing_at(p.x, p.y)
  let angle = @math.atan2(
      32.0 * (b.north.x - b.north.y),
      -16.0 * (b.north.x + b.north.y),
    ) *
    180.0 /
    @math.PI
  assert_true((angle - 78.2658).abs() < 0.02)
}

///|
test "building street adaptation is geographic bounded and direction independent" {
  let b = town_bearing_at(128, 72)
  let turned = town_bearing_turn(b, 7.0)
  assert_true(
    (town_bearing_street_deviation(b, turned.east.x, turned.east.y) - 7.0).abs() <
    0.00001,
  )
  assert_true(
    (town_bearing_street_deviation(b, -turned.east.x, -turned.east.y) - 7.0).abs() <
    0.00001,
  )
  let diagonal = town_bearing_turn(b, 28.0)
  assert_eq(
    town_bearing_street_deviation(b, diagonal.east.x, diagonal.east.y),
    0.0,
  )
}

///|
test "oriented building lots remain inside validated reservations across the town" {
  for x in [4, 64, 128, 192, 252] {
    for y in [4, 36, 72, 108, 140] {
      for deviation in [-10.0, 0.0, 10.0] {
        let b = town_bearing_turn(
          town_bearing_at(x.to_double(), y.to_double()),
          deviation,
        )
        let det = b.east.x * b.north.y - b.east.y * b.north.x
        assert_true(det < -0.1)
        for size in [2, 3, 4, 5] {
          let span = town_bearing_span(b, size, size)
          assert_true(span > 0.0)
          for u in [-0.5, 0.5] {
            for v in [-0.5, 0.5] {
              assert_true(
                ((b.east.x * u + b.north.x * v) * span).abs() <=
                size.to_double() / 2.0 + 0.000001,
              )
              assert_true(
                ((b.east.y * u + b.north.y * v) * span).abs() <=
                size.to_double() / 2.0 + 0.000001,
              )
            }
          }
        }
      }
    }
  }
}

///|
test "bearing prefabs contain complete finite quads for all architectural families" {
  let b = town_bearing_at(128, 72)
  for
    style in [
      "row", "lowrise", "tower", "block", "courtyard", "civic", "industrial", "campus",
    ] {
    let mesh = town_bearing_make_mesh(b, 3.0, style, 1)
    assert_true(mesh.colors.length() > 10)
    assert_eq(mesh.points.length(), mesh.colors.length() * 12)
    for n in mesh.points {
      assert_true(n.abs() < 100.0)
    }
  }
}

///|
test "geographic building review is opt in and preserves the authored production kit" {
  wenyu_scene_test_location("", false)
  assert_false(town_bearing_buildings_requested())
  wenyu_scene_test_location("?building-bearing=geo", false)
  assert_true(town_bearing_buildings_requested())
  wenyu_scene_test_location("?building-bearing=legacy", false)
  assert_false(town_bearing_buildings_requested())
  wenyu_scene_test_location("", true)
}

///|
test "local geographic north varies across the projective map and mesh verticals stay vertical" {
  let a = town_bearing_at(20, 20)
  let b = town_bearing_at(230, 130)
  let angle = fn(b : TownBuildingBearing) {
    @math.atan2(32.0 * (b.north.x - b.north.y), -16.0 * (b.north.x + b.north.y))
  }
  assert_true((angle(a) - angle(b)).abs() > 0.001)
  let mesh : TownBearingMesh = { points: [], colors: [], }
  town_bearing_quad(
    mesh,
    b,
    3,
    [
      { u: 0, v: 0, z: 0, },
      { u: 0.1, v: 0, z: 0, },
      { u: 0.1, v: 0, z: 1, },
      { u: 0, v: 0, z: 1, },
    ],
    "#fff",
  )
  assert_eq(mesh.points[0], mesh.points[9])
  assert_eq(mesh.points[1], mesh.points[10])
  assert_eq(mesh.points[3], mesh.points[6])
  assert_eq(mesh.points[4], mesh.points[7])
}
