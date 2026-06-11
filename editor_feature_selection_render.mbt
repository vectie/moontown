///|
fn editor_feature_selection_result_satisfies_contract(text : String) -> Bool {
  @editor_pipeline.feature_selection_result_satisfies_contract(text)
}

///|
async fn editor_feature_selection_result_summary(
  result_path : String,
) -> String {
  let text = read_text_or_empty(result_path)
  if text == "" {
    return "No result has been written yet."
  }
  if editor_feature_selection_result_satisfies_contract(text) {
    "Valid selection contract exists at `\{result_path}`."
  } else {
    "Result exists at `\{result_path}`, but it does not satisfy `\{@editor_pipeline.feature_selection_result_contract()}`."
  }
}

///|
async fn render_editor_feature_selection_markdown(
  task : EditorFeatureSelectionTask,
) -> String {
  [
    "# Editor Feature Selection",
    "",
    "- contract: `moontown.editor_feature_selection.task.v1`",
    "- task: `\{task.id}`",
    "- status: `\{task.status}`",
    "- workspace: `\{task.workspace_root}`",
    "- packet: `\{task.packet_path}`",
    "- result: `\{task.result_path}`",
    "- proposal: `\{task.proposal_id.unwrap_or("none")}`",
    "- run: `\{task.run_id.unwrap_or("none")}`",
    "",
    "## Summary",
    "",
    task.summary,
    "",
    "## Result",
    "",
    editor_feature_selection_result_summary(task.result_path),
  ].join("\n")
}
