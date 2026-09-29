///|
test "density sampler visits every tile once and interleaves districts" {
  let seen : Map[Int, Bool] = Map([])
  let districts : Map[Int, Bool] = Map([])
  for i in 0..<(256 * 144) {
    let (x, y) = town_bearing_density_site(i)
    assert_true(x >= 0 && x < 256 && y >= 0 && y < 144)
    let key = y * 256 + x
    assert_false(seen.contains(key))
    seen[key] = true
    if i < 144 {
      districts[y / 16 * 16 + x / 16] = true
    }
  }
  assert_eq(seen.length(), 256 * 144)
  assert_eq(districts.length(), 144)
}

///|
test "density target never invents land before scene evidence is ready" {
  let buildings : Map[Int, Array[IntersectionRoadPreviewBuilding]] = Map([])
  town_bearing_fill_density(buildings, town_bearing_density_target)
  assert_eq(buildings.length(), 0)
}

///|
test "compact houses share gardens but walls never enter another building apron" {
  let a : IntersectionRoadPreviewBuilding = {
    id: "procedural-grid-density-20-20",
    style: "lowrise",
    asset_path: intersection_road_preview_building_asset_path("lowrise", 0).unwrap(),
    x: 20,
    y: 20,
    width: 3,
    depth: 3,
    apron: 0,
    depth_key: 46,
  }
  let b = { ..a, id: "procedural-grid-density-24-20", x: 24, depth_key: 50, }
  assert_true(intersection_road_preview_building_geometry_valid(a))
  assert_false(intersection_road_preview_buildings_overlap(a, b))
  assert_false(intersection_road_preview_buildings_overlap(b, a))
  assert_true(intersection_road_preview_buildings_overlap(a, { ..b, x: 23, }))
  assert_false(
    intersection_road_preview_buildings_overlap(a, {
      ..b,
      id: "legacy",
      width: 3,
      depth: 3,
    }),
  )
  assert_true(
    intersection_road_preview_buildings_overlap(a, {
      ..b,
      id: "legacy",
      x: 23,
      width: 3,
      depth: 3,
    }),
  )
  assert_false(
    intersection_road_preview_building_geometry_valid({ ..a, id: "legacy", }),
  )
  assert_false(
    intersection_road_preview_building_geometry_valid({ ..a, style: "civic", }),
  )
}

///|
extern "js" fn town_density_fixture_text(name : String) -> String =
  #| name => process.getBuiltinModule('fs').readFileSync('../assets/tilemap/' + name, 'utf8')

///|
test "density admission respects the actual unshifted Wenyu road and terrain masks" {
  let saved_streets = town_street_segments.map(s => s)
  let streets = town_street_parse(
    town_density_fixture_text("wenyu-unshifted-road-overlay.svg"),
  )
  let saved = wenyu_scene_prefix.map(n => n)
  let saved_roads = wenyu_scene_road_prefix.map(n => n)
  let scene = @json.parse(
    town_density_fixture_text("wenyu-unshifted-scene.json"),
  )
  let terrain = @json.parse(
    town_density_fixture_text("wenyu_reference_labels.json"),
  )
  guard scene
    is { "roadCells": Array(rows), "riversideShiftsApplied": False, .. } else {
    fail("invalid scene fixture")
  }
  guard terrain is { "rows": Array(land), .. } else {
    fail("invalid terrain fixture")
  }
  let prefix = Array::make(257 * 145, 0)
  let roads = Array::make(257 * 145, 0)
  for y in 0..<144 {
    guard rows[y] is String(row) && land[y] is String(ground) else {
      fail("invalid row")
    }
    for x in 0..<256 {
      let road = row[x] == 'R'
      let blocked = road || ground[x] is ('r' | 'l' | 'w' | 'b' | 'G')
      let i = (y + 1) * 257 + x + 1
      prefix[i] = (if blocked { 1 } else { 0 }) +
        prefix[i - 1] +
        prefix[i - 257] -
        prefix[i - 258]
      roads[i] = (if road { 1 } else { 0 }) +
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
  town_street_index(streets)
  let buildings : Map[Int, Array[IntersectionRoadPreviewBuilding]] = Map([])
  town_bearing_fill_density(buildings, town_bearing_density_target)
  let all : Array[IntersectionRoadPreviewBuilding] = []
  let mut valid = true
  for _, items in buildings {
    for b in items {
      all.push(b)
      valid = valid &&
        wenyu_scene_lot_valid(b) &&
        intersection_road_preview_building_geometry_valid(b) &&
        b.width == 3 &&
        b.apron == 0 &&
        town_street_lot_gap(b) <= 1.25
    }
  }
  wenyu_scene_prefix.clear()
  wenyu_scene_road_prefix.clear()
  for n in saved {
    wenyu_scene_prefix.push(n)
  }
  for n in saved_roads {
    wenyu_scene_road_prefix.push(n)
  }
  town_street_index(saved_streets)
  assert_true(valid)
  assert_eq(all.length(), 176)
  for i in 0..<all.length() {
    for j in (i + 1)..<all.length() {
      assert_false(intersection_road_preview_buildings_overlap(all[i], all[j]))
    }
  }
}

///|
test "density fills 176 distinct cleared lots without moving existing buildings" {
  let saved = wenyu_scene_prefix.map(n => n)
  let saved_roads = wenyu_scene_road_prefix.map(n => n)
  let prefix = Array::make(257 * 145, 0)
  // Parallel streets with complete six-cell dry strips between them.
  for y in 0..<144 {
    for x in 0..<256 {
      let i = (y + 1) * 257 + x + 1
      prefix[i] = (if x % 7 == 0 { 1 } else { 0 }) +
        prefix[i - 1] +
        prefix[i - 257] -
        prefix[i - 258]
    }
  }
  wenyu_scene_prefix.clear()
  wenyu_scene_road_prefix.clear()
  for n in prefix {
    wenyu_scene_prefix.push(n)
    wenyu_scene_road_prefix.push(n)
  }
  let existing : IntersectionRoadPreviewBuilding = {
    id: "preserved-source",
    style: "lowrise",
    asset_path: intersection_road_preview_building_asset_path("lowrise", 0).unwrap(),
    x: 2,
    y: 2,
    width: 3,
    depth: 3,
    apron: 1,
    depth_key: 10,
  }
  let buildings : Map[Int, Array[IntersectionRoadPreviewBuilding]] = Map([
    (10, [existing]),
  ])
  town_bearing_fill_density(buildings, town_bearing_density_target)
  let all : Array[IntersectionRoadPreviewBuilding] = []
  let mut valid = true
  for _, items in buildings {
    for b in items {
      all.push(b)
      valid = valid &&
        wenyu_scene_lot_valid(b) &&
        intersection_road_preview_building_geometry_valid(b)
    }
  }
  let first = all.map(b => b.id).join(",")
  town_bearing_fill_density(buildings, town_bearing_density_target)
  let again : Array[String] = []
  for _, items in buildings {
    for b in items {
      again.push(b.id)
    }
  }
  wenyu_scene_prefix.clear()
  wenyu_scene_road_prefix.clear()
  for n in saved {
    wenyu_scene_prefix.push(n)
  }
  for n in saved_roads {
    wenyu_scene_road_prefix.push(n)
  }
  assert_eq(all.length(), 176)
  assert_true(valid)
  assert_eq(first, again.join(","))
  assert_true(all.contains(existing))
  for i in 0..<all.length() {
    for j in (i + 1)..<all.length() {
      assert_false(intersection_road_preview_buildings_overlap(all[i], all[j]))
      assert_true(all[i].id != all[j].id)
    }
  }
}
