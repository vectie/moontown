///|
async test "planbook repair queues bounded packet without marking it active before dispatch" {
  let workspace = planbook_autonomy_test_workspace(
    "/tmp/moontown-planbook-repair-wbtest",
  )
  let snapshot_path = workspace.snapshot_path
  let workspace_root = workspace.workspace_root
  ignore(
    write_moontown_planbook_autonomy(
      snapshot_path~,
      workspace_root~,
      book_catalog_path=workspace.catalog_path,
    ),
  )
  let message = write_moontown_planbook_repair_task(
    snapshot_path~,
    workspace_root~,
    book_catalog_path=workspace.catalog_path,
  )
  assert_true(message.contains("PlanBook repair task"))
  let task_text = read_text_or_empty(
    default_planbook_repair_path(snapshot_path~),
  )
  let task_json = @json.parse(task_text) catch {
    _ => abort("repair task should be valid JSON")
  }
  let task : PlanbookRepairTask = @json.from_json(task_json) catch {
    _ => abort("repair task should satisfy PlanbookRepairTask")
  }
  let packet_text = read_text_or_empty(task.packet_path)
  let skill_text = read_text_or_empty(
    planbook_repair_path_in_workspace(
      workspace_root,
      planbook_repair_skill_relative_path(),
    ),
  )
  let profile_text = read_text_or_empty("\{workspace_root}/moonclaw.jobs.json")
  assert_eq(task.status, "queued")
  assert_true(task.id.contains(task.criterion_id))
  assert_true(task.packet_path.contains(task.id))
  assert_true(packet_text.contains(planbook_repair_result_contract()))
  assert_true(packet_text.contains(task.criterion_id))
  assert_true(packet_text.contains("\"target_files\""))
  assert_true(
    packet_text.contains("\"execution_mode\":\"acp\"") ||
    packet_text.contains("\"execution_mode\": \"acp\""),
  )
  assert_true(
    packet_text.contains("\"execution_target\":\"codex-main\"") ||
    packet_text.contains("\"execution_target\": \"codex-main\""),
  )
  assert_true(packet_text.contains("required_engineering_steps"))
  assert_true(packet_text.contains("required_validation_commands"))
  assert_true(packet_text.contains("git_policy"))
  assert_true(packet_text.contains("commit_after_validation"))
  assert_true(packet_text.contains("commit_only_repair_owned_files"))
  assert_true(
    packet_text.contains("preserve_preexisting_unrelated_dirty_files"),
  )
  assert_true(packet_text.contains("push_after_commit"))
  assert_true(packet_text.contains("\"best_effort_on_timeout\":false"))
  assert_true(skill_text.contains("PlanBook Repair Skill"))
  assert_true(skill_text.contains("Use exact `target_files`"))
  assert_true(skill_text.contains("configured Codex ACP target"))
  assert_true(skill_text.contains("repository source root"))
  assert_true(skill_text.contains("diff_summary"))
  assert_true(skill_text.contains("commit_status"))
  assert_true(skill_text.contains("repair-owned files"))
  assert_true(skill_text.contains("pre-existing unrelated dirty files"))
  assert_true(skill_text.contains("git diff --check"))
  assert_true(skill_text.contains("git status --short"))
  assert_true(profile_text.contains("planbook_repair_worker"))
  assert_true(profile_text.contains("repair_planbook_gap"))
  assert_true(profile_text.contains("\"execution_mode\": \"acp\""))
  assert_true(profile_text.contains("\"execution_target\": \"codex-main\""))
  assert_eq(planbook_repair_active_count(snapshot_path~), 0)
}

///|
test "planbook source patch loop target list covers self patch plumbing" {
  let targets = planbook_repair_target_files("planbook-source-patch-loop").join(
    "\n",
  )
  assert_true(targets.contains("planbook_repair_active.mbt"))
  assert_true(targets.contains("planbook_repair_targets.mbt"))
  assert_true(targets.contains("planbook_repair_request_rules.mbt"))
  assert_true(targets.contains("planbook_repair_skill_page.mbt"))
  assert_true(targets.contains("adapters/moonclaw/run_polling.mbt"))
  assert_true(targets.contains("live_autonomy_wbtest.mbt"))
  assert_true(targets.contains("../moonclaw/acp/runner.mbt"))
  assert_true(targets.contains("../moonclaw/job/analysis_contracts.mbt"))
}

///|
test "planbook live runtime recovery target list covers reconciliation plumbing" {
  let targets = planbook_repair_target_files("live-runtime-recovery").join("\n")
  assert_true(targets.contains("planbook_autonomy_criteria_runtime.mbt"))
  assert_true(targets.contains("planbook_repair_targets.mbt"))
  assert_true(targets.contains("goal_supervision_recovery.mbt"))
  assert_true(targets.contains("goal_supervision_transient_infra_wbtest.mbt"))
  assert_true(targets.contains("standing_watch_recovery_policy.mbt"))
  assert_true(targets.contains("standing_watch_recovery_legacy.mbt"))
  assert_true(targets.contains("live_autonomy_wbtest.mbt"))
  assert_true(targets.contains("adapters/moonclaw/run_polling.mbt"))
  assert_true(targets.contains("../moonclaw/job/analysis_acp_runner.mbt"))
}

///|
async test "planbook backlog item can drive bounded repair packet from json" {
  let workspace = planbook_autonomy_test_workspace(
    "/tmp/moontown-planbook-backlog-repair-wbtest",
  )
  let snapshot_path = workspace.snapshot_path
  let workspace_root = workspace.workspace_root
  ignore(
    bootstrap_moontown_planbook(
      book_catalog_path=workspace.catalog_path,
      workspace_root~,
    ),
  )
  let item = match first_open_planbook_backlog_item(workspace_root) {
    Some(item) => item
    None => fail("expected open backlog item")
  }
  let criterion = planbook_backlog_criterion_for_item(item, workspace_root)
  let task = materialize_planbook_repair_task(
    criterion,
    snapshot_path,
    workspace_root,
    workspace.catalog_path,
    false,
    false,
  )
  let packet_text = read_text_or_empty(task.packet_path)
  let skill_text = read_text_or_empty(
    planbook_repair_path_in_workspace(
      workspace_root,
      planbook_repair_skill_relative_path(),
    ),
  )
  assert_true(task.criterion_id.contains("backlog-"))
  assert_true(packet_text.contains("implementation-backlog.json"))
  assert_true(packet_text.contains("raw/backlog/completed"))
  assert_true(skill_text.contains("For `backlog-*` criteria"))
  assert_true(skill_text.contains("already done"))
  assert_true(skill_text.contains("plan_update_status"))
  assert_eq(planbook_repair_active_count(snapshot_path~), 0)
}

///|
async test "planbook repair supersedes stale runtime handoff evidence" {
  let workspace = planbook_autonomy_test_workspace(
    "/tmp/moontown-planbook-repair-stale-handoff-wbtest",
  )
  let workspace_root = workspace.workspace_root
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
    planbook_repair_result_path_for_workspace(workspace_root),
    [
      "repair_decision: needs_external_owner", "criterion_id: live-runtime-recovery",
      "remaining_blockers: 18 failed town executions remain.",
    ].join("\n"),
  )
  let task = materialize_planbook_repair_task(
    criterion,
    workspace.snapshot_path,
    workspace_root,
    workspace.catalog_path,
    false,
    false,
  )
  let result_text = read_text_or_empty(
    planbook_repair_result_path_for_workspace(workspace_root),
  )
  let superseded = read_text_or_empty(
    planbook_repair_superseded_result_path(workspace_root),
  )
  assert_eq(task.status, "queued")
  assert_true(result_text == "")
  assert_true(superseded.contains("18 failed town executions"))
}

///|
async test "planbook repair retries source patch loop after blocked result without receipt" {
  let workspace = planbook_autonomy_test_workspace(
    "/tmp/moontown-planbook-repair-source-patch-stale-result-wbtest",
  )
  let workspace_root = workspace.workspace_root
  let criterion : PlanbookCriterionStatus = {
    id: "planbook-source-patch-loop",
    plan_id: "test",
    title: "PlanBook repair can patch repository source through Codex ACP",
    owner: "moontown+moonclaw+codex-acp",
    satisfied: false,
    evidence: "no accepted patch receipt",
    next_action: "retry through ACP source patch loop",
  }
  write_text_file(
    planbook_repair_result_path_for_workspace(workspace_root),
    [
      "contract: planbook.repair.result.v1", "repair_decision: blocked", "criterion_id: planbook-source-patch-loop",
      "validation:", "  - moon check --no-render: passed", "diff_summary: previous run blocked before receipt",
      "plan_update_status: unchanged", "commit_status: blocked", "commit_message: Repair PlanBook patch receipt metadata",
      "push_status: not_pushed_by_policy", "patch_receipt: not_applicable_for_blocked_result",
    ].join("\n"),
  )
  let task = materialize_planbook_repair_task(
    criterion,
    workspace.snapshot_path,
    workspace_root,
    workspace.catalog_path,
    false,
    false,
  )
  let result_text = read_text_or_empty(
    planbook_repair_result_path_for_workspace(workspace_root),
  )
  let superseded = read_text_or_empty(
    planbook_repair_superseded_result_path(workspace_root),
  )
  assert_eq(task.status, "queued")
  assert_true(result_text == "")
  assert_true(superseded.contains("patch_receipt: not_applicable"))
}

///|
test "planbook repair ignores stale task when criterion is now satisfied" {
  let task : PlanbookRepairTask = {
    id: "planbook-repair-runtime-books-in-quality-audit",
    criterion_id: "runtime-books-in-quality-audit",
    title: "Active live runtime books are included in MoonBook quality audit",
    status: "failed",
    owner: "moontown+moonbook",
    workspace_root: "/tmp/planbook",
    packet_path: "/tmp/planbook/raw/repair/planbook-repair-runtime-books-in-quality-audit.packet.json",
    proposal_id: Some("proposal-1"),
    run_id: Some("run-1"),
    summary: "stale runtime repair task",
    validation_command: planbook_repair_validation_command(),
    generated_at_ms: 1,
  }
  let status : PlanbookAutonomyStatus = {
    generated_at_ms: 1,
    book_id: default_planbook_book_id(),
    workspace_root: "/tmp/planbook",
    status: "self-healing-open",
    open_count: 1,
    satisfied_count: 1,
    criteria: [
      {
        id: "runtime-books-in-quality-audit",
        plan_id: "test",
        title: "Active live runtime books are included in MoonBook quality audit",
        owner: "moontown+moonbook",
        satisfied: true,
        evidence: "quality audit covers active live runtime books",
        next_action: "none",
      },
      {
        id: "planbook-source-patch-loop",
        plan_id: "test",
        title: "PlanBook repair can patch repository source through Codex ACP",
        owner: "moontown+moonclaw+codex-acp",
        satisfied: false,
        evidence: "no accepted patch receipt",
        next_action: "route PlanBook repair through Codex ACP",
      },
    ],
  }
  assert_true(planbook_repair_task_satisfied_by_status(task, status))
  match first_planbook_open_criterion(status) {
    Some(open) => assert_eq(open.id, "planbook-source-patch-loop")
    None => abort("expected open self-patching criterion")
  }
}

///|
async test "planbook repair acp target uses resolved codex command" {
  let workspace = planbook_autonomy_test_workspace(
    "/tmp/moontown-planbook-repair-acp-target-wbtest",
  )
  let workspace_root = workspace.workspace_root
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
      workspace.snapshot_path,
      workspace_root,
      workspace.catalog_path,
      false,
      false,
    ),
  )
  let target = read_text_or_empty("\{workspace_root}/.moonclaw/moonclaw.json")
  let source_root = planbook_repair_source_root()
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
  assert_true(target.contains("\"--sandbox\""))
  assert_true(target.contains("\"workspace-write\""))
  assert_true(!target.contains("\"command\": \"codex\""))
  assert_true(target.contains("\"cwd\": \"\{source_root}\""))
  assert_true(target.contains("\"workspace\": \"\{source_root}\""))
  assert_true(!target.contains("\"cwd\": \"\{workspace_root}\""))
}
