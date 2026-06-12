///|
priv struct LiveAutonomyBuildInput {
  state : @core.TownState
  snapshot_path : String
  standing_goals : Array[@core.StandingGoal]
  watcher_records : Array[@core.WatcherRunRecord]
  tick_summary : String
  daemon_tick : Int?
  planbook_open : Int
  planbook_repair_active : Int
  planbook_change_log_path : String
  planbook_engineering_digest_path : String
  latest_change_summary : String
  book_template_request_status : @book_templates.BookTemplateRequestStatus
  prior_stable_waiting_observation_streak : Int
}

///|
fn build_live_autonomy_spine(
  input : LiveAutonomyBuildInput,
) -> LiveAutonomySpine {
  live_autonomy_spine_from(
    input,
    live_autonomy_derived_state(input),
    @env.now(),
  )
}

///|
fn live_autonomy_spine_from(
  input : LiveAutonomyBuildInput,
  derived : LiveAutonomyDerivedState,
  generated_at_ms : UInt64,
) -> LiveAutonomySpine {
  let snapshot_path = input.snapshot_path
  let standing_goals = input.standing_goals
  let planbook_open = input.planbook_open
  let planbook_repair_active = input.planbook_repair_active
  let planbook_change_log_path = input.planbook_change_log_path
  let planbook_engineering_digest_path = input.planbook_engineering_digest_path
  let latest_change_summary = input.latest_change_summary
  let book_template_request_status = input.book_template_request_status
  let metrics = derived.metrics
  let template_request_counts = derived.template_request_counts
  let waiting = derived.waiting
  {
    generated_at_ms,
    tick: derived.tick,
    status: derived.status,
    summary: derived.summary,
    stable_waiting: waiting.stable_waiting,
    stable_waiting_observation_streak: waiting.stable_waiting_observation_streak,
    stable_waiting_blockers: waiting.stable_waiting_blockers,
    active_worker_count: metrics.active_workers,
    review_count: metrics.review,
    blocked_count: metrics.blocked,
    accepted_update_count: metrics.accepted_updates,
    no_change_count: metrics.no_change,
    failed_count: metrics.failed,
    transient_infrastructure_debt_count: metrics.transient_infrastructure_debt,
    due_goal_count: metrics.due_goals,
    standing_goal_count: standing_goals.length(),
    enabled_standing_goal_count: metrics.enabled_standing_goals,
    disabled_standing_goal_count: metrics.disabled_standing_goals,
    planbook_open_count: planbook_open,
    planbook_repair_active_count: planbook_repair_active,
    book_template_request_count: template_request_counts.total,
    pending_book_template_request_count: template_request_counts.pending,
    failed_book_template_request_count: template_request_counts.failed,
    book_template_request_summary: book_template_request_status.summary,
    book_template_latest_event_summary: book_template_request_status.latest_event_summary,
    latest_watcher_summary: derived.latest_watcher_summary,
    visual_projection_path: @visual_projection.default_visual_projection_path(
      snapshot_path,
    ),
    journal_path: default_town_journal_path(snapshot_path~),
    digest_path: default_live_digest_path(snapshot_path~),
    planbook_change_log_path,
    planbook_engineering_digest_path,
    latest_change_summary,
    next_actions: derived.next_actions,
  }
}
