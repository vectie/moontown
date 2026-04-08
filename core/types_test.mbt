///|
test "core state registers books workers and tasks" {
  let state = empty_state(TownConfig::new(id="town", name="Moontown"))
  state.register_book(
    BookRef::new(
      id="coding",
      name="Coding",
      purpose="code",
      workspace_root="/tmp/coding",
    ),
  )
  state.register_worker(
    WorkerRef::new(
      id="worker-1",
      name="Harness",
      book_id="coding",
      role=@core.WorkerRole::Harness,
    ),
  )
  state.enqueue_task(
    TownTask::new(
      id="task-1",
      book_id="coding",
      title="Implement",
      prompt="Build the router.",
      domain=@core.WorkDomain::Coding,
    ),
  )
  assert_eq(state.books.length(), 1)
  assert_eq(state.workers.length(), 1)
  assert_eq(state.tasks.length(), 1)
}
