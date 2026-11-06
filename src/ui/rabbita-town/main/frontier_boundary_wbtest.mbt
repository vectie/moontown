///|
extern "js" fn frontier_test_asset(name : String) -> String =
  #| name => process.getBuiltinModule('fs').readFileSync('../assets/' + name, 'utf8')

///|
test "all four exterior gates connect to actual core arrival without changing the core graph" {
  let core : @landmark_routes.Graph = @json.from_json(
    @json.parse(frontier_test_asset("landmark-studio/navigation.json")),
  )
  let boundary : FrontierBoundary = @json.from_json(
    @json.parse(frontier_test_asset("tilemap/wenyu-frontier-exits.json")),
  )
  assert_eq(boundary.exits.length(), 4)
  let mouths = boundary.rivers.map(r => @frontier.Mouth::{
    point: { x: r.x, y: r.y, },
    normal: { x: r.dx, y: r.dy, },
    radius: r.radius,
    drift: r.drift,
  })
  let gates : Array[@frontier.Road] = []
  let coords : Map[String, (Int32, Int32)] = Map([])
  let targets : Array[@frontier.Point] = []
  for e in boundary.exits {
    let roads = @frontier.city_gate(
      frontier_seed,
      { x: e.x, y: e.y, },
      { x: e.dx, y: e.dy, },
      frontier_city_frame(),
      frontier_core,
      mouths,
    )
    assert_false(roads.is_empty())
    targets.push(roads[roads.length() - 1].b)
    gates.append(roads)
    for r in roads {
      for p in [r.a, r.b] {
        let x = @frontier.coordinate(p.x)
        let y = @frontier.coordinate(p.y)
        coords["\{x}:\{y}"] = (x, y)
      }
      for i in 1..<=16 {
        let t = i.to_double() / 16
        let p : @frontier.Point = {
          x: r.a.x + (r.b.x - r.a.x) * t,
          y: r.a.y + (r.b.y - r.a.y) * t,
        }
        assert_false(frontier_core.contains(p, pad=-0.001))
      }
    }
  }
  let chunks = coords
    .values()
    .collect()
    .map(p => {
      @frontier.city(
        frontier_seed,
        p.0,
        p.1,
        frontier_city_frame(),
        frontier_core,
        gates,
        mouths,
      )
    })
  let merged = frontier_merge_graph(
    core,
    frontier_compile_graph(chunks),
    boundary,
  )
  town_landmarks_init()
  let center = town_landmark_find("center").unwrap()
  let start = street_road_point(core, (center.door.x, center.door.y), 4).unwrap().point
  for hub in targets {
    let route = street_road_route(merged, start, (hub.x, hub.y)).unwrap()
    assert_true(route.length() > 5)
    assert_true(street_road_route(merged, (hub.x, hub.y), start) is Some(_))
    let id = @frontier.node_id(hub)
    assert_true(merged.edges.filter(e => e.a == id || e.b == id).length() >= 2)
  }
  for n in core.nodes {
    let found = merged.nodes[merged.nodes
      .search_by(n2 => n.id == n2.id)
      .unwrap()]
    assert_eq((n.x, n.y), (found.x, found.y))
  }
  for i, e in core.edges {
    assert_eq(
      (e.a, e.b, e.bridge),
      (merged.edges[i].a, merged.edges[i].b, merged.edges[i].bridge),
    )
  }
}
