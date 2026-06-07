///|
priv struct BookQualityReviewLedgerReconcileResult {
  ledger : BookQualityReviewRunLedger
  written : Int
  changed : Bool
}

///|
priv struct BookQualityReviewRunReconcileResult {
  run : BookQualityReviewRun
  written : Bool
  changed : Bool
}

///|
fn book_quality_review_ledger_reconcile_result(
  runs : Array[BookQualityReviewRun],
  written : Int,
  changed : Bool,
) -> BookQualityReviewLedgerReconcileResult {
  { ledger: BookQualityReviewRunLedger::{ runs, }, written, changed }
}

///|
fn book_quality_review_run_reconcile_written_delta(
  run_result : BookQualityReviewRunReconcileResult,
) -> Int {
  if run_result.written {
    1
  } else {
    0
  }
}

///|
fn book_quality_review_ledger_reconcile_changed_after(
  already_changed : Bool,
  run_result : BookQualityReviewRunReconcileResult,
) -> Bool {
  already_changed || run_result.changed
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
    changed: written ||
    book_quality_review_run_status_or_summary_changed(before, after),
  }
}
