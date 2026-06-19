///|
async fn reconcile_live_executions(
  state : @core.TownState,
  catalog : Array[@moonbook.BookCatalogEntry],
  snapshot_path : String,
  standing_goals : Array[@core.StandingGoal],
  tick? : Int = supervision_tick(state),
) -> Unit {
  let snapshot = state.executions.copy()
  for execution in snapshot {
    if !@core.pollable_execution_status(execution.status) {
      continue
    }
    match execution.run_id {
      Some(run_id) =>
        reconcile_run_backed_live_execution(
          state, catalog, snapshot_path, standing_goals, execution, run_id, tick,
        )
      None => reconcile_no_run_id_live_execution(state, execution, tick)
    }
  }
}

///|
async fn reconcile_run_backed_live_execution(
  state : @core.TownState,
  catalog : Array[@moonbook.BookCatalogEntry],
  snapshot_path : String,
  standing_goals : Array[@core.StandingGoal],
  execution : @core.TaskExecutionRecord,
  run_id : String,
  tick : Int,
) -> Unit {
  let polled = @moonclaw.poll_run(
    execution.task_id,
    run_id,
    cwd=book_workspace_root(state, execution.book_id),
  )
  let updated = copy_execution_with(
    execution,
    status=polled.status,
    summary=polled.summary,
    heartbeat_tick=tick,
    stale_after_tick=tick + @core.polled_execution_stale_window_ticks(execution),
  )
  replace_execution_task_and_worker(state, updated)
  if updated.status != execution.status &&
    @core.terminal_execution_status(updated.status) {
    reconcile_terminal_live_execution(
      state, catalog, snapshot_path, standing_goals, updated,
    )
  }
}

///|
async fn reconcile_terminal_live_execution(
  state : @core.TownState,
  catalog : Array[@moonbook.BookCatalogEntry],
  snapshot_path : String,
  standing_goals : Array[@core.StandingGoal],
  execution : @core.TaskExecutionRecord,
) -> Unit {
  state.record_event(execution_event(execution, state.executions.length() - 1))
  match @moonbook.entry_for_book_id(catalog, execution.book_id) {
    Some(entry) =>
      reconcile_terminal_live_execution_for_book(
        state, entry, snapshot_path, standing_goals, execution,
      )
    None => ()
  }
}

///|
async fn reconcile_terminal_live_execution_for_book(
  state : @core.TownState,
  entry : @moonbook.BookCatalogEntry,
  snapshot_path : String,
  standing_goals : Array[@core.StandingGoal],
  execution : @core.TaskExecutionRecord,
) -> Unit {
  let reconciled = match persist_execution_into_book(state, entry, execution) {
    Some(outcome) =>
      execution_after_successful_book_persist(
        execution,
        outcome,
        supervision_tick(state),
      )
    None => execution
  }
  if reconciled != execution {
    replace_execution_task_and_worker(state, reconciled)
  }
  finalize_goal_book_entry(state, entry, 0, [reconciled.task_id])
  let observed = finalize_standing_watch_supervision_record(
    state, entry, reconciled, standing_goals, snapshot_path,
  )
  if observed != reconciled {
    replace_execution_task_and_worker(state, observed)
  }
}

///|
fn replace_execution_task_and_worker(
  state : @core.TownState,
  execution : @core.TaskExecutionRecord,
) -> Unit {
  state.replace_execution(execution)
  state.replace_task(task_for_supervision(state, execution))
  sync_worker_from_execution(state, execution)
}

///|
async fn reconcile_no_run_id_live_execution(
  state : @core.TownState,
  execution : @core.TaskExecutionRecord,
  tick : Int,
  launch_confirmed_run? : Bool = true,
  launch_command_override? : String? = None,
) -> Unit {
  if execution.status == ProposalImported {
    if reconcile_detached_import_receipt_if_available(
        state,
        execution,
        tick,
        launch_confirmed_run~,
        launch_command_override~,
      ) {
      return
    }
  }
  if @core.no_run_id_live_execution_stale(execution, tick) {
    fail_stale_no_run_id_execution(state, execution, tick)
  }
}

///|
async fn fail_stale_no_run_id_execution(
  state : @core.TownState,
  execution : @core.TaskExecutionRecord,
  tick : Int,
) -> Unit {
  let stderr_summary = detached_import_stderr_summary(
    detached_import_packet_path_for_execution(execution),
  )
  let updated = copy_execution_with(
    execution,
    status=Failed,
    summary="Standing watch execution failed for \{execution.book_id} / \{execution.task_id}: timed out while importing MoonClaw proposal; no run id or detached import receipt became available before the heartbeat window.\{stderr_summary}",
    heartbeat_tick=tick,
    next_retry_tick=None,
    result_decision="deferred",
    requires_review=false,
    notify_town=false,
  )
  replace_execution_task_and_worker(state, updated)
}
