///|
async test "book template request inbox reports empty ledger through shared summary" {
  let base = "/tmp/moontown-book-template-empty-request-wbtest"
  let request_path = "\{base}/book-template-requests.json"
  @book_templates.save_request_ledger(request_path, { requests: [] })
  assert_eq(
    process_book_template_requests(request_path~),
    "Processed 0 book template request(s); reconciled_events=0 pending=0 installed=0 failed=0.",
  )
}

///|
async test "book template request inbox processes pending requests" {
  let base = "/tmp/moontown-book-template-request-wbtest"
  let request_path = "\{base}/book-template-requests.json"
  let catalog_path = "\{base}/catalog.json"
  let goals_path = "\{base}/standing-goals.json"
  let config_path = "\{base}/pdf-watch.json"
  let method_path = "\{base}/method.md"
  let workspace_root = "\{base}/workspace"
  write_text_file(
    method_path, "# Request Method\n\nUpdate only on real deltas.",
  )
  let spec = PdfEvidenceWatchInstallSpec::{
    book_id: "research-request-pdfs",
    title: "Request PDF Watch",
    purpose: "Installed from the book-template request inbox.",
    websites: ["https://example.org/request-pdfs"],
    analysis_method: "",
    analysis_method_path: "method.md",
    cadence_ticks: 23,
    workspace_root,
  }
  write_text_file(config_path, spec.to_json().stringify(indent=2))
  @book_templates.save_request_ledger(request_path, {
    requests: [
      {
        id: "request-pdf-watch",
        template_id: "pdf-evidence-watch",
        config_path: "pdf-watch.json",
        status: @book_templates.request_status_pending(),
        summary: "",
        last_processed_tick: 0,
      },
    ],
  })
  let summary = process_book_template_requests(
    request_path~,
    book_catalog_path=catalog_path,
    standing_goal_path=goals_path,
    tick=42,
  )
  assert_true(summary.contains("Processed 1 book template request"))
  let status = render_book_template_request_status(request_path~)
  assert_true(status.contains("`installed`"))
  assert_true(status.contains("last_processed_tick") == false)
  assert_true(status.contains("book-template-request-events.jsonl"))
  assert_true(status.contains("installed: `request-pdf-watch` tick=42"))
  assert_true(
    @fs.exists(@book_templates.request_event_path_for_request(request_path)),
  )
  assert_true(@fs.exists("\{workspace_root}/book.json"))
  let ledger = @book_templates.load_request_ledger(request_path)
  assert_eq(
    ledger.requests[0].status,
    @book_templates.request_status_installed(),
  )
  assert_eq(ledger.requests[0].last_processed_tick, 42)
}

///|
async test "book template request inbox processes app tool book requests" {
  let base = "/tmp/moontown-app-tool-template-request-wbtest"
  let request_path = "\{base}/book-template-requests.json"
  let catalog_path = "\{base}/catalog.json"
  let goals_path = "\{base}/standing-goals.json"
  let config_path = "\{base}/app-tool.json"
  let workspace_root = "\{base}/workspace"
  let spec = @app_tool_book.AppToolBookInstallSpec::{
    book_id: "toolbook-request-app",
    title: "Request App Tool",
    purpose: "Installed from the template request inbox.",
    websites: ["https://example.org/request-tool-data"],
    analysis_method: "# Request Method",
    analysis_method_path: "",
    tool_spec: "# Request Tool Spec",
    tool_spec_path: "",
    civic_building_id: "request-tool-lab",
    cadence_ticks: 41,
    workspace_root,
  }
  write_text_file(config_path, spec.to_json().stringify(indent=2))
  @book_templates.save_request_ledger(request_path, {
    requests: [
      {
        id: "request-app-tool",
        template_id: "app-tool-book",
        config_path: "app-tool.json",
        status: @book_templates.request_status_pending(),
        summary: "",
        last_processed_tick: 0,
      },
    ],
  })
  let summary = process_book_template_requests(
    request_path~,
    book_catalog_path=catalog_path,
    standing_goal_path=goals_path,
    tick=77,
  )
  assert_true(summary.contains("Processed 1 book template request"))
  let status = render_book_template_request_status(request_path~)
  assert_true(status.contains("installed: `request-app-tool` tick=77"))
  assert_true(@fs.exists("\{workspace_root}/tool-manifest.json"))
  assert_true(@fs.exists("\{workspace_root}/app/index.html"))
}

///|
async test "book template request processor backfills missing terminal events" {
  let base = "/tmp/moontown-book-template-request-event-backfill-wbtest"
  let request_path = "\{base}/book-template-requests.json"
  let event_path = @book_templates.request_event_path_for_request(request_path)
  if @fs.exists(event_path) {
    @fs.remove(event_path) catch {
      _ => ()
    }
  }
  @book_templates.save_request_ledger(request_path, {
    requests: [
      {
        id: "already-installed",
        template_id: "pdf-evidence-watch",
        config_path: "\{base}/installed.json",
        status: @book_templates.request_status_installed(),
        summary: "Installed earlier.",
        last_processed_tick: 7,
      },
    ],
  })
  let summary = process_book_template_requests(
    request_path~,
    book_catalog_path="\{base}/catalog.json",
    standing_goal_path="\{base}/standing-goals.json",
    tick=99,
  )
  assert_true(summary.contains("Processed 0 book template request"))
  assert_true(summary.contains("reconciled_events=1"))
  let status = render_book_template_request_status(request_path~)
  assert_true(status.contains("installed: `already-installed` tick=99"))
}
