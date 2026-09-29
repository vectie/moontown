///|
test "rounded footprints remain inside their intended bounds" {
  let pts = rounded_outline(38, 40, 7)
  assert_eq(pts.length(), 36)
  for pt in pts {
    assert_true(pt[0].abs() <= 19.00001)
    assert_true(pt[1].abs() <= 20.00001)
  }
}

///|
test "wave bridge leaves the carriageway open" {
  for side in [-1.0, 1.0] {
    for i in 0..<=100 {
      for j in 0..<=20 {
        let p = wave_point(
          i.to_double() / 100,
          j.to_double() * @math.PI / 20,
          side,
        )
        assert_true(p[2].abs() >= 9.0)
        assert_true(p[1] >= 10.449)
      }
    }
  }
  assert_true(wave_height(0.5) < wave_height(0))
  assert_true((wave_height(0) - wave_height(1)).abs() < 0.000001)
}

///|
test "arch ribs lean inward without crossing and return to deck at ends" {
  for i in 0..<=100 {
    let t = i.to_double() / 100
    let a = arch_point(t, -1)
    let b = arch_point(t, 1)
    assert_true(a[2] < b[2])
    assert_true(a[1] >= 11 - 0.00001)
    assert_eq(a[0], b[0])
  }
  assert_true(arch_point(0.5, 1)[2] < arch_point(0, 1)[2])
  assert_true((arch_point(1, 1)[1] - 11).abs() < 0.000001)
}

///|
test "all scene commands have finite geometry and supported materials" {
  let materials = [
    "ivory", "stone", "concrete", "paving", "paving2", "glass", "glassLight", "glassAmber",
    "silver", "copper", "amber", "roof", "metal", "grass", "earth", "sand", "leaf",
    "lime", "sage", "pine", "shrub", "bark", "blossom", "flower", "wood", "asphalt",
    "mark", "water", "ripple", "coral", "navy", "skin", "rubber", "cable", "lamp",
    "trimLight",
  ]
  for study in [future_center(), future_vision(), east_bridge(), arch_bridge()] {
    assert_eq(study.detail_focus.length(), 3)
    assert_eq(study.detail_offset.length(), 3)
    let mut context = 0
    let mut landmark = 0
    for p in study.parts {
      assert_true(materials.contains(p.material))
      assert_true(
        [
          "box", "round", "beam", "profile", "triangles", "sphere", "cylinder", "cone",
          "crown", "girder", "sign",
        ].contains(p.kind),
      )
      assert_eq(p.position.length(), 3)
      assert_eq(p.scale.length(), 3)
      for v in [..p.position, ..p.scale] {
        assert_true(v.abs() < 10000)
      }
      for v in p.scale {
        assert_true(v > 0)
      }
      for point in p.points {
        for v in point {
          assert_true(v.abs() < 10000)
        }
      }
      if p.kind == "triangles" {
        assert_eq(p.points.length() % 3, 0)
      }
      if p.layer == "context" {
        context += 1
      } else {
        landmark += 1
      }
    }
    assert_true(context > 100)
    assert_true(landmark > 100)
  }
}

///|
test "refined wave uses rectangular lattice sections without closing the roadway" {
  let study = east_bridge()
  let mut sections = 0
  for p in study.parts {
    if p.kind == "girder" {
      sections += 1
      assert_true(p.position[2].abs() >= 9)
      assert_true(p.points[0][2].abs() >= 9)
      assert_eq(p.scale[0], 0.32)
      assert_eq(p.scale[2], 0.24)
    }
  }
  assert_eq(sections, 2 * 66 * 10 * 2)
}

///|
test "bridge fittings include an underside and retain clear walkway surfaces" {
  let p : Array[Part] = []
  bridge_fittings(p, 45)
  assert_true(p.any(part => part.material == "metal" && part.position[1] < 8))
  let tactile = p.filter(part => part.material == "sand")
  assert_eq(tactile.length(), 2)
  for part in tactile {
    assert_eq(part.position[2].abs(), 20.5)
    assert_true(part.position[1] > 10.4)
  }
}
