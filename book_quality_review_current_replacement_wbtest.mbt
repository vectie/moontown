///|
test "book quality current run replacement preserves first book order" {
  let current : Array[BookQualityReviewRun] = []
  let first_a = book_quality_review_run_fixture(
    "book-a",
    "a-1.json",
    "book-a.md",
    None,
    Some("run-a-1"),
    book_quality_review_run_queued_status(),
    "first a",
    1UL,
  )
  let first_b = book_quality_review_run_update(
    first_a,
    book_id=Some("book-b"),
    packet_path=Some("b-1.json"),
    result_path=Some("book-b.md"),
    run_id=Some("run-b-1"),
    summary=Some("first b"),
    generated_at_ms=Some(2UL),
  )
  let latest_a = book_quality_review_run_update(
    first_a,
    packet_path=Some("a-2.json"),
    run_id=Some("run-a-2"),
    status=Some(book_quality_review_run_written_status()),
    summary=Some("latest a"),
    generated_at_ms=Some(3UL),
  )
  replace_or_append_current_book_quality_review_run(current, first_a)
  replace_or_append_current_book_quality_review_run(current, first_b)
  replace_or_append_current_book_quality_review_run(current, latest_a)
  assert_eq(current.length(), 2)
  assert_eq(current[0].book_id, "book-a")
  assert_true(current[0].run_id == Some("run-a-2"))
  assert_eq(current[1].book_id, "book-b")
  assert_true(current[1].run_id == Some("run-b-1"))
}
