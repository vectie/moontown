///|
pub async fn inspect_book_template_request_status(
  request_path? : String = default_book_template_request_path(),
) -> BookTemplateRequestStatus {
  let ledger = load_book_template_request_ledger(request_path)
  let event_path = default_book_template_request_event_path(request_path~)
  let latest_event_summary = latest_book_template_request_event_summary(
    event_path,
  )
  let counts = book_template_request_status_counts(ledger)
  {
    request_path,
    event_path,
    request_count: counts.total,
    pending_count: counts.pending,
    installed_count: counts.installed,
    failed_count: counts.failed,
    retry_count: counts.retry,
    ready: counts.failed == 0,
    summary: "book_template_requests=\{counts.total} pending=\{counts.pending} retry=\{counts.retry} installed=\{counts.installed} failed=\{counts.failed}",
    latest_event_summary,
  }
}
