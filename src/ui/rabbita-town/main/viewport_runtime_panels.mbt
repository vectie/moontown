///|
fn execution_stage_cards(
  executions : Array[@core.TaskExecutionRecord],
) -> Array[@rabbita.Html] {
  let summary = execution_count_summary(executions)
  [
    runtime_stat_chip("Packets", summary.packet_ready, "runtime-packets"),
    runtime_stat_chip("Imported", summary.proposal_imported, "runtime-imported"),
    runtime_stat_chip("Running", summary.active_run_flow(), "runtime-running"),
    runtime_stat_chip(
      "Persisting",
      summary.awaiting_persistence,
      "runtime-persisting",
    ),
    runtime_stat_chip("Review", summary.review_queued, "runtime-review"),
    runtime_stat_chip("Done", summary.completed, "runtime-completed"),
    runtime_stat_chip("Issues", summary.issue_count(), "runtime-blocked"),
  ]
}

///|
priv struct TownLaunchpadMapView {
  latest_decision : String
  latest_sources : String
  next_check : String
  active_work : Int
}

///|
fn town_launchpad_map_view(
  model : Model,
  executions : Array[@core.TaskExecutionRecord],
) -> TownLaunchpadMapView {
  let latest = latest_watcher_metric_view(latest_watcher_record(model))
  let executions_summary = execution_count_summary(executions)
  let next_check = standing_goal_next_check_view(model)
  {
    latest_decision: latest.decision,
    latest_sources: latest.sources,
    next_check: next_check.portal_label,
    active_work: executions_summary.total,
  }
}
