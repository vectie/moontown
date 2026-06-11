///|
async fn stale_review_run(
  run : BookQualityReviewRun,
  root : String,
  home : String,
  now_ms? : UInt64 = @env.now(),
) -> BookQualityReviewRun {
  match run.run_id {
    Some(run_id) => {
      if @moonclaw.run_process_alive(run_id) {
        return run
      }
      if !review_run_in_progress_status(run.status) {
        return run
      }
      if review_run_within_stale_window(run, now_ms) {
        return run
      }
      let poll = @moonclaw.poll_run(
        "book-quality-ai-review-\{run.book_id}",
        run_id,
        cwd=root,
        home~,
      )
      orphaned_review_run(run, run_id, poll.summary, now_ms~)
    }
    None => run
  }
}

///|
async fn stale_review_run_reconcile_result(
  run : BookQualityReviewRun,
  root : String,
  home : String,
  now_ms? : UInt64 = @env.now(),
) -> BookQualityReviewRunReconcileResult {
  let reconciled = stale_review_run(run, root, home, now_ms~)
  book_quality_review_run_reconcile_result(run, reconciled, written=false)
}
