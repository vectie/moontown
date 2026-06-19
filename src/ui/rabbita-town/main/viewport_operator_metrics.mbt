///|
priv struct OperatorConsoleMetrics {
  latest_decision : String
  latest_sources : String
  latest_checked : String
  latest_accepted : String
  latest_wiki : String
  latest_book_changed : String
  latest_detail : String
  progress_detail : String
  update_count : Int
  review_count : Int
  no_change_count : Int
  failed_count : Int
  daemon_identity : String
  active_goal_count : Int
  live_status : String
  live_summary : String
  live_detail : String
  live_tone : String
  live_active_worker_label : String
  live_enabled_standing_goal_count : Int
  live_disabled_standing_goal_count : Int
  template_request_count : Int
  pending_template_requests : Int
  failed_template_requests : Int
  template_request_tone : String
  template_request_summary : String
  template_latest_event_summary : String
}

///|
fn operator_template_request_tone(
  pending_template_requests : Int,
  failed_template_requests : Int,
) -> String {
  if failed_template_requests > 0 {
    "alert"
  } else if pending_template_requests > 0 {
    "book"
  } else {
    "neutral"
  }
}

///|
priv struct OperatorProgressView {
  progress_detail : String
  daemon_identity : String
  active_goal_count : Int
}

///|
fn operator_progress_view(model : Model) -> OperatorProgressView {
  let next_check = standing_goal_next_check_view(model)
  {
    progress_detail: next_check.operator_detail,
    daemon_identity: match model.daemon_snapshot {
      Some(snapshot) => "\{snapshot.daemon_id} / \{snapshot.lease_owner}"
      None => "daemon waiting"
    },
    active_goal_count: match model.daemon_snapshot {
      Some(snapshot) => snapshot.active_goal_ids.length()
      None => 0
    },
  }
}

///|
fn operator_console_metrics(
  model : Model,
  workers : Array[WorkerSim],
) -> OperatorConsoleMetrics {
  let workers_summary = worker_count_summary(workers)
  let latest = latest_watcher_metric_view(latest_watcher_record(model))
  let progress = operator_progress_view(model)
  let watcher_summary = watcher_decision_summary(model)
  let live = live_autonomy_operator_view(
    model,
    fallback_active_workers=workers_summary.running,
  )
  {
    latest_decision: latest.decision,
    latest_sources: latest.sources,
    latest_checked: latest.checked,
    latest_accepted: latest.accepted,
    latest_wiki: latest.wiki,
    latest_book_changed: latest.book_changed,
    latest_detail: latest.detail,
    progress_detail: progress.progress_detail,
    update_count: watcher_summary.update_count,
    review_count: watcher_summary.review_count,
    no_change_count: watcher_summary.no_change_count,
    failed_count: watcher_summary.failed_count,
    daemon_identity: progress.daemon_identity,
    active_goal_count: progress.active_goal_count,
    live_status: live.status_label,
    live_summary: live.summary_label,
    live_detail: live.detail_label,
    live_tone: live.tone,
    live_active_worker_label: live.active_worker_label,
    live_enabled_standing_goal_count: live.enabled_standing_goal_count,
    live_disabled_standing_goal_count: live.disabled_standing_goal_count,
    template_request_count: live.template_request_count,
    pending_template_requests: live.pending_template_request_count,
    failed_template_requests: live.failed_template_request_count,
    template_request_tone: operator_template_request_tone(
      live.pending_template_request_count,
      live.failed_template_request_count,
    ),
    template_request_summary: live.template_request_summary,
    template_latest_event_summary: live.template_latest_event_summary,
  }
}
