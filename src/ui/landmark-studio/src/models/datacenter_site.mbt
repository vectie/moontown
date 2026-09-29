///|
fn dc_site() -> ComputeView {
  let p : Array[Part] = []
  dc_box(p, "context", "grass", 0, -0.65, 0, 90, 1, 62)
  dc_box(p, "context", "paving", 0, -0.08, 0, 73, 0.2, 48)
  dc_box(p, "context", "asphalt", 0, 0.06, 24, 83, 0.12, 7)
  for i in 0..<18 {
    dc_box(
      p,
      "context",
      "mark",
      -39.0 + i.to_double() * 4.5,
      0.13,
      24,
      2,
      0.03,
      0.14,
    )
  }
  // Terracotta rainscreen, glazed NOC, standing-seam roof and loading canopy.
  dc_box(p, "hall", "ivory", -4, 0.15, -1, 42, 0.3, 23)
  dc_box(p, "hall", "ivory", -4, 3.25, -12.4, 42, 6.5, 0.2)
  for x in [-24.9, 16.9] {
    dc_box(p, "hall", "ivory", x, 3.25, -1, 0.2, 6.5, 23)
  }
  for row in 0..<2 {
    for col in 0..<6 {
      dc_cabinet(
        p,
        "hall",
        -15.0 + col.to_double() * 3,
        if row == 0 {
          -4
        } else {
          0
        },
        if row == 0 {
          1
        } else {
          -1
        },
      )
    }
  }
  dc_box(p, "hall", "copper", -4, 5.8, 10.56, 42.2, 1.2, 0.22)
  dc_box(p, "hall", "glass", -4, 2.9, 10.59, 40.5, 4.2, 0.12)
  for i in 0..<24 {
    dc_box(
      p,
      "hall",
      "silver",
      -24.0 + i.to_double() * 1.75,
      2.9,
      10.7,
      0.09,
      4.2,
      0.14,
    )
  }
  dc_box(p, "shell", "roof", -4, 6.6, -1, 43, 0.28, 24)
  for i in 0..<31 {
    dc_box(
      p,
      "shell",
      "silver",
      -24.5 + i.to_double() * 1.35,
      6.78,
      -1,
      0.035,
      0.08,
      23.6,
    )
  }
  for i in 0..<7 {
    dc_box(
      p,
      "shell",
      "glass",
      -19.0 + i.to_double() * 5,
      6.85,
      -5,
      3.9,
      0.12,
      5,
    )
  }
  dc_box(p, "hall", "ivory", -14, 3.5, 13, 13, 0.28, 5)
  for x in [-20.0, -8.0] {
    dc_box(p, "hall", "metal", x, 1.7, 14.8, 0.14, 3.4, 0.14)
  }
  sign(p, "MOONTOWN / COMPUTE", -4, 5.75, 10.72, 14, 0.65)
  // Visible secondary facilities, not anonymous boxes.
  for i in 0..<3 {
    let x = 22.0 + i.to_double() * 5
    dc_box(p, "cooling", "concrete", x, 0.25, -4, 4.4, 0.5, 11)
    dc_box(p, "cooling", "ivory", x, 2, -4, 3.7, 3, 9)
    for j in 0..<3 {
      primitive(
        p,
        "cylinder",
        "rubber",
        x,
        3.56,
        -7.0 + j.to_double() * 3,
        2.4,
        0.15,
        2.4,
        layer="cooling",
      )
      for spoke in 0..<6 {
        let a = spoke.to_double() * @math.PI / 3
        beam(
          p,
          "silver",
          [x, 3.67, -7.0 + j.to_double() * 3],
          [x + @math.cos(a), 3.67, -7.0 + j.to_double() * 3 + @math.sin(a)],
          0.09,
          layer="cooling",
        )
      }
    }
    for j in 0..<15 {
      dc_box(
        p,
        "cooling",
        "metal",
        x + 1.88,
        0.8 + j.to_double() * 0.17,
        -4,
        0.05,
        0.055,
        8.6,
      )
    }
  }
  dc_box(p, "power", "ivory", -18, 1.7, -21, 16, 3.4, 5)
  for i in 0..<6 {
    dc_box(
      p,
      "power",
      "metal",
      -24.5 + i.to_double() * 2.6,
      1.6,
      -18.44,
      2.35,
      2.7,
      0.06,
    )
    dc_box(
      p,
      "power",
      "amber",
      -24.5 + i.to_double() * 2.6,
      2.3,
      -18.38,
      0.35,
      0.28,
      0.06,
    )
  }
  dc_box(p, "generator", "sage", 7, 1.5, -21, 12, 3, 4.5)
  for i in 0..<18 {
    dc_box(
      p,
      "generator",
      "rubber",
      2.0 + i.to_double() * 0.6,
      1.6,
      -18.72,
      0.17,
      2.2,
      0.04,
    )
  }
  for x in [3.0, 10.0] {
    primitive(
      p,
      "cylinder",
      "metal",
      x,
      4,
      -21,
      0.3,
      2.4,
      0.3,
      layer="generator",
    )
  }
  for i in 0..<9 {
    tree(p, -38, 0, -23.0 + i.to_double() * 5.4, 30 + i, size=0.43)
  }
  for i in 0..<6 {
    tree(p, 35, 0, 5.0 + i.to_double() * 3, 80 + i, size=0.3)
  }
  for x in [-30.0, 19.0, 32.0] {
    person(p, x, 0, 17, 4)
  }
  return dc_view(
    "site",
    "一座可读的数据中心",
    "SITE / 从建筑外部开始",
    92,
    [0, 1, 0],
    [58, 57, 70],
    p,
    [
      dc_entity(
        "hall",
        "01 · 计算机房",
        "BUILDING",
        [-4, 6.8, 4],
        "进入机房，查看成对机柜、冷通道、热回风与上走线。建筑是设计提案，不代表现有机房。",
        visit="hall",
      ),
      dc_entity(
        "cooling",
        "02 · 冷却设备区",
        "MECHANICAL",
        [27, 4, -4],
        "风冷冷水机组把热量排向室外。冷冻水供回水连接室内 CRAH 换热盘管；机柜内部仍为空气冷却。",
        visit="hall",
      ),
      dc_entity(
        "power",
        "03 · 配电与 UPS",
        "ELECTRICAL",
        [-18, 3.5, -21],
        "市电经配电、UPS 与 A/B 配电路径到达机架 PDU。双路径仅为设计示意，未验证独立性或冗余等级。",
        visit="hall",
      ),
      dc_entity(
        "generator",
        "04 · 备用发电机",
        "STANDBY",
        [7, 3.5, -21],
        "备用电源经切换设备接入配电。正常模式下不画成已发电；此模型不模拟切换瞬态或续航。",
      ),
    ],
    [
      dc_flow(
        "site-data",
        "data",
        "MoonGate → 机房网络",
        "逻辑请求路径，不是抓包或光纤实测。远端模型服务不属于本地物理机架。",
        [[-34, 1, 15], [-29, 1, 15], [-29, 1, 2], [-4, 1, 2]],
      ),
      dc_flow(
        "site-power",
        "power",
        "市电 → 配电 / UPS → 机房",
        "箭头表达能量传递方向，不代表交流电子以箭头速度移动。备用发电机不在正常供电路径内。",
        [
          [-34, 0.7, -21],
          [-18, 0.7, -21],
          [-18, 0.7, -14],
          [-4, 0.7, -14],
          [-4, 0.7, 2],
        ],
      ),
      dc_flow(
        "site-cold",
        "cooling",
        "冷冻水供水",
        "冷水机组 → CRAH 盘管；与机柜空气流不是同一回路。",
        [
          [27, 0.9, -4],
          [20, 0.9, -4],
          [20, 0.9, -15],
          [12, 0.9, -15],
          [12, 0.9, -7],
        ],
      ),
      dc_flow(
        "site-hot",
        "heat",
        "冷冻水回水",
        "CRAH 吸收机房热量后回到冷水机组，最终向室外排热。",
        [
          [10, 1.1, -7],
          [10, 1.1, -16],
          [21, 1.1, -16],
          [21, 1.1, -6],
          [27, 1.1, -6],
        ],
      ),
    ],
  )
}
