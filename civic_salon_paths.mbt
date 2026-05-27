///|
pub fn default_civic_salon_schedule_path(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  "\{civic_salon_base_dir(snapshot_path)}/salons.json"
}

///|
pub fn default_civic_salon_run_ledger_path(
  salon_id : String,
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  "\{civic_salon_base_dir(snapshot_path)}/salon-runs/\{safe_salon_id(salon_id)}.jsonl"
}

///|
pub fn civic_salon_scenario_path(
  salon_id : String,
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  "\{civic_salon_base_dir(snapshot_path)}/salon-scenarios/\{safe_salon_id(salon_id)}.json"
}

///|
fn civic_salon_base_dir(snapshot_path : String) -> String {
  let base = @path.Path::dirname(snapshot_path).to_string()
  if base == "." || base == "" {
    ".moontown/civic"
  } else {
    "\{base}/civic"
  }
}

///|
fn safe_salon_id(id : String) -> String {
  let builder = StringBuilder::new()
  for ch in id {
    if (ch >= 'a' && ch <= 'z') ||
      (ch >= 'A' && ch <= 'Z') ||
      (ch >= '0' && ch <= '9') ||
      ch == '-' ||
      ch == '_' {
      builder.write_char(ch)
    } else {
      builder.write_char('-')
    }
  }
  builder.to_string()
}

///|
fn civic_salon_protocol_ledger_path(
  building_id : String,
  ledger : String,
) -> String {
  ".moontown/civic/protocols/\{building_id}/\{ledger}.jsonl"
}

///|
fn civic_salon_projection_path(
  schedule : CivicSalonSchedule,
  snapshot_path : String,
) -> String {
  let book_id = match
    @civic.wenyu_building_protocol_for_building_id(schedule.building_id) {
    Some(protocol) => protocol.book_id
    None => schedule.building_id
  }
  "\{civic_salon_workspace_base(snapshot_path)}/books/\{book_id}/book/moonbook-ui-state.json"
}

///|
fn civic_salon_workspace_base(snapshot_path : String) -> String {
  let base = @path.Path::dirname(snapshot_path).to_string()
  if base == "." || base == "" {
    ".moontown"
  } else {
    base
  }
}
