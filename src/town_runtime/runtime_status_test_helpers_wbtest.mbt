///|
fn runtime_status_test_state() -> @core.TownState {
  @core.empty_state(@core.TownConfig::new(id="test-town", name="Test Town"))
}

///|
async fn cleaned_runtime_status_test_root(root : String) -> String {
  @support.ignore_checked_command("rm", ["-rf", root])
  root
}

///|
fn runtime_status_test_execution(
  task_id : String,
  book_id : String,
  packet_id : String,
  status : @core.TaskExecutionStatus,
  summary : String,
  packet_path? : String = "",
  run_id? : String? = None,
  output_contract? : String = "test",
) -> @core.TaskExecutionRecord {
  @core.TaskExecutionRecord::new(
    task_id~,
    book_id~,
    packet_id~,
    packet_path=if packet_path == "" {
      "\{packet_id}.json"
    } else {
      packet_path
    },
    run_id~,
    status~,
    summary~,
    output_contract~,
  )
}

///|
fn runtime_status_standing_goal(
  id~ : String,
  title~ : String,
  prompt~ : String,
  book_id~ : String,
  next_due_tick? : Int = 0,
  last_run_tick? : Int? = None,
  cadence_ticks? : Int = 60,
) -> @core.StandingGoal {
  @core.StandingGoal::new(
    id~,
    title~,
    prompt~,
    target_book_id=Some(book_id),
    cadence_ticks~,
    next_due_tick~,
    last_run_tick~,
  )
}
