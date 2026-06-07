///|
pub async fn reconcile_book_quality_ai_review_results(
  result_dir? : String = default_book_quality_review_result_dir(),
  run_path? : String = default_book_quality_review_run_path(),
) -> Int {
  let ledger = load_book_quality_review_run_ledger(run_path)
  let root = book_quality_review_root_from_run_path(run_path)
  let home = book_quality_moonclaw_home_from_run_path(run_path)
  let result = reconcile_book_quality_review_ledger(
    ledger, result_dir, root, home,
  )
  if result.changed {
    write_text_file(
      run_path,
      book_quality_review_run_ledger_to_text(result.ledger),
    )
  }
  result.written
}

///|
async fn reconcile_book_quality_review_run(
  run : BookQualityReviewRun,
  result_dir : String,
  root : String,
  home : String,
) -> BookQualityReviewRunReconcileResult {
  if @fs.exists(run.result_path) {
    return existing_book_quality_review_result(run)
  }
  match run.run_id {
    Some(run_id) =>
      reconcile_book_quality_review_run_content(
        run, run_id, result_dir, root, home,
      )
    None => unchanged_book_quality_review_result(run)
  }
}

///|
fn unchanged_book_quality_review_result(
  run : BookQualityReviewRun,
) -> BookQualityReviewRunReconcileResult {
  book_quality_review_run_reconcile_result(run, run, written=false)
}

///|
fn existing_book_quality_review_result(
  run : BookQualityReviewRun,
) -> BookQualityReviewRunReconcileResult {
  let terminal = corrected_terminal_book_quality_review_run(run)
  book_quality_review_run_reconcile_result(run, terminal, written=false)
}

///|
async fn reconcile_book_quality_review_run_content(
  run : BookQualityReviewRun,
  run_id : String,
  result_dir : String,
  root : String,
  home : String,
) -> BookQualityReviewRunReconcileResult {
  let content = book_quality_review_result_content_from_run(run_id, root, home)
  if book_quality_review_result_satisfies_contract(content) {
    write_book_quality_accepted_review_result(result_dir, run, content)
    book_quality_review_run_reconcile_result(
      run,
      accepted_book_quality_review_run(run, run_id),
      written=true,
    )
  } else {
    stale_book_quality_review_result(run, root, home)
  }
}

///|
async fn stale_book_quality_review_result(
  run : BookQualityReviewRun,
  root : String,
  home : String,
  now_ms? : UInt64 = @env.now(),
) -> BookQualityReviewRunReconcileResult {
  let reconciled_run = stale_book_quality_review_run(run, root, home, now_ms~)
  book_quality_review_run_reconcile_result(run, reconciled_run, written=false)
}
