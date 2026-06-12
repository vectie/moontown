///|
test "runtime status policy ranks terminal records above live snapshots" {
  assert_true(
    execution_status_rank(@core.TaskExecutionStatus::Completed) >
    execution_status_rank(@core.TaskExecutionStatus::Running),
  )
  assert_eq(
    execution_status_rank(@core.TaskExecutionStatus::AwaitingPersistence),
    execution_status_rank(@core.TaskExecutionStatus::Running),
  )
}

///|
test "runtime status policy owns active and review execution sets" {
  assert_true(
    runtime_status_active_execution_status(@core.TaskExecutionStatus::Running),
  )
  assert_true(
    runtime_status_active_execution_status(
      @core.TaskExecutionStatus::AwaitingPersistence,
    ),
  )
  assert_false(
    runtime_status_active_execution_status(
      @core.TaskExecutionStatus::ReviewQueued,
    ),
  )
  assert_true(
    runtime_status_review_execution_status(
      @core.TaskExecutionStatus::ReviewQueued,
    ),
  )
  assert_false(
    runtime_status_review_execution_status(@core.TaskExecutionStatus::Completed),
  )
}

///|
fn runtime_status_policy_test_state() -> @core.TownState {
  @core.empty_state(
    @core.TownConfig::new(
      id="runtime-status-policy",
      name="Runtime Status Policy",
    ),
  )
}

///|
fn runtime_status_policy_test_execution(
  task_id : String,
  status : @core.TaskExecutionStatus,
  packet_id? : String = task_id,
) -> @core.TaskExecutionRecord {
  @core.TaskExecutionRecord::new(
    task_id~,
    book_id="book-runtime",
    packet_id~,
    packet_path="\{packet_id}.json",
    run_id=None,
    status~,
    summary="runtime status policy test",
    output_contract="test",
  )
}

///|
test "runtime status policy owns effective execution dedupe" {
  let state = runtime_status_policy_test_state()
  state.register_execution(
    runtime_status_policy_test_execution(
      "task-dup",
      @core.TaskExecutionStatus::Running,
      packet_id="packet-running",
    ),
  )
  state.register_execution(
    runtime_status_policy_test_execution(
      "task-dup",
      @core.TaskExecutionStatus::AwaitingPersistence,
      packet_id="packet-awaiting",
    ),
  )
  assert_false(effective_execution_record(state, 0))
  assert_true(effective_execution_record(state, 1))
  let indexes = effective_execution_indexes(state)
  assert_eq(indexes.length(), 1)
  assert_eq(indexes[0], 1)
}

///|
test "runtime status policy counts only effective executions" {
  let state = runtime_status_policy_test_state()
  state.register_execution(
    runtime_status_policy_test_execution(
      "task-live",
      @core.TaskExecutionStatus::Running,
    ),
  )
  state.register_execution(
    runtime_status_policy_test_execution(
      "task-done",
      @core.TaskExecutionStatus::Completed,
    ),
  )
  assert_eq(
    count_active_work_executions_in_indexes(
      state,
      effective_execution_indexes(state),
    ),
    1,
  )
}

///|
test "runtime status policy summarizes metric groups" {
  let state = @core.empty_state(
    @core.TownConfig::new(id="runtime-status-policy-test", name="Test Town"),
  )
  let summary = runtime_status_summary(
    state,
    { running: 1, review: 2, failed: 3, stale: 4, completed: 5 },
    { total: 6, enabled: 5, disabled: 1, due: 2 },
    7,
    { total: 8, pending: 9, failed: 10 },
    11,
  )
  assert_true(summary.contains("books=0 workers=0 tasks=0 executions=0"))
  assert_true(summary.contains("running=1 review=2 failed=3 stale=4"))
  assert_true(
    summary.contains(
      "standing_goals=6 enabled_standing_goals=5 disabled_standing_goals=1 due_goals=2",
    ),
  )
  assert_true(
    summary.contains(
      "book_template_requests=8 pending_template_requests=9 failed_template_requests=10",
    ),
  )
  assert_true(summary.contains("watcher_records=7 planned_actions=11"))
}

///|
test "runtime status policy renders operator report details" {
  let status = empty_runtime_status("/tmp/town.json")
  let text = render_runtime_status_report(
    status,
    daemon_id="daemon-test",
    saved_tick=9,
    lease_owner="mayor",
    daemon_job_count=2,
    runtime_health_summary="runtime=healthy",
  )
  assert_true(text.contains("snapshot=/tmp/town.json"))
  assert_true(
    text.contains("daemon=daemon-test tick=0 saved_tick=9 lease=mayor jobs=2"),
  )
  assert_true(text.contains("runtime=healthy"))
  assert_true(text.contains("book_template_latest_event=none"))
  assert_true(text.contains("planned daemon actions=0"))
}
