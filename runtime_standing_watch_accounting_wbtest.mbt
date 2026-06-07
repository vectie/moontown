///|
test "standing watch history parser reads accounting markers from summary body" {
  let history =
    $|# Standing Watch
    $|
    $|## Decisions
    $|
    $|### standing-watch-opc-news-tick-3870
    $|
    $|- Decision: `unknown`
    $|- Delta score: `unknown`
    $|- New source count: `unknown`
    $|- Next check hint: `normal`
    $|- Summary: MoonClaw run completed
    $|
    $|### provider-standing-watch-2063512028-624320892
    $|
    $|- Decision: `no_change`
    $|- Delta score: `10`
    $|- New source count: `0`
    $|- Next check hint: `slower`
    $|- Summary: standing_goal_decision: no_change
    $|delta_score: 10
    $|new_source_count: 0
    $|next_check_hint: slower
    $|checked_sources_count: 4
    $|new_sources_found: 1
    $|accepted_facts_count: 0
    $|rejected_facts_count: 1
    $|wiki_pages_changed_count: 0
    $|book_changed: no
    $|Re-checked baseline sources and rejected one inaccessible candidate.
    $|
    $|### standing-watch-opc-news-tick-3795
    $|
    $|- Decision: `unknown`
  let summary = standing_watch_history_decision_summary_for_task(
    history, "standing-watch-opc-news-tick-3870",
  ).unwrap()
  assert_true(summary.contains("checked_sources_count: 4"))
  assert_true(summary.contains("new_sources_found: 1"))
  assert_true(summary.contains("rejected_facts_count: 1"))
  assert_true(summary.contains("book_changed: no"))
  assert_true(summary.contains("Re-checked baseline sources"))
}

///|
test "standing watch history parser applies update accounting fallbacks" {
  let summary = standing_watch_summary_from_history_block(
    "provider-standing-watch-update",
    [
      "- Decision: `update`", "- Delta score: `8`", "- New source count: `3`", "- Next check hint: `normal`",
      "- Summary: New source changed the book.",
    ],
  ).unwrap()
  assert_true(summary.contains("standing_goal_decision: update"))
  assert_true(summary.contains("new_sources_found: 3"))
  assert_true(summary.contains("accepted_facts_count: 1"))
  assert_true(summary.contains("wiki_pages_changed_count: 1"))
  assert_true(summary.contains("book_changed: yes"))
  assert_true(
    summary.contains("book_watch_record_id: provider-standing-watch-update"),
  )
}
