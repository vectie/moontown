///|
pub struct LiveAutonomySpine {
  generated_at_ms : UInt64
  tick : Int
  status : String
  summary : String
  stable_waiting : Bool
  stable_waiting_observation_streak : Int
  stable_waiting_blockers : Array[String]
  active_worker_count : Int
  review_count : Int
  blocked_count : Int
  accepted_update_count : Int
  no_change_count : Int
  failed_count : Int
  transient_infrastructure_debt_count : Int
  due_goal_count : Int
  standing_goal_count : Int
  enabled_standing_goal_count : Int
  disabled_standing_goal_count : Int
  planbook_open_count : Int
  planbook_repair_active_count : Int
  book_template_request_count : Int
  pending_book_template_request_count : Int
  failed_book_template_request_count : Int
  book_template_request_summary : String
  book_template_latest_event_summary : String
  latest_watcher_summary : String
  visual_projection_path : String
  journal_path : String
  digest_path : String
  planbook_change_log_path : String
  planbook_engineering_digest_path : String
  latest_change_summary : String
  next_actions : Array[String]
} derive(Debug, Eq, ToJson, FromJson)

///|
struct LiveAutonomyJournalTick {
  tick : Int
} derive(FromJson)

///|
struct LiveAutonomyStabilityProbe {
  tick : Int
  active_worker_count : Int
  review_count : Int
  blocked_count : Int
  failed_count : Int
  due_goal_count : Int
  planbook_open_count : Int
  planbook_repair_active_count : Int
  pending_book_template_request_count : Int
  failed_book_template_request_count : Int
} derive(FromJson)

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
async fn latest_live_autonomy_journal_tick(snapshot_path : String) -> Int {
  let mut latest = 0
  let journal_path = default_town_journal_path(snapshot_path~)
  if @fs.exists(journal_path) {
    for line in @fs.read_file(journal_path).text().split("\n") {
      let trimmed = line.trim()
      if trimmed == "" {
        continue
      }
      let parsed = @json.parse(trimmed) catch { _ => continue }
      let spine : LiveAutonomyJournalTick = @json.from_json(parsed) catch {
        _ => continue
      }
      if spine.tick > latest {
        latest = spine.tick
      }
    }
  }
  let live_path = default_live_autonomy_path(snapshot_path~)
  if @fs.exists(live_path) {
    let parsed = @json.parse(@fs.read_file(live_path).text()) catch {
      _ => return latest
    }
    let spine : LiveAutonomyJournalTick = @json.from_json(parsed) catch {
      _ => return latest
    }
    if spine.tick > latest {
      latest = spine.tick
    }
  }
  latest
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
  let book_template_status = inspect_book_template_request_status(
    request_path=default_book_template_request_path(snapshot_path~),
  )
  let change_log_path = live_autonomy_planbook_change_log_path()
  let engineering_digest_path = live_autonomy_planbook_engineering_digest_path()
  let latest_change = normalized_planbook_latest_change_summary(
    latest_planbook_change_summary(change_log_path),
    planbook_open,
    planbook_repair_active,
  )
  let tick = match daemon_tick {
    Some(value) => value
    None => live_autonomy_tick(state)
  }
  let prior_stable_waiting_observation_streak = prior_live_autonomy_stable_waiting_observation_streak(
    snapshot_path, tick,
  )
  let spine = build_live_autonomy_spine(
    state,
    snapshot_path,
    standing_goals,
    watcher_records,
    tick_summary,
    Some(tick),
    planbook_open,
    planbook_repair_active,
    change_log_path,
    engineering_digest_path,
    latest_change,
    book_template_status,
    prior_stable_waiting_observation_streak,
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
  let current = current_live_autonomy_spine(snapshot_path, decoded)
  let spine = sync_live_autonomy_planbook_counts(current, snapshot_path)
  [
    "# Live Autonomy Spine",
    "",
    "- Status: `\{spine.status}`",
    "- Tick: `\{spine.tick}`",
    "- Stable waiting: `\{spine.stable_waiting}`",
    "- Stable waiting observation streak: `\{spine.stable_waiting_observation_streak}`",
    "- Active workers: `\{spine.active_worker_count}`",
    "- Review: `\{spine.review_count}`",
    "- Blocked: `\{spine.blocked_count}`",
    "- Accepted updates: `\{spine.accepted_update_count}`",
    "- No-change cycles: `\{spine.no_change_count}`",
    "- Unresolved failures: `\{spine.failed_count}`",
    "- Transient infrastructure debt: `\{spine.transient_infrastructure_debt_count}`",
    "- Standing goals: `\{spine.standing_goal_count}`",
    "- Enabled standing goals: `\{spine.enabled_standing_goal_count}`",
    "- Disabled standing goals: `\{spine.disabled_standing_goal_count}`",
    "- Due goals: `\{spine.due_goal_count}`",
    "- PlanBook open gaps: `\{spine.planbook_open_count}`",
    "- PlanBook active repairs: `\{spine.planbook_repair_active_count}`",
    "- Book template requests: `\{spine.book_template_request_count}`",
    "- Pending template requests: `\{spine.pending_book_template_request_count}`",
    "- Failed template requests: `\{spine.failed_book_template_request_count}`",
    "- Latest book-template event: \{spine.book_template_latest_event_summary}",
    "- Visual projection: `\{spine.visual_projection_path}`",
    "- Journal: `\{spine.journal_path}`",
    "- Digest: `\{spine.digest_path}`",
    "- PlanBook change log: `\{spine.planbook_change_log_path}`",
    "- PlanBook engineering digest: `\{spine.planbook_engineering_digest_path}`",
    "",
    "## Stable Waiting Blockers",
    "",
    if spine.stable_waiting_blockers.is_empty() {
      "- none"
    } else {
      markdown_bullets(spine.stable_waiting_blockers)
    },
    "",
    "## Summary",
    "",
    spine.summary,
    "",
    "## Latest Watcher",
    "",
    spine.latest_watcher_summary,
    "",
    "## Latest Change",
    "",
    spine.latest_change_summary,
    "",
    "## Book Template Requests",
    "",
    spine.book_template_request_summary,
    "",
    "Latest event: \{spine.book_template_latest_event_summary}",
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
async fn current_live_autonomy_spine(
  snapshot_path : String,
  fallback : LiveAutonomySpine,
) -> LiveAutonomySpine {
  match @storage.load_snapshot_file(snapshot_path) {
    Some(snapshot) => {
      let goals = @storage.load_or_create_standing_goals(
        path=live_autonomy_standing_goal_path(snapshot_path),
      )
      let records = load_live_autonomy_watcher_records(snapshot_path, goals)
      let daemon = load_daemon_state(default_daemon_state_path(snapshot_path))
      let daemon_tick = effective_daemon_tick(
        snapshot_path,
        daemon,
        snapshot.town,
        goals,
        records,
      )
      let prior_stable_waiting_observation_streak = prior_live_autonomy_stable_waiting_observation_streak(
        snapshot_path, daemon_tick,
      )
      build_live_autonomy_spine(
        snapshot.town,
        snapshot_path,
        goals,
        records,
        "",
        Some(daemon_tick),
        fallback.planbook_open_count,
        fallback.planbook_repair_active_count,
        fallback.planbook_change_log_path,
        fallback.planbook_engineering_digest_path,
        fallback.latest_change_summary,
        inspect_book_template_request_status(
          request_path=default_book_template_request_path(snapshot_path~),
        ),
        prior_stable_waiting_observation_streak,
      )
    }
    None => fallback
  }
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
      let daemon_tick = effective_daemon_tick(
        snapshot_path,
        daemon,
        snapshot.town,
        goals,
        records,
      )
      persist_visual_projection(snapshot.town, snapshot_path)
      let spine = write_live_autonomy_spine(
        snapshot.town,
        snapshot_path~,
        standing_goals=goals,
        watcher_records=records,
        tick_summary="manual live autonomy refresh",
        daemon_tick=Some(daemon_tick),
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
    let change_log_path = live_autonomy_planbook_change_log_path()
    let engineering_digest_path = live_autonomy_planbook_engineering_digest_path()
    let latest_change = normalized_planbook_latest_change_summary(
      latest_planbook_change_summary(change_log_path),
      planbook_open,
      planbook_repair_active,
    )
    let stable_waiting_blockers = live_autonomy_stable_waiting_blockers(
      spine.active_worker_count,
      spine.review_count,
      spine.blocked_count,
      spine.failed_count,
      spine.due_goal_count,
      planbook_open,
      planbook_repair_active,
      spine.pending_book_template_request_count,
      spine.failed_book_template_request_count,
    )
    let stable_waiting = stable_waiting_blockers.is_empty()
    let stable_waiting_observation_streak = if stable_waiting {
      max_int(
        spine.stable_waiting_observation_streak,
        prior_live_autonomy_stable_waiting_observation_streak(
          snapshot_path,
          spine.tick,
        ) +
        1,
      )
    } else {
      0
    }
    let goals = @storage.load_or_create_standing_goals(
      path=live_autonomy_standing_goal_path(snapshot_path),
    )
    let records = load_live_autonomy_watcher_records(snapshot_path, goals)
    let synced = {
      ..spine,
      generated_at_ms: @env.now(),
      planbook_open_count: planbook_open,
      planbook_repair_active_count: planbook_repair_active,
      stable_waiting,
      stable_waiting_observation_streak,
      stable_waiting_blockers,
      planbook_change_log_path: change_log_path,
      planbook_engineering_digest_path: engineering_digest_path,
      latest_change_summary: latest_change,
      latest_watcher_summary: latest_watcher_record_summary(records, goals),
      summary,
      next_actions: live_autonomy_next_actions(
        spine.active_worker_count,
        spine.review_count,
        spine.blocked_count,
        spine.due_goal_count,
        records,
        planbook_open,
        planbook_repair_active,
        spine.pending_book_template_request_count,
        spine.failed_book_template_request_count,
        spine.transient_infrastructure_debt_count,
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
  planbook_change_log_path : String,
  planbook_engineering_digest_path : String,
  latest_change_summary : String,
  book_template_request_status : BookTemplateRequestStatus,
  prior_stable_waiting_observation_streak : Int,
) -> LiveAutonomySpine {
  let tick = match daemon_tick {
    Some(value) => value
    None => live_autonomy_tick(state)
  }
  let active_workers = count_live_activity(state)
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
  let transient_infrastructure_debt = count_transient_infrastructure_debt(state)
  let enabled_standing_goals = count_enabled_standing_goals(standing_goals)
  let disabled_standing_goals = count_disabled_standing_goals(standing_goals)
  let due_goals = @scheduler.due_standing_goals(standing_goals, tick + 1)
  let status = live_autonomy_status(active_workers, review, blocked)
  let stable_waiting_blockers = live_autonomy_stable_waiting_blockers(
    active_workers,
    review,
    blocked,
    failed,
    due_goals.length(),
    planbook_open,
    planbook_repair_active,
    book_template_request_status.pending_count +
    book_template_request_status.retry_count,
    book_template_request_status.failed_count,
  )
  let stable_waiting = stable_waiting_blockers.is_empty()
  let stable_waiting_observation_streak = if stable_waiting {
    prior_stable_waiting_observation_streak + 1
  } else {
    0
  }
  let latest = latest_watcher_record_summary(watcher_records, standing_goals)
  let summary = if tick_summary == "" {
    "tick=\{tick} active=\{active_workers} review=\{review} blocked=\{blocked} stable_waiting=\{stable_waiting} stable_waiting_observation_streak=\{stable_waiting_observation_streak} accepted_updates=\{accepted_updates} no_change=\{no_change} transient_infra_debt=\{transient_infrastructure_debt} enabled_goals=\{enabled_standing_goals} disabled_goals=\{disabled_standing_goals} planbook_open=\{planbook_open} template_requests=\{book_template_request_status.request_count} pending_templates=\{book_template_request_status.pending_count + book_template_request_status.retry_count}"
  } else {
    "\{tick_summary}; tick=\{tick} active=\{active_workers} review=\{review} blocked=\{blocked} stable_waiting=\{stable_waiting} stable_waiting_observation_streak=\{stable_waiting_observation_streak} accepted_updates=\{accepted_updates} no_change=\{no_change} transient_infra_debt=\{transient_infrastructure_debt} enabled_goals=\{enabled_standing_goals} disabled_goals=\{disabled_standing_goals} planbook_open=\{planbook_open} template_requests=\{book_template_request_status.request_count} pending_templates=\{book_template_request_status.pending_count + book_template_request_status.retry_count}"
  }
  {
    generated_at_ms: @env.now(),
    tick,
    status,
    summary,
    stable_waiting,
    stable_waiting_observation_streak,
    stable_waiting_blockers,
    active_worker_count: active_workers,
    review_count: review,
    blocked_count: blocked,
    accepted_update_count: accepted_updates,
    no_change_count: no_change,
    failed_count: failed,
    transient_infrastructure_debt_count: transient_infrastructure_debt,
    due_goal_count: due_goals.length(),
    standing_goal_count: standing_goals.length(),
    enabled_standing_goal_count: enabled_standing_goals,
    disabled_standing_goal_count: disabled_standing_goals,
    planbook_open_count: planbook_open,
    planbook_repair_active_count: planbook_repair_active,
    book_template_request_count: book_template_request_status.request_count,
    pending_book_template_request_count: book_template_request_status.pending_count +
    book_template_request_status.retry_count,
    failed_book_template_request_count: book_template_request_status.failed_count,
    book_template_request_summary: book_template_request_status.summary,
    book_template_latest_event_summary: book_template_request_status.latest_event_summary,
    latest_watcher_summary: latest,
    visual_projection_path: default_visual_projection_path(snapshot_path),
    journal_path: default_town_journal_path(snapshot_path~),
    digest_path: default_live_digest_path(snapshot_path~),
    planbook_change_log_path,
    planbook_engineering_digest_path,
    latest_change_summary,
    next_actions: live_autonomy_next_actions(
      active_workers,
      review,
      blocked,
      due_goals.length(),
      watcher_records,
      planbook_open,
      planbook_repair_active,
      book_template_request_status.pending_count +
      book_template_request_status.retry_count,
      book_template_request_status.failed_count,
      transient_infrastructure_debt,
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
  builder.write_string("- stable_waiting: `\{spine.stable_waiting}`\n")
  builder.write_string(
    "- stable_waiting_observation_streak: `\{spine.stable_waiting_observation_streak}`\n",
  )
  builder.write_string(
    "- stable_waiting_blockers: `\{spine.stable_waiting_blockers.length()}`\n",
  )
  builder.write_string("- active_workers: `\{spine.active_worker_count}`\n")
  builder.write_string("- review_queue: `\{spine.review_count}`\n")
  builder.write_string("- blocked_or_unhealthy: `\{spine.blocked_count}`\n")
  builder.write_string("- unresolved_failures: `\{spine.failed_count}`\n")
  builder.write_string(
    "- transient_infrastructure_debt: `\{spine.transient_infrastructure_debt_count}`\n",
  )
  builder.write_string("- accepted_updates: `\{spine.accepted_update_count}`\n")
  builder.write_string("- no_change_cycles: `\{spine.no_change_count}`\n")
  builder.write_string("- standing_goals: `\{spine.standing_goal_count}`\n")
  builder.write_string(
    "- enabled_standing_goals: `\{spine.enabled_standing_goal_count}`\n",
  )
  builder.write_string(
    "- disabled_standing_goals: `\{spine.disabled_standing_goal_count}`\n",
  )
  builder.write_string(
    "- planbook_open_gaps: `\{spine.planbook_open_count}`\n\n",
  )
  builder.write_string(
    "- planbook_active_repairs: `\{spine.planbook_repair_active_count}`\n\n",
  )
  builder.write_string(
    "- book_template_requests: `\{spine.book_template_request_count}`\n",
  )
  builder.write_string(
    "- pending_book_template_requests: `\{spine.pending_book_template_request_count}`\n",
  )
  builder.write_string(
    "- failed_book_template_requests: `\{spine.failed_book_template_request_count}`\n",
  )
  builder.write_string(
    "- book_template_request_summary: \{spine.book_template_request_summary}\n\n",
  )
  builder.write_string(
    "- book_template_latest_event: \{spine.book_template_latest_event_summary}\n\n",
  )
  builder.write_string(
    "- planbook_change_log: `\{spine.planbook_change_log_path}`\n",
  )
  builder.write_string(
    "- planbook_engineering_digest: `\{spine.planbook_engineering_digest_path}`\n",
  )
  builder.write_string("- latest_change: \{spine.latest_change_summary}\n\n")
  builder.write_string("## Current Interpretation\n\n")
  builder.write_string(live_autonomy_digest_interpretation(spine))
  builder.write_string("\n\n")
  builder.write_string("## Stable Waiting Blockers\n\n")
  if spine.stable_waiting_blockers.is_empty() {
    builder.write_string("- none\n\n")
  } else {
    for blocker in spine.stable_waiting_blockers {
      builder.write_string("- \{blocker}\n")
    }
    builder.write_string("\n")
  }
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
  builder.write_string("## Latest PlanBook Change\n\n")
  builder.write_string("\{spine.latest_change_summary}\n\n")
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
  } else if spine.failed_book_template_request_count > 0 {
    "The town has failed book-template requests. Mayor should surface the request and config errors before accepting more Moondesk book creation work."
  } else if spine.pending_book_template_request_count > 0 {
    "The town has pending book-template requests from Moondesk or operators. The next daemon tick should process them into real MoonBook workspaces."
  } else if spine.review_count > 0 {
    "The town is healthy and watching with a visible review queue. Review-gated output is not counted as progress until promoted, but it no longer blocks the live loop."
  } else if spine.active_worker_count > 0 {
    "The town is actively working. Buildings and agents should show motion until the running work closes."
  } else if spine.due_goal_count > 0 {
    "The town is ready to dispatch due standing watches on the next daemon tick."
  } else if spine.transient_infrastructure_debt_count > 0 {
    "The town is healthy and watching. Historical transient infrastructure debt is visible for accounting, but it is not counted as domain progress or unresolved failure."
  } else if spine.stable_waiting {
    "The town is in stable waiting: no active work, review debt, due standing goal, PlanBook gap, or template request is blocking autonomous operation."
  } else {
    "The town is healthy and watching. No-change cycles are operational diligence, not domain progress."
  }
}

///|
fn live_autonomy_planbook_change_log_path() -> String {
  "\{default_planbook_workspace_root()}/wiki/history/change-log.md"
}

///|
fn live_autonomy_planbook_engineering_digest_path() -> String {
  "\{default_planbook_workspace_root()}/wiki/history/daily-engineering-digest.md"
}

///|
async fn latest_planbook_change_summary(path : String) -> String {
  let text = read_text_or_empty(path)
  if text.trim().is_empty() {
    return "No PlanBook change log is available yet."
  }
  let sections = text.split("## ")
  let mut latest = ""
  for section in sections {
    let trimmed = section.trim()
    if trimmed != "" && !trimmed.has_prefix("# PlanBook") {
      latest = trimmed.to_owned()
    }
  }
  if latest == "" {
    "PlanBook change log exists but has no event entries yet."
  } else {
    latest
  }
}

///|
fn normalized_planbook_latest_change_summary(
  latest : String,
  planbook_open : Int,
  planbook_repair_active : Int,
) -> String {
  if planbook_open == 0 &&
    planbook_repair_active == 0 &&
    (
      latest.contains("repair task running") ||
      latest.contains("repair task dispatched") ||
      latest.contains("repair task blocked")
    ) {
    "PlanBook is stable: no open self-build gap and no active repair remains. Latest repair log entry is historical."
  } else {
    latest
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
  let _ = review
  if blocked > 0 {
    "needs-recovery"
  } else if active_workers > 0 {
    "working"
  } else {
    "watching"
  }
}

///|
fn live_autonomy_stable_waiting_blockers(
  active_workers : Int,
  review : Int,
  blocked : Int,
  failed : Int,
  due_goals : Int,
  planbook_open : Int,
  planbook_repair_active : Int,
  pending_book_template_requests : Int,
  failed_book_template_requests : Int,
) -> Array[String] {
  let blockers : Array[String] = []
  if active_workers > 0 {
    blockers.push("active workers or executions: \{active_workers}")
  }
  if review > 0 {
    blockers.push("review queue: \{review}")
  }
  if blocked > 0 {
    blockers.push("blocked or unhealthy items: \{blocked}")
  }
  if failed > 0 {
    blockers.push("unresolved failures: \{failed}")
  }
  if due_goals > 0 {
    blockers.push("due standing goals: \{due_goals}")
  }
  if planbook_open > 0 {
    blockers.push("PlanBook open gaps: \{planbook_open}")
  }
  if planbook_repair_active > 0 {
    blockers.push("PlanBook active repairs: \{planbook_repair_active}")
  }
  if pending_book_template_requests > 0 {
    blockers.push(
      "pending book-template requests: \{pending_book_template_requests}",
    )
  }
  if failed_book_template_requests > 0 {
    blockers.push(
      "failed book-template requests: \{failed_book_template_requests}",
    )
  }
  blockers
}

///|
fn live_autonomy_stability_probe_is_stable(
  probe : LiveAutonomyStabilityProbe,
) -> Bool {
  live_autonomy_stable_waiting_blockers(
    probe.active_worker_count,
    probe.review_count,
    probe.blocked_count,
    probe.failed_count,
    probe.due_goal_count,
    probe.planbook_open_count,
    probe.planbook_repair_active_count,
    probe.pending_book_template_request_count,
    probe.failed_book_template_request_count,
  ).is_empty()
}

///|
async fn prior_live_autonomy_stable_waiting_observation_streak(
  snapshot_path : String,
  current_tick : Int,
) -> Int {
  let journal_path = default_town_journal_path(snapshot_path~)
  if !@fs.exists(journal_path) {
    return 0
  }
  let mut streak = 0
  let mut last_tick = -1
  for line in @fs.read_file(journal_path).text().split("\n") {
    let trimmed = line.trim()
    if trimmed == "" {
      continue
    }
    let parsed = @json.parse(trimmed) catch { _ => continue }
    let probe : LiveAutonomyStabilityProbe = @json.from_json(parsed) catch {
      _ => continue
    }
    if probe.tick >= current_tick {
      continue
    }
    if probe.tick == last_tick {
      if !live_autonomy_stability_probe_is_stable(probe) {
        streak = 0
      }
      continue
    }
    last_tick = probe.tick
    if live_autonomy_stability_probe_is_stable(probe) {
      streak += 1
    } else {
      streak = 0
    }
  }
  streak
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
  pending_book_template_requests : Int,
  failed_book_template_requests : Int,
  transient_infrastructure_debt : Int,
) -> Array[String] {
  let actions : Array[String] = []
  let latest_decision = match latest_watcher_record(watcher_records) {
    Some(record) => Some(watcher_record_effective_decision(record))
    None => None
  }
  if blocked > 0 {
    actions.push(
      "Mayor should recover blocked or stale work before dispatching more tasks.",
    )
  }
  if review > 0 {
    actions.push(
      "Review queue is visible for keeper/operator judgment, but routine queued review does not block the live watch loop.",
    )
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
  if failed_book_template_requests > 0 {
    actions.push(
      "Inspect failed book-template request configs before retrying Moondesk book creation.",
    )
  } else if pending_book_template_requests > 0 {
    actions.push(
      "Process pending book-template requests so requested books become real MoonBook workspaces.",
    )
  }
  match latest_decision {
    Some(decision) =>
      match decision {
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
        @core.WatcherDecisionKind::Deferred =>
          actions.push(
            "Latest watcher is deferred; keep it as infrastructure retry/accounting debt until a real MoonBook terminal marker arrives.",
          )
        _ => ()
      }
    None => ()
  }
  if active_workers == 0 &&
    due_goals == 0 &&
    latest_decision != Some(@core.WatcherDecisionKind::Deferred) {
    if transient_infrastructure_debt > 0 {
      actions.push(
        "Historical transient infrastructure debt is visible and inspectable; keep watching unless the count grows or the latest watcher becomes deferred.",
      )
    }
    actions.push(
      "Town is watching; wait for the next real-world cadence or submit a new request.",
    )
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
fn count_live_activity(state : @core.TownState) -> Int {
  max_int(count_live_workers(state), count_live_active_executions(state))
}

///|
fn count_live_active_executions(state : @core.TownState) -> Int {
  count_live_executions(state, [
    @core.TaskExecutionStatus::ProposalImported,
    @core.TaskExecutionStatus::RunConfirmed,
    @core.TaskExecutionStatus::Running,
    @core.TaskExecutionStatus::AwaitingPersistence,
  ])
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
fn count_transient_infrastructure_debt(state : @core.TownState) -> Int {
  let mut count = 0
  for execution in state.executions {
    if execution.result_decision == "deferred-transient-infrastructure" {
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
    if watcher_record_effective_decision(record) == decision {
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
      if watcher_record_prefer_candidate(latest, record) {
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
      Some(current) =>
        if watcher_record_prefer_candidate(current, record) {
          latest = Some(record)
        }
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
      let decision = watcher_record_effective_decision(record).to_string()
      "\{record.goal_id} -> \{decision} sources=\{record.new_source_count} delta=\{record.delta_score} next_due=\{next_due}"
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
