///|
fn snapshot_test_state() -> @core.TownState {
  @core.empty_state(@core.TownConfig::new(id="test-town", name="Test Town"))
}

///|
fn snapshot_test_execution(
  task_id : String,
  summary : String,
) -> @core.TaskExecutionRecord {
  @core.TaskExecutionRecord::new(
    task_id~,
    book_id="book",
    packet_id="packet-\{task_id}",
    packet_path=@moonclaw.packet_file_path(
      @moonclaw.default_packet_directory(),
      "packet-\{task_id}",
    ),
    status=Failed,
    summary~,
    output_contract="keeper.plan.packet.v1",
  )
}

///|
test "snapshot refresh detects duplicate execution task ids" {
  let state = snapshot_test_state()
  state.executions.push(snapshot_test_execution("task", "first"))
  state.executions.push(snapshot_test_execution("task", "second"))
  assert_eq(snapshot_requires_refresh(@storage.snapshot_of(state)), true)
}

///|
test "snapshot refresh detects broken execution task references" {
  let state = snapshot_test_state()
  state.executions.push(snapshot_test_execution("missing-task", "orphan"))
  assert_true(
    snapshot_has_broken_execution_references(@storage.snapshot_of(state)),
  )
}

///|
test "snapshot refresh detects stale execution failure markers" {
  assert_eq(
    execution_summary_requires_snapshot_refresh(
      "Runtime handoff failed: Unknown external proposal profile",
    ),
    true,
  )
  assert_eq(
    execution_summary_requires_snapshot_refresh(
      "Planner failed because metadata must be object",
    ),
    true,
  )
}

///|
test "snapshot refresh keeps current modeled bootstrap lifecycle snapshots" {
  let state = snapshot_test_state()
  state.register_book(
    @core.BookRef::new(
      id="book",
      name="Book",
      purpose="test",
      workspace_root="/tmp/moontown/books/book",
    ),
  )
  state.enqueue_task(
    @core.TownTask::new(
      id="task",
      book_id="book",
      title="Task",
      prompt="Test task",
      domain=Research,
    ),
  )
  state.register_execution(
    snapshot_test_execution("task", "Modeled bootstrap lifecycle for task"),
  )
  assert_eq(snapshot_requires_refresh(@storage.snapshot_of(state)), false)
}
