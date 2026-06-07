///|
async fn book_quality_ai_review_active_count(
  result_dir? : String = default_book_quality_review_result_dir(),
  run_path? : String = default_book_quality_review_run_path(),
) -> Int {
  let ledger = load_book_quality_review_run_ledger(run_path)
  let now = @env.now()
  let mut active = 0
  for run in ledger.runs {
    if book_quality_review_run_active(run, result_dir, now~) {
      active += 1
    }
  }
  active
}

///|
async fn book_quality_review_run_active(
  run : BookQualityReviewRun,
  result_dir : String,
  now? : UInt64 = @env.now(),
) -> Bool {
  if @fs.exists(book_quality_ai_review_result_path(result_dir, run.book_id)) ||
    @fs.exists(run.result_path) {
    return false
  }
  if !book_quality_review_run_in_progress_status(run.status) {
    return false
  }
  match run.run_id {
    Some(run_id) if @moonclaw.run_process_alive(run_id) => true
    Some(_) => book_quality_review_run_within_stale_window(run, now)
    None => book_quality_review_run_within_stale_window(run, now)
  }
}
