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
  let planbook_root = @editor_runtime.planbook_workspace_root_for_source_root(
    root,
  )
  let course_root = @editor_runtime.wenyu_course_workspace_root_for_source_root(
    root,
  )
  match criterion_id {
    "editor-mode-real-pipeline" =>
      [
        "\{root}/src/planbook_runtime/planbook_autonomy.mbt",
        "\{root}/src/planbook_runtime/planbook_repair.mbt",
        "\{root}/src/planbook_runtime/planbook.mbt",
        "\{root}/src/cmd/main/main.mbt",
        "\{root}/src/ui/rabbita-town/main/main.mbt",
        "\{root}/src/course_book/core.mbt",
        "\{course_root}/wiki/course/beginner-course.md",
        @editor_runtime.editor_pipeline_plan_path(
          planbook_root, "2026-05-31-editor-mode-real-pipeline",
        ),
      ]
    "editor-selected-feature-implementation" =>
      [
        "\{root}/src/editor_runtime/editor_feature_selection.mbt",
        "\{root}/src/editor_runtime/editor_pipeline.mbt",
        "\{root}/src/planbook_runtime/planbook_autonomy.mbt",
        "\{root}/src/planbook_runtime/planbook_repair.mbt",
        "\{root}/src/civic_runtime/civic_protocol_store.mbt",
        "\{root}/src/civic_runtime/civic_status.mbt",
        "\{root}/src/civic_runtime/civic_protocol_registry_runtime.mbt",
        "\{root}/src/ui/rabbita-town/main/main.mbt",
        "\{root}/src/ui/rabbita-town/bootstrap.js",
        "\{course_root}/wiki/course/beginner-course.md",
        "\{course_root}/wiki/course/exercises.md",
        "\{course_root}/wiki/course/progress-rubric.md",
        @editor_runtime.editor_feature_selection_result_path(planbook_root),
        "\{root}/docs/WENYU_UI_MODULE_SYSTEM.md",
      ]
    "planbook-source-patch-loop" =>
      [
        "\{root}/src/planbook_runtime/planbook_autonomy.mbt",
        "\{root}/src/planbook_runtime/planbook_autonomy_criteria_self_build.mbt",
        "\{root}/src/planbook_runtime/planbook_repair.mbt",
        "\{root}/src/planbook_runtime/planbook_repair_active.mbt",
        "\{root}/src/planbook_runtime/planbook_repair_result.mbt",
        "\{root}/src/planbook_runtime/planbook_repair_packet_metadata.mbt",
        "\{root}/src/planbook_runtime/planbook_repair_patch_receipt.mbt",
        "\{root}/src/planbook_runtime/planbook_repair_targets.mbt",
        "\{root}/src/planbook_policy/skill_text.mbt",
        "\{root}/src/planbook_policy/request_rules.mbt",
        "\{root}/src/planbook_policy/repair_paths.mbt",
        "\{root}/src/planbook_runtime/planbook_repair_materialization_wbtest.mbt",
        "\{root}/src/planbook_runtime/planbook_repair_request_contract_wbtest.mbt",
        "\{root}/src/planbook_runtime/planbook_repair_worker_policy_wbtest.mbt",
        "\{root}/src/adapters/moonclaw/run_polling.mbt",
        "\{root}/src/adapters/moonclaw/run_polling_wbtest.mbt",
        "\{root}/src/live_autonomy_runtime/live_autonomy_wbtest.mbt",
        "\{root}/src/planbook_runtime/planbook.mbt",
        "\{root}/src/cmd/main/main.mbt",
        "\{root}/../moonclaw/acp/runner.mbt",
        "\{root}/../moonclaw/acp/runner_wbtest.mbt",
        "\{root}/../moonclaw/job/analysis_acp_runner.mbt",
        "\{root}/../moonclaw/job/analysis_contracts.mbt",
        "\{root}/../moonclaw/job/analysis_wbtest.mbt",
      ]
    "live-runtime-recovery" =>
      [
        "\{root}/src/planbook_runtime/planbook_autonomy_criteria_runtime.mbt",
        "\{root}/src/planbook_runtime/planbook_repair.mbt",
        "\{root}/src/planbook_runtime/planbook_repair_active.mbt",
        "\{root}/src/planbook_runtime/planbook_repair_result.mbt",
        "\{root}/src/planbook_runtime/planbook_repair_targets.mbt",
        "\{root}/src/live_autonomy_runtime/live_autonomy.mbt",
        "\{root}/src/live_autonomy_runtime/live_autonomy_current.mbt",
        "\{root}/src/live_autonomy_runtime/live_autonomy_refresh.mbt",
        "\{root}/src/live_autonomy_runtime/live_autonomy_wbtest.mbt",
        "\{root}/src/town_runtime/goal_supervision_recovery.mbt",
        "\{root}/src/town_runtime/goal_supervision_core.mbt",
        "\{root}/src/town_runtime/goal_supervision_status_helpers.mbt",
        "\{root}/src/town_runtime/goal_supervision_transient_infra_wbtest.mbt",
        "\{root}/src/town_runtime/goal_supervision_standing_watch_ledger_wbtest.mbt",
        "\{root}/src/town_runtime/standing_watch_recovery_policy.mbt",
        "\{root}/src/town_runtime/standing_watch_recovery_legacy.mbt",
        "\{root}/src/town_runtime/standing_watch_recovery_context.mbt",
        "\{root}/src/town_runtime/standing_watch_recovery_policy_wbtest.mbt",
        "\{root}/src/town_runtime/standing_watch_recovery_observed_wbtest.mbt",
        "\{root}/src/runtime_status/runtime_status_lifecycle_wbtest.mbt",
        "\{root}/src/town_runtime/daemon_tick_saved_town.mbt",
        "\{root}/src/town_runtime/daemon_tick_planbook_phase.mbt",
        "\{root}/src/adapters/moonclaw/run_polling.mbt",
        "\{root}/src/adapters/moonclaw/run_polling_wbtest.mbt",
        "\{root}/../moonclaw/job/analysis_acp_runner.mbt",
        "\{root}/../moonclaw/job/analysis_contracts.mbt",
      ]
    _ =>
      [
        "\{root}/src/planbook_runtime/planbook_autonomy.mbt",
        "\{root}/src/planbook_runtime/planbook_autonomy_criteria_self_build.mbt",
        "\{root}/src/planbook_runtime/planbook_repair.mbt",
        "\{root}/src/planbook_runtime/planbook_repair_result.mbt",
        "\{root}/src/planbook_runtime/planbook_repair_packet_metadata.mbt",
        "\{root}/src/planbook_runtime/planbook_repair_patch_receipt.mbt",
        "\{root}/src/planbook_runtime/planbook.mbt",
        "\{root}/src/cmd/main/main.mbt",
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
