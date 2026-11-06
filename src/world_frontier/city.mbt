///|
/// One geographic planning frame, independent of loading chunks. `south` is
/// the projected south axis, not screen-down; both axes retain map shear.
pub(all) struct CityFrame {
  origin : Point
  east : Point
  south : Point
} derive(Debug, Eq)

///|
pub fn CityFrame::ground(self : CityFrame, u : Double, v : Double) -> Point {
  point(
    self.origin.x + self.east.x * u + self.south.x * v,
    self.origin.y + self.east.y * u + self.south.y * v,
  )
}

///|
pub fn CityFrame::plan(self : CityFrame, p : Point) -> Point {
  let x = p.x - self.origin.x
  let y = p.y - self.origin.y
  let d = self.east.x * self.south.y - self.south.x * self.east.y
  {
    x: (self.south.y * x - self.south.x * y) / d,
    y: (self.east.x * y - self.east.y * x) / d,
  }
}

///|
// A street's coordinate depends on its global index only. Unequal blocks do
// not imply crooked roads or restart their pattern at a loading boundary.
fn city_axis(seed : Int32, i : Int32, axis : Int32) -> Double {
  (i * 24 + sample(seed, i, axis, 712) % 9 - 4).to_double()
}

///|
fn city_segment(rect : Rect, a : Point, b : Point) -> (Double, Double)? {
  let mut lo = 0.0
  let mut hi = 1.0
  for
    (p, d, min, max) in [
      (a.x, b.x - a.x, rect.min_x, rect.max_x),
      (a.y, b.y - a.y, rect.min_y, rect.max_y),
    ] {
    if d.abs() < 0.0000001 {
      if p < min || p > max {
        return None
      }
    } else {
      let t0 = (min - p) / d
      let t1 = (max - p) / d
      lo = lo.max(t0.min(t1))
      hi = hi.min(t0.max(t1))
      if lo > hi {
        return None
      }
    }
  }
  Some((lo, hi))
}

///|
fn city_lerp(a : Point, b : Point, t : Double) -> Point {
  point(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t)
}

///|
fn city_bridge(r : Road, mouths : Array[Mouth]) -> Bool {
  let length = distance(r.a, r.b).max(0.001)
  let nx = -(r.b.y - r.a.y) / length * (r.width / 2 + 0.5)
  let ny = (r.b.x - r.a.x) / length * (r.width / 2 + 0.5)
  for t in [0.0, 0.5, 1.0] {
    for side in [-1.0, 0.0, 1.0] {
      let p = city_lerp(r.a, r.b, t)
      if mouth_water(mouths, { x: p.x + nx * side, y: p.y + ny * side, }) {
        return true
      }
    }
  }
  false
}

///|
fn city_line(
  roads : Array[Road],
  a : Point,
  b : Point,
  width : Double,
  bounds : Rect,
  core : Rect,
  mouths : Array[Mouth],
) -> Unit {
  guard city_segment(bounds, a, b) is Some((lo, hi)) else { return }
  let forbidden : Rect = {
    min_x: core.min_x - 5,
    min_y: core.min_y - 5,
    max_x: core.max_x + 5,
    max_y: core.max_y + 5,
  }
  let intervals = match city_segment(forbidden, a, b) {
    Some((s, t)) => [(lo, hi.min(s)), (lo.max(t), hi)]
    None => [(lo, hi)]
  }
  for (from, to) in intervals {
    if to - from < 0.00001 {
      continue
    }
    // Global subdivision before clipping: bank coverage and node identity do
    // not depend on which chunk generated the segment first.
    let steps = (distance(a, b) / 2).ceil().to_int().max(1)
    for i in 0..<steps {
      let s = from.max(i.to_double() / steps.to_double())
      let t = to.min((i + 1).to_double() / steps.to_double())
      if t <= s {
        continue
      }
      let r : Road = {
        a: city_lerp(a, b, s),
        b: city_lerp(a, b, t),
        width,
        bridge: false,
      }
      if r.a != r.b {
        roads.push({ ..r, bridge: city_bridge(r, mouths), })
      }
    }
  }
}

///|
fn city_roads(
  seed : Int32,
  cx : Int32,
  cy : Int32,
  frame : CityFrame,
  core : Rect,
  mouths : Array[Mouth],
) -> Array[Road] {
  let bounds : Rect = {
    min_x: (cx * 32).to_double(),
    min_y: (cy * 32).to_double(),
    max_x: (cx * 32 + 32).to_double(),
    max_y: (cy * 32 + 32).to_double(),
  }
  let corners = [
    Point::{ x: bounds.min_x, y: bounds.min_y, },
    { x: bounds.max_x, y: bounds.min_y, },
    { x: bounds.min_x, y: bounds.max_y, },
    { x: bounds.max_x, y: bounds.max_y, },
  ].map(p => frame.plan(p))
  let x0 = (corners.fold(init=1.0e12, (n, p) => n.min(p.x)) / 24)
    .floor()
    .to_int() -
    1
  let y0 = (corners.fold(init=1.0e12, (n, p) => n.min(p.y)) / 24)
    .floor()
    .to_int() -
    1
  let x1 = (corners.fold(init=-1.0e12, (n, p) => n.max(p.x)) / 24)
    .ceil()
    .to_int() +
    1
  let y1 = (corners.fold(init=-1.0e12, (n, p) => n.max(p.y)) / 24)
    .ceil()
    .to_int() +
    1
  let roads : Array[Road] = []
  for j in y0..<y1 {
    for i in x0..<x1 {
      let u = city_axis(seed, i, 0)
      let v = city_axis(seed, j, 1)
      let p = frame.ground(u, v)
      city_line(
        roads,
        p,
        frame.ground(city_axis(seed, i + 1, 0), v),
        if j % 3 == 0 {
          0.48
        } else {
          0.24
        },
        bounds,
        core,
        mouths,
      )
      // Occasional merged blocks / T junctions, never per-chunk hubs.
      if i % 3 == 0 || sample(seed, i, j, 719) % 100 < 68 {
        city_line(
          roads,
          p,
          frame.ground(u, city_axis(seed, j + 1, 1)),
          if i % 3 == 0 {
            0.48
          } else {
            0.24
          },
          bounds,
          core,
          mouths,
        )
      }
    }
  }
  roads
}

///|
/// Planned roads and parcels are clipped for loading, not designed per chunk.
/// The authored core remains an obstacle; only verified gate roads join it.
pub fn city(
  seed : Int32,
  cx : Int32,
  cy : Int32,
  frame : CityFrame,
  core : Rect,
  gates : Array[Road],
  mouths : Array[Mouth],
) -> Chunk {
  let roads = city_roads(seed, cx, cy, frame, core, mouths)
  let bounds : Rect = {
    min_x: (cx * 32).to_double(),
    min_y: (cy * 32).to_double(),
    max_x: (cx * 32 + 32).to_double(),
    max_y: (cy * 32 + 32).to_double(),
  }
  for r in gates {
    if city_segment(bounds, r.a, r.b) is Some((lo, hi)) && hi - lo > 0.00001 {
      roads.push({
        ..r,
        a: city_lerp(r.a, r.b, lo),
        b: city_lerp(r.a, r.b, hi),
      })
    }
  }
  // World-coordinate candidates may straddle chunk edges. Owning the centre
  // avoids the old regular empty strips caused by inset chunk reservations.
  let lots : Array[Lot] = []
  for y in (cy * 8)..<(cy * 8 + 8) {
    for x in (cx * 8)..<(cx * 8 + 8) {
      let span = if sample(seed, x, y, 732) % 5 == 0 { 3 } else { 4 }
      let offset = if span % 2 == 0 { 0.0 } else { 0.5 }
      let p = point(
        (x * 4 + 2).to_double() + offset,
        (y * 4 + 2).to_double() + offset,
      )
      if p.x < bounds.min_x ||
        p.x >= bounds.max_x ||
        p.y < bounds.min_y ||
        p.y >= bounds.max_y {
        continue
      }
      let plan = frame.plan(p)
      let di = (plan.x / 48).floor().to_int()
      let dj = (plan.y / 48).floor().to_int()
      // Keep shared pocket parks, not independently missing houses in every row.
      if sample(seed, di, dj, 730) % 8 == 0 {
        continue
      }
      if core.distance(p) < span.to_double() * 0.72 + 1 ||
        mouth_water(mouths, p) {
        continue
      }
      let mut near = p
      let mut axis = frame.east
      let mut best = 1.0e12
      for r in roads {
        let q = nearest_on(r, p)
        let d = distance(q, p)
        if d < best {
          near = q
          best = d
          axis = point(r.b.x - r.a.x, r.b.y - r.a.y)
        }
      }
      if best < span.to_double() * 0.5 + 0.35 || best > 6.5 {
        continue
      }
      let reservation : Rect = {
        min_x: p.x - span.to_double() / 2 - 0.25,
        min_y: p.y - span.to_double() / 2 - 0.25,
        max_x: p.x + span.to_double() / 2 + 0.25,
        max_y: p.y + span.to_double() / 2 + 0.25,
      }
      if roads.any(r => city_segment(reservation, r.a, r.b) is Some(_)) {
        continue
      }
      let mut wet = false
      for dy in -3..<=3 {
        for dx in -3..<=3 {
          if mouth_water(
              mouths,
              point(p.x + dx.to_double(), p.y + dy.to_double()),
            ) {
            wet = true
          }
        }
      }
      if wet {
        continue
      }
      let (east, north) = frontage_axes(
        frame.east,
        point(-frame.south.x, -frame.south.y),
        axis,
      )
      let entrance = frontage_entry(p, east, north, span, near)
      if distance(entrance, near) > 2.4 {
        continue
      }
      for k in 0..<=12 {
        if mouth_water(mouths, city_lerp(entrance, near, k.to_double() / 12)) {
          wet = true
        }
      }
      if wet {
        continue
      }
      lots.push({
        id: "frontier-city-v3:\{seed}:\{x}:\{y}",
        x: (p.x - span.to_double() / 2).floor().to_int(),
        y: (p.y - span.to_double() / 2).floor().to_int(),
        size: span,
        style: city_building_style(seed, di, dj, x, y),
        variant: sample(seed, x, y, 735) % 3,
        entrance,
        frontage: near,
        east,
        north,
      })
    }
  }
  let plants : Array[Plant] = []
  // Shared fine lattice with jitter, no one-unit gap around a loading chunk.
  for y in (cy * 16)..<(cy * 16 + 16) {
    for x in (cx * 16)..<(cx * 16 + 16) {
      let p = point(
        (x * 2).to_double() + (sample(seed, x, y, 740) % 180).to_double() / 100,
        (y * 2).to_double() + (sample(seed, x, y, 741) % 180).to_double() / 100,
      )
      if core.contains(p, pad=0.7) || mouth_water(mouths, p) {
        continue
      }
      let density = 0.20 + 0.14 * (1.0 - core.distance(p) / 20).max(0)
      if woodland(p) < 0.3 &&
        (sample(seed, x, y, 742) % 100).to_double() / 100 > density {
        continue
      }
      if roads.any(r => distance(nearest_on(r, p), p) < 1.4) ||
        gates.any(r => distance(nearest_on(r, p), p) < 1.4) ||
        lots.any(l => {
          p.x > l.x.to_double() - 1 &&
          p.x < (l.x + l.size).to_double() + 1 &&
          p.y > l.y.to_double() - 1 &&
          p.y < (l.y + l.size).to_double() + 1
        }) {
        continue
      }
      plants.push({
        point: p,
        kind: if sample(seed, x, y, 745) % 5 < 3 {
          0
        } else {
          sample(
            seed,
            (x.to_double() / 12).floor().to_int(),
            (y.to_double() / 12).floor().to_int(),
            743,
          ) %
          6
        },
        size: 1.0 + (sample(seed, x, y, 744) % 40).to_double() / 100,
      })
    }
  }
  let hub = roads
    .get(0)
    .map(r => r.a)
    .unwrap_or(point((cx * 32 + 16).to_double(), (cy * 32 + 16).to_double()))
  { x: cx, y: cy, theme: "北京街坊", hub, arms: 15, roads, lots, plants, }
}

///|
/// Join a verified exit to an existing planned road node, not a chunk centre.
pub fn city_gate(
  seed : Int32,
  start : Point,
  direction : Point,
  frame : CityFrame,
  core : Rect,
  mouths : Array[Mouth],
) -> Array[Road] {
  let cx = coordinate(start.x + direction.x * 20)
  let cy = coordinate(start.y + direction.y * 20)
  let mut best = 1.0e12
  let mut end = start
  for y in (cy - 1)..<=(cy + 1) {
    for x in (cx - 1)..<=(cx + 1) {
      for r in city_roads(seed, x, y, frame, core, mouths) {
        for p in [r.a, r.b] {
          let d = distance(start, p)
          let along = (p.x - start.x) * direction.x +
            (p.y - start.y) * direction.y
          if d < 9 || along < d * 0.65 || core.distance(p) < 9 {
            continue
          }
          let score = d + (d - along) * 2
          if score < best {
            best = score
            end = p
          }
        }
      }
    }
  }
  if end == start {
    return []
  }
  gate_roads(start, direction, end, mouths)
}
