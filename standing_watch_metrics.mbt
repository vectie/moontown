///|
fn standing_watch_summary_has_zero_material_delta(summary : String) -> Bool {
  standing_watch_marker_int(summary, "delta_score", fallback=0) == 0 &&
  standing_watch_marker_int(summary, "new_source_count", fallback=0) == 0
}

///|
fn standing_watch_execution_has_zero_material_delta(
  execution : @core.TaskExecutionRecord,
) -> Bool {
  standing_watch_delta_score(execution) == 0 &&
  standing_watch_new_source_count(execution) == 0
}

///|
fn standing_watch_delta_score(execution : @core.TaskExecutionRecord) -> Int {
  standing_watch_marker_int(
    execution.summary,
    "delta_score",
    fallback=if standing_watch_decision_from_execution(execution) ==
      @core.WatcherDecisionKind::Update {
      100
    } else {
      0
    },
  )
}

///|
fn standing_watch_new_source_count(
  execution : @core.TaskExecutionRecord,
) -> Int {
  standing_watch_marker_int(execution.summary, "new_source_count", fallback=0)
}
