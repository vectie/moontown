///|
pub struct CivicServiceHealth {
  service_id : String
  title : String
  book_id : String
  service_kind : String
  workspace_root : String
  status : String
  operable : Bool
  proven_by_result : Bool
  workspace_exists : Bool
  schema_ready : Bool
  wiki_ready : Bool
  review_ready : Bool
  projection_ready : Bool
  skill_ready : Bool
  moonclaw_profile_ready : Bool
  latest_result_path : String
  latest_result_found : Bool
  latest_decision : String
  latest_book_changed : String
  latest_pages_changed : Int
  latest_accepted_facts : Int
  latest_review_items : Int
  next_check_hint : String
  missing_required_paths : Array[String]
  notes : Array[String]
} derive(Eq, ToJson, FromJson)

///|
pub struct CivicServicePortfolio {
  total : Int
  operable_count : Int
  proven_count : Int
  seeded_count : Int
  missing_count : Int
  review_count : Int
  blocked_count : Int
  changed_count : Int
  no_change_count : Int
  status_path : String
  markdown_path : String
  services : Array[CivicServiceHealth]
} derive(Eq, ToJson, FromJson)

///|
pub fn default_wenyu_civic_status_path() -> String {
  ".moontown/civic/status.json"
}

///|
pub async fn inspect_wenyu_civic_services(
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  status_path? : String = default_wenyu_civic_status_path(),
) -> CivicServicePortfolio {
  let catalog = @moonbook.load_or_create_catalog(path=book_catalog_path)
  let healths : Array[CivicServiceHealth] = []
  for service in @civic.wenyu_civic_services() {
    let entry = civic_catalog_entry_for_service(service, catalog)
    healths.push(inspect_wenyu_civic_service(service, entry))
  }
  civic_service_portfolio(healths, status_path)
}

///|
pub async fn render_wenyu_civic_status(
  book_catalog_path? : String = @moonbook.default_catalog_path(),
) -> String {
  render_wenyu_civic_portfolio(inspect_wenyu_civic_services(book_catalog_path~))
}

///|
pub async fn write_wenyu_civic_status(
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  status_path? : String = default_wenyu_civic_status_path(),
) -> String {
  let portfolio = inspect_wenyu_civic_services(book_catalog_path~, status_path~)
  write_text_file(status_path, portfolio.to_json().stringify(indent=2))
  write_text_file(
    portfolio.markdown_path,
    render_wenyu_civic_portfolio(portfolio),
  )
  "Wrote Wenyu civic service status for \{portfolio.total} module(s) to \{status_path} and \{portfolio.markdown_path}."
}

///|
fn civic_catalog_entry_for_service(
  service : @civic.CivicServiceDefinition,
  catalog : Array[@moonbook.BookCatalogEntry],
) -> @moonbook.BookCatalogEntry {
  for entry in catalog {
    match @civic.wenyu_civic_service_for_book_id(entry.id) {
      Some(found) if found.id == service.id => return entry
      _ => ()
    }
  }
  @civic.wenyu_civic_book_entry(service)
}

///|
async fn inspect_wenyu_civic_service(
  service : @civic.CivicServiceDefinition,
  entry : @moonbook.BookCatalogEntry,
) -> CivicServiceHealth {
  let root = @moonbook.workspace_root(entry)
  let workspace_exists = @fs.exists(root)
  let missing_required_paths = civic_missing_paths(root, service.target_pages)
  let schema_ready = civic_paths_ready(root, service.schema_pages)
  let wiki_ready = civic_paths_ready(root, service.wiki_pages)
  let review_ready = civic_paths_ready(root, service.review_queues)
  let projection_ready = @fs.exists("\{root}/book/moonbook-ui-state.json")
  let skill_ready = @fs.exists("\{root}/skills/wenyu-civic-service/SKILL.md") &&
    @fs.exists("\{root}/\{service.skill_path}")
  let moonclaw_profile_ready = civic_moonclaw_profile_ready(root)
  let latest_result_path = civic_service_result_path(service)
  let latest_result = read_civic_book_result(latest_result_path)
  let latest_summary = match latest_result {
    Some(result) => result.summary
    None => ""
  }
  let latest_decision = civic_marker_value(
    latest_summary,
    "civic_service_decision",
    fallback=if latest_result == None { "none" } else { "unknown" },
  )
  let latest_book_changed = civic_marker_value(
    latest_summary,
    "book_changed",
    fallback="unknown",
  )
  let latest_pages_changed = civic_marker_int(
    latest_summary,
    "wiki_pages_changed_count",
    fallback=0,
  )
  let latest_accepted_facts = civic_marker_int(
    latest_summary,
    "accepted_facts_count",
    fallback=0,
  )
  let latest_review_items = civic_marker_int(
    latest_summary,
    "review_items_created_count",
    fallback=0,
  )
  let next_check_hint = civic_marker_value(
    latest_summary,
    "next_check_hint",
    fallback="unknown",
  )
  let status = civic_service_status_label(
    workspace_exists~,
    missing_required_paths~,
    skill_ready~,
    moonclaw_profile_ready~,
    latest_result_found=latest_result != None,
    latest_decision~,
    latest_review_items~,
  )
  let operable = workspace_exists &&
    missing_required_paths.is_empty() &&
    schema_ready &&
    wiki_ready &&
    review_ready &&
    projection_ready &&
    skill_ready &&
    moonclaw_profile_ready
  let proven_by_result = civic_service_result_is_proven(latest_decision)
  {
    service_id: service.id,
    title: service.title,
    book_id: service.book_id,
    service_kind: service.service_kind,
    workspace_root: root,
    status,
    operable,
    proven_by_result,
    workspace_exists,
    schema_ready,
    wiki_ready,
    review_ready,
    projection_ready,
    skill_ready,
    moonclaw_profile_ready,
    latest_result_path,
    latest_result_found: latest_result != None,
    latest_decision,
    latest_book_changed,
    latest_pages_changed,
    latest_accepted_facts,
    latest_review_items,
    next_check_hint,
    missing_required_paths,
    notes: civic_health_notes(
      operable~,
      status~,
      missing_required_paths~,
      latest_decision~,
      latest_review_items~,
    ),
  }
}

///|
fn civic_service_portfolio(
  services : Array[CivicServiceHealth],
  status_path : String,
) -> CivicServicePortfolio {
  {
    total: services.length(),
    operable_count: services.filter(fn(item) { item.operable }).length(),
    proven_count: services.filter(fn(item) { item.proven_by_result }).length(),
    seeded_count: services.filter(fn(item) { item.status == "seeded" }).length(),
    missing_count: services
    .filter(fn(item) {
      item.status == "missing-workspace" ||
      item.status == "incomplete" ||
      item.status == "misconfigured"
    })
    .length(),
    review_count: services
    .filter(fn(item) { item.status == "needs-review" })
    .length(),
    blocked_count: services
    .filter(fn(item) { item.status == "blocked" })
    .length(),
    changed_count: services
    .filter(fn(item) { item.status == "changed" })
    .length(),
    no_change_count: services
    .filter(fn(item) { item.status == "no-change" })
    .length(),
    status_path,
    markdown_path: civic_markdown_status_path(status_path),
    services,
  }
}

///|
fn render_wenyu_civic_portfolio(portfolio : CivicServicePortfolio) -> String {
  let builder = StringBuilder::new()
  builder.write_string("# Wenyu Civic Service Status\n\n")
  builder.write_string(
    "Total: \{portfolio.total}; operable: \{portfolio.operable_count}; proven by result: \{portfolio.proven_count}; review: \{portfolio.review_count}; blocked: \{portfolio.blocked_count}; missing/incomplete: \{portfolio.missing_count}.\n\n",
  )
  builder.write_string(
    "| Service | Status | Operable | Latest decision | Changed pages | Accepted facts | Review items | Missing paths |\n",
  )
  builder.write_string("|---|---:|---:|---|---:|---:|---:|---|\n")
  for service in portfolio.services {
    builder.write_string(
      "|\{service.title}|\{service.status}|\{yes_no(service.operable)}|\{service.latest_decision}|\{service.latest_pages_changed}|\{service.latest_accepted_facts}|\{service.latest_review_items}|\{compact_missing_paths(service.missing_required_paths)}|\n",
    )
  }
  builder.write_string("\n## Notes\n\n")
  for service in portfolio.services {
    builder.write_string("- ")
    builder.write_string(service.title)
    builder.write_string(": ")
    builder.write_string(service.notes.join("; "))
    builder.write_string("\n")
  }
  builder.to_string()
}

///|
async fn civic_missing_paths(
  root : String,
  paths : Array[String],
) -> Array[String] {
  let missing : Array[String] = []
  for path in paths {
    if !@fs.exists("\{root}/\{path}") {
      missing.push(path)
    }
  }
  missing
}

///|
async fn civic_paths_ready(root : String, paths : Array[String]) -> Bool {
  if paths.is_empty() {
    return true
  }
  civic_missing_paths(root, paths).is_empty()
}

///|
async fn civic_moonclaw_profile_ready(root : String) -> Bool {
  let path = "\{root}/moonclaw.jobs.json"
  if !@fs.exists(path) {
    return false
  }
  let text = @fs.read_file(path).text() catch { _ => return false }
  text.contains("\"wenyu_civic_service_worker\"") &&
  text.contains("\"execute_civic_service\"") &&
  text.contains("\"review_civic_service\"")
}

///|
async fn read_civic_book_result(path : String) -> @moonbook.BookResult? {
  let text = read_text_or_empty(path)
  if text.trim().is_empty() {
    return None
  }
  let parsed = @json.parse(text) catch { _ => return None }
  Some(@json.from_json(parsed) catch { _ => return None })
}

///|
fn civic_service_result_path(service : @civic.CivicServiceDefinition) -> String {
  ".moontown/book-results/goal-\{service.book_id}-civic-service.json"
}

///|
fn civic_markdown_status_path(status_path : String) -> String {
  if status_path.has_suffix(".json") {
    "\{status_path[:status_path.length() - 5]}.md"
  } else {
    "\{status_path}.md"
  }
}

///|
fn civic_service_status_label(
  workspace_exists~ : Bool,
  missing_required_paths~ : Array[String],
  skill_ready~ : Bool,
  moonclaw_profile_ready~ : Bool,
  latest_result_found~ : Bool,
  latest_decision~ : String,
  latest_review_items~ : Int,
) -> String {
  if !workspace_exists {
    "missing-workspace"
  } else if !skill_ready || !moonclaw_profile_ready {
    "misconfigured"
  } else if !missing_required_paths.is_empty() {
    "incomplete"
  } else if !latest_result_found {
    "seeded"
  } else {
    match latest_decision {
      "update" if latest_review_items > 0 => "needs-review"
      "update" => "changed"
      "no_change" => "no-change"
      "needs_review" => "needs-review"
      "blocked" => "blocked"
      _ => "result-unknown"
    }
  }
}

///|
fn civic_service_result_is_proven(decision : String) -> Bool {
  decision == "update" || decision == "no_change" || decision == "needs_review"
}

///|
fn civic_health_notes(
  operable~ : Bool,
  status~ : String,
  missing_required_paths~ : Array[String],
  latest_decision~ : String,
  latest_review_items~ : Int,
) -> Array[String] {
  let notes : Array[String] = []
  if operable {
    notes.push("workspace is operable")
  } else {
    notes.push("workspace is not yet fully operable")
  }
  if !missing_required_paths.is_empty() {
    notes.push("\{missing_required_paths.length()} required path(s) missing")
  }
  match status {
    "seeded" =>
      notes.push("no civic service result has been accepted into this book yet")
    "needs-review" =>
      notes.push(
        "\{latest_review_items} review item(s) require keeper/operator judgment",
      )
    "blocked" => notes.push("latest service run reported a blocker")
    "changed" => notes.push("latest service run reported an accepted update")
    "no-change" =>
      notes.push(
        "latest service run checked the module and found no material change",
      )
    _ =>
      if latest_decision != "none" {
        notes.push("latest decision is `\{latest_decision}`")
      }
  }
  notes
}

///|
fn compact_missing_paths(paths : Array[String]) -> String {
  if paths.is_empty() {
    return "none"
  }
  if paths.length() <= 3 {
    return paths.join("<br>")
  }
  "\{paths[0]}<br>\{paths[1]}<br>\{paths[2]}<br>+\{paths.length() - 3} more"
}

///|
fn yes_no(value : Bool) -> String {
  if value {
    "yes"
  } else {
    "no"
  }
}
