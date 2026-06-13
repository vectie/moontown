///|
fn planbook_repair_timeout_ms_json() -> Json {
  let value = 600000
  value.to_json()
}

///|
fn planbook_repair_source_root() -> String {
  match @env.current_dir() {
    Some(dir) => dir
    None => "."
  }
}

///|
fn planbook_repair_target_files(criterion_id : String) -> Array[String] {
  let root = planbook_repair_source_root()
  let planbook_root = @editor_runtime.planbook_workspace_root_for_source_root(
    root,
  )
  let course_root = @editor_runtime.wenyu_course_workspace_root_for_source_root(
    root,
  )
  @planbook_policy.repair_target_files_for_criterion(
    criterion_id,
    root,
    course_root,
    @editor_runtime.editor_pipeline_plan_path(
      planbook_root, "2026-05-31-editor-mode-real-pipeline",
    ),
    @editor_runtime.editor_feature_selection_result_path(planbook_root),
  )
}

///|
fn planbook_repair_target_files_markdown(criterion_id : String) -> String {
  let lines : Array[String] = []
  for path in planbook_repair_target_files(criterion_id) {
    lines.push("- `\{path}`")
  }
  lines.join("\n")
}
