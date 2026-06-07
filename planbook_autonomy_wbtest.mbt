///|
async test "planbook autonomy doctor writes self-healing evidence" {
  let workspace = planbook_autonomy_test_workspace(
    "/tmp/moontown-planbook-autonomy-wbtest",
  )
  let message = write_moontown_planbook_autonomy(
    snapshot_path=workspace.snapshot_path,
    workspace_root=workspace.workspace_root,
    book_catalog_path=workspace.catalog_path,
  )
  assert_true(message.contains("PlanBook autonomy status"))
  let status_text = read_text_or_empty(
    default_planbook_autonomy_path(snapshot_path=workspace.snapshot_path),
  )
  let evidence = read_text_or_empty(
    "\{workspace.workspace_root}/wiki/planning/execution-evidence.md",
  )
  let review = read_text_or_empty(
    "\{workspace.workspace_root}/wiki/reviews/active-plan-review.md",
  )
  let backlog = read_text_or_empty(
    "\{workspace.workspace_root}/wiki/planning/implementation-backlog.md",
  )
  let change_log = read_text_or_empty(
    "\{workspace.workspace_root}/wiki/history/change-log.md",
  )
  let engineering_digest = read_text_or_empty(
    "\{workspace.workspace_root}/wiki/history/daily-engineering-digest.md",
  )
  let progress = read_text_or_empty(
    "\{workspace.workspace_root}/wiki/planning/backlog-progress.md",
  )
  let stop_policy = read_text_or_empty(
    "\{workspace.workspace_root}/wiki/planning/stop-policy.md",
  )
  let role_model = read_text_or_empty(
    "\{workspace.workspace_root}/wiki/planning/role-model.md",
  )
  let operating_architecture = read_text_or_empty(
    "\{workspace.workspace_root}/wiki/planning/operating-architecture.md",
  )
  assert_true(status_text.contains("\"status\": \"self-healing-open\""))
  assert_true(status_text.contains("editor-mode-real-pipeline"))
  assert_true(status_text.contains("planbook-source-patch-loop"))
  assert_true(status_text.contains("planbook-software-engineering-loop"))
  assert_true(status_text.contains("backlog-live-change-log-projection"))
  assert_true(status_text.contains("moonbook-native-planbook-provider"))
  assert_true(evidence.contains("PlanBook autonomy doctor"))
  assert_true(review.contains("needs-fix"))
  assert_true(backlog.contains("live-change-log-projection"))
  assert_true(change_log.contains("autonomy doctor"))
  assert_true(engineering_digest.contains("Daily Engineering Digest"))
  assert_true(engineering_digest.contains("Source-Control Policy"))
  assert_true(progress.contains("next_check_interval_ms"))
  assert_true(progress.contains("take the next bounded task immediately"))
  assert_true(stop_policy.contains("The town should stop implementing"))
  assert_true(stop_policy.contains("already complete"))
  assert_true(role_model.contains("Mayor"))
  assert_true(role_model.contains("MoonBook Bookkeeper"))
  assert_true(role_model.contains("MoonClaw Worker"))
  assert_true(role_model.contains("freelance executor"))
  assert_true(operating_architecture.contains("Operating Architecture"))
  assert_true(operating_architecture.contains("Growth Contract"))
  assert_true(operating_architecture.contains("Civic Wiring Rule"))
}

///|
async test "planbook validation evidence requires explicit validation contract" {
  assert_true(
    !planbook_validation_evidence_ready(
      "# Latest PlanBook Validation\n\n- moon check passed\n",
    ),
  )
  let workspace = planbook_autonomy_test_workspace(
    "/tmp/moontown-planbook-validation-evidence-wbtest",
  )
  let path = write_moontown_planbook_validation_evidence(
    snapshot_path=workspace.snapshot_path,
    note="test validation record",
  )
  let text = read_text_or_empty(path)
  assert_true(planbook_validation_evidence_ready(text))
  assert_true(text.contains("contract: planbook.validation.v1"))
  assert_true(text.contains("validation_status: passed"))
}

///|
async test "planbook autonomy doctor repairs missing seed architecture page" {
  let workspace = planbook_autonomy_test_workspace(
    "/tmp/moontown-planbook-seed-repair-wbtest",
  )
  write_text_file(
    "\{workspace.workspace_root}/wiki/index.md",
    "# Existing PlanBook\n\nDo not overwrite existing operator-authored content.",
  )
  ignore(
    write_moontown_planbook_autonomy(
      snapshot_path=workspace.snapshot_path,
      workspace_root=workspace.workspace_root,
      book_catalog_path=workspace.catalog_path,
    ),
  )
  let index = read_text_or_empty("\{workspace.workspace_root}/wiki/index.md")
  let operating_architecture = read_text_or_empty(
    "\{workspace.workspace_root}/wiki/planning/operating-architecture.md",
  )
  assert_true(index.contains("Do not overwrite existing"))
  assert_true(operating_architecture.contains("Operating Architecture"))
  assert_true(operating_architecture.contains("Stable Watch State"))
}

///|
async test "live autonomy includes planbook repair action" {
  let workspace = planbook_autonomy_test_workspace(
    "/tmp/moontown-planbook-live-action-wbtest",
  )
  ignore(
    write_moontown_planbook_autonomy(
      snapshot_path=workspace.snapshot_path,
      workspace_root=workspace.workspace_root,
      book_catalog_path=workspace.catalog_path,
    ),
  )
  let state = visual_projection_test_state(
    worker_status=@core.WorkerStatus::Idle,
    execution_status=@core.TaskExecutionStatus::Completed,
  )
  let spine = write_live_autonomy_spine(
    state,
    snapshot_path=workspace.snapshot_path,
    tick_summary="planbook action check",
  )
  assert_true(spine.planbook_open_count > 0)
  assert_true(spine.next_actions.join("\n").contains("PlanBook has"))
  let status = render_live_autonomy_status(
    snapshot_path=workspace.snapshot_path,
  )
  assert_true(status.contains("PlanBook open gaps"))
}
