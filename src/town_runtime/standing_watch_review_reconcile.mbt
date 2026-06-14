///|
async fn reconcile_review_queued_standing_watch_outputs(
  state : @core.TownState,
  catalog : Array[@moonbook.BookCatalogEntry],
  snapshot_path : String,
  standing_goals : Array[@core.StandingGoal],
) -> Unit {
  let snapshot = state.executions.copy()
  for execution in snapshot {
    if execution.status != @core.TaskExecutionStatus::ReviewQueued {
      continue
    }
    let goal = match
      @standing_watch_policy.standing_goal_for_execution_task(
        standing_goals,
        execution.task_id,
      ) {
      Some(goal) => goal
      None => continue
    }
    if @standing_watch_policy.standing_watch_review_superseded_by_newer_review(
        snapshot, standing_goals, goal, execution,
      ) {
      complete_review_queued_standing_watch(
        state,
        execution,
        "superseded_review",
        "a newer standing-watch cycle already reached a terminal non-review state for the same standing goal, so this older review is historical accounting rather than active keeper debt.",
        result_decision="superseded-review",
        event_kind="event-watch-superseded-review",
        event_detail="Mayor closed superseded review `\{execution.task_id}` because a newer terminal standing-watch cycle exists for `\{goal.id}`.",
      )
      continue
    }
    let entry = match @moonbook.entry_for_book_id(catalog, execution.book_id) {
      Some(entry) => entry
      None => continue
    }
    if @standing_watch_policy.legacy_review_queued_retry_accounting_standing_watch(
        execution,
      ) {
      complete_review_queued_standing_watch(
        state,
        execution,
        "deferred",
        "legacy review-queued standing-watch record was transient infrastructure retry accounting, not durable keeper review debt.",
        result_decision="deferred",
        event_kind="event-watch-legacy-review-reconcile",
        event_detail="Mayor closed legacy review-queued standing watch `\{execution.task_id}` as deferred retry accounting.",
      )
      continue
    }
    reconcile_observed_review_queued_standing_watch(
      state, entry, execution, goal, standing_goals, snapshot_path,
    )
  }
}

///|
async fn reconcile_observed_review_queued_standing_watch(
  state : @core.TownState,
  entry : @moonbook.BookCatalogEntry,
  execution : @core.TaskExecutionRecord,
  goal : @core.StandingGoal,
  standing_goals : Array[@core.StandingGoal],
  snapshot_path : String,
) -> Unit {
  let observed = standing_watch_observed_for_auto_triage(
    entry, execution, snapshot_path,
  )
  let decision = @standing_watch_policy.standing_watch_recovery_decision_from_execution(
    observed,
  )
  if @standing_watch_policy.standing_watch_autonomous_repair_still_open(
      goal, observed, decision,
    ) {
    complete_review_queued_standing_watch(
      state,
      observed,
      "repair_still_open",
      "book-quality repair produced only a generic empty completion, so the standing repair goal should retry autonomously instead of creating human review debt.",
      result_decision="repair-still-open",
      event_kind="event-watch-repair-still-open",
      event_detail="Mayor kept book-quality repair `\{observed.task_id}` in the autonomous standing-goal loop instead of leaving generic empty completion as human review debt.",
    )
    return
  }
  if @standing_watch_policy.standing_watch_empty_completion_is_no_change(
      goal, observed, decision,
    ) {
    complete_empty_standing_watch_as_no_change(state, observed)
    return
  }
  if decision == @core.WatcherDecisionKind::Deferred {
    complete_review_queued_standing_watch(
      state,
      observed,
      "deferred",
      "deferred standing-watch marker is operational retry accounting, not a durable review item.",
      result_decision="deferred",
      event_kind="event-watch-deferred",
      event_detail="Mayor closed deferred standing watch `\{observed.task_id}` as operational retry accounting, not keeper review.",
    )
    return
  }
  if !@standing_watch_policy.standing_watch_auto_triage_allowed(
      goal, observed, decision,
    ) {
    if observed != execution {
      state.replace_execution(observed)
    }
    return
  }
  let completed = copy_execution_with(
    observed,
    status=@core.TaskExecutionStatus::Completed,
    summary=@standing_watch_policy.standing_watch_auto_triage_summary(
      goal, observed, decision,
    ),
    heartbeat_tick=supervision_tick(state),
    next_retry_tick=None,
  )
  state.replace_execution(completed)
  state.replace_task(task_for_supervision(state, completed))
  sync_worker_from_execution(state, completed)
  state.record_event(
    @standing_watch_policy.standing_watch_execution_event(
      "event-watch-auto-triage",
      state.events.length(),
      completed,
      "Mayor auto-triaged standing watch `\{completed.task_id}` as \{decision.to_string()} using MoonBook keeper markers and goal threshold \{goal.quality_threshold}.",
    ),
  )
  let finalized = finalize_standing_watch_supervision_record(
    state, entry, completed, standing_goals, snapshot_path,
  )
  if finalized != completed {
    state.replace_execution(finalized)
    state.replace_task(task_for_supervision(state, finalized))
    sync_worker_from_execution(state, finalized)
  }
}
