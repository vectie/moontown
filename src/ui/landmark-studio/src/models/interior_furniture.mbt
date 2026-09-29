///|
fn office_chair(
  p : Array[Part],
  x : Double,
  z : Double,
  facing? : Double = 1,
) -> Unit {
  primitive(
    p,
    "cylinder",
    "metal",
    x,
    0.23,
    z,
    0.09,
    0.4,
    0.09,
    layer="furniture",
  )
  box(p, "fabric", x, 0.48, z, 0.58, 0.12, 0.57, layer="furniture")
  box(
    p,
    "fabric",
    x,
    0.82,
    z + facing * 0.26,
    0.58,
    0.62,
    0.1,
    layer="furniture",
  )
  for dx in [-0.23, 0.23] {
    box(p, "metal", x + dx, 0.72, z, 0.045, 0.05, 0.44, layer="furniture")
  }
  for a in 0..<5 {
    let angle = a.to_double() * @math.PI * 2 / 5
    let dx = @math.cos(angle) * 0.3
    let dz = @math.sin(angle) * 0.3
    beam(
      p,
      "metal",
      [x, 0.09, z],
      [x + dx, 0.09, z + dz],
      0.025,
      layer="furniture",
    )
    primitive(
      p,
      "sphere",
      "rubber",
      x + dx,
      0.07,
      z + dz,
      0.09,
      0.09,
      0.09,
      layer="furniture",
    )
  }
}

///|
fn workdesk(p : Array[Part], u : Double, v : Double) -> Unit {
  let x = plan_x(u)
  let z = plan_z(v)
  box(p, "oak", x, 0.77, z, 1.65, 0.08, 0.78, layer="furniture")
  for side in [-1.0, 1.0] {
    box(
      p,
      "ivory",
      x + side * 0.68,
      0.38,
      z,
      0.055,
      0.73,
      0.6,
      layer="furniture",
    )
  }
  box(p, "metal", x, 1.11, z - 0.12, 0.67, 0.39, 0.065, layer="furniture")
  box(p, "screen", x, 1.11, z - 0.078, 0.6, 0.32, 0.018, layer="furniture")
  box(p, "silver", x, 0.87, z - 0.12, 0.06, 0.2, 0.06, layer="furniture")
  box(p, "silver", x, 0.819, z + 0.18, 0.48, 0.025, 0.16, layer="furniture")
  office_chair(p, x, z + 0.92)
}

///|
fn meeting_table(p : Array[Part], u : Double, v : Double, seats : Int) -> Unit {
  let x = plan_x(u)
  let z = plan_z(v)
  let length = seats.to_double() * 0.58
  profile(
    p,
    "oak",
    rounded_outline(length, 1.25, 0.3),
    x,
    0.74,
    z,
    0.09,
    layer="furniture",
  )
  for side in [-1.0, 1.0] {
    box(
      p,
      "metal",
      x + side * length * 0.3,
      0.36,
      z,
      0.12,
      0.72,
      0.85,
      layer="furniture",
    )
    for i in 0..<(seats / 2) {
      office_chair(
        p,
        x - length / 2 + 0.55 + i.to_double() * 1.05,
        z + side * 1.05,
        facing=side,
      )
    }
  }
  box(p, "silver", x, 0.84, z, 0.3, 0.03, 0.16, layer="furniture")
}

///|
fn interior_plant(p : Array[Part], u : Double, v : Double) -> Unit {
  let x = plan_x(u)
  let z = plan_z(v)
  primitive(
    p,
    "cylinder",
    "terracotta",
    x,
    0.3,
    z,
    0.62,
    0.6,
    0.62,
    layer="furniture",
  )
  for i in 0..<5 {
    let a = i.to_double() * 2.4
    beam(
      p,
      "leaf",
      [x, 0.55, z],
      [x + @math.cos(a) * 0.3, 1.3 + noise(i) * 0.4, z + @math.sin(a) * 0.3],
      0.025,
      layer="furniture",
    )
    primitive(
      p,
      "crown",
      "sage",
      x + @math.cos(a) * 0.3,
      1.3 + noise(i) * 0.4,
      z + @math.sin(a) * 0.3,
      0.48,
      0.65,
      0.4,
      layer="furniture",
    )
  }
}

///|
fn sofa(p : Array[Part], u : Double, v : Double, facing? : Double = 1) -> Unit {
  let x = plan_x(u)
  let z = plan_z(v)
  box(p, "fabric", x, 0.38, z, 2.25, 0.58, 0.86, layer="furniture")
  box(
    p,
    "fabric",
    x,
    0.77,
    z + facing * 0.37,
    2.25,
    0.62,
    0.17,
    layer="furniture",
  )
  for side in [-1.0, 1.0] {
    box(
      p,
      "fabric",
      x + side * 1.05,
      0.65,
      z,
      0.15,
      0.38,
      0.86,
      layer="furniture",
    )
    box(
      p,
      "linen",
      x + side * 0.53,
      0.72,
      z,
      0.94,
      0.13,
      0.7,
      layer="furniture",
    )
  }
}

///|
fn interior_furniture(p : Array[Part]) -> Unit {
  // Explicit per-room layouts leave the corridor and central void unfurnished.
  for u in [115.0, 160.0, 205.0, 285.0, 330.0] {
    for v in [570.0, 615.0] {
      workdesk(p, u, v)
    }
  }
  for u in [433.0, 510.0] {
    meeting_table(p, u, 592, 4)
  }
  for u in [580.0, 625.0, 665.0] {
    workdesk(p, u, 575)
  }
  meeting_table(p, 625, 630, 4)
  for room in 0..<5 {
    let u = 587.0 + room.to_double() * 94
    for dx in [-20.0, 20.0] {
      workdesk(p, u + dx, 930)
      workdesk(p, u + dx, 985)
    }
    interior_plant(p, u + 30, 1025)
  }
  for u in [270.0, 485.0] {
    workdesk(p, u, 940)
    workdesk(p, u, 985)
  }
  meeting_table(p, 380, 966, 4)
  for u in [1200.0, 1270.0, 1340.0, 1410.0] {
    meeting_table(p, u, 945, 4)
  }
  for u in [1520.0, 1575.0] {
    workdesk(p, u, 935)
    workdesk(p, u, 990)
  }
  // Roadshow: low stage, presentation wall and movable chairs.
  plan_box(p, "oak", 855, 392, 1100, 437, 0.22, 0.44, layer="furniture")
  plan_box(p, "metal", 895, 391, 1060, 395, 1.85, 2.7, layer="furniture")
  plan_box(p, "screen", 900, 395, 1055, 397, 1.85, 2.35, layer="furniture")
  for row in 0..<7 {
    for col in 0..<10 {
      let u = 876.0 + col.to_double() * 21 + (if col >= 5 { 15.0 } else { 0.0 })
      office_chair(p, plan_x(u), plan_z(463 + row.to_double() * 24))
    }
  }
  for u in [1190.0, 1290.0, 1390.0] {
    meeting_table(p, u, 470, 6)
    sofa(p, u, 575)
    profile(
      p,
      "oak",
      rounded_outline(1.8, 0.85, 0.2),
      plan_x(u),
      0.37,
      plan_z(550),
      0.09,
      layer="furniture",
    )
  }
  for v in [435.0, 515.0, 595.0] {
    plan_box(p, "ivory", 1490, v, 1565, v + 20, 0.65, 1.3, layer="furniture")
    primitive(
      p,
      "crown",
      "copper",
      plan_x(1525),
      1.7,
      plan_z(v + 10),
      0.65,
      0.85,
      0.65,
      layer="furniture",
    )
  }
  // Water bar and lounge, in the specifically identified public zone.
  plan_box(p, "oak", 1023, 1010, 1130, 1030, 0.49, 0.98, layer="furniture")
  plan_box(p, "ivory", 1020, 1008, 1133, 1032, 1.01, 0.07, layer="furniture")
  plan_box(p, "metal", 1096, 1012, 1110, 1027, 1.24, 0.42, layer="furniture")
  sofa(p, 1070, 935, facing=-1)
  profile(
    p,
    "oak",
    rounded_outline(1.8, 0.9, 0.2),
    plan_x(1070),
    0.36,
    plan_z(968),
    0.1,
    layer="furniture",
  )
  for u in [1040.0, 1070.0, 1100.0] {
    office_chair(p, plan_x(u), plan_z(988), facing=-1)
  }
  for
    uv in [
      [82.0, 545.0],
      [365.0, 550.0],
      [680.0, 550.0],
      [847.0, 390.0],
      [1120.0, 390.0],
      [1410.0, 390.0],
      [1592.0, 390.0],
      [1595.0, 1025.0],
      [1170.0, 1020.0],
      [1030.0, 910.0],
      [239.0, 1025.0],
      [505.0, 1025.0],
    ] {
    interior_plant(p, uv[0], uv[1])
  }
}
