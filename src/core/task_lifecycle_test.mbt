///|
test "execution status maps to town task lifecycle status" {
  assert_eq(
    town_task_status_for_execution(TaskExecutionStatus::PacketReady),
    TownTaskStatus::Planned,
  )
  assert_eq(
    town_task_status_for_execution(TaskExecutionStatus::ProposalImported),
    TownTaskStatus::Assigned,
  )
  assert_eq(
    town_task_status_for_execution(TaskExecutionStatus::RunConfirmed),
    TownTaskStatus::Assigned,
  )
  assert_eq(
    town_task_status_for_execution(TaskExecutionStatus::Running),
    TownTaskStatus::Running,
  )
  assert_eq(
    town_task_status_for_execution(TaskExecutionStatus::AwaitingPersistence),
    TownTaskStatus::Running,
  )
  assert_eq(
    town_task_status_for_execution(TaskExecutionStatus::ReviewQueued),
    TownTaskStatus::Blocked,
  )
  assert_eq(
    town_task_status_for_execution(TaskExecutionStatus::Completed),
    TownTaskStatus::Done,
  )
  assert_eq(
    town_task_status_for_execution(TaskExecutionStatus::Stale),
    TownTaskStatus::Blocked,
  )
  assert_eq(
    town_task_status_for_execution(TaskExecutionStatus::Failed),
    TownTaskStatus::Failed,
  )
}

///|
test "copy task with status preserves task identity and routing fields" {
  let task = TownTask::new(
    id="task-1",
    book_id="book",
    title="Do work",
    prompt="Work",
    domain=WorkDomain::Coding,
    required_role=Some(WorkerRole::Harness),
    required_capabilities=["codex"],
    status=TownTaskStatus::Running,
  )
  let copied = copy_task_with_status(task, TownTaskStatus::Done)
  assert_eq(copied.id, task.id)
  assert_eq(copied.book_id, task.book_id)
  assert_eq(copied.domain, task.domain)
  assert_true(copied.required_role is Some(WorkerRole::Harness))
  assert_eq(copied.required_capabilities.length(), 1)
  assert_eq(copied.required_capabilities[0], "codex")
  assert_eq(copied.status, TownTaskStatus::Done)
}
