///|
/// Experimental, renderer-neutral scenery. IDs never confer runtime authority.
pub(all) struct Point {
  x : Double
  y : Double
} derive(Debug, Eq, ToJson)

///|
pub(all) struct Road {
  a : Point
  b : Point
  bridge : Bool
  width : Double
} derive(Debug, Eq, ToJson)

///|
pub(all) struct Lot {
  id : String
  x : Int32
  y : Int32
  size : Int32
  style : String
  variant : Int32
  entrance : Point
  frontage : Point
  east : Point
  north : Point
} derive(Debug, Eq, ToJson)

///|
pub(all) struct Plant {
  point : Point
  kind : Int32
  size : Double
} derive(Debug, Eq, ToJson)

///|
pub(all) struct Chunk {
  x : Int32
  y : Int32
  theme : String
  hub : Point
  arms : Int32
  roads : Array[Road]
  lots : Array[Lot]
  plants : Array[Plant]
} derive(Debug, Eq, ToJson)

///|
pub let version : String = "frontier-v1"

///|
pub let size : Int32 = 32

///|
/// This prototype uses bounded Int coordinates; no claim of infinite precision.
pub let coordinate_limit : Int32 = 32768

///|
pub fn coordinate(value : Double) -> Int32 {
  (value / size.to_double())
  .floor()
  .to_int()
  .clamp(min=-coordinate_limit, max=coordinate_limit)
}

///|
fn sample(seed : Int32, x : Int32, y : Int32, salt : Int32) -> Int32 {
  let mut h = seed.reinterpret_as_uint() ^
    (x.reinterpret_as_uint() * 374761393U) ^
    (y.reinterpret_as_uint() * 668265263U) ^
    salt.reinterpret_as_uint()
  h = (h ^ (h >> 13)) * 1274126177U
  ((h ^ (h >> 16)) & 2147483647U).reinterpret_as_int()
}

///|
pub fn node_id(p : Point) -> String {
  // Coordinates are quantized before use, not only when constructing IDs.
  "f:\{(p.x * 1000.0).round().to_int()}:\{(p.y * 1000.0).round().to_int()}"
}

///|
fn point(x : Double, y : Double) -> Point {
  { x: (x * 1000.0).round() / 1000.0, y: (y * 1000.0).round() / 1000.0, }
}

///|
pub fn river_center(channel : Int32, y : Double) -> Double {
  40.0 + channel.to_double() * 128.0 + 2.0 * @math.sin(y / 28.0)
}

///|
pub fn river_distance(p : Point) -> Double {
  // Continuous coordinate field, offset from the north/south street corridor.
  let center = river_center(0, p.y)
  let dx = p.x - center
  (dx - (dx / 128.0).round() * 128.0).abs()
}

///|
pub fn water(p : Point) -> Bool {
  river_distance(p) < 2.2
}

///|
pub fn nearest_on(road : Road, p : Point) -> Point {
  let dx = road.b.x - road.a.x
  let dy = road.b.y - road.a.y
  let length = dx * dx + dy * dy
  let t = if length < 0.000001 {
    0.0
  } else {
    (((p.x - road.a.x) * dx + (p.y - road.a.y) * dy) / length).clamp(
      min=0.0,
      max=1.0,
    )
  }
  point(road.a.x + dx * t, road.a.y + dy * t)
}

///|
pub fn distance(a : Point, b : Point) -> Double {
  ((a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y)).sqrt()
}

///|
fn curve(
  roads : Array[Road],
  a : Point,
  c : Point,
  d : Point,
  b : Point,
) -> Unit {
  let mut previous = a
  for i in 1..<=12 {
    let t = i.to_double() / 12.0
    let u = 1.0 - t
    let p = point(
      u * u * u * a.x +
      3.0 * u * u * t * c.x +
      3.0 * u * t * t * d.x +
      t * t * t * b.x,
      u * u * u * a.y +
      3.0 * u * u * t * c.y +
      3.0 * u * t * t * d.y +
      t * t * t * b.y,
    )
    // Conservatively include banks and the whole segment, not only its midpoint.
    let bridge = [
      previous,
      p,
      point((previous.x + p.x) / 2.0, (previous.y + p.y) / 2.0),
    ].any(q => river_distance(q) < 3.7)
    roads.push({ a: previous, b: p, bridge, width: 1.4, })
    previous = p
  }
}

///|
/// Deterministic layout with identical portals and tangent directions on each
/// shared boundary. Candidate footprints stay inside their owning chunk.
pub fn generate(
  seed : Int32,
  cx : Int32,
  cy : Int32,
  organic~ : Bool = false,
) -> Chunk {
  let cx = cx.clamp(min=-coordinate_limit, max=coordinate_limit)
  let cy = cy.clamp(min=-coordinate_limit, max=coordinate_limit)
  let x = (cx * size).to_double()
  let y = (cy * size).to_double()
  let district_x = (cx.to_double() / 2).floor().to_int()
  let district_y = (cy.to_double() / 2).floor().to_int()
  let theme = ["创作者院落", "河岸生活街", "科学花园"][sample(
      seed,
      if organic {
        district_x
      } else {
        cx
      },
      if organic {
        district_y
      } else {
        cy
      },
      1,
    ) %
    3]
  let hub = point(
    x +
    (if organic { 9.0 } else { 14.0 }) +
    (sample(seed, cx, cy, 2) % (if organic { 15 } else { 5 })).to_double(),
    y +
    (if organic { 9.0 } else { 14.0 }) +
    (sample(seed, cx, cy, 3) % (if organic { 15 } else { 5 })).to_double(),
  )
  let west = if organic {
    8.0 + (sample(seed, cx - 1, cy, 901) % 17).to_double()
  } else {
    16.0
  }
  let east = if organic {
    8.0 + (sample(seed, cx, cy, 901) % 17).to_double()
  } else {
    16.0
  }
  let north = if organic {
    8.0 + (sample(seed, cx, cy - 1, 902) % 17).to_double()
  } else {
    16.0
  }
  let south = if organic {
    8.0 + (sample(seed, cx, cy, 902) % 17).to_double()
  } else {
    16.0
  }
  // Continuous east-west lanes plus regularly guaranteed cross-lanes keep the
  // regional graph connected. Other shared edges create T junctions and parks.
  let arms = if !organic {
    15
  } else {
    3 +
    (if cx % 4 == 0 || sample(seed, cx, cy - 1, 908) % 100 < 38 {
      4
    } else {
      0
    }) +
    (if cx % 4 == 0 || sample(seed, cx, cy, 908) % 100 < 38 { 8 } else { 0 })
  }
  let roads : Array[Road] = []
  curve(
    roads,
    point(x, y + west),
    point(x + 6, y + west),
    point(hub.x - 6, hub.y),
    hub,
  )
  curve(
    roads,
    hub,
    point(hub.x + 6, hub.y),
    point(x + 26, y + east),
    point(x + 32, y + east),
  )
  curve(
    roads,
    point(x + north, y),
    point(x + north, y + 6),
    point(hub.x, hub.y - 6),
    hub,
  )
  curve(
    roads,
    hub,
    point(hub.x, hub.y + 6),
    point(x + south, y + 26),
    point(x + south, y + 32),
  )
  if organic {
    for i, r in roads {
      roads[i] = {
        ..r,
        width: if i < 24 {
          if cy % 3 == 0 {
            0.8
          } else {
            0.48
          }
        } else if cx % 4 == 0 {
          0.72
        } else {
          0.34
        },
      }
    }
  }
  let lots : Array[Lot] = []
  let styles = match theme {
    "创作者院落" => ["courtyard", "row", "lowrise"]
    "河岸生活街" => ["lowrise", "row", "block"]
    _ => ["campus", "civic", "lowrise"]
  }
  for iy in 0..<4 {
    for ix in 0..<4 {
      let salt = ix + iy * 4
      if organic &&
        (
          sample(seed, district_x, district_y, 910) % 5 == 0 ||
          sample(seed, cx, cy, salt + 100) % 100 < 35
        ) {
        continue
      }
      if sample(seed, cx, cy, salt + 100) % 6 == 0 {
        continue
      }
      let lx = cx * size +
        2 +
        ix * 7 +
        (if organic { sample(seed, cx, cy, salt + 501) % 3 - 1 } else { 0 })
      let ly = cy * size +
        2 +
        iy * 7 +
        (if organic { sample(seed, cx, cy, salt + 502) % 3 - 1 } else { 0 })
      let span = 4 + sample(seed, cx, cy, salt + 200) % 2
      let center = point(
        lx.to_double() + span.to_double() / 2.0,
        ly.to_double() + span.to_double() / 2.0,
      )
      let mut wet = false
      for py in (ly - 1)..<=(ly + span + 1) {
        for px in (lx - 1)..<=(lx + span + 1) {
          if !organic &&
            river_distance(point(px.to_double(), py.to_double())) < 3.0 {
            wet = true
          }
        }
      }
      if wet {
        continue
      }
      // A conservative bounding circle reserves the complete oriented footprint.
      let radius = span.to_double() * 0.72 + 0.95
      let mut near = point(0, 0)
      let mut axis = point(1, 0)
      let mut best = 1.0e9
      for index, road in roads {
        if (arms & (1 << (index / 12))) == 0 {
          continue
        }
        let hit = nearest_on(road, center)
        let distance = distance(hit, center)
        if distance < best {
          best = distance
          near = hit
          axis = point(road.b.x - road.a.x, road.b.y - road.a.y)
        }
      }
      if best < radius || best > (if organic { 7.5 } else { 9.0 }) {
        continue
      }
      if organic &&
        lots.any(l => {
          lx < l.x + l.size + 1 &&
          lx + span + 1 > l.x &&
          ly < l.y + l.size + 1 &&
          ly + span + 1 > l.y
        }) {
        continue
      }
      let (east, north) = frontage_axes(point(1, 0), point(0, -1), axis)
      let entrance = frontage_entry(center, east, north, span, near)
      if !organic && water(near) {
        continue
      }
      let mut access_wet = false
      for i in 0..<=16 {
        let t = i.to_double() / 16.0
        if !organic &&
          water(
            point(
              entrance.x + (near.x - entrance.x) * t,
              entrance.y + (near.y - entrance.y) * t,
            ),
          ) {
          access_wet = true
        }
      }
      if access_wet {
        continue
      }
      lots.push({
        id: "\{if organic {"frontier-organic-v1"} else {version}}:\{seed}:\{cx}:\{cy}:\{salt}",
        x: lx,
        y: ly,
        size: span,
        style: styles[sample(seed, cx, cy, salt + 300) % 3],
        variant: sample(seed, cx, cy, salt + 400) %
        (if organic { 2 } else { 10 }),
        entrance,
        frontage: near,
        east,
        north,
      })
    }
  }
  let plants : Array[Plant] = []
  for i in 0..<(if organic { 210 } else { 90 }) {
    let px = x + 1.0 + (sample(seed, cx, cy, 1000 + i) % 300).to_double() / 10.0
    let py = y + 1.0 + (sample(seed, cx, cy, 2000 + i) % 300).to_double() / 10.0
    let p = point(px, py)
    // Continuous groves, rather than evenly sprinkled individual trees.
    if organic && woodland(p) < -0.15 && i % 7 != 0 {
      continue
    }
    if (!organic && river_distance(p) < 3.3) ||
      roads
      .mapi((j, r) => (j, r))
      .any(pair => {
        (arms & (1 << (pair.0 / 12))) != 0 &&
        distance(nearest_on(pair.1, p), p) < 1.7
      }) ||
      lots.any(l => {
        px > l.x.to_double() - 1 &&
        px < (l.x + l.size).to_double() + 1 &&
        py > l.y.to_double() - 1 &&
        py < (l.y + l.size).to_double() + 1
      }) {
      continue
    }
    plants.push({
      point: p,
      kind: if organic && i % 4 != 0 {
        sample(seed, district_x, district_y, 3000) % 6
      } else {
        sample(seed, cx, cy, 3000 + i) % 6
      },
      size: 0.7 + (sample(seed, cx, cy, 4000 + i) % 50).to_double() / 100.0,
    })
  }
  { x: cx, y: cy, theme, hub, arms, roads, lots, plants, }
}

///|
/// Continuous, low-frequency land cover shared across chunk boundaries.
pub fn woodland(p : Point) -> Double {
  @math.sin(p.x / 21.0) * @math.cos(p.y / 27.0) +
  0.55 * @math.sin((p.x + p.y) / 43.0)
}
