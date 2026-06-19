///|
pub fn standing_watch_decision_from_execution(
  execution : @core.TaskExecutionRecord,
) -> @core.WatcherDecisionKind {
  let summary = execution.summary.to_lower()
  let marker_decision = standing_watch_marker_decision(summary)
  match execution.status {
    Failed | Stale => Failed
    ReviewQueued =>
      standing_watch_review_or_marker_decision(execution, marker_decision)
    Completed =>
      standing_watch_review_or_marker_decision(execution, marker_decision)
    _ => Deferred
  }
}

///|
fn standing_watch_review_or_marker_decision(
  execution : @core.TaskExecutionRecord,
  marker_decision : @core.WatcherDecisionKind?,
) -> @core.WatcherDecisionKind {
  if marker_decision is None &&
    standing_watch_orphaned_running_failure_summary(execution.summary) {
    return Deferred
  }
  if standing_watch_operational_no_change_summary(execution.summary) {
    return NoChange
  }
  match marker_decision {
    Some(NeedsReview) =>
      if standing_watch_infrastructure_failure_summary(execution.summary) &&
        standing_watch_summary_has_zero_material_delta(execution.summary) {
        Failed
      } else {
        NeedsReview
      }
    Some(decision) => decision
    None => NeedsReview
  }
}
