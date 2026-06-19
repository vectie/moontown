///|
pub fn standing_watch_marker_value(summary : String, key : String) -> String? {
  let key_colon = "\{key}:"
  let key_equals = "\{key}="
  for raw in summary.split("\n") {
    let line = raw.trim().to_owned()
    let lower = line.to_lower()
    if lower.has_prefix(key_colon) {
      return Some(line[key_colon.length():].trim(chars=" `").to_owned())
    } else if lower.has_prefix(key_equals) {
      return Some(line[key_equals.length():].trim(chars=" `").to_owned())
    }
  }
  None
}

///|
pub fn standing_watch_marker_int(
  summary : String,
  key : String,
  fallback~ : Int,
) -> Int {
  let key_colon = "\{key}:"
  let key_equals = "\{key}="
  for raw in summary.to_lower().split("\n") {
    let line = raw.trim().to_owned()
    if line.has_prefix(key_colon) || line.has_prefix(key_equals) {
      match first_non_negative_int(line) {
        Some(value) => return value
        None => return fallback
      }
    }
  }
  fallback
}

///|
pub fn standing_watch_marker_decision(
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
    { marker: "failed", decision: Failed },
    { marker: "deferred", decision: Deferred },
    { marker: "no_change", decision: NoChange },
    { marker: "needs_review", decision: NeedsReview },
    { marker: "update", decision: Update },
  ]
}

///|
pub fn standing_watch_summary_has_decision(
  summary : String,
  value : String,
) -> Bool {
  summary.contains("standing_goal_decision: \{value}") ||
  summary.contains("standing_goal_decision=\{value}") ||
  summary.contains("decision: \{value}") ||
  summary.contains("decision=\{value}")
}

///|
pub fn standing_watch_summary_has_zero_material_delta(summary : String) -> Bool {
  standing_watch_marker_int(summary, "delta_score", fallback=0) == 0 &&
  standing_watch_marker_int(summary, "new_source_count", fallback=0) == 0
}

///|
pub fn standing_watch_execution_has_zero_material_delta(
  execution : @core.TaskExecutionRecord,
) -> Bool {
  standing_watch_delta_score(execution) == 0 &&
  standing_watch_new_source_count(execution) == 0
}

///|
pub fn standing_watch_delta_score(execution : @core.TaskExecutionRecord) -> Int {
  standing_watch_marker_int(
    execution.summary,
    "delta_score",
    fallback=if standing_watch_marker_decision(execution.summary.to_lower()) ==
      Some(Update) {
      100
    } else {
      0
    },
  )
}

///|
pub fn standing_watch_new_source_count(
  execution : @core.TaskExecutionRecord,
) -> Int {
  standing_watch_marker_int(execution.summary, "new_source_count", fallback=0)
}
