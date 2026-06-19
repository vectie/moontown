///|
priv struct StandingWatchRecoveryContext {
  goal : @core.StandingGoal
  entry : @moonbook.BookCatalogEntry
}

///|
fn standing_watch_failed_or_stale(
  execution : @core.TaskExecutionRecord,
) -> Bool {
  execution.status == Failed || execution.status == Stale
}

///|
fn standing_watch_recovery_context(
  catalog : Array[@moonbook.BookCatalogEntry],
  standing_goals : Array[@core.StandingGoal],
  execution : @core.TaskExecutionRecord,
) -> StandingWatchRecoveryContext? {
  let goal = match
    @standing_watch_policy.standing_goal_for_execution_task(
      standing_goals,
      execution.task_id,
    ) {
    Some(goal) => goal
    None => return None
  }
  let entry = match @moonbook.entry_for_book_id(catalog, execution.book_id) {
    Some(entry) => entry
    None => return None
  }
  Some({ goal, entry })
}

///|
async fn recover_observed_standing_watch_output(
  state : @core.TownState,
  context : StandingWatchRecoveryContext,
  observed : @core.TaskExecutionRecord,
  decision : @core.WatcherDecisionKind,
  standing_goals : Array[@core.StandingGoal],
  snapshot_path : String,
) -> Unit {
  let completed = copy_execution_with(
    observed,
    status=Completed,
    summary=@standing_watch_policy.standing_watch_recovery_summary(
      context.goal,
      observed,
      decision,
    ),
    heartbeat_tick=supervision_tick(state),
    next_retry_tick=None,
  )
  replace_standing_watch_recovery_execution(state, completed)
  state.record_event(
    @standing_watch_policy.standing_watch_execution_event(
      "event-watch-auto-recovery",
      state.events.length(),
      completed,
      "Mayor recovered failed standing watch `\{completed.task_id}` as \{decision.to_string()} because MoonBook persisted a terminal keeper marker.",
    ),
  )
  let finalized = finalize_standing_watch_supervision_record(
    state,
    context.entry,
    completed,
    standing_goals,
    snapshot_path,
  )
  if finalized != completed {
    replace_standing_watch_recovery_execution(state, finalized)
  }
}

///|
fn replace_standing_watch_recovery_execution(
  state : @core.TownState,
  execution : @core.TaskExecutionRecord,
) -> Unit {
  state.replace_execution(execution)
  state.replace_task(task_for_supervision(state, execution))
  sync_worker_from_execution(state, execution)
}
