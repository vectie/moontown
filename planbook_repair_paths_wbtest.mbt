///|
test "planbook repair paths centralize durable workspace layout" {
  let workspace_root = "/tmp/moontown-planbook-repair-paths"
  assert_eq(planbook_repair_result_contract(), "planbook.repair.result.v1")
  assert_eq(
    @planbook_policy.repair_raw_dir(workspace_root),
    "\{workspace_root}/raw/repair",
  )
  assert_eq(
    planbook_repair_task_id("live-runtime-recovery"),
    "planbook-repair-live-runtime-recovery",
  )
  assert_eq(
    @planbook_policy.repair_context_relative_path(),
    "raw/repair/PLANBOOK_REPAIR_CONTEXT.md",
  )
  assert_eq(
    planbook_repair_result_relative_path(),
    "raw/repair/repair-result.md",
  )
  assert_eq(
    @planbook_policy.repair_skill_relative_path(),
    "skills/planbook-repair/SKILL.md",
  )
  assert_eq(
    @planbook_policy.repair_plan_relative_path(),
    "plans/self-healing-repair/plan.md",
  )
  assert_eq(
    planbook_repair_result_path_for_workspace(workspace_root),
    "\{workspace_root}/raw/repair/repair-result.md",
  )
  assert_eq(
    planbook_repair_superseded_result_path(workspace_root),
    "\{workspace_root}/raw/repair/repair-result.superseded.md",
  )
  assert_eq(
    planbook_repair_packet_path_for_criterion(
      workspace_root, "live-runtime-recovery",
    ),
    "\{workspace_root}/raw/repair/planbook-repair-live-runtime-recovery.packet.json",
  )
  assert_eq(
    moonclaw_run_result_path("\{workspace_root}/.moonclaw/run-1"),
    "\{workspace_root}/.moonclaw/run-1/result.json",
  )
  assert_eq(
    planbook_repair_context_path(workspace_root),
    "\{workspace_root}/raw/repair/PLANBOOK_REPAIR_CONTEXT.md",
  )
  assert_eq(
    planbook_repair_skill_path(workspace_root),
    "\{workspace_root}/skills/planbook-repair/SKILL.md",
  )
  assert_eq(
    planbook_repair_plan_path(workspace_root),
    "\{workspace_root}/plans/self-healing-repair/plan.md",
  )
  assert_eq(
    planbook_repair_job_index_path(workspace_root),
    "\{workspace_root}/.moonclaw/jobs/index/runs.json",
  )
  assert_eq(
    planbook_repair_job_proposals_path(workspace_root),
    "\{workspace_root}/.moonclaw/jobs/job_proposals.json",
  )
  assert_eq(
    planbook_repair_workspace_status_page_path(workspace_root),
    "\{workspace_root}/wiki/planning/self-healing-repair.md",
  )
}

///|
test "planbook repair packet page lists share the same layout helpers" {
  assert_eq(
    planbook_repair_context_pages().join("|"),
    "raw/repair/PLANBOOK_REPAIR_CONTEXT.md|plans/self-healing-repair/plan.md|wiki/planning/self-healing.md|wiki/reviews/active-plan-review.md",
  )
  assert_eq(
    planbook_repair_skill_paths().join("|"),
    "skills/planbook-repair/SKILL.md",
  )
  assert_eq(
    planbook_repair_result_target_pages().join("|"),
    "raw/repair/repair-result.md|wiki/reviews/active-plan-review.md|wiki/planning/execution-evidence.md",
  )
}

///|
test "planbook repair result contract accepts structured non-accepted decisions" {
  assert_true(
    planbook_repair_result_satisfies_contract(
      "{\"criterion_id\":\"live-runtime-recovery\",\"repair_decision\":\"blocked\"}",
      "live-runtime-recovery",
    ),
  )
  assert_true(
    planbook_repair_result_satisfies_contract(
      [
        "\"criterion_id\": \"live-runtime-recovery\"", "\"repair_decision\": \"needs_external_owner\"",
      ].join("\n"),
      "live-runtime-recovery",
    ),
  )
  assert_true(
    !planbook_repair_result_satisfies_contract(
      "{\"criterion_id\":\"live-runtime-recovery\",\"repair_decision\":\"accepted\"}",
      "live-runtime-recovery",
    ),
  )
}

///|
test "planbook repair result helpers classify decisions and evidence markers" {
  let criterion_id = "live-runtime-recovery"
  let receipt : Json = {
    "contract": @planbook_policy.repair_patch_receipt_contract(),
    "criterion_id": criterion_id,
    "source_root": planbook_repair_source_root(),
    "execution_mode": "acp",
    "execution_target": "codex-main",
    "run_id": "run-1",
    "acp_run_id": "acp-run-1",
    "base_head": "0000001",
    "final_head": "0000002",
    "changed_files": ["planbook_repair_result.mbt"],
    "validation_commands": planbook_repair_required_commands(),
    "diff_check_status": "passed",
    "commit_status": "committed",
    "commit_sha": "0000002",
    "commit_message": "Repair live runtime",
    "push_status": "not_pushed_by_policy",
    "result_decision": "accepted",
  }
  let accepted = [
    "repair_decision: accepted",
    "criterion_id: \{criterion_id}",
    ..planbook_repair_required_commands().map(fn(command) {
      "validation: \{command} passed"
    }),
    "diff_summary: git diff --check passed",
    "plan_update_status: unchanged",
    "commit_status: committed",
    "commit_message: Repair live runtime",
    "push_status: not_pushed_by_policy",
    @planbook_policy.repair_patch_receipt_text(receipt),
  ].join("\n")
  let marker_only_accepted = [
    "repair_decision: accepted",
    "criterion_id: \{criterion_id}",
    "validation: ok",
    "diff_summary: clean",
    "plan_update_status: unchanged",
    "commit_status: ready_to_commit",
    "commit_message: Repair live runtime",
    "push_status: not_pushed_by_policy",
  ].join("\n")
  let handoff = [
    "\"criterion_id\": \"live-runtime-recovery\"", "\"repair_decision\": \"needs_external_owner\"",
  ].join("\n")
  let blocked = [
    "criterion_id: live-runtime-recovery", "repair_decision: blocked",
  ].join("\n")
  let no_change = [
    "criterion_id: live-runtime-recovery", "repair_decision: no_change",
  ].join("\n")
  assert_true(
    @planbook_policy.repair_result_mentions_criterion(
      accepted, "live-runtime-recovery",
    ),
  )
  assert_true(@planbook_policy.repair_result_has_accepted_decision(accepted))
  assert_true(
    @planbook_policy.repair_result_has_external_owner_decision(handoff),
  )
  assert_true(@planbook_policy.repair_result_has_blocked_decision(blocked))
  assert_true(@planbook_policy.repair_result_has_no_change_decision(no_change))
  assert_true(@planbook_policy.repair_result_has_handoff_decision(handoff))
  assert_true(@planbook_policy.repair_result_has_handoff_decision(blocked))
  assert_true(!@planbook_policy.repair_result_has_handoff_decision(no_change))
  assert_true(@planbook_policy.repair_result_has_engineering_evidence(accepted))
  assert_true(
    !@planbook_policy.repair_result_has_engineering_evidence(
      marker_only_accepted,
    ),
  )
  assert_eq(
    @planbook_policy.repair_result_engineering_evidence_markers().join("|"),
    "validation:|diff_summary:|plan_update_status:|commit_status:|commit_message:|push_status:",
  )
}

///|
test "planbook repair run status predicates centralize moonclaw lifecycle mapping" {
  assert_eq(@planbook_policy.moonclaw_status_bucket(Some("Pending")), "pending")
  assert_eq(@planbook_policy.moonclaw_status_bucket(Some("Running")), "running")
  assert_eq(
    @planbook_policy.moonclaw_status_bucket(Some("WaitingForInput")),
    "running",
  )
  assert_eq(
    @planbook_policy.moonclaw_status_bucket(Some("Succeeded")),
    "succeeded",
  )
  assert_eq(
    @planbook_policy.moonclaw_status_bucket(Some("Failed")),
    "failed-terminal",
  )
  assert_eq(
    @planbook_policy.moonclaw_status_bucket(Some("Cancelled")),
    "failed-terminal",
  )
  assert_eq(@planbook_policy.moonclaw_status_bucket(Some("Unknown")), "unknown")
  assert_eq(@planbook_policy.moonclaw_status_bucket(None), "unknown")
  assert_true(@planbook_policy.moonclaw_status_is_pending("Pending"))
  assert_true(!@planbook_policy.moonclaw_status_is_pending("Running"))
  assert_true(@planbook_policy.moonclaw_status_is_running("Running"))
  assert_true(@planbook_policy.moonclaw_status_is_running("WaitingForInput"))
  assert_true(!@planbook_policy.moonclaw_status_is_running("Succeeded"))
  assert_true(@planbook_policy.moonclaw_status_is_succeeded("Succeeded"))
  assert_true(!@planbook_policy.moonclaw_status_is_succeeded("Running"))
  assert_true(@planbook_policy.moonclaw_status_is_failed_terminal("Failed"))
  assert_true(@planbook_policy.moonclaw_status_is_failed_terminal("Cancelled"))
  assert_true(!@planbook_policy.moonclaw_status_is_failed_terminal("Succeeded"))
  assert_true(@planbook_policy.moonclaw_status_needs_live_runner("Pending"))
  assert_true(@planbook_policy.moonclaw_status_needs_live_runner("Running"))
  assert_true(
    @planbook_policy.moonclaw_status_needs_live_runner("WaitingForInput"),
  )
  assert_true(!@planbook_policy.moonclaw_status_needs_live_runner("Succeeded"))
  assert_eq(
    @planbook_policy.task_status_from_run_status(Some("Pending")),
    "dispatched",
  )
  assert_eq(
    @planbook_policy.task_status_from_run_status(Some("Running")),
    "running",
  )
  assert_eq(
    @planbook_policy.task_status_from_run_status(Some("WaitingForInput")),
    "running",
  )
  assert_eq(
    @planbook_policy.task_status_from_run_status(Some("Succeeded")),
    "failed",
  )
  assert_eq(
    @planbook_policy.task_status_from_run_status(Some("Failed")),
    "failed",
  )
  assert_eq(
    @planbook_policy.task_status_from_run_status(Some("Cancelled")),
    "failed",
  )
  assert_eq(
    @planbook_policy.task_status_from_run_status(Some("Unknown")),
    "dispatched",
  )
  assert_eq(@planbook_policy.task_status_from_run_status(None), "dispatched")
}
