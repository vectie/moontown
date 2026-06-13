///|
pub async fn append_review_run(
  run_path : String,
  run : @book_quality.BookQualityReviewRun,
) -> Unit {
  let ledger = load_review_run_ledger_file(run_path)
  write_review_run_ledger_file(
    run_path,
    @book_quality.review_run_ledger_with_appended_run(ledger, run),
  )
}

///|
pub async fn load_review_run_ledger_file(
  run_path : String,
) -> @book_quality.BookQualityReviewRunLedger {
  if !@fs.exists(run_path) {
    return @book_quality.empty_review_run_ledger()
  }
  let text = @fs.read_file(run_path).text() catch {
    _ => return @book_quality.empty_review_run_ledger()
  }
  @book_quality.review_run_ledger_from_text(text)
}

///|
pub async fn write_review_run_ledger_file(
  run_path : String,
  ledger : @book_quality.BookQualityReviewRunLedger,
) -> Unit {
  @support.write_text_file(
    run_path,
    @book_quality.review_run_ledger_to_text(ledger),
  )
}
