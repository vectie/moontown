///|
fn operator_request_last_summary(model : Model) -> String {
  match latest_operator_request(model) {
    Some(request) => operator_request_last_summary_from_snapshot(request)
    None => operator_request_empty_last_summary()
  }
}

///|
fn operator_request_empty_last_summary() -> String {
  "No watches have been accepted in this browser session yet."
}

///|
fn operator_request_last_summary_from_snapshot(
  request : OperatorRequestSnapshot,
) -> String {
  let parts = [
    "Last accepted watch: \{request.title}",
    "for \{request.target_book_id} at \{request.created_at}.",
    "Status \{request.status}; check frequency \{request.cadence_ticks};",
    "quality \{request.quality_threshold}%.",
    "Request: \{one_line(request.prompt)}",
  ]
  parts.join(" ")
}
