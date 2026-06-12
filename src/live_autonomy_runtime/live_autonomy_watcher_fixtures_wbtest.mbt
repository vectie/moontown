///|
fn live_autonomy_watch_goal(
  id~ : String,
  title~ : String,
  prompt~ : String,
  book_id~ : String,
  next_due_tick? : Int = 0,
) -> @core.StandingGoal {
  @core.StandingGoal::new(
    id~,
    title~,
    prompt~,
    target_book_id=Some(book_id),
    cadence_ticks=60,
    next_due_tick~,
  )
}

///|
fn live_autonomy_watcher_record(
  goal_id~ : String,
  tick~ : Int,
  book_id~ : String,
  decision~ : @core.WatcherDecisionKind,
  delta_score? : Int = 0,
  new_source_count? : Int = 0,
  detail? : String = "",
  task_id? : String? = None,
  run_id? : String? = None,
  next_due_tick~ : Int,
) -> @core.WatcherRunRecord {
  @core.WatcherRunRecord::new(
    goal_id~,
    tick~,
    target_book_id=book_id,
    decision~,
    delta_score~,
    new_source_count~,
    detail~,
    task_id~,
    run_id~,
    next_due_tick~,
  )
}

///|
async fn write_live_autonomy_watcher_record_line(
  root : String,
  goal_id : String,
  record : @core.WatcherRunRecord,
) -> Unit {
  @support.write_text_file(
    "\{root}/watchers/\{goal_id}.jsonl",
    record.to_json().stringify() + "\n",
  )
}
