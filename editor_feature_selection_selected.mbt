///|
struct EditorSelectedFeature {
  selected_feature : String
  title : String
  score : String
  implementation_hint : String
  current_gap : String
} derive(Debug, Eq)

///|
async fn editor_selected_feature_summary(
  workspace_root : String,
) -> EditorSelectedFeature? {
  let text = read_text_or_empty(
    editor_feature_selection_result_path(workspace_root),
  )
  let parsed = @json.parse(text) catch { _ => return None }
  match parsed {
    Object(object) =>
      Some({
        selected_feature: json_object_string(object, "selected_feature").unwrap_or(
          "unknown-feature",
        ),
        title: json_object_string(object, "title").unwrap_or("Untitled feature"),
        score: json_object_field_summary(object, "score").unwrap_or("unknown"),
        implementation_hint: json_object_string(object, "implementation_hint").unwrap_or(
          "No implementation hint was provided.",
        ),
        current_gap: json_object_string(object, "current_gap").unwrap_or(
          "No current gap was provided.",
        ),
      })
    _ => None
  }
}

///|
async fn editor_selected_feature_implementation_ready(
  workspace_root : String,
) -> Bool {
  let feature = match editor_selected_feature_summary(workspace_root) {
    Some(feature) => feature
    None => return false
  }
  let text = read_text_or_empty(
    editor_selected_feature_implementation_path(workspace_root),
  )
  text.contains(
    "contract: \{@editor_pipeline.selected_feature_implementation_contract()}",
  ) &&
  text.contains("selected_feature: \{feature.selected_feature}") &&
  text.contains("implementation_status: accepted")
}

///|
async fn editor_selected_feature_implementation_evidence(
  workspace_root : String,
) -> String {
  let proof_path = editor_selected_feature_implementation_path(workspace_root)
  let feature = match editor_selected_feature_summary(workspace_root) {
    Some(feature) => feature
    None =>
      return "no valid AI-selected feature exists; run `moon run cmd/main -- editor-pipeline feature-select --dispatch` first"
  }
  if editor_selected_feature_implementation_ready(workspace_root) {
    "AI-selected feature `\{feature.selected_feature}` is implemented with accepted proof at `\{proof_path}`"
  } else {
    "AI selected `\{feature.selected_feature}` (`\{feature.title}`) with score \{feature.score}; implementation proof is missing at `\{proof_path}`. Gap: \{feature.current_gap}"
  }
}

///|
async fn editor_selected_feature_implementation_next_action(
  workspace_root : String,
) -> String {
  match editor_selected_feature_summary(workspace_root) {
    Some(feature) =>
      "run `moon run cmd/main -- planbook repair --dispatch`; repair must read `raw/editor-pipeline/next-feature.json`, implement `\{feature.selected_feature}` using the AI acceptance criteria, and write `raw/editor-pipeline/selected-feature-implementation.md`"
    None =>
      "run `moon run cmd/main -- editor-pipeline feature-select --dispatch` before implementation repair"
  }
}

///|
async fn editor_feature_selection_stage_status(
  snapshot_path : String,
  workspace_root : String,
) -> String {
  if editor_feature_selection_ready(workspace_root~) {
    return "ready"
  }
  match load_editor_feature_selection_task(snapshot_path) {
    Some(task) => refresh_editor_feature_selection_task(task).status
    None => "not-started"
  }
}

///|
async fn editor_feature_selection_stage_summary(
  workspace_root : String,
) -> String {
  if editor_feature_selection_ready(workspace_root~) {
    "MoonClaw selected the next missing editor feature from course evidence."
  } else {
    "No valid AI-rated next-feature selection has been produced yet."
  }
}
