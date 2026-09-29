///|
test "routes use node topology not screen-space crossings" {
  let g : @landmark_routes.Graph = {
    nodes: [
      { id: "west", x: 0, y: 1, },
      { id: "east", x: 2, y: 1, },
      { id: "north", x: 1, y: 0, },
      { id: "south", x: 1, y: 2, },
    ],
    edges: [
      { a: "west", b: "east", bridge: true, },
      { a: "north", b: "south", bridge: false, },
    ],
  }
  assert_true(@landmark_routes.route(g, "west", "east") is Some(_))
  assert_true(@landmark_routes.route(g, "west", "north") is None)
  assert_true(@landmark_routes.route(g, "missing", "east") is None)
}

///|
test "constant graph route chooses shortest connected journey" {
  let g : @landmark_routes.Graph = {
    nodes: [
      { id: "a", x: 0, y: 0, },
      { id: "b", x: 1, y: 0, },
      { id: "c", x: 2, y: 0, },
      { id: "detour", x: 1, y: 10, },
    ],
    edges: [
      { a: "a", b: "b", bridge: false, },
      { a: "b", b: "c", bridge: true, },
      { a: "a", b: "detour", bridge: false, },
      { a: "detour", b: "c", bridge: false, },
    ],
  }
  let route = @landmark_routes.route(g, "a", "c").unwrap()
  assert_eq(route.length(), 3)
  assert_eq(route[1].y, 0)
  assert_true(@landmark_routes.nearest(g, { x: 100, y: 100, }, 4) is None)
  assert_eq(@landmark_routes.nearest(g, { x: 0.1, y: 0, }, 4), Some("a"))
}
