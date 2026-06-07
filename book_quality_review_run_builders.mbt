///|
fn blocked_book_quality_review_run(
  book_id : String,
  packet_path : String,
  result_dir : String,
  error : String,
) -> BookQualityReviewRun {
  book_quality_review_run(
    book_id,
    packet_path,
    result_dir,
    None,
    None,
    book_quality_review_run_blocked_status(),
    "MoonClaw AI review dispatch failed: \{error}",
    @env.now(),
  )
}

///|
async fn dispatched_book_quality_review_run(
  book_id : String,
  packet_path : String,
  result_dir : String,
  imported : @moonclaw.ProposalImportReceipt,
  review_dir : String,
  run_inline : Bool,
) -> BookQualityReviewRun {
  let launch_command = match imported.run_id {
    Some(run_id) if !run_inline =>
      Some(
        @moonclaw.run_confirmed_run(
          run_id,
          cwd=book_quality_review_root(review_dir),
          home=book_quality_moonclaw_home(review_dir),
        ),
      )
    _ => None
  }
  book_quality_review_run(
    book_id,
    packet_path,
    result_dir,
    Some(imported.proposal_id),
    imported.run_id,
    book_quality_review_status_for_imported_run(imported.run_id),
    book_quality_review_summary_with_launch_command(
      imported.summary,
      launch_command,
    ),
    @env.now(),
  )
}

///|
fn book_quality_review_status_for_imported_run(run_id : String?) -> String {
  if run_id is Some(_) {
    book_quality_review_run_dispatched_status()
  } else {
    book_quality_review_run_queued_status()
  }
}

///|
fn book_quality_review_summary_with_launch_command(
  summary : String,
  launch_command : String?,
) -> String {
  match launch_command {
    Some(command) => "\{summary} Detached runner: \{command}"
    None => summary
  }
}

///|
fn book_quality_review_run(
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
    result_path: book_quality_ai_review_result_path(result_dir, book_id),
    proposal_id,
    run_id,
    status,
    summary,
    generated_at_ms,
  }
}
