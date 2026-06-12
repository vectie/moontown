///|
pub impl Show for IsolationMode with fn output(
  self : IsolationMode,
  logger : &Logger,
) -> Unit {
  logger.write_string(
    match self {
      SharedWorkspace => "SharedWorkspace"
      BookWorkspace => "BookWorkspace"
      Worktree => "Worktree"
      Sandboxed => "Sandboxed"
    },
  )
}

///|
pub impl Show for TaskExecutionStatus with fn output(
  self : TaskExecutionStatus,
  logger : &Logger,
) -> Unit {
  logger.write_string(
    match self {
      PacketReady => "PacketReady"
      ProposalImported => "ProposalImported"
      RunConfirmed => "RunConfirmed"
      Running => "Running"
      AwaitingPersistence => "AwaitingPersistence"
      ReviewQueued => "ReviewQueued"
      Completed => "Completed"
      Stale => "Stale"
      Failed => "Failed"
    },
  )
}

///|
pub impl Show for AssignmentPlan with fn output(
  self : AssignmentPlan,
  logger : &Logger,
) -> Unit {
  logger.write_string(
    "AssignmentPlan(task_id=\{self.task_id}, worker_id=\{self.worker_id}, book_id=\{self.book_id}, isolation=\{self.isolation})",
  )
}

///|
pub impl Show for TaskExecutionRecord with fn output(
  self : TaskExecutionRecord,
  logger : &Logger,
) -> Unit {
  logger.write_string(
    "TaskExecutionRecord(task_id=\{self.task_id}, book_id=\{self.book_id}, status=\{self.status}, attempt=\{self.attempt}, heartbeat_tick=\{self.heartbeat_tick})",
  )
}
