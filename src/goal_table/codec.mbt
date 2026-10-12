///|
fn headers() -> Array[String] {
  [
    "id_json", "title_json", "prompt_json", "target_book_id_json", "cadence_ticks",
    "next_due_tick", "last_run_tick", "enabled", "source_policy_json", "quality_threshold",
  ]
}

///|
fn source_text(bytes : Bytes) -> String raise {
  guard bytes.length() <= 1048576 else { fail("Input exceeds 1 MiB") }
  @utf8.decode(bytes) catch {
    _ => fail("Input must be lossless UTF-8")
  }
}

///|
fn bounded_output(text : String) -> String raise {
  guard @utf8.encode(text).length() <= 1048576 else {
    fail("Output exceeds 1 MiB; split the goal selection before converting")
  }
  text
}

///|
fn check_goals(goals : Array[@core.StandingGoal]) -> Unit raise {
  guard goals.length() <= 2000 else {
    fail("At most 2,000 goals are supported")
  }
  let seen : Map[String, Bool] = Map([])
  for i, goal in goals {
    guard !goal.id.trim().is_empty() else {
      fail("Goal " + (i + 1).to_string() + " has a blank ID")
    }
    guard !seen.contains(goal.id) else {
      fail(
        "Goal " + (i + 1).to_string() + " duplicates an exact ID: " + goal.id,
      )
    }
    seen[goal.id] = true
  }
}

///|
fn snapshot_goals(bytes : Bytes) -> Array[@core.StandingGoal] raise {
  let parsed = @json.parse(source_text(bytes))
  guard parsed is Array(items) else {
    fail("Snapshot must be an array of StandingGoals")
  }
  let fields = [
    "id", "title", "prompt", "target_book_id", "cadence_ticks", "next_due_tick",
    "last_run_tick", "enabled", "source_policy", "quality_threshold",
  ]
  for i, item in items {
    guard item is Object(values) else {
      fail("Goal " + (i + 1).to_string() + " must be an object")
    }
    // The shared decoder converts JSON numbers to Int. Require exact integers
    // first, so a fractional or overflowing snapshot cannot silently change.
    for
      key in [
        "cadence_ticks", "next_due_tick", "quality_threshold", "last_run_tick",
      ] {
      match values.get(key) {
        Some(Number(n)) => {
          guard n >= -2147483648.0 &&
            n <= 2147483647.0 &&
            n == n.to_int().to_double() else {
            fail(
              "Goal " +
              (i + 1).to_string() +
              ": " +
              key +
              " must be an exact signed 32-bit integer",
            )
          }
        }
        _ => () // The canonical decoder enforces required and optional types.
      }
    }
    for key, _ in values {
      guard fields.contains(key) else {
        fail(
          "Goal " +
          (i + 1).to_string() +
          " has an unknown field that would be lost: " +
          key,
        )
      }
    }
  }
  let goals : Array[@core.StandingGoal] = @json.from_json(parsed)
  check_goals(goals)
  goals
}

///|
fn quoted_cell(text : String) -> String {
  "\"" + text.replace_all(old="\"", new="\"\"") + "\""
}

///|
fn text_cell(value : String) -> String {
  value.to_json().stringify()
}

///|
fn optional_text_cell(value : String?) -> String {
  match value {
    Some(text) => text_cell(text)
    None => "null"
  }
}

///|
fn optional_int_cell(value : Int?) -> String {
  match value {
    Some(number) => number.to_string()
    None => "null"
  }
}

///|
fn string_value(text : String) -> String raise {
  match @json.parse(text) {
    String(value) => value
    _ =>
      fail("Text cells must contain a JSON string, including its double quotes")
  }
}

///|
fn optional_string_value(text : String) -> String? raise {
  match @json.parse(text) {
    Null => None
    String(value) => Some(value)
    _ => fail("Target Book must be a JSON string or null")
  }
}

///|
fn int_value(text : String) -> Int raise {
  let digits = if text.has_prefix("-") { text[1:].to_owned() } else { text }
  guard !digits.is_empty() && digits.iter().all(c => c >= '0' && c <= '9') else {
    fail(
      "Ticks and quality must be signed 32-bit decimal integers (no spaces, plus signs or fractions)",
    )
  }
  @string.parse_int(text) catch {
    _ => fail("Integer is outside signed 32-bit range")
  }
}

///|
fn optional_int_value(text : String) -> Int? raise {
  if text == "null" {
    None
  } else {
    Some(int_value(text))
  }
}

///|
fn row_goal(row : Array[String]) -> @core.StandingGoal raise {
  let enabled = match row[7] {
    "true" => true
    "false" => false
    _ => fail("enabled must be exactly true or false")
  }
  @core.StandingGoal::new(
    id=string_value(row[0]),
    title=string_value(row[1]),
    prompt=string_value(row[2]),
    target_book_id=optional_string_value(row[3]),
    cadence_ticks=int_value(row[4]),
    next_due_tick=int_value(row[5]),
    last_run_tick=optional_int_value(row[6]),
    enabled~,
    source_policy=string_value(row[8]),
    quality_threshold=int_value(row[9]),
  )
}
