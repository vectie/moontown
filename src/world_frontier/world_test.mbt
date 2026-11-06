///|
test "layout is deterministic across order and seeds" {
  let a = @world_frontier.generate(20261028, -2, 3)
  let _ = @world_frontier.generate(19, 45, -90)
  assert_eq(a, @world_frontier.generate(20261028, -2, 3))
  assert_true(a != @world_frontier.generate(20261029, -2, 3))
  assert_eq(@world_frontier.coordinate(-0.001), -1)
  assert_eq(@world_frontier.coordinate(-32.0), -1)
  assert_eq(@world_frontier.coordinate(-32.001), -2)
  assert_eq(@world_frontier.coordinate(32.0), 1)
}

///|
test "all four portals match across positive and negative chunks" {
  for seed in 0..<12 {
    for x in -3..<3 {
      let a = @world_frontier.generate(seed, x, -2)
      let east = @world_frontier.generate(seed, x + 1, -2)
      let south = @world_frontier.generate(seed, x, -1)
      assert_eq(a.roads[23].b, east.roads[0].a)
      assert_eq(a.roads[47].b, south.roads[24].a)
      assert_eq(
        @world_frontier.node_id(a.roads[23].b),
        @world_frontier.node_id(east.roads[0].a),
      )
      assert_eq(a.roads[23].width, east.roads[0].width)
      // Sampled cubic tangents approach the common cardinal boundary direction.
      assert_true((a.roads[23].b.y - a.roads[23].a.y).abs() < 0.05)
      assert_true((east.roads[0].b.y - east.roads[0].a.y).abs() < 0.05)
    }
  }
}

///|
test "lots avoid water roads and each other across 100 layouts" {
  let mut buildings = 0
  for i in 0..<100 {
    let c = @world_frontier.generate(i, i % 13 - 6, i / 13 - 4)
    for j, l in c.lots {
      buildings += 1
      let p : @world_frontier.Point = {
        x: l.x.to_double() + l.size.to_double() / 2,
        y: l.y.to_double() + l.size.to_double() / 2,
      }
      assert_true(l.x >= c.x * 32 + 1 && l.x + l.size < (c.x + 1) * 32)
      assert_true(l.y >= c.y * 32 + 1 && l.y + l.size < (c.y + 1) * 32)
      for road in c.roads {
        assert_true(
          @world_frontier.distance(@world_frontier.nearest_on(road, p), p) >=
          l.size.to_double() * 0.72 + 0.94,
        )
      }
      for y in l.y..<=(l.y + l.size) {
        for x in l.x..<=(l.x + l.size) {
          assert_false(
            @world_frontier.water({ x: x.to_double(), y: y.to_double(), }),
          )
        }
      }
      assert_true(
        c.roads.any(r => {
          @world_frontier.distance(
            @world_frontier.nearest_on(r, l.frontage),
            l.frontage,
          ) <
          0.002
        }),
      )
      for k, o in c.lots {
        if j != k {
          assert_true(
            l.x + l.size <= o.x ||
            o.x + o.size <= l.x ||
            l.y + l.size <= o.y ||
            o.y + o.size <= l.y,
          )
        }
      }
    }
  }
  assert_true(buildings > 100)
}

///|
test "water crossing uses bridge metadata for the complete road width" {
  let mut bridges = 0
  for y in -3..<3 {
    let c = @world_frontier.generate(20261028, 1, y)
    for road in c.roads {
      if road.bridge {
        bridges += 1
      }
      for i in 0..<=8 {
        let t = i.to_double() / 8
        let p : @world_frontier.Point = {
          x: road.a.x + (road.b.x - road.a.x) * t,
          y: road.a.y + (road.b.y - road.a.y) * t,
        }
        if @world_frontier.river_distance(p) < 2.9 {
          assert_true(road.bridge)
        }
      }
    }
  }
  assert_true(bridges > 0)
}

///|
test "streaming stays bounded and revisiting restores identical content" {
  let window = @world_frontier.Window::new(20261028)
  let original = window.around({ x: 16, y: 16, })
  for i in 0..<400 {
    let _ = window.around({ x: (i * 32).to_double(), y: (-i * 32).to_double(), })
    assert_eq(window.count(), 9)
  }
  assert_eq(window.around({ x: 16, y: 16, }), original)
  let _ = window.around({ x: 1048576, y: 1048576, })
  assert_true(window.count() <= 9)
}

///|
test "coordinate key stays distinct at far prototype coordinates" {
  let a = @world_frontier.generate(20261028, 30000, -30000)
  assert_true(
    @world_frontier.node_id(a.roads[0].a) !=
    @world_frontier.node_id(a.roads[0].b),
  )
  assert_eq(a, @world_frontier.generate(20261028, 30000, -30000))
}
