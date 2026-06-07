///|
test "standing watch history parser reads provider decision for current task" {
  let history =
    $|# Standing Watch
    $|
    $|## Decisions
    $|
    $|### standing-watch-opc-news-tick-4
    $|
    $|- Decision: `unknown`
    $|- Delta score: `unknown`
    $|- New source count: `unknown`
    $|- Next check hint: `normal`
    $|- Summary: MoonClaw run completed
    $|
    $|### provider-standing-watch-123
    $|
    $|- Decision: `no_change`
    $|- Delta score: `9`
    $|- New source count: `0`
    $|- Next check hint: `slower`
    $|- Checked sources count: `5`
    $|- New sources found: `2`
    $|- Accepted facts count: `0`
    $|- Rejected facts count: `2`
    $|- Wiki pages changed count: `0`
    $|- Book changed: `no`
    $|- Summary: standing_goal_decision: no_change
    $|
    $|### standing-watch-opc-news-tick-3
    $|
    $|- Decision: `unknown`
  let summary = standing_watch_history_decision_summary_for_task(
    history, "standing-watch-opc-news-tick-4",
  ).unwrap()
  assert_true(summary.contains("standing_goal_decision: no_change"))
  assert_true(summary.contains("delta_score: 9"))
  assert_true(summary.contains("checked_sources_count: 5"))
  assert_true(summary.contains("accepted_facts_count: 0"))
  assert_true(summary.contains("wiki_pages_changed_count: 0"))
  assert_true(summary.contains("book_changed: no"))
  assert_true(
    summary.contains("book_watch_record_id: provider-standing-watch-123"),
  )
}

///|
test "standing watch history parser reads newest provider decision before task block exists" {
  let history =
    $|# Standing Watch
    $|
    $|## Decisions
    $|
    $|### provider-standing-watch-456
    $|
    $|- Decision: `no_change`
    $|- Delta score: `5`
    $|- New source count: `0`
    $|- Next check hint: `slower`
    $|- Checked sources count: `7`
    $|- Rejected facts count: `3`
    $|- Summary: standing_goal_decision: no_change
    $|checked_sources_count: 7
    $|rejected_facts_count: 3
    $|book_changed: no
    $|
    $|### standing-watch-opc-news-tick-4
    $|
    $|- Decision: `unknown`
  let summary = standing_watch_latest_provider_decision_summary(history).unwrap()
  assert_true(summary.contains("standing_goal_decision: no_change"))
  assert_true(summary.contains("delta_score: 5"))
  assert_true(summary.contains("checked_sources_count: 7"))
  assert_true(summary.contains("rejected_facts_count: 3"))
  assert_true(
    summary.contains("book_watch_record_id: provider-standing-watch-456"),
  )
}

///|
test "standing watch collapse removes folded provider decision block" {
  let history =
    $|# Standing Watch
    $|
    $|## Decisions
    $|
    $|### standing-watch-opc-news-tick-5
    $|
    $|- Decision: `no_change`
    $|- Summary: standing_goal_decision: no_change
    $|book_watch_record_id: provider-standing-watch-456
    $|
    $|### provider-standing-watch-456
    $|
    $|- Decision: `no_change`
    $|- Summary: standing_goal_decision: no_change
    $|
    $|### standing-watch-opc-news-tick-4
    $|
    $|- Decision: `unknown`
  let collapsed = remove_standing_watch_history_block(
    history, "provider-standing-watch-456",
  )
  assert_true(collapsed.contains("### standing-watch-opc-news-tick-5"))
  assert_true(!collapsed.contains("### provider-standing-watch-456"))
  assert_true(collapsed.contains("### standing-watch-opc-news-tick-4"))
}
