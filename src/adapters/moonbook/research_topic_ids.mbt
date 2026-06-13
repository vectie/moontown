///|
fn normalize_topic_id(topic : String) -> String {
  let normalized = topic.to_lower().trim().to_owned()
  match normalized {
    "moontown" => "moontown"
    "moonbook" => "moonbook"
    "moonclaw" => "moonclaw"
    "finance" => "finance"
    "coding" => "coding"
    _ => compact_topic_segment(normalized)
  }
}

///|
fn strip_research_attempt_suffix(topic : String) -> String {
  let cleaned = topic.to_lower().trim().to_owned()
  let parts = cleaned.split("-").to_array()
  if parts.length() < 2 {
    return cleaned
  }
  let last = parts[parts.length() - 1].to_owned()
  if !(last.length() > 1 &&
    last[0] == 'v' &&
    string_is_digits(last[1:].to_owned())) {
    return cleaned
  }
  let builder = StringBuilder::new()
  for index in 0..<(parts.length() - 1) {
    if index > 0 {
      builder.write_char('-')
    }
    builder.write_string(parts[index].to_owned())
  }
  builder.to_string()
}

///|
fn string_is_digits(text : String) -> Bool {
  if text.is_empty() {
    return false
  }
  for char in text {
    if char < '0' || char > '9' {
      return false
    }
  }
  true
}

///|
fn compact_topic_segment(text : String) -> String {
  let builder = StringBuilder::new()
  let mut last_dash = false
  for char in text.to_lower() {
    if (char >= 'a' && char <= 'z') || (char >= '0' && char <= '9') {
      builder.write_char(char)
      last_dash = false
    } else if !last_dash {
      builder.write_char('-')
      last_dash = true
    }
  }
  builder.to_string().trim(chars="-").to_owned()
}

///|
fn display_topic_name(topic : String) -> String {
  match topic {
    "moontown" => "Moontown"
    "moonbook" => "MoonBook"
    "moonclaw" => "MoonClaw"
    "finance" => "Finance"
    "coding" => "Coding"
    "opc" => "One Person Company (OPC)"
    _ => topic_id_to_words(topic)
  }
}

///|
fn topic_id_to_words(topic : String) -> String {
  let builder = StringBuilder::new()
  for char in topic {
    if char == '-' {
      builder.write_char(' ')
    } else {
      builder.write_char(char)
    }
  }
  builder.to_string()
}
