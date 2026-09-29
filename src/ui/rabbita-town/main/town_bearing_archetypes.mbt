///|
/// Three genuinely different massings per family, all in geographic u/v/z.
/// These are architectural visual archetypes, not new operational place roles.
priv struct TownBearingArchetype {
  name : String
  blocks : Array[TownBearingBlock]
  roof : String
  wall : String
  roof_color : String
}

///|
fn town_bearing_volume(
  u : Double,
  v : Double,
  width : Double,
  depth : Double,
  floors : Int,
) -> TownBearingBlock {
  { u, v, width, depth, floors, }
}

///|
fn town_bearing_archetype(
  style : String,
  variant : Int,
) -> TownBearingArchetype {
  let v = energy_valley_mod(variant, 3)
  let box = town_bearing_volume
  let (name, blocks, roof, wall, color) = match (style, v) {
    ("lowrise", 0) =>
      (
        "garden-villa",
        [box(-0.10, 0.09, 0.48, 0.50, 2), box(0.26, 0.03, 0.20, 0.36, 1)],
        "hip",
        "#f1e7d1",
        "#98a9a3",
      )
    ("lowrise", 1) =>
      (
        "split-garden-home",
        [box(-0.22, 0.12, 0.30, 0.43, 2), box(0.16, -0.03, 0.38, 0.45, 1)],
        "gable",
        "#eee4d4",
        "#bf9a85",
      )
    ("lowrise", _) =>
      (
        "terrace-house",
        [
          box(-0.20, 0.14, 0.30, 0.46, 3),
          box(0.12, 0.04, 0.32, 0.46, 2),
          box(0.34, -0.03, 0.12, 0.30, 1),
        ],
        "terrace",
        "#f5eddd",
        "#c5d1ab",
      )
    ("row", 0) =>
      (
        "gable-townhouses",
        [
          for i in 0..<3 => {
            box((i.to_double() - 1.0) * 0.25, 0.04, 0.23, 0.48, 2)
          }
        ],
        "gable",
        "#f1e8d8",
        "#a8927e",
      )
    ("row", 1) =>
      (
        "market-arcade",
        [
          for i in 0..<4 => {
            box((i.to_double() - 1.5) * 0.19, 0.07, 0.17, 0.50, 1)
          }
        ],
        "awning",
        "#ebdfc9",
        "#9eb4a0",
      )
    ("row", _) =>
      (
        "stepped-maisonettes",
        [
          for i in 0..<3 => {
            box((i.to_double() - 1.0) * 0.25, 0.07, 0.23, 0.49, i + 1)
          }
        ],
        "terrace",
        "#f3e7d6",
        "#b8caa1",
      )
    ("tower", 0) =>
      (
        "stepped-office",
        [box(0, 0.04, 0.57, 0.52, 5)],
        "crown",
        "#e6ebe5",
        "#91b3b5",
      )
    ("tower", 1) =>
      (
        "twin-towers",
        [box(-0.20, 0.15, 0.28, 0.40, 5), box(0.20, -0.05, 0.28, 0.40, 4)],
        "flat",
        "#f1eddf",
        "#cad2ba",
      )
    ("tower", _) =>
      (
        "slender-residential",
        [box(0.08, 0.12, 0.40, 0.45, 6), box(-0.23, -0.08, 0.20, 0.32, 1)],
        "crown",
        "#ede5d5",
        "#a6c0b6",
      )
    ("block", 0) =>
      (
        "parallel-apartments",
        [box(0, 0.23, 0.74, 0.20, 3), box(0, -0.15, 0.74, 0.20, 3)],
        "gable",
        "#e9deca",
        "#929f9b",
      )
    ("block", 1) =>
      (
        "l-shaped-apartments",
        [box(0, 0.25, 0.74, 0.20, 4), box(-0.27, -0.07, 0.20, 0.44, 3)],
        "flat",
        "#f1e9d8",
        "#bdc9b0",
      )
    ("block", _) =>
      (
        "stepped-housing",
        [
          box(-0.25, 0.06, 0.23, 0.53, 4),
          box(0, 0.06, 0.23, 0.53, 3),
          box(0.25, 0.06, 0.23, 0.53, 2),
        ],
        "terrace",
        "#ede5d7",
        "#abc295",
      )
    ("courtyard", 0) =>
      (
        "siheyuan",
        [
          box(0, 0.27, 0.74, 0.19, 1),
          box(-0.28, -0.015, 0.18, 0.38, 1),
          box(0.28, -0.015, 0.18, 0.38, 1),
          box(0, -0.30, 0.48, 0.16, 1),
        ],
        "hip",
        "#d8c9b2",
        "#7f9190",
      )
    ("courtyard", 1) =>
      (
        "u-shaped-garden",
        [
          box(0, 0.25, 0.74, 0.20, 2),
          box(-0.28, -0.05, 0.18, 0.40, 2),
          box(0.28, -0.05, 0.18, 0.40, 2),
        ],
        "gable",
        "#e9d6be",
        "#a58e7f",
      )
    ("courtyard", _) =>
      (
        "cloister-court",
        [
          box(0, 0.27, 0.74, 0.16, 1),
          box(0, -0.27, 0.74, 0.16, 1),
          box(-0.29, 0, 0.16, 0.38, 2),
          box(0.29, 0, 0.16, 0.38, 1),
        ],
        "flat",
        "#f1e8d5",
        "#c0caa9",
      )
    ("campus", 0) =>
      (
        "research-wings",
        [
          box(-0.24, 0.05, 0.22, 0.57, 3),
          box(0.09, 0.05, 0.22, 0.57, 2),
          box(0.31, 0.19, 0.16, 0.29, 1),
        ],
        "flat",
        "#e6eade",
        "#b9cba9",
      )
    ("campus", 1) =>
      (
        "school-court",
        [
          box(0, 0.27, 0.76, 0.19, 2),
          box(-0.25, -0.06, 0.23, 0.40, 2),
          box(0.23, -0.05, 0.28, 0.41, 1),
        ],
        "gable",
        "#f2e6ce",
        "#b8a086",
      )
    ("campus", _) =>
      (
        "conservatory",
        [
          box(-0.25, 0.04, 0.23, 0.55, 1),
          box(0, 0.04, 0.23, 0.55, 1),
          box(0.25, 0.04, 0.23, 0.55, 1),
        ],
        "glass",
        "#d7e6dd",
        "#8fc3bd",
      )
    ("civic", 0) =>
      (
        "colonnaded-hall",
        [box(0, 0.08, 0.76, 0.49, 2)],
        "hip",
        "#f4e9d5",
        "#91a3a2",
      )
    ("civic", 1) =>
      (
        "terraced-library",
        [
          box(-0.23, 0.09, 0.28, 0.51, 3),
          box(0.04, 0.09, 0.25, 0.51, 2),
          box(0.27, 0.09, 0.21, 0.51, 1),
        ],
        "terrace",
        "#f3eadb",
        "#bfd1aa",
      )
    ("civic", _) =>
      (
        "pavilion-hall",
        [
          box(0, 0.07, 0.51, 0.52, 2),
          box(-0.32, 0.10, 0.12, 0.33, 1),
          box(0.32, 0.10, 0.12, 0.33, 1),
        ],
        "hip",
        "#ecdec6",
        "#b2a18c",
      )
    ("industrial", 0) =>
      (
        "sawtooth-factory",
        [box(0, 0.07, 0.76, 0.60, 1)],
        "saw",
        "#dfd9c9",
        "#9eafa9",
      )
    ("industrial", 1) =>
      (
        "brick-workshops",
        [
          box(-0.24, 0.07, 0.22, 0.57, 1),
          box(0.01, 0.07, 0.22, 0.57, 1),
          box(0.26, 0.07, 0.22, 0.57, 1),
        ],
        "gable",
        "#cdb69d",
        "#9c9f96",
      )
    ("industrial", _) =>
      (
        "logistics-hall",
        [box(-0.10, 0.13, 0.54, 0.44, 1), box(0.27, -0.05, 0.20, 0.44, 2)],
        "saw",
        "#e4ddca",
        "#a3b8af",
      )
    _ =>
      (
        "garden-villa",
        [box(0, 0.08, 0.65, 0.48, 2)],
        "hip",
        "#f1e7d1",
        "#98a9a3",
      )
  }
  { name, blocks, roof, wall, roof_color: color, }
}

///|
/// Distinct roof geometry: gables/hips, sawtooth sheds, glazed ridges and
/// stepped tower crowns. Every vertex uses the same geographic frame as walls.
fn town_bearing_architectural_roof(
  mesh : TownBearingMesh,
  b : TownBuildingBearing,
  span : Double,
  block : TownBearingBlock,
  kind : String,
  color : String,
) -> Unit {
  let h = block.floors.to_double() * 0.22 + 0.05
  let u = block.u
  let v = block.v
  let w = block.width + 0.025
  let d = block.depth + 0.025
  if kind == "crown" {
    town_bearing_box(
      mesh,
      b,
      span,
      u,
      v,
      w,
      d,
      h,
      h + 0.035,
      "#e8e4d7",
      "#f6f0df",
    )
    town_bearing_box(
      mesh,
      b,
      span,
      u,
      v,
      w * 0.72,
      d * 0.74,
      h + 0.035,
      h + 0.20,
      "#d8e3da",
      color,
    )
    town_bearing_box(
      mesh,
      b,
      span,
      u,
      v,
      w * 0.44,
      d * 0.46,
      h + 0.20,
      h + 0.30,
      "#e8e8db",
      "#b0c6b4",
    )
    return
  }
  let sheds = if kind == "saw" { 3 } else { 1 }
  for i in 0..<sheds {
    let d = d / sheds.to_double()
    let v = v - (block.depth + 0.025) / 2.0 + d * (i.to_double() + 0.5)
    let ridge_v = if kind == "saw" { v + d * 0.33 } else { v }
    let rise = if kind == "saw" { 0.10 } else { 0.14 }
    let inset = if kind == "hip" { w * 0.22 } else { 0.0 }
    let a : TownBearingVertex = { u: u - w / 2.0, v: v - d / 2.0, z: h, }
    let c : TownBearingVertex = { u: u + w / 2.0, v: v + d / 2.0, z: h, }
    let left : TownBearingVertex = {
      u: u - w / 2.0 + inset,
      v: ridge_v,
      z: h + rise,
    }
    let right : TownBearingVertex = {
      u: u + w / 2.0 - inset,
      v: ridge_v,
      z: h + rise,
    }
    // North roof first, then the near roof and end caps.
    town_bearing_quad(
      mesh,
      b,
      span,
      [{ u: a.u, v: c.v, z: h, }, c, right, left],
      if kind == "glass" {
        "#bbded6"
      } else {
        "#bdc2b3"
      },
    )
    town_bearing_quad(
      mesh,
      b,
      span,
      [a, { u: c.u, v: a.v, z: h, }, right, left],
      color,
    )
    town_bearing_quad(
      mesh,
      b,
      span,
      [{ u: c.u, v: a.v, z: h, }, c, right, right],
      if kind == "glass" {
        "#abd1cf"
      } else if kind == "hip" {
        "#a6aea4"
      } else {
        "#dcd7c6"
      },
    )
    if kind == "hip" {
      town_bearing_quad(
        mesh,
        b,
        span,
        [a, { u: a.u, v: c.v, z: h, }, left, left],
        "#a6aea4",
      )
    }
    // Raised seams read as construction, not identical rooftop boxes.
    for seam in 1..<4 {
      let x = a.u + w * seam.to_double() / 4.0
      town_bearing_quad(
        mesh,
        b,
        span,
        [
          { u: x - 0.003, v: a.v, z: h + 0.003, },
          { u: x + 0.003, v: a.v, z: h + 0.003, },
          { u: x + 0.003, v: ridge_v, z: h + rise + 0.003, },
          { u: x - 0.003, v: ridge_v, z: h + rise + 0.003, },
        ],
        if kind == "glass" {
          "#e3eee4"
        } else {
          "#b4b6a6"
        },
      )
    }
  }
}
