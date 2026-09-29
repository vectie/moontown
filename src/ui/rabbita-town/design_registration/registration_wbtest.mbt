///|
#cfg(target="js")
extern "js" fn read_design_fixture(name : String) -> String =
  #| name => process.getBuiltinModule('fs').readFileSync('../assets/tilemap/' + name, 'utf8')

///|
test "identity and mesh boundary splitting preserve endpoints" {
  let field = identity()
  let a : Point = { x: 3.0, y: 5.0 }
  let b : Point = { x: 31.0, y: 20.0 }
  assert_eq(field.project(a), a)
  let path = field.segment(a, b)
  assert_eq(path[0], a)
  assert_eq(path[path.length() - 1], b)
  assert_true(path.length() > 2)
  assert_eq(field.minimum_area(), 1.0)
}

///|
test "invalid design does not move geographic evidence" {
  assert_eq(
    fit(Json::null(), Json::null(), Json::null()).maximum_displacement(),
    0.0,
  )
}

///|
test "a deformed segment follows the mesh rather than cutting across mapped vertices" {
  let field = identity()
  field.offsets[5 * 33 + 6] = { x: 1.5, y: -0.5 }
  let a : Point = { x: 31.0, y: 28.0 }
  let b : Point = { x: 67.0, y: 54.0 }
  let path = field.segment(a, b)
  assert_true(field.minimum_area() > 0.5)
  for step in 0..<=100 {
    let t = step.to_double() / 100.0
    let p = field.project({ x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t })
    let mut best = 1000.0
    for index in 1..<path.length() {
      let left = path[index - 1]
      let right = path[index]
      let dx = right.x - left.x
      let dy = right.y - left.y
      let u = (((p.x - left.x) * dx + (p.y - left.y) * dy) /
        distance2(left, right))
        .max(0.0)
        .min(1.0)
      best = best.min(distance2(p, { x: left.x + dx * u, y: left.y + dy * u }))
    }
    assert_true(best < 0.000000001)
  }
}

///|
#cfg(target="js")
test "actual design fit improves corridors without folding or changing the perimeter" {
  let source = @json.parse(
    read_design_fixture("energy-valley-osm-block-graph-v1.json"),
  )
  let design = @json.parse(read_design_fixture("wenyu_reference_roads.json"))
  let terrain = @json.parse(read_design_fixture("wenyu_reference_labels.json"))
  let before_source = source.stringify()
  let before_design = design.stringify()
  let before_terrain = terrain.stringify()
  let field = fit(source, design, terrain)
  println(
    "design fit RMS \{field.before_rms} -> \{field.after_rms}; iterations \{field.iterations}; area \{field.minimum_area()}; maximum movement \{field.maximum_displacement()}",
  )
  println(
    "water conflict edges \{identity().water_conflict_edges(source, terrain)} -> \{field.water_conflict_edges(source, terrain)}",
  )
  assert_true(field.after_rms < field.before_rms)
  assert_true(
    field.water_conflict_edges(source, terrain) <
    identity().water_conflict_edges(source, terrain),
  )
  assert_eq(source.stringify(), before_source)
  assert_eq(design.stringify(), before_design)
  assert_eq(terrain.stringify(), before_terrain)
  assert_true(field.minimum_area() >= 0.4)
  assert_true(field.maximum_displacement() <= 10.0)
  for x in 0..<=256 {
    for y in [0.0, 144.0] {
      let p : Point = { x: x.to_double(), y }
      assert_eq(field.project(p), p)
    }
  }
  for y in 0..<=144 {
    for x in [0.0, 256.0] {
      let p : Point = { x, y: y.to_double() }
      assert_eq(field.project(p), p)
    }
  }
}
