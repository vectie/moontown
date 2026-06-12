///|
fn empty_runtime_status(snapshot_path : String) -> TownRuntimeStatus {
  @runtime_status_policy.empty_runtime_status(snapshot_path)
}

///|
fn empty_book_template_request_status(
  snapshot_path : String,
) -> @book_templates.BookTemplateRequestStatus {
  let request_path = @book_templates.request_path_for_snapshot(snapshot_path)
  @book_templates.empty_request_status(
    request_path~,
    event_path=@book_templates.request_event_path_for_request(request_path),
  )
}
