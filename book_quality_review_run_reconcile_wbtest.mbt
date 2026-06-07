///|
async test "book quality per-run reconciliation leaves non-dispatched run unchanged" {
  let root = cleaned_book_quality_test_root(
    "/tmp/moontown-book-quality-reconcile-single-wbtest",
  )
  let run = book_quality_review_run_fixture(
    "book-stable",
    "\{root}/packet.json",
    "\{root}/result.md",
    None,
    None,
    book_quality_review_run_queued_status(),
    "waiting for dispatch",
    1UL,
  )
  let result = reconcile_book_quality_review_run(
    run,
    "\{root}/results",
    root,
    ".moonclaw",
  )
  assert_eq(result.run.status, book_quality_review_run_queued_status())
  assert_eq(result.run.summary, "waiting for dispatch")
  assert_true(!result.written)
  assert_true(!result.changed)
  let unchanged = unchanged_book_quality_review_result(run)
  assert_eq(unchanged.run.status, book_quality_review_run_queued_status())
  assert_false(unchanged.written)
  assert_false(unchanged.changed)
  assert_true(
    book_quality_review_run_status_or_summary_changed(run, {
      ..run,
      summary: "changed",
    }),
  )
}

///|
test "book quality accepted review transition marks run written" {
  let run = book_quality_review_run_fixture(
    "book-accepted",
    "packet.json",
    "result.md",
    Some("proposal-accepted"),
    Some("run-accepted"),
    book_quality_review_run_dispatched_status(),
    "dispatch summary",
    1UL,
  )
  let accepted = accepted_book_quality_review_run(
    run,
    "run-accepted",
    now_ms=42UL,
  )
  assert_eq(accepted.status, book_quality_review_run_written_status())
  assert_eq(
    accepted.summary,
    harvested_book_quality_review_summary("run-accepted"),
  )
  assert_eq(accepted.generated_at_ms, 42UL)
  assert_eq(accepted.book_id, run.book_id)
}
