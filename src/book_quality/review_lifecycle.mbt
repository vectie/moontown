///|
fn review_run_in_progress_status(status : String) -> Bool {
  review_run_status_bucket(status) == review_run_in_progress_bucket()
}

///|
fn review_run_problem_status(status : String) -> Bool {
  review_run_status_bucket(status) == review_run_problem_bucket()
}

///|
fn review_run_terminal_status(status : String) -> Bool {
  review_run_status_bucket(status) == review_run_terminal_bucket()
}

///|
fn review_run_status_bucket(status : String) -> String {
  if status == review_run_dispatched_status() ||
    status == review_run_queued_status() ||
    status == review_run_running_status() {
    review_run_in_progress_bucket()
  } else if status == review_run_written_status() {
    review_run_terminal_bucket()
  } else if status == review_run_orphaned_status() ||
    status == review_run_blocked_status() {
    review_run_problem_bucket()
  } else {
    review_run_other_bucket()
  }
}

///|
pub fn review_run_dispatched_status() -> String {
  "dispatched"
}

///|
pub fn review_run_queued_status() -> String {
  "queued"
}

///|
pub fn review_run_running_status() -> String {
  "running"
}

///|
pub fn review_run_written_status() -> String {
  "written"
}

///|
pub fn review_run_orphaned_status() -> String {
  "orphaned"
}

///|
pub fn review_run_blocked_status() -> String {
  "blocked"
}

///|
fn review_run_in_progress_bucket() -> String {
  "in-progress"
}

///|
fn review_run_terminal_bucket() -> String {
  "terminal"
}

///|
fn review_run_problem_bucket() -> String {
  "problem"
}

///|
fn review_run_other_bucket() -> String {
  "other"
}

///|
fn review_run_status_or_summary_changed(
  before : BookQualityReviewRun,
  after : BookQualityReviewRun,
) -> Bool {
  before.status != after.status || before.summary != after.summary
}

///|
pub fn review_result_satisfies_contract(content : String) -> Bool {
  content.contains("ai_quality_score:") && content.contains("book_role_fit:")
}

///|
priv enum ReviewTerminalMarker {
  OrphanedReview
  BlockedReview
  NoTerminalMarker
}

///|
fn review_terminal_marker(summary : String) -> ReviewTerminalMarker {
  if summary.contains("Marked orphaned") {
    OrphanedReview
  } else if summary.contains("MoonClaw AI review dispatch failed") {
    BlockedReview
  } else {
    NoTerminalMarker
  }
}

///|
fn corrected_terminal_review_run(
  run : BookQualityReviewRun,
) -> BookQualityReviewRun {
  match review_terminal_marker(run.summary) {
    OrphanedReview => { ..run, status: review_run_orphaned_status() }
    BlockedReview => { ..run, status: review_run_blocked_status() }
    NoTerminalMarker =>
      if review_run_terminal_status(run.status) {
        run
      } else if review_run_in_progress_status(run.status) {
        { ..run, status: review_run_written_status() }
      } else {
        run
      }
  }
}

///|
fn review_stale_after_ms() -> UInt64 {
  600_000UL
}

///|
fn review_run_within_stale_window(
  run : BookQualityReviewRun,
  now_ms : UInt64,
) -> Bool {
  now_ms < run.generated_at_ms + review_stale_after_ms()
}

///|
fn review_run_active_by_observation(
  run : BookQualityReviewRun,
  has_result~ : Bool,
  process_alive~ : Bool,
  now_ms~ : UInt64,
) -> Bool {
  if has_result {
    return false
  }
  if !review_run_in_progress_status(run.status) {
    return false
  }
  if process_alive {
    true
  } else {
    review_run_within_stale_window(run, now_ms)
  }
}

///|
fn accepted_review_run(
  run : BookQualityReviewRun,
  run_id : String,
  now_ms~ : UInt64,
) -> BookQualityReviewRun {
  {
    ..run,
    status: review_run_written_status(),
    summary: harvested_review_summary(run_id),
    generated_at_ms: now_ms,
  }
}

///|
fn harvested_review_summary(run_id : String) -> String {
  "Harvested MoonClaw AI semantic review result from \{run_id}."
}

///|
fn orphaned_review_run(
  run : BookQualityReviewRun,
  run_id : String,
  poll_summary : String,
  now_ms~ : UInt64,
) -> BookQualityReviewRun {
  {
    ..run,
    status: review_run_orphaned_status(),
    summary: orphaned_review_summary(run_id, poll_summary),
    generated_at_ms: now_ms,
  }
}

///|
fn orphaned_review_summary(run_id : String, poll_summary : String) -> String {
  if poll_summary.is_empty() {
    "MoonClaw AI semantic review run \{run_id} is stale, has no result artifact, and no live process was found; marked orphaned so governance can retry."
  } else {
    "\{poll_summary} Marked orphaned by Book Quality reconciliation because no result artifact was produced."
  }
}
