///|
test "dispatch routes coding work to same-book extension API worker" {
  let state = modeled_state()
  let decision = @dispatch.route_task(
    state,
    @dispatch.RouteRequest::new(
      task=@core.TownTask::new(
        id="task-1",
        book_id="coding",
        title="Implement router",
        prompt="Build assignment logic.",
        domain=Coding,
        required_role=Some(Harness),
        required_capabilities=["moonbit"],
      ),
    ),
  )
  assert_true(
    decision is Assigned(plan) &&
    plan.worker_id == "claw-harness" &&
    plan.isolation == Worktree,
  )
}

///|
test "dispatch routes coding standing watch to same-book watcher worker" {
  let state = modeled_state()
  let decision = @dispatch.route_task(
    state,
    @dispatch.RouteRequest::new(
      task=@core.TownTask::new(
        id="standing-watch-coding-tick-1",
        book_id="coding",
        title="Repair coding book quality",
        prompt="Run a book-quality standing watch against the coding book.",
        domain=Coding,
        required_role=Some(Watcher),
        required_capabilities=["standing-watch"],
      ),
    ),
  )
  assert_true(
    decision is Assigned(plan) &&
    plan.worker_id == "claw-coding-watcher" &&
    plan.isolation == Worktree,
  )
}

///|
test "finance work prefers isolated execution" {
  let book = @core.BookRef::new(
    id="finance",
    name="Finance",
    purpose="finance",
    workspace_root="/finance",
    memory_scope=TaskEphemeral,
  )
  let worker = @core.WorkerRef::new(
    id="ledger",
    name="Ledger",
    book_id="finance",
    role=Specialist,
  )
  let task = @core.TownTask::new(
    id="task-2",
    book_id="finance",
    title="Close finance loop",
    prompt="Produce ledger summary.",
    domain=Finance,
    required_role=Some(Specialist),
  )
  assert_eq(@dispatch.choose_isolation(task, worker, book), Sandboxed)
}
