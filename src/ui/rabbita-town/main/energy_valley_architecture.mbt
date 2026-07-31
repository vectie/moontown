///|
/// One deterministic mass in an ambient Wenyu building. Offsets and footprint
/// sizes are expressed in world tiles; height is expressed in canvas pixels so
/// it follows the existing isometric renderer.
priv struct GoldenArchitectureMass {
  x_offset : Double
  y_offset : Double
  width : Double
  depth : Double
  height : Double
  roof : String
  left : String
  right : String
  window_columns : Int
  window_rows : Int
}

///|
/// A small shape grammar keeps the large Wenyu map readable at overview zoom:
/// mass subdivision supplies the silhouette, while a single roof feature gives
/// each archetype an identity without covering the authored roads and terrain.
priv struct GoldenArchitecturePlan {
  masses : Array[GoldenArchitectureMass]
  feature_index : Int
  roof_feature : String
  accent : String
  variant : Int
}

///|
fn golden_architecture_variant(
  grid_x : Int,
  grid_y : Int,
  width : Int,
  depth : Int,
  floors : Int,
) -> Int {
  (grid_x * 17 + grid_y * 31 + width * 7 + depth * 11 + floors * 13) % 3
}

///|
fn golden_architecture_palette(
  structure : String,
  variant : Int,
) -> (String, String, String, String) {
  match structure {
    "tower" =>
      if variant == 0 {
        ("#d8e5e8", "#78939b", "#9eb2b7", "#3f7d88")
      } else if variant == 1 {
        ("#d5e0e8", "#71899c", "#96aabd", "#4d7290")
      } else {
        ("#dfe7e2", "#7f968c", "#a1b4aa", "#4f7f6d")
      }
    "block" =>
      if variant == 0 {
        ("#dde1dc", "#909c97", "#adb7b2", "#52766b")
      } else if variant == 1 {
        ("#e1ded8", "#9d958b", "#bbb2a8", "#6f7164")
      } else {
        ("#d9e2df", "#879b96", "#a7b8b3", "#47796e")
      }
    "courtyard" =>
      if variant == 0 {
        ("#e5e1d4", "#a79c88", "#c1b6a2", "#5d7b62")
      } else if variant == 1 {
        ("#e1e5dc", "#98a493", "#b5c0af", "#50765c")
      } else {
        ("#e7e2da", "#a29a91", "#beb5ac", "#61745d")
      }
    "campus" =>
      if variant == 0 {
        ("#dbe7df", "#88a391", "#aac0b1", "#3f8068")
      } else if variant == 1 {
        ("#dce6e7", "#839ea3", "#a6bbc0", "#397786")
      } else {
        ("#e2e7dd", "#97a58d", "#b6c1ab", "#557b58")
      }
    "civic" =>
      if variant == 0 {
        ("#e8e2d5", "#aa9c87", "#c5b8a3", "#557767")
      } else if variant == 1 {
        ("#e3e5df", "#9aa19a", "#b8bdb6", "#4f7480")
      } else {
        ("#e9e5dc", "#aaa196", "#c5bcb0", "#6b7456")
      }
    "industrial" =>
      if variant == 0 {
        ("#ccd8d9", "#7f9294", "#9fadaf", "#466f75")
      } else if variant == 1 {
        ("#d4d9d5", "#89928d", "#a8b0aa", "#596f69")
      } else {
        ("#cfd8df", "#7d8e9b", "#9eacb7", "#43677f")
      }
    "row" =>
      if variant == 0 {
        ("#e4dfd3", "#a39987", "#bdb3a1", "#66785d")
      } else if variant == 1 {
        ("#dfe5df", "#929f96", "#b0bbb3", "#4d7767")
      } else {
        ("#e5e1dc", "#a09791", "#bbb3ad", "#64716a")
      }
    _ =>
      if variant == 0 {
        ("#e4e4dc", "#a0a49b", "#b9bcb4", "#527565")
      } else if variant == 1 {
        ("#e1e6e1", "#96a29a", "#b3bdb5", "#4a7564")
      } else {
        ("#e6e2da", "#a49c91", "#beb6ab", "#627460")
      }
  }
}

///|
fn golden_architecture_mass(
  x_offset : Double,
  y_offset : Double,
  width : Double,
  depth : Double,
  height : Double,
  roof : String,
  left : String,
  right : String,
  window_columns : Int,
  window_rows : Int,
) -> GoldenArchitectureMass {
  {
    x_offset,
    y_offset,
    width,
    depth,
    height,
    roof,
    left,
    right,
    window_columns,
    window_rows,
  }
}

///|
fn golden_architecture_plan(
  structure : String,
  grid_x : Int,
  grid_y : Int,
  footprint_width : Int,
  footprint_depth : Int,
  floors : Int,
) -> GoldenArchitecturePlan {
  let width = footprint_width.to_double()
  let depth = footprint_depth.to_double()
  let height = 10.0 + floors.to_double() * 18.0
  let variant = golden_architecture_variant(
    grid_x, grid_y, footprint_width, footprint_depth, floors,
  )
  let (roof, left, right, accent) = golden_architecture_palette(
    structure, variant,
  )
  let masses : Array[GoldenArchitectureMass] = []
  let mut feature_index = 0
  let mut roof_feature = "terrace"
  match structure {
    "tower" => {
      masses.push(
        golden_architecture_mass(
          width * 0.05,
          depth * 0.05,
          width * 0.90,
          depth * 0.90,
          12.0 + floors.to_double() * 3.0,
          roof,
          left,
          right,
          footprint_width,
          1,
        ),
      )
      masses.push(
        golden_architecture_mass(
          width * 0.24,
          depth * 0.20,
          width * 0.52,
          depth * 0.56,
          height + 8.0,
          roof,
          left,
          right,
          footprint_width,
          floors,
        ),
      )
      masses.push(
        golden_architecture_mass(
          width * 0.36,
          depth * 0.32,
          width * 0.28,
          depth * 0.30,
          height + 17.0,
          accent,
          left,
          right,
          2,
          1,
        ),
      )
      feature_index = 2
      roof_feature = "crown"
    }
    "block" => {
      masses.push(
        golden_architecture_mass(
          width * 0.05,
          depth * 0.05,
          width * 0.90,
          depth * 0.90,
          height * 0.38,
          roof,
          left,
          right,
          footprint_width,
          1,
        ),
      )
      masses.push(
        golden_architecture_mass(
          width * 0.16,
          depth * 0.14,
          width * 0.68,
          depth * 0.70,
          height,
          roof,
          left,
          right,
          footprint_width,
          floors,
        ),
      )
      feature_index = 1
      roof_feature = if variant == 1 { "garden" } else { "terrace" }
    }
    "courtyard" => {
      masses.push(
        golden_architecture_mass(
          width * 0.06,
          depth * 0.06,
          width * 0.88,
          depth * 0.28,
          height * 0.92,
          roof,
          left,
          right,
          footprint_width,
          floors,
        ),
      )
      masses.push(
        golden_architecture_mass(
          width * 0.06,
          depth * 0.25,
          width * 0.27,
          depth * 0.68,
          height,
          roof,
          left,
          right,
          2,
          floors,
        ),
      )
      masses.push(
        golden_architecture_mass(
          width * 0.67,
          depth * 0.25,
          width * 0.27,
          depth * 0.68,
          height * 0.88,
          roof,
          left,
          right,
          2,
          floors,
        ),
      )
      feature_index = 0
      roof_feature = "garden"
    }
    "campus" => {
      masses.push(
        golden_architecture_mass(
          width * 0.05,
          depth * 0.08,
          width * 0.42,
          depth * 0.70,
          height * 0.86,
          roof,
          left,
          right,
          2,
          floors,
        ),
      )
      masses.push(
        golden_architecture_mass(
          width * 0.53,
          depth * 0.20,
          width * 0.42,
          depth * 0.70,
          height,
          roof,
          left,
          right,
          2,
          floors,
        ),
      )
      masses.push(
        golden_architecture_mass(
          width * 0.41,
          depth * 0.40,
          width * 0.18,
          depth * 0.24,
          height * 0.48,
          accent,
          left,
          right,
          1,
          1,
        ),
      )
      feature_index = 1
      roof_feature = if variant == 2 { "garden" } else { "solar" }
    }
    "civic" => {
      masses.push(
        golden_architecture_mass(
          width * 0.04,
          depth * 0.08,
          width * 0.92,
          depth * 0.82,
          height * 0.34,
          roof,
          left,
          right,
          footprint_width,
          1,
        ),
      )
      masses.push(
        golden_architecture_mass(
          width * 0.20,
          depth * 0.12,
          width * 0.60,
          depth * 0.62,
          height + 6.0,
          roof,
          left,
          right,
          footprint_width,
          floors,
        ),
      )
      masses.push(
        golden_architecture_mass(
          width * 0.28,
          depth * 0.72,
          width * 0.44,
          depth * 0.20,
          height * 0.46,
          accent,
          left,
          right,
          3,
          1,
        ),
      )
      feature_index = 1
      roof_feature = "ridge"
    }
    "industrial" => {
      let bay_width = width * 0.29
      for index in 0..<3 {
        masses.push(
          golden_architecture_mass(
            width * (0.04 + index.to_double() * 0.31),
            depth * 0.08,
            bay_width,
            depth * 0.84,
            height * (0.72 + index.to_double() * 0.05),
            roof,
            left,
            right,
            2,
            if floors < 2 {
              1
            } else {
              floors - 1
            },
          ),
        )
      }
      feature_index = 1
      roof_feature = "sawtooth"
    }
    "row" => {
      if footprint_width >= footprint_depth {
        let segment_width = width * 0.30
        for index in 0..<3 {
          masses.push(
            golden_architecture_mass(
              width * (0.04 + index.to_double() * 0.31),
              depth * 0.08,
              segment_width,
              depth * 0.84,
              height * (0.86 + ((index + variant) % 3).to_double() * 0.07),
              roof,
              left,
              right,
              2,
              floors,
            ),
          )
        }
      } else {
        let segment_depth = depth * 0.30
        for index in 0..<3 {
          masses.push(
            golden_architecture_mass(
              width * 0.08,
              depth * (0.04 + index.to_double() * 0.31),
              width * 0.84,
              segment_depth,
              height * (0.86 + ((index + variant) % 3).to_double() * 0.07),
              roof,
              left,
              right,
              2,
              floors,
            ),
          )
        }
      }
      feature_index = 1
      roof_feature = "ridge"
    }
    _ => {
      masses.push(
        golden_architecture_mass(
          width * 0.06,
          depth * 0.08,
          width * 0.88,
          depth * 0.42,
          height * 0.84,
          roof,
          left,
          right,
          footprint_width,
          floors,
        ),
      )
      masses.push(
        golden_architecture_mass(
          width * 0.06,
          depth * 0.42,
          width * 0.42,
          depth * 0.50,
          height,
          roof,
          left,
          right,
          2,
          floors,
        ),
      )
      feature_index = 1
      roof_feature = if variant == 2 { "solar" } else { "ridge" }
    }
  }
  { masses, feature_index, roof_feature, accent, variant }
}

///|
extern "js" fn golden_draw_architecture_roof_feature(
  context : @dom.CanvasRenderingContext2D,
  feature : String,
  world_x : Double,
  world_y : Double,
  width : Double,
  depth : Double,
  height : Double,
  viewport_width : Int,
  viewport_height : Int,
  accent : String,
  variant : Int,
) -> Unit =
  #| (context, feature, tx, ty, width, depth, height0, vw, vh, accent, variant) => {
  #|   const camera = globalThis.__moontownGoldenValleyCamera ??
  #|     { x: 1792, y: 3200, z: 0.1 };
  #|   const z = camera.z;
  #|   if (z < 0.075) return;
  #|   const toScreen = (x, y) => ({
  #|     x: ((x - y) * 32 - camera.x) * z + vw / 2,
  #|     y: ((x + y) * 16 - camera.y) * z + vh / 2,
  #|   });
  #|   const lift = height0 * z / 0.95;
  #|   const up = point => ({ x: point.x, y: point.y - lift });
  #|   const roof = {
  #|     N: up(toScreen(tx, ty)),
  #|     E: up(toScreen(tx + width, ty)),
  #|     S: up(toScreen(tx + width, ty + depth)),
  #|     W: up(toScreen(tx, ty + depth)),
  #|   };
  #|   const lerp = (a, b, f) => ({
  #|     x: a.x + (b.x - a.x) * f,
  #|     y: a.y + (b.y - a.y) * f,
  #|   });
  #|   const polygon = (points, fill, stroke = null) => {
  #|     context.beginPath();
  #|     context.moveTo(points[0].x, points[0].y);
  #|     for (let i = 1; i < points.length; i += 1) {
  #|       context.lineTo(points[i].x, points[i].y);
  #|     }
  #|     context.closePath();
  #|     context.fillStyle = fill;
  #|     context.fill();
  #|     if (stroke) {
  #|       context.strokeStyle = stroke;
  #|       context.lineWidth = Math.max(0.65, z);
  #|       context.stroke();
  #|     }
  #|   };
  #|   if (feature === "ridge") {
  #|     const a = lerp(roof.N, roof.W, 0.5);
  #|     const b = lerp(roof.E, roof.S, 0.5);
  #|     a.y -= Math.max(1.2, 6 * z);
  #|     b.y -= Math.max(1.2, 6 * z);
  #|     polygon([roof.N, roof.E, b, a], accent, "rgba(255,255,255,.38)");
  #|     polygon([a, b, roof.S, roof.W], "rgba(62,90,77,.78)");
  #|   } else if (feature === "solar") {
  #|     for (let i = 0; i < 2; i += 1) {
  #|       const start = 0.15 + i * 0.38;
  #|       const end = start + 0.28;
  #|       polygon([
  #|         lerp(lerp(roof.N, roof.W, 0.20), lerp(roof.E, roof.S, 0.20), start),
  #|         lerp(lerp(roof.N, roof.W, 0.20), lerp(roof.E, roof.S, 0.20), end),
  #|         lerp(lerp(roof.N, roof.W, 0.68), lerp(roof.E, roof.S, 0.68), end),
  #|         lerp(lerp(roof.N, roof.W, 0.68), lerp(roof.E, roof.S, 0.68), start),
  #|       ], "#315d70", "rgba(190,230,238,.6)");
  #|     }
  #|   } else if (feature === "garden") {
  #|     const center = lerp(lerp(roof.N, roof.S, 0.5), lerp(roof.W, roof.E, 0.5), 0.5);
  #|     for (let i = -2; i <= 2; i += 1) {
  #|       context.fillStyle = i % 2 === 0 ? "#4f7c58" : "#719164";
  #|       context.beginPath();
  #|       context.ellipse(
  #|         center.x + i * Math.max(1.4, 5 * z),
  #|         center.y + (i % 2) * Math.max(0.5, 2 * z),
  #|         Math.max(0.9, 2.4 * z), Math.max(0.55, 1.4 * z),
  #|         0, 0, Math.PI * 2,
  #|       );
  #|       context.fill();
  #|     }
  #|   } else if (feature === "sawtooth") {
  #|     context.strokeStyle = accent;
  #|     context.lineWidth = Math.max(0.75, 1.2 * z);
  #|     for (let i = 1; i <= 3; i += 1) {
  #|       const f = i / 4;
  #|       const a = lerp(roof.N, roof.W, f);
  #|       const b = lerp(roof.E, roof.S, f);
  #|       const m = lerp(a, b, 0.48);
  #|       m.y -= Math.max(1, 4 * z) * (i % 2 === 0 ? 1.35 : 1);
  #|       context.beginPath();
  #|       context.moveTo(a.x, a.y);
  #|       context.lineTo(m.x, m.y);
  #|       context.lineTo(b.x, b.y);
  #|       context.stroke();
  #|     }
  #|   } else if (feature === "crown") {
  #|     const center = lerp(roof.N, roof.S, 0.5);
  #|     context.strokeStyle = accent;
  #|     context.lineWidth = Math.max(0.75, 1.25 * z);
  #|     context.beginPath();
  #|     context.moveTo(center.x, center.y);
  #|     context.lineTo(center.x, center.y - Math.max(3, 18 * z));
  #|     context.stroke();
  #|     context.fillStyle = variant === 1 ? "#82d8df" : "#e6f2ec";
  #|     context.beginPath();
  #|     context.arc(center.x, center.y - Math.max(3, 18 * z), Math.max(0.9, 2 * z), 0, Math.PI * 2);
  #|     context.fill();
  #|   } else {
  #|     const inset = [
  #|       lerp(roof.N, roof.S, 0.16),
  #|       lerp(roof.E, roof.W, 0.16),
  #|       lerp(roof.S, roof.N, 0.16),
  #|       lerp(roof.W, roof.E, 0.16),
  #|     ];
  #|     polygon(inset, "rgba(255,255,255,.08)", accent);
  #|   }
  #| }

///|
fn golden_draw_architecture_plan(
  context : @dom.CanvasRenderingContext2D,
  plan : GoldenArchitecturePlan,
  world_x : Double,
  world_y : Double,
  viewport_width : Int,
  viewport_height : Int,
  hour : Double,
) -> Unit {
  let zoom = golden_valley_camera_zoom()
  let lit_fraction = if hour < 6.0 || hour >= 19.0 { 0.42 } else { 0.0 }
  for mass in plan.masses {
    let center_x = world_x + mass.x_offset + mass.width / 2.0
    let center_y = world_y + mass.y_offset + mass.depth / 2.0
    let sx = golden_screen_x(center_x, center_y, viewport_width)
    let sy = golden_screen_y(center_x, center_y, viewport_height)
    golden_draw_iso_box(
      context,
      sx,
      sy,
      mass.width,
      mass.depth,
      mass.height,
      mass.roof,
      mass.left,
      mass.right,
    )
    if zoom >= 0.18 && mass.window_rows > 0 {
      golden_draw_iso_windows(
        context,
        sx,
        sy,
        mass.width,
        mass.depth,
        mass.height,
        zoom,
        mass.window_columns,
        mass.window_rows,
        lit_fraction,
      )
    }
  }
  let feature = plan.masses[plan.feature_index]
  golden_draw_architecture_roof_feature(
    context,
    plan.roof_feature,
    world_x + feature.x_offset,
    world_y + feature.y_offset,
    feature.width,
    feature.depth,
    feature.height,
    viewport_width,
    viewport_height,
    plan.accent,
    plan.variant,
  )
}
