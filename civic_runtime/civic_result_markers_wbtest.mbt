///|
test "civic marker value parses colon equals and trims markdown wrappers" {
  let summary = [
    "civic_service_decision: `needs_review`", "book_changed=yes", "NEXT_CHECK_HINT: follow_up",
  ].join("\n")
  assert_eq(
    civic_marker_value(summary, "civic_service_decision", fallback="none"),
    "needs_review",
  )
  assert_eq(civic_marker_value(summary, "book_changed", fallback="no"), "yes")
  assert_eq(
    civic_marker_value(summary, "next_check_hint", fallback="unknown"),
    "follow_up",
  )
}

///|
test "civic marker value falls back when key is missing" {
  assert_eq(
    civic_marker_value("book_changed: yes", "missing_key", fallback="fallback"),
    "fallback",
  )
}

///|
test "civic marker int parses non-negative values or fallback" {
  let summary = ["wiki_pages_changed_count: 12", "accepted_facts_count: n/a"].join(
    "\n",
  )
  assert_eq(
    civic_marker_int(summary, "wiki_pages_changed_count", fallback=0),
    12,
  )
  assert_eq(civic_marker_int(summary, "accepted_facts_count", fallback=7), 7)
  assert_eq(civic_marker_int(summary, "missing_count", fallback=3), 3)
}
