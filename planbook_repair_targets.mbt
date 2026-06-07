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
  let backlog_targets = planbook_backlog_target_files_for_criterion(
    criterion_id, root,
  )
  if !backlog_targets.is_empty() {
    return backlog_targets
  }
  let planbook_root = planbook_workspace_root_for_source_root(root)
  let course_root = wenyu_course_workspace_root_for_source_root(root)
  match criterion_id {
    "editor-mode-real-pipeline" =>
      [
        "\{root}/planbook_autonomy.mbt",
        "\{root}/planbook_repair.mbt",
        "\{root}/planbook.mbt",
        "\{root}/cmd/main/main.mbt",
        "\{root}/ui/rabbita-town/main/main.mbt",
        "\{root}/course_book.mbt",
        "\{course_root}/wiki/course/beginner-course.md",
        editor_pipeline_plan_path(
          planbook_root, "2026-05-31-editor-mode-real-pipeline",
        ),
      ]
    "editor-selected-feature-implementation" =>
      [
        "\{root}/editor_feature_selection.mbt",
        "\{root}/editor_pipeline.mbt",
        "\{root}/planbook_autonomy.mbt",
        "\{root}/planbook_repair.mbt",
        "\{root}/civic_protocol_store.mbt",
        "\{root}/civic_status.mbt",
        "\{root}/civic_protocol_registry_runtime.mbt",
        "\{root}/ui/rabbita-town/main/main.mbt",
        "\{root}/ui/rabbita-town/bootstrap.js",
        "\{course_root}/wiki/course/beginner-course.md",
        "\{course_root}/wiki/course/exercises.md",
        "\{course_root}/wiki/course/progress-rubric.md",
        editor_feature_selection_result_path(planbook_root),
        "\{root}/docs/WENYU_UI_MODULE_SYSTEM.md",
      ]
    _ =>
      [
        "\{root}/planbook_autonomy.mbt",
        "\{root}/planbook_autonomy_criteria_self_build.mbt",
        "\{root}/planbook_repair.mbt",
        "\{root}/planbook_repair_result.mbt",
        "\{root}/planbook_repair_packet_metadata.mbt",
        "\{root}/planbook_repair_patch_receipt.mbt",
        "\{root}/planbook.mbt",
        "\{root}/cmd/main/main.mbt",
        "\{root}/../moonclaw/acp/runner.mbt",
        "\{root}/../moonclaw/acp/runner_wbtest.mbt",
      ]
  }
}

///|
fn planbook_repair_target_files_markdown(criterion_id : String) -> String {
  let lines : Array[String] = []
  for path in planbook_repair_target_files(criterion_id) {
    lines.push("- `\{path}`")
  }
  lines.join("\n")
}
