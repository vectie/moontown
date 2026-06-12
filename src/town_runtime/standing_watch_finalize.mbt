///|
async fn finalize_standing_watch_supervision_record(
  state : @core.TownState,
  entry : @moonbook.BookCatalogEntry,
  execution : @core.TaskExecutionRecord,
  standing_goals : Array[@core.StandingGoal],
  snapshot_path : String,
) -> @core.TaskExecutionRecord {
  let goal = match
    @standing_watch_policy.standing_goal_for_execution_task(
      standing_goals,
      execution.task_id,
    ) {
    Some(goal) => goal
    None => return execution
  }
  let observed = standing_watch_execution_with_book_decision(entry, execution)
  collapse_standing_watch_book_history(entry, observed)
  let decision = @standing_watch_policy.standing_watch_decision_from_execution(
    observed,
  )
  if decision == @core.WatcherDecisionKind::Deferred {
    return observed
  }
  let tick = @standing_watch_policy.standing_watch_tick_for_goal_task(
    goal,
    observed.task_id,
  ).unwrap_or(supervision_tick(state))
  let ledger_dir = @storage.watcher_ledger_dir_for_snapshot(snapshot_path)
  let previous_records = @storage.load_watcher_run_records(
    goal.id,
    dir=ledger_dir,
  )
  match terminal_watcher_record_for_execution(goal.id, ledger_dir, observed) {
    Some(record) =>
      if @standing_watch_policy.watcher_record_effective_decision(record) ==
        decision {
        return observed
      }
    None => ()
  }
  if standing_watch_record_already_exists(
      previous_records,
      observed.task_id,
      observed.run_id,
      decision,
    ) {
    return observed
  }
  let no_change_streak = @storage.consecutive_no_change_count(previous_records)
  let next_no_change_streak = if decision == @core.WatcherDecisionKind::NoChange {
    no_change_streak + 1
  } else {
    0
  }
  let updated_goal = goal.mark_watcher_decision(
    tick,
    decision,
    no_change_streak=next_no_change_streak,
  )
  let record = @core.WatcherRunRecord::new(
    goal_id=goal.id,
    tick~,
    target_book_id=observed.book_id,
    decision~,
    delta_score=@standing_watch_policy.standing_watch_delta_score(observed),
    new_source_count=@standing_watch_policy.standing_watch_new_source_count(
      observed,
    ),
    detail=observed.summary,
    task_id=Some(observed.task_id),
    run_id=observed.run_id,
    next_due_tick=updated_goal.next_due_tick,
  )
  @storage.append_watcher_run_record(goal.id, record, dir=ledger_dir)
  state.record_event(
    @standing_watch_policy.standing_watch_event_for_record(record),
  )
  save_standing_goal_update_for_watcher(snapshot_path, updated_goal)
  observed
}
