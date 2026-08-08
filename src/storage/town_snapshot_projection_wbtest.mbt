///|
fn storage_projection_task(
  id : String,
  status : @core.TownTaskStatus,
) -> @core.TownTask {
  @core.TownTask::new(
    id~,
    book_id="book",
    title=id,
    prompt="storage projection test",
    domain=Coding,
    status~,
  )
}

///|
fn storage_projection_execution(
  task_id : String,
  status : @core.TaskExecutionStatus,
) -> @core.TaskExecutionRecord {
  @core.TaskExecutionRecord::new(
    task_id~,
    book_id="book",
    packet_id="packet-\{task_id}",
    packet_path="packet-\{task_id}.json",
    status~,
    summary="storage projection test",
    output_contract="test",
  )
}

///|
test "snapshot projection keeps authoritative count and exposes omissions" {
  let state = @core.empty_state(@core.TownConfig::new(id="town", name="Town"))
  for index in 0..<5 {
    state.record_event(
      @core.TownEvent::new(
        id="event-\{index}",
        kind="test",
        detail="event \{index}",
      ),
    )
    state.enqueue_task(storage_projection_task("done-\{index}", Done))
    state.register_execution(
      storage_projection_execution("done-\{index}", Completed),
    )
  }
  state.enqueue_task(storage_projection_task("blocked", Blocked))
  state.register_execution(storage_projection_execution("failed", Failed))
  let durable = snapshot_of(state)
  let view = project_town_snapshot(
    durable,
    limits=@core.TownStateProjectionLimits::new(
      recent_events=2,
      terminal_tasks=2,
      terminal_executions=2,
    ),
  )
  assert_eq(view.event_count, 5)
  assert_eq(view.town.events.length(), 2)
  assert_eq(view.town.tasks.length(), 3)
  assert_eq(view.town.executions.length(), 2)
  assert_eq(view.retention.omitted_events, 3)
  assert_eq(view.retention.omitted_tasks, 3)
  assert_eq(view.retention.omitted_executions, 4)
  assert_true(view.town.tasks.any(task => task.id == "blocked"))
  assert_true(view.town.tasks.any(task => task.id == "done-4"))
  assert_true(
    view.town.executions.any(execution => execution.task_id == "failed"),
  )
  assert_eq(durable.town.events.length(), 5)
  assert_eq(durable.town.tasks.length(), 6)
  assert_eq(durable.town.executions.length(), 6)
}

///|
test "snapshot projection remains compatible with existing snapshot readers" {
  let state = @core.empty_state(@core.TownConfig::new(id="town", name="Town"))
  for index in 0..<3 {
    state.record_event(
      @core.TownEvent::new(
        id="event-\{index}",
        kind="test",
        detail="event \{index}",
      ),
    )
  }
  let view = project_town_snapshot(
    snapshot_of(state),
    limits=@core.TownStateProjectionLimits::new(recent_events=1),
  )
  let encoded = view.to_json()
  let decoded : TownSnapshot = @json.from_json(encoded) catch {
    error =>
      fail(
        "existing TownSnapshot decoder rejected additive retention: \{error}",
      )
  }
  assert_eq(decoded.event_count, 3)
  assert_eq(decoded.town.events.length(), 1)
  assert_eq(decoded.town.events[0].id, "event-2")
}
