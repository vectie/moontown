///|
test "book quality review run identity ignores packet path but keeps lifecycle fields" {
  let run = book_quality_review_run_fixture(
    "book-a",
    "packet-a.json",
    "book-a.md",
    Some("proposal-a"),
    Some("run-a"),
    book_quality_review_run_written_status(),
    "summary",
    3UL,
  )
  assert_true(
    book_quality_review_run_same_record(run, {
      ..run,
      packet_path: "packet-moved.json",
    }),
  )
  assert_false(
    book_quality_review_run_same_record(run, { ..run, summary: "changed" }),
  )
  assert_false(
    book_quality_review_run_same_record(run, { ..run, generated_at_ms: 4UL }),
  )
}
