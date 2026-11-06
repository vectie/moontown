///|
/// Local stage life, not residents, accounts, work agents or business telemetry.
/// Plans only traverse the copied forecourt graph; no operational state enters
/// this model and no simulated actor is written back to the town snapshot.
priv struct StreetLifeLeg {
  path : Array[(Double, Double)]
  travel : Double
  pause : Double
  pose : String
}

///|
priv struct StreetLifePlan {
  sprite : Int32
  offset : Double
  legs : Array[StreetLifeLeg]
  period : Double
}

///|
priv struct StreetLifeActor {
  sprite : Int32
  point : (Double, Double)
  facing : (Double, Double)
  pose : String
  phase : Double
  attentive : Bool
}

///|
priv struct StreetLifeClock {
  mut last : Double
  mut elapsed : Double
}

///|
let street_life_clock : StreetLifeClock = { last: -1, elapsed: 0, }

///|
let street_life_plans : Array[StreetLifePlan] = []

///|
let street_life_plan_key : Ref[String] = Ref::new("")

///|
fn StreetLifeClock::advance(
  self : StreetLifeClock,
  now : Double,
  active : Bool,
) -> Double {
  if active && self.last >= 0 {
    // No time-lapse teleport after a hidden tab, indoor visit or stalled frame.
    self.elapsed += (now - self.last).max(0).min(0.12)
  }
  self.last = now
  self.elapsed
}

///|
fn street_life_spot(place : String) -> (Double, Double)? {
  let local = match place {
    "chat-a" => Some((-48.0, 139.0))
    "chat-b" => Some((-35.0, 145.0))
    "reader" => Some((95.0, 147.0))
    "coffee-a" => Some((-72.0, 136.0))
    "coffee-b" => Some((-60.0, 137.0))
    "browse-a" => Some((42.0, 139.0))
    "browse-b" => Some((78.0, 137.0))
    "arrival-a" => Some((20.0, 109.0))
    "arrival-b" => Some((35.0, 107.0))
    "arrival-c" => Some((50.0, 105.0))
    "lane-west" => Some((-72.0, 155.0))
    "lane-middle" => Some((5.0, 155.0))
    "lane-east" => Some((65.0, 155.0))
    _ => None
  }
  match local {
    Some((x, y)) =>
      town_landmark_find("center").map(l => {
        let p = town_landmark_at(l, x, y)
        (p.x, p.y)
      })
    None => street_courtyard_point(place)
  }
}

///|
fn street_life_graph(graph : @landmark_routes.Graph) -> @landmark_routes.Graph {
  let nodes = graph.nodes.copy()
  let edges = graph.edges.copy()
  // The prop-free front of the terrace forms a private walking aisle. Do not
  // route scenery through the player's interaction targets (bench/table/door).
  let links = [
    ("lane-middle", "lane-west"),
    ("lane-east", "lane-middle"),
    ("chat-a", "lane-west"),
    ("chat-b", "lane-middle"),
    ("reader", "lane-east"),
    ("coffee-a", "lane-west"),
    ("coffee-b", "lane-west"),
    ("browse-a", "lane-east"),
    ("browse-b", "lane-east"),
    ("arrival-a", "lane-middle"),
    ("arrival-b", "lane-middle"),
    ("arrival-c", "lane-middle"),
  ]
  for place in ["lane-west", ..links.map(l => l.0)] {
    if street_life_spot(place) is Some(p) {
      nodes.push({ id: "scenery-" + place, x: p.0, y: p.1, })
    }
  }
  for (place, parent) in links {
    edges.push({ a: "scenery-" + parent, b: "scenery-" + place, bridge: false, })
  }
  { nodes, edges, }
}

///|
fn street_life_plan(
  graph : @landmark_routes.Graph,
  sprite : Int32,
  offset : Double,
  stops : Array[(String, Double, String)],
) -> StreetLifePlan? {
  if stops.is_empty() {
    return None
  }
  let legs : Array[StreetLifeLeg] = []
  let mut period = 0.0
  for i, (place, pause, pose) in stops {
    let next = stops[(i + 1) % stops.length()].0
    guard street_life_spot(place) is Some(a) &&
      street_life_spot(next) is Some(b) &&
      street_road_route(graph, a, b) is Some(path) else {
      return None
    }
    let travel = player_path_length(path) / 0.52
    legs.push({ path, travel, pause, pose, })
    period += travel + pause
  }
  if period <= 0 {
    None
  } else {
    Some({ sprite, offset, legs, period, })
  }
}

///|
fn street_life_sample(
  plan : StreetLifePlan,
  elapsed : Double,
  visitor : (Double, Double)?,
) -> StreetLifeActor {
  let elapsed = elapsed.max(0) + plan.offset
  let mut phase = elapsed - (elapsed / plan.period).floor() * plan.period
  for leg in plan.legs {
    if phase < leg.pause + leg.travel {
      let walking = phase >= leg.pause && leg.travel > 0
      let walked = (phase - leg.pause).max(0) * 0.52
      let p = player_point_along(leg.path, walked)
      let attentive = !walking &&
        visitor
        .map(v => {
          let dx = p.0 - v.0
          let dy = p.1 - v.1
          dx * dx + dy * dy < 1.2 * 1.2
        })
        .unwrap_or(false)
      let facing = if attentive {
        visitor.unwrap()
      } else {
        player_point_along(leg.path, if walking { walked + 0.06 } else { 0.12 })
      }
      return {
        sprite: plan.sprite,
        point: p,
        facing,
        pose: if walking {
          "walk"
        } else {
          leg.pose
        },
        phase,
        attentive,
      }
    }
    phase -= leg.pause + leg.travel
  }
  // Floating-point endpoint protection, at the same point as the next cycle.
  let p = plan.legs[0].path[0]
  {
    sprite: plan.sprite,
    point: p,
    facing: p,
    pose: plan.legs[0].pose,
    phase: 0,
    attentive: false,
  }
}

///|
fn street_life_prepare() -> Unit {
  guard town_landmark_graph.get("active") is Some(base) &&
    street_spawn() is Some(gate) else {
    return
  }
  // Routes depend on the authored terrace, never on an operational destination.
  let points = [
    "coffee-a", "coffee-b", "browse-a", "browse-b", "arrival-a", "arrival-b", "arrival-c",
    "chat-a", "chat-b", "reader", "lane-west", "lane-middle", "lane-east",
  ].filter_map(street_life_spot)
  let key = "\{gate.0}:\{gate.1}:" + points.to_json().stringify()
  if street_life_plan_key.val == key {
    return
  }
  street_life_plans.clear()
  let graph = street_life_graph(base)
  let plans = [
    street_life_plan(graph, 8, 12, [
      ("coffee-a", 11, "coffee"),
      ("chat-a", 24, "chat"),
      ("arrival-a", 9, "wait"),
    ]),
    street_life_plan(graph, 19, 0, [
      ("chat-b", 34, "chat"),
      ("browse-b", 20, "read"),
      ("arrival-b", 9, "wait"),
    ]),
    street_life_plan(graph, 34, 5, [
      ("browse-a", 20, "read"),
      ("coffee-b", 18, "coffee"),
      ("arrival-c", 16, "wait"),
    ]),
    street_life_plan(graph, 47, 0, [("reader", 240, "rest")]),
  ]
  for plan in plans {
    if plan is Some(p) {
      street_life_plans.push(p)
    }
  }
  // Retry when the accepted navigation graph is not ready yet.
  if street_life_plans.length() == 4 {
    street_life_plan_key.val = key
  }
}

///|
fn street_life_frame(
  visitor : (Double, Double)?,
  w : Int32,
  h : Int32,
) -> Array[StreetLifeActor] {
  guard street_courtyard_point("seat") is Some(center) else { return [] }
  let sx = golden_screen_x(center.0, center.1, w)
  let sy = golden_screen_y(center.0, center.1, h)
  let radius = golden_valley_camera_zoom() * 180
  let visible = sx > -radius &&
    sx < w.to_double() + radius &&
    sy > -radius &&
    sy < h.to_double() + radius
  let active = street_life_visible() && visible
  let time = street_life_clock.advance(
    browser_now_ms() / 1000,
    active && !golden_prefers_reduced_motion(),
  )
  // Reading a panel freezes the scene; it must not make the people vanish.
  if !visible || !street_life_scene_visible() {
    street_life_readout("[]")
    return []
  }
  street_life_prepare()
  let actors = street_life_plans.map(p => street_life_sample(p, time, visitor))
  let result = actors.map(a => {
    if a.pose != "chat" {
      return a
    }
    let partner = actors.search_by(b => {
      b.sprite != a.sprite &&
      b.pose == "chat" &&
      (b.point.0 - a.point.0).abs() + (b.point.1 - a.point.1).abs() < 1.6
    })
    match partner {
      Some(i) =>
        { ..a, facing: if a.attentive { a.facing } else { actors[i].point }, }
      None => { ..a, pose: "wait", }
    }
  })
  street_life_readout(
    result
    .map(a => {
      let row : Json = {
        "id": "scenery-\{a.sprite}",
        "x": a.point.0.to_json(),
        "y": a.point.1.to_json(),
        "pose": a.pose.to_json(),
        "attentive": a.attentive.to_json(),
      }
      row
    })
    .to_json()
    .stringify(),
  )
  result
}

///|
extern "js" fn street_life_visible() -> Bool =
  #| ()=> !document.hidden && !globalThis.__moontownStudioOpen &&
  #| !globalThis.__moontownGoldenValleyCamera?.streetOverview &&
  #| !document.querySelector('[role="dialog"][aria-modal="true"],.neighborhood-panel')

///|
extern "js" fn street_life_scene_visible() -> Bool =
  #| ()=> !globalThis.__moontownStudioOpen && !globalThis.__moontownGoldenValleyCamera?.streetOverview

///|
extern "js" fn street_life_readout(raw : String) -> Unit =
  #| raw=>{const c=document.getElementById('energy-valley-canvas');if(c){c.dataset.streetLife=raw;c.dataset.streetLifeSource='decorative-local';}}
