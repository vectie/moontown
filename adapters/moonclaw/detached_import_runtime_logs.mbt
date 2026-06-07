///|
fn detached_import_text_is_only_runtime_event_logs(text : String) -> Bool {
  let mut saw_log = false
  for raw in text.split("\n") {
    let line = raw.trim()
    if line.is_empty() {
      continue
    }
    let parsed = @json.parse(line) catch { _ => return false }
    if !json_looks_like_moonclaw_runtime_log(parsed) {
      return false
    }
    if json_runtime_log_has_terminal_failure_signal(parsed) {
      return false
    }
    saw_log = true
  }
  saw_log
}

///|
fn json_looks_like_moonclaw_runtime_log(json : Json) -> Bool {
  match json {
    Object(object) =>
      object.get("level") is Some(_) &&
      object.get("msg") is Some(_) &&
      object.get("tag") is Some(_)
    _ => false
  }
}

///|
fn json_runtime_log_has_terminal_failure_signal(json : Json) -> Bool {
  match parse_json_string(json, "msg") {
    Some(message) =>
      detached_import_text_has_terminal_failure_signal(message.to_lower())
    None => false
  }
}
