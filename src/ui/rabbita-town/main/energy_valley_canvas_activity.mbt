///|
/// Keep the full knowledge loop visible when no evidence-linked worker is on
/// the road and alongside real runtime workers. Preview residents remain
/// visually distinct and never enter live task, agent, or completion counts.
fn energy_valley_knowledge_preview_visible(model : Model) -> Bool {
  let _ = model
  true
}

///|
fn golden_valley_path_direction_is_left(
  current : (Double, Double),
  next : (Double, Double),
) -> Bool {
  next.0 - next.1 < current.0 - current.1
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
  energy_valley_runtime_task_for_agent(state, agent)
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
    if golden_valley_nonempty_authored_id(building) == Some(identity) ||
      golden_valley_building_module_key(building) == identity ||
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
/// Pure wall-clock projection for route animation. Task timestamps describe
/// evidence freshness, not when this browser started displaying the journey.
fn golden_valley_runtime_agent_motion_seconds_at(
  state : EnergyValleyRuntimeState,
  agent : EnergyValleyRuntimeAgent,
  now_ms : Double,
) -> Double {
  match energy_valley_runtime_presence_clock_for_agent(state, agent) {
    Some(clock) => (now_ms - clock.started_at_ms).max(0.0) / 1000.0
    None => 0.0
  }
}

///|
fn golden_valley_runtime_agent_motion_seconds(
  state : EnergyValleyRuntimeState,
  agent : EnergyValleyRuntimeAgent,
) -> Double {
  if golden_prefers_reduced_motion() {
    1000000.0
  } else {
    golden_valley_runtime_agent_motion_seconds_at(
      state,
      agent,
      browser_now_ms(),
    )
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
