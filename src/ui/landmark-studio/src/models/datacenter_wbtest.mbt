///|
test "model entities and flow paths are coherent across scales" {
  let views = [
    dc_site(),
    dc_hall(),
    dc_rack(),
    dc_server(false),
    dc_server(true),
  ]
  for v in views {
    assert_true(v.study.parts.length() > 30)
    let ids : Map[String, Bool] = Map([])
    for e in v.entities {
      assert_true(!ids.contains(e.id))
      ids[e.id] = true
      assert_eq(e.position.length(), 3)
      assert_true(e.visit == "" || views.any(view => view.study.id == e.visit))
      assert_true(v.study.parts.any(p => p.layer == e.id))
    }
    for p in v.study.parts {
      assert_eq(p.position.length(), 3)
      assert_eq(p.scale.length(), 3)
      assert_true(p.scale.all(x => x > 0 && x < 1000))
      assert_true(p.position.all(x => x.abs() < 1000))
    }
    for f in v.flows {
      assert_true(f.points.length() >= 2)
      assert_true(["data", "power", "cooling", "heat"].contains(f.family))
      for point in f.points {
        assert_eq(point.length(), 3)
      }
      for i in 1..<f.points.length() {
        assert_true(f.points[i] != f.points[i - 1])
      }
    }
  }
}

///|
test "rack capacity and mirrored hall rows agree with reports" {
  let hall = dc_hall()
  let rack_entities = hall.entities.filter(e => e.visit == "rack")
  assert_eq(rack_entities.length(), 12)
  assert_eq(dc_rack().entities.filter(e => e.visit == "server").length(), 12)
  let fronts = hall.study.parts.filter(p => {
    p.material == "screen" && p.scale[0] == 0.015
  })
  assert_eq(fronts.length(), 144)
  for p in fronts {
    if p.layer.has_prefix("A") {
      assert_true(p.position[2] > -2)
      assert_eq(p.rotation, 0)
    } else {
      assert_true(p.position[2] < 2)
      assert_eq(p.rotation, @math.PI)
    }
  }
}
