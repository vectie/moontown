///|
async fn write_editor_feature_selection_status(
  task : EditorFeatureSelectionTask,
  snapshot_path : String,
) -> Unit {
  write_text_file(
    default_editor_feature_selection_path(snapshot_path~),
    task.to_json().stringify(indent=2),
  )
  write_text_file(
    default_editor_feature_selection_markdown_path(snapshot_path~),
    render_editor_feature_selection_markdown(task),
  )
}

///|
async fn load_editor_feature_selection_task(
  snapshot_path : String,
) -> EditorFeatureSelectionTask? {
  let path = default_editor_feature_selection_path(snapshot_path~)
  if !@fs.exists(path) {
    return None
  }
  let parsed = @json.parse(@fs.read_file(path).text()) catch {
    _ => return None
  }
  match parsed {
    Object(object) =>
      Some({
        id: json_object_string(object, "id").unwrap_or(
          "editor-feature-selection",
        ),
        status: json_object_string(object, "status").unwrap_or("unknown"),
        workspace_root: json_object_string(object, "workspace_root").unwrap_or(
          default_planbook_workspace_root(),
        ),
        packet_path: json_object_string(object, "packet_path").unwrap_or(""),
        result_path: json_object_string(object, "result_path").unwrap_or(
          editor_feature_selection_result_path(
            default_planbook_workspace_root(),
          ),
        ),
        proposal_id: json_object_string(object, "proposal_id"),
        run_id: json_object_string(object, "run_id"),
        summary: json_object_string(object, "summary").unwrap_or(""),
        generated_at_ms: 0,
      })
    _ => None
  }
}
