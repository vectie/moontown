///|
test "execution status maps to town task lifecycle status" {
  assert_eq(
    town_task_status_for_execution(TaskExecutionStatus::PacketReady),
    TownTaskStatus::Planned,
  )
  assert_eq(
    town_task_status_for_execution(TaskExecutionStatus::ProposalImported),
    TownTaskStatus::Assigned,
  )
  assert_eq(
    town_task_status_for_execution(TaskExecutionStatus::RunConfirmed),
    TownTaskStatus::Assigned,
  )
  assert_eq(
    town_task_status_for_execution(TaskExecutionStatus::Running),
    TownTaskStatus::Running,
  )
  assert_eq(
    town_task_status_for_execution(TaskExecutionStatus::AwaitingPersistence),
    TownTaskStatus::Running,
  )
  assert_eq(
    town_task_status_for_execution(TaskExecutionStatus::ReviewQueued),
    TownTaskStatus::Blocked,
  )
  assert_eq(
    town_task_status_for_execution(TaskExecutionStatus::Completed),
    TownTaskStatus::Done,
  )
  assert_eq(
    town_task_status_for_execution(TaskExecutionStatus::Stale),
    TownTaskStatus::Blocked,
  )
  assert_eq(
    town_task_status_for_execution(TaskExecutionStatus::Failed),
    TownTaskStatus::Failed,
  )
}

///|
test "copy task with status preserves task identity and routing fields" {
  let task = TownTask::new(
    id="task-1",
    book_id="book",
    title="Do work",
    prompt="Work",
    domain=WorkDomain::Coding,
    required_role=Some(WorkerRole::Harness),
    required_capabilities=["codex"],
    status=TownTaskStatus::Running,
  )
  let copied = copy_task_with_status(task, TownTaskStatus::Done)
  assert_eq(copied.id, task.id)
  assert_eq(copied.book_id, task.book_id)
  assert_eq(copied.domain, task.domain)
  assert_true(copied.required_role is Some(WorkerRole::Harness))
  assert_eq(copied.required_capabilities.length(), 1)
  assert_eq(copied.required_capabilities[0], "codex")
  assert_eq(copied.status, TownTaskStatus::Done)
}

///|
test "schedulable task status keeps only open work in the daemon loop" {
  assert_true(schedulable_task_status(TownTaskStatus::Pending))
  assert_true(schedulable_task_status(TownTaskStatus::Planned))
  assert_true(schedulable_task_status(TownTaskStatus::Assigned))
  assert_true(schedulable_task_status(TownTaskStatus::Running))
  assert_true(!schedulable_task_status(TownTaskStatus::Blocked))
  assert_true(!schedulable_task_status(TownTaskStatus::Done))
  assert_true(!schedulable_task_status(TownTaskStatus::Failed))
}

///|
test "execution lifecycle predicates classify terminal live and pollable states" {
  assert_true(terminal_execution_status(TaskExecutionStatus::Completed))
  assert_true(terminal_execution_status(TaskExecutionStatus::Failed))
  assert_true(terminal_execution_status(TaskExecutionStatus::Stale))
  assert_true(!terminal_execution_status(TaskExecutionStatus::Running))
  assert_true(live_execution_status(TaskExecutionStatus::ProposalImported))
  assert_true(live_execution_status(TaskExecutionStatus::RunConfirmed))
  assert_true(live_execution_status(TaskExecutionStatus::Running))
  assert_true(!live_execution_status(TaskExecutionStatus::ReviewQueued))
  assert_true(!live_execution_status(TaskExecutionStatus::AwaitingPersistence))
  assert_true(active_work_execution_status(TaskExecutionStatus::Running))
  assert_true(
    active_work_execution_status(TaskExecutionStatus::AwaitingPersistence),
  )
  assert_true(!active_work_execution_status(TaskExecutionStatus::ReviewQueued))
  assert_true(pollable_execution_status(TaskExecutionStatus::Running))
  assert_true(pollable_execution_status(TaskExecutionStatus::Stale))
  assert_true(!pollable_execution_status(TaskExecutionStatus::Completed))
}

///|
test "execution status rank preserves lifecycle precedence" {
  assert_true(
    execution_status_rank(TaskExecutionStatus::Completed) >
    execution_status_rank(TaskExecutionStatus::Running),
  )
  assert_eq(
    execution_status_rank(TaskExecutionStatus::AwaitingPersistence),
    execution_status_rank(TaskExecutionStatus::Running),
  )
  assert_true(
    execution_status_rank(TaskExecutionStatus::ProposalImported) <
    execution_status_rank(TaskExecutionStatus::RunConfirmed),
  )
}

///|
test "execution stale windows distinguish imported runs from no-run snapshots" {
  let with_run = TaskExecutionRecord::new(
    task_id="task-run",
    book_id="book",
    packet_id="packet",
    packet_path="packet.json",
    status=TaskExecutionStatus::Running,
    summary="running",
    output_contract="test",
    run_id=Some("run-1"),
    heartbeat_tick=10,
    stale_after_tick=130,
  )
  let without_run = TaskExecutionRecord::new(
    task_id="task-pending",
    book_id="book",
    packet_id="packet",
    packet_path="packet.json",
    status=TaskExecutionStatus::Running,
    summary="running",
    output_contract="test",
    heartbeat_tick=10,
    stale_after_tick=130,
  )
  assert_eq(polled_execution_stale_window_ticks(with_run), 120)
  assert_eq(polled_execution_stale_window_ticks(without_run), 15)
  assert_true(!no_run_id_live_execution_stale(without_run, 24))
  assert_true(no_run_id_live_execution_stale(without_run, 25))
  assert_true(!no_run_id_live_execution_stale(with_run, 129))
  assert_true(no_run_id_live_execution_stale(with_run, 130))
}

///|
test "town execution aggregation counts only live external runs" {
  let state = empty_state(TownConfig::new(id="town", name="Town"))
  let live_with_run = TaskExecutionRecord::new(
    task_id="task-live-run",
    book_id="book",
    packet_id="packet",
    packet_path="packet.json",
    status=TaskExecutionStatus::Running,
    summary="running",
    output_contract="test",
    run_id=Some("run-1"),
  )
  let live_without_run = TaskExecutionRecord::new(
    task_id="task-live-pending",
    book_id="book",
    packet_id="packet",
    packet_path="packet.json",
    status=TaskExecutionStatus::Running,
    summary="running",
    output_contract="test",
  )
  let retryable = TaskExecutionRecord::new(
    task_id="task-retry",
    book_id="book",
    packet_id="packet",
    packet_path="packet.json",
    status=TaskExecutionStatus::Failed,
    summary="failed",
    output_contract="test",
    attempt=1,
    next_retry_tick=Some(30),
  )
  state.replace_execution(live_with_run)
  state.replace_execution(live_without_run)
  state.replace_execution(retryable)
  assert_eq(live_external_execution_count(state), 1)
  assert_true(has_live_executions(state))
  assert_true(has_active_work_executions(state))
  assert_true(has_retry_pending_executions(state, 20))
}

///|
test "task id tick parser extracts the latest daemon tick marker" {
  assert_eq(tick_from_task_id("standing-watch-opc-news-tick-15949"), 15949)
  assert_eq(
    tick_from_task_id("standing-watch-opc-news-tick-15949-extra"),
    15949,
  )
  assert_eq(tick_from_task_id("task-tick-3-retry-tick-42"), 42)
  assert_eq(tick_from_task_id("standing-watch-without-daemon-tick"), 0)
}
