///|
fn live_autonomy_worker_fixture(
  id~ : String,
  name~ : String,
  status~ : @core.WorkerStatus,
) -> @core.WorkerRef {
  @core.WorkerRef::new(
    id~,
    name~,
    book_id="book",
    role=@core.WorkerRole::Specialist,
    status~,
  )
}

///|
fn live_autonomy_standing_watch_execution(
  task_id : String,
  status : @core.TaskExecutionStatus,
  summary : String,
) -> @core.TaskExecutionRecord {
  live_autonomy_execution_fixture(
    task_id~,
    book_id="research-opc",
    packet_id="packet",
    packet_path="packet.json",
    status~,
    summary~,
    output_contract="standing-watch",
  )
}

///|
fn live_autonomy_execution_fixture(
  task_id~ : String,
  book_id? : String = "book",
  packet_id? : String = "packet",
  packet_path? : String = "/tmp/packet.json",
  status~ : @core.TaskExecutionStatus,
  summary~ : String,
  output_contract? : String = "result",
  result_decision? : String = "",
) -> @core.TaskExecutionRecord {
  @core.TaskExecutionRecord::new(
    task_id~,
    book_id~,
    packet_id~,
    packet_path~,
    status~,
    summary~,
    output_contract~,
    result_decision~,
  )
}
