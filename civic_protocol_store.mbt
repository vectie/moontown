///|
async fn write_protocol_jsonl_record(
  building_id : String,
  ledger : String,
  value : Json,
  ledger_base_dir? : String = default_protocol_ledger_base_dir(),
) -> Unit {
  write_text_file(
    protocol_ledger_path(building_id, ledger, ledger_base_dir~),
    value.stringify() + "\n",
  )
}

///|
async fn write_protocol_jsonl_records(
  building_id : String,
  ledger : String,
  values : Array[Json],
  ledger_base_dir? : String = default_protocol_ledger_base_dir(),
) -> Unit {
  let builder = StringBuilder::new()
  for value in values {
    builder.write_string(value.stringify())
    builder.write_char('\n')
  }
  write_text_file(
    protocol_ledger_path(building_id, ledger, ledger_base_dir~),
    builder.to_string(),
  )
}

///|
async fn count_protocol_jsonl_records(
  building_id : String,
  ledger : String,
  ledger_base_dir? : String = default_protocol_ledger_base_dir(),
) -> Int {
  let text = read_text_or_empty(
    protocol_ledger_path(building_id, ledger, ledger_base_dir~),
  )
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
  ledger_base_dir? : String = default_protocol_ledger_base_dir(),
) -> @civic.BuildingReductionResult? {
  match latest_protocol_json_line(building_id, "reductions", ledger_base_dir~) {
    Some(line) =>
      Some(@json.from_json(@json.parse(line)) catch { _ => return None })
    None => None
  }
}

///|
async fn latest_protocol_reduction_summary(
  building_id : String,
  ledger_base_dir? : String = default_protocol_ledger_base_dir(),
) -> String {
  match latest_protocol_reduction(building_id, ledger_base_dir~) {
    Some(result) =>
      if result.summary.trim().is_empty() {
        latest_protocol_json_string_field(
          building_id,
          "reductions",
          "summary",
          ledger_base_dir~,
        )
      } else {
        result.summary
      }
    None =>
      latest_protocol_json_string_field(
        building_id,
        "reductions",
        "summary",
        ledger_base_dir~,
      )
  }
}

///|
async fn latest_protocol_distribution(
  building_id : String,
  ledger_base_dir? : String = default_protocol_ledger_base_dir(),
) -> @civic.BuildingDistributionRecord? {
  match latest_protocol_json_line(building_id, "outbox", ledger_base_dir~) {
    Some(line) =>
      Some(@json.from_json(@json.parse(line)) catch { _ => return None })
    None => None
  }
}

///|
async fn latest_protocol_distribution_summary(
  building_id : String,
  ledger_base_dir? : String = default_protocol_ledger_base_dir(),
) -> String {
  match latest_protocol_distribution(building_id, ledger_base_dir~) {
    Some(record) =>
      if record.summary.trim().is_empty() {
        latest_protocol_json_string_field(
          building_id,
          "outbox",
          "summary",
          ledger_base_dir~,
        )
      } else {
        record.summary
      }
    None =>
      latest_protocol_json_string_field(
        building_id,
        "outbox",
        "summary",
        ledger_base_dir~,
      )
  }
}

///|
async fn latest_protocol_json_line(
  building_id : String,
  ledger : String,
  ledger_base_dir? : String = default_protocol_ledger_base_dir(),
) -> String? {
  let text = read_text_or_empty(
    protocol_ledger_path(building_id, ledger, ledger_base_dir~),
  )
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
async fn latest_protocol_json_string_field(
  building_id : String,
  ledger : String,
  field : String,
  ledger_base_dir? : String = default_protocol_ledger_base_dir(),
) -> String {
  let text = read_text_or_empty(
    protocol_ledger_path(building_id, ledger, ledger_base_dir~),
  )
  let mut latest = ""
  for raw in text.split("\n") {
    let line = raw.trim().to_owned()
    if !line.is_empty() {
      let parsed = @json.parse(line) catch { _ => continue }
      match parsed {
        Object(map) =>
          match map.get(field) {
            Some(String(value)) =>
              if !value.trim().is_empty() {
                latest = value
              }
            _ => ()
          }
        _ => ()
      }
    }
  }
  latest
}

///|
fn protocol_contract_path(
  building_id : String,
  ledger_base_dir? : String = default_protocol_ledger_base_dir(),
) -> String {
  "\{protocol_ledger_dir(building_id, ledger_base_dir~)}/PROTOCOL.md"
}

///|
fn protocol_ledger_path(
  building_id : String,
  ledger : String,
  ledger_base_dir? : String = default_protocol_ledger_base_dir(),
) -> String {
  "\{protocol_ledger_dir(building_id, ledger_base_dir~)}/\{ledger}.jsonl"
}

///|
fn protocol_ledger_dir(
  building_id : String,
  ledger_base_dir? : String = default_protocol_ledger_base_dir(),
) -> String {
  "\{ledger_base_dir}/\{building_id}"
}

///|
fn default_protocol_ledger_base_dir() -> String {
  ".moontown/civic/protocols"
}

///|
fn protocol_ledger_base_dir_for_status_path(status_path : String) -> String {
  let parent = @path.Path::dirname(status_path).to_string()
  if parent.is_empty() || parent == "." {
    "protocols"
  } else {
    "\{parent}/protocols"
  }
}

///|
fn protocol_status_markdown_path(status_path : String) -> String {
  if status_path.has_suffix(".json") {
    status_path[:status_path.length() - 5].to_owned() + ".md"
  } else {
    status_path + ".md"
  }
}
