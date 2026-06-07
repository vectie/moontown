///|
fn planbook_repair_patch_receipt_contract() -> String {
  "planbook.repair.patch_receipt.v1"
}

///|
fn planbook_repair_patch_receipt_from_payload(payload : Json) -> Json? {
  match payload {
    Object(object) =>
      match object.get("patch_receipt") {
        Some(receipt) => Some(receipt)
        None =>
          match object.get("metadata") {
            Some(Object(metadata)) => metadata.get("patch_receipt")
            _ => None
          }
      }
    _ => None
  }
}

///|
fn planbook_repair_patch_receipt_from_text(text : String) -> Json? {
  let parsed = @json.parse(text.trim().to_owned()) catch {
    _ => return planbook_repair_patch_receipt_block_from_text(text)
  }
  match parsed {
    Object(object) =>
      match object.get("patch_receipt") {
        Some(receipt) => Some(receipt)
        None => Some(parsed)
      }
    _ => None
  }
}

///|
fn planbook_repair_patch_receipt_block_from_text(text : String) -> Json? {
  let lines : Array[String] = []
  for line in text.split("\n") {
    lines.push(line.to_owned())
  }
  for index in 0..<lines.length() {
    if lines[index].trim().to_owned() == "patch_receipt:" {
      let builder = StringBuilder::new()
      for cursor in (index + 1)..<lines.length() {
        if cursor > index + 1 {
          builder.write_char('\n')
        }
        builder.write_string(lines[cursor])
      }
      let parsed = @json.parse(builder.to_string()) catch { _ => return None }
      return Some(parsed)
    }
  }
  None
}

///|
fn planbook_repair_patch_receipt_text(receipt : Json) -> String {
  ["", "patch_receipt:", receipt.stringify(indent=2)].join("\n")
}

///|
fn planbook_repair_result_text_with_patch_receipt(
  content : String,
  payload : Json,
) -> String {
  match planbook_repair_patch_receipt_from_payload(payload) {
    Some(receipt) =>
      if content.contains(planbook_repair_patch_receipt_contract()) {
        content
      } else {
        "\{content.trim().to_owned()}\{planbook_repair_patch_receipt_text(receipt)}"
      }
    None => content
  }
}

///|
fn planbook_json_field(value : Json, key : String) -> Json? {
  match value {
    Object(object) => object.get(key)
    _ => None
  }
}

///|
fn planbook_json_string_field(value : Json, key : String) -> String? {
  match planbook_json_field(value, key) {
    Some(String(text)) => Some(text)
    _ => None
  }
}

///|
fn planbook_json_string_array_field(
  value : Json,
  key : String,
) -> Array[String] {
  match planbook_json_field(value, key) {
    Some(Array(items)) => {
      let result : Array[String] = []
      for item in items {
        match item {
          String(text) => result.push(text)
          Object(object) =>
            match object.get("command") {
              Some(String(command)) => result.push(command)
              _ => ()
            }
          _ => ()
        }
      }
      result
    }
    _ => []
  }
}

///|
fn planbook_repair_receipt_nonblank_field(receipt : Json, key : String) -> Bool {
  match planbook_json_string_field(receipt, key) {
    Some(value) => !value.trim().to_owned().is_blank()
    None => false
  }
}

///|
fn planbook_repair_receipt_required_commands_recorded(receipt : Json) -> Bool {
  let commands = planbook_json_string_array_field(
    receipt, "validation_commands",
  )
  planbook_repair_required_commands().all(fn(required) {
    commands.any(fn(command) { command.contains(required) })
  })
}

///|
fn planbook_repair_result_records_validation_passes(text : String) -> Bool {
  let lowered = text.to_lower()
  planbook_repair_required_commands().all(fn(command) {
    lowered.contains(command.to_lower()) && lowered.contains("passed")
  })
}

///|
fn planbook_repair_patch_receipt_satisfies_contract(
  receipt : Json,
  criterion_id : String,
  source_root : String,
  run_id? : String? = None,
) -> Bool {
  if planbook_json_string_field(receipt, "contract") !=
    Some(planbook_repair_patch_receipt_contract()) {
    return false
  }
  if planbook_json_string_field(receipt, "criterion_id") != Some(criterion_id) {
    return false
  }
  if planbook_json_string_field(receipt, "source_root") != Some(source_root) {
    return false
  }
  match run_id {
    Some(id) if planbook_json_string_field(receipt, "run_id") != Some(id) =>
      return false
    _ => ()
  }
  if planbook_json_string_field(receipt, "execution_mode") != Some("acp") {
    return false
  }
  if !planbook_repair_receipt_nonblank_field(receipt, "execution_target") ||
    !planbook_repair_receipt_nonblank_field(receipt, "acp_run_id") ||
    !planbook_repair_receipt_nonblank_field(receipt, "base_head") ||
    !planbook_repair_receipt_nonblank_field(receipt, "final_head") {
    return false
  }
  if planbook_json_string_field(receipt, "result_decision") != Some("accepted") {
    return false
  }
  if planbook_json_string_field(receipt, "diff_check_status") != Some("passed") {
    return false
  }
  if !planbook_repair_receipt_required_commands_recorded(receipt) {
    return false
  }
  if planbook_json_string_array_field(receipt, "changed_files").is_empty() {
    return false
  }
  if planbook_json_string_field(receipt, "commit_status") != Some("committed") {
    return false
  }
  if !planbook_repair_receipt_nonblank_field(receipt, "commit_sha") ||
    !planbook_repair_receipt_nonblank_field(receipt, "commit_message") {
    return false
  }
  planbook_repair_receipt_nonblank_field(receipt, "push_status")
}

///|
fn planbook_repair_text_has_valid_patch_receipt(
  text : String,
  criterion_id : String,
  source_root : String,
) -> Bool {
  match planbook_repair_patch_receipt_from_text(text) {
    Some(receipt) =>
      planbook_repair_patch_receipt_satisfies_contract(
        receipt, criterion_id, source_root,
      )
    None => false
  }
}

///|
fn planbook_repair_payload_has_valid_patch_receipt(
  payload : Json,
  criterion_id : String,
  source_root : String,
  run_id : String,
) -> Bool {
  match planbook_repair_patch_receipt_from_payload(payload) {
    Some(receipt) =>
      planbook_repair_patch_receipt_satisfies_contract(
        receipt,
        criterion_id,
        source_root,
        run_id=Some(run_id),
      )
    None => false
  }
}

///|
async fn planbook_latest_repair_patch_receipt_ready(
  workspace_root : String,
) -> Bool {
  let text = read_text_or_empty(
    planbook_repair_result_path_for_workspace(workspace_root),
  )
  planbook_repair_result_has_accepted_decision(text) &&
  planbook_repair_result_records_validation_passes(text) &&
  planbook_repair_text_has_valid_patch_receipt(
    text,
    "planbook-source-patch-loop",
    planbook_repair_source_root(),
  )
}
