///|
/// Called under the per-goal lock, before the existing Mayor/Claw dispatch.
/// Persist intent before crossing the dispatch boundary. A reservation without
/// a receipt can only reconcile the original task; it cannot allocate another.
async fn prepare_material_watch(
  state : @core.TownState,
  entry : @moonbook.BookCatalogEntry,
  goal : @core.StandingGoal,
  tick : Int,
  directory : String,
  plan_path : String,
) -> MaterialWatchPreparation {
  let mut saved = load_material_watch_journal(directory)
  if saved is Some(journal) {
    guard journal.goal_id == goal.id && journal.book_id == entry.id else {
      fail("Material-watch journal belongs to a different goal/book")
    }
    let changes = []
    for change in journal.changes {
      let observed = material_watch_observed_execution(state, change)
      let updated = match observed {
        Some(execution) => {
          let bound = bind_material_watch_execution(execution, change)
          state.replace_execution(bound)
          state.replace_task(task_for_supervision(state, bound))
          { ..change, execution: Some(bound), }
        }
        None => change
      }
      changes.push(updated)
    }
    let refreshed = { ..journal, changes, }
    if refreshed != journal {
      save_material_watch_journal(directory, refreshed)
    }
    saved = Some(refreshed)
  }
  // Read failures are health failures, never fabricated NoChange.
  let plan = @material_watch_plan.read_plan(entry, goal, plan_path)
  let sources = @material_watch_plan.read_sources(entry, plan)
  guard saved is Some(journal) else {
    save_material_watch_journal(directory, {
      contract: "moontown.material_watch.v1",
      goal_id: goal.id,
      book_id: entry.id,
      baseline_plan: plan,
      baseline: sources,
      changes: [],
    })
    return Quiet(
      "Material watch baseline saved for \{sources.length()} sources; no review requested.",
    )
  }
  for change in journal.changes {
    match change.execution {
      Some(execution) if change.book_receipt is Some(_) &&
        material_watch_settled(execution) => ()
      observed =>
        return Waiting(
          "Material watch retains task \{change.input.task_id}; reconcile its original dispatch/result before starting another change.",
          observed.bind(execution => execution.run_id),
        )
    }
  }
  if journal.baseline == sources && journal.baseline_plan == plan {
    return Quiet(
      "Material watch unchanged: \{sources.length()} exact sources; no new task or review.",
    )
  }
  let task_id = @standing_watch_policy.standing_watch_task_id(goal.id, tick)
  guard !journal.changes.any(change => change.input.task_id == task_id) else {
    return Waiting(
      "This watch tick already owns a source-bound task; wait for the next due tick.",
      None,
    )
  }
  let input : MaterialWatchInput = {
    goal,
    task_id,
    plan,
    before: journal.baseline,
    after: sources,
  }
  let input_path = directory +
    "/input-" +
    material_watch_hash(task_id) +
    ".json"
  // A crash between input and journal write is replayable only for identical input.
  if @fs.exists(input_path) {
    let existing : MaterialWatchInput = @json.from_json(
      @json.parse(@fs.read_file(input_path).text()),
    )
    guard existing == input else {
      fail(
        "Existing material-watch input needs reconciliation; no replacement was dispatched",
      )
    }
  } else {
    @fs.write_file(
      input_path,
      @utf8.encode(input.to_json().stringify()),
      create_mode=CreateNew,
    )
  }
  let change : MaterialWatchChange = {
    input,
    input_path,
    execution: None,
    book_receipt: None,
  }
  Dispatch(change)
}

///|
async fn reserve_material_watch_change(
  directory : String,
  change : MaterialWatchChange,
) -> Unit {
  guard load_material_watch_journal(directory) is Some(journal) else {
    fail("Material-watch baseline disappeared before dispatch")
  }
  guard !journal.changes.any(saved => {
    saved.input.task_id == change.input.task_id
  }) else {
    fail("Material-watch task is already reserved; reconcile it instead")
  }
  save_material_watch_journal(directory, {
    ..journal,
    baseline: change.input.after,
    baseline_plan: change.input.plan,
    changes: [..journal.changes, change],
  })
}

///|
fn material_watch_settled(execution : @core.TaskExecutionRecord) -> Bool {
  let decision = @standing_watch_policy.standing_watch_decision_from_execution(
    execution,
  )
  (execution.status == Completed || execution.status == ReviewQueued) &&
  execution.summary.contains("material_watch_book_persisted: true") &&
  (decision == NoChange || decision == Update || decision == NeedsReview)
}

///|
fn material_watch_observed_execution(
  state : @core.TownState,
  change : MaterialWatchChange,
) -> @core.TaskExecutionRecord? raise {
  let current = @core.find_execution(state, change.input.task_id)
  select_material_watch_execution(change, current)
}

///|
fn select_material_watch_execution(
  change : MaterialWatchChange,
  current : @core.TaskExecutionRecord?,
) -> @core.TaskExecutionRecord? raise {
  if current is Some(execution) {
    guard execution.book_id == change.input.plan.book_id &&
      execution.task_id == change.input.task_id else {
      fail(
        "Material-watch execution Book identity conflicts with retained input",
      )
    }
  }
  match (current, change.execution) {
    (Some(current), Some(saved)) => {
      guard current.packet_id == saved.packet_id else {
        fail("Material-watch packet identity conflicts with the saved dispatch")
      }
      if current.run_id is Some(run) &&
        saved.run_id is Some(old_run) &&
        run != old_run {
        fail("Material-watch run identity conflicts with the saved receipt")
      }
      // Transient dispatch failures can be represented as Completed/deferred
      // before any run is known. That shape is not a completed worker result;
      // a genuine late receipt for the reserved task must advance it.
      if saved.run_id is None && current.run_id is Some(_) {
        return Some(current)
      }
      // Merge polling, explicit observations and stale checkpoints with one
      // monotone result rule. A late failure must not erase retained output.
      let saved_result = saved.status == Completed ||
        saved.status == ReviewQueued ||
        saved.status == AwaitingPersistence
      let current_result = current.status == Completed ||
        current.status == ReviewQueued ||
        current.status == AwaitingPersistence
      let acknowledged = change.book_receipt is Some(_)
      if (saved_result && !current_result) ||
        (
          acknowledged &&
          saved.status == Completed &&
          current.status != Completed
        ) ||
        (
          acknowledged &&
          saved.status == ReviewQueued &&
          current.status == AwaitingPersistence
        ) ||
        (material_watch_settled(saved) && !material_watch_settled(current)) ||
        (current.run_id is None && saved.run_id is Some(_)) {
        Some(saved)
      } else {
        Some(current)
      }
    }
    (Some(current), None) => Some(current)
    (None, saved) => saved
  }
}
