///|
/// Stable identity and physical projection are separate from the old decorative
/// lots. Original architecture stays in landmark-studio; no sprite re-authoring.
priv struct TownLandmark {
  id : String
  title : String
  origin : WenyuScenePoint
  east : WenyuScenePoint
  south : WenyuScenePoint
  elevation : Double
  half_width : Double
  half_depth : Double
  door : WenyuScenePoint
  note : String
  component : Int32
  arrival : String
}

///|
let town_landmark_registry : Array[TownLandmark] = []

///|
// One destination may own several independently registered physical volumes.
let town_landmark_volumes : Array[TownLandmark] = []

///|
fn future_center_building(
  component : Int32,
  title : String,
  origin : WenyuScenePoint,
  east : WenyuScenePoint,
  south : WenyuScenePoint,
  half_width : Double,
  half_depth : Double,
  door : WenyuScenePoint,
  arrival : String,
) -> TownLandmark {
  let elevation = ((
      east.x * east.x + east.y * east.y + south.x * south.x + south.y * south.y
    ) /
    2).sqrt() *
    32
  {
    id: if component == 0 {
      "center"
    } else {
      "center-" + component.to_string()
    },
    title,
    origin,
    east,
    south,
    elevation,
    half_width,
    half_depth,
    door,
    arrival,
    component,
    note: "依据楼群影像与街道定位，步行到达街边入口。",
  }
}

///|
let town_landmark_graph : Map[String, @landmark_routes.Graph] = Map([])

///|
let town_landmark_route_points : Array[(Double, Double)] = []

///|
let town_landmark_motion : Map[String, Double] = Map([])

///|
fn town_landmark_at(
  l : TownLandmark,
  x : Double,
  z : Double,
) -> WenyuScenePoint {
  {
    x: l.origin.x + l.east.x * x + l.south.x * z,
    y: l.origin.y + l.east.y * x + l.south.y * z,
  }
}

///|
fn town_landmark_create(
  id : String,
  title : String,
  lon : Double,
  lat : Double,
  half_width : Double,
  half_depth : Double,
  bridge : Bool,
) -> TownLandmark {
  let p = town_bearing_geo_to_ground(lon, lat)
  let e = town_bearing_geo_to_ground(
    lon + 1.0 / (111320.0 * @math.cos(lat * @math.PI / 180.0)),
    lat,
  )
  let s = town_bearing_geo_to_ground(lon, lat - 1.0 / 111320.0)
  let east : WenyuScenePoint = { x: e.x - p.x, y: e.y - p.y, }
  let south : WenyuScenePoint = { x: s.x - p.x, y: s.y - p.y, }
  // Fit the straight main crossing, not the curved approach at the south end.
  // Presentation enlargement is map-only; source study geometry is untouched.
  let (east, south) : (WenyuScenePoint, WenyuScenePoint) = if bridge {
    let (dlon, dlat) = if id == "east-bridge" {
      (116.4713797 - 116.4685401, 40.1234322 - 40.1199473)
    } else {
      (116.4624858 - 116.4622087, 40.1241235 - 40.1215482)
    }
    let dx = dlon * @math.cos(lat * @math.PI / 180.0)
    let n = (dx * dx + dlat * dlat).sqrt()
    let a = dx / n
    let b = dlat / n
    (
      { x: east.x * a - south.x * b, y: east.y * a - south.y * b, },
      { x: east.x * b + south.x * a, y: east.y * b + south.y * a, },
    )
  } else {
    (east, south)
  }
  let elevation = ((
      east.x * east.x + east.y * east.y + south.x * south.x + south.y * south.y
    ) /
    2.0).sqrt() *
    32.0
  let (east, south, elevation) : (WenyuScenePoint, WenyuScenePoint, Double) = if bridge {
    (
      { x: east.x * 1.14, y: east.y * 1.14, },
      { x: south.x * 1.28, y: south.y * 1.28, },
      elevation * 1.18,
    )
  } else {
    (east, south, elevation)
  }
  let door = if bridge {
    p
  } else {
    {
      x: p.x + east.x * 43.0 + south.x * 58.0,
      y: p.y + east.y * 43.0 + south.y * 58.0,
    }
  }
  {
    id,
    title,
    origin: p,
    east,
    south,
    elevation,
    half_width,
    half_depth,
    door,
    component: 0,
    arrival: "",
    note: if bridge {
      "沿 OSM 主跨校准 · 地图展示适度放大，非测绘模型"
    } else {
      "按 A21 验收总平和影像定位，楼高近似"
    },
  }
}

///|
fn town_landmarks_init() -> Unit {
  if !town_landmark_registry.is_empty() {
    return
  }
  // WGS84 anchors, NOT raw GCJ-02 map-listing coordinates. Building centers
  // are inferred campus anchors (see integration evidence), not surveyed pins.
  town_landmark_registry.append([
    future_center_court,
    town_landmark_create(
      "vision", "未来视界", 116.47495692, 40.12507434, 126, 99, false,
    ),
    town_landmark_create(
      "east-bridge", "未来科学城东路桥", 116.46990605, 40.1217185, 204, 18,
      true,
    ),
    town_landmark_create(
      "arch-bridge", "未来科学城路桥", 116.46234725, 40.12283585, 204, 24,
      true,
    ),
  ])
  town_landmark_volumes.append(future_center_buildings)
  for l in town_landmark_registry {
    if l.id != "center" {
      town_landmark_volumes.push(l)
    }
  }
}

///|
extern "js" fn town_landmark_input() -> String =
  #| () => {
  #|   document.documentElement.dataset.landmarkNavigation='loading';
  #|   const s=globalThis.__townLandmarkInput ||= {text:'',started:false};
  #|   if(!s.started){s.started=true;fetch('landmark-studio/navigation.json').then(r=>{if(!r.ok)throw Error('Navigation unavailable');return r.text();}).then(t=>{s.text=t;globalThis.__moontownGoldenValleyRender?.('landmarks');}).catch(()=>{s.error=true;});}
  #|   return s.text;
  #| }

///|
extern "js" fn town_landmark_publish(
  data : String,
  route : (String, String) -> String,
  walk : (String, String) -> String,
  playback : (String) -> Unit,
) -> Unit =
  #| (data,route,walk,playback) => {
  #|   document.documentElement.dataset.landmarkNavigation='ready';
  #|   globalThis.__townLandmarks = {places:JSON.parse(data),route:(a,b)=>JSON.parse(route(a,b)),walk:(a,b)=>JSON.parse(walk(a,b)),playback};
  #|   globalThis.dispatchEvent(new Event('town-landmarks-ready'));
  #| }

///|
fn town_landmark_record(l : TownLandmark, buildings : Array[Json]) -> Json {
  let p = if buildings.is_empty() { l.origin } else { l.door }
  let corners = [
    town_landmark_at(l, -l.half_width, -l.half_depth),
    town_landmark_at(l, l.half_width, -l.half_depth),
    town_landmark_at(l, l.half_width, l.half_depth),
    town_landmark_at(l, -l.half_width, l.half_depth),
  ]
  let j : Json = {
    "id": l.id,
    "title": l.title,
    "x": p.x,
    "y": p.y,
    "east": [l.east.x, l.east.y],
    "south": [l.south.x, l.south.y],
    "elevation": l.elevation,
    "halfWidth": l.half_width,
    "halfDepth": l.half_depth,
    "door": [l.door.x, l.door.y],
    "footprint": if buildings.is_empty() {
      corners.map(p => [p.x, p.y]).to_json()
    } else {
      Json::array([])
    },
    "note": l.note,
    "component": l.component,
    "arrivalNode": l.arrival,
    "blocks": if buildings.is_empty() {
      Json::array([])
    } else {
      future_center_review_blocks
      .map(b => {
        Json::object({ "id": b.0, "ring": b.1.map(p => [p.x, p.y]).to_json() })
      })
      .to_json()
    },
    "buildings": buildings,
  }
  j
}

///|
fn town_landmark_prepare() -> Unit {
  town_landmarks_init()
  if town_landmark_graph.contains("active") {
    return
  }
  let input = town_landmark_input()
  if input.is_empty() {
    return
  }
  let graph : @landmark_routes.Graph = @json.from_json(@json.parse(input)) catch {
    e => {
      town_landmark_diagnostic(e.to_string())
      return
    }
  }
  town_landmark_graph["active"] = graph
  let parts = future_center_buildings.map(l => town_landmark_record(l, []))
  let records = town_landmark_registry.map(l => {
    town_landmark_record(l, if l.id == "center" { parts } else { [] })
  })
  town_landmark_publish(
    records.to_json().stringify(),
    town_landmark_route_json,
    town_landmark_walk,
    town_landmark_playback,
  )
}

///|
extern "js" fn town_landmark_diagnostic(message : String) -> Unit =
  #| message => { document.documentElement.dataset.landmarkNavigationError=message; }

///|
fn town_landmark_find(id : String) -> TownLandmark? {
  for l in town_landmark_registry {
    if l.id == id {
      return Some(l)
    }
  }
  for l in future_center_buildings {
    if l.id == id {
      return Some(l)
    }
  }
  None
}

///|
fn town_landmark_arrival(
  g : @landmark_routes.Graph,
  l : TownLandmark,
) -> String? {
  if l.arrival.is_empty() {
    @landmark_routes.nearest(g, { x: l.door.x, y: l.door.y, }, 4.0)
  } else if g.nodes.any(n => n.id == l.arrival) {
    Some(l.arrival)
  } else {
    None
  }
}

///|
fn town_landmark_route(from : String, to : String) -> Array[(Double, Double)]? {
  guard town_landmark_graph.get("active") is Some(g) else { return None }
  if from == to && (from == "east-bridge" || from == "arch-bridge") {
    let (s, t) = if from == "east-bridge" {
      ("3983803697", "3983803696")
    } else {
      ("3354163950", "3354163962")
    }
    return @landmark_routes.route(g, s, t).map(ps => ps.map(p => (p.x, p.y)))
  }
  // A disconnected graph stays disconnected. Never interpolate a town-wide
  // straight line through water or campus buildings when routing fails.
  let arrival = (id : String) => {
    match town_district_arrivals.get(id) {
      Some(node) => Some(node)
      None => town_landmark_find(id).bind(l => town_landmark_arrival(g, l))
    }
  }
  guard arrival(from) is Some(s) &&
    arrival(to) is Some(t) &&
    @landmark_routes.route(g, s, t) is Some(path) else {
    return None
  }
  let result = path.map(p => (p.x, p.y))
  // Building paths stop at the road-side arrival node. Interior access is an
  // explicit portal action; an unverified short entrance is not a walk edge.
  Some(result)
}

///|
fn town_landmark_route_json(from : String, to : String) -> String {
  town_landmark_route_result(town_landmark_route(from, to))
}

///|
fn town_landmark_route_result(path : Array[(Double, Double)]?) -> String {
  match path {
    Some(path) =>
      Json::object({
        "ok": true,
        "points": path.map(p => [p.0, p.1]).to_json(),
        "authority": "local-simulation",
        "arrival": "road-side portal",
      }).stringify()
    None =>
      Json::object({
        "ok": false,
        "reason": "No connected road route within entrance tolerance",
      }).stringify()
  }
}

///|
fn town_landmark_walk(from : String, to : String) -> String {
  let result = town_landmark_route(from, to)
  town_landmark_route_points.clear()
  if result is Some(path) {
    town_landmark_route_points.append(path)
    town_landmark_motion["started"] = golden_animation_seconds()
    town_landmark_motion["paused"] = 0.0
  }
  town_landmark_route_result(result)
}

///|
fn town_landmark_playback(action : String) -> Unit {
  let now = golden_animation_seconds()
  if action == "pause" &&
    town_landmark_motion.get("paused").unwrap_or(0.0) == 0.0 {
    town_landmark_motion["elapsed"] = now -
      town_landmark_motion.get("started").unwrap_or(now)
    town_landmark_motion["paused"] = 1.0
  } else if action == "resume" &&
    town_landmark_motion.get("paused") == Some(1.0) {
    town_landmark_motion["started"] = now -
      town_landmark_motion.get("elapsed").unwrap_or(0.0)
    town_landmark_motion["paused"] = 0.0
  } else if action == "stop" {
    town_landmark_route_points.clear()
  }
}

///|
fn town_landmark_reserved(x : Double, y : Double, pad : Double) -> Bool {
  if town_district_reserved(x, y, pad) {
    return true
  }
  for l in town_landmark_volumes {
    let dx = x - l.origin.x
    let dy = y - l.origin.y
    let det = l.east.x * l.south.y - l.east.y * l.south.x
    let u = (dx * l.south.y - dy * l.south.x) / det
    let v = (dy * l.east.x - dx * l.east.y) / det
    let margin = pad / (l.elevation / 32.0)
    if u.abs() < l.half_width + margin && v.abs() < l.half_depth + margin {
      return true
    }
  }
  false
}

///|
extern "js" fn town_district_reserved(
  x : Double,
  y : Double,
  pad : Double,
) -> Bool =
  #| (x,y,pad)=>globalThis.__townLandmarkPainter?.districtReserved?.(x,y,pad) ?? false

///|
extern "js" fn town_district_ready() -> Bool =
  #| ()=>globalThis.__townLandmarkPainter?.districtReady?.() ?? false

///|
extern "js" fn town_landmark_draw(
  context : @dom.CanvasRenderingContext2D,
  depth : Int32,
  camera_x : Double,
  camera_y : Double,
  zoom : Double,
  width : Int32,
  height : Int32,
  seconds : Double,
  reduced : Bool,
  hour : Double,
) -> Unit =
  #| (ctx,depth,cx,cy,z,w,h,sec,reduced,hour)=>globalThis.__townLandmarkPainter?.draw(ctx,depth,cx,cy,z,w,h,sec,reduced,hour)

///|
extern "js" fn town_landmark_draw_route(
  context : @dom.CanvasRenderingContext2D,
  points : String,
  position : String,
  progress : Double,
  camera_x : Double,
  camera_y : Double,
  zoom : Double,
  width : Int32,
  height : Int32,
  draw_agent : (Double, Double) -> Unit,
) -> Unit =
  #| (ctx,points,position,progress,cx,cy,z,w,h,drawAgent)=>globalThis.__townLandmarkPainter?.drawRoute(ctx,JSON.parse(points),JSON.parse(position),progress,cx,cy,z,w,h,drawAgent)

///|
fn town_landmark_draw_walker(
  context : @dom.CanvasRenderingContext2D,
  width : Int32,
  height : Int32,
) -> Unit {
  if town_landmark_route_points.is_empty() {
    return
  }
  let length = player_path_length(town_landmark_route_points)
  let elapsed = if town_landmark_motion.get("paused") == Some(1.0) {
    town_landmark_motion.get("elapsed").unwrap_or(0.0)
  } else {
    golden_animation_seconds() -
    town_landmark_motion.get("started").unwrap_or(0.0)
  }
  let distance = (elapsed * 2.4).min(length)
  let p = player_point_along(town_landmark_route_points, distance)
  let next = player_point_along(
    town_landmark_route_points,
    (distance + 0.1).min(length),
  )
  town_landmark_draw_route(
    context,
    town_landmark_route_points.map(p => [p.0, p.1]).to_json().stringify(),
    [p.0, p.1].to_json().stringify(),
    if length > 0 {
      distance / length
    } else {
      1.0
    },
    golden_valley_camera_x(),
    golden_valley_camera_y(),
    golden_valley_camera_zoom(),
    width,
    height,
    fn(sx, sy) {
      golden_draw_sprite_agent(
        context,
        sx,
        sy,
        golden_valley_camera_zoom().max(0.32),
        golden_valley_agent_sprite_path("researcher", 0),
        next.0 - next.1 < p.0 - p.1,
        if golden_prefers_reduced_motion() || distance >= length {
          0.0
        } else {
          elapsed * 9.0
        },
        "#d8b861",
        "↗",
        "导航预览",
        true,
        true,
      )
    },
  )
}
