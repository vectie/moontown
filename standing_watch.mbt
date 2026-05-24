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
  let execution_tick = supervision_tick(state)
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
        error =>
          failed_execution_record(
            entry,
            task,
            "Standing watch execution failed for \{entry.id} / \{task.id}: \{error}",
            assigned_worker_id=worker_id,
          )
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
  persist_execution_into_book(state, entry, observed_execution)
  collapse_standing_watch_book_history(entry, observed_execution)
  if terminal_execution_status(observed_execution.status) {
    finalize_goal_book_entry(state, entry, 0, [observed_execution.task_id])
  }
  let decision = standing_watch_decision_from_execution(observed_execution)
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
    delta_score=standing_watch_delta_score(observed_execution),
    new_source_count=standing_watch_new_source_count(observed_execution),
    detail=observed_execution.summary,
    task_id=Some(observed_execution.task_id),
    run_id=observed_execution.run_id,
    next_due_tick=updated.next_due_tick,
  )
  append_standing_watch_record(goal.id, ledger_dir, record)
  record_standing_watch_event(state, record)
  updated
}

///|
fn running_standing_watch_execution(
  entry : @moonbook.BookCatalogEntry,
  task : @moonbook.BookTask,
  worker_id : String,
  tick : Int,
) -> @core.TaskExecutionRecord {
  @core.TaskExecutionRecord::new(
    task_id=task.id,
    book_id=entry.id,
    packet_id="pending-\{entry.id}-\{task.id}",
    packet_path="",
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
    stale_after_tick=tick + 3,
    next_retry_tick=None,
    requires_review=task.requires_review,
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
  prompt
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
      marker_decision.unwrap_or(@core.WatcherDecisionKind::NeedsReview)
    @core.TaskExecutionStatus::Completed =>
      marker_decision.unwrap_or(@core.WatcherDecisionKind::NeedsReview)
    _ => @core.WatcherDecisionKind::Deferred
  }
}

///|
fn standing_watch_marker_decision(
  summary : String,
) -> @core.WatcherDecisionKind? {
  if standing_watch_summary_has_decision(summary, "failed") {
    Some(@core.WatcherDecisionKind::Failed)
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
    let line = raw.to_string()
    if line.has_prefix("### ") {
      if line.trim().to_string() == heading {
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
    let line = raw.to_string()
    if line.has_prefix("### ") {
      if current_id.has_prefix("provider-standing-watch-") {
        return standing_watch_summary_from_history_block(
          current_id, current_lines,
        )
      }
      let heading = line[4:].trim().to_string()
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
    let line = raw.to_string()
    if line.has_prefix("### ") {
      if saw_task && current_id != "" {
        match
          standing_watch_summary_from_history_block(current_id, current_lines) {
          Some(summary) => return Some(summary)
          None => ()
        }
      }
      let heading = line[4:].trim().to_string()
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
      let value = line[prefix.length():].trim().to_string()
      if value.has_suffix("`") {
        return Some(value[:value.length() - 1].to_string())
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
      let value = line[prefix.length():].trim().to_string()
      if !value.is_blank() {
        builder.write_string(value)
        wrote = true
      }
    } else if collecting {
      let value = line.trim().to_string()
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
    let line = raw.trim().to_string()
    let lower = line.to_lower()
    if lower.has_prefix(key_colon) {
      return Some(line[key_colon.length():].trim(chars=" `").to_string())
    } else if lower.has_prefix(key_equals) {
      return Some(line[key_equals.length():].trim(chars=" `").to_string())
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
    let line = raw.trim().to_string()
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
  let value = builder.to_string().trim(chars="-").to_string()
  if value.is_empty() {
    "standing-goal"
  } else {
    value
  }
}
