///|
fn bridge_deck(p : Array[Part], width : Double) -> Unit {
  box(p, "concrete", 0, 9.1, 0, 352, 1.8, width)
  box(p, "asphalt", 0, 10.06, 0, 352, 0.13, width - 8)
  box(p, "stone", 0, 10.24, 0, 352, 0.35, 1.2)
  bridge_fittings(p, width)
  for side in [-1.0, 1.0] {
    box(p, "paving", 0, 10.2, side * (width / 2 - 2), 352, 0.4, 4)
    for i in 0..<89 {
      let x = -175.0 + i.to_double() * 4
      beam(
        p,
        "silver",
        [x, 10.4, side * (width / 2 - 0.3)],
        [x, 11.65, side * (width / 2 - 0.3)],
        0.075,
      )
    }
    for y in [10.8, 11.25, 11.65] {
      beam(
        p,
        "ivory",
        [-176, y, side * (width / 2 - 0.3)],
        [176, y, side * (width / 2 - 0.3)],
        0.095,
      )
    }
    for x in [-152.0, -119.0, -62.0, 0.0, 62.0, 119.0, 152.0] {
      bridge_light(p, x, side * (width / 2 - 4))
    }
    for i in 0..<34 {
      let x = -170.0 + i.to_double() * 10
      for lane in [0.22, 0.39] {
        box(p, "mark", x, 10.15, side * (width - 8) * lane, 4, 0.02, 0.14)
      }
    }
    for i in 0..<7 {
      car(p, -149 + i.to_double() * 48, 10.2, side * 6, i)
    }
    for i in 0..<9 {
      person(p, -106 + i.to_double() * 25, 10.4, side * (width / 2 - 2), i)
    }
    // Approach piers are visible but the ends are a cropped study boundary.
    box(p, "concrete", side * 142, 6, 0, 2.8, 6.5, width - 4)
  }
}

///|
fn v_pier(p : Array[Part], x : Double, width : Double) -> Unit {
  let mesh : Array[Array[Double]] = []
  let front = [
    [x - 2.5, -0.1],
    [x + 2.5, -0.1],
    [x + 6.3, 5.2],
    [x + 12.5, 8.3],
    [x - 12.5, 8.3],
    [x - 6.3, 5.2],
  ]
  for i in 0..<front.length() {
    let a = front[i]
    let b = front[(i + 1) % front.length()]
    quad(
      mesh,
      [a[0], a[1], -width / 2],
      [b[0], b[1], -width / 2],
      [b[0], b[1], width / 2],
      [a[0], a[1], width / 2],
    )
  }
  for side in [-1.0, 1.0] {
    for i in 1..<(front.length() - 1) {
      mesh.append([
        [front[0][0], front[0][1], side * width / 2],
        [front[i][0], front[i][1], side * width / 2],
        [front[i + 1][0], front[i + 1][1], side * width / 2],
      ])
    }
  }
  triangles(p, "concrete", mesh)
}

///|
fn wave_height(t : Double) -> Double {
  // Two high ends and a low middle, as seen in the aerial and side references.
  3.8 + 15.4 * (1 + @math.cos(t * 2 * @math.PI)) / 2
}

///|
fn wave_point(t : Double, angle : Double, side : Double) -> Array[Double] {
  let x = -108.5 + t * 217
  [
    x,
    10.45 + wave_height(t) * @math.sin(angle),
    side * 12.2 + 3.15 * @math.cos(angle),
  ]
}

///|
fn east_bridge() -> Study {
  let p : Array[Part] = []
  river_ground(p)
  bridge_deck(p, 31)
  for x in [-54.0, 54.0] {
    v_pier(p, x, 23)
  }
  // The main roadway is open. Wave lattice encloses the two pedestrian edges.
  for side in [-1.0, 1.0] {
    let segments = 66
    let bands = 10
    for i in 0..<segments {
      let t = i.to_double() / segments.to_double()
      let next = (i + 1).to_double() / segments.to_double()
      for j in 0..<bands {
        let a = j.to_double() * @math.PI / bands.to_double()
        let b = (j + 1).to_double() * @math.PI / bands.to_double()
        girder(
          p,
          "ivory",
          wave_point(t, a, side),
          wave_point(next, b, side),
          0.32,
          0.24,
        )
        girder(
          p,
          "ivory",
          wave_point(t, b, side),
          wave_point(next, a, side),
          0.32,
          0.24,
        )
      }
      for a in [0.0, @math.PI / 2, @math.PI] {
        beam(
          p,
          "ivory",
          wave_point(t, a, side),
          wave_point(next, a, side),
          0.28,
        )
      }
    }
    for end in [0.0, 1.0] {
      for j in 0..<32 {
        beam(
          p,
          "ivory",
          wave_point(end, j.to_double() * @math.PI / 32, side),
          wave_point(end, (j + 1).to_double() * @math.PI / 32, side),
          0.36,
        )
      }
    }
    for i in 0..<=66 {
      for angle in [0.0, @math.PI] {
        let foot = wave_point(i.to_double() / 66, angle, side)
        box(p, "silver", foot[0], 10.52, foot[2], 0.65, 0.16, 0.58)
      }
    }
  }
  {
    id: "east-bridge",
    title: "未来科学城东路桥",
    subtitle: "THE WAVE BRIDGE",
    description: "Two open wave lattices frame the pedestrian edges. An open roadway crosses a planted river corridor, with sculpted piers beneath.",
    note: "217 m main-bridge reference • cropped approaches • lattice and bank geometry interpretive",
    span: 358,
    focus: [0, 9, 0],
    detail_focus: [78, 17, 12],
    detail_offset: [43, 10, 52],
    parts: p,
  }
}

///|
fn arch_point(t : Double, side : Double) -> Array[Double] {
  let rise = @math.sin(@math.PI * t)
  [-104 + 208 * t, 11 + 54 * rise, side * (20.0 - 17.8 * rise)]
}

///|
fn arch_bridge() -> Study {
  let p : Array[Part] = []
  river_ground(p)
  bridge_deck(p, 45)
  for x in [-92.0, 92.0] {
    v_pier(p, x, 32)
  }
  for side in [-1.0, 1.0] {
    let mesh : Array[Array[Double]] = []
    // A closed six-sided swept ribbon. The ribs lean toward one another at the crown.
    for i in 0..<100 {
      let t = i.to_double() / 100
      let nt = (i + 1).to_double() / 100
      let a = arch_point(t, side)
      let b = arch_point(nt, side)
      let depth_a = 2.4 + 6.0 * (1 - @math.sin(@math.PI * t))
      let depth_b = 2.4 + 6.0 * (1 - @math.sin(@math.PI * nt))
      let ring_a : Array[Array[Double]] = []
      let ring_b : Array[Array[Double]] = []
      for j in 0..<6 {
        let angle = j.to_double() * @math.PI / 3
        ring_a.push([
          a[0],
          a[1] + @math.sin(angle) * depth_a,
          a[2] + @math.cos(angle) * 1.4,
        ])
        ring_b.push([
          b[0],
          b[1] + @math.sin(angle) * depth_b,
          b[2] + @math.cos(angle) * 1.4,
        ])
      }
      for j in 0..<6 {
        quad(
          mesh,
          ring_a[j],
          ring_b[j],
          ring_b[(j + 1) % 6],
          ring_a[(j + 1) % 6],
        )
      }
      if i == 0 || i == 99 {
        let ring = if i == 0 { ring_a } else { ring_b }
        for j in 1..<5 {
          mesh.append([ring[0], ring[j], ring[j + 1]])
        }
      }
      beam(
        p,
        "trimLight",
        [a[0], a[1] + depth_a * 0.86, a[2]],
        [b[0], b[1] + depth_b * 0.86, b[2]],
        0.09,
      )
    }
    triangles(p, "ivory", mesh)
    for j in 1..<50 {
      arch_panel_joint(p, j.to_double() / 50, side)
    }
    for i in 1..<25 {
      let t = i.to_double() / 25
      let a = arch_point(t, side)
      let bottom = [a[0], 10.45, side * 16.5]
      let top = [
        a[0],
        a[1] - (2.4 + 6 * (1 - @math.sin(@math.PI * t))) * 0.86,
        a[2],
      ]
      beam(p, "cable", bottom, top, 0.12)
      hanger_fittings(p, bottom, top)
    }
  }
  {
    id: "arch-bridge",
    title: "未来科学城路桥",
    subtitle: "THE SCULPTED ARCH",
    description: "Paired inward-leaning white ribs form a sculptural arch. Slender hangers, a broad deck and V-shaped piers sit above the Wenyu River.",
    note: "45 m deck-width reference • 568 m total bridge, approaches cropped here • arch rise provisional",
    span: 358,
    focus: [0, 22, 0],
    detail_focus: [65, 24, 15],
    detail_offset: [45, 8, 60],
    parts: p,
  }
}
