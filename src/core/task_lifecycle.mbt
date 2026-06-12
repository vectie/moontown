///|
pub fn town_task_status_for_execution(
  status : TaskExecutionStatus,
) -> TownTaskStatus {
  match status {
    TaskExecutionStatus::PacketReady => TownTaskStatus::Planned
    TaskExecutionStatus::ProposalImported => TownTaskStatus::Assigned
    TaskExecutionStatus::RunConfirmed => TownTaskStatus::Assigned
    TaskExecutionStatus::Running => TownTaskStatus::Running
    TaskExecutionStatus::AwaitingPersistence => TownTaskStatus::Running
    TaskExecutionStatus::ReviewQueued => TownTaskStatus::Blocked
    TaskExecutionStatus::Completed => TownTaskStatus::Done
    TaskExecutionStatus::Stale => TownTaskStatus::Blocked
    TaskExecutionStatus::Failed => TownTaskStatus::Failed
  }
}

///|
pub fn copy_task_with_status(
  task : TownTask,
  status : TownTaskStatus,
) -> TownTask {
  TownTask::new(
    id=task.id,
    book_id=task.book_id,
    title=task.title,
    prompt=task.prompt,
    domain=task.domain,
    required_role=task.required_role,
    required_capabilities=task.required_capabilities,
    status~,
  )
}
