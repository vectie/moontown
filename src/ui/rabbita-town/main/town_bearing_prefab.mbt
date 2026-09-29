///|
/// A small 3D architectural kit. Mesh construction and geographic orientation
/// are MoonBit; the browser boundary only paints projected quads.
priv struct TownBearingVertex {
  u : Double
  v : Double
  z : Double
}

///|
priv struct TownBearingMesh {
  points : Array[Double]
  colors : Array[String]
}

///|
priv struct TownBearingBlock {
  u : Double
  v : Double
  width : Double
  depth : Double
  floors : Int
}

///|
fn town_bearing_quad(
  mesh : TownBearingMesh,
  bearing : TownBuildingBearing,
  span : Double,
  ps : Array[TownBearingVertex],
  color : String,
) -> Unit {
  for p in ps {
    mesh.points.push((bearing.east.x * p.u + bearing.north.x * p.v) * span)
    mesh.points.push((bearing.east.y * p.u + bearing.north.y * p.v) * span)
    mesh.points.push(p.z * span)
  }
  mesh.colors.push(color)
}

///|
fn town_bearing_roof(
  mesh : TownBearingMesh,
  bearing : TownBuildingBearing,
  span : Double,
  u : Double,
  v : Double,
  w : Double,
  d : Double,
  z : Double,
  color : String,
) -> Unit {
  town_bearing_quad(
    mesh,
    bearing,
    span,
    [
      { u: u - w / 2.0, v: v - d / 2.0, z, },
      { u: u + w / 2.0, v: v - d / 2.0, z, },
      { u: u + w / 2.0, v: v + d / 2.0, z, },
      { u: u - w / 2.0, v: v + d / 2.0, z, },
    ],
    color,
  )
}

///|
fn town_bearing_box(
  mesh : TownBearingMesh,
  bearing : TownBuildingBearing,
  span : Double,
  u : Double,
  v : Double,
  w : Double,
  d : Double,
  bottom : Double,
  top : Double,
  wall : String,
  roof : String,
) -> Unit {
  let corners : Array[(Double, Double)] = [
    (u - w / 2.0, v - d / 2.0),
    (u + w / 2.0, v - d / 2.0),
    (u + w / 2.0, v + d / 2.0),
    (u - w / 2.0, v + d / 2.0),
  ]
  for i in 0..<4 {
    let (a, b) = corners[i]
    let (c, d) = corners[(i + 1) % 4]
    // Geographic-axis winding is clockwise on screen. Positive projected dx
    // selects only the observer-facing walls, regardless of the lot's bearing.
    let dx = (bearing.east.x - bearing.east.y) * (c - a) +
      (bearing.north.x - bearing.north.y) * (d - b)
    if dx <= 0.0 {
      continue
    }
    town_bearing_quad(
      mesh,
      bearing,
      span,
      [
        { u: a, v: b, z: bottom, },
        { u: c, v: d, z: bottom, },
        { u: c, v: d, z: top, },
        { u: a, v: b, z: top, },
      ],
      if i == 0 {
        wall
      } else {
        "#d9d5c7"
      },
    )
  }
  town_bearing_roof(mesh, bearing, span, u, v, w, d, top, roof)
}

///|
fn town_bearing_facade(
  mesh : TownBearingMesh,
  bearing : TownBuildingBearing,
  span : Double,
  block : TownBearingBlock,
  side : Int,
) -> Unit {
  let south = side == 0
  let along : WenyuScenePoint = if south { bearing.east } else { bearing.north }
  if along.x - along.y <= 0.0 {
    return
  }
  let panels = if south { 4 } else { 2 }
  let length = if south { block.width } else { block.depth }
  let make = fn(a : Double, z : Double) -> TownBearingVertex {
    if south {
      { u: block.u + a, v: block.v - block.depth / 2.0 - 0.001, z, }
    } else {
      { u: block.u + block.width / 2.0 + 0.001, v: block.v + a, z, }
    }
  }
  for floor in 0..<block.floors {
    for panel in 0..<panels {
      let a = -length / 2.0 +
        length * (panel.to_double() + 0.16) / panels.to_double()
      let b = -length / 2.0 +
        length * (panel.to_double() + 0.82) / panels.to_double()
      let z = 0.065 + floor.to_double() * 0.22
      town_bearing_quad(
        mesh,
        bearing,
        span,
        [make(a, z), make(b, z), make(b, z + 0.145), make(a, z + 0.145)],
        "#5a7878",
      )
      town_bearing_quad(
        mesh,
        bearing,
        span,
        [
          make(a + 0.008, z + 0.014),
          make(b - 0.008, z + 0.014),
          make(b - 0.008, z + 0.137),
          make(a + 0.008, z + 0.137),
        ],
        if south {
          "#add5d3"
        } else {
          "#81b7bb"
        },
      )
      town_bearing_quad(
        mesh,
        bearing,
        span,
        [
          make(a, z + 0.015),
          make(b, z + 0.015),
          make(b, z + 0.05),
          make(a, z + 0.05),
        ],
        "#c6a77e",
      )
    }
  }
}

///|
fn town_bearing_blocks(
  style : String,
  variant : Int,
) -> Array[TownBearingBlock] {
  town_bearing_archetype(style, variant).blocks
}

///|
fn town_bearing_make_mesh(
  b : TownBuildingBearing,
  span : Double,
  style : String,
  variant : Int,
) -> TownBearingMesh {
  let mesh : TownBearingMesh = { points: [], colors: [], }
  let archetype = town_bearing_archetype(style, variant)
  let blocks = archetype.blocks
  // Back-to-front ground anchors, with roofs and their fixtures attached to
  // each volume. No screen rotation, skewed verticals, or bitmap stretching.
  let depth = fn(block : TownBearingBlock) {
    (b.east.x + b.east.y) * block.u + (b.north.x + b.north.y) * block.v
  }
  for i in 1..<blocks.length() {
    let mut j = i
    while j > 0 && depth(blocks[j]) < depth(blocks[j - 1]) {
      let previous = blocks[j - 1]
      blocks[j - 1] = blocks[j]
      blocks[j] = previous
      j -= 1
    }
  }
  for block in blocks {
    let h = block.floors.to_double() * 0.22 + 0.05
    town_bearing_box(
      mesh,
      b,
      span,
      block.u,
      block.v,
      block.width,
      block.depth,
      0.02,
      h,
      archetype.wall,
      "#fbf5e7",
    )
    town_bearing_facade(mesh, b, span, block, 0)
    town_bearing_facade(mesh, b, span, block, 1)
    let front = block.v - block.depth / 2.0 - 0.002
    town_bearing_quad(
      mesh,
      b,
      span,
      [
        { u: block.u - 0.035, v: front, z: 0.025, },
        { u: block.u + 0.035, v: front, z: 0.025, },
        { u: block.u + 0.035, v: front, z: 0.185, },
        { u: block.u - 0.035, v: front, z: 0.185, },
      ],
      "#527f83",
    )
    town_bearing_box(
      mesh,
      b,
      span,
      block.u,
      front - 0.025,
      0.11,
      0.07,
      0.02,
      0.035,
      "#cbc4ae",
      "#f3ecda",
    )
    town_bearing_box(
      mesh,
      b,
      span,
      block.u,
      front - 0.022,
      0.13,
      0.065,
      0.19,
      0.21,
      "#b49a74",
      "#6f8783",
    )
    if archetype.name == "colonnaded-hall" {
      for column in 0..<6 {
        town_bearing_box(
          mesh,
          b,
          span,
          block.u - 0.31 + column.to_double() * 0.124,
          front - 0.075,
          0.023,
          0.023,
          0.02,
          0.27,
          "#ede4cf",
          "#fff4de",
        )
      }
      town_bearing_box(
        mesh,
        b,
        span,
        block.u,
        front - 0.065,
        0.76,
        0.13,
        0.27,
        0.30,
        "#d3c6ac",
        "#f1e3c8",
      )
    }
    if archetype.roof == "awning" {
      town_bearing_box(
        mesh,
        b,
        span,
        block.u,
        front - 0.045,
        block.width + 0.015,
        0.115,
        0.19,
        0.215,
        "#b4a180",
        archetype.roof_color,
      )
    }
    if archetype.roof is ("gable" | "hip" | "saw" | "glass" | "crown") {
      town_bearing_architectural_roof(
        mesh,
        b,
        span,
        block,
        archetype.roof,
        archetype.roof_color,
      )
      continue
    }
    // Flat and planted-terrace families retain the spring material kit.
    town_bearing_box(
      mesh,
      b,
      span,
      block.u,
      block.v,
      block.width + 0.016,
      block.depth + 0.016,
      h,
      h + 0.023,
      "#eee9dc",
      "#fff9eb",
    )
    town_bearing_roof(
      mesh,
      b,
      span,
      block.u,
      block.v,
      block.width - 0.035,
      block.depth - 0.035,
      h + 0.024,
      "#e5e1d2",
    )
    town_bearing_box(
      mesh,
      b,
      span,
      block.u,
      block.v + block.depth * 0.17,
      block.width * 0.65,
      block.depth * 0.30,
      h + 0.025,
      h + 0.060,
      "#b3a386",
      archetype.roof_color,
    )
    town_bearing_box(
      mesh,
      b,
      span,
      block.u,
      block.v - block.depth * 0.16,
      block.width * 0.50,
      block.depth * 0.23,
      h + 0.025,
      h + 0.038,
      "#617d80",
      "#8ebdc6",
    )
  }
  // Floor height is an architectural module, not a fraction of the parcel.
  // A narrower frontage must not miniaturize doors, floors and roof heights.
  if span > 0.0 {
    for i in 0..<(mesh.points.length() / 3) {
      mesh.points[i * 3 + 2] = mesh.points[i * 3 + 2] / span * 3.4
    }
  }
  mesh
}

///|
let town_bearing_mesh_cache : Map[String, TownBearingMesh] = Map([])

///|
fn town_bearing_mesh(
  building : IntersectionRoadPreviewBuilding,
) -> TownBearingMesh {
  let key = "\{building.id}:\{building.x}:\{building.y}:\{building.style}:\{building.width}:\{building.depth}"
  match town_bearing_mesh_cache.get(key) {
    Some(mesh) => return mesh
    None => ()
  }
  let b = town_building_bearing(building)
  let span = town_bearing_span(b, building.width, building.depth)
  let mesh = town_bearing_make_mesh(
    b,
    span,
    building.style,
    town_bearing_variant(building.id),
  )
  if town_bearing_mesh_cache.length() > 256 {
    town_bearing_mesh_cache.clear()
  }
  town_bearing_mesh_cache[key] = mesh
  mesh
}

///|
extern "js" fn town_bearing_paint_mesh(
  c : @dom.CanvasRenderingContext2D,
  points : Array[Double],
  colors : Array[String],
  sx : Double,
  sy : Double,
  zoom : Double,
) -> Unit =
  #| (c,ps,colors,sx,sy,z)=>{
  #|   c.save();c.translate(sx,sy);c.scale(z,z);c.lineJoin='round';
  #|   for(let f=0;f<colors.length;f++){
  #|     c.beginPath();
  #|     for(let v=0;v<4;v++){
  #|       const i=f*12+v*3,x=(ps[i]-ps[i+1])*32,y=(ps[i]+ps[i+1])*16-ps[i+2]*32;
  #|       if(v===0)c.moveTo(x,y);else c.lineTo(x,y);
  #|     }
  #|     c.closePath();c.fillStyle=colors[f];c.fill();
  #|     c.lineWidth=.55;c.strokeStyle='rgba(80,92,80,0.26)';c.stroke();
  #|   }
  #|   c.restore();
  #| }

///|
fn town_bearing_draw_building(
  context : @dom.CanvasRenderingContext2D,
  building : IntersectionRoadPreviewBuilding,
  width : Int,
  height : Int,
) -> Unit {
  let (x, y) = intersection_road_preview_building_center(building)
  let mesh = town_bearing_mesh(building)
  town_bearing_paint_mesh(
    context,
    mesh.points,
    mesh.colors,
    golden_screen_x(x, y, width),
    golden_screen_y(x, y, height),
    golden_valley_camera_zoom(),
  )
}

///|
fn town_bearing_draw_lot(
  context : @dom.CanvasRenderingContext2D,
  building : IntersectionRoadPreviewBuilding,
  width : Int,
  height : Int,
) -> Unit {
  let (x, y) = intersection_road_preview_building_center(building)
  let b = town_building_bearing(building)
  let span = town_bearing_span(b, building.width, building.depth)
  let mesh : TownBearingMesh = { points: [], colors: [], }
  town_bearing_roof(mesh, b, span, 0, 0, 1, 1, 0, "#adc393")
  town_bearing_roof(mesh, b, span, 0, 0, 0.92, 0.92, 0.001, "#e5dfce")
  for
    block in town_bearing_blocks(
      building.style,
      town_bearing_variant(building.id),
    ) {
    town_bearing_roof(
      mesh,
      b,
      span,
      block.u + 0.045,
      block.v + 0.025,
      block.width + 0.04,
      block.depth + 0.035,
      0.0015,
      "rgba(73,88,65,0.14)",
    )
  }
  // South-facing entry court and planted strips share the building frame.
  town_bearing_roof(mesh, b, span, 0, -0.35, 0.15, 0.25, 0.002, "#faf2e0")
  town_bearing_roof(mesh, b, span, -0.35, -0.37, 0.15, 0.10, 0.002, "#93af78")
  town_bearing_roof(mesh, b, span, 0.35, -0.37, 0.15, 0.10, 0.002, "#93af78")
  town_bearing_paint_mesh(
    context,
    mesh.points,
    mesh.colors,
    golden_screen_x(x, y, width),
    golden_screen_y(x, y, height),
    golden_valley_camera_zoom(),
  )
  town_street_draw_entry(context, building, width, height)
}
