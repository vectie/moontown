///|
pub(all) struct Point {
  x : Double
  y : Double
} derive(Eq, Debug)

///|
priv struct Sample {
  point : Point
  bridge : Bool
}

///|
/// Design-space deformation, never a new geographic calibration. The fixed
/// perimeter and positive triangle areas prevent folds in this regular mesh.
pub struct Field {
  offsets : Array[Point]
  pub before_rms : Double
  pub after_rms : Double
  pub iterations : Int
}

///|
pub fn identity() -> Field {
  {
    offsets: Array::make(33 * 19, { x: 0.0, y: 0.0 }),
    before_rms: 0.0,
    after_rms: 0.0,
    iterations: 0,
  }
}

///|
fn triangle(p : Point) -> Array[(Int, Double)] {
  let cx = (p.x / 8.0).to_int().max(0).min(31)
  let cy = (p.y / 8.0).to_int().max(0).min(17)
  let u = (p.x / 8.0 - cx.to_double()).max(0.0).min(1.0)
  let v = (p.y / 8.0 - cy.to_double()).max(0.0).min(1.0)
  let a = cy * 33 + cx
  if u >= v {
    [(a, 1.0 - u), (a + 1, u - v), (a + 34, v)]
  } else {
    [(a, 1.0 - v), (a + 34, u), (a + 33, v - u)]
  }
}

///|
pub fn Field::project(self : Field, p : Point) -> Point {
  let mut x = p.x
  let mut y = p.y
  for entry in triangle(p) {
    let (index, weight) = entry
    x += self.offsets[index].x * weight
    y += self.offsets[index].y * weight
  }
  { x, y }
}

///|
/// Split at every mesh boundary so a straight source segment maps exactly to
/// a piecewise-linear path. Merely warping endpoints would cut across bends.
pub fn Field::segment(self : Field, a : Point, b : Point) -> Array[Point] {
  let cuts : Array[Double] = [0.0, 1.0]
  for pair in [(a.x, b.x), (a.y, b.y), (a.x - a.y, b.x - b.y)] {
    let (start, finish) = pair
    if (finish - start).abs() < 0.0000001 {
      continue
    }
    for k in -18..<=32 {
      let t = (k.to_double() * 8.0 - start) / (finish - start)
      if t > 0.0000001 && t < 0.9999999 {
        cuts.push(t)
      }
    }
  }
  cuts.sort()
  let result : Array[Point] = []
  let mut previous = -1.0
  for t in cuts {
    if t - previous > 0.0000001 {
      result.push(
        self.project({ x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t }),
      )
      previous = t
    }
  }
  result
}

///|
fn distance2(a : Point, b : Point) -> Double {
  (a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y)
}

///|
fn area(a : Point, b : Point, c : Point) -> Double {
  ((b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)) / 64.0
}

///|
fn mesh_point(offsets : Array[Point], i : Int) -> Point {
  {
    x: (i % 33 * 8).to_double() + offsets[i].x,
    y: (i / 33 * 8).to_double() + offsets[i].y,
  }
}

///|
fn safe_vertex(offsets : Array[Point], i : Int) -> Bool {
  let x = i % 33
  let y = i / 33
  if offsets[i].x * offsets[i].x + offsets[i].y * offsets[i].y > 100.0 {
    return false
  }
  for cy in (y - 1).max(0)..<=y.min(17) {
    for cx in (x - 1).max(0)..<=x.min(31) {
      let a = cy * 33 + cx
      if area(
          mesh_point(offsets, a),
          mesh_point(offsets, a + 1),
          mesh_point(offsets, a + 34),
        ) <
        0.4 ||
        area(
          mesh_point(offsets, a),
          mesh_point(offsets, a + 34),
          mesh_point(offsets, a + 33),
        ) <
        0.4 {
        return false
      }
    }
  }
  true
}

///|
pub fn Field::minimum_area(self : Field) -> Double {
  let mut result = 1.0
  for y in 0..<18 {
    for x in 0..<32 {
      let a = self.project({ x: (x * 8).to_double(), y: (y * 8).to_double() })
      let b = self.project({
        x: ((x + 1) * 8).to_double(),
        y: (y * 8).to_double(),
      })
      let c = self.project({
        x: ((x + 1) * 8).to_double(),
        y: ((y + 1) * 8).to_double(),
      })
      let d = self.project({
        x: (x * 8).to_double(),
        y: ((y + 1) * 8).to_double(),
      })
      result = result.min(area(a, b, c)).min(area(a, c, d))
    }
  }
  result
}

///|
pub fn Field::maximum_displacement(self : Field) -> Double {
  self.offsets.fold(init=0.0, (n, p) => n.max((p.x * p.x + p.y * p.y).sqrt()))
}

///|
/// Residual centerline conflicts against the unchanged design water mask.
/// Excludes recorded source bridge segments; does not invent new bridges.
pub fn Field::water_conflict_edges(
  self : Field,
  source : Json,
  terrain : Json,
) -> Int {
  let terrain_rows = rows(terrain)
  if terrain_rows.length() != 144 ||
    terrain_rows.any(row => row.length() != 256) {
    return 0
  }
  let mut count = 0
  for edge in values(property(property(source, "graph"), "edges")) {
    let path = values(property(edge, "pathMillis"))
    let spans = values(property(edge, "bridgeSpans"))
    let mut conflict = false
    for index in 1..<path.length() {
      if spans.any(span => {
          number(property(span, "fromIndex")).to_int() <= index - 1 &&
          number(property(span, "toIndex")).to_int() >= index
        }) {
        continue
      }
      let a = point(path[index - 1])
      let b = point(path[index])
      let steps = ((a.x - b.x).abs().max((a.y - b.y).abs()) * 10.0).to_int() + 1
      for step in 0..<steps {
        let t = (step.to_double() + 0.5) / steps.to_double()
        let p = self.project({
          x: a.x + (b.x - a.x) * t,
          y: a.y + (b.y - a.y) * t,
        })
        let x = (p.x + 0.5).to_int().max(0).min(255)
        let y = (p.y + 0.5).to_int().max(0).min(143)
        if terrain_rows[y][x] == 'r' ||
          terrain_rows[y][x] == 'l' ||
          terrain_rows[y][x] == 'b' {
          conflict = true
          break
        }
      }
      if conflict {
        break
      }
    }
    if conflict {
      count += 1
    }
  }
  count
}

///|
fn property(value : Json, key : String) -> Json {
  match value {
    Object(fields) => fields.get(key).unwrap_or(Json::null())
    _ => Json::null()
  }
}

///|
fn values(value : Json) -> Array[Json] {
  match value {
    Array(items) => items
    _ => []
  }
}

///|
fn number(value : Json) -> Double {
  match value {
    Number(n, ..) => n
    _ => 0.0
  }
}

///|
fn point(value : Json) -> Point {
  match value {
    Array([x, y, ..]) => { x: number(x) / 1000.0, y: number(y) / 1000.0 }
    _ => { x: 0.0, y: 0.0 }
  }
}

///|
fn rows(value : Json) -> Array[String] {
  values(property(value, "rows")).map(v => {
    match v {
      String(s) => s
      _ => ""
    }
  })
}

///|
fn nearest_grid(
  roads : Array[String],
  labels : Array[String],
  bridge : Bool,
) -> Array[Point?] {
  let grid : Array[Point?] = Array::make(256 * 144, None)
  for y in 0..<144 {
    for x in 0..<256 {
      let code = roads[y][x]
      let wet = labels[y][x] == 'r' || labels[y][x] == 'l'
      if (bridge && code == 'b') ||
        (!bridge && (code == 'M' || code == 'R') && !wet) {
        grid[y * 256 + x] = Some({ x: x.to_double(), y: y.to_double() })
      }
    }
  }
  // Symmetric nearest-seed propagation; target cells remain fixed throughout.
  for _ in 0..<2 {
    for reverse in [false, true] {
      for ordinal in 0..<(256 * 144) {
        let index = if reverse { 256 * 144 - 1 - ordinal } else { ordinal }
        let x = index % 256
        let y = index / 256
        let p : Point = { x: x.to_double(), y: y.to_double() }
        let mut best = match grid[index] {
          Some(q) => distance2(p, q)
          None => 1000000000.0
        }
        for neighbor in [(-1, 0), (1, 0), (0, -1), (0, 1), (-1, -1), (1, 1)] {
          let (dx, dy) = neighbor
          let nx = x + dx
          let ny = y + dy
          if nx < 0 || nx >= 256 || ny < 0 || ny >= 144 {
            continue
          }
          if grid[ny * 256 + nx] is Some(q) {
            let d = distance2(p, q)
            if d < best {
              best = d
              grid[index] = Some(q)
            }
          }
        }
      }
    }
  }
  grid
}

///|
fn target(p : Point, grid : Array[Point?]) -> Point? {
  let x = (p.x + 0.5).to_int().max(0).min(255)
  let y = (p.y + 0.5).to_int().max(0).min(143)
  match grid[y * 256 + x] {
    Some(q) if distance2(p, q) <= 144.0 => Some(q)
    _ => None
  }
}

///|
fn score(
  field : Field,
  samples : Array[Sample],
  land : Array[Point?],
  bridges : Array[Point?],
) -> Double {
  let mut total = 0.0
  let mut count = 0.0
  for sample in samples {
    let p = field.project(sample.point)
    let grid = if sample.bridge { bridges } else { land }
    let weight = if sample.bridge { 4.0 } else { 1.0 }
    total += weight *
      (match target(p, grid) {
        Some(q) => distance2(p, q)
        None => 144.0
      })
    count += weight
  }
  if count > 0.0 {
    (total / count).sqrt()
  } else {
    0.0
  }
}

///|
/// Fit current roads to designed corridors with a bounded, non-folding field.
/// Nearby corridor matches are geometric candidates, not verified identities.
/// Distant/ambiguous roads are retained; consumers must expose residuals.
pub fn fit(source : Json, design : Json, terrain : Json) -> Field {
  let road_rows = rows(design)
  let terrain_rows = rows(terrain)
  if road_rows.length() != 144 ||
    terrain_rows.length() != 144 ||
    road_rows.any(row => row.length() != 256) ||
    terrain_rows.any(row => row.length() != 256) {
    return identity()
  }
  let samples : Array[Sample] = []
  for edge in values(property(property(source, "graph"), "edges")) {
    let path = values(property(edge, "pathMillis"))
    let spans = values(property(edge, "bridgeSpans"))
    for index in 1..<path.length() {
      let a = point(path[index - 1])
      let b = point(path[index])
      let bridge = spans.any(span => {
        number(property(span, "fromIndex")).to_int() <= index - 1 &&
        number(property(span, "toIndex")).to_int() >= index
      })
      let steps = (distance2(a, b).sqrt() / 1.5).to_int() + 1
      for step in 0..<steps {
        let t = (step.to_double() + 0.5) / steps.to_double()
        samples.push({
          point: { x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t },
          bridge,
        })
      }
    }
  }
  let land = nearest_grid(road_rows, terrain_rows, false)
  let bridges = nearest_grid(road_rows, terrain_rows, true)
  let mut field = identity()
  let initial = score(field, samples, land, bridges)
  let mut best_score = initial
  for iteration in 0..<60 {
    let fx = Array::make(33 * 19, 0.0)
    let fy = Array::make(33 * 19, 0.0)
    let weights = Array::make(33 * 19, 0.0)
    for sample in samples {
      let p = field.project(sample.point)
      if target(p, if sample.bridge { bridges } else { land }) is Some(q) {
        for entry in triangle(sample.point) {
          let (index, weight) = entry
          let w = weight * (if sample.bridge { 4.0 } else { 1.0 })
          fx[index] += (q.x - p.x) * w
          fy[index] += (q.y - p.y) * w
          weights[index] += w
        }
      }
    }
    let deltas = Array::make(33 * 19, { x: 0.0, y: 0.0 })
    for y in 1..<18 {
      for x in 1..<32 {
        let i = y * 33 + x
        let current = field.offsets[i]
        let mut nx = 0.0
        let mut ny = 0.0
        for n in [i - 1, i + 1, i - 33, i + 33] {
          nx += field.offsets[n].x / 4.0
          ny += field.offsets[n].y / 4.0
        }
        let dx = fx[i] / weights[i].max(1.0) * 0.35 +
          (nx - current.x) * 0.8 -
          current.x * 0.002
        let dy = fy[i] / weights[i].max(1.0) * 0.35 +
          (ny - current.y) * 0.8 -
          current.y * 0.002
        let scale = (0.35 / (dx * dx + dy * dy).sqrt().max(0.000001)).min(1.0)
        deltas[i] = { x: dx * scale, y: dy * scale }
      }
    }
    let mut accepted = false
    let mut rate = 1.0
    for _ in 0..<9 {
      let offsets = field.offsets.map(p => p)
      for i in 0..<offsets.length() {
        let previous = offsets[i]
        let mut local_rate = rate
        for _ in 0..<10 {
          offsets[i] = {
            x: previous.x + deltas[i].x * local_rate,
            y: previous.y + deltas[i].y * local_rate,
          }
          if safe_vertex(offsets, i) {
            break
          }
          offsets[i] = previous
          local_rate /= 2.0
        }
      }
      let candidate : Field = {
        offsets,
        before_rms: initial,
        after_rms: best_score,
        iterations: iteration + 1,
      }
      if candidate.minimum_area() >= 0.4 &&
        candidate.maximum_displacement() <= 10.0 {
        let next_score = score(candidate, samples, land, bridges)
        if next_score < best_score - 0.000001 {
          best_score = next_score
          field = { ..candidate, after_rms: next_score }
          accepted = true
          break
        }
      }
      rate /= 2.0
    }
    if !accepted {
      break
    }
  }
  { ..field, before_rms: initial, after_rms: best_score }
}
