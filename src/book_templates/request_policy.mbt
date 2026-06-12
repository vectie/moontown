///|
pub fn request_status_counts(
  ledger : BookTemplateRequestLedger,
) -> BookTemplateRequestStatusCounts {
  let mut pending = 0
  let mut installed = 0
  let mut failed = 0
  let mut retry = 0
  for request in ledger.requests {
    if request.status == request_status_pending() {
      pending += 1
    } else if request.status == request_status_installed() {
      installed += 1
    } else if request.status == request_status_failed() {
      failed += 1
    } else if request.status == request_status_retry() {
      retry += 1
    }
  }
  { total: ledger.requests.length(), pending, installed, failed, retry }
}

///|
pub fn request_status_pending() -> String {
  "pending"
}

///|
pub fn request_status_retry() -> String {
  "retry"
}

///|
pub fn request_status_installed() -> String {
  "installed"
}

///|
pub fn request_status_failed() -> String {
  "failed"
}

///|
pub fn request_status_should_install(status : String) -> Bool {
  status == request_status_pending() || status == request_status_retry()
}

///|
pub fn request_status_needs_event_reconcile(status : String) -> Bool {
  status == request_status_installed() || status == request_status_failed()
}

///|
pub fn install_status_for_summary(summary : String) -> String {
  if install_summary_success(summary) {
    request_status_installed()
  } else {
    request_status_failed()
  }
}

///|
pub fn request_after_install_result(
  request : BookTemplateRequest,
  config_path : String,
  summary : String,
  tick : Int,
) -> BookTemplateRequest {
  {
    ..request,
    config_path,
    status: install_status_for_summary(summary),
    summary,
    last_processed_tick: tick,
  }
}

///|
pub fn request_needs_event_reconcile(
  request : BookTemplateRequest,
  event_request_ids : Array[String],
) -> Bool {
  request_status_needs_event_reconcile(request.status) &&
  !event_request_ids.contains(request.id)
}

///|
pub fn request_process_result(
  request : BookTemplateRequest,
  processed~ : Bool,
  reconciled_event~ : Bool,
) -> BookTemplateRequestProcessResult {
  { request, processed, reconciled_event }
}

///|
pub fn request_processing_outcome(
  results : Array[BookTemplateRequestProcessResult],
) -> BookTemplateRequestProcessingOutcome {
  let mut processed = 0
  let mut reconciled_events = 0
  let updated : Array[BookTemplateRequest] = []
  for result in results {
    if result.processed {
      processed += 1
    }
    if result.reconciled_event {
      reconciled_events += 1
    }
    updated.push(result.request)
  }
  { ledger: { requests: updated }, processed, reconciled_events }
}

///|
pub fn request_runtime_counts(
  status : BookTemplateRequestStatus,
) -> BookTemplateRuntimeCounts {
  {
    total: status.request_count,
    pending: status.pending_count + status.retry_count,
    failed: status.failed_count,
  }
}

///|
pub fn request_status_from_counts(
  request_path~ : String,
  event_path~ : String,
  counts~ : BookTemplateRequestStatusCounts,
  latest_event_summary~ : String,
) -> BookTemplateRequestStatus {
  {
    request_path,
    event_path,
    request_count: counts.total,
    pending_count: counts.pending,
    installed_count: counts.installed,
    failed_count: counts.failed,
    retry_count: counts.retry,
    ready: request_status_ready(counts),
    summary: request_status_summary(counts),
    latest_event_summary,
  }
}

///|
pub fn empty_request_status(
  request_path~ : String,
  event_path~ : String,
) -> BookTemplateRequestStatus {
  request_status_from_counts(
    request_path~,
    event_path~,
    counts={ total: 0, pending: 0, installed: 0, failed: 0, retry: 0 },
    latest_event_summary="none",
  )
}

///|
pub fn request_status_ready(counts : BookTemplateRequestStatusCounts) -> Bool {
  counts.failed == 0
}

///|
pub fn request_status_summary(
  counts : BookTemplateRequestStatusCounts,
) -> String {
  "book_template_requests=\{counts.total} pending=\{counts.pending} retry=\{counts.retry} installed=\{counts.installed} failed=\{counts.failed}"
}

///|
pub fn render_request_process_summary(
  ledger : BookTemplateRequestLedger,
  processed~ : Int,
  reconciled_events~ : Int,
) -> String {
  render_request_process_summary_with_counts(
    processed~,
    reconciled_events~,
    counts=request_status_counts(ledger),
  )
}

///|
pub fn render_request_process_summary_with_counts(
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
pub fn render_request_status_markdown(
  status : BookTemplateRequestStatus,
  ledger : BookTemplateRequestLedger,
) -> String {
  let rows : Array[String] = []
  for request in ledger.requests {
    rows.push(
      "| `\{request.id}` | `\{request.template_id}` | `\{request.status}` | `\{request.config_path}` | \{request.summary} |",
    )
  }
  [
    "# Book Template Request Inbox",
    "",
    "- Path: `\{status.request_path}`",
    "- Ready: `\{status.ready}`",
    "- Requests: `\{status.request_count}`",
    "- Pending: `\{status.pending_count}`",
    "- Installed: `\{status.installed_count}`",
    "- Failed: `\{status.failed_count}`",
    "- Retry: `\{status.retry_count}`",
    "- Event log: `\{status.event_path}`",
    "- Latest event: \{status.latest_event_summary}",
    "",
    "| Request | Template | Status | Config | Summary |",
    "| --- | --- | --- | --- | --- |",
    if rows.is_empty() {
      "| none | none | none | none | none |"
    } else {
      rows.join("\n")
    },
  ].join("\n")
}

///|
pub fn request_event_summary(event : BookTemplateRequestEvent) -> String {
  "\{event.status}: `\{event.request_id}` tick=\{event.tick}"
}

///|
pub fn decode_request_event_line(line : String) -> BookTemplateRequestEvent? {
  let parsed = @json.parse(line) catch { _ => return None }
  Some(@json.from_json(parsed)) catch {
    _ => None
  }
}

///|
pub fn latest_request_event_summary_from_lines(lines : Array[String]) -> String {
  match lines {
    [] => "none"
    _ => {
      let latest = lines[lines.length() - 1]
      match decode_request_event_line(latest) {
        Some(event) => request_event_summary(event)
        None => latest
      }
    }
  }
}

///|
pub fn request_event_request_ids_from_lines(
  lines : Array[String],
) -> Array[String] {
  let ids : Array[String] = []
  for line in lines {
    match decode_request_event_line(line) {
      Some(event) =>
        if !ids.contains(event.request_id) {
          ids.push(event.request_id)
        }
      None => ()
    }
  }
  ids
}

///|
pub fn request_event_lines_from_text(text : String) -> Array[String] {
  let lines : Array[String] = []
  for line in text.split("\n") {
    let trimmed = line.trim()
    if !trimmed.is_empty() {
      lines.push(trimmed.to_owned())
    }
  }
  lines
}

///|
pub fn append_request_event_text(
  existing : String,
  event : BookTemplateRequestEvent,
) -> String {
  let line = event.to_json().stringify()
  if existing == "" {
    "\{line}\n"
  } else {
    "\{existing.trim_end()}\n\{line}\n"
  }
}

///|
pub fn request_event_id(
  request_id : String,
  tick : Int,
  generated_at_ms : UInt64,
) -> String {
  "\{request_id}-\{tick}-\{generated_at_ms}"
}

///|
pub fn request_reconcile_event_id(
  request_id : String,
  tick : Int,
  generated_at_ms : UInt64,
) -> String {
  "\{request_id}-reconciled-\{tick}-\{generated_at_ms}"
}

///|
pub fn request_event(
  request : BookTemplateRequest,
  tick : Int,
  generated_at_ms : UInt64,
  id~ : String,
) -> BookTemplateRequestEvent {
  {
    id,
    request_id: request.id,
    template_id: request.template_id,
    status: request.status,
    config_path: request.config_path,
    summary: request.summary,
    tick,
    generated_at_ms,
  }
}

///|
pub fn install_success_marker() -> String {
  "book_template_install_status: installed"
}

///|
pub fn install_summary_success(summary : String) -> Bool {
  summary.contains(install_success_marker())
}

///|
pub fn resolve_request_path(base_dir : String, path : String) -> String {
  if path.has_prefix("/") || base_dir == "." || base_dir == "" {
    path
  } else {
    "\{base_dir}/\{path}"
  }
}
