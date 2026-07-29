///|
pub struct TownProjection {
  state_root : String
}

///|
pub fn town_projection(state_root : String) -> TownProjection {
  { state_root, }
}

///|
pub fn default_town_projection() -> TownProjection {
  town_projection(@storage.moontown_product_state_dir())
}

///|
fn object_field(fields : Map[String, Json], key : String) -> Map[String, Json] {
  match fields.get(key) {
    Some(Object(value)) => value
    _ => Map([])
  }
}

///|
fn array_field(fields : Map[String, Json], key : String) -> Array[Json] {
  match fields.get(key) {
    Some(Array(value)) => value
    _ => []
  }
}

///|
fn string_field(fields : Map[String, Json], key : String) -> String {
  match fields.get(key) {
    Some(String(value)) => value.trim().to_owned()
    _ => ""
  }
}

///|
fn safe_string_array(fields : Map[String, Json], key : String) -> Array[Json] {
  let values : Array[Json] = []
  for value in array_field(fields, key) {
    if value is String(text) {
      values.push(text.to_json())
    }
  }
  values
}

///|
fn public_book(value : Json) -> Json? {
  guard value is Object(fields) else { return None }
  let id = string_field(fields, "id")
  if id.is_empty() {
    return None
  }
  Some({
    "id": id,
    "name": string_field(fields, "name"),
    "purpose": string_field(fields, "purpose"),
    "memoryScope": string_field(fields, "memory_scope"),
    "tags": Json::array(safe_string_array(fields, "tags")),
  })
}

///|
fn public_building(value : Json) -> Json? {
  guard value is Object(fields) else { return None }
  let id = string_field(fields, "id")
  if id.is_empty() {
    return None
  }
  Some({
    "id": id,
    "name": string_field(fields, "name"),
    "summary": string_field(fields, "purpose"),
    "bookId": id,
    "visibility": "private",
    "status": "ready",
    "kind": "moontown-book",
  })
}

///|
fn public_placement(value : Json, index : Int) -> Json? {
  guard value is Object(fields) else { return None }
  let id = string_field(fields, "id")
  if id.is_empty() {
    return None
  }
  Some({
    "id": "placement-energy-valley-\{id}",
    "buildingId": id,
    "layerId": "layer-energy-valley",
    "x": 18 + index % 4 * 20,
    "y": 20 + index / 4 * 16 + index % 2 * 5,
    "regionId": "energy-valley",
    "pinned": true,
    "layoutSource": "procedural",
  })
}

///|
fn public_agent(value : Json) -> Json? {
  guard value is Object(fields) else { return None }
  let id = string_field(fields, "id")
  if id.is_empty() {
    return None
  }
  Some({
    "id": id,
    "name": string_field(fields, "name"),
    "role": string_field(fields, "role"),
    "status": string_field(fields, "status"),
    "buildingId": string_field(fields, "book_id"),
    "capabilities": Json::array(safe_string_array(fields, "capabilities")),
  })
}

///|
fn execution_by_task(executions : Array[Json]) -> Map[String, Json] {
  let by_task : Map[String, Json] = Map([])
  for execution in executions {
    guard execution is Object(fields) else { continue }
    let task_id = string_field(fields, "task_id")
    if !task_id.is_empty() {
      by_task[task_id] = execution
    }
  }
  by_task
}

///|
fn public_execution_summary(
  fields : Map[String, Json],
  status : String,
) -> String {
  let summary = string_field(fields, "summary")
  let lowered = summary.to_lower()
  let contains_internal_detail = summary.contains("\n") ||
    lowered.contains("/users/") ||
    lowered.contains("/home/") ||
    lowered.contains("\\users\\") ||
    lowered.contains("workspace=") ||
    lowered.contains("cwd=") ||
    lowered.contains("packet_path") ||
    lowered.contains("skill_paths") ||
    lowered.contains("command \"") ||
    lowered.contains("stderr:")
  if summary.is_empty() || contains_internal_detail {
    if status.is_empty() {
      "Work status is available in MoonTown."
    } else {
      "Work is \{status.to_lower()}."
    }
  } else if summary.length() > 240 {
    "Work is \{status.to_lower()}."
  } else {
    summary
  }
}

///|
fn public_run(task : Json, execution : Json?) -> Json? {
  guard task is Object(task_fields) else { return None }
  let id = string_field(task_fields, "id")
  if id.is_empty() {
    return None
  }
  let execution_fields = match execution {
    Some(Object(fields)) => fields
    _ => Map([])
  }
  let execution_status = string_field(execution_fields, "status")
  let status = if execution_status.is_empty() {
    string_field(task_fields, "status")
  } else {
    execution_status
  }
  Some({
    "id": id,
    "taskId": id,
    "buildingId": string_field(task_fields, "book_id"),
    "title": string_field(task_fields, "title"),
    "domain": string_field(task_fields, "domain"),
    "requiredRole": string_field(task_fields, "required_role"),
    "status": status,
    "summary": public_execution_summary(execution_fields, status),
    "requiresReview": match execution_fields.get("requires_review") {
      Some(True) => true
      _ => false
    },
    "resultDecision": string_field(execution_fields, "result_decision"),
  })
}

///|
fn empty_collection() -> Json {
  Json::array([])
}

///|
fn unavailable_snapshot() -> Json {
  {
    "schema": "moontown.miniapp.snapshot.v1",
    "mode": "unavailable",
    "viewer": "local-operator",
    "profile": { "id": "local-operator", "displayName": "MoonTown Operator" },
    "permissions": {
      "canCreateBuilding": false,
      "canPublishBuilding": false,
      "canModerate": false,
      "canReview": false,
    },
    "layout": {
      "kind": "energy-valley-procedural",
      "layerId": "layer-energy-valley",
      "version": 1,
    },
    "buildings": empty_collection(),
    "placements": empty_collection(),
    "books": empty_collection(),
    "bookMemories": empty_collection(),
    "threads": empty_collection(),
    "agents": empty_collection(),
    "runs": empty_collection(),
    "toolResults": empty_collection(),
    "reviews": empty_collection(),
    "messages": empty_collection(),
    "notifications": empty_collection(),
    "notificationStates": empty_collection(),
    "subscriptions": empty_collection(),
    "discoveryActions": empty_collection(),
    "moderationCases": empty_collection(),
    "shares": empty_collection(),
    "auditEvents": empty_collection(),
    "standingGoalCount": 0,
  }
}

///|
pub async fn TownProjection::miniapp_snapshot(self : TownProjection) -> Json {
  let root = @support.read_optional_json_file(self.state_root + "/town.json")
  guard root is Some(Object(root_fields)) else { return unavailable_snapshot() }
  let town = object_field(root_fields, "town")
  let books : Array[Json] = []
  let buildings : Array[Json] = []
  let placements : Array[Json] = []
  for index, value in array_field(town, "books") {
    match public_book(value) {
      Some(book) => books.push(book)
      None => ()
    }
    match public_building(value) {
      Some(building) => buildings.push(building)
      None => ()
    }
    match public_placement(value, index) {
      Some(placement) => placements.push(placement)
      None => ()
    }
  }
  let agents : Array[Json] = []
  for value in array_field(town, "workers") {
    match public_agent(value) {
      Some(agent) => agents.push(agent)
      None => ()
    }
  }
  let executions = execution_by_task(array_field(town, "executions"))
  let runs : Array[Json] = []
  for task in array_field(town, "tasks") {
    guard task is Object(task_fields) else { continue }
    match public_run(task, executions.get(string_field(task_fields, "id"))) {
      Some(run) => runs.push(run)
      None => ()
    }
  }
  let goals = @support.read_optional_json_file(
    self.state_root + "/standing-goals.json",
  )
  let standing_goal_count = match goals {
    Some(Array(values)) => values.length()
    _ => 0
  }
  let snapshot = unavailable_snapshot()
  guard snapshot is Object(fields) else { return snapshot }
  fields["mode"] = "live".to_json()
  fields["buildings"] = Json::array(buildings)
  fields["placements"] = Json::array(placements)
  fields["books"] = Json::array(books)
  fields["agents"] = Json::array(agents)
  fields["runs"] = Json::array(runs)
  fields["standingGoalCount"] = standing_goal_count.to_json()
  match @support.read_optional_json_file(self.state_root + "/daemon.json") {
    Some(Object(daemon)) =>
      match daemon.get("tick_sequence") {
        Some(Number(value, ..)) => fields["tick"] = value.to_json()
        _ => ()
      }
    _ => ()
  }
  Json::object(fields)
}
