///|
fn health_report_state_with_book(
  id~ : String,
  name~ : String,
  purpose~ : String,
  workspace_root~ : String,
) -> @core.TownState {
  let state = @core.empty_state(
    @core.TownConfig::new(id="test-town", name="Test Town"),
  )
  state.register_book(@core.BookRef::new(id~, name~, purpose~, workspace_root~))
  state
}

///|
fn health_report_execution(
  task_id~ : String,
  book_id~ : String,
  status~ : @core.TaskExecutionStatus,
  summary~ : String,
  output_contract? : String = "standing-watch",
  packet_id? : String = "",
  packet_path? : String = "",
  context_pages? : Array[String] = [],
) -> @core.TaskExecutionRecord {
  let resolved_packet_id = if packet_id == "" {
    "packet-\{task_id}"
  } else {
    packet_id
  }
  let resolved_packet_path = if packet_path == "" {
    "\{resolved_packet_id}.json"
  } else {
    packet_path
  }
  @core.TaskExecutionRecord::new(
    task_id~,
    book_id~,
    packet_id=resolved_packet_id,
    packet_path=resolved_packet_path,
    status~,
    summary~,
    output_contract~,
    context_pages~,
  )
}

///|
fn register_health_report_executions(
  state : @core.TownState,
  executions : Array[@core.TaskExecutionRecord],
) -> Unit {
  for execution in executions {
    state.register_execution(execution)
  }
}
