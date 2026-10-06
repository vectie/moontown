///|
async fn run_standing_goal_watch_cycle(
  state : @core.TownState,
  mayor : @roles.Mayor,
  catalog : Array[@moonbook.BookCatalogEntry],
  goal : @core.StandingGoal,
  tick : Int,
  snapshot_path : String,
  execute? : async (
    @roles.Mayor,
    @moonbook.BookCatalogEntry,
    @moonbook.BookTask,
    @roles.MayorDispatchPacket,
    String?,
    Int,
  ) -> @core.TaskExecutionRecord = execute_dispatched_standing_watch_task,
  persist? : async (
    @core.TownState,
    @moonbook.BookCatalogEntry,
    @core.TaskExecutionRecord,
  ) -> @moonbook.PersistResultOutcome? = persist_execution_into_book,
) -> @core.StandingGoal {
  guard material_watch_plan_path(goal) is Some(plan_path) else {
    return run_standing_goal_watch_cycle_unlocked(
      state,
      mayor,
      catalog,
      goal,
      tick,
      snapshot_path,
      execute~,
      persist~,
    )
  }
  let directory = material_watch_directory(snapshot_path, goal.id)
  let target_book_id = goal.target_book_id.unwrap_or("mayor-selected-book")
  let ledger_dir = @storage.watcher_ledger_dir_for_snapshot(snapshot_path)
  try {
    @fs.mkdir(directory, recursive=true) catch {
      error =>
        if !@fs.exists(directory) || @fs.kind(directory) != Directory {
          raise error
        }
    }
    let lock = @fs.open(
      directory + "/watch.lock",
      mode=ReadWrite,
      create_mode=OpenOrCreate,
    )
    defer lock.close()
    if !lock.try_lock(Exclusive) {
      return goal.mark_watcher_decision(tick, Deferred)
    }
    reconcile_material_watch_receipts(directory)
    guard @moonbook.entry_for_book_id(catalog, target_book_id) is Some(entry) else {
      fail("Material-watch target Book is unavailable: " + target_book_id)
    }
    match
      prepare_material_watch(state, entry, goal, tick, directory, plan_path) {
      Quiet(detail) =>
        record_standing_watch_cycle_decision(
          state,
          goal,
          tick,
          target_book_id,
          ledger_dir,
          NoChange,
          detail,
        )
      Waiting(detail, run_id) =>
        record_standing_watch_cycle_decision(
          state,
          goal,
          tick,
          target_book_id,
          ledger_dir,
          Deferred,
          detail,
          run_id~,
        )
      Dispatch(change) =>
        run_standing_goal_watch_cycle_unlocked(
          state,
          mayor,
          catalog,
          goal,
          tick,
          snapshot_path,
          material_change=Some(change),
          execute~,
          persist~,
        )
    }
  } catch {
    error =>
      record_standing_watch_cycle_decision(
        state,
        goal,
        tick,
        target_book_id,
        ledger_dir,
        Failed,
        "Material watch blocked; retained plan, source evidence and original task/run: " +
        error.to_string(),
      )
  }
}

///|
async fn run_standing_goal_watch_cycle_unlocked(
  state : @core.TownState,
  mayor : @roles.Mayor,
  catalog : Array[@moonbook.BookCatalogEntry],
  goal : @core.StandingGoal,
  tick : Int,
  snapshot_path : String,
  material_change? : MaterialWatchChange? = None,
  execute? : async (
    @roles.Mayor,
    @moonbook.BookCatalogEntry,
    @moonbook.BookTask,
    @roles.MayorDispatchPacket,
    String?,
    Int,
  ) -> @core.TaskExecutionRecord = execute_dispatched_standing_watch_task,
  persist? : async (
    @core.TownState,
    @moonbook.BookCatalogEntry,
    @core.TaskExecutionRecord,
  ) -> @moonbook.PersistResultOutcome? = persist_execution_into_book,
) -> @core.StandingGoal {
  let target_book_id = goal.target_book_id.unwrap_or("mayor-selected-book")
  let ledger_dir = @storage.watcher_ledger_dir_for_snapshot(snapshot_path)
  let previous_records = @storage.load_watcher_run_records(
    goal.id,
    dir=ledger_dir,
  )
  let no_change_streak = @storage.consecutive_no_change_count(previous_records)
  if has_active_standing_watch_execution(state, goal.id) {
    return record_standing_watch_cycle_decision(
      state,
      goal,
      tick,
      target_book_id,
      ledger_dir,
      Deferred,
      "Mayor deferred standing goal because a previous watcher execution is still active.",
    )
  }
  let entry = match @moonbook.entry_for_book_id(catalog, target_book_id) {
    Some(entry) => entry
    None =>
      return record_standing_watch_cycle_decision(
        state,
        goal,
        tick,
        target_book_id,
        ledger_dir,
        Failed,
        "Mayor could not resolve target MoonBook `\{target_book_id}` for standing goal.",
      )
  }
  register_town_books(state, [entry.to_book_ref()])
  register_town_workers(state)
  let task = standing_watch_task(goal, target_book_id, tick, no_change_streak)
  let task = match material_change {
    Some(change) =>
      @moonbook.BookTask::new(
        id=task.id,
        goal=task.goal,
        title=task.title,
        kind=task.kind,
        priority=task.priority,
        requires_review=task.requires_review,
        required_role=task.required_role,
        prompt=task.prompt +
          "\n" +
          material_watch_summary(change) +
          "\nRead the retained before/after input. Keep normal Book review policy; source change alone is not accepted knowledge.",
        target_pages=[..task.target_pages, change.input_path],
      )
    None => task
  }
  let planned_task = to_town_task(entry, task, PacketReady)
  let route = mayor.decide_dispatch(state, planned_task)
  state.record_event(route_event(route.decision, state.events.length()))
  let worker_id = assigned_worker_id(route.decision)
  match route.decision {
    Deferred(reason) =>
      return record_standing_watch_cycle_decision(
        state,
        goal,
        tick,
        target_book_id,
        ledger_dir,
        Deferred,
        "Mayor deferred standing goal because no watcher was currently eligible: \{reason}",
        task_id=Some(task.id),
      )
    _ => ()
  }
  let execution_tick = tick
  if material_change is Some(change) {
    reserve_material_watch_change(
      material_watch_directory(snapshot_path, goal.id),
      change,
    )
  }
  publish_running_standing_watch_snapshot(
    state,
    entry,
    task,
    route.decision,
    worker_id,
    execution_tick,
    snapshot_path,
    material_change~,
  )
  let final_execution = execute(
    mayor, entry, task, route, worker_id, execution_tick,
  )
  let final_execution = match material_change {
    Some(change) => {
      let bound = bind_material_watch_execution(final_execution, change)
      remember_material_watch_execution(
        material_watch_directory(snapshot_path, goal.id),
        bound,
      )
      bound
    }
    None => final_execution
  }
  apply_standing_watch_execution_state(state, entry, task, final_execution)
  let observed_execution = standing_watch_execution_with_book_decision(
    entry, final_execution,
  )
  if observed_execution != final_execution {
    state.replace_execution(observed_execution)
  }
  let persisted = if @core.unconfirmed_standing_watch_dispatch(
      observed_execution,
    ) {
    None
  } else {
    persist(state, entry, observed_execution)
  }
  let reconciled_execution = match persisted {
    Some(outcome) if material_change is Some(_) &&
      (
        outcome.executable_event.book_id != observed_execution.book_id ||
        outcome.executable_event.result_id != observed_execution.task_id
      ) =>
      copy_execution_with(
        observed_execution,
        status=AwaitingPersistence,
        summary=observed_execution.summary +
          "\nBook receipt did not match this material-watch task; original result retained.",
      )
    Some(outcome) => {
      if material_change is Some(_) {
        remember_material_watch_receipt(
          material_watch_directory(snapshot_path, goal.id),
          observed_execution,
          outcome,
        )
      }
      execution_after_successful_book_persist(observed_execution, outcome, tick)
    }
    None =>
      if material_change is Some(_) &&
        (
          observed_execution.status == Completed ||
          observed_execution.status == ReviewQueued
        ) {
        copy_execution_with(
          observed_execution,
          status=AwaitingPersistence,
          summary=observed_execution.summary +
            "\nMaterial watch retains the original result; Book persistence is unconfirmed.",
        )
      } else {
        observed_execution
      }
  }
  let stabilized_execution = stabilize_deferred_standing_watch_execution(
    reconciled_execution, tick,
  )
  let stabilized_execution = match material_change {
    Some(change) => bind_material_watch_execution(stabilized_execution, change)
    None => stabilized_execution
  }
  if material_change is Some(_) {
    remember_material_watch_execution(
      material_watch_directory(snapshot_path, goal.id),
      stabilized_execution,
    )
  }
  if stabilized_execution != observed_execution {
    apply_standing_watch_execution_state(
      state, entry, task, stabilized_execution,
    )
  }
  collapse_standing_watch_book_history(entry, observed_execution)
  if !@core.unconfirmed_standing_watch_dispatch(observed_execution) &&
    (
      @core.terminal_execution_status(observed_execution.status) ||
      local_wenyu_result_ready_for_projection(observed_execution)
    ) {
    finalize_goal_book_entry(state, entry, 0, [stabilized_execution.task_id])
  }
  record_completed_standing_watch_cycle(
    state, goal, tick, target_book_id, ledger_dir, stabilized_execution, no_change_streak,
  )
}
