///|
fn book_quality_review_run_status_or_summary_changed(
  before : BookQualityReviewRun,
  after : BookQualityReviewRun,
) -> Bool {
  before.status != after.status || before.summary != after.summary
}

///|
fn book_quality_review_result_satisfies_contract(content : String) -> Bool {
  content.contains("ai_quality_score:") && content.contains("book_role_fit:")
}

///|
priv enum BookQualityReviewTerminalMarker {
  OrphanedReview
  BlockedReview
  NoTerminalMarker
}

///|
fn book_quality_review_terminal_marker(
  summary : String,
) -> BookQualityReviewTerminalMarker {
  if summary.contains("Marked orphaned") {
    OrphanedReview
  } else if summary.contains("MoonClaw AI review dispatch failed") {
    BlockedReview
  } else {
    NoTerminalMarker
  }
}

///|
fn corrected_terminal_book_quality_review_run(
  run : BookQualityReviewRun,
) -> BookQualityReviewRun {
  match book_quality_review_terminal_marker(run.summary) {
    OrphanedReview =>
      { ..run, status: book_quality_review_run_orphaned_status() }
    BlockedReview => { ..run, status: book_quality_review_run_blocked_status() }
    NoTerminalMarker =>
      if book_quality_review_run_terminal_status(run.status) {
        run
      } else if book_quality_review_run_in_progress_status(run.status) {
        { ..run, status: book_quality_review_run_written_status() }
      } else {
        run
      }
  }
}
