///|
priv struct BookQualityReviewLedgerView {
  current_runs : Array[BookQualityReviewRun]
  historical_runs : Array[BookQualityReviewRun]
}

///|
fn book_quality_review_ledger_view(
  ledger : BookQualityReviewRunLedger,
  active_book_ids? : Array[String] = [],
) -> BookQualityReviewLedgerView {
  let latest_runs = current_book_quality_review_runs(ledger)
  let current_runs : Array[BookQualityReviewRun] = []
  for run in latest_runs {
    if book_quality_review_run_active_for_view(run, active_book_ids) {
      current_runs.push(run)
    }
  }
  let historical_runs : Array[BookQualityReviewRun] = []
  for run in ledger.runs {
    if book_quality_review_run_is_current(run, latest_runs) {
      if !book_quality_review_run_active_for_view(run, active_book_ids) {
        historical_runs.push(run)
      }
    } else {
      historical_runs.push(run)
    }
  }
  { current_runs, historical_runs }
}

///|
fn book_quality_review_run_active_for_view(
  run : BookQualityReviewRun,
  active_book_ids : Array[String],
) -> Bool {
  active_book_ids.is_empty() || active_book_ids.contains(run.book_id)
}

///|
fn current_book_quality_review_runs(
  ledger : BookQualityReviewRunLedger,
) -> Array[BookQualityReviewRun] {
  let current : Array[BookQualityReviewRun] = []
  for run in ledger.runs {
    replace_or_append_current_book_quality_review_run(current, run)
  }
  current
}

///|
fn replace_or_append_current_book_quality_review_run(
  current : Array[BookQualityReviewRun],
  run : BookQualityReviewRun,
) -> Unit {
  for index in 0..<current.length() {
    if current[index].book_id == run.book_id {
      current[index] = run
      return
    }
  }
  current.push(run)
}

///|
fn book_quality_review_run_is_current(
  run : BookQualityReviewRun,
  current_runs : Array[BookQualityReviewRun],
) -> Bool {
  current_runs.any(fn(current) {
    book_quality_review_run_same_record(current, run)
  })
}

///|
fn book_quality_review_run_same_record(
  left : BookQualityReviewRun,
  right : BookQualityReviewRun,
) -> Bool {
  left.book_id == right.book_id &&
  left.generated_at_ms == right.generated_at_ms &&
  left.run_id == right.run_id &&
  left.status == right.status &&
  left.summary == right.summary
}

///|
fn historical_book_quality_problem_attempt_count(
  historical_runs : Array[BookQualityReviewRun],
) -> Int {
  let mut count = 0
  for run in historical_runs {
    if review_run_problem_status(run.status) {
      count += 1
    }
  }
  count
}
