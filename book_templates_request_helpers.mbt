///|
priv struct BookTemplateRequestStatusCounts {
  total : Int
  pending : Int
  installed : Int
  failed : Int
  retry : Int
}

///|
fn render_book_template_request_process_summary(
  ledger : BookTemplateRequestLedger,
  processed~ : Int,
  reconciled_events~ : Int,
) -> String {
  render_book_template_request_process_summary_with_counts(
    processed~,
    reconciled_events~,
    counts=book_template_request_process_counts(ledger),
  )
}

///|
fn book_template_request_process_counts(
  ledger : BookTemplateRequestLedger,
) -> BookTemplateRequestStatusCounts {
  book_template_request_status_counts(ledger)
}

///|
fn book_template_request_status_counts(
  ledger : BookTemplateRequestLedger,
) -> BookTemplateRequestStatusCounts {
  let mut pending = 0
  let mut installed = 0
  let mut failed = 0
  let mut retry = 0
  for request in ledger.requests {
    match request.status {
      "pending" => pending += 1
      "installed" => installed += 1
      "failed" => failed += 1
      "retry" => retry += 1
      _ => ()
    }
  }
  { total: ledger.requests.length(), pending, installed, failed, retry }
}

///|
fn render_book_template_request_process_summary_with_counts(
  processed~ : Int,
  reconciled_events~ : Int,
  counts~ : BookTemplateRequestStatusCounts,
) -> String {
  [
    "Processed \{processed} book template request(s);",
    "reconciled_events=\{reconciled_events}",
    "pending=\{counts.pending}",
    "installed=\{counts.installed}",
    "failed=\{counts.failed}.",
  ].join(" ")
}

///|
fn book_template_install_summary_success(summary : String) -> Bool {
  summary.contains("Installed PDF Evidence Watch config") ||
  summary.contains("Bootstrapped PDF Evidence Watch book") ||
  summary.contains("Installed App ToolBook config") ||
  summary.contains("Bootstrapped App ToolBook")
}

///|
fn resolve_book_template_request_path(
  base_dir : String,
  path : String,
) -> String {
  if path.has_prefix("/") || base_dir == "." || base_dir == "" {
    path
  } else {
    "\{base_dir}/\{path}"
  }
}
