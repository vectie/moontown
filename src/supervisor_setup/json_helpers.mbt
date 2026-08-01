///|
fn json_object(fields : Map[String, Json], key : String) -> Map[String, Json] {
  match fields.get(key) {
    Some(Object(value)) => value
    _ => Map([])
  }
}

///|
fn json_string(fields : Map[String, Json], key : String) -> String {
  match fields.get(key) {
    Some(String(value)) => value.trim().to_owned()
    _ => ""
  }
}

///|
fn json_string_alias(
  fields : Map[String, Json],
  camel : String,
  snake : String,
) -> String {
  let direct = json_string(fields, camel)
  if direct.is_empty() {
    json_string(fields, snake)
  } else {
    direct
  }
}

///|
fn json_int_alias(
  fields : Map[String, Json],
  camel : String,
  snake : String,
) -> Int {
  match fields.get(camel) {
    Some(Number(value, ..)) => value.to_int()
    _ =>
      match fields.get(snake) {
        Some(Number(value, ..)) => value.to_int()
        _ => -1
      }
  }
}

///|
fn json_int64_alias(
  fields : Map[String, Json],
  camel : String,
  snake : String,
) -> Int64 {
  match fields.get(camel) {
    Some(Number(value, ..)) => value.to_int64()
    Some(String(value)) => @string.parse_int64(value) catch { _ => -1L }
    _ =>
      match fields.get(snake) {
        Some(Number(value, ..)) => value.to_int64()
        Some(String(value)) => @string.parse_int64(value) catch { _ => -1L }
        _ => -1L
      }
  }
}

///|
fn json_alias_present(
  fields : Map[String, Json],
  camel : String,
  snake : String,
) -> Bool {
  fields.get(camel) is Some(_) || fields.get(snake) is Some(_)
}

///|
fn json_bool_alias(
  fields : Map[String, Json],
  camel : String,
  snake : String,
) -> Bool {
  match fields.get(camel) {
    Some(True) => true
    Some(False) => false
    _ =>
      match fields.get(snake) {
        Some(True) => true
        _ => false
      }
  }
}

///|
fn json_strings_alias(
  fields : Map[String, Json],
  camel : String,
  snake : String,
) -> Array[String] {
  let source = match fields.get(camel) {
    Some(Array(values)) => values
    _ =>
      match fields.get(snake) {
        Some(Array(values)) => values
        _ => []
      }
  }
  let result : Array[String] = []
  for value in source {
    if value is String(text) && !text.trim().is_empty() {
      let item = text.trim().to_owned()
      if !result.contains(item) {
        result.push(item)
      }
    }
  }
  result
}

///|
fn sha256_json(value : Json) -> String {
  let bytes = @utf8.encode(value.stringify())
  "sha256:\{@crypto.bytes_to_hex_string(@crypto.sha256(bytes))}"
}

///|
fn authority_from_id(value : String) -> SupervisorAuthorityCeiling raise {
  match value.to_lower() {
    "suggest" | "suggest_only" => SuggestOnly
    "delegate_bounded" | "delegate_bounded_work" => DelegateBoundedWork
    "request_review" | "request_bookkeeper_review" => RequestBookkeeperReview
    _ =>
      fail(
        "authorityCeiling must be suggest_only, delegate_bounded_work, or request_bookkeeper_review",
      )
  }
}
