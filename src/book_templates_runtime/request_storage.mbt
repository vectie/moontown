///|
pub async fn save_request_ledger(
  request_path : String,
  ledger : @book_templates.BookTemplateRequestLedger,
) -> Unit {
  write_text_file(request_path, ledger.to_json().stringify(indent=2))
}

///|
pub async fn load_request_ledger(
  request_path : String,
) -> @book_templates.BookTemplateRequestLedger {
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
pub async fn latest_request_event_summary(event_path : String) -> String {
  @book_templates.latest_request_event_summary_from_lines(
    load_request_event_lines(event_path),
  )
}

///|
pub async fn append_request_event(
  event_path : String,
  event : @book_templates.BookTemplateRequestEvent,
) -> Unit {
  write_text_file(
    event_path,
    @book_templates.append_request_event_text(
      read_text_or_empty(event_path),
      event,
    ),
  )
}

///|
pub async fn load_request_event_request_ids(
  event_path : String,
) -> Array[String] {
  @book_templates.request_event_request_ids_from_lines(
    load_request_event_lines(event_path),
  )
}

///|
pub async fn load_request_event_lines(event_path : String) -> Array[String] {
  let lines : Array[String] = []
  if !@fs.exists(event_path) {
    return lines
  }
  let text = @fs.read_file(event_path).text() catch { _ => return lines }
  @book_templates.request_event_lines_from_text(text)
}

///|
async fn read_text_or_empty(path : String) -> String {
  if !@fs.exists(path) {
    return ""
  }
  @fs.read_file(path).text() catch {
    _ => ""
  }
}

///|
async fn write_text_file(path : String, content : String) -> Unit {
  ensure_parent_directory(path)
  @fs.write_file(
    path,
    @encoding/utf8.encode(content),
    create=0o644,
    truncate=true,
  )
}

///|
async fn ensure_parent_directory(path : String) -> Unit {
  let parent = @path.Path::dirname(path).to_string()
  if parent == "." || parent == "" || @fs.exists(parent) {
    return
  }
  ensure_parent_directory(parent)
  @fs.mkdir(parent, permission=0o755) catch {
    _ => ()
  }
}
