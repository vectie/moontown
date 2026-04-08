///|
test "demo state seeds books workers tasks and dispatch events" {
  let state = @moontown.demo_state()
  assert_eq(state.books.length(), 2)
  assert_eq(state.workers.length(), 4)
  assert_eq(state.tasks.length(), 4)
  assert_eq(state.events.length(), 4)
  assert_true(state.events[0].detail.contains("task-town-layer"))
  assert_true(state.events[1].detail.contains("task-review-contract"))
}

///|
test "dashboard renders town square and dispatch log" {
  let dashboard = @moontown.demo_dashboard()
  assert_true(dashboard.contains("Dashboard / Moontown / Moonrise"))
  assert_true(dashboard.contains("## Books"))
  assert_true(dashboard.contains("## Workers"))
  assert_true(dashboard.contains("Town Tick"))
  assert_true(dashboard.contains("Snapshot"))
  assert_true(dashboard.contains("task-town-layer"))
}

///|
async test "load or create demo state persists a snapshot" {
  let path = ".moontown/test-town.json"
  let state = @moontown.load_or_create_demo_state(path~)
  assert_eq(state.books.length(), 2)
  let snapshot = @storage.load_snapshot_file(path)
  assert_true(snapshot is Some(saved) && saved.event_count == 4)
}
