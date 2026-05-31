///|
async test "planbook autonomy doctor writes self-healing evidence" {
  let root = "/tmp/moontown-planbook-autonomy-wbtest"
  ignore_checked_command("rm", ["-rf", root])
  let snapshot_path = "\{root}/town.json"
  let workspace_root = "\{root}/books/plan-moontown-quality"
  let catalog_path = "\{root}/catalog.json"
  let message = write_moontown_planbook_autonomy(
    snapshot_path~,
    workspace_root~,
    book_catalog_path=catalog_path,
  )
  assert_true(message.contains("PlanBook autonomy status"))
  let status_text = read_text_or_empty(
    default_planbook_autonomy_path(snapshot_path~),
  )
  let evidence = read_text_or_empty(
    "\{workspace_root}/wiki/planning/execution-evidence.md",
  )
  let review = read_text_or_empty(
    "\{workspace_root}/wiki/reviews/active-plan-review.md",
  )
  assert_true(status_text.contains("\"status\": \"self-healing-open\""))
  assert_true(status_text.contains("moonbook-native-planbook-provider"))
  assert_true(evidence.contains("PlanBook autonomy doctor"))
  assert_true(review.contains("needs-fix"))
}

///|
async test "planbook validation evidence requires explicit validation contract" {
  assert_true(
    !planbook_validation_evidence_ready(
      "# Latest PlanBook Validation\n\n- moon check passed\n",
    ),
  )
  let root = "/tmp/moontown-planbook-validation-evidence-wbtest"
  ignore_checked_command("rm", ["-rf", root])
  let path = write_moontown_planbook_validation_evidence(
    snapshot_path="\{root}/town.json",
    note="test validation record",
  )
  let text = read_text_or_empty(path)
  assert_true(planbook_validation_evidence_ready(text))
  assert_true(text.contains("contract: planbook.validation.v1"))
  assert_true(text.contains("validation_status: passed"))
}

///|
async test "live autonomy includes planbook repair action" {
  let root = "/tmp/moontown-planbook-live-action-wbtest"
  ignore_checked_command("rm", ["-rf", root])
  let snapshot_path = "\{root}/town.json"
  let workspace_root = "\{root}/books/plan-moontown-quality"
  ignore(
    write_moontown_planbook_autonomy(
      snapshot_path~,
      workspace_root~,
      book_catalog_path="\{root}/catalog.json",
    ),
  )
  let state = visual_projection_test_state(
    worker_status=@core.WorkerStatus::Idle,
    execution_status=@core.TaskExecutionStatus::Completed,
  )
  let spine = write_live_autonomy_spine(
    state,
    snapshot_path~,
    tick_summary="planbook action check",
  )
  assert_true(spine.planbook_open_count > 0)
  assert_true(spine.next_actions.join("\n").contains("PlanBook has"))
  let status = render_live_autonomy_status(snapshot_path~)
  assert_true(status.contains("PlanBook open gaps"))
}

///|
async test "planbook repair queues bounded packet without marking it active before dispatch" {
  let root = "/tmp/moontown-planbook-repair-wbtest"
  ignore_checked_command("rm", ["-rf", root])
  let snapshot_path = "\{root}/town.json"
  let workspace_root = "\{root}/books/plan-moontown-quality"
  ignore(
    write_moontown_planbook_autonomy(
      snapshot_path~,
      workspace_root~,
      book_catalog_path="\{root}/catalog.json",
    ),
  )
  let message = write_moontown_planbook_repair_task(
    snapshot_path~,
    workspace_root~,
    book_catalog_path="\{root}/catalog.json",
  )
  assert_true(message.contains("PlanBook repair task"))
  let task_text = read_text_or_empty(
    default_planbook_repair_path(snapshot_path~),
  )
  let packet_text = read_text_or_empty(
    "\{workspace_root}/raw/repair/planbook-repair-semantic-ai-review-results.packet.json",
  )
  let skill_text = read_text_or_empty(
    "\{workspace_root}/skills/planbook-repair/SKILL.md",
  )
  let profile_text = read_text_or_empty("\{workspace_root}/moonclaw.jobs.json")
  assert_true(task_text.contains("\"status\": \"queued\""))
  assert_true(task_text.contains("semantic-ai-review-results"))
  assert_true(packet_text.contains("planbook.repair.result.v1"))
  assert_true(skill_text.contains("PlanBook Repair Skill"))
  assert_true(profile_text.contains("planbook_repair_worker"))
  assert_true(profile_text.contains("repair_planbook_gap"))
  assert_eq(planbook_repair_active_count(snapshot_path~), 0)
}

///|
async test "planbook repair supersedes stale runtime handoff evidence" {
  let root = "/tmp/moontown-planbook-repair-stale-handoff-wbtest"
  ignore_checked_command("rm", ["-rf", root])
  let workspace_root = "\{root}/books/plan-moontown-quality"
  let criterion : PlanbookCriterionStatus = {
    id: "live-runtime-recovery",
    plan_id: "test",
    title: "Live runtime failures are visible to PlanBook repair",
    owner: "moontown+moonclaw",
    satisfied: false,
    evidence: "1 failed/stale executions remain: research-opc/task-opc-watch",
    next_action: "repair the current failure set",
  }
  write_text_file(
    "\{workspace_root}/raw/repair/repair-result.md",
    [
      "repair_decision: needs_external_owner", "criterion_id: live-runtime-recovery",
      "remaining_blockers: 18 failed town executions remain.",
    ].join("\n"),
  )
  let task = materialize_planbook_repair_task(
    criterion,
    "\{root}/town.json",
    workspace_root,
    "\{root}/catalog.json",
    false,
  )
  let result_text = read_text_or_empty(
    "\{workspace_root}/raw/repair/repair-result.md",
  )
  let superseded = read_text_or_empty(
    "\{workspace_root}/raw/repair/repair-result.superseded.md",
  )
  assert_eq(task.status, "queued")
  assert_true(result_text == "")
  assert_true(superseded.contains("18 failed town executions"))
}

///|
async test "planbook repair acp target uses resolved codex command" {
  let root = "/tmp/moontown-planbook-repair-acp-target-wbtest"
  ignore_checked_command("rm", ["-rf", root])
  let workspace_root = "\{root}/books/plan-moontown-quality"
  let criterion : PlanbookCriterionStatus = {
    id: "live-runtime-recovery",
    plan_id: "test",
    title: "Live runtime failures are visible to PlanBook repair",
    owner: "moontown+moonclaw",
    satisfied: false,
    evidence: "1 failed/stale executions remain: research-opc/task-opc-watch",
    next_action: "repair the current failure set",
  }
  ignore(
    materialize_planbook_repair_task(
      criterion,
      "\{root}/town.json",
      workspace_root,
      "\{root}/catalog.json",
      false,
    ),
  )
  let target = read_text_or_empty("\{workspace_root}/.moonclaw/moonclaw.json")
  assert_true(
    target.contains(
      "\"command\": \"/Users/kq/.nvm/versions/node/v22.22.1/bin/node\"",
    ),
  )
  assert_true(
    target.contains(
      "/Users/kq/.nvm/versions/node/v22.22.1/lib/node_modules/@openai/codex/bin/codex.js",
    ),
  )
  assert_true(!target.contains("\"command\": \"codex\""))
}

///|
async test "planbook repair does not treat orphaned pending run as active" {
  let root = "/tmp/moontown-planbook-repair-pending-active-wbtest"
  ignore_checked_command("rm", ["-rf", root])
  let snapshot_path = "\{root}/town.json"
  let workspace_root = "\{root}/books/plan-moontown-quality"
  let task : PlanbookRepairTask = {
    id: "planbook-repair-live-runtime-recovery",
    criterion_id: "live-runtime-recovery",
    title: "Live runtime failures are visible to PlanBook repair",
    status: "dispatched",
    owner: "moontown+moonclaw",
    workspace_root,
    packet_path: "\{workspace_root}/raw/repair/planbook-repair-live-runtime-recovery.packet.json",
    proposal_id: Some("proposal"),
    run_id: Some("run-pending"),
    summary: "Pending repair",
    validation_command: "moon test",
    generated_at_ms: 1,
  }
  write_text_file(
    default_planbook_repair_path(snapshot_path~),
    task.to_json().stringify(indent=2),
  )
  write_text_file(
    "\{workspace_root}/.moonclaw/jobs/index/runs.json",
    "{\"runs\":[{\"id\":\"run-pending\",\"status\":\"Pending\"}]}",
  )
  assert_eq(planbook_repair_active_count(snapshot_path~), 0)
}

///|
async test "planbook repair does not treat orphaned waiting-for-input run as active" {
  let root = "/tmp/moontown-planbook-repair-waiting-active-wbtest"
  ignore_checked_command("rm", ["-rf", root])
  let snapshot_path = "\{root}/town.json"
  let workspace_root = "\{root}/books/plan-moontown-quality"
  let task : PlanbookRepairTask = {
    id: "planbook-repair-live-runtime-recovery",
    criterion_id: "live-runtime-recovery",
    title: "Live runtime failures are visible to PlanBook repair",
    status: "dispatched",
    owner: "moontown+moonclaw",
    workspace_root,
    packet_path: "\{workspace_root}/raw/repair/planbook-repair-live-runtime-recovery.packet.json",
    proposal_id: Some("proposal"),
    run_id: Some("run-waiting"),
    summary: "Waiting repair",
    validation_command: "moon test",
    generated_at_ms: 1,
  }
  write_text_file(
    default_planbook_repair_path(snapshot_path~),
    task.to_json().stringify(indent=2),
  )
  write_text_file(
    "\{workspace_root}/.moonclaw/jobs/index/runs.json",
    "{\"runs\":[{\"id\":\"run-waiting\",\"status\":\"WaitingForInput\"}]}",
  )
  assert_eq(planbook_repair_active_count(snapshot_path~), 0)
}

///|
async test "planbook repair does not treat orphaned running run as active" {
  let root = "/tmp/moontown-planbook-repair-orphaned-active-wbtest"
  ignore_checked_command("rm", ["-rf", root])
  let snapshot_path = "\{root}/town.json"
  let workspace_root = "\{root}/books/plan-moontown-quality"
  let task : PlanbookRepairTask = {
    id: "planbook-repair-live-runtime-recovery",
    criterion_id: "live-runtime-recovery",
    title: "Live runtime failures are visible to PlanBook repair",
    status: "dispatched",
    owner: "moontown+moonclaw",
    workspace_root,
    packet_path: "\{workspace_root}/raw/repair/planbook-repair-live-runtime-recovery.packet.json",
    proposal_id: Some("proposal"),
    run_id: Some("run-orphaned"),
    summary: "Orphaned repair",
    validation_command: "moon test",
    generated_at_ms: 1,
  }
  write_text_file(
    default_planbook_repair_path(snapshot_path~),
    task.to_json().stringify(indent=2),
  )
  write_text_file(
    "\{workspace_root}/.moonclaw/jobs/index/runs.json",
    "{\"runs\":[{\"id\":\"run-orphaned\",\"status\":\"Running\"}]}",
  )
  assert_eq(planbook_repair_active_count(snapshot_path~), 0)
}
