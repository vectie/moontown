///|
priv struct LiveAutonomyOperatorView {
  status_label : String
  summary_label : String
  detail_label : String
  tone : String
  active_worker_label : String
  template_request_count : Int
  pending_template_request_count : Int
  failed_template_request_count : Int
  enabled_standing_goal_count : Int
  disabled_standing_goal_count : Int
  template_request_summary : String
  template_latest_event_summary : String
}

///|
fn live_autonomy_operator_view(
  model : Model,
  fallback_active_workers~ : Int,
) -> LiveAutonomyOperatorView {
  match model.live_autonomy {
    Some(spine) =>
      live_autonomy_connected_operator_view(
        model, spine, fallback_active_workers,
      )
    None => live_autonomy_disconnected_operator_view(fallback_active_workers)
  }
}

///|
fn live_autonomy_connected_operator_view(
  model : Model,
  spine : LiveAutonomySnapshot,
  _fallback_active_workers : Int,
) -> LiveAutonomyOperatorView {
  let standing_goals = standing_goal_summary(model)
  {
    status_label: spine.status,
    summary_label: spine.summary,
    detail_label: live_autonomy_status_view(spine).detail_label(),
    tone: live_autonomy_spine_tone(spine),
    active_worker_label: spine.active_worker_count.to_string(),
    template_request_count: spine.book_template_request_count,
    pending_template_request_count: spine.pending_book_template_request_count,
    failed_template_request_count: spine.failed_book_template_request_count,
    enabled_standing_goal_count: resolved_enabled_standing_goal_count(
      standing_goals, spine,
    ),
    disabled_standing_goal_count: resolved_disabled_standing_goal_count(
      standing_goals, spine,
    ),
    template_request_summary: spine.book_template_request_summary,
    template_latest_event_summary: spine.book_template_latest_event_summary,
  }
}

///|
fn live_autonomy_disconnected_operator_view(
  fallback_active_workers : Int,
) -> LiveAutonomyOperatorView {
  {
    status_label: "not-connected",
    summary_label: "No \{moontown_product_display_artifact_code("live-autonomy.json")} loaded yet. The daemon can still run, but the operator console is missing the single live spine.",
    detail_label: "Run a live refresh or daemon tick to connect the spine.",
    tone: "alert",
    active_worker_label: fallback_active_workers.to_string(),
    template_request_count: 0,
    pending_template_request_count: 0,
    failed_template_request_count: 0,
    enabled_standing_goal_count: 0,
    disabled_standing_goal_count: 0,
    template_request_summary: "No book-template request inbox has been loaded yet.",
    template_latest_event_summary: "No book-template lifecycle event has been loaded yet.",
  }
}

///|
fn resolved_enabled_standing_goal_count(
  summary : StandingGoalSummary,
  spine : LiveAutonomySnapshot,
) -> Int {
  if spine.standing_goal_count > 0 &&
    spine.enabled_standing_goal_count == 0 &&
    summary.enabled_count + summary.disabled_count > 0 {
    summary.enabled_count
  } else {
    spine.enabled_standing_goal_count
  }
}

///|
fn resolved_disabled_standing_goal_count(
  summary : StandingGoalSummary,
  spine : LiveAutonomySnapshot,
) -> Int {
  if spine.standing_goal_count > 0 &&
    spine.disabled_standing_goal_count == 0 &&
    summary.enabled_count + summary.disabled_count > 0 {
    summary.disabled_count
  } else {
    spine.disabled_standing_goal_count
  }
}

///|
fn live_autonomy_spine_tone(spine : LiveAutonomySnapshot) -> String {
  if spine.failed_book_template_request_count > 0 ||
    spine.planbook_repair_active_count > 0 {
    "alert"
  } else if spine.pending_book_template_request_count > 0 ||
    spine.planbook_open_count > 0 {
    "book"
  } else {
    match spine.status {
      "needs-recovery" => "alert"
      "working" => "live"
      "reviewing" => "alert"
      _ => "calm"
    }
  }
}
