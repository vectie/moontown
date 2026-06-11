///|
pub fn repair_patch_receipt_contract() -> String {
  "planbook.repair.patch_receipt.v1"
}

///|
pub fn repair_patch_receipt_from_payload(payload : Json) -> Json? {
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
pub fn repair_patch_receipt_from_text(text : String) -> Json? {
  let parsed = @json.parse(text.trim().to_owned()) catch {
    _ => return repair_patch_receipt_block_from_text(text)
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
pub fn repair_patch_receipt_block_from_text(text : String) -> Json? {
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
pub fn repair_patch_receipt_text(receipt : Json) -> String {
  ["", "patch_receipt:", receipt.stringify(indent=2)].join("\n")
}

///|
pub fn repair_result_text_with_patch_receipt(
  content : String,
  payload : Json,
) -> String {
  match repair_patch_receipt_from_payload(payload) {
    Some(receipt) =>
      if content.contains(repair_patch_receipt_contract()) {
        content
      } else {
        "\{content.trim().to_owned()}\{repair_patch_receipt_text(receipt)}"
      }
    None => content
  }
}

///|
fn json_field(value : Json, key : String) -> Json? {
  match value {
    Object(object) => object.get(key)
    _ => None
  }
}

///|
fn json_string_field(value : Json, key : String) -> String? {
  match json_field(value, key) {
    Some(String(text)) => Some(text)
    _ => None
  }
}

///|
fn json_string_array_field(value : Json, key : String) -> Array[String] {
  match json_field(value, key) {
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
fn repair_receipt_nonblank_field(receipt : Json, key : String) -> Bool {
  match json_string_field(receipt, key) {
    Some(value) => !value.trim().to_owned().is_blank()
    None => false
  }
}

///|
fn repair_receipt_required_commands_recorded(receipt : Json) -> Bool {
  let commands = json_string_array_field(receipt, "validation_commands")
  repair_required_commands().all(fn(required) {
    commands.any(fn(command) { command.contains(required) })
  })
}

///|
pub fn repair_patch_receipt_satisfies_contract(
  receipt : Json,
  criterion_id : String,
  source_root : String,
  run_id? : String? = None,
) -> Bool {
  if json_string_field(receipt, "contract") !=
    Some(repair_patch_receipt_contract()) {
    return false
  }
  if json_string_field(receipt, "criterion_id") != Some(criterion_id) {
    return false
  }
  if json_string_field(receipt, "source_root") != Some(source_root) {
    return false
  }
  match run_id {
    Some(id) if json_string_field(receipt, "run_id") != Some(id) => return false
    _ => ()
  }
  if json_string_field(receipt, "execution_mode") != Some("acp") {
    return false
  }
  if !repair_receipt_nonblank_field(receipt, "execution_target") ||
    !repair_receipt_nonblank_field(receipt, "acp_run_id") ||
    !repair_receipt_nonblank_field(receipt, "base_head") ||
    !repair_receipt_nonblank_field(receipt, "final_head") {
    return false
  }
  if json_string_field(receipt, "result_decision") != Some("accepted") {
    return false
  }
  if json_string_field(receipt, "diff_check_status") != Some("passed") {
    return false
  }
  if !repair_receipt_required_commands_recorded(receipt) {
    return false
  }
  if json_string_array_field(receipt, "changed_files").is_empty() {
    return false
  }
  if json_string_field(receipt, "commit_status") != Some("committed") {
    return false
  }
  if !repair_receipt_nonblank_field(receipt, "commit_sha") ||
    !repair_receipt_nonblank_field(receipt, "commit_message") {
    return false
  }
  repair_receipt_nonblank_field(receipt, "push_status")
}

///|
pub fn repair_text_has_valid_patch_receipt(
  text : String,
  criterion_id : String,
  source_root : String,
) -> Bool {
  match repair_patch_receipt_from_text(text) {
    Some(receipt) =>
      repair_patch_receipt_satisfies_contract(
        receipt, criterion_id, source_root,
      )
    None => false
  }
}

///|
pub fn repair_payload_has_valid_patch_receipt(
  payload : Json,
  criterion_id : String,
  source_root : String,
  run_id : String,
) -> Bool {
  match repair_patch_receipt_from_payload(payload) {
    Some(receipt) =>
      repair_patch_receipt_satisfies_contract(
        receipt,
        criterion_id,
        source_root,
        run_id=Some(run_id),
      )
    None => false
  }
}
