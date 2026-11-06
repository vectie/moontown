///|
test "frontier routes cross chunk seams both ways with matching geometry" {
  let a = @frontier.generate(frontier_seed, 0, 0)
  let b = @frontier.generate(frontier_seed, 1, 0)
  let c = @frontier.generate(frontier_seed, 2, 0)
  let graph = frontier_compile_graph([a, b, c])
  let start = (a.hub.x, a.hub.y)
  let end = (c.hub.x, c.hub.y)
  guard street_road_route(graph, start, end) is Some(path) else {
    fail("missing seam route")
  }
  assert_eq(path[0], start)
  assert_eq(path[path.length() - 1], end)
  assert_true(graph.edges.any(e => e.bridge))
  assert_true(street_road_route(graph, end, start) is Some(_))
  for i in 1..<path.length() {
    // Every traversed segment comes from an authoritative generated edge.
    let p = path[i - 1]
    let q = path[i]
    assert_true(
      ((p.0 - q.0) * (p.0 - q.0) + (p.1 - q.1) * (p.1 - q.1)).sqrt() < 3.0,
    )
  }
}

///|
test "frontier entrances are reachable not decorative disconnected paths" {
  let chunk = @frontier.generate(frontier_seed, 0, 0)
  let graph = frontier_compile_graph([chunk])
  assert_true(!chunk.lots.is_empty())
  for lot in chunk.lots {
    assert_true(
      street_road_route(
        graph,
        (chunk.hub.x, chunk.hub.y),
        (lot.entrance.x, lot.entrance.y),
      )
      is Some(_),
    )
  }
}

///|
test "frontier graph does not depend on chunk compilation order" {
  let a = @frontier.generate(frontier_seed, -1, 0)
  let b = @frontier.generate(frontier_seed, 0, 0)
  let forward = frontier_compile_graph([a, b])
  let reverse = frontier_compile_graph([b, a])
  let start = (a.hub.x, a.hub.y)
  let end = (b.hub.x, b.hub.y)
  assert_eq(
    street_road_route(forward, start, end),
    street_road_route(reverse, start, end),
  )
  assert_eq(forward.nodes.length(), reverse.nodes.length())
}
