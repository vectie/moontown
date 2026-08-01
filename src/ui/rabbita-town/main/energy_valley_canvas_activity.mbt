///|
priv struct GoldenValleyPreviewMotion {
  x : Double
  y : Double
  facing_left : Bool
  activity_glyph : String
  activity_label : String
  activity_color : String
}

///|
/// Keep the full knowledge loop visible when no evidence-linked worker is on
/// the road. Preview residents remain visually distinct and never enter live
/// task, agent, or completion counts.
fn energy_valley_knowledge_preview_visible(model : Model) -> Bool {
  !energy_valley_runtime_can_claim_active_work(model.energy_valley_runtime) ||
  energy_valley_runtime_active_agents(model.energy_valley_runtime).is_empty()
}

///|
fn golden_valley_preview_activity(stage : Int) -> (String, String, String) {
  match stage {
    0 => ("⌕", "Researching", "#a5b4fc")
    1 => ("↔", "Discussing", "#c4b5fd")
    2 => ("✓", "Reviewing", "#fcd34d")
    3 => ("↺", "Revising", "#fb923c")
    _ => ("⇠", "Returning", "#7dd3fc")
  }
}

///|
fn golden_valley_path_direction_is_left(
  current : (Double, Double),
  next : (Double, Double),
) -> Bool {
  next.0 - next.1 < current.0 - current.1
}

///|
fn golden_valley_preview_motion(
  path : Array[(Double, Double)],
  elapsed_seconds : Double,
  speed : Double,
  phase_offset : Double,
  dwell_seconds : Double,
  agent_index : Int,
) -> GoldenValleyPreviewMotion? {
  if path.length() < 2 {
    return None
  }
  let route_distance = (path.length() - 1).to_double()
  let dwell_distance = dwell_seconds * speed
  let cycle_distance = route_distance * 2.0 + dwell_distance * 2.0
  let travelled = elapsed_seconds * speed + phase_offset
  let cycle_index = (travelled / cycle_distance).floor()
  let phase = travelled - cycle_index * cycle_distance
  let mut distance = 0.0
  let mut stage = 0
  let mut returning = false
  if phase < route_distance {
    distance = phase
    stage = 0
  } else if phase < route_distance + dwell_distance {
    distance = route_distance - 0.001
    let dwell_fraction = (phase - route_distance) / dwell_distance
    stage = (dwell_fraction * 4.0).floor().to_int()
    stage = (stage + agent_index) % 4
  } else if phase < route_distance * 2.0 + dwell_distance {
    distance = route_distance - (phase - route_distance - dwell_distance)
    if distance >= route_distance {
      distance = route_distance - 0.001
    }
    stage = 4
    returning = true
  } else {
    distance = 0.0
    stage = 4
  }
  match golden_valley_path_point(path, distance) {
    None => None
    Some(point) => {
      let direction_sample = if returning {
        let next_distance = if distance > 0.12 { distance - 0.12 } else { 0.0 }
        golden_valley_path_point(path, next_distance).unwrap_or(point)
      } else {
        let next_distance = if distance + 0.12 < route_distance {
          distance + 0.12
        } else {
          route_distance - 0.001
        }
        golden_valley_path_point(path, next_distance).unwrap_or(point)
      }
      let activity = golden_valley_preview_activity(stage)
      Some({
        x: point.0,
        y: point.1,
        facing_left: golden_valley_path_direction_is_left(
          point, direction_sample,
        ),
        activity_glyph: activity.0,
        activity_label: activity.1,
        activity_color: activity.2,
      })
    }
  }
}

///|
fn golden_valley_assignment_point(
  path : Array[(Double, Double)],
  elapsed_seconds : Double,
  speed : Double,
) -> (Double, Double)? {
  if path.is_empty() {
    return None
  }
  if path.length() == 1 {
    return Some(path[0])
  }
  let route_distance = (path.length() - 1).to_double()
  let travelled = if elapsed_seconds < 0.0 {
    0.0
  } else {
    elapsed_seconds * speed
  }
  if travelled >= route_distance {
    Some(path[path.length() - 1])
  } else {
    golden_valley_path_point(path, travelled)
  }
}

///|
fn golden_valley_assignment_faces_left(
  path : Array[(Double, Double)],
  elapsed_seconds : Double,
  speed : Double,
  point : (Double, Double),
) -> Bool {
  match golden_valley_assignment_point(path, elapsed_seconds + 0.12, speed) {
    Some(next) =>
      if next == point && path.length() >= 2 {
        golden_valley_path_direction_is_left(
          path[path.length() - 2],
          path[path.length() - 1],
        )
      } else {
        golden_valley_path_direction_is_left(point, next)
      }
    None => false
  }
}

///|
fn golden_valley_runtime_task_for_agent(
  state : EnergyValleyRuntimeState,
  agent : EnergyValleyRuntimeAgent,
) -> EnergyValleyRuntimeWorkItem? {
  match (state.projection, agent.workItemId) {
    (Some(projection), Some(work_item_id)) => {
      for task in projection.tasks {
        if task.id == work_item_id {
          return Some(task)
        }
      }
      None
    }
    _ => None
  }
}

///|
fn golden_valley_optional_nonempty(value : String?) -> String? {
  match value {
    Some(text) if !text.trim().is_empty() => Some(text)
    _ => None
  }
}

///|
fn golden_valley_building_for_identity(
  buildings : Array[GoldenValleyBuilding],
  identity : String,
) -> GoldenValleyBuilding? {
  for building in buildings {
    if golden_valley_building_module_key(building) == identity ||
      golden_valley_building_civic_id(building) == identity {
      return Some(building)
    }
  }
  None
}

///|
fn golden_valley_runtime_book_home(
  buildings : Array[GoldenValleyBuilding],
  book_id : String?,
) -> GoldenValleyBuilding? {
  match golden_valley_optional_nonempty(book_id) {
    None => None
    Some(id) =>
      match find_module_for_book(id) {
        None => None
        Some(civic) => golden_valley_building_for_identity(buildings, civic.id)
      }
  }
}

///|
fn golden_valley_runtime_agent_origin(
  state : EnergyValleyRuntimeState,
  buildings : Array[GoldenValleyBuilding],
  agent : EnergyValleyRuntimeAgent,
) -> GoldenValleyBuilding {
  let task = golden_valley_runtime_task_for_agent(state, agent)
  let explicit = match
    golden_valley_optional_nonempty(agent.originBuildingModuleKey) {
    Some(value) => Some(value)
    None =>
      match task {
        Some(value) =>
          golden_valley_optional_nonempty(value.originBuildingModuleKey)
        None => None
      }
  }
  match explicit {
    Some(identity) =>
      match golden_valley_building_for_identity(buildings, identity) {
        Some(building) => return building
        None => ()
      }
    None => ()
  }
  let book_id = match golden_valley_optional_nonempty(agent.bookId) {
    Some(value) => Some(value)
    None =>
      match task {
        Some(value) => golden_valley_optional_nonempty(value.bookId)
        None => None
      }
  }
  match golden_valley_runtime_book_home(buildings, book_id) {
    Some(building) => building
    None => buildings[0]
  }
}

///|
fn golden_valley_runtime_agent_destination(
  state : EnergyValleyRuntimeState,
  buildings : Array[GoldenValleyBuilding],
  agent : EnergyValleyRuntimeAgent,
) -> GoldenValleyBuilding? {
  let task = golden_valley_runtime_task_for_agent(state, agent)
  let destination = match
    golden_valley_optional_nonempty(agent.destinationBuildingModuleKey) {
    Some(value) => Some(value)
    None =>
      match task {
        Some(value) =>
          match
            golden_valley_optional_nonempty(value.destinationBuildingModuleKey) {
            Some(identity) => Some(identity)
            None => golden_valley_optional_nonempty(agent.buildingModuleKey)
          }
        None => golden_valley_optional_nonempty(agent.buildingModuleKey)
      }
  }
  match destination {
    Some(identity) =>
      match golden_valley_building_for_identity(buildings, identity) {
        Some(building) => Some(building)
        None =>
          match task {
            Some(value) =>
              golden_valley_building_for_identity(
                buildings,
                value.buildingModuleKey,
              )
            None => None
          }
      }
    None => None
  }
}

///|
fn golden_valley_runtime_agent_motion_seconds(
  state : EnergyValleyRuntimeState,
  agent : EnergyValleyRuntimeAgent,
) -> Double {
  if golden_prefers_reduced_motion() {
    return 1000000.0
  }
  match golden_valley_runtime_task_for_agent(state, agent) {
    Some(task) =>
      match task.updatedAt {
        Some(timestamp) => {
          let observed = browser_timestamp_ms(timestamp)
          if observed >= 0.0 {
            return (browser_now_ms() - observed) / 1000.0
          }
        }
        None => ()
      }
    None => ()
  }
  if state.motion_started_at_ms < 0.0 {
    0.0
  } else {
    (browser_now_ms() - state.motion_started_at_ms) / 1000.0
  }
}

///|
fn golden_valley_runtime_agent_activity(
  state : EnergyValleyRuntimeState,
  agent : EnergyValleyRuntimeAgent,
) -> (String, String) {
  let task = golden_valley_runtime_task_for_agent(state, agent)
  let kind = match golden_valley_optional_nonempty(agent.activityKind) {
    Some(value) => value
    None =>
      match task {
        Some(value) => value.activityKind.unwrap_or(value.status).to_lower()
        None => agent.status.to_lower()
      }
  }
  let label = match golden_valley_optional_nonempty(agent.activityLabel) {
    Some(value) => value
    None =>
      match task {
        Some(value) => value.activityLabel.unwrap_or(kind)
        None => kind
      }
  }
  let glyph = match kind {
    "researching" | "discovery" => "⌕"
    "discussing" | "collaboration" => "↔"
    "reviewing" | "review" | "waiting_review" | "waiting" => "✓"
    "revising" | "revision_requested" => "↺"
    "returning" => "⇠"
    "delivering" | "completed" => "⇢"
    "blocked" | "failed" => "!"
    _ => "•"
  }
  (glyph, label)
}
