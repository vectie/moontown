///|
async fn civic_protocol_history(
  building_id : String,
) -> Array[ProtocolHistoryEntry] {
  let entries : Array[ProtocolHistoryEntry] = []
  match
    protocol_history_entry(
      building_id,
      "inbox",
      "Inbox",
      protocol_ledger_path(building_id, "inbox"),
    ) {
    Some(entry) => entries.push(entry)
    None => ()
  }
  match
    protocol_history_entry(
      building_id,
      "reduction",
      "Reduction",
      protocol_ledger_path(building_id, "reductions"),
    ) {
    Some(entry) => entries.push(entry)
    None => ()
  }
  match
    protocol_history_entry(
      building_id,
      "review",
      "Review",
      protocol_ledger_path(building_id, "reviews"),
    ) {
    Some(entry) => entries.push(entry)
    None => ()
  }
  match
    protocol_history_entry(
      building_id,
      "accepted-result",
      "Accepted Result",
      protocol_ledger_path(building_id, "reductions"),
    ) {
    Some(entry) => entries.push(entry)
    None => ()
  }
  match
    protocol_history_entry(
      building_id,
      "outbox",
      "Outbox",
      protocol_ledger_path(building_id, "outbox"),
    ) {
    Some(entry) => entries.push(entry)
    None => ()
  }
  entries
}

///|
fn civic_protocol_history_state(
  protocol_status : String,
  history : Array[ProtocolHistoryEntry],
) -> String {
  if !history.is_empty() {
    "ready"
  } else if protocol_status == "defined" {
    "no-events-yet"
  } else {
    "invalid-or-missing"
  }
}

///|
async fn protocol_history_entry(
  building_id : String,
  step : String,
  title : String,
  evidence_ref : String,
) -> ProtocolHistoryEntry? {
  match
    latest_protocol_json_line(building_id, protocol_history_ledger_name(step)) {
    Some(line) =>
      protocol_history_entry_from_line(step, title, line, evidence_ref)
    None => None
  }
}

///|
fn protocol_history_ledger_name(step : String) -> String {
  match step {
    "inbox" => "inbox"
    "reduction" => "reductions"
    "review" => "reviews"
    "accepted-result" => "reductions"
    "outbox" => "outbox"
    _ => step
  }
}
