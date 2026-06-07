///|
async test "book quality review run table builder is shared by sections" {
  let run = book_quality_review_run_fixture(
    "book-table",
    "packet.json",
    "result.md",
    None,
    Some("run-table"),
    book_quality_review_run_queued_status(),
    "table summary",
    1UL,
  )
  let lines = book_quality_review_run_table_lines([run])
  assert_eq(lines.length(), 2)
  assert_eq(lines[0], book_quality_review_run_table_header())
  assert_eq(lines[1], "|book-table|queued|pending|`run-table`|table summary|")
}
