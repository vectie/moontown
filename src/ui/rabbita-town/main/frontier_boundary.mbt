///|
/// This rectangle is the existing calibrated map, not a new camera frame.
let frontier_core : @frontier.Rect = {
  min_x: 0,
  min_y: 0,
  max_x: 256,
  max_y: 144,
}

///|
priv struct FrontierExit {
  id : String
  side : String
  x : Double
  y : Double
  dx : Double
  dy : Double
} derive(FromJson)

///|
priv struct FrontierRiver {
  x : Double
  y : Double
  dx : Double
  dy : Double
  radius : Double
  drift : Double
} derive(FromJson)

///|
priv struct FrontierBoundary {
  nodes : Array[@landmark_routes.Node]
  edges : Array[@landmark_routes.Edge]
  exits : Array[FrontierExit]
  rivers : Array[FrontierRiver]
} derive(FromJson)

///|
let frontier_boundaries : Array[FrontierBoundary] = []

///|
let frontier_mouths : Array[@frontier.Mouth] = []

///|
let frontier_gates : Array[@frontier.Road] = []

///|
let frontier_gate_chunks : Array[@frontier.Chunk] = []

///|
let frontier_render_cache : Map[String, @frontier.Chunk] = Map([])

///|
let frontier_render_frame : Array[@frontier.Chunk] = []

///|
let frontier_render_keys : Array[String] = []

///|
let frontier_city_frames : Array[@frontier.CityFrame] = []

///|
fn frontier_city_frame() -> @frontier.CityFrame {
  if frontier_city_frames.get(0) is Some(frame) {
    return frame
  }
  let b = town_bearing_at(128, 72)
  let frame : @frontier.CityFrame = {
    origin: { x: 128, y: 72, },
    east: { x: b.east.x, y: b.east.y, },
    south: { x: -b.north.x, y: -b.north.y, },
  }
  frontier_city_frames.push(frame)
  frame
}

///|
extern "js" fn frontier_boundary_input() -> String =
  #| () => {
  #|   const s=globalThis.__frontierBoundaryInput ||= {text:'',started:false};
  #|   if(!s.started){s.started=true;fetch('tilemap/wenyu-frontier-exits.json').then(r=>{if(!r.ok)throw Error('Boundary unavailable');return r.text();}).then(t=>{s.text=t;globalThis.__moontownGoldenValleyRender?.('frontier-boundary');}).catch(()=>{document.documentElement.dataset.frontierBoundary='error';});}
  #|   return s.text;
  #| }

///|
fn frontier_boundary_prepare() -> Bool {
  if !frontier_boundaries.is_empty() {
    return true
  }
  let input = frontier_boundary_input()
  if input.is_empty() {
    return false
  }
  let data : FrontierBoundary = @json.from_json(@json.parse(input)) catch {
    _ => return false
  }
  for r in data.rivers {
    frontier_mouths.push({
      point: { x: r.x, y: r.y, },
      normal: { x: r.dx, y: r.dy, },
      radius: r.radius,
      drift: r.drift,
    })
  }
  let gate_coords : Map[String, (Int32, Int32)] = Map([])
  for exit in data.exits {
    let roads = @frontier.city_gate(
      frontier_seed,
      { x: exit.x, y: exit.y, },
      { x: exit.dx, y: exit.dy, },
      frontier_city_frame(),
      frontier_core,
      frontier_mouths,
    )
    frontier_gates.append(roads)
    for r in roads {
      for p in [r.a, r.b] {
        let cx = @frontier.coordinate(p.x)
        let cy = @frontier.coordinate(p.y)
        gate_coords["\{cx}:\{cy}"] = (cx, cy)
      }
    }
  }
  for _, p in gate_coords {
    frontier_gate_chunks.push(frontier_generate(p.0, p.1))
  }
  frontier_boundaries.push(data)
  frontier_graph_cache.clear()
  true
}

///|
fn frontier_generate(cx : Int32, cy : Int32) -> @frontier.Chunk {
  @frontier.city(
    frontier_seed,
    cx,
    cy,
    frontier_city_frame(),
    frontier_core,
    frontier_gates,
    frontier_mouths,
  )
}

///|
/// Overview uses more, coarser chunks; the cache is replaced, never accumulated.
/// At the minimum camera scale the search is bounded by 32 by 32 chunks,
/// with off-screen chunks rejected before generation (not retained history).
fn frontier_visible_chunks(
  width : Int32,
  height : Int32,
) -> Array[@frontier.Chunk] {
  let corners = [
    (-80.0, -180.0),
    (width.to_double() + 80, -180.0),
    (-80.0, height.to_double() + 180),
    (width.to_double() + 80, height.to_double() + 180),
  ].map(p => {
    golden_canvas_world_at_screen(
      p.0,
      p.1,
      width,
      height,
      golden_valley_camera_x(),
      golden_valley_camera_y(),
      golden_valley_camera_zoom(),
    )
  })
  let minx = @frontier.coordinate(
    corners.fold(init=1.0e12, (n, p) => n.min(p.0)),
  )
  let miny = @frontier.coordinate(
    corners.fold(init=1.0e12, (n, p) => n.min(p.1)),
  )
  let maxx = @frontier.coordinate(
    corners.fold(init=-1.0e12, (n, p) => n.max(p.0)),
  ).min(minx + 31)
  let maxy = @frontier.coordinate(
    corners.fold(init=-1.0e12, (n, p) => n.max(p.1)),
  ).min(miny + 31)
  let key = "\{minx}:\{miny}:\{maxx}:\{maxy}:\{golden_valley_camera_x().to_int()/128}:\{golden_valley_camera_y().to_int()/128}:\{golden_valley_camera_zoom()}"
  if frontier_render_keys.get(0) == Some(key) {
    return frontier_render_frame
  }
  let next : Map[String, @frontier.Chunk] = Map([])
  frontier_render_frame.clear()
  for y in miny..<=maxy {
    for x in minx..<=maxx {
      // Do not even instantiate procedural contents in protected core chunks.
      if x >= 0 && x < 8 && y >= 0 && y < 4 {
        continue
      }
      let sx = golden_screen_x(
        (x * 32 + 16).to_double(),
        (y * 32 + 16).to_double(),
        width,
      )
      let sy = golden_screen_y(
        (x * 32 + 16).to_double(),
        (y * 32 + 16).to_double(),
        height,
      )
      let z = golden_valley_camera_zoom()
      if sx + 1024 * z < -300 ||
        sx - 1024 * z > width.to_double() + 300 ||
        sy + 512 * z < -300 ||
        sy - 512 * z > height.to_double() + 300 {
        continue
      }
      let key = "\{x}:\{y}"
      let c = frontier_render_cache
        .get(key)
        .unwrap_or_else(() => frontier_generate(x, y))
      next[key] = c
      frontier_render_frame.push(c)
    }
  }
  frontier_render_cache.clear()
  for k, c in next {
    frontier_render_cache[k] = c
  }
  frontier_render_keys.clear()
  frontier_render_keys.push(key)
  frontier_render_frame
}

///|
fn frontier_merge_graph(
  core : @landmark_routes.Graph,
  extension : @landmark_routes.Graph,
  boundary : FrontierBoundary,
) -> @landmark_routes.Graph {
  let nodes : Map[String, @landmark_routes.Node] = Map([])
  // Core wins even if an input unexpectedly repeats an ID.
  for n in extension.nodes {
    nodes[n.id] = n
  }
  for n in boundary.nodes {
    nodes[n.id] = n
  }
  for n in core.nodes {
    nodes[n.id] = n
  }
  let edges = core.edges.copy()
  edges.append(boundary.edges)
  edges.append(extension.edges)
  for e in boundary.exits {
    let p : @frontier.Point = { x: e.x, y: e.y, }
    let id = @frontier.node_id(p)
    if nodes.contains(id) {
      edges.push({ a: e.id, b: id, bridge: false, })
    }
  }
  { nodes: nodes.values().collect(), edges, }
}

///|
extern "js" fn frontier_camera_limits(enabled : Bool) -> Unit =
  #| enabled => {
  #|   const c=globalThis.__moontownGoldenValleyCamera;if(!c)return;
  #|   if(!enabled){delete c.frontierMinZoom;return;}
  #|   const el=document.getElementById('energy-valley-canvas');if(!el)return;
  #|   c.frontierMinZoom=Math.max(.07,((el.clientWidth+544)/64+(el.clientHeight+744)/32)/940);
  #|   if(!c.streetTransition)c.z=Math.max(c.frontierMinZoom,c.z);
  #|   let x=(c.x/32+c.y/16)/2,y=(c.y/16-c.x/32)/2;
  #|   x=Math.max(-1048480,Math.min(1048480,x));y=Math.max(-1048480,Math.min(1048480,y));
  #|   c.x=(x-y)*32;c.y=(x+y)*16;
  #| }
