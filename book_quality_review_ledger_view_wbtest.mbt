///|
test "book quality review ledger view separates latest current runs from history" {
  let old_a = book_quality_review_run_fixture(
    "book-a",
    "a-old.json",
    "book-a.md",
    Some("proposal-a-old"),
    Some("run-a-old"),
    book_quality_review_run_orphaned_status(),
    "old failure",
    1UL,
  )
  let current_b = book_quality_review_run_fixture(
    "book-b",
    "b.json",
    "book-b.md",
    Some("proposal-b"),
    Some("run-b"),
    book_quality_review_run_written_status(),
    "current b",
    2UL,
  )
  let current_a = book_quality_review_run_update(
    old_a,
    packet_path=Some("a-current.json"),
    proposal_id=Some("proposal-a-current"),
    run_id=Some("run-a-current"),
    status=Some(book_quality_review_run_written_status()),
    summary=Some("current a"),
    generated_at_ms=Some(3UL),
  )
  let view = book_quality_review_ledger_view(BookQualityReviewRunLedger::{
    runs: [old_a, current_b, current_a],
  })
  assert_eq(view.current_runs.length(), 2)
  assert_eq(view.current_runs[0].book_id, "book-a")
  assert_true(view.current_runs[0].run_id == Some("run-a-current"))
  assert_eq(view.current_runs[1].book_id, "book-b")
  assert_eq(view.historical_runs.length(), 1)
  assert_true(view.historical_runs[0].run_id == Some("run-a-old"))
  assert_eq(
    historical_book_quality_problem_attempt_count(view.historical_runs),
    1,
  )
}
