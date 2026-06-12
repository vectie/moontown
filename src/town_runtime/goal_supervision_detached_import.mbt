///|
async fn reconcile_late_detached_import_receipts(
  state : @core.TownState,
  tick : Int,
  catalog? : Array[@moonbook.BookCatalogEntry] = [],
  snapshot_path? : String = @storage.default_snapshot_path(),
  standing_goals? : Array[@core.StandingGoal] = [],
) -> Unit {
  let snapshot = state.executions.copy()
  for execution in snapshot {
    if !late_detached_import_receipt_candidate(execution) {
      continue
    }
    if reconcile_detached_import_receipt_if_available(
        state,
        execution,
        tick,
        launch_confirmed_run=true,
      ) {
      let updated = @core.find_execution(state, execution.task_id).unwrap_or(
        execution,
      )
      finalize_terminal_detached_watcher_ledger_if_needed(
        state, catalog, snapshot_path, standing_goals, updated,
      )
    } else {
      hydrate_detached_import_handle_if_missing(state, execution)
    }
  }
}

///|
async fn reconcile_terminal_detached_watcher_ledgers(
  state : @core.TownState,
  catalog : Array[@moonbook.BookCatalogEntry],
  snapshot_path : String,
  standing_goals : Array[@core.StandingGoal],
) -> Unit {
  let snapshot = state.executions.copy()
  for execution in snapshot {
    if terminal_detached_watcher_ledger_candidate(
        execution, standing_goals, snapshot_path,
      ) {
      finalize_terminal_detached_watcher_ledger_if_needed(
        state, catalog, snapshot_path, standing_goals, execution,
      )
    }
  }
}
