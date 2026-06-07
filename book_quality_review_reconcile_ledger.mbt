///|
async fn reconcile_book_quality_review_ledger(
  ledger : BookQualityReviewRunLedger,
  result_dir : String,
  root : String,
  home : String,
) -> BookQualityReviewLedgerReconcileResult {
  let reconciled : Array[BookQualityReviewRun] = []
  let mut written = 0
  let mut changed = false
  for run in ledger.runs {
    let result = reconcile_book_quality_review_run(run, result_dir, root, home)
    reconciled.push(result.run)
    written += book_quality_review_run_reconcile_written_delta(result)
    changed = book_quality_review_ledger_reconcile_changed_after(
      changed, result,
    )
  }
  book_quality_review_ledger_reconcile_result(reconciled, written, changed)
}
