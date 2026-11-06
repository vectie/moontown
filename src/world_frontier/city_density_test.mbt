///|
test "street district density and architectural mix sample" {
  let styles : Map[String, Int32] = Map([])
  let designs : Map[String, Bool] = Map([])
  let widths : Map[Int32, Bool] = Map([])
  let mut count = 0
  for y in -6..<4 {
    for x in -10..<0 {
      let c = @world_frontier.city(20261028, x, y, frame, core, [], [])
      let east = @world_frontier.city(20261028, x + 1, y, frame, core, [], [])
      let south = @world_frontier.city(20261028, x, y + 1, frame, core, [], [])
      for l in c.lots {
        count += 1
        styles[l.style] = styles.get(l.style).unwrap_or(0) + 1
        designs["\{l.style}:\{l.variant}"] = true
        widths[l.size] = true
        assert_true(@world_frontier.distance(l.entrance, l.frontage) <= 2.401)
        for other in c.lots {
          if l.id != other.id {
            assert_true(
              l.x + l.size <= other.x ||
              other.x + other.size <= l.x ||
              l.y + l.size <= other.y ||
              other.y + other.size <= l.y,
            )
          }
        }
        for neighbor in [east, south] {
          for other in neighbor.lots {
            assert_true(
              l.x + l.size <= other.x ||
              other.x + other.size <= l.x ||
              l.y + l.size <= other.y ||
              other.y + other.size <= l.y,
            )
          }
        }
      }
    }
  }
  println(
    "district sample: \{count} lots / 100 chunks; \{styles.length()} families; \{designs.length()} designs; \{widths.length()} sizes",
  )
  assert_true(count >= 600 && count <= 900)
  assert_eq(styles.length(), 8)
  assert_eq(designs.length(), 24)
  assert_eq(widths.length(), 2)
}
