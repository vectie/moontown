///|
async fn reconcile_persisted_standing_watch_records(
  state : @core.TownState,
  snapshot_path : String,
  standing_goals : Array[@core.StandingGoal],
) -> Unit {
  let ledger_dir = watcher_ledger_dir_for_snapshot(snapshot_path)
  let snapshot = state.executions.copy()
  for execution in snapshot {
    let goal = match
      @standing_watch_policy.standing_goal_for_execution_task(
        standing_goals,
        execution.task_id,
      ) {
      Some(goal) => goal
      None => continue
    }
    match
      terminal_watcher_record_for_execution(goal.id, ledger_dir, execution) {
      Some(record) => {
        if @standing_watch_policy.watcher_record_effective_decision(record) ==
          @core.WatcherDecisionKind::NeedsReview &&
          standing_watch_review_superseded_by_newer_review(
            snapshot, standing_goals, goal, execution,
          ) {
          continue
        }
        let status = task_status_for_terminal_watcher_decision(record.decision)
        let reconciled = copy_execution_with(
          execution,
          status~,
          summary="\{record.detail}\nkeeper_auto_triage: reconciled_from_watcher_ledger\nreconciled_watcher_decision: \{record.decision.to_string()}",
          heartbeat_tick=supervision_tick(state),
          next_retry_tick=None,
          result_decision=record.decision.to_string(),
          requires_review=record.decision ==
            @core.WatcherDecisionKind::NeedsReview,
        )
        state.replace_execution(reconciled)
        state.replace_task(task_for_supervision(state, reconciled))
        sync_worker_from_execution(state, reconciled)
        state.record_event(
          @core.TownEvent::new(
            id="event-watch-ledger-reconcile-\{state.events.length()}-\{reconciled.task_id}",
            kind="standing-watch",
            detail="Mayor reconciled `\{reconciled.task_id}` from the persisted watcher ledger as \{record.decision.to_string()}.",
            related_task_id=Some(reconciled.task_id),
            related_book_id=Some(reconciled.book_id),
            related_run_id=reconciled.run_id,
          ),
        )
      }
      None => ()
    }
  }
}
