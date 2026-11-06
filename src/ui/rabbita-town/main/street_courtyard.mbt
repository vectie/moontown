///|
/// Local, illustrative street furniture; not a merchant, account or runtime agent.
/// The terrace shares the registered center's geographic basis and touches only
/// its south forecourt. The accepted OSM graph is copied, never mutated.
fn street_courtyard_point(place : String) -> (Double, Double)? {
  guard town_landmark_find("center") is Some(center) else { return None }
  let (x, z) = match place {
    "cafe" => (-75.0, 125.0)
    "seat" => (-15.0, 140.0)
    "stories" => (55.0, 125.0)
    "events" => (100.0, 125.0)
    "interior" => (20.0, 96.0)
    _ => return None
  }
  let p = town_landmark_at(center, x, z)
  Some((p.x, p.y))
}

///|
fn street_courtyard_graph(
  graph : @landmark_routes.Graph,
) -> @landmark_routes.Graph {
  if graph.nodes.any(n => n.id == "courtyard-gate") {
    return graph
  }
  guard street_spawn() is Some(spawn) &&
    street_road_point(graph, spawn, 0.05) is Some(gate) else {
    return graph
  }
  let nodes = graph.nodes.copy()
  let edges : Array[@landmark_routes.Edge] = []
  nodes.push({ id: "courtyard-gate", x: gate.point.0, y: gate.point.1, })
  for i, edge in graph.edges {
    if i == gate.edge {
      edges.push({ a: edge.a, b: "courtyard-gate", bridge: edge.bridge, })
      edges.push({ a: "courtyard-gate", b: edge.b, bridge: edge.bridge, })
    } else {
      edges.push(edge)
    }
  }
  for place in ["cafe", "seat", "stories", "events", "interior"] {
    if street_courtyard_point(place) is Some(p) {
      nodes.push({ id: "courtyard-" + place, x: p.0, y: p.1, })
    }
  }
  for
    (a, b) in [
      ("gate", "seat"),
      ("seat", "cafe"),
      ("seat", "stories"),
      ("stories", "events"),
      ("stories", "interior"),
    ] {
    edges.push({ a: "courtyard-" + a, b: "courtyard-" + b, bridge: false, })
  }
  { nodes, edges, }
}

///|
fn street_visit_allowed(model : Model) -> Bool {
  model.street_living_room &&
  model.town_spatial_layer is Outdoor &&
  !model.neighborhood.open &&
  !model.energy_request_open &&
  model.dashboard_section is None &&
  !model.imported_outputs.open
}

///|
fn street_visit_begin(
  dispatch : Dispatch[Msg],
  model : Model,
  place : String,
) -> (Cmd, Model) {
  guard street_visit_allowed(model) else { return model_only_update(model) }
  if place == "seat" && model.street_seated {
    return model_only_update({
      ..model,
      street_seated: false,
      street_visit: "",
      street_visit_generation: model.street_visit_generation + 1,
    })
  }
  guard street_courtyard_point(place) is Some(goal) &&
    street_position(model) is Some(start) else {
    return model_only_update(model)
  }
  let near = (start.0 - goal.0).abs() + (start.1 - goal.1).abs() < 0.08
  let next = if near { model } else { street_walk_to(model, goal) }
  if !near && !next.life_toast.is_empty() {
    return model_only_update(next)
  }
  let generation = next.street_visit_generation + 1
  let next = {
    ..next,
    street_visit: place,
    street_visit_generation: generation,
    street_seated: false,
    street_overview: false,
  }
  let seconds = if near || golden_prefers_reduced_motion() {
    0.0
  } else {
    next.street_motion
    .map(m => player_path_length(m.path) / player_walk_speed)
    .unwrap_or(0.0)
  }
  let command = @cmd.custom_cmd(scheduler => {
    street_after_walk((seconds * 1000.0 + 40.0).to_int(), () => {
      scheduler.add(dispatch(StreetVisitArrived(generation)))
    })
  })
  (command, next)
}

///|
fn street_visit_arrive(
  dispatch : Dispatch[Msg],
  model : Model,
  generation : Int32,
) -> (Cmd, Model) {
  guard generation == model.street_visit_generation &&
    street_visit_allowed(model) &&
    !model.street_visit.is_empty() else {
    return model_only_update(model)
  }
  let place = model.street_visit
  guard street_courtyard_point(place) is Some(goal) &&
    street_position(model) is Some(p) &&
    (p.0 - goal.0).abs() + (p.1 - goal.1).abs() < 0.1 else {
    return model_only_update(model)
  }
  let memories = model.street_memories.copy()
  if !memories.contains(place) {
    memories.push(place)
  }
  let next = {
    ..model,
    street_visit: "",
    street_seated: place == "seat",
    street_memories: memories,
  }
  if place == "stories" || place == "events" {
    let id = street_featured_item(
        next.neighborhood,
        place == "stories",
        browser_now_ms(),
      )
      .map(item => neighborhood_text(item, "id"))
      .unwrap_or("")
    update(dispatch, OpenStreetContent(place, id), next)
  } else if place == "interior" {
    update(dispatch, OpenReferenceInterior, next)
  } else {
    model_only_update(next)
  }
}

///|
extern "js" fn street_after_walk(ms : Int32, callback : () -> Unit) -> Unit =
  #| (ms, callback) => setTimeout(callback, Math.max(0, ms))

///|
extern "js" fn street_courtyard_state(
  seated : Bool,
  visit : String,
  memories : String,
) -> Unit =
  #| (seated,visit,memories)=>{const root=globalThis.document?.documentElement;if(!root)return;
  #| root.dataset.streetSeated=String(seated);root.dataset.streetVisit=visit;root.dataset.streetMemories=memories;}
