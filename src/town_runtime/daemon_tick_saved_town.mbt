///|
pub async fn daemon_tick_saved_town(
  snapshot_path? : String = @storage.default_snapshot_path(),
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  respect_runtime_lock? : Bool = true,
) -> String {
  if respect_runtime_lock &&
    @daemon_runtime.daemon_tick_runtime_lock_active(snapshot_path) {
    return "MoonTown daemon tick skipped because another live daemon worker is already ticking. Use the existing daemon loop instead of overlapping manual ticks."
  }
  let context = prepare_daemon_tick_context(snapshot_path, book_catalog_path)
  append_daemon_context_phase_log(context, "start")
  run_daemon_supervision_phase(context, snapshot_path)
  append_daemon_context_phase_log(context, "standing-goals")
  let standing_goals_for_projection = run_daemon_standing_goal_phase(
    context.state,
    context.mayor,
    context.catalog,
    context.paths,
    snapshot_path,
    context.next_tick_sequence,
  )
  run_daemon_scheduled_jobs_phase(context, snapshot_path, book_catalog_path)
  append_daemon_context_phase_log(context, "planbook")
  let planbook_phase = @planbook_runtime.run_planbook_daemon_phase(
    snapshot_path, book_catalog_path,
  )
  run_daemon_projection_phase(
    context.state,
    context.daemon,
    context.paths,
    snapshot_path,
    context.next_tick_sequence,
    standing_goals_for_projection,
    planbook_phase,
  )
}

///|
async fn run_daemon_supervision_phase(
  context : DaemonTickContext,
  snapshot_path : String,
) -> Unit {
  append_daemon_context_phase_log(context, "supervision")
  run_supervision_cycle(
    context.state,
    context.mayor,
    context.catalog,
    snapshot_path~,
    standing_goals=context.standing_goals,
    tick=Some(context.next_tick_sequence),
  )
}

///|
async fn run_daemon_scheduled_jobs_phase(
  context : DaemonTickContext,
  snapshot_path : String,
  book_catalog_path : String,
) -> Unit {
  append_daemon_context_phase_log(context, "scheduled-jobs")
  @daemon_runtime.run_daemon_scheduled_jobs(
    context.state,
    context.daemon.jobs,
    snapshot_path,
    book_catalog_path,
    context.next_tick_sequence,
    context.paths.log_path,
  )
}
