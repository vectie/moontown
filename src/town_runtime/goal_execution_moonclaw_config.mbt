///|
fn moontown_moonclaw_inline_enabled() -> Bool {
  match optional_env_text("MOONTOWN_MOONCLAW_INLINE") {
    Some(value) => {
      let lower = value.to_lower()
      lower == "1" || lower == "true" || lower == "yes" || lower == "on"
    }
    None => false
  }
}

///|
fn external_execution_stale_window_ticks() -> Int {
  30
}

///|
fn moontown_moonclaw_supervision_seconds() -> Int {
  match optional_env_text("MOONTOWN_MOONCLAW_SUPERVISION_SECONDS") {
    Some(value) => parse_non_negative_seconds(value, fallback=0)
    None => 0
  }
}

///|
fn moontown_moonclaw_import_timeout_ms() -> Int {
  match optional_env_text("MOONTOWN_MOONCLAW_IMPORT_TIMEOUT_MS") {
    Some(value) => parse_non_negative_seconds(value, fallback=20_000)
    None => 20_000
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
