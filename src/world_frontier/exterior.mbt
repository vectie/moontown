///|
/// An authored footprint is immutable. Procedural geometry lives outside it.
pub(all) struct Rect {
  min_x : Double
  min_y : Double
  max_x : Double
  max_y : Double
} derive(Debug, Eq)

///|
pub fn Rect::contains(self : Rect, p : Point, pad~ : Double = 0) -> Bool {
  p.x >= self.min_x - pad &&
  p.x <= self.max_x + pad &&
  p.y >= self.min_y - pad &&
  p.y <= self.max_y + pad
}

///|
pub fn Rect::distance(self : Rect, p : Point) -> Double {
  let dx = (self.min_x - p.x).max(0).max(p.x - self.max_x)
  let dy = (self.min_y - p.y).max(0).max(p.y - self.max_y)
  (dx * dx + dy * dy).sqrt()
}

///|
/// Round outwards, never shrink the protected core to fit a generation grid.
pub fn Rect::chunk_envelope(self : Rect) -> Rect {
  {
    min_x: (self.min_x / 32).floor() * 32,
    min_y: (self.min_y / 32).floor() * 32,
    max_x: (self.max_x / 32).ceil() * 32,
    max_y: (self.max_y / 32).ceil() * 32,
  }
}

///|
/// Continue an observed river mouth outwards; bending starts with zero tangent.
pub(all) struct Mouth {
  point : Point
  normal : Point
  radius : Double
  drift : Double
} derive(Debug, Eq)

///|
pub fn mouth_water(mouths : Array[Mouth], p : Point) -> Bool {
  mouths.any(m => {
    let dx = p.x - m.point.x
    let dy = p.y - m.point.y
    let along = dx * m.normal.x + dy * m.normal.y
    if along < 0 {
      return false
    }
    let center = m.center_at(along)
    let across = -(p.x - center.x) * m.normal.y + (p.y - center.y) * m.normal.x
    across.abs() < m.radius_at(along)
  })
}

///|
/// Mouth-specific phases avoid parallel canals. The ease-in keeps the exact
/// authored mouth and tangent; wider outlets gradually become river channels.
pub fn Mouth::center_at(self : Mouth, along : Double) -> Point {
  let d = along.max(0)
  let phase = self.point.x * 0.031 + self.point.y * 0.047
  let ease = 1.0 - @math.exp(-d / 28.0)
  let amplitude = (self.radius * 2.6 + 7.0).min(32.0)
  let bend = self.drift * d * @math.exp(-d / 110.0) +
    ease *
    ease *
    amplitude *
    (@math.sin(d / 55.0 + phase) - @math.sin(phase) + 0.3 * @math.sin(d / 23.0))
  {
    x: self.point.x + d * self.normal.x - bend * self.normal.y,
    y: self.point.y + d * self.normal.y + bend * self.normal.x,
  }
}

///|
pub fn Mouth::radius_at(self : Mouth, along : Double) -> Double {
  let d = along.max(0)
  let taper = 0.5 + 0.5 * @math.exp(-d / 70.0)
  self.radius *
  taper *
  (1.0 + 0.15 * (1.0 - @math.exp(-d / 22.0)) * @math.sin(d / 37.0))
}

///|
/// Only extensions outside the core. Gate geometry is supplied by the adapter
/// from verified road exits, not inferred from nearby screen-space lines.
pub fn exterior(
  source : Chunk,
  core : Rect,
  gates : Array[Road],
  mouths : Array[Mouth],
) -> Chunk {
  let envelope = core.chunk_envelope()
  let roads : Array[Road] = []
  // Reject the complete inward arm, not individual vertices (no jagged shifts).
  for arm in 0..<4 {
    if (source.arms & (1 << arm)) == 0 {
      continue
    }
    let from = arm * 12
    if source.roads.length() < from + 12 {
      continue
    }
    let a = source.roads[from].a
    let b = source.roads[from + 11].b
    if envelope.contains(a, pad=0.01) || envelope.contains(b, pad=0.01) {
      continue
    }
    for i in from..<(from + 12) {
      let r = source.roads[i]
      roads.push({ ..r, bridge: exterior_bridge(r, mouths), })
    }
  }
  for road in gates {
    let mid = point((road.a.x + road.b.x) / 2, (road.a.y + road.b.y) / 2)
    if coordinate(mid.x) == source.x && coordinate(mid.y) == source.y {
      roads.push(road)
    }
  }
  let lots = source.lots.filter(l => {
    let center = point(
      l.x.to_double() + l.size.to_double() / 2,
      l.y.to_double() + l.size.to_double() / 2,
    )
    if core.distance(center) < l.size.to_double() + 6 {
      return false
    }
    if !roads.any(r => distance(nearest_on(r, l.frontage), l.frontage) < 0.002) {
      return false
    }
    for y in (l.y - 1)..<=(l.y + l.size + 1) {
      for x in (l.x - 1)..<=(l.x + l.size + 1) {
        if mouth_water(mouths, point(x.to_double(), y.to_double())) {
          return false
        }
      }
    }
    if gates.any(r => {
        distance(nearest_on(r, center), center) < l.size.to_double() * 0.72 + 1
      }) {
      return false
    }
    for i in 0..<=20 {
      let t = i.to_double() / 20
      if mouth_water(
          mouths,
          point(
            l.entrance.x + (l.frontage.x - l.entrance.x) * t,
            l.entrance.y + (l.frontage.y - l.entrance.y) * t,
          ),
        ) {
        return false
      }
    }
    true
  })
  let plants = source.plants.filter(p => {
    !core.contains(p.point, pad=2) &&
    !mouth_water(mouths, p.point) &&
    !gates.any(r => distance(nearest_on(r, p.point), p.point) < 2)
  })
  { ..source, roads, lots, plants, }
}

///|
fn exterior_bridge(road : Road, mouths : Array[Mouth]) -> Bool {
  for i in 0..<=16 {
    let t = i.to_double() / 16
    let p = point(
      road.a.x + (road.b.x - road.a.x) * t,
      road.a.y + (road.b.y - road.a.y) * t,
    )
    for dx in [-0.8, 0.0, 0.8] {
      for dy in [-0.8, 0.0, 0.8] {
        if mouth_water(mouths, point(p.x + dx, p.y + dy)) {
          return true
        }
      }
    }
  }
  false
}

///|
pub fn gate_roads(
  start : Point,
  direction : Point,
  hub : Point,
  mouths : Array[Mouth],
) -> Array[Road] {
  let roads : Array[Road] = []
  let reach = distance(start, hub).min(8)
  curve(
    roads,
    start,
    point(start.x + direction.x * reach, start.y + direction.y * reach),
    point(hub.x - direction.x * reach, hub.y - direction.y * reach),
    hub,
  )
  roads.mapi((i, r) => {
    ..r,
    width: 0.24 + 0.4 * (i.to_double() / 11),
    bridge: exterior_bridge(r, mouths),
  })
}
