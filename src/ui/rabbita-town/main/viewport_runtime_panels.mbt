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
