///|
fn active_execution_statuses() -> Array[@core.TaskExecutionStatus] {
  [
    @core.TaskExecutionStatus::ProposalImported,
    @core.TaskExecutionStatus::RunConfirmed,
    @core.TaskExecutionStatus::Running,
    @core.TaskExecutionStatus::AwaitingPersistence,
  ]
}

///|
fn review_execution_statuses() -> Array[@core.TaskExecutionStatus] {
  [@core.TaskExecutionStatus::ReviewQueued]
}

///|
fn execution_status_in(
  status : @core.TaskExecutionStatus,
  candidates : Array[@core.TaskExecutionStatus],
) -> Bool {
  for candidate in candidates {
    if status == candidate {
      return true
    }
  }
  false
}
