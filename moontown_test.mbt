///|
test "demo state seeds books workers tasks and dispatch events" {
  let state = @moontown.demo_state()
  assert_eq(state.books.length(), 2)
  assert_eq(state.workers.length(), 4)
  assert_eq(state.tasks.length(), 4)
  assert_eq(state.executions.length(), 4)
  assert_eq(state.events.length(), 8)
  assert_true(state.events[0].detail.contains("goal-plan-next-coding"))
  assert_true(state.events[4].detail.contains("proposal=proposal-packet-"))
}

///|
test "dashboard renders town square and dispatch log" {
  let dashboard = @moontown.demo_dashboard()
  assert_true(dashboard.contains("Dashboard / Moontown / Moonrise"))
  assert_true(dashboard.contains("## Town Map"))
  assert_true(dashboard.contains("scene: 1280x720"))
  assert_true(dashboard.contains("City Hall"))
  assert_true(dashboard.contains("frame: 500,80 280x180"))
  assert_true(dashboard.contains("ui/assets/buildings/city-hall.svg"))
  assert_true(dashboard.contains("Anomaly Corner"))
  assert_true(dashboard.contains("## Books"))
  assert_true(dashboard.contains("## Workers"))
  assert_true(dashboard.contains("## Pipeline"))
  assert_true(dashboard.contains("## Executions"))
  assert_true(dashboard.contains("stage=Review"))
  assert_true(dashboard.contains("active stage: Review"))
  assert_true(dashboard.contains("## Mayor"))
  assert_true(dashboard.contains("Town Tick"))
  assert_true(dashboard.contains("Snapshot"))
  assert_true(dashboard.contains("proposal lifecycle records: 4"))
}

///|
async test "load or create demo state persists a snapshot" {
  let path = ".moontown/test-town-modeled.json"
  let state = @moontown.load_or_create_modeled_demo_state(path~)
  assert_eq(state.books.length(), 2)
  let snapshot = @storage.load_snapshot_file(path)
  assert_true(snapshot is Some(saved) && saved.event_count == 8)
}

///|
async test "load or create demo state accepts injected book provider" {
  let snapshot_path = ".moontown/test-provider-town.json"
  let provider = @core.StaticBookProvider::new([
    @core.BookRef::new(
      id="lab",
      name="Town Lab",
      purpose="Isolated social experiment lab book.",
      workspace_root="/workspace/lab",
      memory_scope=@core.MemoryScope::BookPrivate,
      tags=["experiments", "observation"],
    ),
  ])
  let state = @moontown.load_or_create_demo_state_with_provider(
    provider,
    path=snapshot_path,
  )
  assert_eq(state.books.length(), 1)
  assert_eq(state.books[0].id, "lab")
  assert_eq(state.books[0].workspace_root, "/workspace/lab")
}
