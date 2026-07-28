///|
let energy_valley_runtime_schema = "moontown.energy-valley.runtime.v1"

///|
let missing_durable_observation = "1970-01-01T00:00:00.000Z"

///|
async fn read_optional_json(path : String) -> Json? {
  let text = @support.read_text_or_empty(path)
  if text.trim().is_empty() {
    return None
  }
  let value = @json.parse(text) catch { _ => return None }
  Some(value)
}

///|
fn object_fields(value : Json?) -> Map[String, Json] {
  match value {
    Some(Object(fields)) => fields
    _ => Map([])
  }
}

///|
fn array_field(fields : Map[String, Json], key : String) -> Array[Json] {
  match fields.get(key) {
    Some(Array(items)) => items
    _ => []
  }
}

///|
fn enum_key(value : String) -> String {
  let builder = StringBuilder::new()
  for char in value.to_lower() {
    if (char >= 'a' && char <= 'z') || (char >= '0' && char <= '9') {
      builder.write_char(char)
    }
  }
  builder.to_string()
}

///|
fn json_uint64_field(fields : Map[String, Json], key : String) -> UInt64? {
  match fields.get(key) {
    Some(Number(value, ..)) if value > 0.0 => Some(value.to_uint64())
    Some(String(value)) => {
      let parsed = @string.parse_uint64(value.trim()) catch { _ => return None }
      if parsed > 0UL {
        Some(parsed)
      } else {
        None
      }
    }
    _ => None
  }
}

///|
fn durable_observed_at(runtime : Json?) -> String {
  let fields = object_fields(runtime)
  let status = enum_key(json_string_field(fields, "status"))
  let heartbeat = if status == "running" ||
    status == "starting" ||
    status == "supervising" {
    json_uint64_field(fields, "last_heartbeat_ms")
  } else {
    None
  }
  let finished = json_uint64_field(fields, "last_tick_finished_ms")
  let timestamp = match (heartbeat, finished) {
    (Some(left), Some(right)) => Some(if left > right { left } else { right })
    (Some(value), None) | (None, Some(value)) => Some(value)
    _ => None
  }
  match timestamp {
    Some(value) => iso_timestamp(value)
    None => missing_durable_observation
  }
}

///|
fn building_module_key(book_id : String) -> String {
  if book_id.is_empty() {
    "unlocated"
  } else if book_id.has_prefix("research-") {
    match book_id {
      "research-embodied-robotics" => "research-embodied-robotics"
      "research-ai-agents" => "research-ai-agents"
      "research-opc" => "research-opc"
      "research-how-llms-are-trained-in-very-detail" => "research-llm-training"
      "research-ai-hardware" => "research-ai-hardware"
      id if id.contains("robot") => "research-embodied-robotics"
      id if id.contains("opc") => "research-opc"
      id if id.contains("hardware") => "research-ai-hardware"
      id if id.contains("llm") || id.contains("training") =>
        "research-llm-training"
      _ => "research-ai-agents"
    }
  } else {
    match book_id {
      "coding" | "wenyu-ai-garden" => "ai-garden"
      "finance" | "wenyu-valley-market" => "valley-market"
      "wenyu-town-shell" => "town-shell"
      "wenyu-resident-twins" => "resident-twins"
      "wenyu-policy-hall" => "policy-hall"
      "wenyu-contest-express" => "contest-express"
      "wenyu-social-square" => "social-square"
      "wenyu-talent-avenue" => "talent-avenue"
      "wenyu-vitality-dashboard" => "vitality-tower"
      "wenyu-broadcast-tower" => "story-radar"
      // The current Energy Valley layout has no standalone bridge building.
      // Keep bridge work visible at the civic hub instead of leaving it
      // unlocated.
      "wenyu-physical-bridge" => "town-shell"
      "vitality-dashboard" => "vitality-tower"
      "broadcast-tower" => "story-radar"
      _ => book_id
    }
  }
}

///|
fn worker_role(role : String) -> String {
  match enum_key(role) {
    "mayor" => "mayor"
    "keeper" | "memorykeeper" => "keeper"
    _ => "worker"
  }
}

///|
fn worker_status(status : String) -> String {
  match enum_key(status) {
    "running" => "running"
    "waiting" => "waiting"
    "blocked" => "blocked"
    "offline" => "offline"
    _ => "idle"
  }
}

///|
fn execution_outcome_status(fields : Map[String, Json]) -> String? {
  let decision = enum_key(json_string_field(fields, "result_decision"))
  if decision.contains("deferred") ||
    decision.contains("transientinfrastructure") {
    return Some("blocked")
  }
  if decision == "failed" || decision == "failure" || decision == "rejected" {
    return Some("failed")
  }
  let summary = json_string_field(fields, "summary").to_lower()
  if summary.contains("deferred-transient-infrastructure") {
    Some("blocked")
  } else if summary.contains("planning failed") {
    Some("failed")
  } else {
    None
  }
}

///|
fn town_task_status(
  task : Map[String, Json],
  execution : Map[String, Json],
) -> String {
  match execution_outcome_status(execution) {
    Some(status) => return status
    None => ()
  }
  match enum_key(json_string_field(execution, "status")) {
    "packetready" | "proposalimported" | "runconfirmed" => return "assigned"
    "running" | "awaitingpersistence" => return "running"
    "reviewqueued" => return "waiting_review"
    "completed" => return "completed"
    "stale" => return "blocked"
    "failed" => return "failed"
    _ => ()
  }
  match enum_key(json_string_field(task, "status")) {
    "assigned" => "assigned"
    "running" => "running"
    "blocked" => "blocked"
    "done" | "completed" => "completed"
    "failed" => "failed"
    _ => "queued"
  }
}

///|
fn watcher_task_status(watcher : Map[String, Json]) -> String? {
  if watcher.length() == 0 {
    return None
  }
  match enum_key(json_string_field(watcher, "decision")) {
    "needsreview" => Some("waiting_review")
    "update" | "nochange" => Some("completed")
    "running" | "started" => Some("running")
    "queued" | "pending" => Some("assigned")
    "deferred" => Some("blocked")
    "failed" => Some("failed")
    // A durable watcher row must never inherit an older successful execution
    // when its current decision is missing or unrecognized.
    _ => Some("blocked")
  }
}

///|
async fn latest_watchers_by_task() -> Map[String, Json] {
  let watchers : Map[String, Json] = Map([])
  let directory = state_root() + "/watchers"
  guard @fs.exists(directory) && @fs.kind(directory) is Directory else {
    return watchers
  }
  let dir = @fs.opendir(directory)
  defer dir.close()
  for name in dir.read_all() {
    if !name.has_suffix(".jsonl") {
      continue
    }
    let text = @support.read_text_or_empty(directory + "/" + name)
    for raw in text.split("\n") {
      let line = raw.trim().to_owned()
      if line.is_empty() {
        continue
      }
      let value = @json.parse(line) catch { _ => continue }
      guard value is Object(fields) else { continue }
      let task_id = json_string_field(fields, "task_id")
      if !task_id.is_empty() {
        // Watcher ledgers are append-only and one ledger owns each task, so the
        // last durable row is the authoritative decision for that task.
        watchers[task_id] = value
      }
    }
  }
  watchers
}

///|
fn execution_tick(fields : Map[String, Json]) -> Int {
  json_int_field(fields, "heartbeat_tick", 0, 0, 2147483647)
}

///|
fn latest_executions(items : Array[Json]) -> Map[String, Json] {
  let latest : Map[String, Json] = Map([])
  let ticks : Map[String, Int] = Map([])
  for item in items {
    guard item is Object(fields) else { continue }
    let task_id = json_string_field(fields, "task_id")
    if task_id.is_empty() {
      continue
    }
    let tick = execution_tick(fields)
    match ticks.get(task_id) {
      Some(previous) if previous > tick => ()
      _ => {
        ticks[task_id] = tick
        latest[task_id] = item
      }
    }
  }
  latest
}

///|
fn string_artifacts(fields : Map[String, Json]) -> Array[Json] {
  let artifacts : Array[Json] = []
  for value in array_field(fields, "artifacts") {
    guard value is String(path) && !path.trim().is_empty() else { continue }
    artifacts.push(path.trim().to_owned().to_json())
  }
  let packet = json_string_field(fields, "packet_path")
  if !packet.is_empty() {
    artifacts.push(packet.to_json())
  }
  artifacts
}

///|
fn optional_item_field(
  fields : Map[String, Json],
  key : String,
  value : String,
) -> Unit {
  if !value.is_empty() {
    fields[key] = value.to_json()
  }
}

///|
fn concise_summary(value : String) -> String {
  let trimmed = value.trim().to_owned()
  let builder = StringBuilder::new()
  let mut count = 0
  for char in trimmed {
    if count >= 1200 {
      builder.write_string(
        "\n… Open the durable result or log for full detail.",
      )
      break
    }
    builder.write_char(char)
    count += 1
  }
  builder.to_string()
}

///|
fn watcher_detail_value(watcher : Map[String, Json], key : String) -> String? {
  match watcher.get(key) {
    Some(String(value)) if !value.trim().is_empty() =>
      return Some(value.trim().to_owned())
    Some(Number(value, ..)) => return Some(value.to_string())
    Some(True) => return Some("true")
    Some(False) => return Some("false")
    _ => ()
  }
  let prefix = key.to_lower() + ":"
  let detail = json_string_field(watcher, "detail")
  for raw in detail.split("\n") {
    let line = raw.trim().to_owned()
    let lowered = line.to_lower()
    if lowered.has_prefix(prefix) {
      return Some(line[prefix.length():].trim().to_owned())
    }
  }
  None
}

///|
fn watcher_non_negative_int(watcher : Map[String, Json], key : String) -> Int? {
  guard watcher_detail_value(watcher, key) is Some(value) else { return None }
  let parsed = @string.parse_int(value) catch { _ => return None }
  if parsed >= 0 {
    Some(parsed)
  } else {
    None
  }
}

///|
fn town_work_item(
  task_value : Json,
  execution_value : Json?,
  workers : Map[String, Json],
  watcher_value : Json?,
  request_value : Json?,
) -> Json? {
  guard task_value is Object(task) else { return None }
  let execution = object_fields(execution_value)
  let watcher = object_fields(watcher_value)
  let request = object_fields(request_value)
  let id = {
    let task_id = json_string_field(task, "id")
    if task_id.is_empty() {
      json_string_field(execution, "task_id")
    } else {
      task_id
    }
  }
  if id.is_empty() {
    return None
  }
  let book_id = {
    let value = json_string_field(task, "book_id")
    if value.is_empty() {
      json_string_field(execution, "book_id")
    } else {
      value
    }
  }
  let agent_id = json_string_field(execution, "assigned_worker_id")
  let worker = object_fields(workers.get(agent_id))
  let watcher_run_id = json_string_field(watcher, "run_id")
  let execution_run_id = json_string_field(execution, "run_id")
  let title = {
    let value = json_string_field(task, "title")
    if value.is_empty() {
      id
    } else {
      value
    }
  }
  let fields : Map[String, Json] = {
    "id": id,
    "title": title,
    "status": watcher_task_status(watcher).unwrap_or(
      town_task_status(task, execution),
    ),
    "buildingModuleKey": building_module_key(book_id),
    "artifacts": Json::array(
      if !watcher_run_id.is_empty() && watcher_run_id != execution_run_id {
        []
      } else {
        string_artifacts(execution)
      },
    ),
    "source": if watcher.length() > 0 {
      "watcher"
    } else {
      "town-runtime"
    },
  }
  optional_item_field(fields, "bookId", book_id)
  optional_item_field(fields, "agentId", agent_id)
  optional_item_field(fields, "agentName", json_string_field(worker, "name"))
  let role = {
    let value = json_string_field(worker, "role")
    if value.is_empty() {
      json_string_field(task, "required_role")
    } else {
      value
    }
  }
  if !role.is_empty() {
    fields["role"] = worker_role(role).to_json()
  }
  optional_item_field(
    fields,
    "runId",
    if watcher_run_id.is_empty() {
      execution_run_id
    } else {
      watcher_run_id
    },
  )
  let summary = {
    let watcher_detail = json_string_field(watcher, "detail")
    if !watcher_detail.is_empty() {
      watcher_detail
    } else {
      let value = json_string_field(execution, "summary")
      if value.is_empty() {
        json_string_field(task, "prompt")
      } else {
        value
      }
    }
  }
  optional_item_field(fields, "summary", concise_summary(summary))
  let request_id = {
    let value = json_string_field(execution, "request_id")
    if value.is_empty() {
      let task_request = json_string_field(task, "request_id")
      if task_request.is_empty() {
        json_string_field(request, "id")
      } else {
        task_request
      }
    } else {
      value
    }
  }
  optional_item_field(fields, "requestId", request_id)
  let standing_goal_id = {
    let from_watcher = json_string_field(watcher, "goal_id")
    if !from_watcher.is_empty() {
      from_watcher
    } else {
      let from_execution = json_string_field(execution, "standing_goal_id")
      if !from_execution.is_empty() {
        from_execution
      } else {
        let goal = json_string_field(execution, "goal_id")
        if !goal.is_empty() {
          goal
        } else {
          let task_goal = json_string_field(task, "standing_goal_id")
          if task_goal.is_empty() {
            json_string_field(task, "goal_id")
          } else {
            task_goal
          }
        }
      }
    }
  }
  optional_item_field(fields, "standingGoalId", standing_goal_id)
  let correlation_id = {
    let value = json_string_field(execution, "correlation_id")
    if value.is_empty() {
      json_string_field(task, "correlation_id")
    } else {
      value
    }
  }
  if !request_id.is_empty() {
    fields["correlationId"] = request_id.to_json()
  } else if !correlation_id.is_empty() {
    fields["correlationId"] = correlation_id.to_json()
  } else if !standing_goal_id.is_empty() {
    fields["correlationId"] = ("standing-goal:" + standing_goal_id).to_json()
  }
  if watcher.length() > 0 {
    let progress : Map[String, Json] = Map([])
    let metrics = [
      ("checked_sources_count", "checkedSources"),
      ("new_sources_found", "newSources"),
      ("accepted_facts_count", "acceptedFacts"),
      ("rejected_facts_count", "rejectedFacts"),
      ("wiki_pages_changed_count", "pagesChanged"),
    ]
    for metric in metrics {
      let (source, target) = metric
      match watcher_non_negative_int(watcher, source) {
        Some(value) => progress[target] = value.to_json()
        None => ()
      }
    }
    if !progress.contains("newSources") {
      match watcher_non_negative_int(watcher, "new_source_count") {
        Some(value) => progress["newSources"] = value.to_json()
        None => ()
      }
    }
    let changed = enum_key(
      watcher_detail_value(watcher, "book_changed").unwrap_or(""),
    )
    if changed == "yes" || changed == "true" || changed == "1" {
      progress["bookChanged"] = true.to_json()
    } else if changed == "no" || changed == "false" || changed == "0" {
      progress["bookChanged"] = false.to_json()
    } else {
      let decision = enum_key(json_string_field(watcher, "decision"))
      if decision == "update" || decision == "needsreview" {
        progress["bookChanged"] = true.to_json()
      } else if decision == "nochange" || decision == "failed" {
        progress["bookChanged"] = false.to_json()
      }
    }
    if progress.length() > 0 {
      fields["progress"] = Json::object(progress)
    }
  }
  Some(Json::object(fields))
}

///|
fn operator_work_item(value : Json) -> Json? {
  guard value is Object(request) else { return None }
  let id = json_string_field(request, "id")
  if id.is_empty() {
    return None
  }
  let status = match enum_key(json_string_field(request, "status")) {
    "failed" | "rejected" => "failed"
    "completed" | "done" => "completed"
    "blocked" => "blocked"
    _ => "queued"
  }
  let title = {
    let value = json_string_field(request, "title")
    if value.is_empty() {
      id
    } else {
      value
    }
  }
  let book_id = json_string_field(request, "target_book_id")
  let fields : Map[String, Json] = {
    "id": id,
    "title": title,
    "status": status,
    "buildingModuleKey": building_module_key(book_id),
    "requestId": id,
    "correlationId": id,
    "artifacts": Json::array([]),
    "source": "operator-request",
  }
  optional_item_field(fields, "bookId", book_id)
  optional_item_field(fields, "summary", json_string_field(request, "prompt"))
  optional_item_field(
    fields,
    "updatedAt",
    json_string_field(request, "created_at"),
  )
  optional_item_field(
    fields,
    "standingGoalId",
    json_string_field(request, "standing_goal_id"),
  )
  Some(Json::object(fields))
}

///|
fn active_status(status : String) -> Bool {
  status == "assigned" ||
  status == "running" ||
  status == "waiting_review" ||
  status == "blocked"
}

///|
async fn attach_result_links(tasks : Array[Json]) -> Unit {
  for task in tasks {
    guard task is Object(fields) else { continue }
    let status = json_string_field(fields, "status")
    if status != "completed" && status != "waiting_review" {
      continue
    }
    let book_id = json_string_field(fields, "bookId")
    if book_id.is_empty() || safe_slug(book_id) != book_id {
      continue
    }
    let root = books_root() + "/" + book_id
    let links : Array[Json] = []
    let candidates : Array[(String, String, String)] = [
      ("Current book evidence", "book/synthesis/evidence.html", "evidence"),
      ("Current book review", "book/reviews/pending.html", "review"),
      ("Current book site", "book/site/generated/index.html", "site"),
      ("Current book index", "book/index.html", "site"),
    ]
    let mut found_site = false
    for candidate in candidates {
      let (label, relative, kind) = candidate
      if kind == "site" && found_site {
        continue
      }
      let path = root + "/" + relative
      if @fs.exists(path) && @fs.kind(path) is Regular {
        links.push({
          "label": label,
          "url": "/book-output/" + book_id + "/" + relative,
          "kind": kind,
        })
        if kind == "site" {
          found_site = true
        }
      }
    }
    if !links.is_empty() {
      fields["resultLinks"] = Json::array(links)
    }
  }
}

///|
fn collaboration_participant_status(status : String) -> String {
  match enum_key(status) {
    "running" => "running"
    "queued" => "queued"
    "pending" => "assigned"
    "succeeded" | "completed" => "completed"
    "failed" | "cancelled" => "failed"
    _ => "unknown"
  }
}

///|
async fn collaboration_for_run(run_id : String) -> Json? {
  if run_id.is_empty() || safe_slug(run_id) != run_id {
    return None
  }
  let directory = @storage.moontown_active_workspace_root() +
    "/.moonsuite/products/moonclaw/jobs/runs/" +
    run_id +
    "/steps"
  guard @fs.exists(directory) && @fs.kind(directory) is Directory else {
    return None
  }
  let dir = @fs.opendir(directory)
  defer dir.close()
  let participants : Array[Json] = []
  let participants_by_family : Map[String, Json] = Map([])
  let discovered_families : Array[String] = []
  let families : Map[String, Bool] = Map([])
  for name in dir.read_all() {
    if !name.has_suffix(".json") {
      continue
    }
    let step = read_optional_json(directory + "/" + name)
    let fields = object_fields(step)
    let family = json_string_field(fields, "step_id")
    if family.is_empty() {
      continue
    }
    if participants_by_family.contains(family) {
      continue
    }
    families[family] = true
    discovered_families.push(family)
    participants_by_family[family] = {
      "runId": run_id + ":" + family,
      "parentRunId": run_id,
      "family": family,
      "status": collaboration_participant_status(
        json_string_field(fields, "status"),
      ),
      "artifacts": Json::array([]),
    }
  }
  let research_order = [
    "research_bootstrap_sources", "research_bootstrap_source_expansion", "research_bootstrap_report",
    "research_bootstrap_quality_repair",
  ]
  let emitted : Map[String, Bool] = Map([])
  for family in research_order {
    match participants_by_family.get(family) {
      Some(participant) => {
        participants.push(participant)
        emitted[family] = true
      }
      None => ()
    }
  }
  for family in discovered_families {
    if emitted.contains(family) {
      continue
    }
    match participants_by_family.get(family) {
      Some(participant) => participants.push(participant)
      None => ()
    }
  }
  if participants.length() < 2 {
    return None
  }
  let research_bootstrap = research_order.all(fn(family) {
    families.contains(family)
  })
  Some({
    "mode": if research_bootstrap {
      "sequential"
    } else {
      "unknown"
    },
    "participants": Json::array(participants),
  })
}

///|
async fn attach_collaboration(tasks : Array[Json]) -> Unit {
  let by_run : Map[String, Json?] = Map([])
  for task in tasks {
    guard task is Object(fields) else { continue }
    let run_id = json_string_field(fields, "runId")
    if run_id.is_empty() {
      continue
    }
    let collaboration = match by_run.get(run_id) {
      Some(value) => value
      None => {
        let value = collaboration_for_run(run_id)
        by_run[run_id] = value
        value
      }
    }
    match collaboration {
      Some(value) => fields["collaboration"] = value
      None => ()
    }
  }
}

///|
fn collaborator_agent_status(status : String) -> String {
  match status {
    "running" | "assigned" => "running"
    "failed" | "blocked" => "blocked"
    _ => "idle"
  }
}

///|
fn projected_collaboration_agents(tasks : Array[Json]) -> Array[Json] {
  let agents : Array[Json] = []
  let seen : Map[String, Bool] = Map([])
  for task in tasks {
    guard task is Object(task_fields) else { continue }
    guard task_fields.get("collaboration") is Some(Object(collaboration)) else {
      continue
    }
    for participant in array_field(collaboration, "participants") {
      guard participant is Object(fields) else { continue }
      let run_id = json_string_field(fields, "runId")
      let family = json_string_field(fields, "family")
      if run_id.is_empty() || family.is_empty() || seen.contains(run_id) {
        continue
      }
      seen[run_id] = true
      agents.push({
        "id": "moonclaw-" + run_id,
        "name": family.replace(old="_", new=" "),
        "role": "worker",
        "status": collaborator_agent_status(json_string_field(fields, "status")),
        "buildingModuleKey": json_string_field(task_fields, "buildingModuleKey"),
        "workItemId": json_string_field(task_fields, "id"),
        "runId": run_id,
      })
    }
  }
  agents
}

///|
fn projected_agents(
  worker_values : Array[Json],
  tasks : Array[Json],
) -> Array[Json] {
  let active_by_agent : Map[String, Json] = Map([])
  for task in tasks {
    guard task is Object(fields) else { continue }
    let agent_id = json_string_field(fields, "agentId")
    let status = json_string_field(fields, "status")
    if !agent_id.is_empty() && active_status(status) {
      active_by_agent[agent_id] = task
    }
  }
  let agents : Array[Json] = []
  for worker_value in worker_values {
    guard worker_value is Object(worker) else { continue }
    let id = json_string_field(worker, "id")
    let name = json_string_field(worker, "name")
    if id.is_empty() || name.is_empty() {
      continue
    }
    let work = object_fields(active_by_agent.get(id))
    let work_status = json_string_field(work, "status")
    let status = if work_status == "waiting_review" {
      "waiting"
    } else if work_status == "blocked" {
      "blocked"
    } else if work_status == "assigned" {
      "assigned"
    } else {
      worker_status(json_string_field(worker, "status"))
    }
    let fields : Map[String, Json] = {
      "id": id,
      "name": name,
      "role": worker_role(json_string_field(worker, "role")),
      "status": status,
    }
    if work.length() > 0 {
      optional_item_field(
        fields,
        "buildingModuleKey",
        json_string_field(work, "buildingModuleKey"),
      )
      optional_item_field(fields, "workItemId", json_string_field(work, "id"))
      optional_item_field(fields, "runId", json_string_field(work, "runId"))
    } else {
      optional_item_field(
        fields,
        "buildingModuleKey",
        building_module_key(json_string_field(worker, "book_id")),
      )
    }
    agents.push(Json::object(fields))
  }
  for collaborator in projected_collaboration_agents(tasks) {
    agents.push(collaborator)
  }
  agents
}

///|
async fn energy_valley_runtime_projection() -> Json {
  let town_path = state_root() + "/town.json"
  let daemon_path = state_root() + "/daemon.json"
  let daemon_runtime_path = state_root() + "/daemon-runtime.json"
  let request_path = state_root() + "/operator-requests/requests.jsonl"
  let town_root = read_optional_json(town_path)
  let town = match town_root {
    Some(Object(root)) => object_fields(root.get("town"))
    _ => Map([])
  }
  let workers = array_field(town, "workers")
  let workers_by_id : Map[String, Json] = Map([])
  for worker in workers {
    guard worker is Object(worker_fields) else { continue }
    let id = json_string_field(worker_fields, "id")
    if !id.is_empty() {
      workers_by_id[id] = worker
    }
  }
  let executions = latest_executions(array_field(town, "executions"))
  let watchers = latest_watchers_by_task()
  let requests = operator_requests_json()
  let requests_by_goal : Map[String, Json] = Map([])
  match requests {
    Array(items) =>
      for item in items {
        guard item is Object(fields) else { continue }
        let goal_id = json_string_field(fields, "standing_goal_id")
        if !goal_id.is_empty() {
          requests_by_goal[goal_id] = item
        }
      }
    _ => ()
  }
  let tasks : Array[Json] = []
  let represented_requests : Map[String, Bool] = Map([])
  let represented_goals : Map[String, Bool] = Map([])
  let represented_watcher_tasks : Map[String, Bool] = Map([])
  for task in array_field(town, "tasks") {
    guard task is Object(task_fields) else { continue }
    let task_id = json_string_field(task_fields, "id")
    let watcher = watchers.get(task_id)
    if watcher is Some(_) {
      represented_watcher_tasks[task_id] = true
    }
    let watcher_fields = object_fields(watcher)
    let goal_id = json_string_field(watcher_fields, "goal_id")
    let request = if goal_id.is_empty() {
      None
    } else {
      requests_by_goal.get(goal_id)
    }
    let item = town_work_item(
      task,
      executions.get(task_id),
      workers_by_id,
      watcher,
      request,
    )
    match item {
      Some(value) => {
        let fields = object_fields(Some(value))
        let request_id = json_string_field(fields, "requestId")
        if !request_id.is_empty() {
          represented_requests[request_id] = true
        }
        let standing_goal_id = json_string_field(fields, "standingGoalId")
        if !standing_goal_id.is_empty() {
          represented_goals[standing_goal_id] = true
        }
        tasks.push(value)
      }
      _ => ()
    }
  }
  for task_id, watcher in watchers {
    if represented_watcher_tasks.contains(task_id) {
      continue
    }
    let watcher_fields = object_fields(Some(watcher))
    let goal_id = json_string_field(watcher_fields, "goal_id")
    let request = if goal_id.is_empty() {
      None
    } else {
      requests_by_goal.get(goal_id)
    }
    let request_fields = object_fields(request)
    let target_book_id = json_string_field(watcher_fields, "target_book_id")
    let title = {
      let request_title = json_string_field(request_fields, "title")
      if !request_title.is_empty() {
        request_title
      } else if !goal_id.is_empty() {
        "Standing watch: " + goal_id
      } else {
        "Standing watch: " + task_id
      }
    }
    let synthetic_task : Json = {
      "id": task_id,
      "title": title,
      "book_id": target_book_id,
      "prompt": json_string_field(watcher_fields, "detail"),
      "required_role": "Watcher",
      "standing_goal_id": goal_id,
    }
    match
      town_work_item(
        synthetic_task,
        None,
        workers_by_id,
        Some(watcher),
        request,
      ) {
      Some(value) => {
        let fields = object_fields(Some(value))
        let request_id = json_string_field(fields, "requestId")
        if !request_id.is_empty() {
          represented_requests[request_id] = true
        }
        if !goal_id.is_empty() {
          represented_goals[goal_id] = true
        }
        tasks.push(value)
      }
      None => ()
    }
  }
  match requests {
    Array(items) =>
      for item in items {
        guard item is Object(fields) else { continue }
        let id = json_string_field(fields, "id")
        let goal_id = json_string_field(fields, "standing_goal_id")
        if represented_requests.contains(id) ||
          (!goal_id.is_empty() && represented_goals.contains(goal_id)) {
          continue
        }
        match operator_work_item(item) {
          Some(value) => tasks.push(value)
          None => ()
        }
      }
    _ => ()
  }
  attach_collaboration(tasks)
  attach_result_links(tasks)
  let daemon_runtime = read_optional_json(daemon_runtime_path)
  let observed_at = durable_observed_at(daemon_runtime)
  let source_found = @fs.exists(town_path) ||
    @fs.exists(daemon_path) ||
    @fs.exists(daemon_runtime_path) ||
    @fs.exists(request_path)
  if !source_found {
    return {
      "schema": energy_valley_runtime_schema,
      "mode": "unavailable",
      "observedAt": observed_at,
      "tasks": Json::array([]),
      "agents": Json::array([]),
      "message": "MoonTown runtime state is unavailable.",
    }
  }
  let fields : Map[String, Json] = {
    "schema": energy_valley_runtime_schema,
    "mode": "live",
    "observedAt": observed_at,
    "tasks": Json::array(tasks),
    "agents": Json::array(projected_agents(workers, tasks)),
  }
  match read_optional_json(daemon_path) {
    Some(Object(daemon)) =>
      match daemon.get("tick_sequence") {
        Some(Number(value, ..)) => fields["tick"] = value.to_json()
        _ => ()
      }
    _ => ()
  }
  if town.length() == 0 {
    fields["message"] = "Runtime ledgers are available, but the town worker snapshot is unavailable.".to_json()
  }
  Json::object(fields)
}
