///|
async fn write_book_quality_accepted_review_result(
  result_dir : String,
  run : BookQualityReviewRun,
  content : String,
) -> Unit {
  write_text_file(
    book_quality_ai_review_result_path(result_dir, run.book_id),
    content,
  )
}

///|
fn accepted_book_quality_review_run(
  run : BookQualityReviewRun,
  run_id : String,
  now_ms? : UInt64 = @env.now(),
) -> BookQualityReviewRun {
  {
    ..run,
    status: book_quality_review_run_written_status(),
    summary: harvested_book_quality_review_summary(run_id),
    generated_at_ms: now_ms,
  }
}

///|
fn harvested_book_quality_review_summary(run_id : String) -> String {
  "Harvested MoonClaw AI semantic review result from \{run_id}."
}
