///|
test "live autonomy metric predicates name active worker and execution rules" {
  assert_true(
    worker_is_live(
      live_autonomy_worker_fixture(
        id="running",
        name="Running",
        status=@core.WorkerStatus::Running,
      ),
    ),
  )
  assert_true(
    worker_is_live(
      live_autonomy_worker_fixture(
        id="waiting",
        name="Waiting",
        status=@core.WorkerStatus::Waiting,
      ),
    ),
  )
  assert_true(
    worker_is_live(
      live_autonomy_worker_fixture(
        id="blocked",
        name="Blocked",
        status=@core.WorkerStatus::Blocked,
      ),
    ),
  )
  assert_false(
    worker_is_live(
      live_autonomy_worker_fixture(
        id="idle",
        name="Idle",
        status=@core.WorkerStatus::Idle,
      ),
    ),
  )
  assert_true(
    execution_status_in(@core.TaskExecutionStatus::Running, [
      @core.TaskExecutionStatus::ProposalImported,
      @core.TaskExecutionStatus::Running,
    ]),
  )
  assert_false(
    execution_status_in(@core.TaskExecutionStatus::Completed, [
      @core.TaskExecutionStatus::ProposalImported,
      @core.TaskExecutionStatus::Running,
    ]),
  )
  assert_true(
    execution_status_in(
      @core.TaskExecutionStatus::AwaitingPersistence,
      active_execution_statuses(),
    ),
  )
  assert_false(
    execution_status_in(
      @core.TaskExecutionStatus::ReviewQueued,
      active_execution_statuses(),
    ),
  )
  assert_true(
    execution_status_in(
      @core.TaskExecutionStatus::ReviewQueued,
      review_execution_statuses(),
    ),
  )
}

///|
test "live autonomy transient infrastructure debt predicate is explicit" {
  let deferred = live_autonomy_execution_fixture(
    task_id="task-deferred",
    status=@core.TaskExecutionStatus::Failed,
    summary="transient issue",
    result_decision="deferred-transient-infrastructure",
  )
  let failed = live_autonomy_execution_fixture(
    task_id="task-failed",
    status=@core.TaskExecutionStatus::Failed,
    summary="hard failure",
    result_decision="failed",
  )
  assert_true(execution_is_transient_infrastructure_debt(deferred))
  assert_false(execution_is_transient_infrastructure_debt(failed))
}

///|
test "shared standing goal counts include enabled disabled and due goals" {
  let counts = standing_goal_counts(
    [
      live_autonomy_watch_goal(
        id="watch-due",
        title="Due Watch",
        prompt="watch due",
        book_id="research-due",
        next_due_tick=10,
      ),
      @core.StandingGoal::new(
        id="watch-disabled",
        title="Disabled Watch",
        prompt="watch disabled",
        target_book_id=Some("research-disabled"),
        next_due_tick=10,
        enabled=false,
      ),
      live_autonomy_watch_goal(
        id="watch-later",
        title="Later Watch",
        prompt="watch later",
        book_id="research-later",
        next_due_tick=99,
      ),
    ],
    11,
  )
  assert_eq(counts.total, 3)
  assert_eq(counts.enabled, 2)
  assert_eq(counts.disabled, 1)
  assert_eq(counts.due, 1)
}

///|
test "shared health anomaly counter matches exact anomaly titles" {
  let state = visual_projection_test_state(
    worker_status=@core.WorkerStatus::Idle,
    execution_status=@core.TaskExecutionStatus::Failed,
  )
  state.register_execution(
    live_autonomy_execution_fixture(
      task_id="task-second-failure",
      book_id="research-opc",
      packet_id="packet-second-failure",
      packet_path="/tmp/packet-second-failure.json",
      status=@core.TaskExecutionStatus::Failed,
      summary="Second failed execution.",
    ),
  )
  let report = @health.inspect_town(state)
  assert_eq(count_health_anomalies_by_title(report, "execution-failed"), 2)
  assert_eq(count_health_anomalies_by_title(report, "worker-health"), 0)
  assert_eq(count_health_anomalies_by_title(report, "missing"), 0)
}
