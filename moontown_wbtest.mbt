///|
test "dispatch routes coding work to same-book harness worker" {
  let state = demo_state()
  let decision = @dispatch.route_task(
    state,
    @dispatch.RouteRequest::new(
      task=@core.TownTask::new(
        id="task-1",
        book_id="coding",
        title="Implement router",
        prompt="Build assignment logic.",
        domain=@core.WorkDomain::Coding,
        required_role=Some(@core.WorkerRole::Harness),
        required_capabilities=["moonbit"],
      ),
    ),
  )
  assert_true(
    decision is Assigned(plan) &&
    plan.worker_id == "claw-harness" &&
    plan.isolation == @core.IsolationMode::Worktree,
  )
}

///|
test "finance work prefers isolated execution" {
  let book = @core.BookRef::new(
    id="finance",
    name="Finance",
    purpose="finance",
    workspace_root="/finance",
    memory_scope=@core.MemoryScope::TaskEphemeral,
  )
  let worker = @core.WorkerRef::new(
    id="ledger",
    name="Ledger",
    book_id="finance",
    role=@core.WorkerRole::Specialist,
  )
  let task = @core.TownTask::new(
    id="task-2",
    book_id="finance",
    title="Close finance loop",
    prompt="Produce ledger summary.",
    domain=@core.WorkDomain::Finance,
    required_role=Some(@core.WorkerRole::Specialist),
  )
  assert_eq(
    @dispatch.choose_isolation(task, worker, book),
    @core.IsolationMode::Sandboxed,
  )
}
