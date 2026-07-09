///|
fn count_execution_status(
  executions : Array[@core.TaskExecutionRecord],
  status : @core.TaskExecutionStatus,
) -> Int {
  let mut count = 0
  for execution in executions {
    if execution.status == status {
      count += 1
    }
  }
  count
}

///|
fn execution_status_needs_attention(status : @core.TaskExecutionStatus) -> Bool {
  status == Failed ||
  status == Stale ||
  status == ReviewQueued
}

///|
fn execution_status_is_active_run(status : @core.TaskExecutionStatus) -> Bool {
  status == Running ||
  status == RunConfirmed
}

///|
fn execution_status_has_run_id(status : @core.TaskExecutionStatus) -> Bool {
  !(status == PacketReady ||
  status == ProposalImported)
}

///|
fn execution_status_requires_review(status : @core.TaskExecutionStatus) -> Bool {
  status == AwaitingPersistence ||
  status == ReviewQueued
}

///|
priv struct ExecutionCountSummary {
  packet_ready : Int
  proposal_imported : Int
  run_confirmed : Int
  running : Int
  awaiting_persistence : Int
  review_queued : Int
  completed : Int
  stale : Int
  failed : Int
}

///|
fn execution_count_summary(
  executions : Array[@core.TaskExecutionRecord],
) -> ExecutionCountSummary {
  {
    packet_ready: count_execution_status(
      executions,
      PacketReady,
    ),
    proposal_imported: count_execution_status(
      executions,
      ProposalImported,
    ),
    run_confirmed: count_execution_status(
      executions,
      RunConfirmed,
    ),
    running: count_execution_status(
      executions,
      Running,
    ),
    awaiting_persistence: count_execution_status(
      executions,
      AwaitingPersistence,
    ),
    review_queued: count_execution_status(
      executions,
      ReviewQueued,
    ),
    completed: count_execution_status(
      executions,
      Completed,
    ),
    stale: count_execution_status(executions, Stale),
    failed: count_execution_status(
      executions,
      Failed,
    ),
  }
}

///|
fn ExecutionCountSummary::active_run_flow(self : ExecutionCountSummary) -> Int {
  self.running + self.run_confirmed
}

///|
fn ExecutionCountSummary::active_or_unresolved(
  self : ExecutionCountSummary,
) -> Int {
  self.run_confirmed +
  self.running +
  self.awaiting_persistence +
  self.review_queued +
  self.stale
}

///|
fn ExecutionCountSummary::issue_count(self : ExecutionCountSummary) -> Int {
  self.stale + self.failed
}
