///|
fn framed_block(
  p : Array[Part],
  x : Double,
  z : Double,
  w : Double,
  d : Double,
  h : Double,
) -> Unit {
  let y = 2.3
  // Four wings enclose a real open-air courtyard, rather than a painted roof.
  let wing = 10.0
  for s in [-1.0, 1.0] {
    box(p, "glass", x, y + h / 2, z + s * (d - wing) / 2, w, h, wing)
    box(p, "glass", x + s * (w - wing) / 2, y + h / 2, z, wing, h, d - 2 * wing)
    box(
      p,
      "ivory",
      x,
      y + h + 0.4,
      z + s * (d - wing) / 2,
      w + 0.8,
      0.8,
      wing + 0.5,
    )
    box(
      p,
      "ivory",
      x + s * (w - wing) / 2,
      y + h + 0.4,
      z,
      wing + 0.5,
      0.8,
      d - 2 * wing,
    )
    box(p, "stone", x, y + 1, z + s * (d - wing) / 2, w + 1, 2, wing + 1)
    for i in 0..<=(w / 2.4).to_int() {
      let dx = -w / 2 + i.to_double() * w / (w / 2.4).to_int().to_double()
      // Deliberately leave a glass corner bay, as in the real facade.
      if dx < w / 2 - 5 || s < 0 {
        box(
          p,
          "ivory",
          x + dx,
          y + h / 2,
          z + s * (d / 2 + 0.17),
          0.48,
          h,
          0.65,
        )
      }
    }
    for i in 0..<=(d / 2.4).to_int() {
      let dz = -d / 2 + i.to_double() * d / (d / 2.4).to_int().to_double()
      box(p, "ivory", x + s * (w / 2 + 0.17), y + h / 2, z + dz, 0.65, h, 0.42)
    }
    for floor in 1..<(h / 4.4).to_int() {
      let fy = y + floor.to_double() * 4.4
      box(p, "stone", x, fy, z + s * (d / 2 + 0.1), w, 0.28, 0.5)
      box(p, "stone", x + s * (w / 2 + 0.1), fy, z, 0.5, 0.28, d)
    }
    // Courtyard-facing glazing rhythm and roof plant screened from the street.
  }
  box(p, "paving", x, y + 0.15, z, w - 20, 0.2, d - 20, layer="context")
  tree(p, x, y + 0.3, z, 21, size=0.8)
  // A glazed entrance canopy and an explicitly paved short front approach.
  box(p, "glassLight", x, y + 4.6, z + d / 2 + 2.5, 10, 0.3, 5)
  for dx in [-4.4, 4.4] {
    box(p, "metal", x + dx, y + 2.3, z + d / 2 + 4.4, 0.15, 4.6, 0.15)
  }
  box(p, "paving2", x, y + 0.1, z + d / 2 + 5, 10, 0.1, 10, layer="context")
  framed_details(p, x, z, w, d, h)
}

///|
fn future_center() -> Study {
  let p : Array[Part] = []
  campus_ground(p)
  for column in 0..<3 {
    let x = -93.0 + column.to_double() * 67
    for row in [-1.0, 1.0] {
      framed_block(
        p,
        x,
        row * 37,
        if column == 0 {
          44
        } else {
          51
        },
        34,
        if column == 2 {
          41
        } else {
          45
        },
      )
    }
  }
  // No. 7 is a paired-tower composition with elevated cross pieces.
  for z in [-24.0, 24.0] {
    framed_block(p, 105, z, 26, 34, 78)
    box(p, "ivory", 105, 81.6, z, 28, 1.8, 35)
  }
  for y in [27.0, 51.0, 73.0] {
    box(p, "glass", 105, y, 0, 20, 8, 16)
    box(p, "ivory", 105, y + 4, 0, 21, 0.8, 16)
    box(p, "ivory", 105, y - 4, 0, 21, 0.8, 16)
  }
  // Central garden spine: planting, seating, clear pedestrian circulation.
  box(p, "ivory", 43, 3.8, 68, 14, 3, 1.2)
  sign(p, "未来中心", 43, 3.9, 68.62, 10, 1.8)
  for i in 0..<12 {
    let x = -123.0 + i.to_double() * 18
    planter(p, x, 2.3, 0, 10, 9, i * 11)
    tree(p, x, 3.3, 0, i + 34, size=0.8)
    bench(p, x, 2.3, 8)
    person(p, x + 4, 2.3, -9, i)
  }
  {
    id: "center",
    title: "未来中心",
    subtitle: "FUTURE CENTER",
    description: "An ordered campus of courtyard offices, pale facade frames and a paired-tower landmark. Gardens form its central pedestrian spine.",
    note: "Reference-led massing • 45 m / 80 m design references • footprint and rear details approximate",
    span: 310,
    focus: [0, 24, 0],
    detail_focus: [41, 18, 53],
    detail_offset: [38, 15, 64],
    parts: p,
  }
}

///|
fn glass_profile(
  p : Array[Part],
  outline : Array[Array[Double]],
  x : Double,
  z : Double,
  h : Double,
  creative : Bool,
) -> Unit {
  let y = 2.35
  profile(
    p,
    if creative {
      "glassAmber"
    } else {
      "glassLight"
    },
    outline,
    x,
    y,
    z,
    h,
  )
  profile(p, "roof", outline, x, y + h, z, 0.32)
  let n = outline.length()
  // Wall divisions follow the true curved perimeter on all elevations.
  for i in 0..<n {
    let a = outline[i]
    let b = outline[(i + 1) % n]
    let dx = b[0] - a[0]
    let dz = b[1] - a[1]
    let length = (dx * dx + dz * dz).sqrt()
    let count = (length / 1.65).to_int() + 1
    for j in 0..<count {
      let t = j.to_double() / count.to_double()
      let px = x + mix(a[0], b[0], t)
      let pz = z + mix(a[1], b[1], t)
      beam(p, "silver", [px, y, pz], [px, y + h, pz], 0.08)
    }
    if creative && i % 9 < 2 {
      let low = if i % 3 == 0 { h * 0.3 } else { 0.0 }
      let high = if i % 5 == 0 { h * 0.82 } else { h }
      let panel : Array[Array[Double]] = []
      quad(
        panel,
        [x + a[0] * 1.003, y + low, z + a[1] * 1.003],
        [x + b[0] * 1.003, y + low, z + b[1] * 1.003],
        [x + b[0] * 1.003, y + high, z + b[1] * 1.003],
        [x + a[0] * 1.003, y + high, z + a[1] * 1.003],
      )
      triangles(p, if i % 2 == 0 { "copper" } else { "amber" }, panel)
    }
    for level in 0..<=(h / 4.1).to_int() {
      let fy = y + level.to_double() * 4.1
      beam(
        p,
        "silver",
        [x + a[0], fy, z + a[1]],
        [x + b[0], fy, z + b[1]],
        0.085,
      )
    }
    beam(
      p,
      "ivory",
      [x + a[0], y + h + 0.4, z + a[1]],
      [x + b[0], y + h + 0.4, z + b[1]],
      0.26,
    )
  }
  if creative {
    planter(p, x, y + h + 0.4, z, 7, 6, h.to_int())
    tree(p, x, y + h + 1.4, z, h.to_int(), size=0.48)
  } else {
    profile(p, "silver", rounded_outline(13, 15, 2), x, y + h + 0.4, z, 1.4)
  }
  curved_details(p, outline, x, z, h, creative)
}

///|
fn future_vision() -> Study {
  let p : Array[Part] = []
  campus_ground(p)
  // Three taller offices, not a single generic tower. Heights are provisional.
  glass_profile(p, rounded_outline(38, 40, 7), -62, -37, 79, false)
  glass_profile(p, rounded_outline(35, 35, 8), 20, -40, 54, false)
  glass_profile(p, rounded_outline(38, 37, 7), 101, 25, 41, false)
  let lobes = smooth_outline([
    [-26, -15],
    [-12, -19],
    [-3, -9],
    [13, -18],
    [25, -13],
    [22, -1],
    [12, 4],
    [13, 18],
    [1, 23],
    [-10, 13],
    [-11, 3],
    [-27, 0],
  ])
  glass_profile(p, lobes, -89, 31, 23, true)
  let middle = smooth_outline([
    [-22, -7],
    [-9, -16],
    [4, -9],
    [19, -15],
    [24, -7],
    [15, 3],
    [12, 19],
    [1, 24],
    [-7, 12],
    [-22, 6],
  ])
  glass_profile(p, middle, -23, 30, 20.5, true)
  let right = smooth_outline([
    [-15, -20],
    [0, -26],
    [12, -20],
    [10, -5],
    [23, 1],
    [25, 12],
    [13, 16],
    [-1, 10],
    [-5, 23],
    [-17, 20],
    [-20, 7],
    [-10, -5],
  ])
  glass_profile(p, right, 44, 23, 24.6, true)
  for i in 0..<14 {
    let x = -120.0 + i.to_double() * 18
    planter(p, x, 2.3, 67, 6, 4, i)
    if i % 2 == 0 {
      tree(p, x, 3.3, 67, i + 56, size=0.65)
    }
    person(p, x + 3, 2.3, 61, i)
    if i % 3 == 0 {
      bench(p, x, 2.3, 60)
    }
  }
  // Entrance monument, water garden and the landscaped gaps between groups.
  box(p, "ivory", -25, 3.8, 63, 15, 3, 1.2)
  sign(p, "未来视界", -25, 3.9, 63.62, 10, 1.8)
  profile(
    p,
    "stone",
    rounded_outline(16, 12, 5),
    63,
    2.35,
    -39,
    0.5,
    layer="context",
  )
  profile(
    p,
    "water",
    rounded_outline(14, 10, 4),
    63,
    2.87,
    -39,
    0.05,
    layer="context",
  )
  for x in [-120.0, -3.0, 67.0, 122.0] {
    tree(p, x, 2.3, -5, x.to_int().abs() + 3)
    planter(p, x, 2.3, -9, 5, 3, 34)
  }
  {
    id: "vision",
    title: "未来视界",
    subtitle: "FUTURE VISION",
    description: "Three connected, sculpted creative-office footprints meet taller glass volumes. Amber fins, roof gardens and a planted arrival court define the campus.",
    note: "Six-part reference composition • illustrative landscaping • heights and back elevations provisional",
    span: 310,
    focus: [0, 24, 0],
    detail_focus: [-23, 15, 46],
    detail_offset: [30, 15, 60],
    parts: p,
  }
}
