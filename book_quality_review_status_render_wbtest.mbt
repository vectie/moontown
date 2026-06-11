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
    @book_quality.review_run_orphaned_status(),
    "Marked orphaned by Book Quality reconciliation because no result artifact was produced.",
    1UL,
  )
  let current_run = book_quality_review_run_update(
    old_run,
    proposal_id=Some("proposal-current"),
    run_id=Some("run-current"),
    status=Some(@book_quality.review_run_written_status()),
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

///|
async test "book quality status treats inactive smoke current rows as historical audit trail" {
  let root = cleaned_book_quality_test_root(
    "/tmp/moontown-book-quality-active-status-wbtest",
  )
  let result_dir = "\{root}/book-quality/ai-review-results"
  let run_path = "\{root}/book-quality/ai-review-runs.json"
  let catalog_path = "\{root}/moonbooks.json"
  let snapshot_path = "\{root}/town.json"
  @moonbook.save_catalog_file(catalog_path, [
    book_quality_catalog_entry(
      id="research-llm",
      name="LLM Research",
      purpose="Research how LLM systems are trained.",
      workspace_root="\{root}/books/research-llm",
      tags=["research"],
    ),
    book_quality_catalog_entry(
      id="codex-smoke-pdf-watch",
      name="Codex Smoke PDF Watch",
      purpose="Smoke test PDF watcher.",
      workspace_root="\{root}/books/codex-smoke-pdf-watch",
      tags=["research"],
    ),
  ])
  let active_run = book_quality_review_run_fixture(
    "research-llm",
    "\{root}/book-quality/moonclaw-packets/llm.json",
    "\{result_dir}/research-llm.md",
    Some("proposal-llm"),
    Some("run-llm"),
    @book_quality.review_run_written_status(),
    "Harvested MoonClaw AI semantic review result from run-llm.",
    1UL,
  )
  let smoke_run = book_quality_review_run_fixture(
    "codex-smoke-pdf-watch",
    "\{root}/book-quality/moonclaw-packets/smoke.json",
    "\{result_dir}/codex-smoke-pdf-watch.md",
    Some("proposal-smoke"),
    Some("run-smoke"),
    @book_quality.review_run_written_status(),
    "Smoke review result should remain audit trail, not active status.",
    2UL,
  )
  write_text_file(
    "\{result_dir}/research-llm.md",
    "ai_quality_score: 91\nbook_role_fit: strong\n",
  )
  write_text_file(
    "\{result_dir}/codex-smoke-pdf-watch.md",
    "ai_quality_score: 40\nbook_role_fit: smoke\n",
  )
  write_book_quality_review_run_ledger(run_path, [active_run, smoke_run])
  let status = render_book_quality_ai_review_status(
    result_dir~,
    run_path~,
    book_catalog_path=catalog_path,
    snapshot_path~,
  )
  assert_true(status.contains("- current books: `1`"))
  assert_true(status.contains("- historical attempts: `1`"))
  assert_true(status.contains("## Current By Book"))
  assert_true(
    status.contains(
      "|research-llm|written|written|`run-llm`|Harvested MoonClaw AI semantic review result from run-llm.|",
    ),
  )
  let current_section = status.split("## Historical Attempts").to_array()[0]
  assert_false(
    current_section.contains(
      "|codex-smoke-pdf-watch|written|written|`run-smoke`|Smoke review result should remain audit trail, not active status.|",
    ),
  )
  assert_true(status.contains("## Historical Attempts"))
  assert_true(
    status.contains(
      "|codex-smoke-pdf-watch|written|written|`run-smoke`|Smoke review result should remain audit trail, not active status.|",
    ),
  )
}
