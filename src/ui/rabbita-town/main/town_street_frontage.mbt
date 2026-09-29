///|
priv struct TownStreetSegment {
  a : WenyuScenePoint
  b : WenyuScenePoint
}

///|
priv struct TownStreetHit {
  point : WenyuScenePoint
  dx : Double
  dy : Double
  distance : Double
}

///|
let town_street_segments : Array[TownStreetSegment] = []

///|
let town_street_bins : Map[Int, Array[Int]] = Map([])

///|
let town_street_hit_cache : Map[String, TownStreetHit?] = Map([])

///|
/// Match the SVG's ground clip exactly. Off-map continuation is not frontage.
fn town_street_clip(segment : TownStreetSegment) -> TownStreetSegment? {
  let a = segment.a
  let dx = segment.b.x - a.x
  let dy = segment.b.y - a.y
  let mut enter = 0.0
  let mut leave = 1.0
  for pair in [(-dx, a.x), (dx, 256.0 - a.x), (-dy, a.y), (dy, 144.0 - a.y)] {
    let (p, q) = pair
    if p.abs() < 0.0000001 {
      if q < 0.0 {
        return None
      }
    } else {
      let t = q / p
      if p < 0.0 {
        enter = enter.max(t)
      } else {
        leave = leave.min(t)
      }
      if enter > leave {
        return None
      }
    }
  }
  Some({
    a: { x: a.x + enter * dx, y: a.y + enter * dy, },
    b: { x: a.x + leave * dx, y: a.y + leave * dy, },
  })
}

///|
/// Read the same shipped SVG used by the renderer. No second calibration,
/// invented streets or new asset: transport only at the browser boundary.
extern "js" fn town_street_svg_input() -> String =
  #| () => {
  #|   let s=globalThis.__townStreetSvgTransport;
  #|   if(!s){s={text:''};globalThis.__townStreetSvgTransport=s;
  #|     fetch('tilemap/wenyu-unshifted-road-overlay.svg').then(r=>{if(!r.ok)throw Error('Street frontage unavailable');return r.text();})
  #|       .then(t=>{s.text=t;globalThis.__moontownGoldenValleyRender?.('street-frontage');}).catch(()=>{});}
  #|   return s.text;
  #| }

///|
/// The generated overlay has a deliberately restricted M/L path grammar.
/// Parse only its road group, not the wide green-spine decoration.
fn town_street_parse(svg : String) -> Array[TownStreetSegment] raise {
  let groups = svg.split("<g fill='none' stroke='#ffc46d'").to_array()
  guard groups.length() == 2 else { fail("Missing canonical road group") }
  let result : Array[TownStreetSegment] = []
  let paths = groups[1].to_string().split("<path d='M").to_array()
  for path in paths[1:] {
    let raw = path.to_string().split("'").to_array()[0].to_string()
    let vertices : Array[WenyuScenePoint] = []
    for vertex in raw.split("L") {
      let xy = vertex.to_string().split(",").to_array()
      guard xy.length() == 2 else { fail("Unsupported road vertex") }
      let x = @string.parse_double(xy[0])
      let y = @string.parse_double(xy[1])
      guard x.abs() < 100000 && y.abs() < 100000 else {
        fail("Invalid road vertex")
      }
      vertices.push({ x, y, })
    }
    for i in 1..<vertices.length() {
      if town_street_clip({ a: vertices[i - 1], b: vertices[i], })
        is Some(segment) {
        result.push(segment)
      }
    }
  }
  guard !result.is_empty() else { fail("Empty road geometry") }
  result
}

///|
fn town_street_prepare() -> Bool {
  if !town_street_segments.is_empty() {
    return true
  }
  let svg = town_street_svg_input()
  if svg.is_empty() {
    return false
  }
  let parsed = town_street_parse(svg) catch { _ => return false }
  town_street_index(parsed)
  true
}

///|
fn town_street_index(parsed : Array[TownStreetSegment]) -> Unit {
  town_street_segments.clear()
  town_street_bins.clear()
  town_street_hit_cache.clear()
  town_building_bearing_cache.clear()
  for segment in parsed {
    let index = town_street_segments.length()
    town_street_segments.push(segment)
    let a = segment.a
    let b = segment.b
    for
      y in (a.y.min(b.y) / 8.0).floor().to_int().max(0).min(17)..<=(a.y.max(b.y) /
      8.0)
      .floor()
      .to_int()
      .min(17) {
      for
        x in (a.x.min(b.x) / 8.0).floor().to_int().max(0).min(31)..<=(a.x.max(
          b.x,
        ) /
        8.0)
        .floor()
        .to_int()
        .min(31) {
        let key = y * 32 + x
        match town_street_bins.get(key) {
          Some(items) => items.push(index)
          None => town_street_bins[key] = [index]
        }
      }
    }
  }
}

///|
fn town_street_project(
  segment : TownStreetSegment,
  x : Double,
  y : Double,
) -> TownStreetHit {
  let dx = segment.b.x - segment.a.x
  let dy = segment.b.y - segment.a.y
  let length = dx * dx + dy * dy
  let t = if length > 0.0000001 {
    (((x - segment.a.x) * dx + (y - segment.a.y) * dy) / length)
    .max(0.0)
    .min(1.0)
  } else {
    0.0
  }
  let point : WenyuScenePoint = {
    x: segment.a.x + t * dx,
    y: segment.a.y + t * dy,
  }
  {
    point,
    dx,
    dy,
    distance: ((point.x - x) * (point.x - x) + (point.y - y) * (point.y - y)).sqrt(),
  }
}

///|
fn town_street_nearest(x : Double, y : Double) -> TownStreetHit? {
  let key = "\{x}:\{y}"
  if town_street_hit_cache.get(key) is Some(cached) {
    return cached
  }
  let mut best : TownStreetHit? = None
  let mut distance = 8.0
  for
    yy in ((y - 8.0) / 8.0).floor().to_int().max(0)..<=((y + 8.0) / 8.0)
    .floor()
    .to_int()
    .min(17) {
    for
      xx in ((x - 8.0) / 8.0).floor().to_int().max(0)..<=((x + 8.0) / 8.0)
      .floor()
      .to_int()
      .min(31) {
      for index in town_street_bins.get(yy * 32 + xx).unwrap_or([]) {
        let hit = town_street_project(town_street_segments[index], x, y)
        if hit.distance < distance {
          best = Some(hit)
          distance = hit.distance
        }
      }
    }
  }
  if town_street_hit_cache.length() >= 1024 {
    town_street_hit_cache.clear()
  }
  town_street_hit_cache[key] = best
  best
}

///|
fn town_street_lot_gap(b : IntersectionRoadPreviewBuilding) -> Double {
  let (x, y) = intersection_road_preview_building_center(b)
  match town_street_nearest(x, y) {
    None => 100.0
    Some(hit) => {
      let dx = (b.x.to_double() - hit.point.x)
        .max(0.0)
        .max(hit.point.x - (b.x + b.width).to_double())
      let dy = (b.y.to_double() - hit.point.y)
        .max(0.0)
        .max(hit.point.y - (b.y + b.depth).to_double())
      (dx * dx + dy * dy).sqrt()
    }
  }
}

///|
/// A short entry walk from the street-facing lot edge, not a new road from
/// the south door to a distant walker path. Cardinal building facing stays.
fn town_street_entry_geometry(
  b : TownBuildingBearing,
  span : Double,
  x : Double,
  y : Double,
  road : WenyuScenePoint,
) -> (WenyuScenePoint, WenyuScenePoint)? {
  let det = b.east.x * b.north.y - b.east.y * b.north.x
  if span <= 0.0 || det.abs() < 0.00001 {
    return None
  }
  let dx = road.x - x
  let dy = road.y - y
  let u = ((dx * b.north.y - dy * b.north.x) / det / span).max(-0.5).min(0.5)
  let v = ((b.east.x * dy - b.east.y * dx) / det / span).max(-0.5).min(0.5)
  let ax = x + (b.east.x * u + b.north.x * v) * span
  let ay = y + (b.east.y * u + b.north.y * v) * span
  let length = ((road.x - ax) * (road.x - ax) + (road.y - ay) * (road.y - ay)).sqrt()
  if length > 1.75 || length < 0.01 {
    return None
  }
  Some(({ x: ax, y: ay, }, road))
}

///|
fn town_street_draw_entry(
  context : @dom.CanvasRenderingContext2D,
  building : IntersectionRoadPreviewBuilding,
  width : Int,
  height : Int,
) -> Unit {
  let (x, y) = intersection_road_preview_building_center(building)
  guard town_street_nearest(x, y) is Some(hit) else { return }
  let b = town_building_bearing(building)
  guard town_street_entry_geometry(
      b,
      town_bearing_span(b, building.width, building.depth),
      x,
      y,
      hit.point,
    )
    is Some((start, _)) else {
    return
  }
  let ax = start.x
  let ay = start.y
  for i in 0..<=16 {
    let t = i.to_double() / 16.0
    if !intersection_road_preview_reference_cell_buildable(
        (ax + (hit.point.x - ax) * t).floor().to_int(),
        (ay + (hit.point.y - ay) * t).floor().to_int(),
      ) {
      return
    }
  }
  town_street_entry_paint(
    context,
    golden_screen_x(ax, ay, width),
    golden_screen_y(ax, ay, height),
    golden_screen_x(hit.point.x, hit.point.y, width),
    golden_screen_y(hit.point.x, hit.point.y, height),
    golden_valley_camera_zoom(),
  )
}

///|
extern "js" fn town_street_entry_paint(
  c : @dom.CanvasRenderingContext2D,
  ax : Double,
  ay : Double,
  bx : Double,
  by : Double,
  zoom : Double,
) -> Unit =
  #| (c,ax,ay,bx,by,z)=>{c.save();c.beginPath();c.moveTo(ax,ay);c.lineTo(bx,by);c.strokeStyle='#d7c5a3';c.lineWidth=5*z;c.lineCap='round';c.stroke();c.restore();}
