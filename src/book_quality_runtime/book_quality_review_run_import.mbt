///|
async fn imported_book_quality_review_run_from_receipt(
  book_id : String,
  packet_path : String,
  result_dir : String,
  imported : @moonclaw.ProposalImportReceipt,
  review_dir : String,
  run_inline : Bool,
  generated_at_ms : UInt64,
) -> @book_quality.BookQualityReviewRun {
  let launch_command = match imported.run_id {
    Some(run_id) if !run_inline =>
      Some(
        @moonclaw.run_confirmed_run(
          run_id,
          cwd=@book_quality.review_root(review_dir),
          home=@book_quality.moonclaw_home(review_dir),
        ),
      )
    _ => None
  }
  @book_quality.imported_review_run_from_observation(
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
