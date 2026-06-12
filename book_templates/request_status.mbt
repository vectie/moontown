///|
pub async fn inspect_book_template_request_status(
  request_path? : String = request_path_for_snapshot(
    @storage.default_snapshot_path(),
  ),
) -> BookTemplateRequestStatus {
  let ledger = load_request_ledger(request_path)
  let event_path = request_event_path_for_request(request_path)
  let latest_event_summary = latest_request_event_summary(event_path)
  let counts = request_status_counts(ledger)
  request_status_from_counts(
    request_path~,
    event_path~,
    counts~,
    latest_event_summary~,
  )
}
