///|
pub async fn render_civic_communication_schedule_status(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  let schedules = load_or_create_civic_communication_schedules(
    path=default_civic_communication_schedule_path(snapshot_path~),
  )
  let now_ms = @env.now()
  let builder = StringBuilder::new()
  builder.write_string("# Civic Communication Pattern Schedule Status\n\n")
  builder.write_string(
    "| Pattern session | Building | Enabled | Due | Interval min | Rounds | Latest |\n",
  )
  builder.write_string("| --- | --- | ---:| ---:| ---:| ---:| --- |\n")
  for schedule in schedules {
    builder.write_string(
      "|\{schedule.title}|\{schedule.building_id}|\{schedule.enabled}|\{civic_communication_is_due(schedule, now_ms)}|\{schedule.interval_ms / 60_000UL}|\{schedule.round_count}|\{schedule.latest_round_id}|\n",
    )
  }
  builder.to_string()
}
