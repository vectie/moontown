///|
fn render_operator_watch_column(
  model : Model,
  metrics : OperatorConsoleMetrics,
) -> @rabbita.Html {
  div(class="operator-watch-column", [
    render_operator_stat_grid(metrics),
    render_standing_goal_portfolio(model),
    render_watcher_timeline(model),
  ])
}

///|
fn render_operator_stat_grid(metrics : OperatorConsoleMetrics) -> @rabbita.Html {
  div(class="operator-stat-grid", [
    render_operator_stat(
      "Current workers",
      metrics.live_active_worker_label,
      metrics.live_summary,
      "live",
    ),
    render_operator_stat(
      "Live spine",
      metrics.live_status,
      metrics.live_detail,
      metrics.live_tone,
    ),
    render_operator_stat(
      "Standing watches",
      "\{metrics.live_enabled_standing_goal_count} active / \{metrics.live_disabled_standing_goal_count} archived",
      "Disabled standing goals are preserved for audit but do not consume autonomous cadence.",
      "neutral",
    ),
    render_operator_stat(
      "Book creation",
      "\{metrics.pending_template_requests} pending / \{metrics.failed_template_requests} failed",
      "Template inbox total \{metrics.template_request_count}. \{metrics.template_request_summary} Latest event: \{metrics.template_latest_event_summary}",
      metrics.template_request_tone,
    ),
    render_operator_stat(
      "Latest decision",
      metrics.latest_decision,
      metrics.latest_detail,
      if watcher_decision_is_failed(metrics.latest_decision) {
        "alert"
      } else {
        "calm"
      },
    ),
    render_operator_stat(
      "New sources",
      metrics.latest_sources,
      "Latest digest: checked \{metrics.latest_checked}, accepted \{metrics.latest_accepted}, wiki pages \{metrics.latest_wiki}, book changed \{metrics.latest_book_changed}.",
      if metrics.latest_sources == "0" {
        "neutral"
      } else {
        "live"
      },
    ),
    render_operator_stat(
      "Decision mix",
      "U\{metrics.update_count} / R\{metrics.review_count} / N\{metrics.no_change_count} / F\{metrics.failed_count}",
      metrics.progress_detail,
      "neutral",
    ),
  ])
}
