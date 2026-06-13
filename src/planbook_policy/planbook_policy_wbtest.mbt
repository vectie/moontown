///|
fn sample_patch_receipt(
  criterion_id : String,
  source_root : String,
  run_id : String,
) -> Json {
  {
    "contract": repair_patch_receipt_contract(),
    "criterion_id": criterion_id,
    "source_root": source_root,
    "execution_mode": "acp",
    "execution_target": "codex-main",
    "run_id": run_id,
    "acp_run_id": "acp-run-1",
    "base_head": "base",
    "final_head": "final",
    "changed_files": ["planbook_repair.mbt"],
    "validation_commands": repair_required_commands(),
    "diff_check_status": "passed",
    "commit_status": "committed",
    "commit_sha": "abc123",
    "commit_message": "Repair PlanBook gap",
    "push_status": "not_pushed_by_policy",
    "result_decision": "accepted",
  }
}

///|
fn accepted_repair_text(criterion_id : String, receipt : Json) -> String {
  [
    "criterion_id: \{criterion_id}",
    "repair_decision: accepted",
    "validation: passed",
    "diff_summary: changed source",
    "plan_update_status: updated",
    "commit_status: committed",
    "commit_message: Repair PlanBook gap",
    "push_status: not_pushed_by_policy",
    repair_required_commands().join(" passed\n"),
    repair_patch_receipt_text(receipt),
  ].join("\n")
}

///|
test "planbook repair contracts and commands are stable" {
  assert_eq(repair_result_contract(), "planbook.repair.result.v1")
  assert_eq(repair_patch_receipt_contract(), "planbook.repair.patch_receipt.v1")
  let command = repair_validation_command()
  assert_true(command.contains("moon check --no-render"))
  assert_true(command.contains("moon test --no-render"))
  assert_true(command.contains("git diff --check"))
}

///|
test "planbook validation evidence contract is package-owned policy" {
  let text = validation_evidence_markdown("validated", 42UL)
  assert_true(text.contains("contract: planbook.validation.v1"))
  assert_true(text.contains("validation_status: passed"))
  assert_true(text.contains("generated_at_ms: 42"))
  assert_true(validation_evidence_ready(text))
  assert_false(validation_evidence_ready("# Latest PlanBook Validation"))
  assert_true(
    validation_required_commands().any(fn(command) {
      command.contains("moon check --no-render")
    }),
  )
}

///|
test "planbook repair workspace layout is package-owned policy" {
  let workspace_root = "/tmp/moontown-planbook-repair-paths"
  assert_eq(
    repair_context_relative_path(),
    "raw/repair/PLANBOOK_REPAIR_CONTEXT.md",
  )
  assert_eq(repair_result_relative_path(), "raw/repair/repair-result.md")
  assert_eq(
    repair_superseded_result_relative_path(),
    "raw/repair/repair-result.superseded.md",
  )
  assert_eq(repair_skill_relative_path(), "skills/planbook-repair/SKILL.md")
  assert_eq(repair_plan_relative_path(), "plans/self-healing-repair/plan.md")
  assert_eq(repair_raw_dir(workspace_root), "\{workspace_root}/raw/repair")
  assert_eq(
    repair_task_id("live-runtime-recovery"),
    "planbook-repair-live-runtime-recovery",
  )
  assert_eq(
    repair_result_target_pages().join("|"),
    "raw/repair/repair-result.md|wiki/reviews/active-plan-review.md|wiki/planning/execution-evidence.md",
  )
  assert_eq(
    repair_context_pages().join("|"),
    "raw/repair/PLANBOOK_REPAIR_CONTEXT.md|plans/self-healing-repair/plan.md|wiki/planning/self-healing.md|wiki/reviews/active-plan-review.md",
  )
  assert_eq(repair_skill_paths().join("|"), "skills/planbook-repair/SKILL.md")
  assert_eq(
    repair_result_path_for_workspace(workspace_root),
    "\{workspace_root}/raw/repair/repair-result.md",
  )
  assert_eq(
    repair_superseded_result_path(workspace_root),
    "\{workspace_root}/raw/repair/repair-result.superseded.md",
  )
  assert_eq(
    repair_packet_path_for_criterion(workspace_root, "live-runtime-recovery"),
    "\{workspace_root}/raw/repair/planbook-repair-live-runtime-recovery.packet.json",
  )
  assert_eq(
    repair_job_index_path(workspace_root),
    "\{workspace_root}/.moonclaw/jobs/index/runs.json",
  )
  assert_eq(
    repair_job_proposals_path(workspace_root),
    "\{workspace_root}/.moonclaw/jobs/job_proposals.json",
  )
  assert_eq(
    repair_workspace_status_page_path(workspace_root),
    "\{workspace_root}/wiki/planning/self-healing-repair.md",
  )
}

///|
test "planbook repair request rules are package-owned policy" {
  let selected_rule = repair_selected_feature_task_rule()
  assert_eq(repair_request_task_rules().length(), 13)
  assert_true(
    repair_request_task_rules()[0].contains(
      "Read `skills/planbook-repair/SKILL.md`",
    ),
  )
  assert_true(
    repair_request_task_rules()[12].contains(
      "accepted source-root ACP patch receipt",
    ),
  )
  assert_true(selected_rule.contains("raw/editor-pipeline/next-feature.json"))
  assert_true(
    selected_rule.contains(
      @editor_pipeline.selected_feature_implementation_contract(),
    ),
  )
  assert_true(
    repair_result_write_task_rule().contains(repair_result_relative_path()),
  )
  assert_true(
    repair_result_write_task_rule().contains(repair_patch_receipt_contract()),
  )
  assert_true(
    repair_satisfaction_gate_task_rule().contains(
      "Do not mark the criterion satisfied",
    ),
  )
}

///|
test "planbook repair skill text is package-owned policy" {
  let skill = repair_skill_markdown()
  assert_true(skill.contains("name: planbook-repair"))
  assert_true(skill.contains("Repair one bounded PlanBook self-build gap"))
  assert_true(skill.contains("## Required Decision"))
  assert_true(skill.contains("repair_decision"))
  assert_true(
    skill.contains("accepted | needs_external_owner | blocked | no_change"),
  )
  assert_true(skill.contains(repair_patch_receipt_contract()))
  assert_true(
    skill.contains(@editor_pipeline.selected_feature_implementation_contract()),
  )
  assert_true(
    skill.contains(@skill_quality.exploration_quality_contract_section()),
  )
}

///|
test "accepted repair requires patch receipt evidence" {
  let weak = [
    "criterion_id: planbook-source-patch-loop",
    "repair_decision: accepted",
    "validation: passed",
    "diff_summary: changed source",
    "plan_update_status: updated",
    "commit_status: committed",
    "commit_message: Repair",
    "push_status: not_pushed_by_policy",
    repair_required_commands().join(" passed\n"),
  ].join("\n")
  assert_false(
    repair_result_satisfies_contract(
      weak, "planbook-source-patch-loop", "/repo",
    ),
  )
}

///|
test "accepted repair with valid patch receipt satisfies contract" {
  let receipt = sample_patch_receipt(
    "planbook-source-patch-loop", "/repo", "run-1",
  )
  let text = accepted_repair_text("planbook-source-patch-loop", receipt)
  assert_true(
    repair_result_satisfies_contract(
      text, "planbook-source-patch-loop", "/repo",
    ),
  )
}

///|
test "handoff and no-change decisions do not require patch receipt" {
  assert_true(
    repair_result_satisfies_contract(
      "criterion_id: moonbook-native-planbook-provider\nrepair_decision: needs_external_owner",
      "moonbook-native-planbook-provider", "/repo",
    ),
  )
  assert_true(
    repair_result_satisfies_contract(
      "criterion_id: live-autonomy-spine\nrepair_decision: no_change", "live-autonomy-spine",
      "/repo",
    ),
  )
}

///|
test "payload patch receipt enforces run id" {
  let receipt = sample_patch_receipt(
    "planbook-source-patch-loop", "/repo", "run-1",
  )
  let payload : Json = { "patch_receipt": receipt }
  assert_true(
    repair_payload_has_valid_patch_receipt(
      payload, "planbook-source-patch-loop", "/repo", "run-1",
    ),
  )
  assert_false(
    repair_payload_has_valid_patch_receipt(
      payload, "planbook-source-patch-loop", "/repo", "run-2",
    ),
  )
}

///|
test "moonclaw statuses map to repair task statuses" {
  assert_eq(moonclaw_status_bucket(Some("Pending")), "pending")
  assert_eq(moonclaw_status_bucket(Some("WaitingForInput")), "running")
  assert_eq(task_status_from_run_status(Some("Succeeded")), "completed")
  assert_eq(task_status_from_run_status(Some("Failed")), "failed")
  assert_eq(task_status_from_run_status(None), "dispatched")
}
