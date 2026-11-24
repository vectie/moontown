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
  floors : Int32
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
        "#a4b29b"
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
  side : Int32,
  style : String,
  archetype : String,
) -> Unit {
  let longitudinal = side % 2 == 0
  let front = side == 0
  let along = if longitudinal { bearing.east } else { bearing.north }
  let sign = if side < 2 { 1.0 } else { -1.0 }
  if (along.x - along.y) * sign <= 0.0 {
    return
  }
  let length = if longitudinal { block.width } else { block.depth }
  let make = fn(a : Double, z : Double) -> TownBearingVertex {
    if longitudinal {
      { u: block.u + a, v: block.v - sign * (block.depth / 2 + 0.001), z, }
    } else {
      { u: block.u + sign * (block.width / 2 + 0.001), v: block.v + a, z, }
    }
  }
  let rect = fn(
    left : Double,
    right : Double,
    bottom : Double,
    top : Double,
    color : String,
  ) {
    town_bearing_quad(
      mesh,
      bearing,
      span,
      [
        make(left, bottom),
        make(right, bottom),
        make(right, top),
        make(left, top),
      ],
      color,
    )
  }
  let industrial = style == "industrial"
  let glazed = style == "campus" ||
    style == "civic" ||
    archetype == "market-arcade" ||
    (style == "tower" && archetype != "slender-residential")
  let bays = (length /
    (if industrial { 0.28 } else if glazed { 0.16 } else { 0.19 }))
    .round()
    .to_int()
    .max(1)
  let pitch = length / bays.to_double()
  for floor in 0..<block.floors {
    let z = 0.035 + floor.to_double() * 0.22
    for i in 0..<bays {
      let center = -length / 2 + (i.to_double() + 0.5) * pitch
      let half = pitch *
        (if glazed || industrial { 0.42 } else if front { 0.34 } else { 0.22 })
      let sill = z +
        (if industrial { 0.117 } else if glazed { 0.026 } else { 0.048 })
      let head = z + 0.185
      rect(
        center - half,
        center + half,
        sill,
        head,
        if front {
          "#79a4a4"
        } else {
          "#637f88"
        },
      )
      if glazed && longitudinal {
        rect(center - 0.003, center + 0.003, sill, head, "#b4c0b8")
      } else if front && !industrial && floor > 0 {
        rect(
          center - half - 0.007,
          center + half + 0.007,
          sill - 0.017,
          sill + 0.012,
          "#d4c7aa",
        )
      }
    }
    if front && glazed && floor == 0 {
      rect(-length * 0.46, length * 0.46, z + 0.193, z + 0.211, "#e2d8bd")
    }
  }
}

///|
fn town_bearing_blocks(
  style : String,
  variant : Int32,
) -> Array[TownBearingBlock] {
  town_bearing_archetype(style, variant).blocks
}

///|
fn town_bearing_make_mesh(
  b : TownBuildingBearing,
  span : Double,
  style : String,
  variant : Int32,
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
    for side in 0..<4 {
      town_bearing_facade(mesh, b, span, block, side, style, archetype.name)
    }
    let front = block.v - block.depth / 2.0 - 0.002
    if b.east.x > b.east.y {
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
    }
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
  bearing? : TownBuildingBearing,
  variant? : Int32,
) -> TownBearingMesh {
  let b = bearing.unwrap_or_else(() => town_building_bearing(building))
  let span = town_bearing_span(b, building.width, building.depth)
  let variant = variant.unwrap_or_else(() => town_bearing_variant(building.id))
  // Reuse the same architectural mesh across repeated exterior lots. World
  // position is supplied at draw time, not baked into the geometry cache key.
  let rounded = fn(n : Double) { (n * 1000000).round() / 1000000 }
  let key = "\{building.style}:\{variant}:\{rounded(span)}:\{rounded(b.east.x)}:\{rounded(b.east.y)}:\{rounded(b.north.x)}:\{rounded(b.north.y)}"
  match town_bearing_mesh_cache.get(key) {
    Some(mesh) => return mesh
    None => ()
  }
  let mesh = town_bearing_make_mesh(b, span, building.style, variant)
  if town_bearing_mesh_cache.length() >= 768 {
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
  #|   const cache=globalThis.__townBearingPaintCache ||= {entries:new Map(),bytes:0};
  #|   let tile=cache.entries.get(ps);
  #|   if(!tile){
  #|     let left=Infinity,top=Infinity,right=-Infinity,bottom=-Infinity;
  #|     for(let i=0;i<ps.length;i+=3){const x=(ps[i]-ps[i+1])*32,y=(ps[i]+ps[i+1])*16-ps[i+2]*32;left=Math.min(left,x);right=Math.max(right,x);top=Math.min(top,y);bottom=Math.max(bottom,y);}
  #|     left-=2;top-=2;right+=2;bottom+=2;const width=right-left,height=bottom-top;if(!(width>0&&height>0))return;
  #|     const compact=globalThis.__townDisplay?.compact;
  #|     const ratio=Math.min(compact?1:2,768/Math.max(width,height)),canvas=document.createElement('canvas');canvas.width=Math.ceil(width*ratio);canvas.height=Math.ceil(height*ratio);
  #|     const out=canvas.getContext('2d');out.scale(ratio,ratio);out.translate(-left,-top);out.lineJoin='round';
  #|   for(let f=0;f<colors.length;f++){
  #|     out.beginPath();
  #|     for(let v=0;v<4;v++){
  #|       const i=f*12+v*3,x=(ps[i]-ps[i+1])*32,y=(ps[i]+ps[i+1])*16-ps[i+2]*32;
  #|       if(v===0)out.moveTo(x,y);else out.lineTo(x,y);
  #|     }
  #|     out.closePath();out.fillStyle=colors[f];out.fill();
  #|     out.lineWidth=.45;out.strokeStyle='rgba(80,92,80,0.18)';out.stroke();
  #|   }
  #|     tile={canvas,left,top,width:canvas.width/ratio,height:canvas.height/ratio,bytes:canvas.width*canvas.height*4};
  #|     cache.entries.set(ps,tile);cache.bytes+=tile.bytes;
  #|     while(cache.entries.size>512||cache.bytes>(compact?20:96)*1024*1024){const key=cache.entries.keys().next().value;cache.bytes-=cache.entries.get(key).bytes;cache.entries.delete(key);}
  #|   }else{cache.entries.delete(ps);cache.entries.set(ps,tile);}
  #|   c.drawImage(tile.canvas,sx+tile.left*z,sy+tile.top*z,tile.width*z,tile.height*z);
  #| }

///|
fn town_bearing_draw_building(
  context : @dom.CanvasRenderingContext2D,
  building : IntersectionRoadPreviewBuilding,
  width : Int32,
  height : Int32,
  bearing? : TownBuildingBearing,
  variant? : Int32,
) -> Unit {
  let (x, y) = intersection_road_preview_building_center(building)
  let mesh = town_bearing_mesh(building, bearing?, variant?)
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
  width : Int32,
  height : Int32,
  bearing? : TownBuildingBearing,
  variant? : Int32,
  connect_street~ : Bool = true,
) -> Unit {
  let (x, y) = intersection_road_preview_building_center(building)
  let b = bearing.unwrap_or_else(() => town_building_bearing(building))
  let span = town_bearing_span(b, building.width, building.depth)
  let mesh : TownBearingMesh = { points: [], colors: [], }
  town_bearing_roof(mesh, b, span, 0, 0, 1, 1, 0, "#adc393")
  town_bearing_roof(mesh, b, span, 0, 0, 0.92, 0.92, 0.001, "#e5dfce")
  for
    block in town_bearing_blocks(
      building.style,
      variant.unwrap_or_else(() => town_bearing_variant(building.id)),
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
      "rgba(40,80,60,0.26)",
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
  if connect_street {
    town_street_draw_entry(context, building, width, height)
  }
}
