///|
pub fn blocked_review_run(
  book_id : String,
  packet_path : String,
  result_dir : String,
  error : String,
  generated_at_ms : UInt64,
) -> BookQualityReviewRun {
  review_run(
    book_id,
    packet_path,
    result_dir,
    None,
    None,
    review_run_blocked_status(),
    "MoonClaw AI review dispatch failed: \{error}",
    generated_at_ms,
  )
}

///|
pub fn imported_review_run_from_observation(
  book_id : String,
  packet_path : String,
  result_dir : String,
  proposal_id : String,
  run_id : String?,
  summary : String,
  launch_command : String?,
  generated_at_ms : UInt64,
) -> BookQualityReviewRun {
  review_run(
    book_id,
    packet_path,
    result_dir,
    Some(proposal_id),
    run_id,
    review_status_for_imported_run(run_id),
    review_summary_with_launch_command(summary, launch_command),
    generated_at_ms,
  )
}

///|
fn review_status_for_imported_run(run_id : String?) -> String {
  if run_id is Some(_) {
    review_run_dispatched_status()
  } else {
    review_run_queued_status()
  }
}

///|
fn review_summary_with_launch_command(
  summary : String,
  launch_command : String?,
) -> String {
  match launch_command {
    Some(command) => "\{summary} Detached runner: \{command}"
    None => summary
  }
}

///|
fn review_run(
  book_id : String,
  packet_path : String,
  result_dir : String,
  proposal_id : String?,
  run_id : String?,
  status : String,
  summary : String,
  generated_at_ms : UInt64,
) -> BookQualityReviewRun {
  {
    book_id,
    packet_path,
    result_path: review_result_path(result_dir, book_id),
    proposal_id,
    run_id,
    status,
    summary,
    generated_at_ms,
  }
}
