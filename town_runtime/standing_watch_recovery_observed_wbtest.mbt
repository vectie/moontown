///|
test "empty completion recovery summary exposes strict no-change accounting" {
  let summary = standing_watch_empty_completion_no_change_summary(
    "keeper-opc-watch-tick-42",
  )
  assert_true(summary.contains("standing_goal_decision: no_change"))
  assert_true(summary.contains("delta_score: 0"))
  assert_true(summary.contains("new_source_count: 0"))
  assert_true(summary.contains("next_check_hint: normal"))
  assert_true(summary.contains("checked_sources_count: 0"))
  assert_true(summary.contains("new_sources_found: 0"))
  assert_true(summary.contains("accepted_facts_count: 0"))
  assert_true(summary.contains("rejected_facts_count: 0"))
  assert_true(summary.contains("wiki_pages_changed_count: 0"))
  assert_true(summary.contains("book_changed: no"))
  assert_true(
    summary.contains("book_watch_record_id: keeper-opc-watch-tick-42"),
  )
  assert_true(summary.contains("mayor classified it as no_change"))
}

///|
test "empty completion recovery lines keep accounting order stable" {
  let lines = standing_watch_empty_completion_no_change_lines("watch-task")
  assert_eq(lines.length(), 12)
  assert_eq(lines[0], "standing_goal_decision: no_change")
  assert_eq(lines[10], "book_watch_record_id: watch-task")
  assert_eq(lines[11], standing_watch_empty_completion_no_change_reason())
}
