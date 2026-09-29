///|
test "architectural vocabulary has 24 named and geometrically distinct designs" {
  let names : Map[String, Bool] = Map([])
  let geometry : Map[String, Bool] = Map([])
  let b = town_bearing_at(128, 72)
  for family in town_bearing_families {
    for variant in 0..<3 {
      let design = town_bearing_archetype(family, variant)
      assert_false(names.contains(design.name))
      names[design.name] = true
      let mesh = town_bearing_make_mesh(b, 3.0, family, variant)
      let signature = mesh.points.to_json().stringify()
      assert_false(geometry.contains(signature))
      geometry[signature] = true
      assert_eq(mesh.points.length(), mesh.colors.length() * 12)
      // Eaves, entrance canopies and roof fixtures must remain in the reserved
      // geographic lot envelope, just like their underlying wall volumes.
      for i in 0..<(mesh.points.length() / 3) {
        assert_true(
          mesh.points[i * 3].abs() <
          3.0 * (b.east.x.abs() + b.north.x.abs()) / 2.0,
        )
        assert_true(
          mesh.points[i * 3 + 1].abs() <
          3.0 * (b.east.y.abs() + b.north.y.abs()) / 2.0,
        )
        assert_true(
          mesh.points[i * 3 + 2] >= 0.0 && mesh.points[i * 3 + 2] < 8.0,
        )
      }
    }
  }
  assert_eq(names.length(), 24)
  assert_eq(geometry.length(), 24)
}

///|
test "diversity infill variants are explicit and old source identities remain stable" {
  for variant in 0..<3 {
    assert_eq(
      town_bearing_variant("procedural-grid-diversity-\{variant}-civic-18-20"),
      variant,
    )
  }
  let id = "procedural-source-example"
  assert_eq(town_bearing_variant(id), town_bearing_variant(id))
  assert_true(town_bearing_variant(id) >= 0 && town_bearing_variant(id) < 3)
}

///|
test "diversity completion does not invent buildable land without scene evidence" {
  assert_eq(wenyu_scene_prefix.length(), 0)
  let existing = intersection_road_preview_fixed_building(
    "preserved", "campus", 1, 10, 10,
  )
  let buildings : Map[Int, Array[IntersectionRoadPreviewBuilding]] = Map([
    (existing.depth_key, [existing]),
  ])
  town_bearing_complete_mix(buildings)
  assert_eq(buildings.length(), 1)
  assert_eq(buildings[existing.depth_key], [existing])
}

///|
test "diversity admission uses a compact legal pocket and rejects an occupied one" {
  let saved = wenyu_scene_prefix.map(n => n)
  let saved_roads = wenyu_scene_road_prefix.map(n => n)
  let prefix = Array::make(257 * 145, 0)
  let roads = Array::make(257 * 145, 0)
  for y in 0..<144 {
    for x in 0..<256 {
      let i = (y + 1) * 257 + x + 1
      let blocked = !(x >= 19 && x < 24 && y >= 19 && y < 24)
      prefix[i] = (if blocked { 1 } else { 0 }) +
        prefix[i - 1] +
        prefix[i - 257] -
        prefix[i - 258]
      roads[i] = (if x == 24 { 1 } else { 0 }) +
        roads[i - 1] +
        roads[i - 257] -
        roads[i - 258]
    }
  }
  wenyu_scene_prefix.clear()
  wenyu_scene_road_prefix.clear()
  for n in prefix {
    wenyu_scene_prefix.push(n)
  }
  for n in roads {
    wenyu_scene_road_prefix.push(n)
  }
  let candidate = town_bearing_find_diversity_lot("civic", 2, [])
  let second = match candidate {
    Some(b) => town_bearing_find_diversity_lot("industrial", 1, [b])
    None => None
  }
  // Restore globals before assertions, including on a failing result.
  wenyu_scene_prefix.clear()
  wenyu_scene_road_prefix.clear()
  for n in saved {
    wenyu_scene_prefix.push(n)
  }
  for n in saved_roads {
    wenyu_scene_road_prefix.push(n)
  }
  assert_true(
    candidate is Some({ x: 20, y: 20, width: 3, depth: 3, apron: 1, .. }),
  )
  assert_true(second is None)
}
