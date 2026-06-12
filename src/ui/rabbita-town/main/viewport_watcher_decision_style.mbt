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
fn watcher_decision_is_failed(decision : String) -> Bool {
  watcher_decision_kind(decision) is Failed
}

///|
fn watcher_decision_text_mentions_failed(text : String) -> Bool {
  text.contains("Failed") || text.contains("failed")
}

///|
fn watcher_decision_text_mentions_no_change(text : String) -> Bool {
  text.contains("NoChange")
}

///|
fn watcher_decision_chip_class(decision : String) -> String {
  match watcher_decision_kind(decision) {
    Update => "chip-live"
    NeedsReview => "chip-book"
    Failed => "chip-alert"
    Deferred => "chip-neutral"
    NoChange => "chip-calm"
    Other => "chip-neutral"
  }
}

///|
fn watcher_decision_class(base_class : String, decision : String) -> String {
  "\{base_class} watch-decision-\{decision}"
}
