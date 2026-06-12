///|
pub async fn write_editor_feature_selection_task(
  snapshot_path? : String = @storage.default_snapshot_path(),
  workspace_root? : String = default_planbook_workspace_root(),
  dispatch? : Bool = false,
) -> String {
  let task = materialize_editor_feature_selection_task(
    snapshot_path, workspace_root, dispatch,
  )
  write_editor_feature_selection_status(task, snapshot_path)
  "Editor feature selection task `\{task.id}` is \{task.status}: \{task.summary}"
}

///|
pub async fn render_editor_feature_selection_status(
  snapshot_path? : String = @storage.default_snapshot_path(),
  workspace_root? : String = default_planbook_workspace_root(),
) -> String {
  ignore(workspace_root)
  let task = match load_editor_feature_selection_task(snapshot_path) {
    Some(task) => task
    None =>
      return "No editor feature selection task exists. Run `moon run src/cmd/main -- editor-pipeline feature-select --dispatch`."
  }
  let refreshed = refresh_editor_feature_selection_task(task)
  write_editor_feature_selection_status(refreshed, snapshot_path)
  render_editor_feature_selection_markdown(refreshed)
}

///|
pub async fn editor_feature_selection_ready(
  workspace_root? : String = default_planbook_workspace_root(),
) -> Bool {
  editor_feature_selection_result_satisfies_contract(
    @support.read_text_or_empty(
      editor_feature_selection_result_path(workspace_root),
    ),
  )
}

///|
pub async fn editor_feature_selection_evidence(
  workspace_root? : String = default_planbook_workspace_root(),
) -> String {
  let result_path = editor_feature_selection_result_path(workspace_root)
  let text = @support.read_text_or_empty(result_path)
  if editor_feature_selection_result_satisfies_contract(text) {
    "valid AI-rated feature selection exists at `\{result_path}`"
  } else if @fs.exists(result_path) {
    "feature selection result exists at `\{result_path}`, but it does not satisfy `\{@editor_pipeline.feature_selection_result_contract()}`"
  } else {
    "no AI-rated feature selection exists at `\{result_path}`"
  }
}
