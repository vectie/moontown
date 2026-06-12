///|
pub(all) enum ExecutionViewStage {
  Packet
  Running
  Persisting
  Review
  Completed
  Recovery
} derive(Debug, Eq)

///|
pub fn execution_view_stage_for_status(
  status : @core.TaskExecutionStatus,
) -> ExecutionViewStage {
  match status {
    @core.TaskExecutionStatus::PacketReady
    | @core.TaskExecutionStatus::ProposalImported => Packet
    @core.TaskExecutionStatus::RunConfirmed
    | @core.TaskExecutionStatus::Running => Running
    @core.TaskExecutionStatus::AwaitingPersistence => Persisting
    @core.TaskExecutionStatus::ReviewQueued => Review
    @core.TaskExecutionStatus::Completed => Completed
    @core.TaskExecutionStatus::Failed | @core.TaskExecutionStatus::Stale =>
      Recovery
  }
}
