///|
async fn run_standing_goal_watch_cycle(
  state : @core.TownState,
  mayor : @roles.Mayor,
  catalog : Array[@moonbook.BookCatalogEntry],
  goal : @core.StandingGoal,
  tick : Int,
  snapshot_path : String,
) -> @core.StandingGoal {
  let target_book_id = goal.target_book_id.unwrap_or("mayor-selected-book")
  let ledger_dir = watcher_ledger_dir_for_snapshot(snapshot_path)
  let previous_records = @storage.load_watcher_run_records(
    goal.id,
    dir=ledger_dir,
  )
  let no_change_streak = @storage.consecutive_no_change_count(previous_records)
  if has_active_standing_watch_execution(state, goal.id) {
    let decision = @core.WatcherDecisionKind::Deferred
    let updated = goal.mark_watcher_decision(tick, decision)
    let record = @core.WatcherRunRecord::new(
      goal_id=goal.id,
      tick~,
      target_book_id~,
      decision~,
      detail="Mayor deferred standing goal because a previous watcher execution is still active.",
      next_due_tick=updated.next_due_tick,
    )
    append_standing_watch_record(goal.id, ledger_dir, record)
    record_standing_watch_event(state, record)
    return updated
  }
  let entry = match @moonbook.entry_for_book_id(catalog, target_book_id) {
    Some(entry) => entry
    None => {
      let decision = @core.WatcherDecisionKind::Failed
      let updated = goal.mark_watcher_decision(tick, decision)
      let record = @core.WatcherRunRecord::new(
        goal_id=goal.id,
        tick~,
        target_book_id~,
        decision~,
        detail="Mayor could not resolve target MoonBook `\{target_book_id}` for standing goal.",
        next_due_tick=updated.next_due_tick,
      )
      append_standing_watch_record(goal.id, ledger_dir, record)
      record_standing_watch_event(state, record)
      return updated
    }
  }
  register_demo_books(state, [entry.to_book_ref()])
  register_demo_workers(state)
  let task = standing_watch_task(goal, target_book_id, tick, no_change_streak)
  let planned_task = to_town_task(
    entry,
    task,
    @core.TaskExecutionStatus::PacketReady,
  )
  let route = mayor.decide_dispatch(state, planned_task)
  state.record_event(route_event(route.decision, state.events.length()))
  let worker_id = assigned_worker_id(route.decision)
  match route.decision {
    @dispatch.RouteDecision::Deferred(reason) => {
      let decision = @core.WatcherDecisionKind::Deferred
      let updated = goal.mark_watcher_decision(tick, decision)
      let record = @core.WatcherRunRecord::new(
        goal_id=goal.id,
        tick~,
        target_book_id~,
        decision~,
        detail="Mayor deferred standing goal because no watcher was currently eligible: \{reason}",
        task_id=Some(task.id),
        next_due_tick=updated.next_due_tick,
      )
      append_standing_watch_record(goal.id, ledger_dir, record)
      record_standing_watch_event(state, record)
      return updated
    }
    _ => ()
  }
  let execution_tick = tick
  publish_running_standing_watch_snapshot(
    state,
    entry,
    task,
    route.decision,
    worker_id,
    execution_tick,
    snapshot_path,
  )
  let execution = match route.decision {
    @dispatch.RouteDecision::Assigned(_) =>
      execute_goal_book_task(
        mayor,
        entry,
        task,
        assigned_worker_id=worker_id,
        tick=execution_tick,
      ) catch {
        error => {
          let detail = "Standing watch execution failed for \{entry.id} / \{task.id}: \{error}"
          if standing_watch_transient_dispatch_error(detail) {
            transient_deferred_standing_watch_execution_record(
              entry,
              task,
              detail,
              assigned_worker_id=worker_id,
              tick=execution_tick,
            )
          } else {
            failed_execution_record(
              entry,
              task,
              detail,
              assigned_worker_id=worker_id,
            )
          }
        }
      }
    _ =>
      failed_execution_record(
        entry,
        task,
        "Mayor could not dispatch standing watch task for \{entry.id}: \{route.rationale}",
      )
  }
  let final_execution = complete_wenyu_build_artifacts_if_needed(
    entry, task, execution,
  )
  state.replace_task(to_town_task(entry, task, final_execution.status))
  state.replace_execution(final_execution)
  sync_worker_from_execution(state, final_execution)
  state.record_event(
    execution_event(final_execution, state.executions.length() - 1),
  )
  let observed_execution = standing_watch_execution_with_book_decision(
    entry, final_execution,
  )
  if observed_execution != final_execution {
    state.replace_execution(observed_execution)
  }
  let reconciled_execution = match
    persist_execution_into_book(state, entry, observed_execution) {
    Some(outcome) =>
      execution_after_successful_book_persist(observed_execution, outcome, tick)
    None => observed_execution
  }
  let stabilized_execution = stabilize_deferred_standing_watch_execution(
    reconciled_execution, tick,
  )
  if stabilized_execution != observed_execution {
    state.replace_task(to_town_task(entry, task, stabilized_execution.status))
    state.replace_execution(stabilized_execution)
    sync_worker_from_execution(state, stabilized_execution)
  }
  collapse_standing_watch_book_history(entry, observed_execution)
  if terminal_execution_status(observed_execution.status) {
    finalize_goal_book_entry(state, entry, 0, [stabilized_execution.task_id])
  }
  let decision = standing_watch_decision_from_execution(stabilized_execution)
  let next_no_change_streak = if decision == @core.WatcherDecisionKind::NoChange {
    no_change_streak + 1
  } else {
    0
  }
  let updated = goal.mark_watcher_decision(
    tick,
    decision,
    no_change_streak=next_no_change_streak,
  )
  let record = @core.WatcherRunRecord::new(
    goal_id=goal.id,
    tick~,
    target_book_id~,
    decision~,
    delta_score=standing_watch_delta_score(stabilized_execution),
    new_source_count=standing_watch_new_source_count(stabilized_execution),
    detail=stabilized_execution.summary,
    task_id=Some(stabilized_execution.task_id),
    run_id=stabilized_execution.run_id,
    next_due_tick=updated.next_due_tick,
  )
  append_standing_watch_record(goal.id, ledger_dir, record)
  record_standing_watch_event(state, record)
  updated
}

///|
fn stabilize_deferred_standing_watch_execution(
  execution : @core.TaskExecutionRecord,
  tick : Int,
) -> @core.TaskExecutionRecord {
  let decision = standing_watch_recovery_decision_from_execution(execution)
  if decision == @core.WatcherDecisionKind::Deferred &&
    standing_watch_infrastructure_failure_summary(execution.summary) {
    copy_execution_with(
      execution,
      status=@core.TaskExecutionStatus::Completed,
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
    status=@core.TaskExecutionStatus::Running,
    summary="Mayor assigned \{task.id} for `\{task.title}`; MoonClaw watcher is searching and MoonBook will persist only useful deltas for `\{entry.id}`.",
    output_contract="standing-watch-live-snapshot",
    context_pages=task.target_pages,
    skill_paths=entry.skills,
    last_command=None,
    assigned_worker_id=Some(worker_id),
    attempt=1,
    heartbeat_tick=tick,
    stale_after_tick=tick + standing_watch_stale_window_ticks(),
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
    status=@core.TaskExecutionStatus::Completed,
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
fn standing_watch_transient_dispatch_error(detail : String) -> Bool {
  transient_external_dependency_error(detail)
}

///|
fn standing_watch_stale_window_ticks() -> Int {
  120
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
    (@dispatch.RouteDecision::Assigned(_), Some(worker_id)) => {
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
fn standing_watch_task(
  goal : @core.StandingGoal,
  target_book_id : String,
  tick : Int,
  no_change_streak : Int,
) -> @moonbook.BookTask {
  @moonbook.BookTask::new(
    id=standing_watch_task_id(goal.id, tick),
    goal=Some(goal.prompt),
    title="Standing watch: \{goal.title}",
    kind="standing-watch",
    prompt=standing_watch_prompt(goal, target_book_id, tick, no_change_streak),
    priority=95,
    requires_review=false,
    target_pages=[
      "wiki/history/journey.md", "wiki/sources/", "wiki/synthesis/overview.md", "raw/bootstrap/",
    ],
    required_role=Some(@core.WorkerRole::Watcher),
  )
}

///|
fn standing_watch_prompt(
  goal : @core.StandingGoal,
  target_book_id : String,
  tick : Int,
  no_change_streak : Int,
) -> String {
  let prompt =
    $|This is a MoonBook-owned 24/7 standing-watch cycle.
    $|
    $|Standing goal:
    $|- id: \{goal.id}
    $|- title: \{goal.title}
    $|- target_book_id: \{target_book_id}
    $|- source_policy: \{goal.source_policy}
    $|- quality_threshold: \{goal.quality_threshold}
    $|- daemon_tick: \{tick}
    $|- consecutive_no_change_before_this_check: \{no_change_streak}
    $|
    $|User intent:
    $|\{goal.prompt}
    $|
    $|Keeper responsibility:
    $|- MoonBook owns the baseline, source fingerprints, wiki memory, update threshold, digest history, and generated projection.
    $|- MoonClaw only performs bounded search/fetch/read/summarize work and returns candidate evidence.
    $|- Moontown only scheduled this check and will consume your final decision marker.
    $|
    $|Research temperament:
    $|- Use imagination to form better hypotheses and search angles, not to invent facts.
    $|- Use curiosity to ask what would surprise the current book, why this topic matters now, and which weak signals deserve a future pass.
    $|- Use judgement to reject noise, mirrors, stale material, inaccessible pages, and operational churn.
    $|- A truthful no-change digest is better than a fake update.
    $|
    $|Required workflow:
    $|1. Load the current book baseline before searching: wiki/sources, wiki/entities, wiki/concepts, wiki/synthesis, wiki/history, raw/bootstrap, and any latest digest.
    $|2. Search/fetch web sources first when the source policy is web-first. If web search is unavailable, record the tool blocker and use approved local/source hints only as fallback.
    $|3. Compare candidates against the existing baseline. Do not rewrite the wiki just because the standing goal is due.
    $|4. If the new evidence is meaningfully useful, add or revise durable MoonBook artifacts: source cards, claim/evidence notes, timeline/journey note, synthesis/digest, and generated-site projection inputs.
    $|5. If there is no meaningful new evidence, contradiction, advantage, risk, or synthesis value for this topic, write only a compact no-change observation in the book journey/review surface and do not inflate the wiki.
    $|6. If evidence is ambiguous or risky, queue review instead of silently accepting it.
    $|
    $|Required final marker in the result summary:
    $|standing_goal_decision: update | no_change | needs_review | failed
    $|delta_score: 0-100
    $|new_source_count: <integer>
    $|next_check_hint: normal | slower | faster | review
    $|checked_sources_count: <integer>
    $|new_sources_found: <integer>
    $|accepted_facts_count: <integer>
    $|rejected_facts_count: <integer>
    $|wiki_pages_changed_count: <integer>
    $|book_changed: yes | no
    $|
    $|Decision meaning:
    $|- update: useful new evidence was persisted or queued for durable memory.
    $|- no_change: checked sources did not beat the current baseline.
    $|- needs_review: likely useful, but requires keeper/human review.
    $|- failed: the check could not complete honestly.
    $|
    $|Strict accounting:
    $|- new_source_count counts newly useful accepted sources, not search results.
    $|- checked_sources_count counts sources actually opened/fetched/read enough to judge.
    $|- accepted_facts_count and wiki_pages_changed_count must be 0 for failed and ordinary no_change cycles.
    $|- book_changed is yes only when durable book knowledge changed or review was queued.
    $|- Generated site rebuilds, retries, history entries, and operational logs do not count as research progress.
  if standing_goal_is_book_quality_repair(goal) {
    "\{prompt}\n\{standing_watch_book_quality_repair_appendix()}"
  } else {
    prompt
  }
}

///|
fn standing_goal_is_book_quality_repair(goal : @core.StandingGoal) -> Bool {
  goal.id.has_prefix("book-quality-repair-")
}

///|
fn standing_watch_book_quality_repair_appendix() -> String {
  let appendix =
    $|
    $|Book-quality repair mode:
    $|- This standing goal is not a passive latest-news watch. It exists because a semantic MoonBook quality review found a concrete gap.
    $|- Read `wiki/reviews/book-quality-repair.md` and execute the named repair task before deciding.
    $|- If the repair queue names missing artifacts, create or revise those artifacts using the book's own SKILL.md, contracts, local source hints, approved web/source tools, and current workspace state.
    $|- If web search/fetch is unavailable, record that blocker but still use approved local/source hints and existing book context to make bounded progress when possible.
    $|- Do not return ordinary `no_change` merely because no fresh source was found while the repair queue still names missing artifacts.
    $|- Return `no_change` only when the required artifacts already exist, the named gap is already satisfied, or the review queue is stale and no longer applies.
    $|- Return `needs_review` when source authority, policy, privacy, or evidence uncertainty prevents autonomous promotion after useful repair work.
    $|- Return `update` when durable book artifacts, accepted evidence, or review-gated repair artifacts were created or revised.
    $|- Keep the repair book-local. Do not create v1/v2/v3/v4 alternate books.
  appendix
}

///|
fn standing_watch_task_id(goal_id : String, tick : Int) -> String {
  "standing-\{compact_watch_segment(goal_id)}-tick-\{tick}"
}

///|
fn has_active_standing_watch_execution(
  state : @core.TownState,
  goal_id : String,
) -> Bool {
  let prefix = "standing-\{compact_watch_segment(goal_id)}-"
  for execution in state.executions {
    if execution.task_id.has_prefix(prefix) &&
      (
        execution.status == @core.TaskExecutionStatus::ProposalImported ||
        execution.status == @core.TaskExecutionStatus::RunConfirmed ||
        execution.status == @core.TaskExecutionStatus::Running ||
        execution.status == @core.TaskExecutionStatus::AwaitingPersistence
      ) {
      return true
    }
  }
  false
}

///|
fn standing_watch_decision_from_execution(
  execution : @core.TaskExecutionRecord,
) -> @core.WatcherDecisionKind {
  let summary = execution.summary.to_lower()
  let marker_decision = standing_watch_marker_decision(summary)
  match execution.status {
    @core.TaskExecutionStatus::Failed | @core.TaskExecutionStatus::Stale =>
      @core.WatcherDecisionKind::Failed
    @core.TaskExecutionStatus::ReviewQueued =>
      standing_watch_review_or_marker_decision(execution, marker_decision)
    @core.TaskExecutionStatus::Completed =>
      standing_watch_review_or_marker_decision(execution, marker_decision)
    _ => @core.WatcherDecisionKind::Deferred
  }
}

///|
fn standing_watch_review_or_marker_decision(
  execution : @core.TaskExecutionRecord,
  marker_decision : @core.WatcherDecisionKind?,
) -> @core.WatcherDecisionKind {
  if marker_decision is None &&
    standing_watch_orphaned_running_failure_summary(execution.summary) {
    return @core.WatcherDecisionKind::Deferred
  }
  if standing_watch_operational_no_change_summary(execution.summary) {
    return @core.WatcherDecisionKind::NoChange
  }
  match marker_decision {
    Some(@core.WatcherDecisionKind::NeedsReview) =>
      if standing_watch_infrastructure_failure_summary(execution.summary) &&
        standing_watch_marker_int(execution.summary, "delta_score", fallback=0) ==
        0 &&
        standing_watch_marker_int(
          execution.summary,
          "new_source_count",
          fallback=0,
        ) ==
        0 {
        @core.WatcherDecisionKind::Failed
      } else {
        @core.WatcherDecisionKind::NeedsReview
      }
    Some(decision) => decision
    None => @core.WatcherDecisionKind::NeedsReview
  }
}

///|
fn standing_watch_operational_no_change_summary(summary : String) -> Bool {
  if standing_watch_orphaned_running_failure_summary(summary) {
    return false
  }
  let lowered = summary.to_lower()
  (
    lowered.contains("persisted_result_review: false") ||
    lowered.contains("keeper_auto_triage: persisted_non_review_result") ||
    lowered.contains("keeper_auto_triage: transient_infrastructure_contention")
  ) &&
  standing_watch_marker_int(summary, "delta_score", fallback=0) == 0 &&
  standing_watch_marker_int(summary, "new_source_count", fallback=0) == 0
}

///|
fn standing_watch_orphaned_running_failure_summary(summary : String) -> Bool {
  let lowered = summary.to_lower()
  (
    lowered.contains("indexed as running") &&
    lowered.contains("no live proposal process was found")
  ) ||
  lowered.contains("treating it as failed for mayor recovery")
}

///|
fn standing_watch_infrastructure_failure_summary(summary : String) -> Bool {
  let lowered = summary.to_lower()
  lowered.contains("standing watch execution failed") &&
  (
    transient_external_dependency_error(lowered) ||
    lowered.contains("runtime error: abort() called") ||
    lowered.contains("stringbuilder::grow_if_necessary") ||
    lowered.contains("systemstore::save_job_proposals")
  )
}

///|
fn watcher_record_effective_decision(
  record : @core.WatcherRunRecord,
) -> @core.WatcherDecisionKind {
  if standing_watch_orphaned_running_failure_summary(record.detail) &&
    record.delta_score == 0 &&
    record.new_source_count == 0 {
    return @core.WatcherDecisionKind::Deferred
  }
  if record.decision == @core.WatcherDecisionKind::Failed &&
    record.delta_score == 0 &&
    record.new_source_count == 0 &&
    standing_watch_detached_import_log_noise_summary(record.detail) {
    return @core.WatcherDecisionKind::Deferred
  }
  if record.decision == @core.WatcherDecisionKind::Failed &&
    record.delta_score == 0 &&
    record.new_source_count == 0 &&
    standing_watch_infrastructure_failure_summary(record.detail) &&
    transient_external_dependency_error(record.detail) {
    return @core.WatcherDecisionKind::Deferred
  }
  if record.decision != @core.WatcherDecisionKind::NeedsReview {
    return record.decision
  }
  if record.delta_score == 0 &&
    record.new_source_count == 0 &&
    standing_watch_operational_no_change_summary(record.detail) {
    return @core.WatcherDecisionKind::NoChange
  }
  if record.delta_score == 0 &&
    record.new_source_count == 0 &&
    standing_watch_infrastructure_failure_summary(record.detail) {
    return @core.WatcherDecisionKind::Failed
  }
  record.decision
}

///|
fn standing_watch_detached_import_log_noise_summary(detail : String) -> Bool {
  let lowered = detail.to_lower()
  let detached_import = lowered.contains("detached moonclaw import failed for")
  let startup_log = lowered.contains("\"tag\":\"model\"") ||
    lowered.contains("\"tag\":\"job-analysis\"") ||
    lowered.contains("loading skills from directory") ||
    lowered.contains("loaded skill")
  let terminal_signal = lowered.contains("failure(") ||
    lowered.contains(" failed:") ||
    lowered.contains("runtime error") ||
    lowered.contains("jsondecodeerror") ||
    lowered.contains("abort() called") ||
    lowered.contains("panic")
  detached_import && startup_log && !terminal_signal
}

///|
fn watcher_record_same_terminal_identity(
  left : @core.WatcherRunRecord,
  right : @core.WatcherRunRecord,
) -> Bool {
  left.goal_id == right.goal_id &&
  left.tick == right.tick &&
  left.task_id == right.task_id &&
  left.run_id == right.run_id
}

///|
fn watcher_record_observation_quality(record : @core.WatcherRunRecord) -> Int {
  if record.decision == @core.WatcherDecisionKind::Deferred {
    return 0
  }
  if record.detail.contains("standing_goal_decision:") ||
    record.detail.contains("standing_goal_decision=") ||
    record.detail.contains("book_watch_record_id:") {
    return 4
  }
  if record.decision == @core.WatcherDecisionKind::NeedsReview &&
    record.delta_score == 0 &&
    record.new_source_count == 0 &&
    record.detail.contains("Workflow completed") {
    return 1
  }
  if watcher_record_effective_decision(record) != record.decision {
    return 3
  }
  2
}

///|
fn watcher_record_prefer_candidate(
  current : @core.WatcherRunRecord,
  candidate : @core.WatcherRunRecord,
) -> Bool {
  if candidate.tick > current.tick {
    return true
  }
  if candidate.tick < current.tick {
    return false
  }
  if watcher_record_same_terminal_identity(current, candidate) {
    return watcher_record_observation_quality(candidate) >
      watcher_record_observation_quality(current)
  }
  true
}

///|
fn standing_watch_marker_decision(
  summary : String,
) -> @core.WatcherDecisionKind? {
  if standing_watch_summary_has_decision(summary, "failed") {
    Some(@core.WatcherDecisionKind::Failed)
  } else if standing_watch_summary_has_decision(summary, "deferred") {
    Some(@core.WatcherDecisionKind::Deferred)
  } else if standing_watch_summary_has_decision(summary, "no_change") {
    Some(@core.WatcherDecisionKind::NoChange)
  } else if standing_watch_summary_has_decision(summary, "needs_review") {
    Some(@core.WatcherDecisionKind::NeedsReview)
  } else if standing_watch_summary_has_decision(summary, "update") {
    Some(@core.WatcherDecisionKind::Update)
  } else {
    None
  }
}

///|
fn standing_watch_summary_has_decision(
  summary : String,
  value : String,
) -> Bool {
  summary.contains("standing_goal_decision: \{value}") ||
  summary.contains("standing_goal_decision=\{value}") ||
  summary.contains("decision: \{value}") ||
  summary.contains("decision=\{value}")
}

///|
fn standing_watch_delta_score(execution : @core.TaskExecutionRecord) -> Int {
  standing_watch_marker_int(
    execution.summary,
    "delta_score",
    fallback=if standing_watch_decision_from_execution(execution) ==
      @core.WatcherDecisionKind::Update {
      100
    } else {
      0
    },
  )
}

///|
fn standing_watch_new_source_count(
  execution : @core.TaskExecutionRecord,
) -> Int {
  standing_watch_marker_int(execution.summary, "new_source_count", fallback=0)
}

///|
async fn finalize_standing_watch_supervision_record(
  state : @core.TownState,
  entry : @moonbook.BookCatalogEntry,
  execution : @core.TaskExecutionRecord,
  standing_goals : Array[@core.StandingGoal],
  snapshot_path : String,
) -> @core.TaskExecutionRecord {
  let goal = match
    standing_goal_for_execution_task(standing_goals, execution.task_id) {
    Some(goal) => goal
    None => return execution
  }
  let observed = standing_watch_execution_with_book_decision(entry, execution)
  collapse_standing_watch_book_history(entry, observed)
  let decision = standing_watch_decision_from_execution(observed)
  if decision == @core.WatcherDecisionKind::Deferred {
    return observed
  }
  let tick = standing_watch_tick_for_goal_task(goal, observed.task_id).unwrap_or(
    supervision_tick(state),
  )
  let ledger_dir = watcher_ledger_dir_for_snapshot(snapshot_path)
  let previous_records = @storage.load_watcher_run_records(
    goal.id,
    dir=ledger_dir,
  )
  match terminal_watcher_record_for_execution(goal.id, ledger_dir, observed) {
    Some(record) =>
      if watcher_record_effective_decision(record) == decision {
        return observed
      }
    None => ()
  }
  if standing_watch_record_already_exists(
      previous_records,
      observed.task_id,
      observed.run_id,
      decision,
    ) {
    return observed
  }
  let no_change_streak = @storage.consecutive_no_change_count(previous_records)
  let next_no_change_streak = if decision == @core.WatcherDecisionKind::NoChange {
    no_change_streak + 1
  } else {
    0
  }
  let updated_goal = goal.mark_watcher_decision(
    tick,
    decision,
    no_change_streak=next_no_change_streak,
  )
  let record = @core.WatcherRunRecord::new(
    goal_id=goal.id,
    tick~,
    target_book_id=observed.book_id,
    decision~,
    delta_score=standing_watch_delta_score(observed),
    new_source_count=standing_watch_new_source_count(observed),
    detail=observed.summary,
    task_id=Some(observed.task_id),
    run_id=observed.run_id,
    next_due_tick=updated_goal.next_due_tick,
  )
  append_standing_watch_record(goal.id, ledger_dir, record)
  record_standing_watch_event(state, record)
  save_standing_goal_update_for_watcher(snapshot_path, updated_goal)
  observed
}

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
      standing_goal_for_execution_task(standing_goals, execution.task_id) {
      Some(goal) => goal
      None => continue
    }
    if standing_watch_review_superseded_by_newer_review(
        snapshot, standing_goals, goal, execution,
      ) {
      let completed = copy_execution_with(
        execution,
        status=@core.TaskExecutionStatus::Completed,
        summary="\{execution.summary}\nkeeper_auto_triage: superseded_review\nkeeper_auto_triage_reason: a newer standing-watch cycle already reached a terminal non-review state for the same standing goal, so this older review is historical accounting rather than active keeper debt.",
        heartbeat_tick=supervision_tick(state),
        next_retry_tick=None,
        result_decision="superseded-review",
        requires_review=false,
        notify_town=false,
      )
      state.replace_execution(completed)
      state.replace_task(task_for_supervision(state, completed))
      sync_worker_from_execution(state, completed)
      state.record_event(
        @core.TownEvent::new(
          id="event-watch-superseded-review-\{state.events.length()}-\{completed.task_id}",
          kind="standing-watch",
          detail="Mayor closed superseded review `\{completed.task_id}` because a newer terminal standing-watch cycle exists for `\{goal.id}`.",
          related_task_id=Some(completed.task_id),
          related_book_id=Some(completed.book_id),
          related_run_id=completed.run_id,
        ),
      )
      continue
    }
    let entry = match @moonbook.entry_for_book_id(catalog, execution.book_id) {
      Some(entry) => entry
      None => continue
    }
    if legacy_review_queued_retry_accounting_standing_watch(execution) {
      let completed = copy_execution_with(
        execution,
        status=@core.TaskExecutionStatus::Completed,
        summary="\{execution.summary}\nkeeper_auto_triage: deferred\nkeeper_auto_triage_reason: legacy review-queued standing-watch record was transient infrastructure retry accounting, not durable keeper review debt.",
        heartbeat_tick=supervision_tick(state),
        next_retry_tick=None,
        result_decision="deferred",
        requires_review=false,
        notify_town=false,
      )
      state.replace_execution(completed)
      state.replace_task(task_for_supervision(state, completed))
      sync_worker_from_execution(state, completed)
      state.record_event(
        @core.TownEvent::new(
          id="event-watch-legacy-review-reconcile-\{state.events.length()}-\{completed.task_id}",
          kind="standing-watch",
          detail="Mayor closed legacy review-queued standing watch `\{completed.task_id}` as deferred retry accounting.",
          related_task_id=Some(completed.task_id),
          related_book_id=Some(completed.book_id),
          related_run_id=completed.run_id,
        ),
      )
      continue
    }
    let observed = standing_watch_observed_for_auto_triage(
      entry, execution, snapshot_path,
    )
    let decision = standing_watch_recovery_decision_from_execution(observed)
    if standing_watch_autonomous_repair_still_open(goal, observed, decision) {
      let completed = copy_execution_with(
        observed,
        status=@core.TaskExecutionStatus::Completed,
        summary="\{observed.summary}\nkeeper_auto_triage: repair_still_open\nkeeper_auto_triage_reason: book-quality repair produced only a generic empty completion, so the standing repair goal should retry autonomously instead of creating human review debt.",
        heartbeat_tick=supervision_tick(state),
        next_retry_tick=None,
        result_decision="repair-still-open",
        requires_review=false,
        notify_town=false,
      )
      state.replace_execution(completed)
      state.replace_task(task_for_supervision(state, completed))
      sync_worker_from_execution(state, completed)
      state.record_event(
        @core.TownEvent::new(
          id="event-watch-repair-still-open-\{state.events.length()}-\{completed.task_id}",
          kind="standing-watch",
          detail="Mayor kept book-quality repair `\{completed.task_id}` in the autonomous standing-goal loop instead of leaving generic empty completion as human review debt.",
          related_task_id=Some(completed.task_id),
          related_book_id=Some(completed.book_id),
          related_run_id=completed.run_id,
        ),
      )
      continue
    }
    if standing_watch_empty_completion_is_no_change(goal, observed, decision) {
      let completed = copy_execution_with(
        observed,
        status=@core.TaskExecutionStatus::Completed,
        summary="\{observed.summary}\nkeeper_auto_triage: empty_completion_no_change\nkeeper_auto_triage_reason: watcher completed without a standing-goal decision marker, candidate insight, evidence delta, or source delta, so mayor treats it as no_change instead of human review debt.\nstanding_goal_decision: no_change\ndelta_score: 0\nnew_source_count: 0\nbook_changed: no",
        heartbeat_tick=supervision_tick(state),
        next_retry_tick=None,
        result_decision="NoChange",
        requires_review=false,
        notify_town=false,
      )
      state.replace_execution(completed)
      state.replace_task(task_for_supervision(state, completed))
      sync_worker_from_execution(state, completed)
      state.record_event(
        @core.TownEvent::new(
          id="event-watch-empty-no-change-\{state.events.length()}-\{completed.task_id}",
          kind="standing-watch",
          detail="Mayor closed empty standing-watch completion `\{completed.task_id}` as no_change rather than human review debt.",
          related_task_id=Some(completed.task_id),
          related_book_id=Some(completed.book_id),
          related_run_id=completed.run_id,
        ),
      )
      continue
    }
    if decision == @core.WatcherDecisionKind::Deferred {
      let completed = copy_execution_with(
        observed,
        status=@core.TaskExecutionStatus::Completed,
        summary="\{observed.summary}\nkeeper_auto_triage: deferred\nkeeper_auto_triage_reason: deferred standing-watch marker is operational retry accounting, not a durable review item.",
        heartbeat_tick=supervision_tick(state),
        next_retry_tick=None,
        result_decision="deferred",
        requires_review=false,
        notify_town=false,
      )
      state.replace_execution(completed)
      state.replace_task(task_for_supervision(state, completed))
      sync_worker_from_execution(state, completed)
      state.record_event(
        @core.TownEvent::new(
          id="event-watch-deferred-\{state.events.length()}-\{completed.task_id}",
          kind="standing-watch",
          detail="Mayor closed deferred standing watch `\{completed.task_id}` as operational retry accounting, not keeper review.",
          related_task_id=Some(completed.task_id),
          related_book_id=Some(completed.book_id),
          related_run_id=completed.run_id,
        ),
      )
      continue
    }
    if !standing_watch_auto_triage_allowed(goal, observed, decision) {
      if observed != execution {
        state.replace_execution(observed)
      }
      continue
    }
    let completed = copy_execution_with(
      observed,
      status=@core.TaskExecutionStatus::Completed,
      summary=standing_watch_auto_triage_summary(goal, observed, decision),
      heartbeat_tick=supervision_tick(state),
      next_retry_tick=None,
    )
    state.replace_execution(completed)
    state.replace_task(task_for_supervision(state, completed))
    sync_worker_from_execution(state, completed)
    state.record_event(
      @core.TownEvent::new(
        id="event-watch-auto-triage-\{state.events.length()}-\{completed.task_id}",
        kind="standing-watch",
        detail="Mayor auto-triaged standing watch `\{completed.task_id}` as \{decision.to_string()} using MoonBook keeper markers and goal threshold \{goal.quality_threshold}.",
        related_task_id=Some(completed.task_id),
        related_book_id=Some(completed.book_id),
        related_run_id=completed.run_id,
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
}

///|
fn standing_watch_empty_completion_is_no_change(
  goal : @core.StandingGoal,
  execution : @core.TaskExecutionRecord,
  decision : @core.WatcherDecisionKind,
) -> Bool {
  !goal.id.has_prefix("book-quality-repair-") &&
  decision == @core.WatcherDecisionKind::NeedsReview &&
  standing_watch_delta_score(execution) == 0 &&
  standing_watch_new_source_count(execution) == 0 &&
  standing_watch_generic_empty_repair_review_summary(execution.summary)
}

///|
fn standing_watch_autonomous_repair_still_open(
  goal : @core.StandingGoal,
  execution : @core.TaskExecutionRecord,
  decision : @core.WatcherDecisionKind,
) -> Bool {
  goal.id.has_prefix("book-quality-repair-") &&
  decision == @core.WatcherDecisionKind::NeedsReview &&
  standing_watch_delta_score(execution) == 0 &&
  standing_watch_new_source_count(execution) == 0 &&
  standing_watch_generic_empty_repair_review_summary(execution.summary)
}

///|
fn standing_watch_generic_empty_repair_review_summary(summary : String) -> Bool {
  let lowered = summary.to_lower()
  let generic_completion = lowered.contains("inline run finished") ||
    lowered.contains("workflow completed")
  generic_completion &&
  !lowered.contains("standing_goal_decision") &&
  !lowered.contains("candidate insight") &&
  !lowered.contains("pending_review") &&
  !lowered.contains("book_watch_record_id")
}

///|
fn standing_watch_review_superseded_by_newer_review(
  executions : Array[@core.TaskExecutionRecord],
  standing_goals : Array[@core.StandingGoal],
  goal : @core.StandingGoal,
  execution : @core.TaskExecutionRecord,
) -> Bool {
  let current_tick = match
    standing_watch_tick_for_goal_task(goal, execution.task_id) {
    Some(tick) => tick
    None => return false
  }
  for candidate in executions {
    if candidate.task_id == execution.task_id {
      continue
    }
    match standing_goal_for_execution_task(standing_goals, candidate.task_id) {
      Some(candidate_goal) => if candidate_goal.id != goal.id { continue }
      None => continue
    }
    match standing_watch_tick_for_goal_task(goal, candidate.task_id) {
      Some(candidate_tick) if candidate_tick > current_tick =>
        if standing_watch_cycle_supersedes_review(candidate) {
          return true
        }
      _ => ()
    }
  }
  false
}

///|
fn standing_watch_cycle_supersedes_review(
  execution : @core.TaskExecutionRecord,
) -> Bool {
  match execution.status {
    @core.TaskExecutionStatus::ReviewQueued => true
    @core.TaskExecutionStatus::Completed => {
      let decision = standing_watch_decision_from_execution(execution)
      decision == @core.WatcherDecisionKind::NoChange ||
      decision == @core.WatcherDecisionKind::Update ||
      decision == @core.WatcherDecisionKind::Deferred
    }
    _ => false
  }
}

///|
async fn reconcile_persisted_standing_watch_records(
  state : @core.TownState,
  snapshot_path : String,
  standing_goals : Array[@core.StandingGoal],
) -> Unit {
  let ledger_dir = watcher_ledger_dir_for_snapshot(snapshot_path)
  let snapshot = state.executions.copy()
  for execution in snapshot {
    let goal = match
      standing_goal_for_execution_task(standing_goals, execution.task_id) {
      Some(goal) => goal
      None => continue
    }
    match
      terminal_watcher_record_for_execution(goal.id, ledger_dir, execution) {
      Some(record) => {
        if watcher_record_effective_decision(record) ==
          @core.WatcherDecisionKind::NeedsReview &&
          standing_watch_review_superseded_by_newer_review(
            snapshot, standing_goals, goal, execution,
          ) {
          continue
        }
        let status = task_status_for_terminal_watcher_decision(record.decision)
        let reconciled = copy_execution_with(
          execution,
          status~,
          summary="\{record.detail}\nkeeper_auto_triage: reconciled_from_watcher_ledger\nreconciled_watcher_decision: \{record.decision.to_string()}",
          heartbeat_tick=supervision_tick(state),
          next_retry_tick=None,
          result_decision=record.decision.to_string(),
          requires_review=record.decision ==
            @core.WatcherDecisionKind::NeedsReview,
        )
        state.replace_execution(reconciled)
        state.replace_task(task_for_supervision(state, reconciled))
        sync_worker_from_execution(state, reconciled)
        state.record_event(
          @core.TownEvent::new(
            id="event-watch-ledger-reconcile-\{state.events.length()}-\{reconciled.task_id}",
            kind="standing-watch",
            detail="Mayor reconciled `\{reconciled.task_id}` from the persisted watcher ledger as \{record.decision.to_string()}.",
            related_task_id=Some(reconciled.task_id),
            related_book_id=Some(reconciled.book_id),
            related_run_id=reconciled.run_id,
          ),
        )
      }
      None => ()
    }
  }
}

///|
async fn terminal_watcher_record_for_execution(
  goal_id : String,
  ledger_dir : String,
  execution : @core.TaskExecutionRecord,
) -> @core.WatcherRunRecord? {
  let records = @storage.load_watcher_run_records(goal_id, dir=ledger_dir)
  let mut found : @core.WatcherRunRecord? = None
  for record in records {
    if record.task_id == Some(execution.task_id) &&
      watcher_record_run_matches_execution(record, execution) &&
      record.decision != @core.WatcherDecisionKind::Deferred {
      found = Some(record)
    }
  }
  found
}

///|
fn watcher_record_run_matches_execution(
  record : @core.WatcherRunRecord,
  execution : @core.TaskExecutionRecord,
) -> Bool {
  match execution.run_id {
    Some(run_id) => record.run_id == Some(run_id)
    None => true
  }
}

///|
fn task_status_for_terminal_watcher_decision(
  decision : @core.WatcherDecisionKind,
) -> @core.TaskExecutionStatus {
  match decision {
    @core.WatcherDecisionKind::NeedsReview =>
      @core.TaskExecutionStatus::ReviewQueued
    @core.WatcherDecisionKind::Failed => @core.TaskExecutionStatus::Failed
    _ => @core.TaskExecutionStatus::Completed
  }
}

///|
async fn reconcile_failed_standing_watch_outputs(
  state : @core.TownState,
  catalog : Array[@moonbook.BookCatalogEntry],
  snapshot_path : String,
  standing_goals : Array[@core.StandingGoal],
) -> Unit {
  let snapshot = state.executions.copy()
  for execution in snapshot {
    if execution.status != @core.TaskExecutionStatus::Failed &&
      execution.status != @core.TaskExecutionStatus::Stale {
      continue
    }
    let goal = match
      standing_goal_for_execution_task(standing_goals, execution.task_id) {
      Some(goal) => goal
      None => continue
    }
    let entry = match @moonbook.entry_for_book_id(catalog, execution.book_id) {
      Some(entry) => entry
      None => continue
    }
    if legacy_tick_domain_stale_standing_watch(execution) {
      let completed = copy_execution_with(
        execution,
        status=@core.TaskExecutionStatus::Completed,
        summary="\{execution.summary}\nkeeper_auto_triage: deferred\nkeeper_auto_triage_reason: legacy prelaunch standing-watch heartbeat used an event-count tick while the task id used the daemon tick; mayor closed it as retry accounting.",
        heartbeat_tick=supervision_tick(state),
        next_retry_tick=None,
        result_decision="deferred",
        requires_review=false,
        notify_town=false,
      )
      state.replace_execution(completed)
      state.replace_task(task_for_supervision(state, completed))
      sync_worker_from_execution(state, completed)
      state.record_event(
        @core.TownEvent::new(
          id="event-watch-legacy-tick-reconcile-\{state.events.length()}-\{completed.task_id}",
          kind="standing-watch",
          detail="Mayor closed legacy tick-domain standing watch `\{completed.task_id}` as deferred retry accounting.",
          related_task_id=Some(completed.task_id),
          related_book_id=Some(completed.book_id),
          related_run_id=completed.run_id,
        ),
      )
      continue
    }
    let observed = standing_watch_observed_for_auto_triage(
      entry, execution, snapshot_path,
    )
    let decision = standing_watch_recovery_decision_from_execution(observed)
    if !standing_watch_recovery_allowed(goal, observed, decision) {
      if observed != execution {
        state.replace_execution(observed)
      }
      continue
    }
    let completed = copy_execution_with(
      observed,
      status=@core.TaskExecutionStatus::Completed,
      summary=standing_watch_recovery_summary(goal, observed, decision),
      heartbeat_tick=supervision_tick(state),
      next_retry_tick=None,
    )
    state.replace_execution(completed)
    state.replace_task(task_for_supervision(state, completed))
    sync_worker_from_execution(state, completed)
    state.record_event(
      @core.TownEvent::new(
        id="event-watch-auto-recovery-\{state.events.length()}-\{completed.task_id}",
        kind="standing-watch",
        detail="Mayor recovered failed standing watch `\{completed.task_id}` as \{decision.to_string()} because MoonBook persisted a terminal keeper marker.",
        related_task_id=Some(completed.task_id),
        related_book_id=Some(completed.book_id),
        related_run_id=completed.run_id,
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
}

///|
fn legacy_tick_domain_stale_standing_watch(
  execution : @core.TaskExecutionRecord,
) -> Bool {
  execution.status == @core.TaskExecutionStatus::Stale &&
  execution.run_id is None &&
  execution.output_contract == "standing-watch-live-snapshot" &&
  execution.summary.contains("missed its heartbeat window") &&
  tick_from_task_id(execution.task_id) > execution.stale_after_tick
}

///|
fn legacy_review_queued_retry_accounting_standing_watch(
  execution : @core.TaskExecutionRecord,
) -> Bool {
  if execution.status != @core.TaskExecutionStatus::ReviewQueued {
    return false
  }
  if !standing_watch_infrastructure_failure_summary(execution.summary) {
    return false
  }
  let task_tick = tick_from_task_id(execution.task_id)
  task_tick > execution.stale_after_tick ||
  standing_watch_recovery_decision_from_execution(execution) ==
  @core.WatcherDecisionKind::Deferred ||
  (
    standing_watch_recovery_decision_from_execution(execution) ==
    @core.WatcherDecisionKind::Failed &&
    standing_watch_delta_score(execution) == 0 &&
    standing_watch_new_source_count(execution) == 0
  )
}

///|
async fn standing_watch_observed_for_auto_triage(
  entry : @moonbook.BookCatalogEntry,
  execution : @core.TaskExecutionRecord,
  snapshot_path : String,
) -> @core.TaskExecutionRecord {
  let observed = standing_watch_execution_with_book_decision(entry, execution)
  let decision = standing_watch_decision_from_execution(observed)
  if decision != @core.WatcherDecisionKind::NeedsReview {
    return observed
  }
  match
    standing_watch_no_change_summary_from_book_result(snapshot_path, execution) {
    Some(summary) =>
      copy_execution_with(observed, summary="\{observed.summary}\n\{summary}")
    None => observed
  }
}

///|
async fn standing_watch_no_change_summary_from_book_result(
  snapshot_path : String,
  execution : @core.TaskExecutionRecord,
) -> String? {
  let path = standing_watch_book_result_path(snapshot_path, execution.task_id)
  if !@fs.exists(path) {
    return None
  }
  let parsed = @json.parse(@fs.read_file(path).text()) catch {
    _ => return None
  }
  let result : @moonbook.BookResult = @json.from_json(parsed) catch {
    _ => return None
  }
  if result.requires_review || !result.memory_candidates.is_empty() {
    return None
  }
  if standing_watch_marker_decision(result.summary.to_lower()) != None {
    return None
  }
  if !result.summary.contains("Workflow completed") {
    return None
  }
  Some(
    "standing_goal_decision: no_change\ndelta_score: 0\nnew_source_count: 0\nnext_check_hint: normal\nchecked_sources_count: 0\nnew_sources_found: 0\naccepted_facts_count: 0\nrejected_facts_count: 0\nwiki_pages_changed_count: 0\nbook_changed: no\nbook_watch_record_id: \{execution.task_id}\nMoonBook result was an empty, non-review operational completion; mayor classified it as no_change so it does not block live autonomy.",
  )
}

///|
fn standing_watch_book_result_path(
  snapshot_path : String,
  task_id : String,
) -> String {
  let base = @path.Path::dirname(snapshot_path).to_string()
  let root = if base == "." || base == "" { ".moontown" } else { base }
  "\{root}/book-results/\{task_id}.json"
}

///|
fn standing_watch_auto_triage_allowed(
  goal : @core.StandingGoal,
  execution : @core.TaskExecutionRecord,
  decision : @core.WatcherDecisionKind,
) -> Bool {
  match decision {
    @core.WatcherDecisionKind::NoChange => true
    @core.WatcherDecisionKind::Update =>
      standing_watch_delta_score(execution) >= goal.quality_threshold
    _ => false
  }
}

///|
fn standing_watch_auto_triage_summary(
  goal : @core.StandingGoal,
  execution : @core.TaskExecutionRecord,
  decision : @core.WatcherDecisionKind,
) -> String {
  "\{execution.summary}\nkeeper_auto_triage: accepted\nauto_triage_decision: \{decision.to_string()}\nauto_triage_threshold: \{goal.quality_threshold}\nauto_triage_reason: MoonBook standing-watch marker was sufficient for keeper-level autonomous closure."
}

///|
fn standing_watch_recovery_allowed(
  goal : @core.StandingGoal,
  execution : @core.TaskExecutionRecord,
  decision : @core.WatcherDecisionKind,
) -> Bool {
  if decision == @core.WatcherDecisionKind::NoChange {
    return true
  }
  decision == @core.WatcherDecisionKind::Update &&
  standing_watch_delta_score(execution) >= goal.quality_threshold
}

///|
fn standing_watch_recovery_decision_from_execution(
  execution : @core.TaskExecutionRecord,
) -> @core.WatcherDecisionKind {
  standing_watch_marker_decision(execution.summary.to_lower()).unwrap_or(
    standing_watch_decision_from_execution(execution),
  )
}

///|
fn standing_watch_recovery_summary(
  goal : @core.StandingGoal,
  execution : @core.TaskExecutionRecord,
  decision : @core.WatcherDecisionKind,
) -> String {
  "\{execution.summary}\nkeeper_auto_recovery: accepted\nauto_recovery_decision: \{decision.to_string()}\nauto_recovery_threshold: \{goal.quality_threshold}\nauto_recovery_reason: Failed transport/index status was superseded by a terminal MoonBook standing-watch marker, so mayor closed it without operator intervention."
}

///|
fn standing_goal_for_execution_task(
  goals : Array[@core.StandingGoal],
  task_id : String,
) -> @core.StandingGoal? {
  for goal in goals {
    match standing_watch_tick_for_goal_task(goal, task_id) {
      Some(_) => return Some(goal)
      None => ()
    }
  }
  None
}

///|
fn standing_watch_tick_for_goal_task(
  goal : @core.StandingGoal,
  task_id : String,
) -> Int? {
  let prefix = "standing-\{compact_watch_segment(goal.id)}-tick-"
  if task_id.has_prefix(prefix) {
    first_non_negative_int(task_id[prefix.length():].to_owned())
  } else {
    None
  }
}

///|
fn standing_watch_record_already_exists(
  records : Array[@core.WatcherRunRecord],
  task_id : String,
  run_id : String?,
  decision : @core.WatcherDecisionKind,
) -> Bool {
  for record in records {
    if record.task_id == Some(task_id) &&
      record.run_id == run_id &&
      record.decision == decision {
      return true
    }
  }
  false
}

///|
async fn save_standing_goal_update_for_watcher(
  snapshot_path : String,
  updated_goal : @core.StandingGoal,
) -> Unit {
  let path = default_standing_goal_state_path(snapshot_path)
  let goals = @storage.load_or_create_standing_goals(path~)
  let updated : Array[@core.StandingGoal] = []
  let mut replaced = false
  for goal in goals {
    if goal.id == updated_goal.id {
      updated.push(updated_goal)
      replaced = true
    } else {
      updated.push(goal)
    }
  }
  if !replaced {
    updated.push(updated_goal)
  }
  @storage.save_standing_goals_file(path, updated)
}

///|
async fn standing_watch_execution_with_book_decision(
  entry : @moonbook.BookCatalogEntry,
  execution : @core.TaskExecutionRecord,
) -> @core.TaskExecutionRecord {
  match standing_watch_book_decision_summary(entry, execution.task_id) {
    Some(summary) =>
      copy_execution_with(execution, summary="\{execution.summary}\n\{summary}")
    None => execution
  }
}

///|
async fn standing_watch_book_decision_summary(
  entry : @moonbook.BookCatalogEntry,
  task_id : String,
) -> String? {
  let root = @moonbook.workspace_root(entry)
  let history = read_text_or_empty("\{root}/wiki/history/standing-watch.md")
  if history.trim().is_blank() {
    None
  } else {
    match standing_watch_history_decision_summary_for_task(history, task_id) {
      Some(summary) => Some(summary)
      None => standing_watch_latest_provider_decision_summary(history)
    }
  }
}

///|
async fn collapse_standing_watch_book_history(
  entry : @moonbook.BookCatalogEntry,
  execution : @core.TaskExecutionRecord,
) -> Unit {
  let provider_id = standing_watch_marker_value(
    execution.summary,
    "book_watch_record_id",
  ).unwrap_or("")
  if provider_id.is_empty() {
    return
  }
  let root = @moonbook.workspace_root(entry)
  let path = "\{root}/wiki/history/standing-watch.md"
  let history = read_text_or_empty(path)
  if history.trim().is_blank() {
    return
  }
  let collapsed = remove_standing_watch_history_block(history, provider_id)
  if collapsed != history {
    write_text_file(path, collapsed)
  }
}

///|
fn remove_standing_watch_history_block(
  history : String,
  block_id : String,
) -> String {
  let heading = "### \{block_id}"
  let builder = StringBuilder::new()
  let mut skipping = false
  let mut removed = false
  for raw in history.split("\n") {
    let line = raw.to_owned()
    if line.has_prefix("### ") {
      if line.trim().to_owned() == heading {
        skipping = true
        removed = true
        continue
      }
      skipping = false
    }
    if !skipping {
      builder.write_string(line)
      builder.write_char('\n')
    }
  }
  if removed {
    builder.to_string()
  } else {
    history
  }
}

///|
fn standing_watch_latest_provider_decision_summary(history : String) -> String? {
  let mut current_id = ""
  let current_lines : Array[String] = []
  for raw in history.split("\n") {
    let line = raw.to_owned()
    if line.has_prefix("### ") {
      if current_id.has_prefix("provider-standing-watch-") {
        return standing_watch_summary_from_history_block(
          current_id, current_lines,
        )
      }
      let heading = line[4:].trim().to_owned()
      current_id = heading
      current_lines.clear()
    } else if current_id != "" {
      current_lines.push(line)
    }
  }
  if current_id.has_prefix("provider-standing-watch-") {
    standing_watch_summary_from_history_block(current_id, current_lines)
  } else {
    None
  }
}

///|
fn standing_watch_history_decision_summary_for_task(
  history : String,
  task_id : String,
) -> String? {
  let mut saw_task = false
  let mut current_id = ""
  let current_lines : Array[String] = []
  for raw in history.split("\n") {
    let line = raw.to_owned()
    if line.has_prefix("### ") {
      if saw_task && current_id != "" {
        match
          standing_watch_summary_from_history_block(current_id, current_lines) {
          Some(summary) => return Some(summary)
          None => ()
        }
      }
      let heading = line[4:].trim().to_owned()
      if saw_task && heading.has_prefix("standing-watch-") && heading != task_id {
        return None
      }
      if heading == task_id || saw_task {
        saw_task = true
        current_id = heading
        current_lines.clear()
      }
    } else if saw_task && current_id != "" {
      current_lines.push(line)
    }
  }
  if saw_task && current_id != "" {
    standing_watch_summary_from_history_block(current_id, current_lines)
  } else {
    None
  }
}

///|
fn standing_watch_summary_from_history_block(
  block_id : String,
  lines : Array[String],
) -> String? {
  let summary_text = standing_watch_history_summary_text(lines)
  let decision = standing_watch_history_field(lines, "- Decision: `").unwrap_or(
    "unknown",
  )
  if decision == "unknown" || decision.trim().is_blank() {
    return None
  }
  let delta_score = standing_watch_history_field(lines, "- Delta score: `").unwrap_or(
    "0",
  )
  let new_source_count = standing_watch_history_field(
    lines, "- New source count: `",
  ).unwrap_or("0")
  let next_check_hint = standing_watch_history_field(
    lines, "- Next check hint: `",
  ).unwrap_or("normal")
  let checked_sources_count = standing_watch_history_field(
    lines, "- Checked sources count: `",
  ).unwrap_or(
    standing_watch_marker_int(summary_text, "checked_sources_count", fallback=0).to_string(),
  )
  let new_sources_found = standing_watch_history_field(
    lines, "- New sources found: `",
  ).unwrap_or(
    standing_watch_marker_int(
      summary_text,
      "new_sources_found",
      fallback=first_non_negative_int(new_source_count).unwrap_or(0),
    ).to_string(),
  )
  let accepted_facts_count = standing_watch_history_field(
    lines, "- Accepted facts count: `",
  ).unwrap_or(
    standing_watch_marker_int(
      summary_text,
      "accepted_facts_count",
      fallback=if decision == "update" { 1 } else { 0 },
    ).to_string(),
  )
  let rejected_facts_count = standing_watch_history_field(
    lines, "- Rejected facts count: `",
  ).unwrap_or(
    standing_watch_marker_int(summary_text, "rejected_facts_count", fallback=0).to_string(),
  )
  let wiki_pages_changed_count = standing_watch_history_field(
    lines, "- Wiki pages changed count: `",
  ).unwrap_or(
    standing_watch_marker_int(
      summary_text,
      "wiki_pages_changed_count",
      fallback=if decision == "update" || decision == "needs_review" {
        1
      } else {
        0
      },
    ).to_string(),
  )
  let book_changed = standing_watch_history_field(lines, "- Book changed: `").unwrap_or(
    standing_watch_marker_value(summary_text, "book_changed").unwrap_or(
      if decision == "update" || decision == "needs_review" {
        "yes"
      } else {
        "no"
      },
    ),
  )
  let summary = if summary_text.is_blank() {
    "MoonBook recorded a standing-watch decision."
  } else {
    summary_text
  }
  Some(
    "standing_goal_decision: \{decision}\ndelta_score: \{delta_score}\nnew_source_count: \{new_source_count}\nnext_check_hint: \{next_check_hint}\nchecked_sources_count: \{checked_sources_count}\nnew_sources_found: \{new_sources_found}\naccepted_facts_count: \{accepted_facts_count}\nrejected_facts_count: \{rejected_facts_count}\nwiki_pages_changed_count: \{wiki_pages_changed_count}\nbook_changed: \{book_changed}\nbook_watch_record_id: \{block_id}\n\{summary}",
  )
}

///|
fn standing_watch_history_field(
  lines : Array[String],
  prefix : String,
) -> String? {
  for line in lines {
    if line.has_prefix(prefix) {
      let value = line[prefix.length():].trim().to_owned()
      if value.has_suffix("`") {
        return Some(value[:value.length() - 1].to_owned())
      }
      return Some(value)
    }
  }
  None
}

///|
fn standing_watch_history_summary_text(lines : Array[String]) -> String {
  let prefix = "- Summary: "
  let builder = StringBuilder::new()
  let mut collecting = false
  let mut wrote = false
  for line in lines {
    if line.has_prefix(prefix) {
      collecting = true
      let value = line[prefix.length():].trim().to_owned()
      if !value.is_blank() {
        builder.write_string(value)
        wrote = true
      }
    } else if collecting {
      let value = line.trim().to_owned()
      if value.is_blank() || line.has_prefix("- ") {
        break
      }
      if wrote {
        builder.write_char('\n')
      }
      builder.write_string(value)
      wrote = true
    }
  }
  builder.to_string()
}

///|
fn standing_watch_marker_value(summary : String, key : String) -> String? {
  let key_colon = "\{key}:"
  let key_equals = "\{key}="
  for raw in summary.split("\n") {
    let line = raw.trim().to_owned()
    let lower = line.to_lower()
    if lower.has_prefix(key_colon) {
      return Some(line[key_colon.length():].trim(chars=" `").to_owned())
    } else if lower.has_prefix(key_equals) {
      return Some(line[key_equals.length():].trim(chars=" `").to_owned())
    }
  }
  None
}

///|
fn standing_watch_marker_int(
  summary : String,
  key : String,
  fallback~ : Int,
) -> Int {
  let key_colon = "\{key}:"
  let key_equals = "\{key}="
  for raw in summary.to_lower().split("\n") {
    let line = raw.trim().to_owned()
    if line.has_prefix(key_colon) || line.has_prefix(key_equals) {
      match first_non_negative_int(line) {
        Some(value) => return value
        None => return fallback
      }
    }
  }
  fallback
}

///|
fn first_non_negative_int(text : String) -> Int? {
  let mut seen = false
  let mut value = 0
  for char in text {
    if char >= '0' && char <= '9' {
      value = value * 10 + (char.to_int() - '0'.to_int())
      seen = true
    } else if seen {
      return Some(value)
    }
  }
  if seen {
    Some(value)
  } else {
    None
  }
}

///|
async fn append_standing_watch_record(
  goal_id : String,
  ledger_dir : String,
  record : @core.WatcherRunRecord,
) -> Unit {
  @storage.append_watcher_run_record_file(
    @storage.watcher_ledger_path(goal_id, dir=ledger_dir),
    record,
  )
}

///|
fn record_standing_watch_event(
  state : @core.TownState,
  record : @core.WatcherRunRecord,
) -> Unit {
  state.record_event(
    @core.TownEvent::new(
      id="event-watch-\{record.tick}-\{record.goal_id}",
      kind="standing-watch",
      detail="Standing watch \{record.goal_id} -> \{record.decision.to_string()} for \{record.target_book_id}; next_due_tick=\{record.next_due_tick}; \{record.detail}",
      related_book_id=Some(record.target_book_id),
      related_task_id=record.task_id,
      related_run_id=record.run_id,
    ),
  )
}

///|
fn watcher_ledger_dir_for_snapshot(snapshot_path : String) -> String {
  let base = @path.Path::dirname(snapshot_path).to_string()
  if base == "." || base == "" {
    @storage.default_watcher_ledger_dir()
  } else {
    "\{base}/watchers"
  }
}

///|
fn compact_watch_segment(text : String) -> String {
  let builder = StringBuilder::new()
  let mut emitted = 0
  let mut last_dash = false
  for char in text.to_lower() {
    if (char >= 'a' && char <= 'z') || (char >= '0' && char <= '9') {
      if emitted >= 48 {
        break
      }
      builder.write_char(char)
      emitted += 1
      last_dash = false
    } else if !last_dash && emitted > 0 {
      if emitted >= 48 {
        break
      }
      builder.write_char('-')
      emitted += 1
      last_dash = true
    }
  }
  let value = builder.to_string().trim(chars="-").to_owned()
  if value.is_empty() {
    "standing-goal"
  } else {
    value
  }
}
