///|
fn stabilize_deferred_standing_watch_execution(
  execution : @core.TaskExecutionRecord,
  tick : Int,
) -> @core.TaskExecutionRecord {
  let decision = @standing_watch_policy.standing_watch_recovery_decision_from_execution(
    execution,
  )
  if decision == Deferred &&
    @standing_watch_policy.standing_watch_infrastructure_failure_summary(
      execution.summary,
    ) {
    copy_execution_with(
      execution,
      status=Completed,
      summary="\{execution.summary}\nkeeper_auto_triage: deferred\nkeeper_auto_triage_reason: transient standing-watch infrastructure failure is retry accounting, not durable review debt.",
      heartbeat_tick=tick,
      next_retry_tick=None,
      result_decision="deferred",
      requires_review=false,
      notify_town=false,
    )
  } else {
    execution
  }
}

///|
fn running_standing_watch_execution(
  entry : @moonbook.BookCatalogEntry,
  task : @moonbook.BookTask,
  worker_id : String,
  tick : Int,
) -> @core.TaskExecutionRecord {
  let packet_id = @roles.keeper_packet_id(entry.id, task.id)
  let packet_path = @moonclaw.packet_file_path(
    @moonclaw.default_packet_directory(),
    packet_id,
  )
  @core.TaskExecutionRecord::new(
    task_id=task.id,
    book_id=entry.id,
    packet_id~,
    packet_path~,
    proposal_id=None,
    run_id=None,
    status=Running,
    summary="Mayor assigned \{task.id} for `\{task.title}`; MoonClaw watcher is searching and MoonBook will persist only useful deltas for `\{entry.id}`.",
    output_contract="standing-watch-live-snapshot",
    context_pages=task.target_pages,
    skill_paths=entry.skills,
    last_command=None,
    assigned_worker_id=Some(worker_id),
    attempt=1,
    heartbeat_tick=tick,
    stale_after_tick=tick +
      @standing_watch_policy.standing_watch_stale_window_ticks(),
    next_retry_tick=None,
    requires_review=task.requires_review,
    notify_town=true,
  )
}

///|
fn transient_deferred_standing_watch_execution_record(
  entry : @moonbook.BookCatalogEntry,
  task : @moonbook.BookTask,
  detail : String,
  assigned_worker_id? : String? = None,
  tick? : Int = 0,
) -> @core.TaskExecutionRecord {
  let packet_id = @roles.keeper_packet_id(entry.id, task.id)
  let packet_path = @moonclaw.packet_file_path(
    @moonclaw.default_packet_directory(),
    packet_id,
  )
  @core.TaskExecutionRecord::new(
    task_id=task.id,
    book_id=entry.id,
    packet_id~,
    packet_path~,
    status=Completed,
    summary="\{detail}\nstanding_goal_decision: deferred\nstanding_watch_transient_retry: true\nnext_check_hint: immediate",
    output_contract="standing-watch-live-snapshot",
    assigned_worker_id~,
    heartbeat_tick=tick,
    next_retry_tick=Some(tick + 1),
    requires_review=false,
    notify_town=true,
  )
}

///|
async fn publish_running_standing_watch_snapshot(
  state : @core.TownState,
  entry : @moonbook.BookCatalogEntry,
  task : @moonbook.BookTask,
  decision : @dispatch.RouteDecision,
  worker_id : String?,
  tick : Int,
  snapshot_path : String,
) -> Unit {
  match (decision, worker_id) {
    (Assigned(_), Some(worker_id)) => {
      let live_execution = running_standing_watch_execution(
        entry, task, worker_id, tick,
      )
      state.replace_task(to_town_task(entry, task, live_execution.status))
      state.replace_execution(live_execution)
      sync_worker_from_execution(state, live_execution)
      state.record_event(
        @core.TownEvent::new(
          id="event-watch-running-\{tick}-\{task.id}",
          kind="execution",
          detail="\{task.id} is running now; \{worker_id} is checking sources for `\{entry.id}` and will report whether the book needs an update.",
          related_task_id=Some(task.id),
          related_book_id=Some(entry.id),
        ),
      )
      persist_town_checkpoint(state, snapshot_path)
    }
    _ => ()
  }
}

///|
fn has_active_standing_watch_execution(
  state : @core.TownState,
  goal_id : String,
) -> Bool {
  let prefix = @standing_watch_policy.standing_watch_task_prefix(goal_id)
  for execution in state.executions {
    if execution.task_id.has_prefix(prefix) &&
      @core.active_work_execution_status(execution.status) {
      return true
    }
  }
  false
}
