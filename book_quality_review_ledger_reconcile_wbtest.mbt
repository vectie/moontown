///|
async test "book quality ledger reconciliation aggregates changed runs" {
  let root = cleaned_book_quality_test_root(
    "/tmp/moontown-book-quality-ledger-reconcile-wbtest",
  )
  let result_dir = "\{root}/results"
  let run_path = "\{root}/book-quality/ai-review-runs.json"
  let stale = book_quality_review_run_fixture(
    "course-example",
    "\{root}/packet-stale.json",
    "\{result_dir}/course-example.md",
    Some("proposal-stale"),
    Some("run-stale-book-quality-review"),
    @book_quality.review_run_dispatched_status(),
    "started but never produced a result",
    1UL,
  )
  let queued = book_quality_review_run_fixture(
    "course-queued",
    "\{root}/packet-queued.json",
    "\{result_dir}/course-queued.md",
    None,
    None,
    @book_quality.review_run_queued_status(),
    "waiting for dispatch",
    2UL,
  )
  write_book_quality_review_run_ledger(run_path, [stale, queued])
  let written = @book_quality.reconcile_review_run_ledger_file(
    result_dir~,
    run_path~,
  )
  assert_eq(written, 0)
  let ledger_text = @fs.read_file(run_path).text()
  assert_true(ledger_text.contains("\"book_id\": \"course-example\""))
  assert_true(ledger_text.contains("\"status\": \"orphaned\""))
  assert_true(ledger_text.contains("\"book_id\": \"course-queued\""))
  assert_true(ledger_text.contains("\"status\": \"queued\""))
}
