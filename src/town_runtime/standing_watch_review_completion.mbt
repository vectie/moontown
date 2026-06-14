///|
fn complete_review_queued_standing_watch(
  state : @core.TownState,
  execution : @core.TaskExecutionRecord,
  marker : String,
  reason : String,
  result_decision~ : String,
  event_kind~ : String,
  event_detail~ : String,
) -> Unit {
  let completed = copy_execution_with(
    execution,
    status=@core.TaskExecutionStatus::Completed,
    summary="\{execution.summary}\nkeeper_auto_triage: \{marker}\nkeeper_auto_triage_reason: \{reason}",
    heartbeat_tick=supervision_tick(state),
    next_retry_tick=None,
    result_decision~,
    requires_review=false,
    notify_town=false,
  )
  state.replace_execution(completed)
  state.replace_task(task_for_supervision(state, completed))
  sync_worker_from_execution(state, completed)
  state.record_event(
    @standing_watch_policy.standing_watch_execution_event(
      event_kind,
      state.events.length(),
      completed,
      event_detail,
    ),
  )
}

///|
fn complete_empty_standing_watch_as_no_change(
  state : @core.TownState,
  observed : @core.TaskExecutionRecord,
) -> Unit {
  let completed = copy_execution_with(
    observed,
    status=@core.TaskExecutionStatus::Completed,
    summary=@standing_watch_policy.standing_watch_empty_review_completion_summary(
      observed,
    ),
    heartbeat_tick=supervision_tick(state),
    next_retry_tick=None,
    result_decision="NoChange",
    requires_review=false,
    notify_town=false,
  )
  state.replace_execution(completed)
  state.replace_task(task_for_supervision(state, completed))
  sync_worker_from_execution(state, completed)
  state.record_event(
    @standing_watch_policy.standing_watch_execution_event(
      "event-watch-empty-no-change",
      state.events.length(),
      completed,
      "Mayor closed empty standing-watch completion `\{completed.task_id}` as no_change rather than human review debt.",
    ),
  )
}
