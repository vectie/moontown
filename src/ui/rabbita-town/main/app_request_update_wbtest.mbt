///|
test "request readiness treats whitespace as missing text" {
  assert_true(!has_text(""))
  assert_true(!has_text("   \n  "))
  assert_true(has_text(" watch OPC "))
}

///|
test "request submission models expose clear ready and missing states" {
  let model = init_model()
  let operator_submitting = operator_request_submitting_model(model)
  assert_true(operator_submitting.request_submitting)
  assert_true(operator_submitting.request_status.contains("Saving this watch"))
  let operator_missing = operator_request_missing_required_fields_model(model)
  assert_true(operator_missing.request_status.contains("title and a request"))
  let book_submitting = book_template_request_submitting_model(model)
  assert_true(book_submitting.book_request_submitting)
  assert_true(
    book_submitting.book_request_status.contains(
      "Queueing this PDF Evidence Watch book",
    ),
  )
  let book_missing = book_template_request_missing_required_fields_model(model)
  assert_true(book_missing.book_request_status.contains("title"))
  assert_true(book_missing.book_request_status.contains("website"))
}

///|
test "request result parser handles invalid and mismatched json" {
  let invalid = parse_request_submit_result("{bad json")
  assert_true(!invalid.ok)
  assert_eq(invalid.error.unwrap(), "Request endpoint returned invalid JSON.")
  let mismatched = parse_request_submit_result("{\"ok\":\"yes\"}")
  assert_true(!mismatched.ok)
  assert_eq(
    mismatched.error.unwrap(),
    "Request endpoint response did not match the expected contract.",
  )
}

///|
test "request status message helpers keep operator and book paths distinct" {
  assert_eq(
    operator_request_success_status("goal-opc", "request-1", "accepted"),
    "Watch accepted. Moontown will run it on the next check.",
  )
  assert_eq(
    operator_request_failure_status("network error"),
    "Could not save the watch: network error",
  )
  assert_eq(
    book_template_request_success_status("book-request-1", "pending"),
    "Book request queued. Moontown will install it through the book workflow.",
  )
  assert_eq(
    book_template_request_failure_status("missing website"),
    "Could not queue the book request: missing website",
  )
}

///|
test "operator request result model clears submit flag and refreshes ledgers" {
  let model = { ..init_model(), request_submitting: true }
  let next = operator_request_success_model(
    model, "goal-opc", "request-1", "accepted",
  )
  assert_true(!next.request_submitting)
  assert_true(next.request_status.contains("Watch accepted"))
  assert_true(!next.request_status.contains("request-1"))
  assert_eq(next.standing_goals_version, standing_goals_version())
  assert_eq(next.operator_requests_version, operator_requests_version())
}

///|
test "book template result model clears submit flag and refreshes live autonomy" {
  let model = { ..init_model(), book_request_submitting: true }
  let next = book_template_request_success_model(
    model, "book-request-1", "pending",
  )
  assert_true(!next.book_request_submitting)
  assert_true(next.book_request_status.contains("Book request queued"))
  assert_true(!next.book_request_status.contains("book-request-1"))
  assert_eq(next.live_autonomy_version, live_autonomy_version())
}
