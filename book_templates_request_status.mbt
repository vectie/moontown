///|
pub async fn inspect_book_template_request_status(
  request_path? : String = @book_templates.request_path_for_snapshot(
    @storage.default_snapshot_path(),
  ),
) -> @book_templates.BookTemplateRequestStatus {
  let ledger = @book_templates.load_request_ledger(request_path)
  let event_path = @book_templates.request_event_path_for_request(request_path)
  let latest_event_summary = @book_templates.latest_request_event_summary(
    event_path,
  )
  let counts = @book_templates.request_status_counts(ledger)
  @book_templates.request_status_from_counts(
    request_path~,
    event_path~,
    counts~,
    latest_event_summary~,
  )
}
