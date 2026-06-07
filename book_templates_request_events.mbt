///|
async fn latest_book_template_request_event_summary(
  event_path : String,
) -> String {
  let lines = load_book_template_request_event_lines(event_path)
  match lines {
    [] => "none"
    _ => {
      let latest = lines[lines.length() - 1]
      match decode_book_template_request_event(latest) {
        Some(event) => book_template_request_event_summary(event)
        None => latest
      }
    }
  }
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
  for line in load_book_template_request_event_lines(event_path) {
    match decode_book_template_request_event(line) {
      Some(event) =>
        if !ids.contains(event.request_id) {
          ids.push(event.request_id)
        }
      None => ()
    }
  }
  ids
}

///|
async fn load_book_template_request_event_lines(
  event_path : String,
) -> Array[String] {
  let lines : Array[String] = []
  if !@fs.exists(event_path) {
    return lines
  }
  let text = @fs.read_file(event_path).text() catch { _ => return lines }
  for line in text.split("\n") {
    let trimmed = line.trim()
    if !trimmed.is_empty() {
      lines.push(trimmed.to_owned())
    }
  }
  lines
}

///|
fn decode_book_template_request_event(
  line : String,
) -> BookTemplateRequestEvent? {
  let parsed = @json.parse(line) catch { _ => return None }
  Some(@json.from_json(parsed)) catch {
    _ => None
  }
}

///|
fn book_template_request_event_summary(
  event : BookTemplateRequestEvent,
) -> String {
  "\{event.status}: `\{event.request_id}` tick=\{event.tick}"
}
