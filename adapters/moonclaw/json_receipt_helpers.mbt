///|
fn parse_json_string(json : Json, key : String) -> String? {
  match json {
    Object(object) =>
      match object.get(key) {
        Some(String(value)) => Some(value)
        _ => None
      }
    _ => None
  }
}

///|
fn parse_json_bool(json : Json, key : String) -> Bool? {
  match json {
    Object(object) =>
      match object.get(key) {
        Some(True) => Some(true)
        Some(False) => Some(false)
        _ => None
      }
    _ => None
  }
}

///|
fn parse_json_from_command_text(text : String) -> Json raise {
  let trimmed = text.trim().to_owned()
  let whole = @json.parse(trimmed) catch {
    _ => {
      let lines = trimmed.split("\n").to_array()
      let count = lines.length()
      for offset in 0..<count {
        let start = count - offset - 1
        let line = lines[start].trim().to_owned()
        if line.has_prefix("{") || line.has_prefix("[") {
          let builder = StringBuilder::new()
          for index in start..<count {
            if index > start {
              builder.write_char('\n')
            }
            builder.write_string(lines[index].to_owned())
          }
          let candidate = builder.to_string()
          let parsed = @json.parse(candidate) catch { _ => continue }
          if json_looks_like_import_receipt(parsed) {
            return parsed
          }
          let single = @json.parse(line) catch { _ => continue }
          if json_looks_like_import_receipt(single) {
            return single
          }
        }
      }
      raise Failure::Failure("Expected JSON output in command text.")
    }
  }
  if json_looks_like_import_receipt(whole) {
    whole
  } else {
    raise Failure::Failure("Expected MoonClaw import receipt JSON.")
  }
}

///|
fn json_looks_like_import_receipt(json : Json) -> Bool {
  match json {
    Object(object) =>
      object.get("proposal_id") is Some(_) ||
      object.get("run_id") is Some(_) ||
      object.get("status") is Some(_)
    _ => false
  }
}
