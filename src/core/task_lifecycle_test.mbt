///|
test "execution status maps to town task lifecycle status" {
  assert_eq(town_task_status_for_execution(PacketReady), Planned)
  assert_eq(town_task_status_for_execution(ProposalImported), Assigned)
  assert_eq(town_task_status_for_execution(RunConfirmed), Assigned)
  assert_eq(town_task_status_for_execution(Running), Running)
  assert_eq(town_task_status_for_execution(AwaitingPersistence), Running)
  assert_eq(town_task_status_for_execution(ReviewQueued), Blocked)
  assert_eq(town_task_status_for_execution(Completed), Done)
  assert_eq(town_task_status_for_execution(Stale), Blocked)
  assert_eq(town_task_status_for_execution(Failed), Failed)
}

///|
test "copy task with status preserves task identity and routing fields" {
  let task = TownTask::new(
    id="task-1",
    book_id="book",
    title="Do work",
    prompt="Work",
    domain=Coding,
    required_role=Some(Harness),
    required_capabilities=["codex"],
    status=Running,
  )
  let copied = copy_task_with_status(task, Done)
  assert_eq(copied.id, task.id)
  assert_eq(copied.book_id, task.book_id)
  assert_eq(copied.domain, task.domain)
  assert_true(copied.required_role is Some(Harness))
  assert_eq(copied.required_capabilities.length(), 1)
  assert_eq(copied.required_capabilities[0], "codex")
  assert_eq(copied.status, Done)
}

///|
test "schedulable task status keeps only open work in the daemon loop" {
  assert_true(schedulable_task_status(Pending))
  assert_true(schedulable_task_status(Planned))
  assert_true(schedulable_task_status(Assigned))
  assert_true(schedulable_task_status(Running))
  assert_true(!schedulable_task_status(Blocked))
  assert_true(!schedulable_task_status(Done))
  assert_true(!schedulable_task_status(Failed))
}

///|
test "execution lifecycle predicates classify terminal live and pollable states" {
  assert_true(terminal_execution_status(Completed))
  assert_true(terminal_execution_status(Failed))
  assert_true(terminal_execution_status(Stale))
  assert_true(!terminal_execution_status(Running))
  assert_true(live_execution_status(ProposalImported))
  assert_true(live_execution_status(RunConfirmed))
  assert_true(live_execution_status(Running))
  assert_true(!live_execution_status(ReviewQueued))
  assert_true(!live_execution_status(AwaitingPersistence))
  assert_true(active_work_execution_status(Running))
  assert_true(active_work_execution_status(AwaitingPersistence))
  assert_true(!active_work_execution_status(ReviewQueued))
  assert_true(pollable_execution_status(Running))
  assert_true(pollable_execution_status(Stale))
  assert_true(!pollable_execution_status(Completed))
}

///|
test "execution status rank preserves lifecycle precedence" {
  assert_true(execution_status_rank(Completed) > execution_status_rank(Running))
  assert_eq(
    execution_status_rank(AwaitingPersistence),
    execution_status_rank(Running),
  )
  assert_true(
    execution_status_rank(ProposalImported) <
    execution_status_rank(RunConfirmed),
  )
}

///|
test "execution stale windows distinguish imported runs from no-run snapshots" {
  let with_run = TaskExecutionRecord::new(
    task_id="task-run",
    book_id="book",
    packet_id="packet",
    packet_path="packet.json",
    status=Running,
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
    status=Running,
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
    status=Running,
    summary="running",
    output_contract="test",
    run_id=Some("run-1"),
  )
  let live_without_run = TaskExecutionRecord::new(
    task_id="task-live-pending",
    book_id="book",
    packet_id="packet",
    packet_path="packet.json",
    status=Running,
    summary="running",
    output_contract="test",
  )
  let retryable = TaskExecutionRecord::new(
    task_id="task-retry",
    book_id="book",
    packet_id="packet",
    packet_path="packet.json",
    status=Failed,
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
