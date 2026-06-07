///|
async test "book quality treats recent detached review as active until stale" {
  let root = cleaned_book_quality_test_root(
    "/tmp/moontown-book-quality-active-wbtest",
  )
  let result_dir = "\{root}/book-quality/ai-review-results"
  let run = book_quality_review_run_fixture(
    "course-example",
    "\{root}/book-quality/moonclaw-packets/course-example.json",
    "\{result_dir}/course-example.md",
    Some("proposal-recent"),
    Some("run-recent-book-quality-review"),
    book_quality_review_run_dispatched_status(),
    "recent detached runner",
    1_000UL,
  )
  assert_true(book_quality_review_run_active(run, result_dir, now=600_999UL))
  assert_true(!book_quality_review_run_active(run, result_dir, now=601_000UL))
}

///|
test "book quality stale window helper defines active boundary" {
  let run = book_quality_review_run_fixture(
    "book-stale-window",
    "packet.json",
    "result.md",
    None,
    Some("run-stale-window"),
    book_quality_review_run_dispatched_status(),
    "recent runner",
    1_000UL,
  )
  assert_true(book_quality_review_run_within_stale_window(run, 600_999UL))
  assert_false(book_quality_review_run_within_stale_window(run, 601_000UL))
}

///|
test "book quality review run status predicates define lifecycle buckets" {
  assert_book_quality_review_run_status_traits(
    book_quality_review_run_dispatched_status(),
    book_quality_review_run_in_progress_bucket(),
    true,
    false,
    false,
  )
  assert_book_quality_review_run_status_traits(
    book_quality_review_run_queued_status(),
    book_quality_review_run_in_progress_bucket(),
    true,
    false,
    false,
  )
  assert_book_quality_review_run_status_traits(
    book_quality_review_run_running_status(),
    book_quality_review_run_in_progress_bucket(),
    true,
    false,
    false,
  )
  assert_book_quality_review_run_status_traits(
    book_quality_review_run_written_status(),
    book_quality_review_run_terminal_bucket(),
    false,
    true,
    false,
  )
  assert_book_quality_review_run_status_traits(
    book_quality_review_run_orphaned_status(),
    book_quality_review_run_problem_bucket(),
    false,
    false,
    true,
  )
  assert_book_quality_review_run_status_traits(
    book_quality_review_run_blocked_status(),
    book_quality_review_run_problem_bucket(),
    false,
    false,
    true,
  )
  assert_book_quality_review_run_status_traits(
    "surprise",
    book_quality_review_run_other_bucket(),
    false,
    false,
    false,
  )
}

///|
test "book quality review result contract requires score and role fit" {
  assert_true(
    book_quality_review_result_satisfies_contract(
      "ai_quality_score: 82\nbook_role_fit: excellent\n",
    ),
  )
  assert_true(
    !book_quality_review_result_satisfies_contract(
      "ai_quality_score: 82\nsemantic_gaps:\n- thin evidence\n",
    ),
  )
  assert_true(
    !book_quality_review_result_satisfies_contract(
      "book_role_fit: acceptable\nsemantic_gaps:\n- missing score\n",
    ),
  )
}

///|
test "book quality terminal marker classifier is explicit" {
  assert_true(
    book_quality_review_terminal_marker("Marked orphaned after stale run")
    is OrphanedReview,
  )
  assert_true(
    book_quality_review_terminal_marker(
      "MoonClaw AI review dispatch failed: denied",
    )
    is BlockedReview,
  )
  assert_true(
    book_quality_review_terminal_marker("Harvested successfully")
    is NoTerminalMarker,
  )
}

///|
test "book quality terminal result preserves failed attempt status" {
  let orphaned = corrected_terminal_book_quality_review_run(BookQualityReviewRun::{
    book_id: "book-a",
    packet_path: "packet.json",
    result_path: "result.md",
    proposal_id: None,
    run_id: Some("run-a"),
    status: book_quality_review_run_written_status(),
    summary: "Marked orphaned by Book Quality reconciliation because no result artifact was produced.",
    generated_at_ms: 1UL,
  })
  assert_eq(orphaned.status, book_quality_review_run_orphaned_status())
  let blocked = corrected_terminal_book_quality_review_run({
    ..orphaned,
    status: book_quality_review_run_written_status(),
    summary: "MoonClaw AI review dispatch failed: permission denied",
  })
  assert_eq(blocked.status, book_quality_review_run_blocked_status())
  let active = corrected_terminal_book_quality_review_run({
    ..orphaned,
    status: book_quality_review_run_dispatched_status(),
    summary: "imported and completed",
  })
  assert_eq(active.status, book_quality_review_run_written_status())
}

///|
test "book quality existing result wrapper reports terminal change" {
  let run = book_quality_review_run_fixture(
    "book-existing",
    "packet.json",
    "result.md",
    None,
    Some("run-existing"),
    book_quality_review_run_dispatched_status(),
    "imported and completed",
    1UL,
  )
  let result = existing_book_quality_review_result(run)
  assert_false(result.written)
  assert_true(result.changed)
  assert_eq(result.run.status, book_quality_review_run_written_status())
}
