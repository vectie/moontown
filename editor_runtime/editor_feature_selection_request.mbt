///|
fn editor_feature_selection_target_files() -> Array[String] {
  let root = planbook_repair_source_root()
  let planbook_root = planbook_workspace_root_for_source_root(root)
  let course_root = wenyu_course_workspace_root_for_source_root(root)
  [
    "\{course_root}/wiki/course/beginner-course.md",
    "\{course_root}/wiki/course/exercises.md",
    "\{course_root}/wiki/course/progress-rubric.md",
    editor_pipeline_plan_path(
      planbook_root, "2026-05-31-editor-mode-real-pipeline",
    ),
    editor_implemented_features_ledger_path(planbook_root),
    editor_selected_feature_implementation_path(planbook_root),
    editor_feature_selection_current_evidence_path(planbook_root),
    "\{root}/docs/WENYU_UI_MODULE_SYSTEM.md",
  ]
}

///|
fn editor_feature_selection_request_text(result_path : String) -> String {
  @editor_pipeline.feature_selection_request_text(
    result_path,
    editor_feature_selection_target_files(),
  )
}

///|
fn editor_feature_selection_profile_prompt_template() -> String {
  @editor_pipeline.feature_selection_profile_prompt_template()
}
