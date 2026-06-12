///|
async fn run_standing_goal_watch_cycle(
  state : @core.TownState,
  mayor : @roles.Mayor,
  catalog : Array[@moonbook.BookCatalogEntry],
  goal : @core.StandingGoal,
  tick : Int,
  snapshot_path : String,
) -> @core.StandingGoal {
  let target_book_id = goal.target_book_id.unwrap_or("mayor-selected-book")
  let ledger_dir = @storage.watcher_ledger_dir_for_snapshot(snapshot_path)
  let previous_records = @storage.load_watcher_run_records(
    goal.id,
    dir=ledger_dir,
  )
  let no_change_streak = @storage.consecutive_no_change_count(previous_records)
  if has_active_standing_watch_execution(state, goal.id) {
    return record_standing_watch_cycle_decision(
      state,
      goal,
      tick,
      target_book_id,
      ledger_dir,
      @core.WatcherDecisionKind::Deferred,
      "Mayor deferred standing goal because a previous watcher execution is still active.",
    )
  }
  let entry = match @moonbook.entry_for_book_id(catalog, target_book_id) {
    Some(entry) => entry
    None =>
      return record_standing_watch_cycle_decision(
        state,
        goal,
        tick,
        target_book_id,
        ledger_dir,
        @core.WatcherDecisionKind::Failed,
        "Mayor could not resolve target MoonBook `\{target_book_id}` for standing goal.",
      )
  }
  register_demo_books(state, [entry.to_book_ref()])
  register_demo_workers(state)
  let task = @standing_watch_policy.standing_watch_task(
    goal, target_book_id, tick, no_change_streak,
  )
  let planned_task = to_town_task(
    entry,
    task,
    @core.TaskExecutionStatus::PacketReady,
  )
  let route = mayor.decide_dispatch(state, planned_task)
  state.record_event(route_event(route.decision, state.events.length()))
  let worker_id = assigned_worker_id(route.decision)
  match route.decision {
    @dispatch.RouteDecision::Deferred(reason) =>
      return record_standing_watch_cycle_decision(
        state,
        goal,
        tick,
        target_book_id,
        ledger_dir,
        @core.WatcherDecisionKind::Deferred,
        "Mayor deferred standing goal because no watcher was currently eligible: \{reason}",
        task_id=Some(task.id),
      )
    _ => ()
  }
  let execution_tick = tick
  publish_running_standing_watch_snapshot(
    state,
    entry,
    task,
    route.decision,
    worker_id,
    execution_tick,
    snapshot_path,
  )
  let final_execution = execute_dispatched_standing_watch_task(
    mayor, entry, task, route, worker_id, execution_tick,
  )
  apply_standing_watch_execution_state(state, entry, task, final_execution)
  let observed_execution = standing_watch_execution_with_book_decision(
    entry, final_execution,
  )
  if observed_execution != final_execution {
    state.replace_execution(observed_execution)
  }
  let reconciled_execution = match
    persist_execution_into_book(state, entry, observed_execution) {
    Some(outcome) =>
      execution_after_successful_book_persist(observed_execution, outcome, tick)
    None => observed_execution
  }
  let stabilized_execution = stabilize_deferred_standing_watch_execution(
    reconciled_execution, tick,
  )
  if stabilized_execution != observed_execution {
    apply_standing_watch_execution_state(
      state, entry, task, stabilized_execution,
    )
  }
  collapse_standing_watch_book_history(entry, observed_execution)
  if @core.terminal_execution_status(observed_execution.status) {
    finalize_goal_book_entry(state, entry, 0, [stabilized_execution.task_id])
  }
  record_completed_standing_watch_cycle(
    state, goal, tick, target_book_id, ledger_dir, stabilized_execution, no_change_streak,
  )
}
