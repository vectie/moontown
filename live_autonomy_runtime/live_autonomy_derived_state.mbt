///|
priv struct LiveAutonomyDerivedState {
  tick : Int
  status : String
  metrics : LiveAutonomyMetricCounts
  template_request_counts : @book_templates.BookTemplateRuntimeCounts
  waiting : LiveAutonomyWaitingState
  latest_watcher_summary : String
  summary : String
  next_actions : Array[String]
}

///|
fn live_autonomy_derived_state(
  input : LiveAutonomyBuildInput,
) -> LiveAutonomyDerivedState {
  let state = input.state
  let standing_goals = input.standing_goals
  let watcher_records = input.watcher_records
  let tick_summary = input.tick_summary
  let planbook_open = input.planbook_open
  let planbook_repair_active = input.planbook_repair_active
  let book_template_request_status = input.book_template_request_status
  let prior_stable_waiting_observation_streak = input.prior_stable_waiting_observation_streak
  let tick = live_autonomy_build_tick(input)
  let metrics = live_autonomy_metric_counts(
    state, standing_goals, watcher_records, tick,
  )
  let status = @live_autonomy_policy.live_autonomy_status(
    metrics.active_workers,
    metrics.review,
    metrics.blocked,
  )
  let template_request_counts = @book_templates.request_runtime_counts(
    book_template_request_status,
  )
  let waiting = @live_autonomy_policy.live_autonomy_waiting_state(
    live_autonomy_blocker_context(
      metrics,
      planbook_open,
      planbook_repair_active,
      template_request_counts.pending,
      template_request_counts.failed,
    ),
    prior_stable_waiting_observation_streak,
  )
  let latest = latest_watcher_record_summary(watcher_records, standing_goals)
  let summary = live_autonomy_summary_line(
    tick_summary,
    live_autonomy_summary_context(
      tick, metrics, waiting, planbook_open, template_request_counts,
    ),
  )
  {
    tick,
    status,
    metrics,
    template_request_counts,
    waiting,
    summary,
    latest_watcher_summary: latest,
    next_actions: @live_autonomy_policy.live_autonomy_next_actions_for(
      live_autonomy_action_context(
        metrics,
        watcher_records,
        planbook_open,
        planbook_repair_active,
        template_request_counts.pending,
        template_request_counts.failed,
      ),
    ),
  }
}

///|
fn live_autonomy_build_tick(input : LiveAutonomyBuildInput) -> Int {
  match input.daemon_tick {
    Some(value) => value
    None => live_autonomy_tick(input.state)
  }
}
