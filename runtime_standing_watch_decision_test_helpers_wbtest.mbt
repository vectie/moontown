///|
fn standing_watch_decision_execution(
  summary~ : String,
  status? : @core.TaskExecutionStatus = @core.TaskExecutionStatus::Completed,
  task_id? : String = "standing-watch-opc",
  book_id? : String = "research-opc",
  output_contract? : String = "test",
  requires_review? : Bool = false,
  notify_town? : Bool = false,
) -> @core.TaskExecutionRecord {
  @core.TaskExecutionRecord::new(
    task_id~,
    book_id~,
    packet_id="packet",
    packet_path="packet.json",
    status~,
    summary~,
    output_contract~,
    requires_review~,
    notify_town~,
  )
}
