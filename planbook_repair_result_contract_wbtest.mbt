///|
test "planbook repair result contract rejects best-effort timeout placeholders" {
  let criterion_id = "editor-mode-real-pipeline"
  assert_true(
    !planbook_repair_result_satisfies_contract(
      "Analysis step repair_planbook_gap timed out after 600000ms; continuing because `best_effort_on_timeout` is enabled.",
      criterion_id,
    ),
  )
  assert_true(
    !planbook_repair_result_satisfies_contract(
      [
        "repair_decision: accepted", "criterion_id: editor-mode-real-pipeline", "files_changed: editor_pipeline.mbt",
        "validation: moon check --no-render passed",
      ].join("\n"),
      criterion_id,
    ),
  )
  assert_true(
    planbook_repair_result_satisfies_contract(
      [
        "repair_decision: accepted", "criterion_id: editor-mode-real-pipeline", "files_changed: editor_pipeline.mbt",
        "validation: moon check --no-render passed", "diff_summary: git diff --check passed",
        "plan_update_status: unchanged", "commit_status: ready_to_commit", "commit_message: Add editor pipeline verification",
        "push_status: not_pushed_by_policy",
      ].join("\n"),
      criterion_id,
    ),
  )
  assert_eq(planbook_task_status_from_run_status(Some("Succeeded")), "failed")
}
