///|
test "frontage reads every rendered street group but excludes the decorative spine" {
  let svg = "<svg><path d='M0,0L100,100'/><g fill='none' stroke='#ffc46d'><g stroke-width='0.09'><path d='M1,2L3,4'/></g><g stroke-width='0.24'><path d='M-1,8L20,8L20,10'/></g></g></svg>"
  let lines = town_street_parse(svg)
  assert_eq(lines.length(), 3)
  assert_eq(lines[0].a.x, 1.0)
  assert_eq(lines[1].a.x, 0.0)
  assert_eq(lines[2].b.y, 10.0)
  for
    input in [
      "<svg/>", "<g fill='none' stroke='#ffc46d'><path d='MNaN,2L3,4'/>", "<g fill='none' stroke='#ffc46d'><path d='M0,0C2,3,4,5,6,7'/>",
    ] {
    let rejected = try {
      ignore(town_street_parse(input))
      false
    } catch {
      _ => true
    }
    assert_true(rejected)
  }
}

///|
test "actual displayed-road index agrees with exhaustive nearest-segment search" {
  let parsed = town_street_parse(
    town_density_fixture_text("wenyu-unshifted-road-overlay.svg"),
  )
  let saved = town_street_segments.map(s => s)
  town_street_index(parsed)
  let errors : Array[Double] = []
  for x in [1.0, 32.0, 96.0, 128.0, 192.0, 255.0] {
    for y in [1.0, 36.0, 72.0, 108.0, 143.0] {
      let mut expected = 8.0
      for segment in parsed {
        expected = expected.min(town_street_project(segment, x, y).distance)
      }
      let actual = match town_street_nearest(x, y) {
        Some(hit) => hit.distance
        None => 8.0
      }
      errors.push((actual - expected).abs())
    }
  }
  town_street_index(saved)
  assert_true(parsed.length() > 3000)
  for error in errors {
    assert_true(error < 0.000001)
  }
}

///|
test "building floor heights do not shrink with frontage width" {
  let b = town_bearing_at(128, 72)
  for family in town_bearing_families {
    for variant in 0..<3 {
      let small = town_bearing_make_mesh(b, 2.0, family, variant)
      let large = town_bearing_make_mesh(b, 4.0, family, variant)
      assert_eq(small.points.length(), large.points.length())
      for i in 0..<(small.points.length() / 3) {
        assert_true(
          (small.points[i * 3 + 2] - large.points[i * 3 + 2]).abs() < 0.000001,
        )
        assert_true(
          (small.points[i * 3] * 2.0 - large.points[i * 3]).abs() < 0.000001,
        )
      }
    }
  }
}

///|
test "entrance walks are short and start at the street-facing lot edge" {
  let b : TownBuildingBearing = {
    east: { x: 1, y: 0, },
    north: { x: 0, y: -1, },
    deviation: 0,
  }
  let close = town_street_entry_geometry(b, 3, 0, 0, { x: 2.5, y: 0, })
  assert_true(close is Some(({ x: 1.5, y: 0, .. }, { x: 2.5, y: 0, .. })))
  assert_true(town_street_entry_geometry(b, 3, 0, 0, { x: 7, y: 0, }) is None)
  assert_true(town_street_entry_geometry(b, 3, 0, 0, { x: 0, y: 0, }) is None)
}
