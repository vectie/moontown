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
let moonbook_bookkeeper_contract = "moonbook.bookkeeper.v1"

///|
let moonbook_bookkeeper_ui_projection = "moonbook.bookkeeper.ui.v1"

///|
let moontown_acceptance_receipt_projection = "moontown.moonbook.acceptance-receipt-projection.v1"

///|
/// Project only the latest explicit, evidence-bearing MoonBook bookkeeper
/// acceptance decision. Display text and earlier superseded decisions are not
/// acceptance evidence.
fn moonbook_acceptance_receipt_projection(value : Json?) -> Json? {
  guard value is Some(Object(state)) else { return None }
  guard json_string_field(state, "contract_version") ==
    moonbook_bookkeeper_contract &&
    json_string_field(state, "projection_version") ==
    moonbook_bookkeeper_ui_projection &&
    state.get("loaded") is Some(True) else {
    return None
  }
  let decisions = array_field(state, "deliverable_acceptance")
  if decisions.is_empty() {
    return None
  }
  guard decisions[decisions.length() - 1] is Object(decision) else {
    return None
  }
  let decision_id = json_string_field(decision, "record_id")
  let candidate_version = json_string_field(decision, "record_version")
  let reviewer = json_string_field(decision, "owner_route")
  let evidence_count = json_int_field(
    decision, "evidence_count", -1, -1, 2147483647,
  )
  let issue_count = json_int_field(decision, "issue_count", -1, -1, 2147483647)
  guard json_string_field(decision, "stage") == "deliverable_acceptance" &&
    json_string_field(decision, "status") == "accepted" &&
    decision.get("requires_human_review") is Some(False) &&
    !decision_id.is_empty() &&
    !candidate_version.is_empty() &&
    !reviewer.is_empty() &&
    evidence_count > 0 &&
    issue_count == 0 else {
    return None
  }
  Some({
    "contract_version": moontown_acceptance_receipt_projection,
    "decision": "accepted",
    "decision_id": decision_id,
    "candidate_version": candidate_version,
    "reviewer": reviewer,
    "evidence_count": evidence_count,
    "issue_count": issue_count,
    "requires_human_review": false,
    "source_contract": moonbook_bookkeeper_contract,
    "source_projection": moonbook_bookkeeper_ui_projection,
  })
}

///|
fn ensure_projection_array(fields : Map[String, Json], key : String) -> Unit {
  match fields.get(key) {
    Some(Array(_)) => ()
    _ => fields[key] = Json::array([])
  }
}

///|
async fn module_projection_links(
  book_id : String,
  root : String,
) -> Array[Json] {
  let links : Array[Json] = []
  let candidates : Array[(String, String, String)] = [
    ("Open book", "book/site/generated/index.html", "site"),
    ("Open book index", "book/index.html", "site"),
    ("Open book home", "book/Home.html", "site"),
    ("Review queue", "book/reviews/pending.html", "review"),
    ("Evidence", "book/synthesis/evidence.html", "evidence"),
  ]
  let mut has_site = false
  for candidate in candidates {
    let (label, relative, kind) = candidate
    if kind == "site" && has_site {
      continue
    }
    if @fs.exists(root + "/" + relative) &&
      @fs.kind(root + "/" + relative) is Regular {
      links.push({
        "label": label,
        "kind": kind,
        "url": "/book-output/" + book_id + "/" + relative,
      })
      if kind == "site" {
        has_site = true
      }
    }
  }
  links
}

///|
async fn module_projections_json() -> Json {
  let projections : Array[Json] = []
  let root = books_root()
  if @fs.exists(root) && @fs.kind(root) is Directory {
    let dir = @fs.opendir(root)
    defer dir.close()
    let names = dir.read_all()
    names.sort()
    for name in names {
      if safe_slug(name) != name {
        continue
      }
      let book_root = root + "/" + name
      let path = book_root + "/book/moonbook-ui-state.json"
      guard @fs.exists(path) && @fs.kind(path) is Regular else { continue }
      guard read_optional_json(path) is Some(Object(source)) else { continue }
      let fields : Map[String, Json] = Map([])
      for key, value in source {
        fields[key] = value
      }
      // A presentation document cannot self-assert acceptance. Re-project this
      // field only from MoonBook's durable bookkeeper state below.
      fields.remove("acceptance_receipt")
      fields["book_id"] = name.to_json()
      if json_string_field(fields, "title").is_empty() {
        fields["title"] = name.replace(old="-", new=" ").to_json()
      }
      if json_string_field(fields, "summary").is_empty() {
        fields["summary"] = "MoonBook projection is available.".to_json()
      }
      for
        key in [
          "status_chips", "metrics", "readiness", "review_queue", "page_families",
          "journey",
        ] {
        ensure_projection_array(fields, key)
      }
      fields["links"] = Json::array(module_projection_links(name, book_root))
      match
        moonbook_acceptance_receipt_projection(
          read_optional_json(book_root + "/.moonbook/bookkeeper/ui-state.json"),
        ) {
        Some(receipt) => fields["acceptance_receipt"] = receipt
        None => ()
      }
      projections.push(Json::object(fields))
    }
  }
  {
    "generated_at": iso_timestamp(@env.now()),
    "projections": Json::array(projections),
  }
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
fn building_module_key(
  book_id : String,
  bindings? : Map[String, String] = Map([]),
) -> String {
  if book_id.is_empty() {
    "unlocated"
  } else {
    match bindings.get(book_id) {
      Some(building_id) => runtime_building_module_key(building_id)
      None =>
        match book_id {
          "research-embodied-robotics" => "research-embodied-robotics"
          "research-ai-agents" | "research-agent-work-projection" =>
            "research-ai-agents"
          "research-opc" => "research-opc"
          "research-how-llms-are-trained-in-very-detail" =>
            "research-llm-training"
          "research-ai-hardware" => "research-ai-hardware"
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
          _ => "unlocated"
        }
    }
  }
}

///|
fn runtime_building_module_key(building_id : String) -> String {
  match building_id {
    "vitality-dashboard" => "vitality-tower"
    "broadcast-tower" => "story-radar"
    id => id
  }
}

///|
async fn knowledge_domain_book_bindings() -> Map[String, String] {
  let bindings : Map[String, String] = Map([])
  guard resolved_knowledge_domain_catalog() is Some(catalog) else {
    return bindings
  }
  for domain in catalog.domains {
    for book in domain.books {
      bindings[book.book_id] = domain.building_id
    }
  }
  bindings
}

///|
fn knowledge_domain_catalog_paths(
  configured : String?,
  browser_static_root : String,
  application_resource_root : String,
) -> Array[String] {
  match configured {
    Some(path) => [path]
    None =>
      [
        browser_static_root + "/knowledge-domain-catalog.json",
        application_resource_root + "/domains/catalog.v1.json",
        "assets/templates/domains/catalog.v1.json",
      ]
  }
}

///|
/// Resolve one catalog for every desktop consumer. An explicit environment
/// override is exclusive and fails closed instead of being mixed with a
/// different bundled browser catalog.
async fn resolved_knowledge_domain_catalog() -> @domain_catalog.KnowledgeDomainCatalog? {
  let paths = knowledge_domain_catalog_paths(
    env_value("MOONTOWN_KNOWLEDGE_DOMAIN_CATALOG"),
    static_root(),
    resource_root(),
  )
  for path in paths {
    if !@fs.exists(path) {
      continue
    }
    if !(@fs.kind(path) is Regular) {
      continue
    }
    let text = @support.read_text_or_empty(path)
    let catalog = @domain_catalog.parse_knowledge_domain_catalog(text) catch {
      _ => continue
    }
    return Some(catalog)
  }
  None
}

///|
fn knowledge_domain_catalog_body(
  catalog : @domain_catalog.KnowledgeDomainCatalog,
) -> String {
  catalog.to_json().stringify(indent=2)
}

///|
fn knowledge_domain_catalog_digest(
  catalog : @domain_catalog.KnowledgeDomainCatalog,
) -> String {
  let bytes = @utf8.encode(knowledge_domain_catalog_body(catalog))
  "sha256:\{@crypto.bytes_to_hex_string(@crypto.sha256(bytes))}"
}

///|
async fn resolved_knowledge_domain_catalog_response() -> (String, String)? {
  match resolved_knowledge_domain_catalog() {
    Some(catalog) =>
      Some(
        (
          knowledge_domain_catalog_body(catalog),
          knowledge_domain_catalog_digest(catalog),
        ),
      )
    None => None
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
/// A completed town task can retain a terminal MoonClaw handoff whose only
/// outcome was explicitly triaged transient infrastructure contention. That
/// row is useful recovery history, but it is not current blocked work. Keep
/// the predicate deliberately narrow so ordinary blocked/failed executions
/// remain actionable in the live task collection.
fn terminal_transient_handoff_is_history(
  task : Map[String, Json],
  execution : Map[String, Json],
) -> Bool {
  let task_status = enum_key(json_string_field(task, "status"))
  let execution_status = enum_key(json_string_field(execution, "status"))
  let decision = enum_key(json_string_field(execution, "result_decision"))
  let summary = json_string_field(execution, "summary").to_lower()
  (task_status == "done" || task_status == "completed") &&
  execution_status == "completed" &&
  decision == "deferredtransientinfrastructure" &&
  summary.contains("keeper_auto_triage: transient_infrastructure_contention")
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
/// A detached standing watch records `Deferred` while its external import is
/// still producing a receipt. During that window the durable execution row is
/// the stronger observation: `ProposalImported` means assigned and `Running`
/// means the worker is still active. Once supervision marks the execution
/// stale or failed, the watcher decision becomes authoritative again.
fn projected_work_item_status(
  task : Map[String, Json],
  execution : Map[String, Json],
  watcher : Map[String, Json],
) -> String {
  let execution_status = town_task_status(task, execution)
  if enum_key(json_string_field(watcher, "decision")) == "deferred" &&
    (execution_status == "assigned" || execution_status == "running") {
    return execution_status
  }
  watcher_task_status(watcher).unwrap_or(execution_status)
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
  book_bindings : Map[String, String],
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
    "status": projected_work_item_status(task, execution, watcher),
    "buildingModuleKey": building_module_key(book_id, bindings=book_bindings),
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
  if watcher.length() == 0 &&
    terminal_transient_handoff_is_history(task, execution) {
    fields["recordScope"] = "history".to_json()
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
/// Route terminal recovery history away from the live task list. The marker
/// is projection-internal and is removed before either collection is emitted.
fn route_projected_work_item(
  value : Json,
  tasks : Array[Json],
  history : Array[Json],
) -> Unit {
  guard value is Object(fields) else { return }
  if json_string_field(fields, "recordScope") == "history" {
    fields.remove("recordScope")
    history.push(value)
  } else {
    tasks.push(value)
  }
}

///|
fn energy_valley_runtime_history_projection_limit() -> Int {
  @system_settings.current_system_settings().runtime_history_projection_limit
}

///|
fn projected_history_compare(left : Json, right : Json) -> Int {
  let left_fields = object_fields(Some(left))
  let right_fields = object_fields(Some(right))
  let by_time = json_string_field(left_fields, "updatedAt").compare(
    json_string_field(right_fields, "updatedAt"),
  )
  if by_time != 0 {
    by_time
  } else {
    let by_id = json_string_field(left_fields, "id").compare(
      json_string_field(right_fields, "id"),
    )
    if by_id != 0 {
      by_id
    } else {
      left.stringify().compare(right.stringify())
    }
  }
}

///|
fn bounded_projected_history(source : ArrayView[Json]) -> Array[Json] {
  let history = source.to_owned()
  history.sort_by(projected_history_compare)
  while history.length() > energy_valley_runtime_history_projection_limit() {
    ignore(history.remove(0))
  }
  history
}

///|
fn operator_work_item(
  value : Json,
  book_bindings : Map[String, String],
) -> Json? {
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
    "buildingModuleKey": building_module_key(book_id, bindings=book_bindings),
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
fn projected_task_activity(fields : Map[String, Json]) -> (String, String) {
  let status = json_string_field(fields, "status")
  let collaboration_count = match fields.get("collaboration") {
    Some(Object(collaboration)) =>
      array_field(collaboration, "participants").length()
    _ => 0
  }
  let progress = match fields.get("progress") {
    Some(Object(progress)) => progress
    _ => Map([])
  }
  let accepted = json_int_field(progress, "acceptedFacts", 0, 0, 2147483647)
  let changed = json_int_field(progress, "pagesChanged", 0, 0, 2147483647)
  match status {
    "queued" => ("idle", "等待调度")
    "assigned" => ("walking", "前往研究建筑")
    "waiting_review" => ("reviewing", "独立审阅")
    "blocked" | "failed" => ("recovering", "恢复与修订")
    // Durable completion is not evidence that a worker is still in transit.
    // A live return animation needs a recent, timestamped return receipt.
    "completed" => ("idle", "工作已完成")
    "running" if collaboration_count >= 2 => ("discussing", "跨书讨论")
    "running" if accepted > 0 || changed > 0 => ("synthesizing", "综合证据")
    "running" => ("researching", "研究资料")
    _ => ("idle", "等待工作")
  }
}

///|
fn annotate_projected_task_activities(
  tasks : Array[Json],
  book_bindings : Map[String, String],
) -> Unit {
  for task in tasks {
    guard task is Object(fields) else { continue }
    let (kind, label) = projected_task_activity(fields)
    let home = building_module_key(
      json_string_field(fields, "bookId"),
      bindings=book_bindings,
    )
    let destination = match kind {
      "discussing" => "social-square"
      "recovering" => "town-shell"
      _ => json_string_field(fields, "buildingModuleKey")
    }
    fields["activityKind"] = kind.to_json()
    fields["activityLabel"] = label.to_json()
    optional_item_field(fields, "originBuildingModuleKey", home)
    optional_item_field(fields, "destinationBuildingModuleKey", destination)
  }
}

///|
/// A book may contain evidence produced by a later run. Never attach those
/// current-book pages to a terminal task that has no Run ID of its own.
fn projected_task_can_link_results(fields : Map[String, Json]) -> Bool {
  let status = json_string_field(fields, "status")
  (status == "completed" || status == "waiting_review") &&
  !json_string_field(fields, "runId").is_empty()
}

///|
async fn attach_result_links(tasks : Array[Json]) -> Unit {
  for task in tasks {
    guard task is Object(fields) else { continue }
    if !projected_task_can_link_results(fields) {
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
        "buildingModuleKey": json_string_field(
          task_fields, "destinationBuildingModuleKey",
        ),
        "bookId": json_string_field(task_fields, "bookId"),
        "activityKind": "discussing",
        "activityLabel": "跨书讨论",
        "originBuildingModuleKey": json_string_field(
          task_fields, "originBuildingModuleKey",
        ),
        "destinationBuildingModuleKey": "social-square",
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
  book_bindings : Map[String, String],
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
      "kind": "bounded-worker",
      "durability": "run-scoped",
    }
    if work.length() > 0 {
      optional_item_field(
        fields,
        "buildingModuleKey",
        json_string_field(work, "buildingModuleKey"),
      )
      optional_item_field(fields, "workItemId", json_string_field(work, "id"))
      optional_item_field(fields, "runId", json_string_field(work, "runId"))
      optional_item_field(fields, "bookId", json_string_field(work, "bookId"))
      optional_item_field(
        fields,
        "activityKind",
        json_string_field(work, "activityKind"),
      )
      optional_item_field(
        fields,
        "activityLabel",
        json_string_field(work, "activityLabel"),
      )
      optional_item_field(
        fields,
        "originBuildingModuleKey",
        json_string_field(work, "originBuildingModuleKey"),
      )
      optional_item_field(
        fields,
        "destinationBuildingModuleKey",
        json_string_field(work, "destinationBuildingModuleKey"),
      )
      fields["movementSource"] = "runtime-task-projection".to_json()
      fields["workStatusSource"] = "runtime-execution-ledger".to_json()
    } else {
      optional_item_field(
        fields,
        "buildingModuleKey",
        building_module_key(
          json_string_field(worker, "book_id"),
          bindings=book_bindings,
        ),
      )
      fields["movementSource"] = "not-observed".to_json()
      fields["workStatusSource"] = "worker-snapshot".to_json()
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
  let book_bindings = knowledge_domain_book_bindings()
  let catalog_digest = match resolved_knowledge_domain_catalog() {
    Some(catalog) => knowledge_domain_catalog_digest(catalog)
    None => ""
  }
  let town_path = state_root() + "/town.json"
  let daemon_path = state_root() + "/daemon.json"
  let daemon_runtime_path = state_root() + "/daemon-runtime.json"
  let request_path = state_root() + "/operator-requests/requests.jsonl"
  let supervisor_path = state_root() + "/supervisor-setup/state.json"
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
  let history : Array[Json] = []
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
      book_bindings,
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
        route_projected_work_item(value, tasks, history)
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
        book_bindings,
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
        route_projected_work_item(value, tasks, history)
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
        match operator_work_item(item, book_bindings) {
          Some(value) => route_projected_work_item(value, tasks, history)
          None => ()
        }
      }
    _ => ()
  }
  attach_collaboration(tasks)
  annotate_projected_task_activities(tasks, book_bindings)
  attach_result_links(tasks)
  let daemon_runtime = read_optional_json(daemon_runtime_path)
  let observed_at = durable_observed_at(daemon_runtime)
  let source_found = @fs.exists(town_path) ||
    @fs.exists(daemon_path) ||
    @fs.exists(daemon_runtime_path) ||
    @fs.exists(request_path) ||
    @fs.exists(supervisor_path)
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
    "history": Json::array(bounded_projected_history(history)),
    "agents": Json::array(
      {
        let agents = projected_agents(workers, tasks, book_bindings)
        let supervisor_app = @supervisor_setup.default_supervisor_setup_application()
        let lineage = supervisor_app.execution_lineage_projection()
        for agent in agents {
          guard agent is Object(agent_fields) else { continue }
          let run_id = json_string_field(agent_fields, "runId")
          if run_id.is_empty() {
            continue
          }
          for edge in lineage {
            guard edge is Object(edge_fields) else { continue }
            if json_string_field(edge_fields, "runId") == run_id {
              optional_item_field(
                agent_fields,
                "supervisorProfileId",
                json_string_field(edge_fields, "supervisorProfileId"),
              )
              optional_item_field(
                agent_fields,
                "lineageStatus",
                json_string_field(edge_fields, "status"),
              )
              agent_fields["lineageSource"] = "supervisor-execution-handoff".to_json()
            }
          }
        }
        for supervisor in supervisor_app.supervisor_agents_projection() {
          agents.push(supervisor)
        }
        for worker in supervisor_app.supervisor_worker_agents_projection() {
          agents.push(worker)
        }
        agents
      },
    ),
  }
  optional_item_field(fields, "knowledgeCatalogDigest", catalog_digest)
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
