///|
test "operator request submit labels reflect pending state" {
  assert_eq(operator_request_submit_label(false), "Submit Standing Watch")
  assert_eq(operator_request_submit_label(true), "Submitting...")
}

///|
test "book template request submit labels reflect pending state" {
  assert_eq(book_template_request_submit_label(false), "Queue PDF Watch Book")
  assert_eq(book_template_request_submit_label(true), "Queueing...")
}

///|
test "book template target label follows package-owned inbox filename" {
  assert_eq(
    book_template_request_target_label(),
    "Writes \{@book_templates.request_file_name()}",
  )
}

///|
test "book template intro explains durable PDF evidence workflow" {
  let intro = book_template_request_intro()
  assert_true(intro.contains("fetch PDFs"))
  assert_true(intro.contains("approved websites"))
  assert_true(intro.contains("extract text"))
  assert_true(intro.contains("accepted knowledge changes"))
}

///|
test "operator request summary includes accepted request details" {
  let request : OperatorRequestSnapshot = {
    id: "request-1",
    status: "accepted",
    created_at: "2026-06-06T08:00:00Z",
    title: "Track OPC news",
    prompt: "Watch official sources.\nNotify only on source-backed change.",
    target_book_id: "research-opc",
    cadence_ticks: 60,
    source_policy: "web-first",
    quality_threshold: 85,
    standing_goal_id: "watch-opc",
  }
  let summary = operator_request_last_summary_from_snapshot(request)
  assert_true(summary.contains("`watch-opc` (`request-1`)"))
  assert_true(summary.contains("for `research-opc`"))
  assert_true(summary.contains("Status accepted"))
  assert_true(summary.contains("title: Track OPC news"))
  assert_true(summary.contains("cadence 60"))
  assert_true(summary.contains("policy web-first"))
  assert_true(summary.contains("quality 85%"))
  assert_true(summary.contains("Request: Watch official sources."))
}

///|
test "operator request empty summary is explicit" {
  assert_true(
    operator_request_empty_last_summary().contains(
      "No operator-submitted standing goals",
    ),
  )
}
