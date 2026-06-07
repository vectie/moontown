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
    !planbook_repair_result_satisfies_contract(
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

///|
fn planbook_test_validation_lines() -> Array[String] {
  planbook_repair_required_commands().map(fn(command) {
    "validation: \{command} passed"
  })
}

///|
fn planbook_test_valid_patch_receipt(
  criterion_id : String,
  run_id? : String = "run-1",
) -> Json {
  {
    "contract": planbook_repair_patch_receipt_contract(),
    "criterion_id": criterion_id,
    "source_root": planbook_repair_source_root(),
    "execution_mode": "acp",
    "execution_target": "codex-main",
    "run_id": run_id,
    "acp_run_id": "acp-run-1",
    "base_head": "0000001",
    "final_head": "0000002",
    "changed_files": ["planbook_repair_result.mbt"],
    "validation_commands": planbook_repair_required_commands(),
    "diff_check_status": "passed",
    "commit_status": "committed",
    "commit_sha": "0000002",
    "commit_message": "Add PlanBook repair patch receipt",
    "push_status": "not_pushed_by_policy",
    "result_decision": "accepted",
  }
}

///|
test "planbook repair result contract accepts structural patch receipt evidence" {
  let criterion_id = "planbook-source-patch-loop"
  let receipt = planbook_test_valid_patch_receipt(criterion_id)
  let text = [
    "repair_decision: accepted",
    "criterion_id: \{criterion_id}",
    "files_changed: planbook_repair_result.mbt",
    ..planbook_test_validation_lines(),
    "diff_summary: git diff --check passed",
    "plan_update_status: unchanged",
    "commit_status: committed",
    "commit_message: Add PlanBook repair patch receipt",
    "push_status: not_pushed_by_policy",
    "remaining_blockers: none",
    "cookbook_impact: none",
    planbook_repair_patch_receipt_text(receipt),
  ].join("\n")
  assert_true(planbook_repair_result_satisfies_contract(text, criterion_id))
}

///|
test "planbook repair run result requires payload patch receipt evidence" {
  let criterion_id = "planbook-source-patch-loop"
  let content = [
    "repair_decision: accepted",
    "criterion_id: \{criterion_id}",
    "files_changed: planbook_repair_result.mbt",
    ..planbook_test_validation_lines(),
    "diff_summary: git diff --check passed",
    "plan_update_status: unchanged",
    "commit_status: committed",
    "commit_message: Add PlanBook repair patch receipt",
    "push_status: not_pushed_by_policy",
  ].join("\n")
  assert_true(
    !planbook_repair_run_result_satisfies_contract(
      { "content": content },
      content,
      "/tmp/workspace",
      "run-1",
      criterion_id,
    ),
  )
  assert_true(
    planbook_repair_run_result_satisfies_contract(
      {
        "content": content,
        "patch_receipt": planbook_test_valid_patch_receipt(criterion_id),
      },
      content,
      "/tmp/workspace",
      "run-1",
      criterion_id,
    ),
  )
  assert_true(
    planbook_repair_run_result_satisfies_contract(
      {
        "content": content,
        "metadata": {
          "patch_receipt": planbook_test_valid_patch_receipt(criterion_id),
        },
      },
      content,
      "/tmp/workspace",
      "run-1",
      criterion_id,
    ),
  )
  assert_true(
    planbook_repair_run_result_has_accepted_evidence(
      {
        "content": content,
        "patch_receipt": planbook_test_valid_patch_receipt(criterion_id),
      },
      content,
      "run-1",
      criterion_id,
    ),
  )
}

///|
test "planbook repair run result keeps blocked acp output from completing" {
  let criterion_id = "planbook-source-patch-loop"
  let content = [
    "repair_decision: blocked",
    "criterion_id: \{criterion_id}",
    "files_changed: none",
    "validation: moon check --no-render blocked",
    "diff_summary: no accepted source patch",
    "plan_update_status: stale_blocked",
    "commit_status: blocked",
    "commit_message: none",
    "push_status: not_pushed_by_policy",
  ].join("\n")
  assert_true(
    planbook_repair_run_result_satisfies_contract(
      { "content": content },
      content,
      "/tmp/workspace",
      "run-1",
      criterion_id,
    ),
  )
  assert_true(
    !planbook_repair_run_result_has_accepted_evidence(
      { "content": content },
      content,
      "run-1",
      criterion_id,
    ),
  )
}
