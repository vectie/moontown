///|
async fn execute_goal_book_task(
  mayor : @roles.Mayor,
  entry : @moonbook.BookCatalogEntry,
  task : @moonbook.BookTask,
  assigned_worker_id? : String? = None,
  tick? : Int = 0,
  run_inline? : Bool = moontown_moonclaw_inline_enabled(),
) -> @core.TaskExecutionRecord {
  if @build_pipeline.is_wenyu_book(entry) &&
    @build_pipeline.is_local_wenyu_build_fallback_task(task.kind) {
    return @build_pipeline.local_wenyu_build_execution_record(
      entry,
      task,
      assigned_worker_id~,
      tick~,
    )
  }
  let prepared = mayor.prepare_keeper_packet(entry, task)
  let workspace_root = @moonbook.workspace_root(entry)
  let maintenance_summary = if is_detached_standing_watch_task(task) {
    @moonclaw_runtime.compact_moonclaw_job_store_if_needed(workspace_root, tick)
  } else {
    ""
  }
  let imported = if is_detached_standing_watch_task(task) {
    @moonclaw.import_packet_detached(
      prepared.packet,
      prepared.packet_path,
      cwd=workspace_root,
      confirm=true,
      run_inline~,
    )
  } else {
    import_packet_with_daemon_timeout(
      prepared.packet,
      prepared.packet_path,
      workspace_root,
      run_inline,
    )
  }
  let execution = match imported.run_id {
    Some(run_id) => ensure_run_execution(task.id, run_id, workspace_root)
    None => None
  }
  @core.TaskExecutionRecord::new(
    task_id=task.id,
    book_id=entry.id,
    packet_id=prepared.packet.packet_id,
    packet_path=prepared.packet_path,
    proposal_id=Some(imported.proposal_id),
    run_id=imported.run_id,
    status=execution
      .map(fn(result) { result.0.status })
      .unwrap_or(imported.status),
    summary=execution
      .map(fn(result) {
        append_execution_maintenance_summary(
          result.0.summary,
          maintenance_summary,
        )
      })
      .unwrap_or(
        append_execution_maintenance_summary(
          imported.summary,
          maintenance_summary,
        ),
      ),
    output_contract=prepared.packet.output_contract,
    context_pages=prepared.packet.context_pages,
    skill_paths=prepared.packet.skill_paths,
    last_command=Some(render_execution_commands(imported.command, execution)),
    assigned_worker_id~,
    attempt=1,
    heartbeat_tick=tick,
    stale_after_tick=tick + external_execution_stale_window_ticks(),
    next_retry_tick=None,
    result_decision=execution
      .map(fn(result) { result.0.result_decision })
      .unwrap_or("pending"),
    requires_review=execution
      .map(fn(result) { result.0.requires_review })
      .unwrap_or(task.requires_review),
    notify_town=execution
      .map(fn(result) { result.0.notify_town })
      .unwrap_or(true),
  )
}
