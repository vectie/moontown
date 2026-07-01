///|
pub fn default_civic_communication_schedule_path(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  "\{civic_communication_base_dir(snapshot_path)}/pattern-schedules.json"
}

///|
pub fn default_civic_communication_run_ledger_path(
  scenario_id : String,
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  "\{civic_communication_base_dir(snapshot_path)}/pattern-runs/\{safe_scenario_id(scenario_id)}.jsonl"
}

///|
pub fn civic_communication_scenario_path(
  scenario_id : String,
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  "\{civic_communication_base_dir(snapshot_path)}/pattern-scenarios/\{safe_scenario_id(scenario_id)}.json"
}

///|
fn civic_communication_base_dir(snapshot_path : String) -> String {
  "\{@storage.snapshot_base_dir(snapshot_path)}/civic"
}

///|
fn safe_scenario_id(id : String) -> String {
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
fn civic_communication_protocol_ledger_path(
  building_id : String,
  ledger : String,
) -> String {
  "\{@storage.moontown_product_state_dir()}/civic/protocols/\{building_id}/\{ledger}.jsonl"
}

///|
fn civic_communication_projection_path_for_scenario(
  scenario : CivicCommunicationScenario,
  snapshot_path : String,
) -> String {
  "\{civic_communication_workspace_base(snapshot_path)}/books/\{scenario.building_book_id}/book/moonbook-ui-state.json"
}

///|
fn civic_communication_workspace_base(snapshot_path : String) -> String {
  @storage.snapshot_base_dir(snapshot_path)
}
