///|
fn protocol_history_entry_from_line(
  step : String,
  title : String,
  line : String,
  evidence_ref : String,
) -> ProtocolHistoryEntry? {
  let parsed = @json.parse(line) catch { _ => return None }
  match parsed {
    Object(map) => {
      let status = protocol_history_status(step, map)
      let detail = protocol_history_detail(step, map)
      let entry_title = protocol_history_title(title, map)
      Some({ step, status, title: entry_title, detail, evidence_ref })
    }
    _ => None
  }
}

///|
fn protocol_history_status(step : String, map : Map[String, Json]) -> String {
  match step {
    "inbox" => json_object_string(map, "review_status").unwrap_or("received")
    "reduction" =>
      json_object_string(map, "review_status").unwrap_or(
        json_object_string(map, "decision").unwrap_or("reduced"),
      )
    "review" => json_object_string(map, "status").unwrap_or("review")
    "accepted-result" =>
      if json_object_string(map, "review_status") == Some("accepted") {
        "accepted"
      } else {
        "pending"
      }
    "outbox" =>
      json_object_string(map, "review_status").unwrap_or("distributed")
    _ => "unknown"
  }
}

///|
fn protocol_history_title(title : String, map : Map[String, Json]) -> String {
  json_object_string(map, "id").unwrap_or(title)
}

///|
fn protocol_history_detail(step : String, map : Map[String, Json]) -> String {
  match step {
    "accepted-result" =>
      first_non_empty_json_string(
        [map.get("accepted_records"), map.get("summary")],
        "Accepted result record is present.",
      )
    _ =>
      first_non_empty_json_string(
        [map.get("summary"), map.get("reason"), map.get("payload")],
        "Protocol record is present.",
      )
  }
}

///|
fn first_non_empty_json_string(
  values : Array[Json?],
  fallback : String,
) -> String {
  for item in values {
    match item {
      Some(String(value)) if !value.trim().is_empty() => return value
      Some(Array(items)) =>
        for child in items {
          match child {
            String(value) if !value.trim().is_empty() => return value
            _ => ()
          }
        }
      _ => ()
    }
  }
  fallback
}
