///|
fn standing_watch_marker_decision(
  summary : String,
) -> @core.WatcherDecisionKind? {
  for rule in standing_watch_marker_decision_rules() {
    if standing_watch_summary_has_decision(summary, rule.marker) {
      return Some(rule.decision)
    }
  }
  None
}

///|
priv struct StandingWatchMarkerDecisionRule {
  marker : String
  decision : @core.WatcherDecisionKind
}

///|
fn standing_watch_marker_decision_rules() -> Array[
  StandingWatchMarkerDecisionRule,
] {
  [
    { marker: "failed", decision: @core.WatcherDecisionKind::Failed },
    { marker: "deferred", decision: @core.WatcherDecisionKind::Deferred },
    { marker: "no_change", decision: @core.WatcherDecisionKind::NoChange },
    { marker: "needs_review", decision: @core.WatcherDecisionKind::NeedsReview },
    { marker: "update", decision: @core.WatcherDecisionKind::Update },
  ]
}

///|
fn standing_watch_summary_has_decision(
  summary : String,
  value : String,
) -> Bool {
  summary.contains("standing_goal_decision: \{value}") ||
  summary.contains("standing_goal_decision=\{value}") ||
  summary.contains("decision: \{value}") ||
  summary.contains("decision=\{value}")
}
