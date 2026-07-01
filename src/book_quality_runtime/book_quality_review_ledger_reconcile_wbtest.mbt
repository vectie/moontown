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
  let written = reconcile_book_quality_ai_review_results(result_dir~, run_path~)
  assert_eq(written, 0)
  let ledger_text = @fs.read_file(run_path).text()
  assert_true(ledger_text.contains("\"book_id\": \"course-example\""))
  assert_true(ledger_text.contains("\"status\": \"orphaned\""))
  assert_true(ledger_text.contains("\"book_id\": \"course-queued\""))
  assert_true(ledger_text.contains("\"status\": \"queued\""))
}

///|
async test "book quality runtime harvests MoonClaw result into review ledger" {
  let root = cleaned_book_quality_test_root(
    "/tmp/moontown-book-quality-runtime-harvest-wbtest",
  )
  let result_dir = "\{root}/results"
  let run_path = "\{root}/book-quality/ai-review-runs.json"
  let home = @book_quality.moonclaw_home_from_run_path(run_path)
  let workspace = "\{root}/moonclaw-workspace"
  let run = book_quality_review_run_fixture(
    "course-accepted",
    "\{root}/packet-accepted.json",
    "\{result_dir}/course-accepted.md",
    Some("proposal-accepted"),
    Some("run-accepted-book-quality-review"),
    @book_quality.review_run_dispatched_status(),
    "accepted run started",
    1UL,
  )
  write_book_quality_review_run_ledger(run_path, [run])
  @support.write_text_file(
    "\{home}/jobs/index/runs.json",
    "{ \"runs\": [{ \"id\": \"run-accepted-book-quality-review\", \"workspace_dir\": \"\{workspace}\", \"status\": \"Succeeded\", \"summary\": \"done\" }] }",
  )
  @support.write_text_file(
    "\{home}/jobs/runs/run-accepted-book-quality-review/meta.json",
    "{ \"id\": \"run-accepted-book-quality-review\", \"workspace_dir\": \"\{workspace}\", \"status\": \"Succeeded\", \"summary\": \"done\" }",
  )
  @support.write_text_file(
    "\{workspace}/result.json",
    "{\"content\":\"ai_quality_score: 92\\nbook_role_fit: strong\\n\"}",
  )
  let written = reconcile_book_quality_ai_review_results(result_dir~, run_path~)
  assert_eq(written, 1)
  assert_false(@fs.exists("\{root}/book-quality/.moonclaw"))
  let result_text = @fs.read_file("\{result_dir}/course-accepted.md").text()
  assert_true(result_text.contains("ai_quality_score: 92"))
  let ledger_text = @fs.read_file(run_path).text()
  assert_true(ledger_text.contains("\"status\": \"written\""))
  assert_true(ledger_text.contains("run-accepted-book-quality-review"))
}
