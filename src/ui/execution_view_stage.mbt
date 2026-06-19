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
    PacketReady | ProposalImported => Packet
    RunConfirmed | Running => Running
    AwaitingPersistence => Persisting
    ReviewQueued => Review
    Completed => Completed
    Failed | Stale => Recovery
  }
}
