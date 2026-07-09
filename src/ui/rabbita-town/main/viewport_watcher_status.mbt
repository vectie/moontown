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
  review_count : Int
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
  let mut review_count = 0
  let mut failed_count = 0
  for record in model.watcher_records {
    if watcher_record_matches_goal(record, goal_id) {
      match watcher_decision_kind(record.decision) {
        NeedsReview => review_count += 1
        Failed => failed_count += 1
        Update | NoChange | Deferred | Other => ()
      }
    }
  }
  { review_count, failed_count }
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
