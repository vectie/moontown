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
    @core.TownEvent::new(
      id="\{event_kind}-\{state.events.length()}-\{completed.task_id}",
      kind="standing-watch",
      detail=event_detail,
      related_task_id=Some(completed.task_id),
      related_book_id=Some(completed.book_id),
      related_run_id=completed.run_id,
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
    summary=standing_watch_empty_review_completion_summary(observed),
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
    @core.TownEvent::new(
      id="event-watch-empty-no-change-\{state.events.length()}-\{completed.task_id}",
      kind="standing-watch",
      detail="Mayor closed empty standing-watch completion `\{completed.task_id}` as no_change rather than human review debt.",
      related_task_id=Some(completed.task_id),
      related_book_id=Some(completed.book_id),
      related_run_id=completed.run_id,
    ),
  )
}

///|
fn standing_watch_empty_review_completion_summary(
  observed : @core.TaskExecutionRecord,
) -> String {
  [
    observed.summary,
    "keeper_auto_triage: empty_completion_no_change",
    standing_watch_empty_review_completion_reason_line(),
    standing_watch_empty_completion_no_change_summary(observed.task_id),
  ].join("\n")
}

///|
fn standing_watch_empty_review_completion_reason_line() -> String {
  "keeper_auto_triage_reason: \{standing_watch_empty_review_completion_reason()}"
}

///|
fn standing_watch_empty_review_completion_reason() -> String {
  [
    "watcher completed without a standing-goal decision marker, candidate insight, evidence delta, or source delta,",
    "so mayor treats it as no_change instead of human review debt.",
  ].join(" ")
}
