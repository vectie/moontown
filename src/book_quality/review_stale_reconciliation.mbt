///|
fn stale_review_run_from_observation(
  run : BookQualityReviewRun,
  process_alive~ : Bool,
  poll_summary~ : String,
  now_ms~ : UInt64,
) -> BookQualityReviewRun {
  match run.run_id {
    Some(run_id) => {
      if process_alive {
        return run
      }
      if !review_run_in_progress_status(run.status) {
        return run
      }
      if review_run_within_stale_window(run, now_ms) {
        return run
      }
      orphaned_review_run(run, run_id, poll_summary, now_ms~)
    }
    None => run
  }
}

///|
fn stale_review_run_reconcile_result_from_observation(
  run : BookQualityReviewRun,
  process_alive~ : Bool,
  poll_summary~ : String,
  now_ms~ : UInt64,
) -> BookQualityReviewRunReconcileResult {
  let reconciled = stale_review_run_from_observation(
    run,
    process_alive~,
    poll_summary~,
    now_ms~,
  )
  book_quality_review_run_reconcile_result(run, reconciled, written=false)
}
