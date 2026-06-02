///|
async test "book template registry exposes pdf evidence watch template" {
  let registry = inspect_book_template_registry()
  assert_true(registry.ready)
  assert_eq(registry.missing_count, 0)
  let mut found = false
  for template in registry.templates {
    if template.template_id == "pdf-evidence-watch" {
      found = true
      assert_eq(template.book_type, "research-book")
      assert_true(template.install_command.contains("books template install"))
      assert_true(
        template.editable_files.contains("wiki/methods/analysis-method.md"),
      )
    }
  }
  assert_true(found)
}

///|
async test "book template registry reports missing manifest as not ready" {
  let registry = inspect_book_template_registry(
    registry_path="/tmp/moontown-missing-book-template-registry.json",
  )
  assert_false(registry.ready)
  assert_eq(registry.templates.length(), 0)
  assert_eq(registry.missing_count, 1)
}

///|
async test "generic book template installer dispatches pdf evidence watch" {
  let base = "/tmp/moontown-book-template-install-wbtest"
  let config_path = "\{base}/pdf-watch.json"
  let catalog_path = "\{base}/catalog.json"
  let goals_path = "\{base}/standing-goals.json"
  let method_path = "\{base}/method.md"
  let workspace_root = "\{base}/workspace"
  write_text_file(
    method_path, "# Registry Method\n\nPromote only durable deltas.",
  )
  let spec = PdfEvidenceWatchInstallSpec::{
    book_id: "research-registry-pdfs",
    title: "Registry PDF Watch",
    purpose: "Installed through generic template registry.",
    websites: ["https://example.org/registry-pdfs"],
    analysis_method: "",
    analysis_method_path: "method.md",
    cadence_ticks: 19,
    workspace_root,
  }
  write_text_file(config_path, spec.to_json().stringify(indent=2))
  let summary = install_book_template_config(
    "pdf-evidence-watch",
    config_path,
    book_catalog_path=catalog_path,
    standing_goal_path=goals_path,
  )
  assert_true(summary.contains("Installed PDF Evidence Watch config"))
  assert_true(@fs.exists("\{workspace_root}/book.json"))
  let method_text = read_text_or_empty(
    "\{workspace_root}/wiki/methods/analysis-method.md",
  )
  assert_true(method_text.contains("Registry Method"))
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
  save_book_template_request_ledger(request_path, {
    requests: [
      {
        id: "request-pdf-watch",
        template_id: "pdf-evidence-watch",
        config_path: "pdf-watch.json",
        status: "pending",
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
    @fs.exists(default_book_template_request_event_path(request_path~)),
  )
  assert_true(@fs.exists("\{workspace_root}/book.json"))
  let ledger = load_book_template_request_ledger_for_test(request_path)
  assert_eq(ledger.requests[0].status, "installed")
  assert_eq(ledger.requests[0].last_processed_tick, 42)
}

///|
async test "book template request processor backfills missing terminal events" {
  let base = "/tmp/moontown-book-template-request-event-backfill-wbtest"
  let request_path = "\{base}/book-template-requests.json"
  let event_path = default_book_template_request_event_path(request_path~)
  if @fs.exists(event_path) {
    @fs.remove(event_path) catch {
      _ => ()
    }
  }
  save_book_template_request_ledger(request_path, {
    requests: [
      {
        id: "already-installed",
        template_id: "pdf-evidence-watch",
        config_path: "\{base}/installed.json",
        status: "installed",
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

///|
async fn load_book_template_request_ledger_for_test(
  request_path : String,
) -> BookTemplateRequestLedger {
  let text = read_text_or_empty(request_path)
  let parsed = @json.parse(text) catch { _ => fail("ledger should parse") }
  @json.from_json(parsed) catch {
    _ => fail("ledger should decode")
  }
}
