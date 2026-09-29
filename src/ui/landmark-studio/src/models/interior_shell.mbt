///|
fn interior_shell(p : Array[Part]) -> Unit {
  // Six slab regions preserve the asymmetric outer boundary and atrium opening.
  let slabs = [
    [60.0, 520.0, 540.0, 1050.0],
    [540.0, 530.0, 820.0, 705.0],
    [820.0, 365.0, 1150.0, 705.0],
    [1150.0, 365.0, 1620.0, 1050.0],
    [540.0, 845.0, 1150.0, 1050.0],
  ]
  for b in slabs {
    plan_box(p, "plaster", b[0], b[1], b[2], b[3], -0.23, 0.46)
    plan_box(p, "plaster", b[0], b[1], b[2], b[3], 3.5, 0.16, layer="ceiling")
  }
  // Depth cue below the opening is context, never a walkable third-floor slab.
  plan_box(p, "earth", 540, 705, 1150, 845, -4.0, 0.15, layer="context")
  let perimeter = [
    [60.0, 520.0],
    [820.0, 520.0],
    [820.0, 365.0],
    [1620.0, 365.0],
    [1620.0, 1050.0],
    [60.0, 1050.0],
  ]
  for i in 0..<perimeter.length() {
    let a = perimeter[i]
    let b = perimeter[(i + 1) % perimeter.length()]
    plan_wall(p, a[0], a[1], b[0], b[1], glass=true)
    let length = (b[0] - a[0]).abs() + (b[1] - a[1]).abs()
    for j in 0..<=(length / 32).to_int() {
      let t = j.to_double() / (length / 32).to_int().to_double()
      box(
        p,
        "ivory",
        plan_x(mix(a[0], b[0], t)),
        1.7,
        plan_z(mix(a[1], b[1], t)),
        0.12,
        3.4,
        0.12,
        layer="walls",
      )
    }
  }
  // Atrium balustrade: human-scale glass and posts, not a sealed central room.
  for side in [705.0, 845.0] {
    plan_box(
      p,
      "partitionGlass",
      540,
      side,
      1150,
      side + 1,
      0.6,
      1.2,
      layer="structure",
    )
    beam(
      p,
      "silver",
      [plan_x(540), 1.22, plan_z(side)],
      [plan_x(1150), 1.22, plan_z(side)],
      0.035,
      layer="structure",
    )
    for i in 0..<=24 {
      box(
        p,
        "metal",
        plan_x(540 + i.to_double() * 610 / 24),
        0.6,
        plan_z(side),
        0.045,
        1.2,
        0.045,
        layer="structure",
      )
    }
  }
  for side in [540.0, 1150.0] {
    plan_box(
      p,
      "partitionGlass",
      side,
      705,
      side + 1,
      845,
      0.6,
      1.2,
      layer="structure",
    )
    beam(
      p,
      "silver",
      [plan_x(side), 1.22, plan_z(705)],
      [plan_x(side), 1.22, plan_z(845)],
      0.035,
      layer="structure",
    )
  }
  // Columns traced from the repeated dark squares on the source plan.
  for v in [535.0, 700.0, 845.0, 1030.0] {
    for
      u in [
        80.0, 240.0, 395.0, 540.0, 695.0, 845.0, 995.0, 1150.0, 1300.0, 1450.0, 1600.0,
      ] {
      if !(v == 845 && u > 540 && u < 1150) {
        box(
          p,
          "plaster",
          plan_x(u),
          1.68,
          plan_z(v),
          0.48,
          3.36,
          0.48,
          layer="structure",
        )
      }
    }
  }
  for u in [845.0, 995.0, 1140.0, 1290.0, 1440.0, 1590.0] {
    box(
      p,
      "plaster",
      plan_x(u),
      1.68,
      plan_z(390),
      0.48,
      3.36,
      0.48,
      layer="structure",
    )
  }
  // North rooms. 307 has the two explicitly requested independently accessed rooms.
  for u in [395.0, 472.0, 550.0, 695.0, 830.0] {
    plan_wall(p, u, 530, u, 665)
  }
  plan_front(p, 70, 395, 665, 365)
  plan_front(p, 395, 472, 665, 437)
  plan_front(p, 472, 550, 665, 512)
  plan_front(p, 550, 695, 665, 647)
  plan_front(p, 695, 830, 665, 778)
  plan_front(p, 830, 1140, 665, 1020)
  plan_front(p, 1140, 1435, 665, 1320)
  plan_front(p, 1435, 1615, 665, 1480)
  plan_wall(p, 1435, 370, 1435, 655, glass=true)
  // South rooms: five 304 offices, three 305 spaces, social zone, 303 and 302.
  for i in 0..<5 {
    let u = 540.0 + i.to_double() * 94
    plan_wall(p, u, 885, u, 1045, glass=true)
    plan_front(p, u, u + 94, 885, u + 47)
  }
  for i in 0..<3 {
    let u = 220.0 + i.to_double() * 320 / 3
    plan_wall(p, u, 885, u, 1045, glass=true)
    plan_front(p, u, u + 320.0 / 3, 885, u + 53)
  }
  plan_wall(p, 1010, 885, 1010, 1045)
  plan_wall(p, 1145, 885, 1145, 1045)
  plan_front(p, 1145, 1480, 885, 1330)
  plan_wall(p, 1480, 885, 1480, 1045, glass=true)
  plan_front(p, 1480, 1620, 885, 1535)
  // Suspended linear luminaires remain visible with the ceiling hidden.
  for
    uv in [
      [220.0, 585.0],
      [435.0, 592.0],
      [510.0, 592.0],
      [625.0, 585.0],
      [960.0, 475.0],
      [960.0, 575.0],
      [1290.0, 460.0],
      [1290.0, 560.0],
      [1525.0, 470.0],
      [270.0, 955.0],
      [380.0, 955.0],
      [485.0, 955.0],
      [587.0, 955.0],
      [681.0, 955.0],
      [775.0, 955.0],
      [869.0, 955.0],
      [963.0, 955.0],
      [1070.0, 970.0],
      [1280.0, 970.0],
      [1550.0, 960.0],
    ] {
    box(
      p,
      "metal",
      plan_x(uv[0]),
      3.03,
      plan_z(uv[1]),
      2.5,
      0.09,
      0.12,
      layer="lighting",
    )
    box(
      p,
      "lamp",
      plan_x(uv[0]),
      2.98,
      plan_z(uv[1]),
      2.4,
      0.035,
      0.09,
      layer="lighting",
    )
  }
}

///|
fn service_core(p : Array[Part], east : Bool) -> Unit {
  let start = if east { 1305.0 } else { 215.0 }
  let stair = if east { 1307.0 } else { 335.0 }
  let toilets = if east { 1370.0 } else { 220.0 }
  plan_wall(p, start, 705, start + 175, 705)
  plan_wall(p, start, 845, start + 175, 845)
  for u in [start, start + 175] {
    plan_wall(p, u, 705, u, 760)
    plan_wall(p, u, 788, u, 845)
  }
  // Two short visible flights, landing and central divider; indicative dimensions.
  for i in 0..<12 {
    let y = i.to_double() * 0.14
    plan_box(
      p,
      "paving2",
      stair + 4,
      722 + i.to_double() * 6,
      stair + 22,
      728 + i.to_double() * 6,
      y / 2,
      y + 0.1,
      layer="structure",
    )
    plan_box(
      p,
      "paving2",
      stair + 27,
      788 - i.to_double() * 6,
      stair + 45,
      794 - i.to_double() * 6,
      0.85 + y / 2,
      1.7 + y,
      layer="structure",
    )
  }
  plan_box(
    p,
    "paving2",
    stair + 4,
    794,
    stair + 45,
    811,
    1.72,
    0.13,
    layer="structure",
  )
  for v in [728.0, 790.0] {
    for i in 0..<3 {
      let u = toilets + 10 + i.to_double() * 28
      plan_wall(p, u, v, u, v + 42)
      primitive(
        p,
        "sphere",
        "ivory",
        plan_x(u + 13),
        0.33,
        plan_z(v + 24),
        0.42,
        0.38,
        0.58,
        layer="furniture",
      )
      box(
        p,
        "ivory",
        plan_x(u + 13),
        0.61,
        plan_z(v + 5),
        0.45,
        0.6,
        0.15,
        layer="furniture",
      )
    }
  }
  plan_wall(p, toilets, 775, toilets + 94, 775)
  let lift = if east { 1250.0 } else { 410.0 }
  for v in [732.0, 808.0] {
    plan_box(
      p,
      "plaster",
      lift - 20,
      v - 25,
      lift + 20,
      v + 25,
      1.65,
      3.3,
      layer="walls",
    )
    let face = if east { lift - 20.5 } else { lift + 20.5 }
    box(
      p,
      "silver",
      plan_x(face),
      1.25,
      plan_z(v),
      0.05,
      2.5,
      1.32,
      layer="walls",
    )
    box(
      p,
      "metal",
      plan_x(face) + (if east { -0.035 } else { 0.035 }),
      1.25,
      plan_z(v),
      0.02,
      2.5,
      0.022,
      layer="walls",
    )
  }
}

///|
/// A separate reference-plan interior study; not included in the four landmark selector.
pub fn interior_study() -> Json {
  let p : Array[Part] = []
  interior_shell(p)
  let zones = interior_zones()
  for zone in zones {
    if zone.id != "atrium" {
      zone_floor(
        p,
        zone,
        match zone.id {
          "304" | "306" | "308" => "carpetSage"
          "307" | "305" => "carpetRose"
          "social" => "oak"
          "core-west" | "core-east" => "paving2"
          _ => "carpetSand"
        },
      )
    }
  }
  service_core(p, false)
  service_core(p, true)
  interior_furniture(p)
  let study : Study = {
    id: "interior-g3",
    title: "未来中心 G座 · 三层",
    subtitle: "REFERENCE-PLAN INTERIOR",
    description: "A new floor-plan-led interior study: central atrium, two service cores, perimeter workspaces and a shared roadshow hall.",
    note: "Layout traced from user photograph • dimensions and fit-out provisional • no live agents connected",
    span: 110,
    focus: [0, 18, 0],
    detail_focus: [14, 1, 16],
    detail_offset: [12, 12, 16],
    parts: p,
  }
  {
    "study": ToJson::to_json(study),
    "zones": zones.to_json(),
    "subdivisions": [
      { "parent": "304", "ids": ["304-1", "304-2", "304-3", "304-4", "304-5"] },
      { "parent": "307", "ids": ["307-A", "307-B"] },
    ],
    "source": "private functional plan (not bundled)",
  }
}
