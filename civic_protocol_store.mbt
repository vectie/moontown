///|
async fn write_protocol_jsonl_record(
  building_id : String,
  ledger : String,
  value : Json,
) -> Unit {
  write_text_file(
    protocol_ledger_path(building_id, ledger),
    value.stringify() + "\n",
  )
}

///|
async fn write_protocol_jsonl_records(
  building_id : String,
  ledger : String,
  values : Array[Json],
) -> Unit {
  let builder = StringBuilder::new()
  for value in values {
    builder.write_string(value.stringify())
    builder.write_char('\n')
  }
  write_text_file(
    protocol_ledger_path(building_id, ledger),
    builder.to_string(),
  )
}

///|
async fn count_protocol_jsonl_records(
  building_id : String,
  ledger : String,
) -> Int {
  let text = read_text_or_empty(protocol_ledger_path(building_id, ledger))
  let mut count = 0
  for raw in text.split("\n") {
    if !raw.trim().is_empty() {
      count += 1
    }
  }
  count
}

///|
async fn latest_protocol_reduction(
  building_id : String,
) -> @civic.BuildingReductionResult? {
  match latest_protocol_json_line(building_id, "reductions") {
    Some(line) =>
      Some(@json.from_json(@json.parse(line)) catch { _ => return None })
    None => None
  }
}

///|
async fn latest_protocol_distribution(
  building_id : String,
) -> @civic.BuildingDistributionRecord? {
  match latest_protocol_json_line(building_id, "outbox") {
    Some(line) =>
      Some(@json.from_json(@json.parse(line)) catch { _ => return None })
    None => None
  }
}

///|
async fn latest_protocol_json_line(
  building_id : String,
  ledger : String,
) -> String? {
  let text = read_text_or_empty(protocol_ledger_path(building_id, ledger))
  let mut latest = ""
  for raw in text.split("\n") {
    let line = raw.trim().to_owned()
    if !line.is_empty() {
      latest = line
    }
  }
  if latest.is_empty() {
    None
  } else {
    Some(latest)
  }
}

///|
fn protocol_contract_path(building_id : String) -> String {
  "\{protocol_ledger_dir(building_id)}/PROTOCOL.md"
}

///|
fn protocol_ledger_path(building_id : String, ledger : String) -> String {
  "\{protocol_ledger_dir(building_id)}/\{ledger}.jsonl"
}

///|
fn protocol_ledger_dir(building_id : String) -> String {
  ".moontown/civic/protocols/\{building_id}"
}

///|
fn protocol_status_markdown_path(status_path : String) -> String {
  if status_path.has_suffix(".json") {
    status_path[:status_path.length() - 5].to_owned() + ".md"
  } else {
    status_path + ".md"
  }
}
