///|
fn civic_communication_reduction_status_live(
  status : @core.TaskExecutionStatus,
) -> Bool {
  @core.active_work_execution_status(status)
}

///|
fn failed_civic_communication_reduction(
  root : String,
  packet_id : String?,
  packet_path : String?,
  summary : String,
  proposal_id? : String? = None,
  run_id? : String? = None,
) -> CivicCommunicationReductionResult {
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
