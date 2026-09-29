///|
// Coordinates are manually traced from the supplied photograph, then squared
// to a diagrammatic plan. 0.06 is a presentation scale, not a surveyed scale.
fn plan_x(u : Double) -> Double {
  (u - 840) * 0.06
}

///|
fn plan_z(v : Double) -> Double {
  (v - 710) * 0.06
}

///|
priv struct InteriorZone {
  id : String
  name : String
  area : String
  evidence : String
  proposal : String
  bounds : Array[Double]
} derive(ToJson)

///|
fn interior_zones() -> Array[InteriorZone] {
  [
    {
      id: "306",
      name: "企业办公区",
      area: "557.53 m²",
      evidence: "房号、面积与企业办公用途来自图纸；西侧延伸边界待核实。",
      proposal: "团队工位、讨论桌、文件收纳。",
      bounds: [70, 525, 395, 665],
    },
    {
      id: "307",
      name: "两间独立公用会议室",
      area: "116.44 m² · 照片读数待核实",
      evidence: "图中明确要求分割为两间独立公用会议室。",
      proposal: "两间各自开门的会议室，会议桌与显示屏为方案。",
      bounds: [395, 530, 550, 665],
    },
    {
      id: "308",
      name: "欧中创新中心办公区",
      area: "108.60 m²",
      evidence: "房号、面积及标注用途来自图纸。",
      proposal: "小团队办公与访客讨论区。",
      bounds: [550, 530, 695, 665],
    },
    {
      id: "309",
      name: "路演大厅 · 西区",
      area: "445.88 m²",
      evidence: "309 / 310 所在区域标注路演大厅；内部边界需现场核实。",
      proposal: "可移动座椅、低舞台、演示屏；并非现状装修。",
      bounds: [830, 370, 1140, 655],
    },
    {
      id: "310",
      name: "路演大厅 · 东区",
      area: "454.23 m²",
      evidence: "沿用图纸房号和面积，保留大厅横向联系。",
      proposal: "交流桌、路演溢出区与展陈岛。",
      bounds: [1140, 370, 1435, 655],
    },
    {
      id: "301",
      name: "301 · 功能待定",
      area: "324.96 m²",
      evidence: "照片只清楚给出房号和面积，未指定用途。",
      proposal: "暂作项目展示与讨论空间，可重新分配。",
      bounds: [1435, 370, 1615, 655],
    },
    {
      id: "302",
      name: "302 · 功能待定",
      area: "194.99 m²",
      evidence: "保留原图房号与面积，不推定现有租户。",
      proposal: "暂作协作工作室。",
      bounds: [1480, 885, 1620, 1045],
    },
    {
      id: "303",
      name: "303 · 功能待定",
      area: "251.83 m²",
      evidence: "保留原图房号与面积。",
      proposal: "暂作灵活培训室，桌椅可重排。",
      bounds: [1145, 885, 1480, 1045],
    },
    {
      id: "304",
      name: "五间独立租赁办公室",
      area: "373.72 m²",
      evidence: "图中明确标注分割为 5 间独立隔间办公区。",
      proposal: "五个独立门、五组工位；分隔位置为等分示意。",
      bounds: [540, 885, 1010, 1045],
    },
    {
      id: "305",
      name: "隔间办公 / 创业投融资咨询",
      area: "面积被文字遮挡 · 不作猜测",
      evidence: "两侧隔间办公，中间创业投融资咨询室。",
      proposal: "三间可独立使用的办公室与咨询桌。",
      bounds: [220, 885, 540, 1045],
    },
    {
      id: "social",
      name: "公共交流 · 休息 · 水吧",
      area: "图纸未标面积",
      evidence: "位于 304 与 303 之间的南侧公共区域。",
      proposal: "水吧、软座与圆桌，保持北侧出入口畅通。",
      bounds: [1010, 885, 1145, 1045],
    },
    {
      id: "core-west",
      name: "西侧电梯厅 / 楼梯 / 卫生间",
      area: "服务核心",
      evidence: "依据左侧核心筒位置重建，设备尺寸待核实。",
      proposal: "升降机门、双跑楼梯、卫生间及前室。",
      bounds: [215, 705, 540, 845],
    },
    {
      id: "core-east",
      name: "东侧电梯厅 / 楼梯 / 卫生间",
      area: "服务核心",
      evidence: "依据右侧核心筒位置重建。",
      proposal: "与西侧对应的垂直交通与卫生间。",
      bounds: [1150, 705, 1480, 845],
    },
    {
      id: "atrium",
      name: "中央挑空",
      area: "非三层可用楼面",
      evidence: "图中中央黑框与挑空标记：保留为楼板空洞，不摆工位。",
      proposal: "沿内侧设置护栏；下层仅作暗色深度提示。",
      bounds: [540, 705, 1150, 845],
    },
  ]
}

///|
fn plan_box(
  p : Array[Part],
  mat : String,
  u1 : Double,
  v1 : Double,
  u2 : Double,
  v2 : Double,
  y : Double,
  h : Double,
  layer? : String = "floor",
) -> Unit {
  box(
    p,
    mat,
    plan_x((u1 + u2) / 2),
    y,
    plan_z((v1 + v2) / 2),
    (u2 - u1) * 0.06,
    h,
    (v2 - v1) * 0.06,
    layer~,
  )
}

///|
fn plan_wall(
  p : Array[Part],
  u1 : Double,
  v1 : Double,
  u2 : Double,
  v2 : Double,
  glass? : Bool = false,
) -> Unit {
  let x1 = plan_x(u1)
  let z1 = plan_z(v1)
  let x2 = plan_x(u2)
  let z2 = plan_z(v2)
  let w = (x2 - x1).abs() + 0.18
  let d = (z2 - z1).abs() + 0.18
  box(
    p,
    if glass {
      "partitionGlass"
    } else {
      "plaster"
    },
    (x1 + x2) / 2,
    1.65,
    (z1 + z2) / 2,
    w,
    3.3,
    d,
    layer="walls",
  )
  box(
    p,
    "oak",
    (x1 + x2) / 2,
    0.13,
    (z1 + z2) / 2,
    w + 0.025,
    0.20,
    d + 0.025,
    layer="walls",
  )
  box(
    p,
    "ivory",
    (x1 + x2) / 2,
    3.32,
    (z1 + z2) / 2,
    w + 0.035,
    0.06,
    d + 0.035,
    layer="walls",
  )
}

///|
// Door openings are actual gaps, not doors painted onto solid walls.
fn plan_front(
  p : Array[Part],
  u1 : Double,
  u2 : Double,
  v : Double,
  door : Double,
) -> Unit {
  plan_wall(p, u1, v, door - 12, v, glass=true)
  plan_wall(p, door + 12, v, u2, v, glass=true)
  for u in [door - 12, door + 12] {
    box(p, "metal", plan_x(u), 1.45, plan_z(v), 0.08, 2.9, 0.15, layer="walls")
  }
  box(p, "metal", plan_x(door), 2.91, plan_z(v), 1.5, 0.08, 0.15, layer="walls")
  // Open leaf sits perpendicular beside its jamb; circulation stays clear.
  box(
    p,
    "partitionGlass",
    plan_x(door - 11),
    1.35,
    plan_z(v) + 0.36,
    0.055,
    2.7,
    0.72,
    layer="walls",
  )
}

///|
fn zone_floor(p : Array[Part], zone : InteriorZone, mat : String) -> Unit {
  let b = zone.bounds
  p.push({
    kind: "box",
    material: mat,
    layer: "zones",
    caption: zone.id,
    position: [plan_x((b[0] + b[2]) / 2), 0.012, plan_z((b[1] + b[3]) / 2)],
    scale: [(b[2] - b[0]) * 0.06 - 0.15, 0.035, (b[3] - b[1]) * 0.06 - 0.15],
    rotation: 0,
    points: [],
  })
}
