///|
fn civic_salon_reduction_status_live(
  status : @core.TaskExecutionStatus,
) -> Bool {
  status is @core.TaskExecutionStatus::ProposalImported ||
  status is @core.TaskExecutionStatus::RunConfirmed ||
  status is @core.TaskExecutionStatus::Running ||
  status is @core.TaskExecutionStatus::AwaitingPersistence
}

///|
fn failed_civic_salon_reduction(
  root : String,
  packet_id : String?,
  packet_path : String?,
  summary : String,
  proposal_id? : String? = None,
  run_id? : String? = None,
) -> CivicSalonReductionResult {
  {
    ideas: [],
    status: @core.TaskExecutionStatus::Failed,
    summary,
    packet_id,
    packet_path,
    proposal_id,
    run_id,
    workspace_root: root,
    reducer_kind: "moonclaw",
  }
}
