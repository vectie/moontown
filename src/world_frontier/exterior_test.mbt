///|
test "procedural roads lots and plants cannot replace the authored core" {
  let core : @world_frontier.Rect = {
    min_x: 0,
    min_y: 0,
    max_x: 256,
    max_y: 144,
  }
  assert_eq(core.chunk_envelope().max_y, 160)
  let mut outside_lots = 0
  for y in -2..<=6 {
    for x in -2..<=9 {
      let original = @world_frontier.generate(20261028, x, y)
      let c = @world_frontier.exterior(original, core, [], [])
      assert_eq(c, @world_frontier.exterior(original, core, [], []))
      for r in c.roads {
        for i in 0..<=20 {
          let t = i.to_double() / 20
          assert_false(
            core.contains(
              {
                x: r.a.x + (r.b.x - r.a.x) * t,
                y: r.a.y + (r.b.y - r.a.y) * t,
              },
              pad=0.5,
            ),
          )
        }
      }
      for l in c.lots {
        outside_lots += 1
        let corners : Array[@world_frontier.Point] = [
          { x: l.x.to_double(), y: l.y.to_double(), },
          { x: (l.x + l.size).to_double(), y: (l.y + l.size).to_double(), },
        ]
        for p in corners {
          assert_false(core.contains(p, pad=4))
        }
      }
      for p in c.plants {
        assert_false(core.contains(p.point, pad=2))
      }
      if x >= 0 && x < 8 && y >= 0 && y < 4 {
        assert_eq(c.roads.length(), 0)
        assert_eq(c.lots.length(), 0)
        assert_eq(c.plants.length(), 0)
      }
    }
  }
  assert_true(outside_lots > 100)
}

///|
test "river mouths preserve their boundary position width and tangent" {
  let mouth : @world_frontier.Mouth = {
    point: { x: 256, y: 40, },
    normal: { x: 1, y: 0, },
    radius: 3,
    drift: 0,
  }
  assert_true(@world_frontier.mouth_water([mouth], { x: 256, y: 40, }))
  assert_true(@world_frontier.mouth_water([mouth], { x: 257, y: 42.9, }))
  assert_false(@world_frontier.mouth_water([mouth], { x: 256, y: 43.1, }))
  assert_false(@world_frontier.mouth_water([mouth], { x: 255, y: 40, }))
}

///|
test "exterior bridge and parcel decisions use inherited river mouths" {
  let core : @world_frontier.Rect = {
    min_x: 0,
    min_y: 0,
    max_x: 256,
    max_y: 144,
  }
  let mouths : Array[@world_frontier.Mouth] = [
    { point: { x: 256, y: 48, }, normal: { x: 1, y: 0, }, radius: 4, drift: 0, },
  ]
  let c = @world_frontier.exterior(
    @world_frontier.generate(20261028, 8, 1),
    core,
    [],
    mouths,
  )
  assert_true(c.roads.any(r => r.bridge))
  for r in c.roads {
    for i in 0..<=12 {
      let t = i.to_double() / 12
      if @world_frontier.mouth_water(mouths, {
          x: r.a.x + (r.b.x - r.a.x) * t,
          y: r.a.y + (r.b.y - r.a.y) * t,
        }) {
        assert_true(r.bridge)
      }
    }
  }
  for l in c.lots {
    for y in l.y..<=(l.y + l.size) {
      for x in l.x..<=(l.x + l.size) {
        assert_false(
          @world_frontier.mouth_water(mouths, {
            x: x.to_double(),
            y: y.to_double(),
          }),
        )
      }
    }
  }
}
