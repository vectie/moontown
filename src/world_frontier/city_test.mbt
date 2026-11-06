///|
let frame : @world_frontier.CityFrame = {
  origin: { x: 128, y: 72, },
  east: { x: 1.05, y: 0.35, },
  south: { x: -0.3, y: 0.84, },
}

///|
let core : @world_frontier.Rect = {
  min_x: 0,
  min_y: 0,
  max_x: 256,
  max_y: 144,
}

///|
test "city streets follow geographic axes not chunk hubs" {
  let widths : Map[Double, Bool] = Map([])
  for y in -5..<0 {
    for x in -4..<7 {
      let c = @world_frontier.city(20261028, x, y, frame, core, [], [])
      assert_eq(c, @world_frontier.city(20261028, x, y, frame, core, [], []))
      for r in c.roads {
        let a = frame.plan(r.a)
        let b = frame.plan(r.b)
        assert_true((a.x - b.x).abs() < 0.002 || (a.y - b.y).abs() < 0.002)
        assert_false(core.contains(r.a, pad=-0.001))
        assert_false(core.contains(r.b, pad=-0.001))
        widths[r.width] = true
      }
    }
  }
  assert_eq(widths.length(), 2)
}

///|
test "loading boundaries cannot change road location width or tangent" {
  for y in -4..<0 {
    for x in -4..<6 {
      let a = @world_frontier.city(20261028, x, y, frame, core, [], [])
      let b = @world_frontier.city(20261028, x + 1, y, frame, core, [], [])
      let c = @world_frontier.city(20261028, x, y + 1, frame, core, [], [])
      for
        (next, boundary, vertical) in [
          (b, ((x + 1) * 32).to_double(), true),
          (c, ((y + 1) * 32).to_double(), false),
        ] {
        for r in a.roads {
          for p in [r.a, r.b] {
            if (if vertical { p.x } else { p.y }) != boundary {
              continue
            }
            assert_true(
              next.roads.any(s => (s.a == p || s.b == p) && s.width == r.width),
            )
          }
        }
      }
    }
  }
}

///|
test "city parcels respect protected core water and have real frontage" {
  let mouths : Array[@world_frontier.Mouth] = [
    {
      point: { x: 235, y: 144, },
      normal: { x: 0, y: 1, },
      radius: 14,
      drift: 0.3,
    },
  ]
  let mut count = 0
  for y in 3..<9 {
    for x in -2..<11 {
      let c = @world_frontier.city(20261028, x, y, frame, core, [], mouths)
      for l in c.lots {
        count += 1
        let matches = c.roads.any(r => {
          let d = @world_frontier.distance(
            @world_frontier.nearest_on(r, l.frontage),
            l.frontage,
          )
          let dx = r.b.x - r.a.x
          let dy = r.b.y - r.a.y
          d < 0.002 &&
          (l.east.x * dy - l.east.y * dx)
          .abs()
          .min((l.north.x * dy - l.north.y * dx).abs()) <
          0.000001
        })
        assert_true(matches)
        let span = (l.size.to_double() / (l.east.x.abs() + l.north.x.abs())).min(
          l.size.to_double() / (l.east.y.abs() + l.north.y.abs()),
        )
        let dx = l.entrance.x - l.x.to_double() - l.size.to_double() / 2
        let dy = l.entrance.y - l.y.to_double() - l.size.to_double() / 2
        let det = l.east.x * l.north.y - l.north.x * l.east.y
        let u = (l.north.y * dx - l.north.x * dy) / det / span
        let v = (l.east.x * dy - l.east.y * dx) / det / span
        // Entrance nodes use the world's 0.001 ground-unit quantization.
        assert_true(
          (u.abs().max(v.abs()) - 0.5).abs() * span < 0.002,
          msg="lot=\{l.id} xy=\{l.x},\{l.y} size=\{l.size} entry=\{l.entrance.x},\{l.entrance.y} uv=\{u},\{v}",
        )
        assert_true(
          c.roads.any(r => {
            @world_frontier.distance(
              @world_frontier.nearest_on(r, l.frontage),
              l.frontage,
            ) <
            0.002
          }),
        )
        assert_false(core.contains({ x: l.x.to_double(), y: l.y.to_double(), }))
        for dy in 0..<=l.size {
          for dx in 0..<=l.size {
            assert_false(
              @world_frontier.mouth_water(mouths, {
                x: (l.x + dx).to_double(),
                y: (l.y + dy).to_double(),
              }),
            )
          }
        }
      }
    }
  }
  assert_true(count > 20)
}

///|
test "river continuation retains measured edge width and incoming direction" {
  let m : @world_frontier.Mouth = {
    point: { x: 235, y: 144, },
    normal: { x: 0, y: 1, },
    radius: 14,
    drift: 0.75,
  }
  assert_eq(m.center_at(0), m.point)
  assert_eq(m.radius_at(0), 14)
  let p = m.center_at(0.001)
  assert_true(((p.x - m.point.x) / 0.001 + 0.75).abs() < 0.001)
  assert_true(((p.y - m.point.y) / 0.001 - 1).abs() < 0.001)
}
