///|
pub struct MoonCodeBookResultImport {
  key : String
  session_id : String
  command_id : String
  result_id : String
  summary : String
  artifacts : Array[String]
  review_queued : Bool
  notify_town : Bool
  evidence_id : String
  updated_pages : Array[String]
  executable_event_path : String
  latest_executable_event_path : String
  executable_event : @moonbook_contracts.ExecutableBookEvent
} derive(Debug, Eq, ToJson, FromJson)

///|
fn mooncode_book_results_sessions_root(book_root : String) -> String {
  "\{book_root}/.moonclaw/mooncode/sessions"
}

///|
fn mooncode_book_results_processed_ledger(entry : BookCatalogEntry) -> String {
  @storage.moontown_product_artifact(
    "mooncode-book-results/\{safe_mooncode_book_result_id(entry.id)}/processed.jsonl",
  )
}

///|
fn safe_mooncode_book_result_id(book_id : String) -> String {
  let builder = StringBuilder::new()
  for ch in book_id {
    if (ch >= 'a' && ch <= 'z') ||
      (ch >= 'A' && ch <= 'Z') ||
      (ch >= '0' && ch <= '9') ||
      ch == '-' ||
      ch == '_' {
      builder.write_char(ch)
    } else {
      builder.write_char('-')
    }
  }
  let safe = builder.to_string().trim(chars="-").to_owned()
  if safe.is_empty() {
    "book"
  } else {
    safe
  }
}

///|
pub async fn reconcile_mooncode_book_result_sidecars(
  entry : BookCatalogEntry,
  moonbook_root? : String = default_moonbook_root(),
) -> Array[MoonCodeBookResultImport] {
  let root = resolved_workspace_root(entry.workspace_root)
  let sessions_root = mooncode_book_results_sessions_root(root)
  if !@fs.exists(sessions_root) {
    return []
  }
  let ledger_path = mooncode_book_results_processed_ledger(entry)
  let processed = read_mooncode_book_result_processed_keys(ledger_path)
  let imports : Array[MoonCodeBookResultImport] = []
  for session_dir in @support.list_directory_paths(sessions_root) {
    let session_id = @support.path_basename(session_dir)
    let log_path = "\{session_dir}/book-results.jsonl"
    let log_text = @support.read_optional_text(log_path).unwrap_or("")
    if log_text.trim().is_empty() {
      continue
    }
    for raw in log_text.split("\n") {
      let line = raw.trim()
      if line.is_empty() {
        continue
      }
      let payload = @json.parse(line) catch { _ => continue }
      let result = match decode_book_result_payload(payload) {
        Some(result) => result
        None => continue
      }
      let command_id = mooncode_sidecar_string(payload, "command_id").unwrap_or(
        result.result_id,
      )
      let key = mooncode_book_result_processed_key(
        payload,
        session_id,
        command_id,
        result.result_id,
      )
      if processed.contains(key) {
        continue
      }
      let outcome = persist_result_payload(entry, payload, moonbook_root~)
      processed.push(key)
      write_mooncode_book_result_processed_keys(ledger_path, processed)
      imports.push({
        key,
        session_id,
        command_id,
        result_id: result.result_id,
        summary: result.summary,
        artifacts: result.artifacts,
        review_queued: outcome.review_queued,
        notify_town: outcome.notify_town,
        evidence_id: outcome.evidence_id,
        updated_pages: outcome.updated_pages,
        executable_event_path: outcome.executable_event_path,
        latest_executable_event_path: outcome.latest_executable_event_path,
        executable_event: outcome.executable_event,
      })
    }
  }
  imports
}

///|
async fn read_mooncode_book_result_processed_keys(
  path : String,
) -> Array[String] {
  let keys : Array[String] = []
  let content = @support.read_text_or_empty(path)
  for raw in content.split("\n") {
    let key = raw.trim().to_owned()
    if !key.is_empty() && !keys.contains(key) {
      keys.push(key)
    }
  }
  keys
}

///|
async fn write_mooncode_book_result_processed_keys(
  path : String,
  keys : Array[String],
) -> Unit {
  @support.write_text_file(path, keys.join("\n") + "\n")
}

///|
fn mooncode_book_result_processed_key(
  payload : Json,
  session_id : String,
  command_id : String,
  task_id : String,
) -> String {
  mooncode_sidecar_string(payload, "result_path").unwrap_or(
    "\{session_id}:\{command_id}:\{task_id}",
  )
}

///|
fn mooncode_sidecar_string(payload : Json, field : String) -> String? {
  match payload {
    Object(fields) =>
      match fields.get(field) {
        Some(String(value)) => Some(value)
        _ => None
      }
    _ => None
  }
}
