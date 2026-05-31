///|
pub struct LiveAutonomySpine {
  generated_at_ms : UInt64
  tick : Int
  status : String
  summary : String
  active_worker_count : Int
  review_count : Int
  blocked_count : Int
  accepted_update_count : Int
  no_change_count : Int
  failed_count : Int
  due_goal_count : Int
  standing_goal_count : Int
  planbook_open_count : Int
  planbook_repair_active_count : Int
  latest_watcher_summary : String
  visual_projection_path : String
  journal_path : String
  digest_path : String
  next_actions : Array[String]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn default_live_autonomy_path(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  "\{live_autonomy_base_dir(snapshot_path)}/live-autonomy.json"
}

///|
pub fn default_town_journal_path(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  "\{live_autonomy_base_dir(snapshot_path)}/town-journal.jsonl"
}

///|
pub fn default_live_digest_path(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  "\{live_autonomy_base_dir(snapshot_path)}/live-digest.md"
}

///|
pub async fn write_live_autonomy_spine(
  state : @core.TownState,
  snapshot_path? : String = @storage.default_snapshot_path(),
  standing_goals? : Array[@core.StandingGoal] = [],
  watcher_records? : Array[@core.WatcherRunRecord] = [],
  tick_summary? : String = "",
  daemon_tick? : Int? = None,
) -> LiveAutonomySpine {
  let journal_path = default_town_journal_path(snapshot_path~)
  let planbook_open = planbook_open_gap_count(snapshot_path~)
  let planbook_repair_active = planbook_repair_active_count(snapshot_path~)
  let spine = build_live_autonomy_spine(
    state, snapshot_path, standing_goals, watcher_records, tick_summary, daemon_tick,
    planbook_open, planbook_repair_active,
  )
  write_text_file(
    default_live_autonomy_path(snapshot_path~),
    spine.to_json().stringify(indent=2),
  )
  append_live_autonomy_journal(journal_path, spine)
  write_live_autonomy_digest(
    default_live_digest_path(snapshot_path~),
    state,
    spine,
    standing_goals,
    watcher_records,
  )
  spine
}

///|
pub async fn render_live_autonomy_status(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  let path = default_live_autonomy_path(snapshot_path~)
  if !@fs.exists(path) {
    ignore(refresh_live_autonomy_spine(snapshot_path~))
    if !@fs.exists(path) {
      return "No live autonomy spine exists at \{path}. Run `moon run cmd/main -- daemon tick` or `moon run cmd/main -- live refresh`."
    }
  }
  let parsed = @json.parse(@fs.read_file(path).text()) catch {
    _ =>
      return "Live autonomy spine exists at \{path}, but it is not valid JSON."
  }
  let decoded = match decode_live_autonomy_spine(parsed) {
    Some(value) => value
    None => {
      ignore(refresh_live_autonomy_spine(snapshot_path~))
      let refreshed = @json.parse(@fs.read_file(path).text()) catch {
        _ =>
          return "Live autonomy spine exists at \{path}, but it is not valid JSON after refresh."
      }
      match decode_live_autonomy_spine(refreshed) {
        Some(value) => value
        None =>
          return "Live autonomy spine exists at \{path}, but it does not match the contract after refresh."
      }
    }
  }
  let spine = sync_live_autonomy_planbook_counts(decoded, snapshot_path)
  [
    "# Live Autonomy Spine",
    "",
    "- Status: `\{spine.status}`",
    "- Tick: `\{spine.tick}`",
    "- Active workers: `\{spine.active_worker_count}`",
    "- Review: `\{spine.review_count}`",
    "- Blocked: `\{spine.blocked_count}`",
    "- Accepted updates: `\{spine.accepted_update_count}`",
    "- No-change cycles: `\{spine.no_change_count}`",
    "- Unresolved failures: `\{spine.failed_count}`",
    "- Standing goals: `\{spine.standing_goal_count}`",
    "- Due goals: `\{spine.due_goal_count}`",
    "- PlanBook open gaps: `\{spine.planbook_open_count}`",
    "- PlanBook active repairs: `\{spine.planbook_repair_active_count}`",
    "- Visual projection: `\{spine.visual_projection_path}`",
    "- Journal: `\{spine.journal_path}`",
    "- Digest: `\{spine.digest_path}`",
    "",
    "## Summary",
    "",
    spine.summary,
    "",
    "## Latest Watcher",
    "",
    spine.latest_watcher_summary,
    "",
    "## Next Actions",
    "",
    if spine.next_actions.is_empty() {
      "- none"
    } else {
      markdown_bullets(spine.next_actions)
    },
  ].join("\n")
}

///|
fn decode_live_autonomy_spine(json : Json) -> LiveAutonomySpine? {
  Some(@json.from_json(json)) catch {
    _ => None
  }
}

///|
pub async fn refresh_live_autonomy_spine(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  match @storage.load_snapshot_file(snapshot_path) {
    Some(snapshot) => {
      let goals = @storage.load_or_create_standing_goals(
        path=live_autonomy_standing_goal_path(snapshot_path),
      )
      let records = load_live_autonomy_watcher_records(snapshot_path, goals)
      let daemon = load_daemon_state(default_daemon_state_path(snapshot_path))
      persist_visual_projection(snapshot.town, snapshot_path)
      let spine = write_live_autonomy_spine(
        snapshot.town,
        snapshot_path~,
        standing_goals=goals,
        watcher_records=records,
        tick_summary="manual live autonomy refresh",
        daemon_tick=Some(daemon.tick_sequence),
      )
      "Refreshed live autonomy spine at \{default_live_autonomy_path(snapshot_path=snapshot_path)}: \{spine.summary}"
    }
    None => {
      let goals = @storage.load_or_create_standing_goals(
        path=live_autonomy_standing_goal_path(snapshot_path),
      )
      let records = load_live_autonomy_watcher_records(snapshot_path, goals)
      let daemon = load_daemon_state(default_daemon_state_path(snapshot_path))
      let spine = write_live_autonomy_spine(
        empty_live_autonomy_state(),
        snapshot_path~,
        standing_goals=goals,
        watcher_records=records,
        tick_summary="manual live autonomy refresh without saved town snapshot",
        daemon_tick=Some(daemon.tick_sequence),
      )
      "Refreshed live autonomy spine without saved town snapshot at \{default_live_autonomy_path(snapshot_path=snapshot_path)}: \{spine.summary}"
    }
  }
}

///|
async fn sync_live_autonomy_planbook_counts(
  spine : LiveAutonomySpine,
  snapshot_path : String,
) -> LiveAutonomySpine {
  let planbook_open = planbook_open_gap_count(snapshot_path~)
  let planbook_repair_active = planbook_repair_active_count(snapshot_path~)
  if planbook_open == spine.planbook_open_count &&
    planbook_repair_active == spine.planbook_repair_active_count {
    spine
  } else {
    let summary = synced_live_autonomy_summary(
      spine.summary,
      spine.tick,
      spine.active_worker_count,
      spine.review_count,
      spine.blocked_count,
      spine.accepted_update_count,
      spine.no_change_count,
      planbook_open,
    )
    let synced = {
      ..spine,
      generated_at_ms: @env.now(),
      planbook_open_count: planbook_open,
      planbook_repair_active_count: planbook_repair_active,
      summary,
      next_actions: live_autonomy_next_actions(
        spine.active_worker_count,
        spine.review_count,
        spine.blocked_count,
        spine.due_goal_count,
        [],
        planbook_open,
        planbook_repair_active,
      ),
    }
    write_text_file(
      default_live_autonomy_path(snapshot_path~),
      synced.to_json().stringify(indent=2),
    )
    synced
  }
}

///|
fn synced_live_autonomy_summary(
  previous : String,
  tick : Int,
  active_workers : Int,
  review : Int,
  blocked : Int,
  accepted_updates : Int,
  no_change : Int,
  planbook_open : Int,
) -> String {
  let mut prefix = ""
  for part in previous.split(";") {
    prefix = part.trim().to_owned()
    break
  }
  let metrics = "tick=\{tick} active=\{active_workers} review=\{review} blocked=\{blocked} accepted_updates=\{accepted_updates} no_change=\{no_change} planbook_open=\{planbook_open}"
  if prefix.is_blank() || prefix.has_prefix("tick=") {
    "\{metrics}; planbook counts reconciled from authoritative state"
  } else {
    "\{prefix}; \{metrics}; planbook counts reconciled from authoritative state"
  }
}

///|
fn empty_live_autonomy_state() -> @core.TownState {
  @core.empty_state(
    @core.TownConfig::new(
      id="moontown-live-autonomy",
      name="Moontown Live Autonomy",
    ),
  )
}

///|
fn build_live_autonomy_spine(
  state : @core.TownState,
  snapshot_path : String,
  standing_goals : Array[@core.StandingGoal],
  watcher_records : Array[@core.WatcherRunRecord],
  tick_summary : String,
  daemon_tick : Int?,
  planbook_open : Int,
  planbook_repair_active : Int,
) -> LiveAutonomySpine {
  let tick = match daemon_tick {
    Some(value) => value
    None => live_autonomy_tick(state)
  }
  let active_workers = count_live_workers(state)
  let review = count_live_executions(state, [
    @core.TaskExecutionStatus::ReviewQueued,
  ])
  let health_report = @health.inspect_town(state)
  let blocked = health_report.anomalies.length()
  let accepted_updates = count_watcher_decisions(
    watcher_records,
    @core.WatcherDecisionKind::Update,
  )
  let no_change = count_watcher_decisions(
    watcher_records,
    @core.WatcherDecisionKind::NoChange,
  )
  let failed = count_live_anomalies(health_report, "execution-failed")
  let due_goals = @scheduler.due_standing_goals(standing_goals, tick + 1)
  let status = live_autonomy_status(active_workers, review, blocked)
  let latest = latest_watcher_record_summary(watcher_records, standing_goals)
  let summary = if tick_summary == "" {
    "tick=\{tick} active=\{active_workers} review=\{review} blocked=\{blocked} accepted_updates=\{accepted_updates} no_change=\{no_change} planbook_open=\{planbook_open}"
  } else {
    "\{tick_summary}; tick=\{tick} active=\{active_workers} review=\{review} blocked=\{blocked} accepted_updates=\{accepted_updates} no_change=\{no_change} planbook_open=\{planbook_open}"
  }
  {
    generated_at_ms: @env.now(),
    tick,
    status,
    summary,
    active_worker_count: active_workers,
    review_count: review,
    blocked_count: blocked,
    accepted_update_count: accepted_updates,
    no_change_count: no_change,
    failed_count: failed,
    due_goal_count: due_goals.length(),
    standing_goal_count: standing_goals.length(),
    planbook_open_count: planbook_open,
    planbook_repair_active_count: planbook_repair_active,
    latest_watcher_summary: latest,
    visual_projection_path: default_visual_projection_path(snapshot_path),
    journal_path: default_town_journal_path(snapshot_path~),
    digest_path: default_live_digest_path(snapshot_path~),
    next_actions: live_autonomy_next_actions(
      active_workers,
      review,
      blocked,
      due_goals.length(),
      watcher_records,
      planbook_open,
      planbook_repair_active,
    ),
  }
}

///|
async fn write_live_autonomy_digest(
  path : String,
  state : @core.TownState,
  spine : LiveAutonomySpine,
  standing_goals : Array[@core.StandingGoal],
  watcher_records : Array[@core.WatcherRunRecord],
) -> Unit {
  write_text_file(
    path,
    render_live_autonomy_digest(state, spine, standing_goals, watcher_records),
  )
}

///|
fn render_live_autonomy_digest(
  state : @core.TownState,
  spine : LiveAutonomySpine,
  standing_goals : Array[@core.StandingGoal],
  watcher_records : Array[@core.WatcherRunRecord],
) -> String {
  let builder = StringBuilder::new()
  builder.write_string("# Moontown Live Digest\n\n")
  builder.write_string("- status: `\{spine.status}`\n")
  builder.write_string("- tick: `\{spine.tick}`\n")
  builder.write_string("- active_workers: `\{spine.active_worker_count}`\n")
  builder.write_string("- review_queue: `\{spine.review_count}`\n")
  builder.write_string("- blocked_or_unhealthy: `\{spine.blocked_count}`\n")
  builder.write_string("- unresolved_failures: `\{spine.failed_count}`\n")
  builder.write_string("- accepted_updates: `\{spine.accepted_update_count}`\n")
  builder.write_string("- no_change_cycles: `\{spine.no_change_count}`\n")
  builder.write_string(
    "- planbook_open_gaps: `\{spine.planbook_open_count}`\n\n",
  )
  builder.write_string(
    "- planbook_active_repairs: `\{spine.planbook_repair_active_count}`\n\n",
  )
  builder.write_string("## Current Interpretation\n\n")
  builder.write_string(live_autonomy_digest_interpretation(spine))
  builder.write_string("\n\n")
  builder.write_string("## Standing Watches\n\n")
  if standing_goals.is_empty() {
    builder.write_string("No standing watches are configured.\n\n")
  } else {
    builder.write_string(
      "| Goal | Book | Next Due | Due In | Approx Time | Latest Decision | Evidence |\n",
    )
    builder.write_string("|---|---|---:|---:|---|---|---:|\n")
    for goal in standing_goals {
      let latest = latest_record_for_goal(watcher_records, goal.id)
      let decision = match latest {
        Some(record) => record.decision.to_string()
        None => "not-run"
      }
      let evidence = match latest {
        Some(record) => record.new_source_count.to_string()
        None => "0"
      }
      let book = goal.target_book_id.unwrap_or("mayor-selected-book")
      let due_in_ticks = if goal.next_due_tick > spine.tick {
        goal.next_due_tick - spine.tick
      } else {
        0
      }
      builder.write_string(
        "|\{goal.id}|\{book}|\{goal.next_due_tick}|\{due_in_ticks}|\{live_autonomy_due_in_label(due_in_ticks)}|\{decision}|\{evidence}|\n",
      )
    }
    builder.write_string("\n")
  }
  builder.write_string("## Latest Watcher Signal\n\n")
  builder.write_string("\{spine.latest_watcher_summary}\n\n")
  builder.write_string("## Next Actions\n\n")
  if spine.next_actions.is_empty() {
    builder.write_string("- none\n")
  } else {
    for action in spine.next_actions {
      builder.write_string("- \{action}\n")
    }
  }
  builder.write_string("\n## Recent Town Events\n\n")
  let recent_events = recent_live_events(state, 6)
  if recent_events.is_empty() {
    builder.write_string("- no recent events\n")
  } else {
    for event in recent_events {
      builder.write_string(
        "- `\{event.kind}`: \{normalize_civic_pending_summary(event.detail)}\n",
      )
    }
  }
  builder.to_string()
}

///|
fn live_autonomy_digest_interpretation(spine : LiveAutonomySpine) -> String {
  if spine.blocked_count > 0 || spine.failed_count > 0 {
    "Mayor should recover live blockers before dispatching more work. Historical watcher failures are not counted here unless they remain unresolved."
  } else if spine.review_count > 0 {
    "The town is alive but waiting on keeper/operator review. It should not count review-gated output as progress until promoted."
  } else if spine.active_worker_count > 0 {
    "The town is actively working. Buildings and agents should show motion until the running work closes."
  } else if spine.due_goal_count > 0 {
    "The town is ready to dispatch due standing watches on the next daemon tick."
  } else {
    "The town is healthy and watching. No-change cycles are operational diligence, not domain progress."
  }
}

///|
fn recent_live_events(
  state : @core.TownState,
  limit : Int,
) -> Array[@core.TownEvent] {
  let events : Array[@core.TownEvent] = []
  let mut index = state.events.length() - 1
  while index >= 0 && events.length() < limit {
    events.push(state.events[index])
    index -= 1
  }
  events
}

///|
async fn append_live_autonomy_journal(
  path : String,
  spine : LiveAutonomySpine,
) -> Unit {
  let existing = read_text_or_empty(path)
  let line = spine.to_json().stringify()
  let content = if existing == "" {
    "\{line}\n"
  } else {
    "\{existing.trim_end()}\n\{line}\n"
  }
  write_text_file(path, content)
}

///|
fn live_autonomy_status(
  active_workers : Int,
  review : Int,
  blocked : Int,
) -> String {
  if blocked > 0 {
    "needs-recovery"
  } else if review > 0 {
    "reviewing"
  } else if active_workers > 0 {
    "working"
  } else {
    "watching"
  }
}

///|
fn live_autonomy_due_in_label(ticks : Int) -> String {
  let seconds = ticks * standing_goal_tick_seconds()
  if seconds <= 0 {
    "due now"
  } else if seconds < 60 {
    "\{seconds}s"
  } else if seconds < 3600 {
    "\{seconds / 60}m"
  } else {
    let hours = seconds / 3600
    let minutes = seconds % 3600 / 60
    if minutes == 0 {
      "\{hours}h"
    } else {
      "\{hours}h \{minutes}m"
    }
  }
}

///|
fn standing_goal_tick_seconds() -> Int {
  30
}

///|
fn live_autonomy_next_actions(
  active_workers : Int,
  review : Int,
  blocked : Int,
  due_goals : Int,
  watcher_records : Array[@core.WatcherRunRecord],
  planbook_open : Int,
  planbook_repair_active : Int,
) -> Array[String] {
  let actions : Array[String] = []
  if blocked > 0 {
    actions.push(
      "Mayor should recover blocked or stale work before dispatching more tasks.",
    )
  }
  if review > 0 {
    actions.push("Operator or keeper should process review-gated outputs.")
  }
  if due_goals > 0 {
    actions.push("Dispatch due standing goals on the next daemon tick.")
  }
  if planbook_repair_active > 0 {
    actions.push(
      "PlanBook has an active self-repair packet; monitor repair status before creating another one.",
    )
  } else if planbook_open > 0 {
    actions.push(
      "PlanBook has \{planbook_open} open self-build gap(s); the next daemon tick will queue and dispatch the top bounded Codex ACP repair packet when no repair is active.",
    )
  }
  if active_workers == 0 && due_goals == 0 {
    actions.push(
      "Town is watching; wait for the next real-world cadence or submit a new request.",
    )
  }
  match latest_watcher_record(watcher_records) {
    Some(record) =>
      match record.decision {
        @core.WatcherDecisionKind::Update =>
          actions.push(
            "Promote the latest watcher update into accepted book/projection state if review passes.",
          )
        @core.WatcherDecisionKind::NeedsReview =>
          actions.push(
            "Review the latest watcher finding before counting it as progress.",
          )
        @core.WatcherDecisionKind::Failed =>
          actions.push(
            "Retry the latest watcher failure with backoff and preserve the blocker.",
          )
        _ => ()
      }
    None => ()
  }
  actions
}

///|
fn count_live_workers(state : @core.TownState) -> Int {
  let mut count = 0
  for worker in state.workers {
    if worker.status == @core.WorkerStatus::Running ||
      worker.status == @core.WorkerStatus::Waiting ||
      worker.status == @core.WorkerStatus::Blocked {
      count += 1
    }
  }
  count
}

///|
fn count_live_executions(
  state : @core.TownState,
  statuses : Array[@core.TaskExecutionStatus],
) -> Int {
  let mut count = 0
  for execution in state.executions {
    for status in statuses {
      if execution.status == status {
        count += 1
        break
      }
    }
  }
  count
}

///|
fn count_live_anomalies(report : @health.HealthReport, title : String) -> Int {
  let mut count = 0
  for anomaly in report.anomalies {
    if anomaly.title == title {
      count += 1
    }
  }
  count
}

///|
fn count_watcher_decisions(
  records : Array[@core.WatcherRunRecord],
  decision : @core.WatcherDecisionKind,
) -> Int {
  let mut count = 0
  for record in records {
    if record.decision == decision {
      count += 1
    }
  }
  count
}

///|
fn latest_watcher_record(
  records : Array[@core.WatcherRunRecord],
) -> @core.WatcherRunRecord? {
  if records.is_empty() {
    None
  } else {
    let mut latest = records[0]
    for record in records {
      if record.tick >= latest.tick {
        latest = record
      }
    }
    Some(latest)
  }
}

///|
fn latest_record_for_goal(
  records : Array[@core.WatcherRunRecord],
  goal_id : String,
) -> @core.WatcherRunRecord? {
  let mut latest : @core.WatcherRunRecord? = None
  for record in records {
    if record.goal_id != goal_id {
      continue
    }
    match latest {
      Some(current) => if record.tick >= current.tick { latest = Some(record) }
      None => latest = Some(record)
    }
  }
  latest
}

///|
fn latest_watcher_record_summary(
  records : Array[@core.WatcherRunRecord],
  standing_goals : Array[@core.StandingGoal],
) -> String {
  match latest_watcher_record(records) {
    Some(record) => {
      let next_due = latest_watcher_summary_next_due(record, standing_goals)
      "\{record.goal_id} -> \{record.decision.to_string()} sources=\{record.new_source_count} delta=\{record.delta_score} next_due=\{next_due}"
    }
    None => "No watcher records yet."
  }
}

///|
fn latest_watcher_summary_next_due(
  record : @core.WatcherRunRecord,
  standing_goals : Array[@core.StandingGoal],
) -> Int {
  for goal in standing_goals {
    if goal.id == record.goal_id {
      return goal.next_due_tick
    }
  }
  record.next_due_tick
}

///|
fn live_autonomy_tick(state : @core.TownState) -> Int {
  let mut tick = state.events.length()
  for execution in state.executions {
    if execution.heartbeat_tick > tick {
      tick = execution.heartbeat_tick
    }
  }
  tick
}

///|
fn live_autonomy_base_dir(snapshot_path : String) -> String {
  let base = @path.Path::dirname(snapshot_path).to_string()
  if base == "." || base == "" {
    ".moontown"
  } else {
    base
  }
}

///|
fn live_autonomy_standing_goal_path(snapshot_path : String) -> String {
  "\{live_autonomy_base_dir(snapshot_path)}/standing-goals.json"
}

///|
async fn load_live_autonomy_watcher_records(
  snapshot_path : String,
  goals : Array[@core.StandingGoal],
) -> Array[@core.WatcherRunRecord] {
  let records : Array[@core.WatcherRunRecord] = []
  let ledger_dir = "\{live_autonomy_base_dir(snapshot_path)}/watchers"
  for goal in goals {
    for record in @storage.load_watcher_run_records(goal.id, dir=ledger_dir) {
      records.push(record)
    }
  }
  records
}
