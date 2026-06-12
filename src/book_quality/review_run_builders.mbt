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
fn imported_review_run(
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
pub async fn imported_review_run_from_receipt(
  book_id : String,
  packet_path : String,
  result_dir : String,
  imported : @moonclaw.ProposalImportReceipt,
  review_dir : String,
  run_inline : Bool,
  generated_at_ms : UInt64,
) -> BookQualityReviewRun {
  let launch_command = match imported.run_id {
    Some(run_id) if !run_inline =>
      Some(
        @moonclaw.run_confirmed_run(
          run_id,
          cwd=review_root(review_dir),
          home=moonclaw_home(review_dir),
        ),
      )
    _ => None
  }
  imported_review_run(
    book_id,
    packet_path,
    result_dir,
    imported.proposal_id,
    imported.run_id,
    imported.summary,
    launch_command,
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
  BookQualityReviewRun::{
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
