///|
pub async fn render_book_quality_ai_review_status(
  result_dir? : String = default_book_quality_review_result_dir(),
  run_path? : String = default_book_quality_review_run_path(),
) -> String {
  ignore(reconcile_book_quality_ai_review_results(result_dir~, run_path~))
  let ledger = load_book_quality_review_run_ledger(run_path)
  let active = book_quality_ai_review_active_count(result_dir~, run_path~)
  let view = book_quality_review_ledger_view(ledger)
  [
    ..book_quality_review_status_summary_lines(
      run_path, result_dir, active, ledger, view,
    ),
    ..book_quality_review_current_section(view.current_runs),
    ..book_quality_review_historical_section(view.historical_runs),
  ].join("\n")
}

///|
fn book_quality_review_status_summary_lines(
  run_path : String,
  result_dir : String,
  active : Int,
  ledger : BookQualityReviewRunLedger,
  view : BookQualityReviewLedgerView,
) -> Array[String] {
  let historical_problem_attempts = historical_book_quality_problem_attempt_count(
    view.historical_runs,
  )
  [
    "# Book Quality AI Review Runs",
    "",
    "- run ledger: `\{run_path}`",
    "- result dir: `\{result_dir}`",
    "- active reviews: `\{active}`",
    "- runs: `\{ledger.runs.length()}`",
    "- current books: `\{view.current_runs.length()}`",
    "- historical attempts: `\{view.historical_runs.length()}`",
    "- historical problem attempts: `\{historical_problem_attempts}`",
    "",
  ]
}

///|
async fn book_quality_review_current_section(
  current_runs : Array[BookQualityReviewRun],
) -> Array[String] {
  [
    "## Current By Book",
    "",
    ..book_quality_review_run_table_lines(current_runs),
  ]
}

///|
async fn book_quality_review_historical_section(
  historical_runs : Array[BookQualityReviewRun],
) -> Array[String] {
  if historical_runs.is_empty() {
    return []
  }
  let lines : Array[String] = [
    "",
    "## Historical Attempts",
    "",
    "Historical attempts are audit trail. If a later current row is `written`, earlier `orphaned` or `blocked` rows are recovered failures, not current unresolved work.",
    "",
    ..book_quality_review_run_table_lines(historical_runs),
  ]
  lines
}

///|
async fn book_quality_review_run_table_lines(
  runs : Array[BookQualityReviewRun],
) -> Array[String] {
  let lines : Array[String] = [book_quality_review_run_table_header()]
  for run in runs {
    lines.push(book_quality_review_run_markdown_row(run))
  }
  lines
}

///|
async fn book_quality_review_run_markdown_row(
  run : BookQualityReviewRun,
) -> String {
  "|\{run.book_id}|\{run.status}|\{book_quality_review_result_state(run)}|`\{run.run_id.unwrap_or("none")}`|\{markdown_inline(run.summary)}|"
}

///|
async fn book_quality_review_result_state(run : BookQualityReviewRun) -> String {
  if @fs.exists(run.result_path) {
    book_quality_review_written_result_state()
  } else {
    book_quality_review_pending_result_state()
  }
}

///|
fn book_quality_review_run_table_header() -> String {
  [
    "| Book | Status | Result | Run | Summary |", "| --- | --- | --- | --- | --- |",
  ].join("\n")
}

///|
fn book_quality_review_written_result_state() -> String {
  book_quality_review_run_written_status()
}

///|
fn book_quality_review_pending_result_state() -> String {
  "pending"
}
