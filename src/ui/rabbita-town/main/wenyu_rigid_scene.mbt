///|
/// Display-space scene data, compiled with the exact same rigid roads as the SVG.
priv struct WenyuScenePoint {
  x : Double
  y : Double
}

///|
priv struct WenyuScenePath {
  points : Array[WenyuScenePoint]
  lengths : Array[Double]
  total : Double
}

///|
let wenyu_scene_paths : Array[WenyuScenePath] = []

///|
let wenyu_scene_prefix : Array[Int] = []

///|
let wenyu_scene_road_prefix : Array[Int] = []

///|
let wenyu_scene_access_cache : Map[String, WenyuScenePoint?] = Map([])

///|
fn wenyu_rigid_scene_active() -> Bool {
  wenyu_scene_default_requested() ||
  (wenyu_gentle_ground_trial_requested() && wenyu_gentle_bank_requested())
}

///|
/// Production outdoor presentation; explicit historical reviews remain opt-in.
extern "js" fn wenyu_scene_default_requested() -> Bool =
  #| () => {
  #|   if (!globalThis.location) return false;
  #|   const p = new URLSearchParams(globalThis.location.search || '');
  #|   return !p.has('road-trial') && !p.has('registration-review');
  #| }

///|
/// Fetch transport only; all scene parsing, placement and movement are MoonBit.
extern "js" fn wenyu_scene_input() -> String =
  #| () => {
  #|   let state = globalThis.__wenyuRigidSceneTransport;
  #|   if (!state) {
  #|     state = { status: 'loading', text: '' };
  #|     globalThis.__wenyuRigidSceneTransport = state;
  #|     fetch('tilemap/wenyu-unshifted-scene.json').then(response => {
  #|       if (!response.ok) throw new Error('Scene data unavailable');
  #|       return response.text();
  #|     }).then(text => {
  #|       state.text = text; state.status = 'ready';
  #|       globalThis.__moontownGoldenValleyRender?.('rigid-scene');
  #|     }).catch(() => { state.status = 'error'; });
  #|   }
  #|   return state.text;
  #| }

///|
fn wenyu_scene_prepare() -> Bool {
  if town_bearing_buildings_requested() && !town_street_prepare() {
    return false
  }
  if !wenyu_scene_prefix.is_empty() {
    return true
  }
  let input = wenyu_scene_input()
  if input.is_empty() || !reference_tile_snapshot_ready() {
    return false
  }
  let parsed = @json.parse(input) catch { _ => Json::null() }
  guard parsed
    is {
      "schema": String("moontown.wenyu_rigid_scene.v1"),
      "riversideShiftsApplied": False,
      "roadCells": Array(rows),
      "paths": Array(paths),
      ..
    } &&
    rows.length() == 144 else {
    return false
  }
  let prefix = Array::make(257 * 145, 0)
  let road_prefix = Array::make(257 * 145, 0)
  for y in 0..<144 {
    guard rows[y] is String(row) && row.length() == 256 else { return false }
    for x in 0..<256 {
      let blocked = row[x] == 'R' ||
        !intersection_road_preview_reference_cell_buildable(x, y)
      let i = (y + 1) * 257 + x + 1
      prefix[i] = (if blocked { 1 } else { 0 }) +
        prefix[i - 1] +
        prefix[i - 257] -
        prefix[i - 258]
      road_prefix[i] = (if row[x] == 'R' { 1 } else { 0 }) +
        road_prefix[i - 1] +
        road_prefix[i - 257] -
        road_prefix[i - 258]
    }
  }
  for raw in paths {
    guard raw is { "points": Array(points), .. } else { continue }
    let ps : Array[WenyuScenePoint] = []
    let lengths : Array[Double] = []
    let mut total = 0.0
    for p in points {
      guard p is [Number(x, ..), Number(y, ..)] else { continue }
      if !ps.is_empty() {
        let prev = ps[ps.length() - 1]
        total += ((x - prev.x) * (x - prev.x) + (y - prev.y) * (y - prev.y)).sqrt()
      }
      ps.push({ x, y, })
      lengths.push(total)
    }
    if ps.length() > 1 && total > 2.0 {
      wenyu_scene_paths.push({ points: ps, lengths, total, })
    }
  }
  wenyu_scene_paths.sort_by((a, b) => b.total.compare(a.total))
  for n in prefix {
    wenyu_scene_prefix.push(n)
  }
  for n in road_prefix {
    wenyu_scene_road_prefix.push(n)
  }
  true
}

///|
fn wenyu_scene_region_clear(
  prefix : Array[Int],
  x : Int,
  y : Int,
  width : Int,
  depth : Int,
) -> Bool {
  if prefix.length() != 257 * 145 ||
    width <= 0 ||
    depth <= 0 ||
    x < 0 ||
    y < 0 ||
    x + width > 256 ||
    y + depth > 144 {
    return false
  }
  let a = y * 257 + x
  let b = y * 257 + x + width
  let c = (y + depth) * 257 + x
  let d = (y + depth) * 257 + x + width
  prefix[d] - prefix[b] - prefix[c] + prefix[a] == 0
}

///|
fn wenyu_scene_nearest(x : Double, y : Double) -> WenyuScenePoint? {
  let key = "\{x}:\{y}"
  match wenyu_scene_access_cache.get(key) {
    Some(p) => return p
    None => ()
  }
  let mut best : WenyuScenePoint? = None
  let mut distance = 100.0
  for path in wenyu_scene_paths {
    for i in 1..<path.points.length() {
      let a = path.points[i - 1]
      let b = path.points[i]
      let dx = b.x - a.x
      let dy = b.y - a.y
      let length = dx * dx + dy * dy
      let t = if length > 0 {
        ((x - a.x) * dx + (y - a.y) * dy) / length
      } else {
        0.0
      }
      let t = t.max(0.0).min(1.0)
      let p : WenyuScenePoint = { x: a.x + t * dx, y: a.y + t * dy, }
      let d = (p.x - x) * (p.x - x) + (p.y - y) * (p.y - y)
      if d < distance {
        distance = d
        best = Some(p)
      }
    }
  }
  wenyu_scene_access_cache[key] = best
  best
}

///|
fn wenyu_scene_lot_valid(b : IntersectionRoadPreviewBuilding) -> Bool {
  if !wenyu_scene_region_clear(
      wenyu_scene_prefix,
      b.x - b.apron,
      b.y - b.apron,
      b.width + b.apron * 2,
      b.depth + b.apron * 2,
    ) {
    return false
  }
  // Frontage is road occupancy, not just a wetland/forest edge.
  let x = (b.x - 3).max(0)
  let y = (b.y - 3).max(0)
  !wenyu_scene_region_clear(
    wenyu_scene_road_prefix,
    x,
    y,
    (b.x + b.width + 3).min(256) - x,
    (b.y + b.depth + 3).min(144) - y,
  )
}

///|
/// Constant distance speed, reversing at endpoints instead of teleporting.
fn wenyu_scene_sample(
  path : WenyuScenePath,
  distance : Double,
) -> WenyuScenePoint {
  let cycle = distance / (path.total * 2.0)
  let distance = (cycle - cycle.floor()) * path.total * 2.0
  let distance = if distance > path.total {
    path.total * 2.0 - distance
  } else {
    distance
  }
  for i in 1..<path.points.length() {
    if distance <= path.lengths[i] {
      let span = path.lengths[i] - path.lengths[i - 1]
      let t = if span > 0 {
        (distance - path.lengths[i - 1]) / span
      } else {
        0.0
      }
      let a = path.points[i - 1]
      let b = path.points[i]
      return { x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t, }
    }
  }
  path.points[path.points.length() - 1]
}

///|
fn wenyu_scene_walkers(
  seconds : Double,
  reduced : Bool,
) -> Array[GoldenValleyCanvasAgent] {
  let result : Array[GoldenValleyCanvasAgent] = []
  let roles = ["worker", "researcher", "resident", "keeper"]
  for i in 0..<wenyu_scene_paths.length().min(12) {
    let path = wenyu_scene_paths[i]
    let d = path.total * (i.to_double() * 0.137) +
      (if reduced { 0.0 } else { seconds * 0.65 })
    let p = wenyu_scene_sample(path, d)
    let next = wenyu_scene_sample(path, d + 0.1)
    result.push({
      x: p.x,
      y: p.y,
      sprite_path: golden_valley_agent_sprite_path(roles[i % 4], i),
      facing_left: next.x - next.y < p.x - p.y,
      bob: if reduced {
        0.0
      } else {
        seconds * 9.0 + i.to_double()
      },
      work_color: "#a5cba1",
      activity_glyph: "",
      activity_label: "",
      preview: false,
      selected: false,
    })
  }
  result
}

///|
extern "js" fn wenyu_scene_line(
  context : @dom.CanvasRenderingContext2D,
  ax : Double,
  ay : Double,
  bx : Double,
  by : Double,
  zoom : Double,
) -> Unit =
  #| (context,ax,ay,bx,by,zoom)=>{
  #|   context.save();context.beginPath();context.moveTo(ax,ay);context.lineTo(bx,by);
  #|   context.strokeStyle='#e9e1ce';context.lineWidth=12*zoom;context.lineCap='round';context.stroke();context.restore();
  #| }

///|
fn wenyu_scene_draw_access(
  context : @dom.CanvasRenderingContext2D,
  x : Double,
  y : Double,
  width : Int,
  height : Int,
) -> Unit {
  match wenyu_scene_nearest(x, y) {
    None => ()
    Some(p) => {
      // Refuse a decorative approach across authored water/forest or other lots' roads.
      let dx = p.x - x
      let dy = p.y - y
      let n = ((dx * dx + dy * dy).sqrt() * 4.0).ceil().to_int().max(1)
      for i in 0..<=n {
        let t = i.to_double() / n.to_double()
        if !intersection_road_preview_reference_cell_buildable(
            (x + dx * t).floor().to_int(),
            (y + dy * t).floor().to_int(),
          ) {
          return
        }
      }
      wenyu_scene_line(
        context,
        golden_screen_x(x, y, width),
        golden_screen_y(x, y, height),
        golden_screen_x(p.x, p.y, width),
        golden_screen_y(p.x, p.y, height),
        golden_valley_camera_zoom(),
      )
    }
  }
}
