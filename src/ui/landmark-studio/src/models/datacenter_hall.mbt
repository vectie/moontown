///|
// Rack archetype: 42U frame, twelve 2U chassis at U03–26, two 1U switches.
// Scale and yaw are applied to every child, maintaining a single orientation.
fn dc_cabinet(
  p : Array[Part],
  id : String,
  x : Double,
  z : Double,
  facing : Double,
) -> Unit {
  let q : Array[Part] = []
  dc_box(q, id, "rubber", 0, 0.09, 0, 0.8, 0.18, 1.2)
  dc_box(q, id, "metal", 0, 2.09, 0, 0.8, 0.12, 1.2)
  for a in [-0.37, 0.37] {
    for b in [-0.55, 0.55] {
      dc_box(q, id, "metal", a, 1.12, b, 0.055, 1.95, 0.055)
    }
  }
  for i in 0..<12 {
    let y = 0.23 + (i.to_double() * 2 + 2) * 0.04445
    dc_box(
      q,
      id,
      if i % 3 == 0 {
        "silver"
      } else {
        "navy"
      },
      0,
      y + 0.04,
      0,
      0.69,
      0.084,
      1.04,
    )
    for bay in 0..<6 {
      dc_box(
        q,
        id,
        "rubber",
        -0.277 + bay.to_double() * 0.11,
        y + 0.04,
        0.526,
        0.095,
        0.063,
        0.014,
      )
    }
    dc_box(q, id, "screen", 0.322, y + 0.055, 0.54, 0.015, 0.012, 0.01)
  }
  for y in [1.94, 1.895] {
    dc_box(q, id, "silver", 0, y, 0, 0.69, 0.041, 0.9)
    for i in 0..<12 {
      dc_box(
        q,
        id,
        "rubber",
        -0.3 + i.to_double() * 0.054,
        y,
        0.46,
        0.032,
        0.022,
        0.02,
      )
    }
  }
  dc_box(q, id, "metal", 0, 1.66, 0.53, 0.69, 0.41, 0.018)
  for side in [-1.0, 1.0] {
    dc_box(
      q,
      id,
      if side < 0 {
        "copper"
      } else {
        "screen"
      },
      side * 0.31,
      1.04,
      -0.55,
      0.055,
      1.6,
      0.06,
    )
  }
  for part in q {
    p.push({
      ..part,
      position: [
        x + part.position[0] * facing,
        part.position[1],
        z + part.position[2] * facing,
      ],
      rotation: if facing < 0 {
        @math.PI
      } else {
        0
      },
    })
  }
}

///|
fn dc_hall() -> ComputeView {
  let p : Array[Part] = []
  let entities : Array[ComputeEntity] = []
  dc_box(p, "context", "concrete", 0, -0.22, 0, 14, 0.4, 13)
  for x in 0..<14 {
    for z in 0..<13 {
      dc_box(
        p,
        "context",
        "ivory",
        -6.5 + x.to_double(),
        0.015,
        -6.0 + z.to_double(),
        0.975,
        0.045,
        0.975,
      )
    }
  }
  dc_box(p, "walls", "plaster", 0, 2.25, -6.3, 14, 4.5, 0.2)
  dc_box(p, "walls", "plaster", -6.8, 2.25, 0, 0.2, 4.5, 12.5)
  dc_box(p, "shell", "ivory", 0, 4.65, 0, 14, 0.2, 13)
  // Cold aisle between inward-facing rack fronts; hot exhaust outside rows.
  dc_box(p, "cold-aisle", "screen", 0, 0.055, 0, 5.3, 0.055, 2.9)
  for z in [-3.55, 3.55] {
    dc_box(p, "hot-aisle", "terracotta", 0, 0.055, z, 5.3, 0.055, 1.3)
  }
  for row in 0..<2 {
    let z = if row == 0 { -2.0 } else { 2.0 }
    for col in 0..<6 {
      let x = -2.125 + col.to_double() * 0.85
      let id = "\{if row == 0 { "A" } else { "B" }}\{col + 1}"
      dc_cabinet(p, id, x, z, if row == 0 { 1 } else { -1 })
      if col < 5 {
        dc_box(p, "containment", "metal", x + 0.425, 1.1, z, 0.05, 2.1, 1.2)
      }
      entities.push(
        dc_entity(
          id,
          "机柜 \{id}",
          "42U / DESIGN",
          [x, 2.25, z],
          "12 台 2U 服务器 + 2 台 1U 交换机；26 / 42U。8 kW 是规划容量，不是传感器读数。物理位置未绑定真实节点。",
          visit="rack",
        ),
      )
    }
    for x in [-2.64, 2.64] {
      dc_box(p, "containment", "silver", x, 1.1, z * 0.725, 0.08, 2.2, 0.08)
    }
    dc_box(p, "containment", "silver", 0, 2.18, z * 0.725, 5.3, 0.08, 0.08)
    // Open ladder tray: beams and rungs instead of solid hovering roads.
    for offset in [-0.22, 0.22] {
      dc_box(p, "network", "metal", 0, 3.55, z + offset, 6, 0.08, 0.06)
    }
    for i in 0..<15 {
      dc_box(
        p,
        "network",
        "metal",
        -2.8 + i.to_double() * 0.4,
        3.53,
        z,
        0.035,
        0.045,
        0.5,
      )
    }
    for x in [-4.0, 0.0, 4.0] {
      dc_box(p, "context", "trimLight", x, 4.3, z, 2, 0.06, 0.12)
    }
  }
  dc_box(p, "containment", "partitionGlass", 0, 2.2, 0, 5.3, 0.045, 2.9)
  for x in [-2.64, 2.64] {
    dc_box(p, "containment", "partitionGlass", x, 1.1, 0, 0.045, 2.2, 2.9)
  }
  for x in [-3.0, 0.0, 3.0] {
    dc_box(p, "cooling", "ivory", x, 1.45, -5.4, 2, 2.9, 1.1)
    for j in 0..<16 {
      dc_box(
        p,
        "cooling",
        "metal",
        x,
        0.3 + j.to_double() * 0.15,
        -4.82,
        1.75,
        0.06,
        0.05,
      )
    }
    dc_box(p, "cooling", "screen", x, 2.55, -4.8, 0.6, 0.22, 0.06)
  }
  for i in 0..<4 {
    dc_box(
      p,
      "power",
      if i % 2 == 0 {
        "metal"
      } else {
        "ivory"
      },
      -5.5,
      1.3,
      -3.5 + i.to_double() * 2.2,
      1.2,
      2.6,
      1.5,
    )
    dc_box(
      p,
      "power",
      "amber",
      -4.86,
      1.9,
      -3.5 + i.to_double() * 2.2,
      0.04,
      0.3,
      0.45,
    )
  }
  for i in 0..<2 {
    dc_box(
      p,
      "network",
      "navy",
      5.5,
      1.5,
      -1.5 + i.to_double() * 3,
      1.2,
      3,
      1.2,
    )
    for j in 0..<8 {
      dc_box(
        p,
        "network",
        "silver",
        5.5,
        0.45 + j.to_double() * 0.3,
        -0.88 + i.to_double() * 3,
        1.05,
        0.16,
        0.03,
      )
    }
  }
  entities.push(
    dc_entity(
      "cooling",
      "CRAH / 空气处理",
      "COOLING",
      [0, 3.15, -5.4],
      "回风经过冷冻水盘管降温，送入架空地板和冷通道。冷风穿过服务器后从热通道回流。温度与风量尚未接入。",
    ),
  )
  entities.push(
    dc_entity(
      "power",
      "UPS + A/B 配电",
      "POWER",
      [-5.5, 2.9, -0.5],
      "A/B 配电至机柜双 PDU。没有配电单线图与实测负荷，不能据此声明 2N / N+1 或可用性。",
    ),
  )
  entities.push(
    dc_entity(
      "network",
      "双 Spine / 网络区",
      "NETWORK",
      [5.5, 3.3, 0],
      "机架 ToR 作为 leaf 连接两台 spine。机架间流量经 leaf → spine → leaf；MoonGate 是逻辑服务入口，不是交换机。",
    ),
  )
  entities.push(
    dc_entity(
      "cold-aisle",
      "封闭冷通道",
      "AIR MANAGEMENT",
      [0, 0.2, 0],
      "两排服务器进风口相对，冷通道端门与顶盖限制冷热气流混合。透明罩可以隐藏查看机架。",
    ),
  )
  return dc_view(
    "hall",
    "从机房到每一台机柜",
    "HALL 01 / 12 个设计机位",
    16,
    [0, 1, 0],
    [13, 18, 20],
    p,
    entities,
    [
      dc_flow(
        "hall-eastwest",
        "data",
        "A1 → Leaf A → Spine → Leaf B → B1",
        "光/电链路承载帧与数据包；双向通信中此动画只展示一个方向。不是实际业务或逐包追踪。",
        [
          [-2.125, 1.95, -2],
          [-2.125, 3.65, -2],
          [5.5, 3.65, -2],
          [5.5, 3.65, 2],
          [-2.125, 3.65, 2],
          [-2.125, 1.95, 2],
        ],
      ),
      dc_flow(
        "hall-a",
        "power",
        "UPS / A 路 → 机柜 PDU",
        "铜色为 A 路供电。线路位置是示意路径，没有实际电缆长度或断路器负载证据。",
        [
          [-5.5, 1.5, -3.5],
          [-4, 1.5, -3.5],
          [-4, 0.15, -2.8],
          [-2.125, 0.15, -2.8],
          [-2.125, 1, -2.55],
        ],
      ),
      dc_flow(
        "hall-b",
        "power",
        "UPS / B 路 → 机柜 PDU",
        "独立配电路径的设计意图，尚未验证上游故障域是否独立。",
        [
          [-5.5, 1.5, 3],
          [-4, 1.5, 3],
          [-4, 0.2, 2.8],
          [-2.125, 0.2, 2.8],
          [-2.125, 1, 2.55],
        ],
      ),
      dc_flow(
        "hall-cold",
        "cooling",
        "CRAH → 地板送风 → 冷通道 → 服务器",
        "蓝色为空气，不是流入服务器的水。动效速度不表示实际风速。",
        [
          [0, 1, -5.4],
          [0, -0.1, -4.5],
          [0, -0.1, 0],
          [0, 1, 0],
          [-2.125, 1, 0],
          [-2.125, 1, -1.5],
        ],
      ),
      dc_flow(
        "hall-hot",
        "heat",
        "服务器排风 → 热通道 → CRAH 回风",
        "热量随排风回到换热盘管，再通过冷冻水回路向室外排出。",
        [
          [-2.125, 1, -2.6],
          [-2.125, 1, -3.6],
          [-2.125, 3.2, -3.6],
          [0, 3.2, -4.5],
          [0, 2.2, -5.4],
        ],
      ),
    ],
  )
}

///|
fn dc_rack() -> ComputeView {
  let p : Array[Part] = []
  dc_cabinet(p, "frame", 0, 0, 1)
  // Remove archetype server bodies so every installed chassis is selectable.
  let filtered = p
    .filter(part => {
      !(part.position[1] > 0.31 &&
      part.position[1] < 1.39 &&
      part.scale[0] < 0.71 &&
      part.scale[1] < 0.09)
    })
    .map(part => {
      if part.position[1] > 1.87 &&
        part.position[1] < 1.97 &&
        part.scale[1] < 0.05 {
        { ..part, layer: "switch", }
      } else if part.scale[0] == 0.055 && part.scale[1] == 1.6 {
        { ..part, layer: if part.position[0] < 0 { "pdu-a" } else { "pdu-b" }, }
      } else {
        part
      }
    })
  let entities : Array[ComputeEntity] = []
  for i in 0..<12 {
    let u = 3 + i * 2
    let id = "U\{u}"
    let y = 0.23 + (u - 1).to_double() * 0.04445 + 0.04
    dc_box(filtered, id, "navy", 0, y, 0, 0.69, 0.084, 1.04)
    for bay in 0..<8 {
      let x = -0.294 + bay.to_double() * 0.084
      dc_box(filtered, id, "silver", x, y, 0.53, 0.075, 0.064, 0.045)
      dc_box(filtered, id, "rubber", x, y, 0.556, 0.056, 0.043, 0.009)
      dc_box(
        filtered,
        id,
        "screen",
        x + 0.023,
        y + 0.014,
        0.563,
        0.006,
        0.008,
        0.003,
      )
    }
    for x in [-0.36, 0.36] {
      dc_box(filtered, id, "silver", x, y, 0.58, 0.032, 0.06, 0.06)
    }
    entities.push(
      dc_entity(
        id,
        "U\{u}–\{u + 1} / 计算节点",
        "2U / CONCEPT",
        [0, y, 0.59],
        "可抽取的通用 2U 服务器。机位编号真实对应本设计模型；不是 LunaNexa 的物理资产绑定。",
        visit="server",
      ),
    )
  }
  for i in 0..<42 {
    let y = 0.23 + i.to_double() * 0.04445
    for x in [-0.37, 0.37] {
      for h in [0.008, 0.024, 0.037] {
        dc_box(
          filtered,
          "frame",
          "rubber",
          x,
          y + h,
          0.582,
          0.014,
          0.009,
          0.008,
        )
      }
    }
  }
  for side in [-1.0, 1.0] {
    let id = if side < 0 { "pdu-a" } else { "pdu-b" }
    for i in 0..<12 {
      dc_box(
        filtered,
        id,
        "rubber",
        side * 0.31,
        0.35 + i.to_double() * 0.12,
        -0.59,
        0.035,
        0.06,
        0.02,
      )
    }
    entities.push(
      dc_entity(
        id,
        if side < 0 {
          "PDU A"
        } else {
          "PDU B"
        },
        "POWER",
        [side * 0.38, 1.15, -0.58],
        "后置竖向 PDU 为服务器双 PSU 供电。切换到背面检查供电与网络接口。电流、电压和温度未采集。",
      ),
    )
  }
  entities.push(
    dc_entity(
      "switch",
      "ToR A / B",
      "LEAF SWITCH",
      [0, 1.98, 0.5],
      "双交换机占用 U38–39，每台下接服务器、上联 spine。端口数量与跳线为通用设计。",
    ),
  )
  // Patch leads with three segments; front service loops remain clear of fans.
  for i in 0..<12 {
    let y = 0.36 + i.to_double() * 0.089
    beam(
      filtered,
      "screen",
      [0.24, y, -0.53],
      [0.45, y, -0.73],
      0.006,
      layer="switch",
    )
    beam(
      filtered,
      "screen",
      [0.45, y, -0.73],
      [0.45, 1.93, -0.73],
      0.006,
      layer="switch",
    )
    beam(
      filtered,
      "screen",
      [0.45, 1.93, -0.73],
      [0.23, 1.93, -0.46],
      0.006,
      layer="switch",
    )
  }
  dc_box(filtered, "context", "paving", 0, -0.035, 0, 2.4, 0.07, 2.3)
  return dc_view(
    "rack",
    "一柜一档 · 可追溯到机位",
    "RACK / 42U 双路供电",
    3,
    [0, 1.05, 0],
    [2.5, 1.6, 3.6],
    filtered,
    entities,
    [
      dc_flow(
        "rack-data",
        "data",
        "Spine 上联 → ToR → NIC",
        "青色路径示意链路方向。链路速率、丢包和端口状态都没有实测。",
        [
          [0, 2.35, -0.7],
          [0, 1.93, -0.5],
          [0.48, 1.93, -0.75],
          [0.48, 0.36, -0.75],
          [0.24, 0.36, -0.53],
        ],
      ),
      dc_flow(
        "rack-power-a",
        "power",
        "PDU A → PSU A",
        "交流供电进入服务器电源模块。额定功率不能替代实际功耗。",
        [[-0.31, 1.1, -0.61], [-0.31, 0.36, -0.7], [-0.18, 0.36, -0.53]],
      ),
      dc_flow(
        "rack-power-b",
        "power",
        "PDU B → PSU B",
        "B 路连接第二电源模块，冗余能力取决于每一路容量和共同故障点。",
        [[0.31, 1.1, -0.61], [0.31, 0.36, -0.7], [0.12, 0.36, -0.53]],
      ),
      dc_flow(
        "rack-cold",
        "cooling",
        "冷通道 → 前面板进风",
        "服务器正面朝冷通道。",
        [[0, 0.7, 1.05], [0, 0.7, 0.3]],
      ),
      dc_flow(
        "rack-hot",
        "heat",
        "后面板排风 → 热通道",
        "空气通过机内热源后进入后方热通道。",
        [[0, 0.7, -0.3], [0, 0.7, -1.05]],
      ),
    ],
  )
}
