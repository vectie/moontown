///|
priv struct BookTemplateRequestCounts {
  total : Int
  pending : Int
  failed : Int
}

///|
fn book_template_request_counts(
  status : BookTemplateRequestStatus,
) -> BookTemplateRequestCounts {
  {
    total: status.request_count,
    pending: status.pending_count + status.retry_count,
    failed: status.failed_count,
  }
}
