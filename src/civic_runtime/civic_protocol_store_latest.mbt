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
pub async fn latest_protocol_json_line(
  building_id : String,
  ledger : String,
  ledger_base_dir? : String = default_protocol_ledger_base_dir(),
) -> String? {
  let text = @support.read_text_or_empty(
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
  let text = @support.read_text_or_empty(
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
