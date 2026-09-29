///|
fn tree(
  p : Array[Part],
  x : Double,
  y : Double,
  z : Double,
  seed : Int,
  size? : Double = 1.0,
) -> Unit {
  let h = (5.5 + noise(seed) * 3) * size
  primitive(
    p,
    "cylinder",
    "bark",
    x,
    y + h * 0.33,
    z,
    0.38 * size,
    h * 0.66,
    0.38 * size,
    layer="context",
  )
  if seed % 9 == 0 {
    for j in 0..<3 {
      primitive(
        p,
        "cone",
        "pine",
        x,
        y + h * (0.48 + j.to_double() * 0.2),
        z,
        (3.5 - j.to_double() * 0.6) * size,
        h * 0.62,
        (3.5 - j.to_double() * 0.6) * size,
        layer="context",
      )
    }
  } else {
    let mat = if seed % 13 == 0 {
      "blossom"
    } else if seed % 4 == 0 {
      "lime"
    } else if seed % 3 == 0 {
      "sage"
    } else {
      "leaf"
    }
    for j in 0..<4 {
      let angle = j.to_double() * 2.1 + noise(seed + 2)
      let r = if j == 3 { 0.0 } else { 1.2 * size }
      primitive(
        p,
        "crown",
        mat,
        x + @math.cos(angle) * r,
        y + h * (0.7 + j.to_double() * 0.06),
        z + @math.sin(angle) * r,
        (3.2 + noise(seed + j) * 0.8) * size,
        3.5 * size,
        3.0 * size,
        layer="context",
        rotation=angle,
      )
    }
  }
}

///|
fn planter(
  p : Array[Part],
  x : Double,
  y : Double,
  z : Double,
  w : Double,
  d : Double,
  seed : Int,
) -> Unit {
  box(p, "stone", x, y + 0.3, z, w, 0.6, d, layer="context")
  box(p, "shrub", x, y + 0.7, z, w - 0.5, 0.6, d - 0.5, layer="context")
  for j in 0..<8 {
    let fx = x + (noise(seed + j * 31) - 0.5) * (w - 1)
    let fz = z + (noise(seed + j * 11) - 0.5) * (d - 1)
    primitive(
      p,
      "crown",
      if j % 2 == 0 {
        "flower"
      } else {
        "blossom"
      },
      fx,
      y + 1.12,
      fz,
      0.55,
      0.35,
      0.55,
      layer="context",
    )
  }
}

///|
fn bench(p : Array[Part], x : Double, y : Double, z : Double) -> Unit {
  box(p, "wood", x, y + 0.65, z, 3.0, 0.24, 0.85, layer="context")
  box(p, "wood", x, y + 1.12, z + 0.36, 3.0, 0.75, 0.13, layer="context")
  for dx in [-1.1, 1.1] {
    box(p, "metal", x + dx, y + 0.3, z, 0.17, 0.6, 0.75, layer="context")
  }
}

///|
fn person(
  p : Array[Part],
  x : Double,
  y : Double,
  z : Double,
  seed : Int,
) -> Unit {
  let mat = if seed % 2 == 0 { "coral" } else { "navy" }
  primitive(
    p,
    "sphere",
    "skin",
    x,
    y + 1.62,
    z,
    0.38,
    0.4,
    0.38,
    layer="context",
  )
  primitive(p, "cylinder", mat, x, y + 1.1, z, 0.48, 0.8, 0.4, layer="context")
  for dx in [-0.13, 0.13] {
    box(p, "navy", x + dx, y + 0.36, z, 0.17, 0.72, 0.2, layer="context")
  }
}

///|
fn lamp(p : Array[Part], x : Double, y : Double, z : Double) -> Unit {
  beam(p, "metal", [x, y, z], [x, y + 6, z], 0.1, layer="context")
  beam(p, "metal", [x, y + 6, z], [x + 1.6, y + 6, z], 0.1, layer="context")
  box(p, "lamp", x + 1.35, y + 5.92, z, 1, 0.18, 0.4, layer="context")
}

///|
fn car(p : Array[Part], x : Double, y : Double, z : Double, seed : Int) -> Unit {
  let mat = if seed % 3 == 0 {
    "coral"
  } else if seed % 3 == 1 {
    "ivory"
  } else {
    "navy"
  }
  box(p, mat, x, y + 0.8, z, 4.4, 0.85, 1.9, layer="context")
  box(p, "glass", x - 0.2, y + 1.38, z, 2.45, 0.65, 1.7, layer="context")
  box(p, mat, x - 0.2, y + 1.72, z, 2.4, 0.14, 1.7, layer="context")
  for dx in [-1.4, 1.4] {
    for dz in [-1.0, 1.0] {
      primitive(
        p,
        "sphere",
        "rubber",
        x + dx,
        y + 0.42,
        z + dz,
        0.76,
        0.76,
        0.28,
        layer="context",
      )
    }
  }
}

///|
fn road(
  p : Array[Part],
  x : Double,
  z : Double,
  length : Double,
  width : Double,
  y? : Double = 2.25,
) -> Unit {
  box(p, "asphalt", x, y, z, length, 0.12, width, layer="context")
  for i in 0..<(length / 10).to_int() {
    box(
      p,
      "mark",
      x - length / 2 + 4 + i.to_double() * 10,
      y + 0.08,
      z,
      4,
      0.025,
      0.18,
      layer="context",
    )
  }
}

///|
fn campus_ground(p : Array[Part]) -> Unit {
  primitive(p, "round", "earth", 0, -2.6, 0, 310, 8, 224, layer="context")
  primitive(p, "round", "grass", 0, 1.55, 0, 309, 0.7, 223, layer="context")
  primitive(p, "round", "paving", 0, 2.02, 0, 263, 0.25, 151, layer="context")
  road(p, 0, 87, 298, 12)
  road(p, 0, -87, 298, 12)
  for side in [-1.0, 1.0] {
    box(p, "asphalt", side * 140, 2.25, 0, 10, 0.12, 186, layer="context")
    for i in 0..<21 {
      let x = -132.0 + i.to_double() * 13
      tree(p, x, 2, side * 101, i + (if side < 0 { 5 } else { 67 }), size=1.45)
      if i % 3 == 0 {
        lamp(p, x, 2, side * 77)
      }
    }
  }
  for i in 0..<7 {
    car(
      p,
      -120 + i.to_double() * 37,
      2.4,
      if i % 2 == 0 {
        89.5
      } else {
        -89.5
      },
      i,
    )
  }
  for j in 0..<14 {
    box(
      p,
      "paving2",
      -122 + j.to_double() * 18,
      2.18,
      0,
      0.2,
      0.025,
      144,
      layer="context",
    )
  }
  // Pocket gardens soften the paved campus edge without blocking the entries.
  for side in [-1.0, 1.0] {
    for i in 0..<9 {
      let x = -114.0 + i.to_double() * 28
      planter(p, x, 2.22, side * 72, 14, 4, 109 + i * 31)
      if i % 2 == 0 {
        tree(p, x, 3.2, side * 72, 63 + i, size=1.05)
      }
    }
    // Road crossings and flush paving connect the diorama boundary logically.
    for i in 0..<7 {
      box(
        p,
        "mark",
        side * 119 + i.to_double() * 1.1,
        2.34,
        87,
        0.55,
        0.03,
        9,
        layer="context",
      )
    }
  }
}

///|
fn river_ground(p : Array[Part]) -> Unit {
  primitive(p, "round", "earth", 0, -4.0, 0, 358, 7, 238, layer="context")
  box(p, "water", 0, -0.42, 0, 350, 0.32, 230, layer="context")
  for side in [-1.0, 1.0] {
    let land : Array[Array[Double]] = []
    let grass : Array[Array[Double]] = []
    for i in 0..<=48 {
      let z = -116.0 + i.to_double() * 232 / 48
      let edge = side *
        (78 + 8 * @math.sin(z * 0.018) + 4 * @math.cos(z * 0.046))
      land.push([edge, z])
      grass.push([edge + side * 5, z])
    }
    land.append([[side * 176, 116], [side * 176, -116]])
    grass.append([[side * 176, 116], [side * 176, -116]])
    profile(p, "sand", land, 0, -0.2, 0, 2.1, layer="context")
    profile(p, "grass", grass, 0, 1.75, 0, 0.5, layer="context")
    // One continuous path strip: no rotated-box steps at the river curves.
    let path : Array[Array[Double]] = []
    for i in 0..<92 {
      let z = -114.0 + i.to_double() * 228 / 92
      let nz = z + 228.0 / 92
      let x = side * (89 + 8 * @math.sin(z * 0.018) + 4 * @math.cos(z * 0.046))
      let nx = side *
        (89 + 8 * @math.sin(nz * 0.018) + 4 * @math.cos(nz * 0.046))
      quad(path, [x - 1.65, 2.4, z], [x + 1.65, 2.4, z], [nx + 1.65, 2.4, nz], [
        nx - 1.65,
        2.4,
        nz,
      ])
    }
    triangles(p, "paving", path, layer="context")
    for i in 0..<42 {
      let z = -111.0 + i.to_double() * 5.3
      let x = side * (80 + 8 * @math.sin(z * 0.018) + 4 * @math.cos(z * 0.046))
      primitive(
        p,
        "crown",
        "stone",
        x + side * 0.9,
        1.95,
        z + 1.5,
        1.8,
        0.8,
        1.1,
        layer="context",
      )
      for j in 0..<7 {
        let dx = (noise(i * 13 + j) - 0.5) * 1.5
        let dz = (noise(i * 7 + j * 13) - 0.5) * 2
        let h = 0.9 + noise(i * 23 + j) * 1.3
        beam(
          p,
          "sage",
          [x + dx, 1.9, z + dz],
          [x + dx + 0.22, 1.9 + h, z + dz],
          0.035,
          layer="context",
        )
        primitive(
          p,
          "crown",
          "sand",
          x + dx + 0.22,
          1.9 + h,
          z + dz,
          0.2,
          0.48,
          0.2,
          layer="context",
        )
      }
    }
    for i in 0..<92 {
      let z = -107.0 + noise(i * 31 + 5) * 214
      let x = side * (106 + noise(i * 13 + 4) * 60)
      if z.abs() > 27 {
        tree(
          p,
          x,
          2.3,
          z,
          i + (if side < 0 { 106 } else { 240 }),
          size=0.8 + noise(i + 17) * 0.55,
        )
      }
    }
    for i in 0..<12 {
      let z = -103.0 + i.to_double() * 18
      if z.abs() > 27 {
        planter(p, side * 96, 2.2, z, 4, 3, i)
        bench(p, side * 98, 2.3, z + 5)
      }
    }
  }
  for i in 0..<35 {
    let x = -70.0 + noise(i * 13) * 130
    let z = -108.0 + noise(i * 29 + 7) * 216
    box(
      p,
      "ripple",
      x,
      -0.22,
      z,
      1.8 + noise(i) * 4,
      0.02,
      0.07,
      layer="context",
    )
  }
}
