///|
fn civic_binding_key(text : String) -> String {
  let stripped = strip_prefix(strip_prefix(text, "book-"), "wenyu-")
  stripped.to_lower()
}

///|
fn civic_persistence_mode(module_mode : String) -> String {
  match module_mode {
    "agent-workspace" => "workspace-backed"
    "exchange-place" => "ledger-backed"
    "projection-surface" => "projection-backed"
    "gateway" => "handoff-ledger-backed"
    "hybrid" => "mixed-memory-backed"
    _ => "support-backed"
  }
}

///|
fn strip_prefix(text : String, prefix : String) -> String {
  if text.length() >= prefix.length() &&
    text[:prefix.length()].to_owned() == prefix {
    text[prefix.length():].to_owned()
  } else {
    text
  }
}

///|
fn unique_strings(values : Array[String]) -> Array[String] {
  let result : Array[String] = []
  for value in values {
    if !result.contains(value) {
      result.push(value)
    }
  }
  result
}

///|
fn bullet_lines(values : Array[String]) -> String {
  let builder = StringBuilder::new()
  for value in values {
    builder.write_string("- ")
    builder.write_string(value)
    builder.write_char('\n')
  }
  builder.to_string().trim().to_owned()
}
