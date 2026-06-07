///|
pub async fn render_saved_town_status(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  let status = inspect_saved_town(snapshot_path~)
  let daemon = load_daemon_state(default_daemon_state_path(snapshot_path))
  let runtime = inspect_daemon_runtime(snapshot_path~)
  let builder = StringBuilder::new()
  builder.write_string("Moontown status\n")
  builder.write_string("\{status.summary}\n")
  if !status.has_snapshot {
    return builder.to_string()
  }
  write_runtime_status_snapshot_summary(builder, status, daemon, runtime)
  write_runtime_status_daemon_actions(builder, status.daemon_actions)
  builder.to_string()
}

///|
fn write_runtime_status_snapshot_summary(
  builder : StringBuilder,
  status : TownRuntimeStatus,
  daemon : @scheduler.DaemonState,
  runtime : DaemonRuntimeHealth,
) -> Unit {
  builder.write_string("snapshot=\{status.snapshot_path}\n")
  builder.write_string(
    "daemon=\{daemon.daemon_id} tick=\{status.daemon_tick} saved_tick=\{daemon.tick_sequence} lease=\{daemon.lease_owner} jobs=\{daemon.jobs.length()}\n",
  )
  builder.write_string("\{daemon_runtime_health_summary(runtime)}\n")
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
}

///|
fn write_runtime_status_daemon_actions(
  builder : StringBuilder,
  actions : Array[@scheduler.SchedulerAction],
) -> Unit {
  for action in actions {
    builder.write_string("- \{action.kind}: \{action.detail}\n")
  }
}
