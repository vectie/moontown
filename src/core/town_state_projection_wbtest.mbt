///|
fn projection_test_task(id : String, status : TownTaskStatus) -> TownTask {
  TownTask::new(
    id~,
    book_id="book",
    title=id,
    prompt="projection test",
    domain=Coding,
    status~,
  )
}

///|
fn projection_test_execution(
  task_id : String,
  status : TaskExecutionStatus,
) -> TaskExecutionRecord {
  TaskExecutionRecord::new(
    task_id~,
    book_id="book",
    packet_id="packet-\{task_id}",
    packet_path="packet-\{task_id}.json",
    status~,
    summary="projection test",
    output_contract="test",
  )
}

///|
fn projection_test_event(index : Int) -> TownEvent {
  TownEvent::new(id="event-\{index}", kind="test", detail="event \{index}")
}

///|
test "bounded state projection keeps newest events with exact evidence" {
  let state = empty_state(TownConfig::new(id="town", name="Town"))
  for index in 0..<7 {
    state.record_event(projection_test_event(index))
  }
  let view = state.bounded_read_projection(
    TownStateProjectionLimits::new(
      recent_events=3,
      terminal_tasks=0,
      terminal_executions=0,
    ),
  )
  assert_eq(view.state.events.length(), 3)
  assert_eq(view.state.events[0].id, "event-4")
  assert_eq(view.state.events[2].id, "event-6")
  assert_eq(view.evidence.total_events, 7)
  assert_eq(view.evidence.retained_events, 3)
  assert_eq(view.evidence.omitted_events, 4)
  assert_eq(state.events.length(), 7)
  assert_eq(state.events[0].id, "event-0")
}

///|
test "bounded state projection caps terminal history but keeps live rows" {
  let state = empty_state(TownConfig::new(id="town", name="Town"))
  state.enqueue_task(projection_test_task("done-old", Done))
  state.enqueue_task(projection_test_task("failed", Failed))
  state.enqueue_task(projection_test_task("running", Running))
  state.enqueue_task(projection_test_task("blocked", Blocked))
  state.enqueue_task(projection_test_task("done-new", Done))
  state.register_execution(projection_test_execution("complete-old", Completed))
  state.register_execution(projection_test_execution("failed", Failed))
  state.register_execution(projection_test_execution("stale", Stale))
  state.register_execution(projection_test_execution("review", ReviewQueued))
  state.register_execution(projection_test_execution("complete-new", Completed))
  let view = state.bounded_read_projection(
    TownStateProjectionLimits::new(
      recent_events=0,
      terminal_tasks=1,
      terminal_executions=2,
    ),
  )
  assert_eq(view.state.tasks.map(task => task.id), [
    "running", "blocked", "done-new",
  ])
  assert_eq(view.state.executions.map(execution => execution.task_id), [
    "stale", "review", "complete-new",
  ])
  assert_eq(view.evidence.total_tasks, 5)
  assert_eq(view.evidence.retained_tasks, 3)
  assert_eq(view.evidence.omitted_tasks, 2)
  assert_eq(view.evidence.total_executions, 5)
  assert_eq(view.evidence.retained_executions, 3)
  assert_eq(view.evidence.omitted_executions, 2)
  assert_eq(state.tasks.length(), 5)
  assert_eq(state.executions.length(), 5)
}

///|
test "bounded state projection retains current registries and normalizes limits" {
  let state = empty_state(TownConfig::new(id="town", name="Town"))
  state.register_book(
    BookRef::new(
      id="book",
      name="Book",
      purpose="test",
      workspace_root="/tmp/book",
    ),
  )
  state.register_worker(
    WorkerRef::new(id="worker", name="Worker", book_id="book", role=Harness),
  )
  state.enqueue_task(projection_test_task("done", Done))
  state.register_execution(projection_test_execution("done", Completed))
  state.record_event(projection_test_event(0))
  let limits = TownStateProjectionLimits::new(
    recent_events=-1,
    live_tasks=-1,
    terminal_tasks=-2,
    live_executions=-2,
    terminal_executions=-3,
  )
  let view = state.bounded_read_projection(limits)
  assert_eq(limits.recent_events, 0)
  assert_eq(limits.live_tasks, 0)
  assert_eq(limits.terminal_tasks, 0)
  assert_eq(limits.live_executions, 0)
  assert_eq(limits.terminal_executions, 0)
  assert_eq(view.state.books.length(), 1)
  assert_eq(view.state.workers.length(), 1)
  assert_eq(view.state.tasks.length(), 0)
  assert_eq(view.state.executions.length(), 0)
  assert_eq(view.state.events.length(), 0)
}

///|
test "bounded state projection caps a large failed terminal history" {
  let state = empty_state(TownConfig::new(id="town", name="Town"))
  for index in 0..<10000 {
    let id = "failed-\{index}"
    state.enqueue_task(projection_test_task(id, Failed))
    state.register_execution(projection_test_execution(id, Failed))
  }
  let view = state.bounded_read_projection(
    TownStateProjectionLimits::new(
      recent_events=0,
      terminal_tasks=1,
      terminal_executions=1,
    ),
  )
  assert_eq(view.state.tasks.map(task => task.id), ["failed-9999"])
  assert_eq(view.state.executions.map(execution => execution.task_id), [
    "failed-9999",
  ])
  assert_eq(view.evidence.omitted_tasks, 9999)
  assert_eq(view.evidence.omitted_executions, 9999)
  assert_eq(state.tasks.length(), 10000)
  assert_eq(state.executions.length(), 10000)
}

///|
test "bounded state projection has an absolute live family bound" {
  let state = empty_state(TownConfig::new(id="town", name="Town"))
  for index in 0..<10000 {
    let id = "live-\{index}"
    state.enqueue_task(projection_test_task(id, Blocked))
    state.register_execution(projection_test_execution(id, ReviewQueued))
  }
  let view = state.bounded_read_projection(
    TownStateProjectionLimits::new(
      recent_events=0,
      live_tasks=1,
      terminal_tasks=0,
      live_executions=1,
      terminal_executions=0,
    ),
  )
  assert_eq(view.state.tasks.map(task => task.id), ["live-9999"])
  assert_eq(view.state.executions.map(execution => execution.task_id), [
    "live-9999",
  ])
  assert_eq(view.evidence.omitted_tasks, 9999)
  assert_eq(view.evidence.omitted_live_tasks, 9999)
  assert_eq(view.evidence.omitted_terminal_tasks, 0)
  assert_eq(view.evidence.omitted_executions, 9999)
  assert_eq(view.evidence.omitted_live_executions, 9999)
  assert_eq(view.evidence.omitted_terminal_executions, 0)
  assert_eq(state.tasks.length(), 10000)
  assert_eq(state.executions.length(), 10000)
}
