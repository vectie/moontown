///|
pub fn repair_target_files_for_criterion(
  criterion_id : String,
  source_root : String,
  course_root : String,
  editor_pipeline_plan_path : String,
  editor_feature_selection_result_path : String,
) -> Array[String] {
  let backlog_targets = backlog_target_files_for_criterion(
    criterion_id, source_root,
  )
  if !backlog_targets.is_empty() {
    return backlog_targets
  }
  match criterion_id {
    "editor-mode-real-pipeline" =>
      [
        "\{source_root}/src/planbook_runtime/planbook_autonomy.mbt",
        "\{source_root}/src/planbook_runtime/planbook_repair.mbt",
        "\{source_root}/src/planbook_runtime/planbook.mbt",
        "\{source_root}/src/cmd/main/main.mbt",
        "\{source_root}/src/ui/rabbita-town/main/main.mbt",
        "\{source_root}/src/course_book/core.mbt",
        "\{course_root}/wiki/course/beginner-course.md",
        editor_pipeline_plan_path,
      ]
    "editor-selected-feature-implementation" =>
      [
        "\{source_root}/src/editor_runtime/editor_feature_selection.mbt",
        "\{source_root}/src/editor_runtime/editor_pipeline.mbt",
        "\{source_root}/src/planbook_runtime/planbook_autonomy.mbt",
        "\{source_root}/src/planbook_runtime/planbook_repair.mbt",
        "\{source_root}/src/civic_runtime/civic_protocol_store.mbt",
        "\{source_root}/src/civic_runtime/civic_status.mbt",
        "\{source_root}/src/civic_runtime/civic_protocol_registry_runtime.mbt",
        "\{source_root}/src/ui/rabbita-town/main/main.mbt",
        "\{source_root}/src/ui/rabbita-town/bootstrap.js",
        "\{course_root}/wiki/course/beginner-course.md",
        "\{course_root}/wiki/course/exercises.md",
        "\{course_root}/wiki/course/progress-rubric.md",
        editor_feature_selection_result_path,
        "\{source_root}/docs/WENYU_UI_MODULE_SYSTEM.md",
      ]
    "planbook-source-patch-loop" =>
      [
        "\{source_root}/src/planbook_runtime/planbook_autonomy.mbt",
        "\{source_root}/src/planbook_runtime/planbook_autonomy_criteria_self_build.mbt",
        "\{source_root}/src/planbook_runtime/planbook_repair.mbt",
        "\{source_root}/src/planbook_runtime/planbook_repair_active.mbt",
        "\{source_root}/src/planbook_runtime/planbook_repair_result.mbt",
        "\{source_root}/src/planbook_runtime/planbook_repair_packet_metadata.mbt",
        "\{source_root}/src/planbook_runtime/planbook_repair_patch_receipt.mbt",
        "\{source_root}/src/planbook_runtime/planbook_repair_targets.mbt",
        "\{source_root}/src/planbook_policy/skill_text.mbt",
        "\{source_root}/src/planbook_policy/request_rules.mbt",
        "\{source_root}/src/planbook_policy/repair_paths.mbt",
        "\{source_root}/src/planbook_runtime/planbook_repair_materialization_wbtest.mbt",
        "\{source_root}/src/planbook_runtime/planbook_repair_request_contract_wbtest.mbt",
        "\{source_root}/src/planbook_runtime/planbook_repair_worker_policy_wbtest.mbt",
        "\{source_root}/src/adapters/moonclaw/run_polling.mbt",
        "\{source_root}/src/adapters/moonclaw/run_polling_wbtest.mbt",
        "\{source_root}/src/adapters/moonclaw/import.mbt",
        "\{source_root}/src/adapters/moonclaw/commands.mbt",
        "\{source_root}/src/live_autonomy_runtime/live_autonomy_wbtest.mbt",
        "\{source_root}/src/planbook_runtime/planbook.mbt",
        "\{source_root}/src/cmd/main/main.mbt",
      ]
    "live-runtime-recovery" =>
      [
        "\{source_root}/src/planbook_runtime/planbook_autonomy_criteria_runtime.mbt",
        "\{source_root}/src/planbook_runtime/planbook_repair.mbt",
        "\{source_root}/src/planbook_runtime/planbook_repair_active.mbt",
        "\{source_root}/src/planbook_runtime/planbook_repair_result.mbt",
        "\{source_root}/src/planbook_runtime/planbook_repair_targets.mbt",
        "\{source_root}/src/live_autonomy_runtime/live_autonomy.mbt",
        "\{source_root}/src/live_autonomy_runtime/live_autonomy_current.mbt",
        "\{source_root}/src/live_autonomy_runtime/live_autonomy_refresh.mbt",
        "\{source_root}/src/live_autonomy_runtime/live_autonomy_wbtest.mbt",
        "\{source_root}/src/town_runtime/goal_supervision_recovery.mbt",
        "\{source_root}/src/town_runtime/goal_supervision_core.mbt",
        "\{source_root}/src/town_runtime/goal_supervision_status_helpers.mbt",
        "\{source_root}/src/town_runtime/goal_supervision_transient_infra_wbtest.mbt",
        "\{source_root}/src/town_runtime/goal_supervision_standing_watch_ledger_wbtest.mbt",
        "\{source_root}/src/town_runtime/standing_watch_recovery_policy.mbt",
        "\{source_root}/src/town_runtime/standing_watch_recovery_context.mbt",
        "\{source_root}/src/town_runtime/standing_watch_recovery_policy_wbtest.mbt",
        "\{source_root}/src/town_runtime/standing_watch_recovery_observed_wbtest.mbt",
        "\{source_root}/src/runtime_status/runtime_status_lifecycle_wbtest.mbt",
        "\{source_root}/src/town_runtime/daemon_tick_saved_town.mbt",
        "\{source_root}/src/town_runtime/daemon_tick_planbook_phase.mbt",
        "\{source_root}/src/adapters/moonclaw/run_polling.mbt",
        "\{source_root}/src/adapters/moonclaw/run_polling_wbtest.mbt",
        "\{source_root}/src/adapters/moonclaw/import.mbt",
        "\{source_root}/src/adapters/moonclaw/commands.mbt",
      ]
    _ =>
      [
        "\{source_root}/src/planbook_runtime/planbook_autonomy.mbt",
        "\{source_root}/src/planbook_runtime/planbook_autonomy_criteria_self_build.mbt",
        "\{source_root}/src/planbook_runtime/planbook_repair.mbt",
        "\{source_root}/src/planbook_runtime/planbook_repair_result.mbt",
        "\{source_root}/src/planbook_runtime/planbook_repair_packet_metadata.mbt",
        "\{source_root}/src/planbook_runtime/planbook_repair_patch_receipt.mbt",
        "\{source_root}/src/planbook_runtime/planbook.mbt",
        "\{source_root}/src/cmd/main/main.mbt",
      ]
  }
}
