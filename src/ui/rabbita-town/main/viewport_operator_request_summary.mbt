///|
fn operator_request_last_summary(model : Model) -> String {
  match latest_operator_request(model) {
    Some(request) => operator_request_last_summary_from_snapshot(request)
    None => operator_request_empty_last_summary()
  }
}

///|
fn operator_request_empty_last_summary() -> String {
  "No operator-submitted standing goals have been accepted in this browser session yet."
}

///|
fn operator_request_last_summary_from_snapshot(
  request : OperatorRequestSnapshot,
) -> String {
  let parts = [
    "Last accepted: `\{request.standing_goal_id}` (`\{request.id}`)",
    "for `\{request.target_book_id}` at \{request.created_at}.",
    "Status \{request.status}; title: \{request.title};",
    "cadence \{request.cadence_ticks}; policy \{request.source_policy};",
    "quality \{request.quality_threshold}%.",
    "Request: \{one_line(request.prompt)}",
  ]
  parts.join(" ")
}
