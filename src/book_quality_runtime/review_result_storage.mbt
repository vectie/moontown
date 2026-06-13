///|
pub async fn read_review_result_text(
  result_dir : String,
  book_id : String,
) -> String {
  let path = @book_quality.review_result_path(result_dir, book_id)
  if !@fs.exists(path) {
    return ""
  }
  @fs.read_file(path).text()
}

///|
pub async fn score_book(
  entry : @moonbook.BookCatalogEntry,
  review_result_dir : String,
) -> @book_quality.BookQualityScore {
  @book_quality.score_book_with_review_text(
    entry,
    read_review_result_text(review_result_dir, entry.id),
  )
}

///|
pub async fn write_accepted_review_result(
  result_dir : String,
  run : @book_quality.BookQualityReviewRun,
  content : String,
) -> Unit {
  @support.write_text_file(
    @book_quality.review_result_path(result_dir, run.book_id),
    content,
  )
}
