///|
fn book_quality_review_run_table_header() -> String {
  [
    "| Book | Status | Result | Run | Summary |", "| --- | --- | --- | --- | --- |",
  ].join("\n")
}

///|
fn review_status_summary_lines(
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
fn review_status_markdown(
  run_path : String,
  result_dir : String,
  active : Int,
  ledger : BookQualityReviewRunLedger,
  view : BookQualityReviewLedgerView,
  current_rows : Array[BookQualityReviewRunDisplayRow],
  historical_rows : Array[BookQualityReviewRunDisplayRow],
) -> String {
  [
    ..review_status_summary_lines(run_path, result_dir, active, ledger, view),
    ..review_current_section(current_rows),
    ..review_historical_section(historical_rows),
  ].join("\n")
}

///|
pub async fn review_status_markdown_from_files(
  run_path : String,
  result_dir : String,
  active_book_ids~ : Array[String],
) -> String {
  let ledger = load_review_run_ledger_file(run_path)
  let active = active_review_count(result_dir~, run_path~)
  let view = book_quality_review_ledger_view(ledger, active_book_ids~)
  review_status_markdown(
    run_path,
    result_dir,
    active,
    ledger,
    view,
    review_display_rows_for_runs(view.current_runs),
    review_display_rows_for_runs(view.historical_runs),
  )
}

///|
async fn review_display_rows_for_runs(
  runs : Array[BookQualityReviewRun],
) -> Array[BookQualityReviewRunDisplayRow] {
  let rows : Array[BookQualityReviewRunDisplayRow] = []
  for run in runs {
    rows.push(
      review_run_display_row_for_result_exists(run, @fs.exists(run.result_path)),
    )
  }
  rows
}

///|
fn book_quality_review_written_result_state() -> String {
  review_run_written_status()
}

///|
fn book_quality_review_pending_result_state() -> String {
  "pending"
}

///|
fn review_run_display_row(
  run : BookQualityReviewRun,
  result_state : String,
) -> BookQualityReviewRunDisplayRow {
  { run, result_state }
}

///|
fn review_result_state_for_exists(result_exists : Bool) -> String {
  if result_exists {
    book_quality_review_written_result_state()
  } else {
    book_quality_review_pending_result_state()
  }
}

///|
fn review_run_display_row_for_result_exists(
  run : BookQualityReviewRun,
  result_exists : Bool,
) -> BookQualityReviewRunDisplayRow {
  review_run_display_row(run, review_result_state_for_exists(result_exists))
}

///|
fn review_current_section(
  rows : Array[BookQualityReviewRunDisplayRow],
) -> Array[String] {
  ["## Current By Book", "", ..review_run_table_lines(rows)]
}

///|
fn review_historical_section(
  rows : Array[BookQualityReviewRunDisplayRow],
) -> Array[String] {
  if rows.is_empty() {
    return []
  }
  [
    "",
    "## Historical Attempts",
    "",
    "Historical attempts are audit trail. If a later current row is `written`, earlier `orphaned` or `blocked` rows are recovered failures, not current unresolved work.",
    "",
    ..review_run_table_lines(rows),
  ]
}

///|
fn review_run_table_lines(
  rows : Array[BookQualityReviewRunDisplayRow],
) -> Array[String] {
  let lines : Array[String] = [book_quality_review_run_table_header()]
  for row in rows {
    lines.push(book_quality_review_run_markdown_row(row.run, row.result_state))
  }
  lines
}

///|
fn book_quality_review_run_markdown_row(
  run : BookQualityReviewRun,
  result_state : String,
) -> String {
  "|\{run.book_id}|\{run.status}|\{result_state}|`\{run.run_id.unwrap_or("none")}`|\{book_quality_markdown_inline(run.summary)}|"
}

///|
fn book_quality_markdown_inline(text : String) -> String {
  text.replace(old="\n", new=" ").replace(old="|", new="\\|").trim().to_owned()
}
