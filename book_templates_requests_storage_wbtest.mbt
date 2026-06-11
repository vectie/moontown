///|
async test "book template request ledger loader tolerates missing and malformed files" {
  let root = "/tmp/moontown-book-template-request-storage-wbtest"
  ignore_checked_command("rm", ["-rf", root])
  let missing = @book_templates.load_request_ledger("\{root}/missing.json")
  assert_eq(missing.requests.length(), 0)
  write_text_file("\{root}/bad.json", "{bad json")
  let malformed = @book_templates.load_request_ledger("\{root}/bad.json")
  assert_eq(malformed.requests.length(), 0)
  @book_templates.save_request_ledger("\{root}/requests.json", {
    requests: [
      {
        id: "request-a",
        template_id: "pdf-evidence-watch",
        config_path: "a.json",
        status: "pending",
        summary: "waiting",
        last_processed_tick: 0,
      },
      {
        id: "request-b",
        template_id: "app-tool-book",
        config_path: "b.json",
        status: "installed",
        summary: "done",
        last_processed_tick: 2,
      },
    ],
  })
  let loaded = @book_templates.load_request_ledger("\{root}/requests.json")
  assert_eq(loaded.requests.length(), 2)
  let counts = @book_templates.request_status_counts(loaded)
  assert_eq(counts.pending, 1)
  assert_eq(counts.installed, 1)
  assert_eq(counts.failed, 0)
  assert_eq(counts.retry, 0)
}

///|
test "book template request process summary centralizes status counts" {
  let ledger : @book_templates.BookTemplateRequestLedger = {
    requests: [
      {
        id: "request-a",
        template_id: "pdf-evidence-watch",
        config_path: "a.json",
        status: "pending",
        summary: "waiting",
        last_processed_tick: 0,
      },
      {
        id: "request-b",
        template_id: "app-tool-book",
        config_path: "b.json",
        status: "installed",
        summary: "done",
        last_processed_tick: 2,
      },
      {
        id: "request-c",
        template_id: "pdf-evidence-watch",
        config_path: "c.json",
        status: "failed",
        summary: "bad config",
        last_processed_tick: 3,
      },
    ],
  }
  let counts = @book_templates.request_status_counts(ledger)
  assert_eq(counts.total, 3)
  assert_eq(counts.pending, 1)
  assert_eq(counts.installed, 1)
  assert_eq(counts.failed, 1)
  assert_eq(counts.retry, 0)
  assert_eq(
    @book_templates.render_request_process_summary(
      ledger,
      processed=2,
      reconciled_events=1,
    ),
    "Processed 2 book template request(s); reconciled_events=1 pending=1 installed=1 failed=1.",
  )
}

///|
async test "book template request event ledger summarizes latest valid event" {
  let root = "/tmp/moontown-book-template-request-events-wbtest"
  ignore_checked_command("rm", ["-rf", root])
  let event_path = "\{root}/events.jsonl"
  assert_eq(@book_templates.latest_request_event_summary(event_path), "none")
  @book_templates.append_request_event(event_path, {
    id: "event-1",
    request_id: "request-a",
    template_id: "pdf-evidence-watch",
    status: "installed",
    config_path: "a.json",
    summary: "installed a",
    tick: 1,
    generated_at_ms: 10UL,
  })
  @book_templates.append_request_event(event_path, {
    id: "event-2",
    request_id: "request-b",
    template_id: "app-tool-book",
    status: "failed",
    config_path: "b.json",
    summary: "failed b",
    tick: 2,
    generated_at_ms: 20UL,
  })
  write_text_file(event_path, read_text_or_empty(event_path) + "not-json\n")
  let ids = @book_templates.load_request_event_request_ids(event_path)
  assert_true(ids.contains("request-a"))
  assert_true(ids.contains("request-b"))
  assert_eq(ids.length(), 2)
  assert_eq(
    @book_templates.latest_request_event_summary(event_path),
    "not-json",
  )
  @book_templates.append_request_event(event_path, {
    id: "event-3",
    request_id: "request-c",
    template_id: "pdf-evidence-watch",
    status: "installed",
    config_path: "c.json",
    summary: "installed c",
    tick: 3,
    generated_at_ms: 30UL,
  })
  assert_eq(
    @book_templates.latest_request_event_summary(event_path),
    "installed: `request-c` tick=3",
  )
}
