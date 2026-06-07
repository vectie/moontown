///|
priv struct LiveAutonomySummaryContext {
  tick : Int
  metrics : LiveAutonomyMetricCounts
  waiting : LiveAutonomyWaitingState
  planbook_open : Int
  template_request_count : Int
  pending_template_count : Int
}

///|
fn live_autonomy_summary_context(
  tick : Int,
  metrics : LiveAutonomyMetricCounts,
  waiting : LiveAutonomyWaitingState,
  planbook_open : Int,
  template_request_counts : BookTemplateRequestCounts,
) -> LiveAutonomySummaryContext {
  {
    tick,
    metrics,
    waiting,
    planbook_open,
    template_request_count: template_request_counts.total,
    pending_template_count: template_request_counts.pending,
  }
}

///|
fn live_autonomy_summary_line(
  prefix : String,
  context : LiveAutonomySummaryContext,
) -> String {
  let metrics_text = live_autonomy_summary_metrics_text(context)
  if prefix == "" {
    metrics_text
  } else {
    "\{prefix}; \{metrics_text}"
  }
}

///|
fn live_autonomy_summary_metrics_text(
  context : LiveAutonomySummaryContext,
) -> String {
  [
    live_autonomy_tick_metrics_text(context.tick),
    live_autonomy_worker_metrics_text(context.metrics),
    live_autonomy_stability_metrics_text(context.waiting),
    live_autonomy_watcher_metrics_text(context.metrics),
    live_autonomy_standing_goal_metrics_text(context.metrics),
    live_autonomy_planbook_metrics_text(context.planbook_open),
    live_autonomy_template_request_metrics_text(
      context.template_request_count,
      context.pending_template_count,
    ),
  ].join(" ")
}

///|
fn live_autonomy_tick_metrics_text(tick : Int) -> String {
  "tick=\{tick}"
}

///|
fn live_autonomy_worker_metrics_text(
  metrics : LiveAutonomyMetricCounts,
) -> String {
  [
    "active=\{metrics.active_workers}",
    "review=\{metrics.review}",
    "blocked=\{metrics.blocked}",
  ].join(" ")
}

///|
fn live_autonomy_stability_metrics_text(
  waiting : LiveAutonomyWaitingState,
) -> String {
  [
    "stable_waiting=\{waiting.stable_waiting}",
    "stable_waiting_observation_streak=\{waiting.stable_waiting_observation_streak}",
  ].join(" ")
}

///|
fn live_autonomy_watcher_metrics_text(
  metrics : LiveAutonomyMetricCounts,
) -> String {
  [
    "accepted_updates=\{metrics.accepted_updates}",
    "no_change=\{metrics.no_change}",
    "transient_infra_debt=\{metrics.transient_infrastructure_debt}",
  ].join(" ")
}

///|
fn live_autonomy_standing_goal_metrics_text(
  metrics : LiveAutonomyMetricCounts,
) -> String {
  [
    "enabled_goals=\{metrics.enabled_standing_goals}",
    "disabled_goals=\{metrics.disabled_standing_goals}",
  ].join(" ")
}

///|
fn live_autonomy_planbook_metrics_text(planbook_open : Int) -> String {
  "planbook_open=\{planbook_open}"
}

///|
fn live_autonomy_template_request_metrics_text(
  template_request_count : Int,
  pending_template_count : Int,
) -> String {
  [
    "template_requests=\{template_request_count}",
    "pending_templates=\{pending_template_count}",
  ].join(" ")
}
