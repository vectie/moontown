///|
pub fn render_runtime_status_report(
  status : TownRuntimeStatus,
  daemon_id~ : String,
  saved_tick~ : Int,
  lease_owner~ : String,
  daemon_job_count~ : Int,
  runtime_health_summary~ : String,
) -> String {
  let builder = StringBuilder::new()
  builder.write_string("snapshot=\{status.snapshot_path}\n")
  builder.write_string(
    "daemon=\{daemon_id} tick=\{status.daemon_tick} saved_tick=\{saved_tick} lease=\{lease_owner} jobs=\{daemon_job_count}\n",
  )
  builder.write_string("\{runtime_health_summary}\n")
  builder.write_string(
    "standing_goals=\{status.standing_goal_count} enabled=\{status.enabled_standing_goal_count} disabled=\{status.disabled_standing_goal_count} due_next_tick=\{status.due_standing_goal_count}\n",
  )
  builder.write_string(
    "watcher_records=\{status.watcher_record_count} \{status.watcher_summary}\n",
  )
  builder.write_string(
    "book_template_requests=\{status.book_template_request_count} pending=\{status.pending_book_template_request_count} failed=\{status.failed_book_template_request_count} \{status.book_template_request_summary}\n",
  )
  builder.write_string(
    "book_template_latest_event=\{status.book_template_latest_event_summary}\n",
  )
  builder.write_string(
    "planned daemon actions=\{status.daemon_actions.length()}\n",
  )
  builder.write_string(
    render_runtime_status_daemon_actions(status.daemon_actions),
  )
  builder.to_string()
}

///|
pub fn render_runtime_status_daemon_actions(
  actions : Array[@scheduler.SchedulerAction],
) -> String {
  let builder = StringBuilder::new()
  for action in actions {
    builder.write_string("- \{action.kind}: \{action.detail}\n")
  }
  builder.to_string()
}
