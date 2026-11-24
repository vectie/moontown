///|
extern "js" fn wenyu_scene_test_location(
  search : String,
  restore : Bool,
) -> Unit =
  #| (search,restore) => {
  #|   if (restore) {
  #|     if (globalThis.__wenyuTestLocation === undefined) delete globalThis.location;
  #|     else globalThis.location=globalThis.__wenyuTestLocation;
  #|     delete globalThis.__wenyuTestLocation;
  #|   } else {
  #|     if (!('__wenyuTestLocation' in globalThis)) globalThis.__wenyuTestLocation=globalThis.location;
  #|     globalThis.location={search};
  #|   }
  #| }

///|
test "production uses restored scene without a trial query and keeps comparisons explicit" {
  wenyu_scene_test_location("", false)
  assert_true(wenyu_scene_default_requested())
  assert_true(wenyu_rigid_scene_active())
  wenyu_scene_test_location("?road-trial=gentle", false)
  assert_false(wenyu_scene_default_requested())
  assert_false(wenyu_rigid_scene_active())
  wenyu_scene_test_location("?road-trial=gentle&shore=1", false)
  assert_true(wenyu_rigid_scene_active())
  wenyu_scene_test_location("?registration-review=1", false)
  assert_false(wenyu_scene_default_requested())
  wenyu_scene_test_location("", true)
}

///|
test "corrected scene rectangle query includes its full footprint and apron" {
  let prefix = Array::make(257 * 145, 0)
  for y in 1..<=144 {
    for x in 1..<=256 {
      let i = y * 257 + x
      prefix[i] = (if x == 11 && y == 21 { 1 } else { 0 }) +
        prefix[i - 1] +
        prefix[i - 257] -
        prefix[i - 258]
    }
  }
  assert_false(wenyu_scene_region_clear(prefix, 9, 19, 3, 3))
  assert_true(wenyu_scene_region_clear(prefix, 11, 20, 3, 3))
  assert_false(wenyu_scene_region_clear(prefix, -1, 20, 3, 3))
  assert_false(wenyu_scene_region_clear(prefix, 255, 140, 3, 3))
}

///|
test "corrected scene walkers follow bends and reverse without endpoint jumps" {
  let path : WenyuScenePath = {
    points: [{ x: 0, y: 0, }, { x: 3, y: 0, }, { x: 3, y: 4, }],
    lengths: [0, 3, 7],
    total: 7,
  }
  let p = wenyu_scene_sample(path, 5)
  assert_eq(p.x, 3.0)
  assert_eq(p.y, 2.0)
  let before = wenyu_scene_sample(path, 6.99)
  let after = wenyu_scene_sample(path, 7.01)
  assert_true((before.x - after.x).abs() < 0.00001)
  assert_true((before.y - after.y).abs() < 0.00001)
  let wrap = wenyu_scene_sample(path, 14.01)
  assert_true((wrap.x - 0.01).abs() < 0.00001)
  assert_eq(wrap.y, 0.0)
}

///|
test "display parcels reject malformed, overlapping and boundary-spanning lots" {
  assert_true(wenyu_scene_read_parcels([[0, 0, 2, 1], [0, 1, 3, 2]]) is None)
  assert_true(wenyu_scene_read_parcels([[144, 0, 2, 1]]) is None)
  assert_true(wenyu_scene_read_parcels([[0, 1.5, 2, 1]]) is None)
  let index = wenyu_scene_read_parcels([[0, 0, 3, 1], [0, 3, 5, 2]]).unwrap()
  assert_true(wenyu_scene_single_parcel(index, 0, 0, 3, 1))
  assert_false(wenyu_scene_single_parcel(index, 2, 0, 2, 1))
  assert_false(wenyu_scene_single_parcel(index, 4, 0, 2, 1))
  assert_true(wenyu_scene_single_parcel(index, 5, 0, 2, 1))
}

///|
test "the calibrated right-dike stays dry and park trail has only the reviewed short water contact" {
  let scene = @json.parse(town_density_fixture_text("wenyu-bank-scene-v2.json"))
  let terrain = @json.parse(
    town_density_fixture_text("wenyu_reference_labels.json"),
  )
  guard scene is { "paths": Array(ways), .. } &&
    terrain is { "rows": Array(rows), .. } else {
    fail("missing Wenyu scene")
  }
  for
    (id, ax, ay, bx, by, pad, limit) in [
      (260842920.0, 143.4165, 21.7088, 135.9727, 12.8003, 0.12, 0.0),
      (622609746.0, 158.245, 66.181, 168.2011, 63.9711, 0.045, 0.36),
    ] {
    guard ways.search_by(w => w is { "id": Number(n, ..), .. } && n == id)
      is Some(ix) &&
      ways[ix] is { "points": Array(vertices), .. } else {
      fail("missing walking route")
    }
    let points : Array[WenyuScenePoint] = []
    let lengths = []
    let mut total = 0.0
    for vertex in vertices {
      guard vertex is [Number(x, ..), Number(y, ..)] else {
        fail("invalid walking vertex")
      }
      if points.is_empty() && (x != ax || y != ay) {
        continue
      }
      if points.last() is Some(p) {
        total += ((x - p.x) * (x - p.x) + (y - p.y) * (y - p.y)).sqrt()
      }
      points.push({ x, y, })
      lengths.push(total)
      if x == bx && y == by {
        break
      }
    }
    assert_true(total > 0 && points.last() is Some(p) && p.x == bx && p.y == by)
    let route : WenyuScenePath = { points, lengths, total, }
    let steps = (total / 0.02).ceil().to_int()
    let mut wet_steps = 0
    for i in 0..<=steps {
      let p = wenyu_scene_sample(
        route,
        total * i.to_double() / steps.to_double(),
      )
      let mut wet = false
      for dx in [-pad, pad] {
        for dy in [-pad, pad] {
          guard rows[(p.y + dy).floor().to_int()] is String(row) else {
            fail("invalid terrain row")
          }
          if row[(p.x + dx).floor().to_int()] is ('r' | 'l') {
            wet = true
          }
        }
      }
      if wet {
        wet_steps += 1
      }
    }
    assert_true(wet_steps.to_double() * total / steps.to_double() <= limit)
  }
}

///|
extern "js" fn wenyu_shore_source_fixture(name : String) -> String =
  #| name => process.getBuiltinModule('fs').readFileSync('../../../docs/project/'+name+'.json','utf8')

///|
test "left dike and connected walking streets preserve every registered OSM vertex in order" {
  let scene = @json.parse(town_density_fixture_text("wenyu-bank-scene-v2.json"))
  let reference = @json.parse(
    wenyu_shore_source_fixture("wenyu-lower-perspective"),
  )
  let group = @json.parse(
    wenyu_shore_source_fixture("wenyu-left-dike-group-trial"),
  )
  let fit = @json.parse(wenyu_shore_source_fixture("wenyu-major-road-fit"))
  guard group is { "ways": Array(ids), .. } &&
    fit
    is {
      "coreFit": {
        "origin": { "x": Number(ox, ..), "y": Number(oy, ..), .. },
        "shift": { "x": Number(sx, ..), "y": Number(sy, ..), .. },
        "axis": { "x": Number(ax, ..), "y": Number(ay, ..), .. },
        "drop": Number(drop, ..),
        "isotropic": Number(iso, ..),
        "uniform": false,
        ..
      },
      ..
    } else {
    fail("missing accepted dike group fit")
  }
  let inner : Set[Double] = Set([])
  for id in ids {
    if id is Number(n, ..) {
      inner.add(n)
    }
  }
  guard scene is { "paths": Array(paths), .. } &&
    reference is { "ways": Array(ways), .. } else {
    fail("missing road data")
  }
  let baseline : Map[String, Map[String, Double]] = @json.from_json(
    @json.parse(wenyu_shore_source_fixture("wenyu-bank-node-overrides")),
  )
  let mut checked = 0
  let routes : Map[Double, Array[Json]] = Map([])
  for p in paths {
    if p is { "id": Number(n, ..), "points": Array(points), .. } {
      routes[n] = points
    }
  }
  for w in ways {
    guard w
      is {
        "osmWayId": Number(id, ..),
        "pathGrid": Array(raw),
        "nodes": Array(nodes),
        ..
      } &&
      inner.contains(id) &&
      routes.get(id) is Some(out) else {
      continue
    }
    assert_eq(raw.length(), out.length())
    for i, p in raw {
      guard p is { "x": Number(x, ..), "y": Number(y, ..), .. } &&
        nodes[i] is Number(node, ..) &&
        out[i] is [Number(px, ..), Number(py, ..)] else {
        fail("invalid vertex")
      }
      let depth = 1.0 + 0.01 * ((x - 256) / 256 - y / 144)
      let (gx, gy) = match baseline.get(node.to_string()) {
        Some(p) => (p["x"], p["y"])
        None => (256.0 + (x - 256) / depth, y / depth)
      }
      let v = ((gx - ox) * ax + (gy - oy) * ay) * drop
      assert_true((px - (gx + sx - iso * (gx - ox) - v * ax)).abs() <= 0.000051)
      assert_true((py - (gy + sy - iso * (gy - oy) - v * ay)).abs() <= 0.000051)
    }
    checked += 1
  }
  assert_true(checked > 2)
  let dike = routes[47518902]
  let access = routes[1239039189]
  assert_eq(dike.length(), 63)
  assert_true(dike.contains(access[0]) && dike.contains(access.last().unwrap()))
}
