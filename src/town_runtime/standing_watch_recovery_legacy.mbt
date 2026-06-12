///|
fn recover_legacy_tick_domain_standing_watch(
  state : @core.TownState,
  execution : @core.TaskExecutionRecord,
) -> Bool {
  if !@standing_watch_policy.legacy_tick_domain_stale_standing_watch(execution) {
    return false
  }
  let completed = copy_execution_with(
    execution,
    status=@core.TaskExecutionStatus::Completed,
    summary="\{execution.summary}\nkeeper_auto_triage: deferred\nkeeper_auto_triage_reason: legacy prelaunch standing-watch heartbeat used an event-count tick while the task id used the daemon tick; mayor closed it as retry accounting.",
    heartbeat_tick=supervision_tick(state),
    next_retry_tick=None,
    result_decision="deferred",
    requires_review=false,
    notify_town=false,
  )
  replace_standing_watch_recovery_execution(state, completed)
  state.record_event(
    @core.TownEvent::new(
      id="event-watch-legacy-tick-reconcile-\{state.events.length()}-\{completed.task_id}",
      kind="standing-watch",
      detail="Mayor closed legacy tick-domain standing watch `\{completed.task_id}` as deferred retry accounting.",
      related_task_id=Some(completed.task_id),
      related_book_id=Some(completed.book_id),
      related_run_id=completed.run_id,
    ),
  )
  true
}
