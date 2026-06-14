///|
pub fn standing_watch_event_kind() -> String {
  "standing-watch"
}

///|
pub fn standing_watch_execution_event(
  event_prefix : String,
  event_count : Int,
  execution : @core.TaskExecutionRecord,
  detail : String,
) -> @core.TownEvent {
  @core.TownEvent::new(
    id="\{event_prefix}-\{event_count}-\{execution.task_id}",
    kind=standing_watch_event_kind(),
    detail~,
    related_task_id=Some(execution.task_id),
    related_book_id=Some(execution.book_id),
    related_run_id=execution.run_id,
  )
}

///|
pub fn standing_watch_event_for_record(
  record : @core.WatcherRunRecord,
) -> @core.TownEvent {
  @core.TownEvent::new(
    id="event-watch-\{record.tick}-\{record.goal_id}",
    kind=standing_watch_event_kind(),
    detail="Standing watch \{record.goal_id} -> \{record.decision.to_string()} for \{record.target_book_id}; next_due_tick=\{record.next_due_tick}; \{record.detail}",
    related_book_id=Some(record.target_book_id),
    related_task_id=record.task_id,
    related_run_id=record.run_id,
  )
}
