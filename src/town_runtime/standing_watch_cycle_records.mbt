///|
async fn record_standing_watch_cycle_decision(
  state : @core.TownState,
  goal : @core.StandingGoal,
  tick : Int,
  target_book_id : String,
  ledger_dir : String,
  decision : @core.WatcherDecisionKind,
  detail : String,
  task_id? : String? = None,
  run_id? : String? = None,
  delta_score? : Int = 0,
  new_source_count? : Int = 0,
  no_change_streak? : Int = 0,
) -> @core.StandingGoal {
  let updated = goal.mark_watcher_decision(tick, decision, no_change_streak~)
  let record = @core.WatcherRunRecord::new(
    goal_id=goal.id,
    tick~,
    target_book_id~,
    decision~,
    delta_score~,
    new_source_count~,
    detail~,
    task_id~,
    run_id~,
    next_due_tick=updated.next_due_tick,
  )
  @storage.append_watcher_run_record(goal.id, record, dir=ledger_dir)
  state.record_event(
    @standing_watch_policy.standing_watch_event_for_record(record),
  )
  updated
}

///|
async fn record_completed_standing_watch_cycle(
  state : @core.TownState,
  goal : @core.StandingGoal,
  tick : Int,
  target_book_id : String,
  ledger_dir : String,
  execution : @core.TaskExecutionRecord,
  previous_no_change_streak : Int,
) -> @core.StandingGoal {
  let decision = @standing_watch_policy.standing_watch_decision_from_execution(
    execution,
  )
  let next_no_change_streak = if decision == NoChange {
    previous_no_change_streak + 1
  } else {
    0
  }
  record_standing_watch_cycle_decision(
    state,
    goal,
    tick,
    target_book_id,
    ledger_dir,
    decision,
    execution.summary,
    task_id=Some(execution.task_id),
    run_id=execution.run_id,
    delta_score=@standing_watch_policy.standing_watch_delta_score(execution),
    new_source_count=@standing_watch_policy.standing_watch_new_source_count(
      execution,
    ),
    no_change_streak=next_no_change_streak,
  )
}
