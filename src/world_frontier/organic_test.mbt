///|
test "organic street seams share variable portals and hierarchy in both orders" {
  let ys : Map[Double, Bool] = Map([])
  let masks : Map[Int32, Bool] = Map([])
  for x in -6..<=6 {
    for y in -5..<=5 {
      let a = @world_frontier.generate(20261028, x, y, organic=true)
      let b = @world_frontier.generate(20261028, x + 1, y, organic=true)
      let c = @world_frontier.generate(20261028, x, y + 1, organic=true)
      assert_eq(a.roads[23].b, b.roads[0].a)
      assert_eq(a.roads[23].width, b.roads[0].width)
      assert_eq(a.roads[47].b, c.roads[24].a)
      assert_eq((a.arms & 8) != 0, (c.arms & 4) != 0)
      assert_eq(a.roads[47].width, c.roads[24].width)
      assert_eq(a, @world_frontier.generate(20261028, x, y, organic=true))
      ys[a.roads[23].b.y - (y * 32).to_double()] = true
      masks[a.arms] = true
      assert_eq(a.arms & 3, 3)
      if x % 4 == 0 {
        assert_eq(a.arms, 15)
      }
    }
  }
  assert_true(ys.length() > 10)
  assert_true(masks.length() >= 3)
}

///|
test "organic parcels keep road frontage clearance with clearings and groves" {
  let core : @world_frontier.Rect = {
    min_x: 0,
    min_y: 0,
    max_x: 256,
    max_y: 144,
  }
  let mut empty = 0
  let mut built = 0
  for y in -5..<0 {
    for x in 0..<12 {
      let c = @world_frontier.exterior(
        @world_frontier.generate(20261028, x, y, organic=true),
        core,
        [],
        [],
      )
      if c.lots.is_empty() {
        empty += 1
      } else {
        built += 1
      }
      for l in c.lots {
        let center : @world_frontier.Point = {
          x: l.x.to_double() + l.size.to_double() / 2,
          y: l.y.to_double() + l.size.to_double() / 2,
        }
        assert_false(core.contains(center, pad=6))
        assert_true(
          c.roads.any(r => {
            @world_frontier.distance(
              @world_frontier.nearest_on(r, l.frontage),
              l.frontage,
            ) <
            0.002
          }),
        )
        for r in c.roads {
          assert_true(
            @world_frontier.distance(
              @world_frontier.nearest_on(r, center),
              center,
            ) >=
            l.size.to_double() * 0.72 + 0.94,
          )
        }
      }
    }
  }
  assert_true(empty > 5 && built > 10)
}
