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
fn execution_status_is_dispatch_phase(
  status : @core.TaskExecutionStatus,
) -> Bool {
  status == @core.TaskExecutionStatus::PacketReady ||
  status == @core.TaskExecutionStatus::ProposalImported ||
  status == @core.TaskExecutionStatus::RunConfirmed
}

///|
fn execution_status_needs_attention(
  status : @core.TaskExecutionStatus,
) -> Bool {
  status == @core.TaskExecutionStatus::Failed ||
  status == @core.TaskExecutionStatus::Stale ||
  status == @core.TaskExecutionStatus::ReviewQueued
}

///|
fn execution_status_is_persistence_or_done(
  status : @core.TaskExecutionStatus,
) -> Bool {
  status == @core.TaskExecutionStatus::AwaitingPersistence ||
  status == @core.TaskExecutionStatus::Completed
}

///|
fn execution_status_is_active_run(status : @core.TaskExecutionStatus) -> Bool {
  status == @core.TaskExecutionStatus::Running ||
  status == @core.TaskExecutionStatus::RunConfirmed
}

///|
fn execution_status_has_run_id(status : @core.TaskExecutionStatus) -> Bool {
  !(
    status == @core.TaskExecutionStatus::PacketReady ||
    status == @core.TaskExecutionStatus::ProposalImported
  )
}

///|
fn execution_status_requires_review(status : @core.TaskExecutionStatus) -> Bool {
  status == @core.TaskExecutionStatus::AwaitingPersistence ||
  status == @core.TaskExecutionStatus::ReviewQueued
}

///|
priv struct ExecutionCountSummary {
  total : Int
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
  ExecutionCountSummary::{
    total: executions.length(),
    packet_ready: count_execution_status(
      executions,
      @core.TaskExecutionStatus::PacketReady,
    ),
    proposal_imported: count_execution_status(
      executions,
      @core.TaskExecutionStatus::ProposalImported,
    ),
    run_confirmed: count_execution_status(
      executions,
      @core.TaskExecutionStatus::RunConfirmed,
    ),
    running: count_execution_status(
      executions,
      @core.TaskExecutionStatus::Running,
    ),
    awaiting_persistence: count_execution_status(
      executions,
      @core.TaskExecutionStatus::AwaitingPersistence,
    ),
    review_queued: count_execution_status(
      executions,
      @core.TaskExecutionStatus::ReviewQueued,
    ),
    completed: count_execution_status(
      executions,
      @core.TaskExecutionStatus::Completed,
    ),
    stale: count_execution_status(executions, @core.TaskExecutionStatus::Stale),
    failed: count_execution_status(executions, @core.TaskExecutionStatus::Failed),
  }
}

///|
fn ExecutionCountSummary::active_run_flow(self : ExecutionCountSummary) -> Int {
  self.running + self.run_confirmed
}

///|
fn ExecutionCountSummary::active_or_unresolved(self : ExecutionCountSummary) -> Int {
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
