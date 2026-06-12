///|
fn latest_watcher_record(model : Model) -> WatcherRunRecordSnapshot? {
  if model.watcher_records.is_empty() {
    None
  } else {
    Some(model.watcher_records[model.watcher_records.length() - 1])
  }
}

///|
fn latest_watcher_record_for_goal(
  model : Model,
  goal_id : String,
) -> WatcherRunRecordSnapshot? {
  let mut found : WatcherRunRecordSnapshot? = None
  for record in model.watcher_records {
    if record.goal_id == goal_id {
      found = Some(record)
    }
  }
  found
}

///|
fn latest_operator_request(model : Model) -> OperatorRequestSnapshot? {
  if model.operator_requests.is_empty() {
    None
  } else {
    Some(model.operator_requests[model.operator_requests.length() - 1])
  }
}

///|
priv struct WatcherDecisionSummary {
  update_count : Int
  review_count : Int
  no_change_count : Int
  failed_count : Int
}

///|
fn watcher_decision_summary(model : Model) -> WatcherDecisionSummary {
  watcher_decision_summary_for_goal(model, None)
}

///|
fn watcher_decision_summary_for_goal(
  model : Model,
  goal_id : String?,
) -> WatcherDecisionSummary {
  let mut update_count = 0
  let mut review_count = 0
  let mut no_change_count = 0
  let mut failed_count = 0
  for record in model.watcher_records {
    if watcher_record_matches_goal(record, goal_id) {
      match watcher_decision_kind(record.decision) {
        Update => update_count += 1
        NeedsReview => review_count += 1
        NoChange => no_change_count += 1
        Failed => failed_count += 1
        Deferred | Other => ()
      }
    }
  }
  { update_count, review_count, no_change_count, failed_count }
}

///|
fn watcher_record_matches_goal(
  record : WatcherRunRecordSnapshot,
  goal_id : String?,
) -> Bool {
  match goal_id {
    Some(id) => record.goal_id == id
    None => true
  }
}

///|
fn watcher_record_count_for_goal(model : Model, goal_id : String) -> Int {
  let mut count = 0
  for record in model.watcher_records {
    if record.goal_id == goal_id {
      count += 1
    }
  }
  count
}

///|
fn watcher_metric_value(value : Int?) -> String {
  match value {
    Some(count) => count.to_string()
    None => "n/a"
  }
}

///|
fn watcher_book_changed_value(value : String?) -> String {
  match value {
    Some(flag) => flag
    None => "unknown"
  }
}

///|
fn one_line(text : String) -> String {
  for line in text.split("\n") {
    return line.trim().to_owned()
  }
  text
}

///|
priv enum RequestStatusTone {
  RequestAlert
  RequestCalm
  RequestNeutral
}

///|
fn request_status_tone_kind(status : String) -> RequestStatusTone {
  if status.contains("failed") || status.contains("Failed") {
    RequestAlert
  } else if status.contains("Accepted") || status.contains("Ready") {
    RequestCalm
  } else {
    RequestNeutral
  }
}

///|
fn request_status_tone_from_kind(kind : RequestStatusTone) -> String {
  match kind {
    RequestAlert => "alert"
    RequestCalm => "calm"
    RequestNeutral => "neutral"
  }
}

///|
fn request_status_tone(status : String) -> String {
  request_status_tone_from_kind(request_status_tone_kind(status))
}
