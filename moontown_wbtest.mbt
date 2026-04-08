///|
test "worker score prefers book local matching specialist" {
  let task = Task::new(
    id="task-1",
    title="Implement router",
    summary="Build assignment logic.",
    book_id="coding",
    domain=Coding,
    required_role=Some(Harness),
    required_skills=["moonbit", "git"],
  )
  let local_worker = Worker::new(
    id="local",
    name="Local",
    book_id="coding",
    role=Harness,
    skills=["moonbit", "git"],
    preferred_isolation=Worktree,
  )
  let foreign_worker = Worker::new(
    id="foreign",
    name="Foreign",
    book_id="finance",
    role=Harness,
    skills=["moonbit", "git"],
    preferred_isolation=Worktree,
  )
  assert_true(
    worker_score(local_worker, task) > worker_score(foreign_worker, task),
  )
}

///|
test "finance work prefers isolated execution" {
  let task = Task::new(
    id="task-2",
    title="Close finance loop",
    summary="Produce ledger summary.",
    book_id="finance",
    domain=Finance,
    required_role=Some(Specialist),
    required_skills=["ledgers"],
  )
  let worker = Worker::new(
    id="ledger",
    name="Ledger",
    book_id="finance",
    role=Specialist,
    skills=["ledgers"],
    preferred_isolation=BookWorkspace,
  )
  assert_eq(preferred_isolation(task, worker), Worktree)
}
