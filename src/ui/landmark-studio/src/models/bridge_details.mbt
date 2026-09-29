///|
// Detail dimensions are visual interpretations, not structural specifications.
fn bridge_fittings(p : Array[Part], width : Double) -> Unit {
  for side in [-1.0, 1.0] {
    let edge = side * (width / 2 - 0.3)
    let walk = side * (width / 2 - 2)
    // Recessed fascia, steel girder flanges, curb and continuous tactile strip.
    box(p, "metal", 0, 8.8, side * (width / 2 - 0.2), 351, 0.9, 0.18)
    box(p, "silver", 0, 9.55, edge, 351, 0.15, 0.38)
    box(p, "concrete", 0, 10.35, side * (width / 2 - 4), 351, 0.48, 0.32)
    box(p, "sand", 0, 10.414, walk, 351, 0.02, 0.42)
    for z in [walk - 1.3, walk + 1.3] {
      box(p, "paving2", 0, 10.411, z, 351, 0.015, 0.025)
    }
    for i in 0..<352 {
      let x = -175.5 + i.to_double()
      box(p, "paving2", x, 10.413, walk, 0.024, 0.016, 3.65)
      if i % 4 == 0 {
        box(p, "silver", x, 10.45, edge, 0.32, 0.1, 0.32)
        // Inner pedestrian guardrail visible in the inspection photographs.
        beam(
          p,
          "silver",
          [x, 10.45, side * (width / 2 - 3.7)],
          [x, 11.55, side * (width / 2 - 3.7)],
          0.06,
        )
      }
    }
    for y in [10.7, 10.98, 11.26, 11.55] {
      beam(
        p,
        "silver",
        [-176, y, side * (width / 2 - 3.7)],
        [176, y, side * (width / 2 - 3.7)],
        0.055,
      )
    }
    for i in 0..<18 {
      let x = -170.0 + i.to_double() * 20
      box(p, "metal", x, 10.42, side * (width / 2 - 4.3), 0.8, 0.05, 0.36)
      for j in 0..<5 {
        box(
          p,
          "silver",
          x - 0.32 + j.to_double() * 0.16,
          10.45,
          side * (width / 2 - 4.3),
          0.035,
          0.02,
          0.32,
        )
      }
    }
    // The reference describes a box girder, not an exposed checkerboard truss.
    box(p, "silver", 0, 7.18, side * (width / 2 - 3.1), 350, 0.12, 0.5)
  }
  for x in [-108.5, 0.0, 108.5] {
    box(p, "rubber", x, 10.145, 0, 0.18, 0.022, width - 8)
    for dx in [-0.16, 0.16] {
      box(p, "silver", x + dx, 10.15, 0, 0.065, 0.03, width - 8)
    }
  }
  box(p, "metal", 0, 7.7, 0, 350, 1.0, width - 6)
}

///|
fn bridge_light(p : Array[Part], x : Double, z : Double) -> Unit {
  box(p, "silver", x, 10.55, z, 0.55, 0.3, 0.55)
  beam(p, "silver", [x, 10.6, z], [x, 18.7, z], 0.11)
  for s in [-1.0, 1.0] {
    beam(p, "silver", [x, 17.8, z], [x + s * 1.15, 19.3, z], 0.075)
    beam(p, "silver", [x + s * 1.15, 19.3, z], [x + s * 2.8, 19.55, z], 0.07)
    box(p, "lamp", x + s * 2.55, 19.53, z, 1.0, 0.1, 0.38)
  }
}

///|
fn hanger_fittings(
  p : Array[Part],
  bottom : Array[Double],
  top : Array[Double],
) -> Unit {
  box(p, "ivory", bottom[0], 10.55, bottom[2], 0.85, 0.2, 0.85)
  beam(
    p,
    "silver",
    bottom,
    [
      mix(bottom[0], top[0], 0.04),
      mix(bottom[1], top[1], 0.04),
      mix(bottom[2], top[2], 0.04),
    ],
    0.23,
  )
  beam(
    p,
    "silver",
    [
      mix(bottom[0], top[0], 0.96),
      mix(bottom[1], top[1], 0.96),
      mix(bottom[2], top[2], 0.96),
    ],
    top,
    0.22,
  )
  for dx in [-0.3, 0.3] {
    for dz in [-0.3, 0.3] {
      primitive(
        p,
        "cylinder",
        "metal",
        bottom[0] + dx,
        10.68,
        bottom[2] + dz,
        0.1,
        0.07,
        0.1,
      )
    }
  }
}

///|
fn arch_panel_joint(p : Array[Part], t : Double, side : Double) -> Unit {
  let a = arch_point(t, side)
  let depth = 2.4 + 6.0 * (1 - @math.sin(@math.PI * t))
  for j in 0..<6 {
    let angle = j.to_double() * @math.PI / 3
    let next = (j + 1).to_double() * @math.PI / 3
    beam(
      p,
      "stone",
      [
        a[0],
        a[1] + @math.sin(angle) * (depth + 0.025),
        a[2] + @math.cos(angle) * 1.425,
      ],
      [
        a[0],
        a[1] + @math.sin(next) * (depth + 0.025),
        a[2] + @math.cos(next) * 1.425,
      ],
      0.022,
    )
  }
}
