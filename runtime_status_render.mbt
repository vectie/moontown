///|
pub async fn render_saved_town_status(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  let status = inspect_saved_town(snapshot_path~)
  let daemon = @daemon_runtime.load_daemon_state(
    @daemon_runtime.default_daemon_state_path(snapshot_path),
  )
  let runtime = @daemon_runtime.inspect_daemon_runtime(snapshot_path~)
  let builder = StringBuilder::new()
  builder.write_string("Moontown status\n")
  builder.write_string("\{status.summary}\n")
  if !status.has_snapshot {
    return builder.to_string()
  }
  builder.write_string(
    @runtime_status_policy.render_runtime_status_report(
      status,
      daemon_id=daemon.daemon_id,
      saved_tick=daemon.tick_sequence,
      lease_owner=daemon.lease_owner,
      daemon_job_count=daemon.jobs.length(),
      runtime_health_summary=@daemon_runtime_policy.daemon_runtime_health_summary(
        runtime,
      ),
    ),
  )
  builder.to_string()
}
