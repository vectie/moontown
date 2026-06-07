///|
async test "book quality reconcile marks stale detached review orphaned" {
  let root = cleaned_book_quality_test_root(
    "/tmp/moontown-book-quality-orphan-wbtest",
  )
  let result_dir = "\{root}/book-quality/ai-review-results"
  let run_path = "\{root}/book-quality/ai-review-runs.json"
  let run = book_quality_review_run_fixture(
    "course-example",
    "\{root}/book-quality/moonclaw-packets/course-example.json",
    "\{result_dir}/course-example.md",
    Some("proposal-stale"),
    Some("run-stale-book-quality-review"),
    book_quality_review_run_dispatched_status(),
    "started but never produced a result",
    1UL,
  )
  write_book_quality_review_run_ledger(run_path, [run])
  let written = reconcile_book_quality_ai_review_results(result_dir~, run_path~)
  assert_eq(written, 0)
  let ledger = load_book_quality_review_run_ledger(run_path)
  assert_eq(ledger.runs.length(), 1)
  assert_eq(ledger.runs[0].status, book_quality_review_run_orphaned_status())
  assert_true(ledger.runs[0].summary.contains("Marked orphaned"))
  assert_true(!@fs.exists("\{result_dir}/course-example.md"))
}

///|
async test "book quality stale reconciliation result reports changed orphan" {
  let root = cleaned_book_quality_test_root(
    "/tmp/moontown-book-quality-stale-result-wbtest",
  )
  let run = book_quality_review_run_fixture(
    "course-example",
    "\{root}/packet.json",
    "\{root}/result.md",
    Some("proposal-stale"),
    Some("run-stale-book-quality-review"),
    book_quality_review_run_dispatched_status(),
    "started but never produced a result",
    1UL,
  )
  let result = stale_book_quality_review_result(
    run,
    root,
    ".moonclaw",
    now_ms=book_quality_review_stale_after_ms() + 2UL,
  )
  assert_false(result.written)
  assert_true(result.changed)
  assert_eq(result.run.status, book_quality_review_run_orphaned_status())
}
