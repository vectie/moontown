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
    @book_quality.review_run_dispatched_status(),
    "started but never produced a result",
    1UL,
  )
  write_book_quality_review_run_ledger(run_path, [run])
  let written = reconcile_book_quality_ai_review_results(result_dir~, run_path~)
  assert_eq(written, 0)
  let ledger_text = @fs.read_file(run_path).text()
  assert_true(ledger_text.contains("\"status\": \"orphaned\""))
  assert_true(ledger_text.contains("Marked orphaned"))
  assert_true(!@fs.exists("\{result_dir}/course-example.md"))
}
