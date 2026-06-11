///|
test "request status counts classify template request lifecycle" {
  let ledger : BookTemplateRequestLedger = {
    requests: [
      request("a", request_status_pending()),
      request("b", request_status_retry()),
      request("c", request_status_installed()),
      request("d", request_status_failed()),
      request("e", "ignored"),
    ],
  }
  let counts = request_status_counts(ledger)
  assert_eq(counts.total, 5)
  assert_eq(counts.pending, 1)
  assert_eq(counts.retry, 1)
  assert_eq(counts.installed, 1)
  assert_eq(counts.failed, 1)
  assert_true(request_status_should_install(request_status_pending()))
  assert_true(request_status_should_install(request_status_retry()))
  assert_false(request_status_should_install(request_status_installed()))
  assert_false(request_status_should_install(request_status_failed()))
  assert_true(request_status_needs_event_reconcile(request_status_installed()))
  assert_true(request_status_needs_event_reconcile(request_status_failed()))
  assert_false(request_status_needs_event_reconcile(request_status_pending()))
  assert_false(request_status_needs_event_reconcile(request_status_retry()))
}

///|
test "runtime counts treat retry as pending work" {
  let counts = request_runtime_counts({
    request_path: "requests.json",
    event_path: "events.jsonl",
    request_count: 4,
    pending_count: 1,
    installed_count: 1,
    failed_count: 1,
    retry_count: 1,
    ready: false,
    summary: "summary",
    latest_event_summary: "latest",
  })
  assert_eq(counts.total, 4)
  assert_eq(counts.pending, 2)
  assert_eq(counts.failed, 1)
}

///|
test "request status construction owns readiness and compact summary" {
  let counts : BookTemplateRequestStatusCounts = {
    total: 4,
    pending: 1,
    installed: 1,
    failed: 1,
    retry: 1,
  }
  let status = request_status_from_counts(
    request_path="requests.json",
    event_path="events.jsonl",
    counts~,
    latest_event_summary="installed: `a` tick=7",
  )
  assert_false(status.ready)
  assert_eq(status.request_count, 4)
  assert_eq(status.pending_count, 1)
  assert_eq(status.retry_count, 1)
  assert_eq(
    status.summary,
    "book_template_requests=4 pending=1 retry=1 installed=1 failed=1",
  )
}

///|
test "request policy owns empty request status shape" {
  let status = empty_request_status(
    request_path="requests.json",
    event_path="events.jsonl",
  )
  assert_true(status.ready)
  assert_eq(status.request_count, 0)
  assert_eq(status.pending_count, 0)
  assert_eq(status.retry_count, 0)
  assert_eq(status.installed_count, 0)
  assert_eq(status.failed_count, 0)
  assert_eq(
    status.summary,
    "book_template_requests=0 pending=0 retry=0 installed=0 failed=0",
  )
  assert_eq(status.latest_event_summary, "none")
}

///|
test "request policy renders process summary and install success" {
  let ledger : BookTemplateRequestLedger = {
    requests: [
      request("a", request_status_pending()),
      request("b", request_status_failed()),
    ],
  }
  assert_eq(
    render_request_process_summary(ledger, processed=1, reconciled_events=2),
    "Processed 1 book template request(s); reconciled_events=2 pending=1 installed=0 failed=1.",
  )
  assert_true(
    install_summary_success(
      "\{install_success_marker()}\nBootstrapped App ToolBook: x",
    ),
  )
  assert_false(install_summary_success("Bootstrapped App ToolBook: x"))
  assert_false(install_summary_success("Unknown book template: x"))
  assert_eq(
    install_status_for_summary(
      "\{install_success_marker()}\nBootstrapped App ToolBook: x",
    ),
    request_status_installed(),
  )
  assert_eq(
    install_status_for_summary("Unknown book template: x"),
    request_status_failed(),
  )
}

///|
test "request policy constructs post-install request state" {
  let source = request("request-a", request_status_pending())
  let installed = request_after_install_result(
    source,
    "/tmp/request-a.json",
    "\{install_success_marker()}\nInstalled.",
    42,
  )
  assert_eq(installed.id, "request-a")
  assert_eq(installed.config_path, "/tmp/request-a.json")
  assert_eq(installed.status, request_status_installed())
  assert_eq(installed.summary, "\{install_success_marker()}\nInstalled.")
  assert_eq(installed.last_processed_tick, 42)
  let failed = request_after_install_result(
    source, "bad.json", "bad config", 43,
  )
  assert_eq(failed.status, request_status_failed())
  assert_eq(failed.last_processed_tick, 43)
}

///|
test "request policy decides whether terminal requests need event reconcile" {
  let installed = request("request-a", request_status_installed())
  assert_true(request_needs_event_reconcile(installed, []))
  assert_false(request_needs_event_reconcile(installed, ["request-a"]))
  assert_true(
    request_needs_event_reconcile(
      request("request-b", request_status_failed()),
      ["request-a"],
    ),
  )
  assert_false(
    request_needs_event_reconcile(
      request("request-c", request_status_pending()),
      [],
    ),
  )
}

///|
test "request policy constructs process result records" {
  let source = request("request-a", request_status_installed())
  let result = request_process_result(
    source,
    processed=true,
    reconciled_event=false,
  )
  assert_eq(result.request.id, "request-a")
  assert_true(result.processed)
  assert_false(result.reconciled_event)
}

///|
test "request policy aggregates processing outcome and preserves order" {
  let installed = request("request-a", request_status_installed())
  let reconciled = request("request-b", request_status_failed())
  let unchanged = request("request-c", request_status_pending())
  let outcome = request_processing_outcome([
    request_process_result(installed, processed=true, reconciled_event=false),
    request_process_result(reconciled, processed=false, reconciled_event=true),
    request_process_result(unchanged, processed=false, reconciled_event=false),
  ])
  assert_eq(outcome.processed, 1)
  assert_eq(outcome.reconciled_events, 1)
  assert_eq(outcome.ledger.requests.length(), 3)
  assert_eq(outcome.ledger.requests[0].id, "request-a")
  assert_eq(outcome.ledger.requests[1].id, "request-b")
  assert_eq(outcome.ledger.requests[2].id, "request-c")
}

///|
test "request policy renders request status markdown" {
  let ledger : BookTemplateRequestLedger = {
    requests: [
      request("a", request_status_installed()),
      request("b", request_status_pending()),
    ],
  }
  let counts = request_status_counts(ledger)
  let status = request_status_from_counts(
    request_path="requests.json",
    event_path="events.jsonl",
    counts~,
    latest_event_summary="installed: `a` tick=9",
  )
  let text = render_request_status_markdown(status, ledger)
  assert_true(text.contains("# Book Template Request Inbox"))
  assert_true(text.contains("- Ready: `true`"))
  assert_true(text.contains("- Pending: `1`"))
  assert_true(text.contains("- Latest event: installed: `a` tick=9"))
  assert_true(text.contains("| `a` | `pdf-evidence-watch` | `installed` |"))
}

///|
test "request policy renders request event summary" {
  let event : BookTemplateRequestEvent = {
    id: "event-1",
    request_id: "request-a",
    template_id: "pdf-evidence-watch",
    status: request_status_installed(),
    config_path: "a.json",
    summary: "installed a",
    tick: 3,
    generated_at_ms: 30UL,
  }
  assert_eq(request_event_summary(event), "installed: `request-a` tick=3")
}

///|
test "request policy constructs lifecycle events from request state" {
  let source = request("request-a", request_status_installed())
  let event_id = request_event_id(source.id, 3, 30UL)
  assert_eq(event_id, "request-a-3-30")
  let event = request_event(source, 3, 30UL, id=event_id)
  assert_eq(event.id, "request-a-3-30")
  assert_eq(event.request_id, "request-a")
  assert_eq(event.template_id, "pdf-evidence-watch")
  assert_eq(event.status, request_status_installed())
  assert_eq(event.config_path, "request-a.json")
  assert_eq(event.summary, "summary")
  assert_eq(event.tick, 3)
  assert_eq(event.generated_at_ms, 30UL)
  assert_eq(
    request_reconcile_event_id(source.id, 4, 40UL),
    "request-a-reconciled-4-40",
  )
}

///|
test "request policy parses event lines and summarizes latest event" {
  let event = request_event(
    request("request-a", request_status_installed()),
    3,
    30UL,
    id="event-1",
  )
  let line = event.to_json().stringify()
  match decode_request_event_line(line) {
    Some(decoded) => assert_eq(decoded.request_id, "request-a")
    None => fail("expected event line to decode")
  }
  assert_true(decode_request_event_line("not-json") is None)
  assert_eq(latest_request_event_summary_from_lines([]), "none")
  assert_eq(
    latest_request_event_summary_from_lines([line]),
    "installed: `request-a` tick=3",
  )
  assert_eq(
    latest_request_event_summary_from_lines([line, "not-json"]),
    "not-json",
  )
  let failed_event = request_event(
    request("request-b", request_status_failed()),
    4,
    40UL,
    id="event-2",
  )
  let ids = request_event_request_ids_from_lines([
    line,
    "not-json",
    line,
    failed_event.to_json().stringify(),
  ])
  assert_eq(ids.length(), 2)
  assert_eq(ids[0], "request-a")
  assert_eq(ids[1], "request-b")
}

///|
test "request policy normalizes event log text and appends events" {
  let event = request_event(
    request("request-a", request_status_installed()),
    3,
    30UL,
    id="event-1",
  )
  assert_eq(request_event_lines_from_text(" \n\n").length(), 0)
  let normalized = request_event_lines_from_text(" one \n two\n\n")
  assert_eq(normalized.length(), 2)
  assert_eq(normalized[0], "one")
  assert_eq(normalized[1], "two")
  let first = append_request_event_text("", event)
  assert_true(first.has_suffix("\n"))
  assert_eq(request_event_lines_from_text(first).length(), 1)
  let second = append_request_event_text(first + "\n", event)
  let lines = request_event_lines_from_text(second)
  assert_eq(lines.length(), 2)
  assert_true(lines[0].contains("\"request_id\":\"request-a\""))
  assert_true(lines[1].contains("\"request_id\":\"request-a\""))
}

///|
test "request path resolution keeps absolute and local roots stable" {
  assert_eq(
    resolve_request_path("/tmp/requests", "a.json"),
    "/tmp/requests/a.json",
  )
  assert_eq(resolve_request_path("/tmp/requests", "/abs/a.json"), "/abs/a.json")
  assert_eq(resolve_request_path(".", "a.json"), "a.json")
  assert_eq(resolve_request_path("", "a.json"), "a.json")
}

///|
fn request(id : String, status : String) -> BookTemplateRequest {
  {
    id,
    template_id: "pdf-evidence-watch",
    config_path: "\{id}.json",
    status,
    summary: "summary",
    last_processed_tick: 0,
  }
}
