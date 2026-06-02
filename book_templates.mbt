///|
pub struct BookTemplateDescriptor {
  template_id : String
  book_type : String
  specialization : String
  title : String
  purpose : String
  root : String
  install_example : String
  install_command : String
  status_command : String
  required_paths : Array[String]
  editable_files : Array[String]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub struct BookTemplateRegistry {
  registry_path : String
  templates : Array[BookTemplateDescriptor]
  missing_count : Int
  missing_paths : Array[String]
  ready : Bool
} derive(Debug, Eq, ToJson, FromJson)

///|
pub struct BookTemplateRequest {
  id : String
  template_id : String
  config_path : String
  status : String
  summary : String
  last_processed_tick : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
pub struct BookTemplateRequestLedger {
  requests : Array[BookTemplateRequest]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub struct BookTemplateRequestEvent {
  id : String
  request_id : String
  template_id : String
  status : String
  config_path : String
  summary : String
  tick : Int
  generated_at_ms : UInt64
} derive(Debug, Eq, ToJson, FromJson)

///|
pub struct BookTemplateRequestStatus {
  request_path : String
  event_path : String
  request_count : Int
  pending_count : Int
  installed_count : Int
  failed_count : Int
  retry_count : Int
  ready : Bool
  summary : String
  latest_event_summary : String
} derive(Debug, Eq, ToJson, FromJson)

///|
struct BookTemplateRegistryFile {
  templates : Array[BookTemplateDescriptor]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn default_book_template_registry_path() -> String {
  "templates/books/templates.json"
}

///|
pub fn default_book_template_request_path(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  "\{@path.Path::dirname(snapshot_path).to_string()}/book-template-requests.json"
}

///|
pub fn default_book_template_request_event_path(
  request_path? : String = default_book_template_request_path(),
) -> String {
  "\{@path.Path::dirname(request_path).to_string()}/book-template-request-events.jsonl"
}

///|
pub async fn inspect_book_template_registry(
  registry_path? : String = default_book_template_registry_path(),
) -> BookTemplateRegistry {
  let templates = load_book_template_registry_file(registry_path)
  let missing : Array[String] = []
  if !@fs.exists(registry_path) {
    missing.push(registry_path)
  }
  for template in templates {
    if !@fs.exists(template.root) {
      missing.push(template.root)
    }
    if !template.install_example.trim().is_empty() &&
      !@fs.exists(template.install_example) {
      missing.push(template.install_example)
    }
    for required in template.required_paths {
      let path = "\{template.root}/\{required}"
      if !@fs.exists(path) {
        missing.push(path)
      }
    }
  }
  {
    registry_path,
    templates,
    missing_count: missing.length(),
    missing_paths: missing,
    ready: !templates.is_empty() && missing.is_empty(),
  }
}

///|
pub async fn render_book_template_registry(
  registry_path? : String = default_book_template_registry_path(),
) -> String {
  let registry = inspect_book_template_registry(registry_path~)
  let rows : Array[String] = []
  for template in registry.templates {
    rows.push(
      "| `\{template.template_id}` | `\{template.book_type}` | `\{template.specialization}` | \{template.title} | `\{template.install_command}` |",
    )
  }
  [
    "# Book Template Registry",
    "",
    "- Registry: `\{registry.registry_path}`",
    "- Ready: `\{registry.ready}`",
    "- Templates: `\{registry.templates.length()}`",
    "- Missing required paths: `\{registry.missing_count}`",
    "",
    "## Templates",
    "",
    "| Template | Book type | Specialization | Title | Install command |",
    "| --- | --- | --- | --- | --- |",
    if rows.is_empty() {
      "| none | none | none | none | none |"
    } else {
      rows.join("\n")
    },
    "",
    "## Missing",
    "",
    if registry.missing_paths.is_empty() {
      "- none"
    } else {
      markdown_bullets(registry.missing_paths)
    },
  ].join("\n")
}

///|
pub async fn render_book_template_request_status(
  request_path? : String = default_book_template_request_path(),
) -> String {
  let status = inspect_book_template_request_status(request_path~)
  let ledger = load_book_template_request_ledger(request_path)
  let rows : Array[String] = []
  for request in ledger.requests {
    rows.push(
      "| `\{request.id}` | `\{request.template_id}` | `\{request.status}` | `\{request.config_path}` | \{request.summary} |",
    )
  }
  [
    "# Book Template Request Inbox",
    "",
    "- Path: `\{status.request_path}`",
    "- Ready: `\{status.ready}`",
    "- Requests: `\{status.request_count}`",
    "- Pending: `\{status.pending_count}`",
    "- Installed: `\{status.installed_count}`",
    "- Failed: `\{status.failed_count}`",
    "- Retry: `\{status.retry_count}`",
    "- Event log: `\{status.event_path}`",
    "- Latest event: \{status.latest_event_summary}",
    "",
    "| Request | Template | Status | Config | Summary |",
    "| --- | --- | --- | --- | --- |",
    if rows.is_empty() {
      "| none | none | none | none | none |"
    } else {
      rows.join("\n")
    },
  ].join("\n")
}

///|
pub async fn inspect_book_template_request_status(
  request_path? : String = default_book_template_request_path(),
) -> BookTemplateRequestStatus {
  let ledger = load_book_template_request_ledger(request_path)
  let event_path = default_book_template_request_event_path(request_path~)
  let latest_event_summary = latest_book_template_request_event_summary(
    event_path,
  )
  let pending = count_book_template_requests_by_status(ledger, "pending")
  let installed = count_book_template_requests_by_status(ledger, "installed")
  let failed = count_book_template_requests_by_status(ledger, "failed")
  let retry = count_book_template_requests_by_status(ledger, "retry")
  let count = ledger.requests.length()
  {
    request_path,
    event_path,
    request_count: count,
    pending_count: pending,
    installed_count: installed,
    failed_count: failed,
    retry_count: retry,
    ready: failed == 0,
    summary: "book_template_requests=\{count} pending=\{pending} retry=\{retry} installed=\{installed} failed=\{failed}",
    latest_event_summary,
  }
}

///|
pub async fn process_book_template_requests(
  request_path? : String = default_book_template_request_path(),
  registry_path? : String = default_book_template_registry_path(),
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  standing_goal_path? : String = @storage.default_standing_goal_path(),
  tick? : Int = 0,
) -> String {
  let ledger = load_book_template_request_ledger(request_path)
  if ledger.requests.is_empty() {
    return "Processed 0 book template request(s); pending=0 installed=0 failed=0."
  }
  let updated : Array[BookTemplateRequest] = []
  let event_path = default_book_template_request_event_path(request_path~)
  let event_request_ids = load_book_template_request_event_request_ids(
    event_path,
  )
  let request_base_dir = @path.Path::dirname(request_path).to_string()
  let mut processed = 0
  let mut reconciled_events = 0
  for request in ledger.requests {
    if request.status == "pending" || request.status == "retry" {
      let config_path = resolve_book_template_request_path(
        request_base_dir,
        request.config_path,
      )
      let summary = install_book_template_config(
        request.template_id,
        config_path,
        registry_path~,
        book_catalog_path~,
        standing_goal_path~,
      )
      processed += 1
      let next_request = {
        ..request,
        config_path,
        status: if book_template_install_summary_success(summary) {
          "installed"
        } else {
          "failed"
        },
        summary,
        last_processed_tick: tick,
      }
      updated.push(next_request)
      append_book_template_request_event(event_path, {
        id: "\{request.id}-\{tick}-\{@env.now()}",
        request_id: request.id,
        template_id: request.template_id,
        status: next_request.status,
        config_path,
        summary,
        tick,
        generated_at_ms: @env.now(),
      })
      event_request_ids.push(request.id)
    } else {
      if (request.status == "installed" || request.status == "failed") &&
        !event_request_ids.contains(request.id) {
        append_book_template_request_event(event_path, {
          id: "\{request.id}-reconciled-\{tick}-\{@env.now()}",
          request_id: request.id,
          template_id: request.template_id,
          status: request.status,
          config_path: request.config_path,
          summary: request.summary,
          tick,
          generated_at_ms: @env.now(),
        })
        event_request_ids.push(request.id)
        reconciled_events += 1
      }
      updated.push(request)
    }
  }
  let next = BookTemplateRequestLedger::{ requests: updated }
  save_book_template_request_ledger(request_path, next)
  "Processed \{processed} book template request(s); reconciled_events=\{reconciled_events} pending=\{count_book_template_requests_by_status(next, "pending")} installed=\{count_book_template_requests_by_status(next, "installed")} failed=\{count_book_template_requests_by_status(next, "failed")}."
}

///|
pub async fn save_book_template_request_ledger(
  request_path : String,
  ledger : BookTemplateRequestLedger,
) -> Unit {
  write_text_file(request_path, ledger.to_json().stringify(indent=2))
}

///|
pub async fn install_book_template_config(
  template_id : String,
  config_path : String,
  registry_path? : String = default_book_template_registry_path(),
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  standing_goal_path? : String = @storage.default_standing_goal_path(),
) -> String {
  let registry = inspect_book_template_registry(registry_path~)
  match find_book_template_descriptor(registry.templates, template_id) {
    Some(template) =>
      match template.template_id {
        "pdf-evidence-watch" =>
          install_pdf_evidence_watch_book_config(
            config_path,
            book_catalog_path~,
            standing_goal_path~,
          )
        _ =>
          "Book template `\{template_id}` is registered but has no installer yet."
      }
    None => "Unknown book template: \{template_id}"
  }
}

///|
async fn load_book_template_request_ledger(
  request_path : String,
) -> BookTemplateRequestLedger {
  if !@fs.exists(request_path) {
    return { requests: [] }
  }
  let text = @fs.read_file(request_path).text() catch {
    _ => return { requests: [] }
  }
  let parsed = @json.parse(text) catch { _ => return { requests: [] } }
  @json.from_json(parsed) catch {
    _ => { requests: [] }
  }
}

///|
async fn latest_book_template_request_event_summary(
  event_path : String,
) -> String {
  if !@fs.exists(event_path) {
    return "none"
  }
  let text = @fs.read_file(event_path).text() catch { _ => return "none" }
  let mut latest = ""
  for line in text.split("\n") {
    let trimmed = line.trim()
    if !trimmed.is_empty() {
      latest = trimmed.to_owned()
    }
  }
  if latest.is_empty() {
    return "none"
  }
  let parsed = @json.parse(latest) catch { _ => return latest }
  let event : BookTemplateRequestEvent = @json.from_json(parsed) catch {
    _ => return latest
  }
  "\{event.status}: `\{event.request_id}` tick=\{event.tick}"
}

///|
async fn append_book_template_request_event(
  event_path : String,
  event : BookTemplateRequestEvent,
) -> Unit {
  let existing = read_text_or_empty(event_path)
  let line = event.to_json().stringify()
  let content = if existing == "" {
    "\{line}\n"
  } else {
    "\{existing.trim_end()}\n\{line}\n"
  }
  write_text_file(event_path, content)
}

///|
async fn load_book_template_request_event_request_ids(
  event_path : String,
) -> Array[String] {
  let ids : Array[String] = []
  if !@fs.exists(event_path) {
    return ids
  }
  let text = @fs.read_file(event_path).text() catch { _ => return ids }
  for line in text.split("\n") {
    let trimmed = line.trim()
    if trimmed.is_empty() {
      continue
    }
    let parsed = @json.parse(trimmed.to_owned()) catch { _ => continue }
    let event : BookTemplateRequestEvent = @json.from_json(parsed) catch {
      _ => continue
    }
    if !ids.contains(event.request_id) {
      ids.push(event.request_id)
    }
  }
  ids
}

///|
async fn load_book_template_registry_file(
  registry_path : String,
) -> Array[BookTemplateDescriptor] {
  if !@fs.exists(registry_path) {
    return []
  }
  let text = @fs.read_file(registry_path).text() catch { _ => return [] }
  let parsed = @json.parse(text) catch { _ => return [] }
  let registry : BookTemplateRegistryFile = @json.from_json(parsed) catch {
    _ => return []
  }
  registry.templates
}

///|
fn count_book_template_requests_by_status(
  ledger : BookTemplateRequestLedger,
  status : String,
) -> Int {
  let mut count = 0
  for request in ledger.requests {
    if request.status == status {
      count += 1
    }
  }
  count
}

///|
fn book_template_install_summary_success(summary : String) -> Bool {
  summary.contains("Installed PDF Evidence Watch config") ||
  summary.contains("Bootstrapped PDF Evidence Watch book")
}

///|
fn resolve_book_template_request_path(
  base_dir : String,
  path : String,
) -> String {
  if path.has_prefix("/") || base_dir == "." || base_dir == "" {
    path
  } else {
    "\{base_dir}/\{path}"
  }
}

///|
fn find_book_template_descriptor(
  templates : Array[BookTemplateDescriptor],
  template_id : String,
) -> BookTemplateDescriptor? {
  for template in templates {
    if template.template_id == template_id {
      return Some(template)
    }
  }
  None
}
