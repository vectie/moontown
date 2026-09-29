///|
// Service equipment is illustrative; no as-built roof services plan is available.
fn roof_plant(p : Array[Part], x : Double, y : Double, z : Double) -> Unit {
  box(p, "roof", x, y + 0.7, z, 4.5, 1.4, 4)
  for s in [-1.0, 1.0] {
    for i in 0..<7 {
      box(
        p,
        "silver",
        x,
        y + 0.18 + i.to_double() * 0.22,
        z + s * 2.1,
        4.8,
        0.09,
        0.12,
      )
    }
    primitive(p, "cylinder", "metal", x + s * 1.1, y + 1.5, z, 1.5, 0.18, 1.5)
    primitive(
      p,
      "cylinder",
      "silver",
      x + s * 1.1,
      y + 1.62,
      z,
      0.35,
      0.12,
      0.35,
    )
    for dx in [-0.5, 0.0, 0.5] {
      box(p, "silver", x + s * 1.1 + dx, y + 1.61, z, 0.055, 0.03, 1.0)
    }
  }
}

///|
fn entrance_detail(
  p : Array[Part],
  x : Double,
  y : Double,
  z : Double,
  width : Double,
) -> Unit {
  // A framed entrance overlay with transom, double doors and handles.
  box(p, "glassLight", x, y + 2.2, z, width, 4.4, 0.14)
  for dx in [-width / 2, -1.6, 0.0, 1.6, width / 2] {
    box(p, "metal", x + dx, y + 2.2, z + 0.12, 0.075, 4.4, 0.14)
  }
  for fy in [0.12, 3.2, 4.4] {
    box(p, "silver", x, y + fy, z + 0.12, width, 0.09, 0.14)
  }
  for dx in [-0.22, 0.22] {
    beam(p, "silver", [x + dx, y + 1, z + 0.3], [x + dx, y + 2, z + 0.3], 0.035)
  }
  box(p, "rubber", x, y + 0.035, z + 1.2, 3.4, 0.04, 1.7)
  for dx in [-width / 2 - 0.8, width / 2 + 0.8] {
    primitive(p, "cylinder", "silver", x + dx, y + 0.5, z + 2.5, 0.15, 1, 0.15)
    primitive(p, "cylinder", "lamp", x + dx, y + 0.8, z + 2.5, 0.16, 0.13, 0.16)
  }
}

///|
fn framed_details(
  p : Array[Part],
  x : Double,
  z : Double,
  w : Double,
  d : Double,
  h : Double,
) -> Unit {
  let y = 2.3
  for side in [-1.0, 1.0] {
    // Shadowed spandrels sit behind the pale structural grid.
    for floor in 1..<(h / 4.4).to_int() {
      let fy = y + floor.to_double() * 4.4
      box(
        p,
        "metal",
        x,
        fy - 0.55,
        z + side * (d / 2 + 0.02),
        w - 0.4,
        0.8,
        0.08,
      )
      box(
        p,
        "metal",
        x + side * (w / 2 + 0.02),
        fy - 0.55,
        z,
        0.08,
        0.8,
        d - 0.4,
      )
      // Inner courtyard transoms, missing from the massing pass.
      box(p, "silver", x, fy, z + side * (d / 2 - 10 - 0.04), w - 20, 0.13, 0.1)
      box(p, "silver", x + side * (w / 2 - 10 - 0.04), fy, z, 0.1, 0.13, d - 20)
    }
    let bays = (w / 2.4).to_int()
    for i in 0..<bays {
      let bx = x - w / 2 + (i.to_double() + 0.5) * w / bays.to_double()
      box(p, "silver", bx, y + h / 2, z + side * (d / 2 + 0.05), 0.065, h, 0.12)
    }
    for i in 1..<((w - 20) / 2).to_int() {
      box(
        p,
        "silver",
        x - (w - 20) / 2 + i.to_double() * 2,
        y + h / 2,
        z + side * (d / 2 - 10 - 0.08),
        0.09,
        h,
        0.12,
      )
    }
    // Inset roof surfaces preserve the open courtyard, with inner and outer parapets.
    box(p, "roof", x, y + h + 0.82, z + side * (d - 10) / 2, w - 1, 0.05, 8.7)
    box(p, "roof", x + side * (w - 10) / 2, y + h + 0.82, z, 8.7, 0.05, d - 20)
    for inset in [0.0, 10.0] {
      box(
        p,
        "ivory",
        x,
        y + h + 1.15,
        z + side * (d / 2 - inset),
        w - 2 * inset,
        0.65,
        0.22,
      )
      box(
        p,
        "ivory",
        x + side * (w / 2 - inset),
        y + h + 1.15,
        z,
        0.22,
        0.65,
        d - 2 * inset,
      )
    }
    roof_plant(p, x + side * (w - 10) / 2, y + h + 0.85, z)
  }
  entrance_detail(p, x, y + 0.1, z + d / 2 + 0.62, 8)
  for dx in [-4.8, -2.4, 0.0, 2.4, 4.8] {
    box(p, "silver", x + dx, y + 4.8, z + d / 2 + 2.5, 0.09, 0.15, 5)
  }
  box(p, "silver", x, y + 4.8, z + d / 2 + 5, 10.1, 0.18, 0.18)
  // Courtyard-scale seating and planters; no change to the campus layout.
  for side in [-1.0, 1.0] {
    planter(p, x + side * (w - 23) / 2, y + 0.3, z, 1.4, d - 22, 20)
  }
}

///|
fn curved_details(
  p : Array[Part],
  outline : Array[Array[Double]],
  x : Double,
  z : Double,
  h : Double,
  creative : Bool,
) -> Unit {
  let y = 2.35
  let spandrels : Array[Array[Double]] = []
  let panes : Array[Array[Double]] = []
  for i in 0..<outline.length() {
    let a = outline[i]
    let b = outline[(i + 1) % outline.length()]
    let ax = x + a[0] * 1.001
    let az = z + a[1] * 1.001
    let bx = x + b[0] * 1.001
    let bz = z + b[1] * 1.001
    for level in 1..<(h / 4.1).to_int() {
      let fy = y + level.to_double() * 4.1
      quad(
        spandrels,
        [ax, fy - 0.65, az],
        [bx, fy - 0.65, bz],
        [bx, fy - 0.06, bz],
        [ax, fy - 0.06, az],
      )
      // Subtle glazing variation makes distinct panes readable, not random color noise.
      if (i + level * 3) % 11 == 0 {
        quad(
          panes,
          [ax, fy + 0.1, az],
          [bx, fy + 0.1, bz],
          [bx, fy + 3.3, bz],
          [ax, fy + 3.3, az],
        )
      }
      beam(p, "silver", [ax, fy + 2.8, az], [bx, fy + 2.8, bz], 0.026)
    }
    girder(
      p,
      "silver",
      [ax, y + h + 0.9, az],
      [bx, y + h + 0.9, bz],
      0.13,
      0.13,
    )
    // A real upstand and coping follow every curve of the existing roof silhouette.
    girder(p, "ivory", [ax, y + h + 0.6, az], [bx, y + h + 0.6, bz], 0.4, 0.16)
    if creative && i % 5 == 0 {
      box(
        p,
        "stone",
        x + a[0] * 0.80,
        y + h + 0.62,
        z + a[1] * 0.80,
        1.8,
        0.55,
        1.8,
      )
      primitive(
        p,
        "crown",
        "shrub",
        x + a[0] * 0.80,
        y + h + 1.15,
        z + a[1] * 0.80,
        2.1,
        1,
        2.1,
      )
    }
  }
  triangles(p, "metal", spandrels)
  triangles(p, "glass", panes)
  if !creative {
    roof_plant(p, x, y + h + 1.8, z)
  }
  // Locate a short canopy on the most forward outline point, rather than guessing a bounding box.
  let mut front = outline[0]
  for point in outline {
    if point[1] > front[1] {
      front = point
    }
  }
  let ex = x + front[0]
  let ez = z + front[1]
  entrance_detail(p, ex, y + 0.03, ez + 0.16, 5)
  profile(p, "ivory", rounded_outline(8, 5, 1.2), ex, y + 4.6, ez + 1.5, 0.3)
  box(p, "glassLight", ex, y + 4.94, ez + 1.5, 5.8, 0.08, 3.5)
}
