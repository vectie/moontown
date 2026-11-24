///|
/// Reads the four-decimal grid coordinates shared by the SVG and road walkers.
pub fn decode_polyline(text : String) -> Array[Point]? {
  let points : Array[Point] = []
  let mut x = 0
  let mut y = 0
  let mut reading_x = true
  let mut bits = 0
  let mut shift = 0
  for i in 0..<text.length() {
    let code = text[i].to_int() - 63
    if code < 0 || code > 63 || shift > 25 {
      return None
    }
    bits = bits | ((code & 31) << shift)
    if code >= 32 {
      shift += 5
      continue
    }
    let delta = if (bits & 1) == 0 { bits >> 1 } else { -(bits >> 1) - 1 }
    if reading_x {
      x += delta
    } else {
      y += delta
      points.push({ x: x.to_double() / 10000, y: y.to_double() / 10000, })
    }
    reading_x = !reading_x
    bits = 0
    shift = 0
  }
  if !reading_x || shift != 0 {
    None
  } else {
    Some(points)
  }
}

///|
pub impl @json.FromJson for Graph with fn from_json(value, path) {
  guard value is { "nodes": Array(raw_nodes), "edges": Array(raw_edges), .. } else {
    raise @json.JsonDecodeError((path, "missing navigation graph"))
  }
  let nodes : Array[Node] = @json.from_json(Json::array(raw_nodes), path~)
  let edges : Array[Edge] = []
  let mut packed = false
  for raw in raw_edges {
    let e : Edge = @json.from_json(raw, path~)
    if raw is { "shape": field, .. } {
      guard field is [Number(first, ..), String(data)] &&
        first < 0 &&
        first == first.floor() &&
        decode_polyline(data) is Some(vertices) else {
        raise @json.JsonDecodeError((path, "invalid navigation shape"))
      }
      let mut prev = e.a
      for i, p in vertices {
        let id = (first - i.to_double()).to_string()
        nodes.push({ id, x: p.x, y: p.y, })
        edges.push({ a: prev, b: id, bridge: e.bridge, })
        prev = id
      }
      edges.push({ a: prev, b: e.b, bridge: e.bridge, })
      packed = true
    } else {
      edges.push(e)
    }
  }
  if packed {
    nodes.sort_by((a, b) => a.id.compare(b.id))
  }
  { nodes, edges, }
}
