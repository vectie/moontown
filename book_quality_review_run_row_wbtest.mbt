///|
async test "book quality review run row reports pending and written result state" {
  let root = cleaned_book_quality_test_root(
    "/tmp/moontown-book-quality-row-wbtest",
  )
  let run = book_quality_review_run_fixture(
    "book-row",
    "\{root}/packet.json",
    "\{root}/result.md",
    None,
    None,
    book_quality_review_run_queued_status(),
    "row | summary",
    1UL,
  )
  assert_eq(
    book_quality_review_run_table_header(),
    "| Book | Status | Result | Run | Summary |\n| --- | --- | --- | --- | --- |",
  )
  assert_eq(
    book_quality_review_result_state(run),
    book_quality_review_pending_result_state(),
  )
  assert_eq(
    book_quality_review_run_markdown_row(run),
    "|book-row|queued|pending|`none`|row \\| summary|",
  )
  write_text_file("\{root}/result.md", "ai_quality_score: 80\n")
  assert_eq(
    book_quality_review_result_state(run),
    book_quality_review_written_result_state(),
  )
  assert_eq(
    book_quality_review_run_markdown_row(
      book_quality_review_run_update(run, run_id=Some("run-row")),
    ),
    "|book-row|queued|written|`run-row`|row \\| summary|",
  )
}
