///|
pub async fn first_pending_review_score(
  audit : @book_quality.BookQualityAudit,
  result_dir : String,
) -> @book_quality.BookQualityScore? {
  @book_quality.first_pending_review_score_for_completed(
    audit,
    completed_review_book_ids(audit, result_dir),
  )
}

///|
async fn completed_review_book_ids(
  audit : @book_quality.BookQualityAudit,
  result_dir : String,
) -> Array[String] {
  let completed : Array[String] = []
  for score in audit.scores {
    if @fs.exists(@book_quality.review_result_path(result_dir, score.book_id)) {
      completed.push(score.book_id)
    }
  }
  completed
}
