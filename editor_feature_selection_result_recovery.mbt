///|
async fn refresh_editor_feature_selection_task(
  task : EditorFeatureSelectionTask,
) -> EditorFeatureSelectionTask {
  if @fs.exists(task.result_path) &&
    editor_feature_selection_result_satisfies_contract(
      read_text_or_empty(task.result_path),
    ) {
    return {
      ..task,
      status: "completed",
      summary: "MoonClaw wrote a valid editor feature selection result.",
    }
  }
  let run_id = match task.run_id {
    Some(run_id) => run_id
    None => return task
  }
  let content = editor_feature_selection_result_text_from_run(task, run_id)
  if editor_feature_selection_result_satisfies_contract(content) {
    write_text_file(task.result_path, content)
    return {
      ..task,
      status: "completed",
      summary: "Recovered valid editor feature selection from MoonClaw run `\{run_id}`.",
    }
  }
  task
}

///|
async fn editor_feature_selection_result_text_from_run(
  task : EditorFeatureSelectionTask,
  run_id : String,
) -> String {
  moonclaw_run_result_text_from_run(run_id, task.workspace_root)
}
