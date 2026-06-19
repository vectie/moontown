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
    packet_path=".moontown/packets/packet-\{task_id}.json",
    status=Failed,
    summary~,
    output_contract="keeper.plan.packet.v1",
  )
}

///|
test "snapshot refresh detects duplicate execution task ids" {
  let state = snapshot_test_state()
  state.register_execution(snapshot_test_execution("task", "first"))
  state.register_execution(snapshot_test_execution("task", "second"))
  assert_eq(snapshot_requires_refresh(@storage.snapshot_of(state)), true)
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
  state.register_execution(
    snapshot_test_execution("task", "Modeled bootstrap lifecycle for task"),
  )
  assert_eq(snapshot_requires_refresh(@storage.snapshot_of(state)), false)
}
