///|
fn import_receipt_status(
  run_id : String?,
  status_text : String?,
) -> @core.TaskExecutionStatus {
  match status_text.map(fn(text) { text.to_lower() }) {
    Some("succeeded") | Some("completed") =>
      @core.TaskExecutionStatus::Completed
    Some("failed") => @core.TaskExecutionStatus::Failed
    _ =>
      if run_id is Some(_) {
        @core.TaskExecutionStatus::RunConfirmed
      } else {
        @core.TaskExecutionStatus::ProposalImported
      }
  }
}
