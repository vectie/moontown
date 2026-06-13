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
