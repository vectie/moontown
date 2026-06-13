///|
pub(all) struct BookQualityReviewRunReconcileResult {
  run : BookQualityReviewRun
  written : Bool
  changed : Bool
}

///|
fn book_quality_review_run_reconcile_result(
  before : BookQualityReviewRun,
  after : BookQualityReviewRun,
  written~ : Bool,
) -> BookQualityReviewRunReconcileResult {
  {
    run: after,
    written,
    changed: written || review_run_status_or_summary_changed(before, after),
  }
}

///|
pub fn reconcile_review_run_from_observation(
  run : BookQualityReviewRun,
  result_exists~ : Bool,
  result_content? : String = "",
  process_alive~ : Bool,
  poll_summary~ : String,
  now_ms~ : UInt64,
) -> BookQualityReviewRunReconcileResult {
  if result_exists {
    return existing_result_review_run_reconcile_result(run)
  }
  match run.run_id {
    Some(run_id) =>
      if review_result_satisfies_contract(result_content) {
        accepted_review_run_reconcile_result(run, run_id, now_ms~)
      } else {
        stale_review_run_reconcile_result_from_observation(
          run,
          process_alive~,
          poll_summary~,
          now_ms~,
        )
      }
    None => unchanged_review_run_reconcile_result(run)
  }
}

///|
fn unchanged_review_run_reconcile_result(
  run : BookQualityReviewRun,
) -> BookQualityReviewRunReconcileResult {
  book_quality_review_run_reconcile_result(run, run, written=false)
}

///|
fn existing_result_review_run_reconcile_result(
  run : BookQualityReviewRun,
) -> BookQualityReviewRunReconcileResult {
  book_quality_review_run_reconcile_result(
    run,
    corrected_terminal_review_run(run),
    written=false,
  )
}

///|
fn accepted_review_run_reconcile_result(
  run : BookQualityReviewRun,
  run_id : String,
  now_ms~ : UInt64,
) -> BookQualityReviewRunReconcileResult {
  book_quality_review_run_reconcile_result(
    run,
    accepted_review_run(run, run_id, now_ms~),
    written=true,
  )
}
