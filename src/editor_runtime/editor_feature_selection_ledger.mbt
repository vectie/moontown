///|
async fn record_accepted_editor_feature_if_present(
  workspace_root : String,
) -> Unit {
  let feature_id = match editor_current_accepted_feature_id(workspace_root) {
    Some(feature_id) => feature_id
    None => return
  }
  let ledger_path = editor_implemented_features_ledger_path(workspace_root)
  let current_ledger = @support.read_text_or_empty(ledger_path)
  let entry = "- `\{feature_id}`"
  if !current_ledger.contains(entry) {
    let next_ledger = if current_ledger.trim().is_empty() {
      [
        "# Implemented Editor Features", "", "This file is Moontown's durable exclusion ledger for iterative AI feature selection. Features listed here must not be selected again by `editor-feature-rater`.",
        "", entry,
      ].join("\n")
    } else {
      "\{current_ledger.trim().to_owned()}\n\{entry}"
    }
    @support.write_text_file(ledger_path, next_ledger)
  }
  let selection = @support.read_text_or_empty(
    editor_feature_selection_result_path(workspace_root),
  )
  if !selection.trim().is_empty() {
    @support.write_text_file(
      editor_implemented_feature_archive_path(
        workspace_root, feature_id, "selection.json",
      ),
      selection,
    )
  }
  let proof = @support.read_text_or_empty(
    editor_selected_feature_implementation_path(workspace_root),
  )
  if !proof.trim().is_empty() {
    @support.write_text_file(
      editor_implemented_feature_archive_path(
        workspace_root, feature_id, "implementation.md",
      ),
      proof,
    )
  }
}

///|
async fn editor_current_accepted_feature_id(workspace_root : String) -> String? {
  let text = @support.read_text_or_empty(
    editor_selected_feature_implementation_path(workspace_root),
  )
  if !text.contains(
      "contract: \{@editor_pipeline.selected_feature_implementation_contract()}",
    ) ||
    !text.contains("implementation_status: accepted") {
    return None
  }
  markdown_field_value(text, "selected_feature")
}

///|
async fn editor_accepted_feature_ids(workspace_root : String) -> Array[String] {
  let ids : Array[String] = []
  let ledger = @support.read_text_or_empty(
    editor_implemented_features_ledger_path(workspace_root),
  )
  for raw in ledger.split("\n") {
    let line = raw.trim().to_owned()
    if line.has_prefix("- `") {
      let id = line.trim(chars="- `").to_owned()
      if !id.trim().is_empty() && !ids.contains(id) {
        ids.push(id)
      }
    }
  }
  match editor_current_accepted_feature_id(workspace_root) {
    Some(id) if !ids.contains(id) => ids.push(id)
    _ => ()
  }
  ids
}

///|
async fn editor_accepted_features_markdown(workspace_root : String) -> String {
  let ids = editor_accepted_feature_ids(workspace_root)
  if ids.length() == 0 {
    return "- none"
  }
  let lines : Array[String] = []
  for id in ids {
    lines.push("- `\{id}`")
  }
  lines.join("\n")
}

///|
fn markdown_field_value(text : String, field : String) -> String? {
  let key_colon = "\{field}:"
  let key_equals = "\{field} ="
  for raw in text.split("\n") {
    let line = raw.trim().to_owned()
    if line.has_prefix(key_colon) {
      return Some(line[key_colon.length():].trim(chars=" `").to_owned())
    }
    if line.has_prefix(key_equals) {
      return Some(line[key_equals.length():].trim(chars=" `").to_owned())
    }
  }
  None
}
