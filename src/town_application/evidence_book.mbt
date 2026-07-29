///|
pub async fn RequestApplication::queue_evidence_book(
  self : RequestApplication,
  body : String,
) -> Json {
  let parsed = @json.parse(body)
  let fields = match parsed {
    Object(fields) => fields
    _ => fail("request body must be a JSON object")
  }
  let template_id = {
    let value = json_string_field(fields, "template_id")
    if value.is_empty() {
      "pdf-evidence-watch"
    } else {
      value
    }
  }
  if template_id != "pdf-evidence-watch" {
    fail("unsupported template_id: \{template_id}")
  }
  let title = json_string_field(fields, "title")
  let websites = json_string_list_field(fields, "websites")
  if title.is_empty() || websites.is_empty() {
    fail("title and at least one website are required")
  }
  let book_id = {
    let value = json_string_field(fields, "book_id")
    safe_slug(if value.is_empty() { title } else { value })
  }
  let purpose = {
    let value = json_string_field(fields, "purpose")
    if value.is_empty() {
      "Watch approved websites for relevant PDFs, extract full text, analyze with the book-owned method, and notify only when accepted knowledge changes."
    } else {
      value
    }
  }
  let cadence_ticks = json_int_field(fields, "cadence_ticks", 60, 1, 2147483647)
  let analysis_method = json_string_field(fields, "analysis_method")
  let timestamp = @env.now()
  let request_id = "book-template-\{timestamp}-\{request_nonce()}-\{safe_slug(title)}"
  let config_relative_path = "book-template-configs/\{request_id}.json"
  let config : Json = {
    "book_id": book_id,
    "title": title,
    "purpose": purpose,
    "websites": websites,
    "analysis_method": analysis_method,
    "analysis_method_path": "",
    "cadence_ticks": cadence_ticks,
    "workspace_root": "",
  }
  let request : Json = {
    "id": request_id,
    "template_id": template_id,
    "config_path": config_relative_path,
    "status": "pending",
    "summary": "Queued \{title} for \{template_id}; \{websites.length()} website(s).",
    "last_processed_tick": 0,
  }
  let ledger_path = self.state_root + "/book-template-requests.json"
  let ledger_text = @support.read_text_or_empty(ledger_path)
  let requests : Array[Json] = if ledger_text.trim().is_empty() {
    []
  } else {
    match @json.parse(ledger_text) {
      Object(ledger) =>
        match ledger.get("requests") {
          Some(Array(items)) => items
          _ => []
        }
      _ => []
    }
  }
  requests.push(request)
  @support.write_text_file(
    self.state_root + "/" + config_relative_path,
    config.stringify(indent=2),
  )
  @support.write_text_file(
    ledger_path,
    ({ "requests": requests } : Json).stringify(indent=2),
  )
  {
    "ok": true,
    "request_id": request_id,
    "status": "pending",
    "template_id": template_id,
    "config_path": config_relative_path,
  }
}
