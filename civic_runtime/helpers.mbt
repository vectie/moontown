///|
fn optional_env_text(key : String) -> String? {
  match @sys.get_env_var(key) {
    Some(value) => {
      let trimmed = value.trim().to_owned()
      if trimmed.is_empty() {
        None
      } else {
        Some(trimmed)
      }
    }
    None => None
  }
}

///|
fn parse_non_negative_seconds(text : String, fallback~ : Int) -> Int {
  let mut seen = false
  let mut value = 0
  for char in text.trim() {
    if char >= '0' && char <= '9' {
      value = value * 10 + (char.to_int() - '0'.to_int())
      seen = true
    } else {
      return fallback
    }
  }
  if seen {
    value
  } else {
    fallback
  }
}

///|
fn first_non_negative_int(text : String) -> Int? {
  let mut seen = false
  let mut value = 0
  for char in text.trim() {
    if char >= '0' && char <= '9' {
      value = value * 10 + (char.to_int() - '0'.to_int())
      seen = true
    } else if seen {
      return Some(value)
    }
  }
  if seen {
    Some(value)
  } else {
    None
  }
}

///|
fn civic_marker_value(
  summary : String,
  key : String,
  fallback~ : String,
) -> String {
  let lower_key = key.to_lower()
  let key_colon = "\{lower_key}:"
  let key_equals = "\{lower_key}="
  for raw in summary.split("\n") {
    let line = raw.trim().to_owned()
    let lower = line.to_lower()
    if lower.has_prefix(key_colon) {
      return line[key_colon.length():].trim(chars=" `").to_owned()
    } else if lower.has_prefix(key_equals) {
      return line[key_equals.length():].trim(chars=" `").to_owned()
    }
  }
  fallback
}

///|
fn civic_marker_int(summary : String, key : String, fallback~ : Int) -> Int {
  let value = civic_marker_value(summary, key, fallback="")
  match first_non_negative_int(value) {
    Some(parsed) => parsed
    None => fallback
  }
}

///|
fn civic_workspace_target_page(path : String) -> String {
  if path.has_prefix("wiki/") {
    path[5:].to_owned()
  } else {
    path
  }
}
