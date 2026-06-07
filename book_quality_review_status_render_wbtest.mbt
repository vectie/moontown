///|
async test "book quality status separates current success from historical failed attempts" {
  let root = cleaned_book_quality_test_root(
    "/tmp/moontown-book-quality-current-status-wbtest",
  )
  let result_dir = "\{root}/book-quality/ai-review-results"
  let run_path = "\{root}/book-quality/ai-review-runs.json"
  let old_run = book_quality_review_run_fixture(
    "wenyu-contest-express",
    "\{root}/book-quality/moonclaw-packets/contest.json",
    "\{result_dir}/wenyu-contest-express.md",
    Some("proposal-old"),
    Some("run-old"),
    book_quality_review_run_orphaned_status(),
    "Marked orphaned by Book Quality reconciliation because no result artifact was produced.",
    1UL,
  )
  let current_run = book_quality_review_run_update(
    old_run,
    proposal_id=Some("proposal-current"),
    run_id=Some("run-current"),
    status=Some(book_quality_review_run_written_status()),
    summary=Some(
      "Harvested MoonClaw AI semantic review result from run-current.",
    ),
    generated_at_ms=Some(2UL),
  )
  write_text_file(
    "\{result_dir}/wenyu-contest-express.md",
    "ai_quality_score: 82\nbook_role_fit: strong\n",
  )
  write_book_quality_review_run_ledger(run_path, [old_run, current_run])
  let status = render_book_quality_ai_review_status(result_dir~, run_path~)
  assert_true(status.contains("- current books: `1`"))
  assert_true(status.contains("- historical attempts: `1`"))
  assert_true(status.contains("- historical problem attempts: `1`"))
  assert_true(status.contains("## Current By Book"))
  assert_true(
    status.contains(
      "|wenyu-contest-express|written|written|`run-current`|Harvested MoonClaw AI semantic review result from run-current.|",
    ),
  )
  assert_true(status.contains("## Historical Attempts"))
  assert_true(
    status.contains(
      "|wenyu-contest-express|orphaned|written|`run-old`|Marked orphaned by Book Quality reconciliation because no result artifact was produced.|",
    ),
  )
}
