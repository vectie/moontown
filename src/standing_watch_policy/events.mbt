///|
pub fn standing_watch_event_for_record(
  record : @core.WatcherRunRecord,
) -> @core.TownEvent {
  @core.TownEvent::new(
    id="event-watch-\{record.tick}-\{record.goal_id}",
    kind="standing-watch",
    detail="Standing watch \{record.goal_id} -> \{record.decision.to_string()} for \{record.target_book_id}; next_due_tick=\{record.next_due_tick}; \{record.detail}",
    related_book_id=Some(record.target_book_id),
    related_task_id=record.task_id,
    related_run_id=record.run_id,
  )
}
