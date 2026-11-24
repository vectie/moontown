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
    // A full structural bay spans two panes. Slim mullions are authored in
    // framed_details; the outer stone grid has real reveal depth.
    let front_bays = (w / 4.8).round().to_int().max(1)
    for i in 0..<=front_bays {
      let dx = -w / 2 + i.to_double() * w / front_bays.to_double()
      // Deliberately leave a glass corner bay, as in the real facade.
      if dx < w / 2 - 5 || s < 0 {
        box(
          p,
          "ivory",
          x + dx,
          y + h / 2,
          z + s * (d / 2 + 0.17),
          0.68,
          h,
          1.02,
        )
      }
    }
    let side_bays = (d / 4.8).round().to_int().max(1)
    for i in 0..<=side_bays {
      let dz = -d / 2 + i.to_double() * d / side_bays.to_double()
      box(p, "ivory", x + s * (w / 2 + 0.17), y + h / 2, z + dz, 1.02, h, 0.62)
    }
    for floor in 1..<(h / 4.4).to_int() {
      let fy = y + floor.to_double() * 4.4
      box(p, "stone", x, fy, z + s * (d / 2 + 0.1), w, 0.51, 0.78)
      box(p, "stone", x + s * (w / 2 + 0.1), fy, z, 0.78, 0.51, d)
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
fn future_center_block(
  p : Array[Part],
  number : Int32,
  x : Double,
  z : Double,
) -> Unit {
  if number < 7 {
    framed_block(
      p,
      x,
      z,
      if number <= 2 {
        44
      } else {
        51
      },
      34,
      if number >= 5 {
        41
      } else {
        45
      },
    )
    return
  }
  for dz in [-24.0, 24.0] {
    framed_block(p, x, z + dz, 26, 34, 78)
    box(p, "ivory", x, 81.6, z + dz, 28, 1.8, 35)
  }
  for y in [27.0, 51.0, 73.0] {
    box(p, "glass", x, y, z, 20, 8, 16)
    box(p, "ivory", x, y + 4, z, 21, 0.8, 16)
    box(p, "ivory", x, y - 4, z, 21, 0.8, 16)
  }
}

///|
/// Bake one architectural volume in its local frame. Called only by the map baker.
pub fn future_center_map_parts(number : Int32) -> Json {
  let parts : Array[Part] = []
  if number >= 1 && number <= 7 {
    future_center_block(parts, number, 0, 0)
  }
  parts.to_json()
}

///|
fn future_center() -> Study {
  let p : Array[Part] = []
  campus_ground(p)
  for column in 0..<3 {
    for row in 0..<2 {
      future_center_block(
        p,
        1 + column * 2 + row,
        -93.0 + column.to_double() * 67,
        -37.0 + row.to_double() * 74,
      )
    }
  }
  future_center_block(p, 7, 105, 0)
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
      "glassSmoke"
    } else {
      "glassAzure"
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
      if creative {
        beam(p, "metal", [px, y, pz], [px, y + h, pz], 0.11)
      } else if length > 3 && j % 4 == 0 {
        girder(p, "ivory", [px, y, pz], [px, y + h, pz], 0.65, 0.78)
      } else {
        beam(p, "silver", [px, y, pz], [px, y + h, pz], 0.10)
      }
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
// The A21 model uses metres east and south from the same imagery origin as
// the town projection. Offsets describe individual bases, including roof lean.
fn vision_tower(
  p : Array[Part],
  x : Double,
  z : Double,
  w : Double,
  d : Double,
  angle : Double,
  h : Double,
) -> Unit {
  let rad = angle * @math.PI / 180
  let c = @math.cos(rad)
  let s = @math.sin(rad)
  let ring = rounded_outline(w, d, 3).map(pt => {
    [pt[0] * c - pt[1] * s, pt[0] * s + pt[1] * c]
  })
  glass_profile(p, ring, x, z, h, false)
}

///|
fn vision_wing(
  p : Array[Part],
  x : Double,
  z : Double,
  h : Double,
  ring : Array[Array[Double]],
) -> Unit {
  glass_profile(p, smooth_outline(ring), x, z, h, true)
}

///|
fn vision_link(
  p : Array[Part],
  ax : Double,
  az : Double,
  bx : Double,
  bz : Double,
  y : Double,
) -> Unit {
  girder(p, "glassSmoke", [ax, y, az], [bx, y, bz], 4.4, 4.0)
  girder(p, "silver", [ax, y + 2.1, az], [bx, y + 2.1, bz], 4.8, 0.24)
}

///|
fn future_vision() -> Study {
  let p : Array[Part] = []
  let site : Array[Array[Double]] = [
    [-172, 51],
    [-85, -128],
    [113, -108],
    [136, -94],
    [138, 146],
    [88, 124],
    [0, 91],
  ]
  profile(p, "grass", site, 0, 0, 0, 2.1, layer="context")
  profile(
    p,
    "paving",
    [[-141, 49], [-92, -75], [-42, -101], [92, -77], [108, 109], [18, 76]],
    0,
    2.1,
    0,
    0.2,
    layer="context",
  )
  profile(
    p,
    "asphalt",
    [
      [-175, 51],
      [0, 83],
      [88, 112],
      [139, 143],
      [135, 152],
      [82, 121],
      [-2, 92],
      [-178, 60],
    ],
    0,
    2.15,
    0,
    0.13,
    layer="context",
  )
  // No. 1 hotel and offices share the broad, stepped western podium.
  let podium : Array[Array[Double]] = [
    [-96, -25],
    [-69, -85],
    [-30, -77],
    [-13, -61],
    [-14, -29],
    [-34, -12],
  ]
  profile(p, "glassSmoke", podium, 0, 2.3, 0, 10)
  profile(p, "ivory", podium, 0, 12.3, 0, 0.8)
  profile(
    p,
    "sage",
    podium.map(pt => [(pt[0] + 52) * 0.91 - 52, (pt[1] + 47) * 0.91 - 47]),
    0,
    13.1,
    0,
    0.2,
  )
  for i in 0..<podium.length() {
    let a = podium[i]
    let b = podium[(i + 1) % podium.length()]
    let n = ((a[0] - b[0]) * (a[0] - b[0]) + (a[1] - b[1]) * (a[1] - b[1]))
      .sqrt()
      .to_int() /
      3 +
      1
    for j in 0..<n {
      let t = j.to_double() / n.to_double()
      let x = mix(a[0], b[0], t)
      let z = mix(a[1], b[1], t)
      girder(p, "silver", [x, 2.3, z], [x, 12.3, z], 0.17, 0.24)
    }
    for y in [6.6, 10.7] {
      beam(p, "silver", [a[0], y, a[1]], [b[0], y, b[1]], 0.12)
    }
  }
  vision_tower(p, -44, -55, 43, 44, 19, 96)
  vision_tower(p, 57, -32, 42, 42, -4, 64)
  vision_tower(p, 75, 73, 41, 41, 8, 47)
  // Nos. 6, 5 and 4 each have two separately articulated curved wings. The
  // gaps below the links are open to the pedestrian court.
  vision_wing(p, -106.4, 23.8, 22, [
    [-13.9, 12.4],
    [-9.4, 1],
    [1.5, -14.8],
    [8.9, -19.8],
    [16.3, -18.3],
    [17.3, -13.4],
    [7.9, -3],
    [1.5, 10.4],
    [-1, 16.8],
    [-10.4, 17.3],
  ])
  vision_wing(p, -74.7, 21.3, 22, [
    [-13.9, 15.8],
    [-9.4, 0],
    [-4, -14.4],
    [2.5, -19.3],
    [12.4, -19.8],
    [16.8, -16.3],
    [14.4, -9.9],
    [5, 2.5],
    [-3.5, 19.8],
    [-10.4, 22.3],
  ])
  vision_wing(p, -54.9, 38.6, 21, [
    [-11.9, 10.9],
    [-8.4, -0.5],
    [1.5, -13.4],
    [8.9, -17.8],
    [14.4, -16.8],
    [15.8, -11.4],
    [9.4, 0.5],
    [6.4, 12.4],
    [3, 15.3],
    [-8.9, 13.9],
  ])
  vision_wing(p, -27.7, 39.1, 21, [
    [-9.4, 8.9],
    [-8.4, -1.5],
    [-0.5, -14.4],
    [6.4, -21.3],
    [12.4, -21.8],
    [11.9, -11.9],
    [8.4, 2],
    [7.9, 14.8],
    [4.5, 17.8],
    [-6.9, 16.3],
  ])
  vision_wing(p, 17.8, 19.3, 23, [
    [-18.3, 13.9],
    [-11.9, 1],
    [-3.5, -14.8],
    [4, -19.8],
    [10.4, -18.8],
    [17.3, -12.9],
    [16.8, -7.4],
    [5.9, 2],
    [-7.9, 12.9],
    [-14.8, 18.3],
  ])
  vision_wing(p, 28.2, 41.1, 23, [
    [-13.4, 11.4],
    [-12.4, 2],
    [-6.9, -9.4],
    [3, -18.8],
    [10.9, -23.3],
    [14.8, -21.3],
    [13.9, -15.8],
    [5, -5.4],
    [2.5, 5.4],
    [5.4, 14.4],
    [0.5, 17.8],
    [-10.4, 16.3],
  ])
  vision_link(p, -95.5, 15.3, -78.2, 19.8, 16)
  vision_link(p, -105.4, 30.2, -85.6, 33.7, 16)
  vision_link(p, -47, 30.7, -29.7, 34.2, 16)
  vision_link(p, -49.5, 48.5, -33.7, 50.5, 16)
  vision_link(p, 22.8, 16.8, 31.7, 27.2, 16)
  vision_link(p, 14.4, 26.2, 24.8, 35.1, 16)
  for i in 0..<15 {
    let x = -145.0 + i.to_double() * 16
    let z = 56.0 + (x + 145) * 0.16 + (if x > 0 { x * 0.22 } else { 0.0 })
    tree(p, x, 2.3, z, i + 32, size=0.82)
    if i % 3 == 0 {
      lamp(p, x + 4, 2.3, z + 2)
      bench(p, x, 2.3, z - 3)
    }
    person(p, x + 3, 2.3, z - 2, i)
  }
  for i in 0..<9 {
    tree(p, 105, 2.3, -88 + i.to_double() * 19, 60 + i, size=0.75)
  }
  {
    id: "vision",
    title: "未来视界",
    subtitle: "FUTURE VISION",
    description: "西北酒店与裙房、东侧两座总部、南侧三组曲面办公楼环抱步行庭院。",
    note: "楼群按 A21 验收总平、楼号图及影像复核。高度、背立面与景观细节近似。",
    span: 330,
    focus: [-5, 27, 0],
    detail_focus: [-46, 16, 33],
    detail_offset: [48, 24, 65],
    parts: p,
  }
}
