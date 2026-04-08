///|
test "demo town creates isolated moonbooks with routed assignments" {
  let town = @moontown.demo_town()
  assert_eq(town.book_count(), 2)
  assert_eq(town.active_assignment_count(), 4)
  let coding_tasks = town.tasks_for_book("coding")
  let finance_tasks = town.tasks_for_book("finance")
  assert_eq(coding_tasks.length(), 2)
  assert_eq(finance_tasks.length(), 2)
  assert_true(coding_tasks[0].assigned_worker_id is Some("claw-harness"))
  assert_true(coding_tasks[1].assigned_worker_id is Some("claw-review"))
  assert_true(finance_tasks[0].assigned_worker_id is Some("claw-ledger"))
  assert_true(finance_tasks[1].assigned_worker_id is Some("claw-memory"))
}

///|
test "dashboard renders town square and dispatch log" {
  let dashboard = @moontown.demo_town().render_dashboard()
  assert_true(dashboard.contains("MOONTOWN / moonrise"))
  assert_true(dashboard.contains("Moonbook / Coding"))
  assert_true(dashboard.contains("Moonbook / Finance"))
  assert_true(dashboard.contains("Dispatch Log"))
  assert_true(dashboard.contains("task-town-layer"))
}
