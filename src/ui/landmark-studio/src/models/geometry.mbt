///|
// Renderer-neutral model commands. Architecture, planting and structure are
// authored here; the JavaScript adapter only turns these commands into meshes.
priv struct Part {
  kind : String
  material : String
  layer : String
  position : Array[Double]
  scale : Array[Double]
  rotation : Double
  points : Array[Array[Double]]
  caption : String
} derive(ToJson)

///|
priv struct Study {
  id : String
  title : String
  subtitle : String
  description : String
  note : String
  span : Double
  focus : Array[Double]
  detail_focus : Array[Double]
  detail_offset : Array[Double]
  parts : Array[Part]
} derive(ToJson)

///|
fn primitive(
  p : Array[Part],
  kind : String,
  mat : String,
  x : Double,
  y : Double,
  z : Double,
  w : Double,
  h : Double,
  d : Double,
  layer? : String = "landmark",
  rotation? : Double = 0.0,
) -> Unit {
  p.push({
    kind,
    material: mat,
    layer,
    position: [x, y, z],
    scale: [w, h, d],
    rotation,
    points: [],
    caption: "",
  })
}

///|
fn box(
  p : Array[Part],
  mat : String,
  x : Double,
  y : Double,
  z : Double,
  w : Double,
  h : Double,
  d : Double,
  layer? : String = "landmark",
  rotation? : Double = 0.0,
) -> Unit {
  primitive(p, "box", mat, x, y, z, w, h, d, layer~, rotation~)
}

///|
fn beam(
  p : Array[Part],
  mat : String,
  a : Array[Double],
  b : Array[Double],
  radius : Double,
  layer? : String = "landmark",
) -> Unit {
  p.push({
    kind: "beam",
    material: mat,
    layer,
    position: a,
    scale: [radius, radius, radius],
    rotation: 0,
    points: [b],
    caption: "",
  })
}

///|
// Oriented rectangular steel section; unlike a cylinder it has readable faces.
fn girder(
  p : Array[Part],
  mat : String,
  a : Array[Double],
  b : Array[Double],
  width : Double,
  depth : Double,
) -> Unit {
  p.push({
    kind: "girder",
    material: mat,
    layer: "landmark",
    position: a,
    scale: [width, 1, depth],
    rotation: 0,
    points: [b],
    caption: "",
  })
}

///|
fn profile(
  p : Array[Part],
  mat : String,
  pts : Array[Array[Double]],
  x : Double,
  y : Double,
  z : Double,
  height : Double,
  layer? : String = "landmark",
) -> Unit {
  p.push({
    kind: "profile",
    material: mat,
    layer,
    position: [x, y, z],
    scale: [1, height, 1],
    rotation: 0,
    points: pts,
    caption: "",
  })
}

///|
fn triangles(
  p : Array[Part],
  mat : String,
  pts : Array[Array[Double]],
  layer? : String = "landmark",
) -> Unit {
  p.push({
    kind: "triangles",
    material: mat,
    layer,
    position: [0, 0, 0],
    scale: [1, 1, 1],
    rotation: 0,
    points: pts,
    caption: "",
  })
}

///|
fn sign(
  p : Array[Part],
  caption : String,
  x : Double,
  y : Double,
  z : Double,
  w : Double,
  h : Double,
) -> Unit {
  p.push({
    kind: "sign",
    material: "metal",
    layer: "landmark",
    position: [x, y, z],
    scale: [w, h, 1],
    rotation: 0,
    points: [],
    caption,
  })
}

///|
fn quad(
  p : Array[Array[Double]],
  a : Array[Double],
  b : Array[Double],
  c : Array[Double],
  d : Array[Double],
) -> Unit {
  p.append([a, b, c, a, c, d])
}

///|
fn rounded_outline(w : Double, d : Double, r : Double) -> Array[Array[Double]] {
  let pts : Array[Array[Double]] = []
  for k in 0..<4 {
    let cx = if k == 0 || k == 3 { w / 2 - r } else { -w / 2 + r }
    let cz = if k < 2 { d / 2 - r } else { -d / 2 + r }
    for i in 0..<=8 {
      let a = (k.to_double() * 0.5 + i.to_double() / 16.0) * @math.PI
      pts.push([cx + r * @math.cos(a), cz + r * @math.sin(a)])
    }
  }
  pts
}

///|
// Closed Catmull-Rom outline for the creative offices' connected lobes.
fn smooth_outline(control : Array[Array[Double]]) -> Array[Array[Double]] {
  let out : Array[Array[Double]] = []
  let n = control.length()
  for i in 0..<n {
    let a = control[(i + n - 1) % n]
    let b = control[i]
    let c = control[(i + 1) % n]
    let d = control[(i + 2) % n]
    for step in 0..<6 {
      let t = step.to_double() / 6.0
      let v : Array[Double] = []
      for axis in 0..<2 {
        v.push(
          0.5 *
          (
            2 * b[axis] +
            (-a[axis] + c[axis]) * t +
            (2 * a[axis] - 5 * b[axis] + 4 * c[axis] - d[axis]) * t * t +
            (-a[axis] + 3 * b[axis] - 3 * c[axis] + d[axis]) * t * t * t
          ),
        )
      }
      out.push(v)
    }
  }
  out
}

///|
fn mix(a : Double, b : Double, t : Double) -> Double {
  a + (b - a) * t
}

///|
fn noise(seed : Int) -> Double {
  ((seed * 7919 + 104729) % 65521).to_double() / 65521.0
}
