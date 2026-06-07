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
