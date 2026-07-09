///|
priv enum WatcherDecisionKind {
  Update
  NeedsReview
  Failed
  Deferred
  NoChange
  Other
}

///|
fn watcher_decision_kind(decision : String) -> WatcherDecisionKind {
  match decision {
    "Update" => Update
    "NeedsReview" => NeedsReview
    "Failed" => Failed
    "Deferred" => Deferred
    "NoChange" => NoChange
    _ => Other
  }
}

///|
fn watcher_decision_text_mentions_failed(text : String) -> Bool {
  text.contains("Failed") || text.contains("failed")
}

///|
fn watcher_decision_text_mentions_no_change(text : String) -> Bool {
  text.contains("NoChange")
}
