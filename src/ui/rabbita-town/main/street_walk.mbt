///|
/// A visit is transient presentation state, not an account, resident record or
/// runtime agent. Walk only the accepted landmark graph; never create a shortcut
/// across a lot, water, or two visually intersecting but disconnected roads.
priv struct StreetRoadPoint {
  edge : Int32
  t : Double
  point : (Double, Double)
}

///|
fn street_road_point(
  graph : @landmark_routes.Graph,
  p : (Double, Double),
  radius : Double,
  edge_hint~ : (Double, Double)? = None,
) -> StreetRoadPoint? {
  let nodes : Map[String, @landmark_routes.Node] = Map([])
  for node in graph.nodes {
    nodes[node.id] = node
  }
  let mut best = None
  let mut distance = radius * radius
  for index, edge in graph.edges {
    guard nodes.get(edge.a) is Some(a) && nodes.get(edge.b) is Some(b) else {
      continue
    }
    let dx = b.x - a.x
    let dy = b.y - a.y
    let length = dx * dx + dy * dy
    if length < 0.00000001 {
      continue
    }
    if edge_hint is Some(hint) {
      let ht = (((hint.0 - a.x) * dx + (hint.1 - a.y) * dy) / length)
        .max(0.0)
        .min(1.0)
      let hx = hint.0 - a.x - ht * dx
      let hy = hint.1 - a.y - ht * dy
      if hx * hx + hy * hy > 0.000000001 {
        continue
      }
    }
    let t = (((p.0 - a.x) * dx + (p.1 - a.y) * dy) / length).max(0.0).min(1.0)
    let point = (a.x + t * dx, a.y + t * dy)
    let d = (p.0 - point.0) * (p.0 - point.0) +
      (p.1 - point.1) * (p.1 - point.1)
    if d < distance {
      distance = d
      best = Some({ edge: index, t, point, })
    }
  }
  best
}

///|
/// Insert both projected positions into their actual edges before routing.
/// Splitting an edge preserves bridge metadata and avoids node-to-node jumps
/// when a walk is interrupted midway. The source graph is never mutated.
fn street_road_route(
  graph : @landmark_routes.Graph,
  start : (Double, Double),
  goal : (Double, Double),
  start_hint~ : (Double, Double)? = None,
) -> Array[(Double, Double)]? {
  guard street_road_point(graph, start, 0.05, edge_hint=start_hint) is Some(a) &&
    street_road_point(graph, goal, 1.1) is Some(b) else {
    return None
  }
  let nodes = graph.nodes.copy()
  nodes.push({ id: "street-visit-start", x: a.point.0, y: a.point.1, })
  nodes.push({ id: "street-visit-goal", x: b.point.0, y: b.point.1, })
  let edges : Array[@landmark_routes.Edge] = []
  for index, edge in graph.edges {
    let splits : Array[(Double, String)] = [(0.0, edge.a), (1.0, edge.b)]
    if index == a.edge {
      splits.push((a.t, "street-visit-start"))
    }
    if index == b.edge {
      splits.push((b.t, "street-visit-goal"))
    }
    splits.sort_by((a, b) => a.0.compare(b.0))
    for i in 1..<splits.length() {
      edges.push({ a: splits[i - 1].1, b: splits[i].1, bridge: edge.bridge, })
    }
  }
  @landmark_routes.route(
    { nodes, edges, },
    "street-visit-start",
    "street-visit-goal",
  ).map(path => path.map(p => (p.x, p.y)))
}

///|
fn street_spawn() -> (Double, Double)? {
  guard town_landmark_graph.get("active") is Some(graph) &&
    town_landmark_find("center") is Some(center) else {
    return None
  }
  street_road_point(graph, (center.door.x, center.door.y), 4.0).map(p => p.point)
}

///|
fn street_position(model : Model) -> (Double, Double)? {
  match model.street_motion {
    Some(motion) =>
      Some(
        player_point_along(
          motion.path,
          ((golden_animation_seconds() - motion.started_seconds) *
          player_walk_speed).max(0.0),
        ),
      )
    None => street_spawn()
  }
}

///|
/// Remember the incoming edge at an exact geometric crossing. Coordinates
/// alone cannot distinguish a bridge from the unrelated road underneath it.
fn street_incoming_hint(model : Model) -> (Double, Double)? {
  model.street_motion.map(m => {
    let distance = ((golden_animation_seconds() - m.started_seconds) *
      player_walk_speed)
      .max(0.0)
      .min(player_path_length(m.path))
    player_point_along(
      m.path,
      if distance > 0.002 {
        distance - 0.001
      } else {
        distance + 0.001
      },
    )
  })
}

///|
extern "js" fn street_walk_follow(recenter : Bool) -> Unit =
  #| recenter => {
  #|   const camera = globalThis.__moontownGoldenValleyCamera;
  #|   if (camera) { camera.streetFollow = true; camera.streetRecenter = recenter; }
  #| }

///|
fn street_walk_to(model : Model, point : (Double, Double)) -> Model {
  if !model.street_living_room ||
    !(model.town_spatial_layer is Outdoor) ||
    model.neighborhood.open ||
    model.energy_request_open {
    return model
  }
  guard town_landmark_graph.get("active") is Some(graph) &&
    street_position(model) is Some(start) else {
    return {
      ..model,
      life_toast: "道路加载中",
      life_toast_tick: model.tick,
    }
  }
  guard street_road_route(
      graph,
      start,
      point,
      start_hint=street_incoming_hint(model),
    )
    is Some(path) &&
    player_path_length(path) > 0.01 else {
    return {
      ..model,
      life_toast: "请选择相连的道路",
      life_toast_tick: model.tick,
    }
  }
  street_walk_follow(false)
  let target = path[path.length() - 1]
  {
    ..model,
    street_motion: Some({
      from_x: start.0,
      from_y: start.1,
      to_x: target.0,
      to_y: target.1,
      started_seconds: golden_animation_seconds() -
      (if golden_prefers_reduced_motion() {
        player_path_length(path) / player_walk_speed
      } else {
        0.0
      }),
      path,
    }),
    life_toast: "",
  }
}

///|
fn street_walk_screen(
  model : Model,
  screen_x : Int32,
  screen_y : Int32,
) -> Model {
  let zoom = golden_valley_camera_zoom()
  let px = (
      screen_x.to_double() -
      golden_valley_canvas_width("energy-valley-canvas").to_double() / 2.0
    ) /
    zoom +
    golden_valley_camera_x()
  let py = (
      screen_y.to_double() -
      golden_valley_canvas_height("energy-valley-canvas").to_double() / 2.0
    ) /
    zoom +
    golden_valley_camera_y()
  street_walk_to(
    model,
    ((px / 32.0 + py / 16.0) / 2.0, (py / 16.0 - px / 32.0) / 2.0),
  )
}

///|
fn street_step(model : Model, dx : Int32, dy : Int32) -> Model {
  guard street_position(model) is Some(p) &&
    town_landmark_graph.get("active") is Some(graph) else {
    return model
  }
  // A screen-direction step selects a nearby connected edge, not a raw tile.
  for distance in 1..<=4 {
    let point = (
      p.0 + dx.to_double() * distance.to_double() * 0.5,
      p.1 + dy.to_double() * distance.to_double() * 0.5,
    )
    if street_road_route(
        graph,
        p,
        point,
        start_hint=street_incoming_hint(model),
      )
      is Some(path) &&
      player_path_length(path) > 0.1 {
      return street_walk_to(model, point)
    }
  }
  { ..model, life_toast: "换个方向试试", life_toast_tick: model.tick, }
}

///|
fn street_draw_visitor(
  context : @dom.CanvasRenderingContext2D,
  view : TownCanvasViewState,
  depth : Int32,
  width : Int32,
  height : Int32,
) -> Unit {
  let position = town_canvas_follow_position({ ..view, follow_enabled: true, })
  let position = match position {
    Some(_) => position
    None => street_spawn()
  }
  guard position is Some(p) else { return }
  if (p.0 + p.1).floor().to_int() != depth {
    return
  }
  let elapsed = view.player_motion
    .map(m => (golden_animation_seconds() - m.started_seconds).max(0.0))
    .unwrap_or(0.0)
  let moving = view.player_motion
    .map(m => elapsed * player_walk_speed < player_path_length(m.path))
    .unwrap_or(false)
  let next = view.player_motion
    .map(m => player_point_along(m.path, elapsed * player_walk_speed + 0.05))
    .unwrap_or(p)
  golden_draw_sprite_agent(
    context,
    golden_screen_x(p.0, p.1, width),
    golden_screen_y(p.0, p.1, height),
    golden_valley_camera_zoom().min(0.9).max(0.35),
    golden_valley_agent_sprite_path("resident", 0),
    next.0 - next.1 < p.0 - p.1,
    if moving && !golden_prefers_reduced_motion() {
      elapsed * 9.0
    } else {
      0.0
    },
    "#45634e",
    "你",
    "你",
    false,
    true,
  )
  street_visitor_readout(p.0, p.1, moving)
}

///|
extern "js" fn street_visitor_readout(
  x : Double,
  y : Double,
  moving : Bool,
) -> Unit =
  #| (x,y,moving) => {
  #|   const el = document.getElementById('street-walk-status');
  #|   if (!el) return;
  #|   el.dataset.position = `${x.toFixed(4)},${y.toFixed(4)}`;
  #|   const text = moving ? '行走中' : '点击道路走走';
  #|   if (el.textContent !== text) el.textContent = text;
  #| }
