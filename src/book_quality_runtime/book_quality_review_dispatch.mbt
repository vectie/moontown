///|
async fn dispatch_next_book_quality_ai_review_run(
  book_catalog_path : String,
  snapshot_path : String,
  review_dir : String,
  result_dir : String,
  run_path : String,
  run_inline : Bool,
) -> String {
  match
    book_quality_ai_review_dispatch_preflight(
      book_catalog_path, snapshot_path, review_dir, result_dir, run_path,
    ) {
    ActiveReview(active) => @book_quality.active_review_dispatch_message(active)
    NoPendingReview =>
      @book_quality.no_pending_review_dispatch_message(result_dir)
    PendingReview(score) =>
      dispatch_book_quality_ai_review_for_score(
        score, review_dir, result_dir, run_path, run_inline,
      )
  }
}

///|
priv enum BookQualityReviewDispatchPreflight {
  ActiveReview(Int)
  NoPendingReview
  PendingReview(@book_quality.BookQualityScore)
}

///|
async fn book_quality_ai_review_dispatch_preflight(
  book_catalog_path : String,
  snapshot_path : String,
  review_dir : String,
  result_dir : String,
  run_path : String,
) -> BookQualityReviewDispatchPreflight {
  ignore(reconcile_book_quality_ai_review_results(result_dir~, run_path~))
  let active = active_book_quality_review_count(result_dir, run_path)
  if active > 0 {
    return ActiveReview(active)
  }
  ignore(
    write_book_quality_review_packets(
      book_catalog_path~,
      snapshot_path~,
      review_dir~,
    ),
  )
  let audit = inspect_book_quality(book_catalog_path~, snapshot_path~)
  match first_pending_review_score(audit, result_dir) {
    Some(score) => PendingReview(score)
    None => NoPendingReview
  }
}

///|
async fn dispatch_book_quality_ai_review_for_score(
  score : @book_quality.BookQualityScore,
  review_dir : String,
  result_dir : String,
  run_path : String,
  run_inline : Bool,
) -> String {
  write_book_quality_review_moonclaw_profile(review_dir)
  let packet = @book_quality.review_packet(score, review_dir)
  let external = book_quality_review_external_packet(
    @book_quality.review_external_proposal_spec(
      packet,
      result_dir,
      @codex.codex_main_target_id(),
    ),
  )
  let packet_path = @book_quality.external_packet_path(
    review_dir,
    score.book_id,
  )
  let imported = @moonclaw.import_packet(
    external,
    packet_path,
    cwd=@book_quality.review_root(review_dir),
    home=@book_quality.moonclaw_home(review_dir),
    confirm=true,
    run_inline~,
  ) catch {
    error => {
      let run = @book_quality.blocked_review_run(
        score.book_id,
        packet_path,
        result_dir,
        error.to_string(),
        @env.now(),
      )
      append_review_run(run_path, run)
      return run.summary
    }
  }
  let run = imported_book_quality_review_run_from_receipt(
    score.book_id,
    packet_path,
    result_dir,
    imported,
    review_dir,
    run_inline,
    @env.now(),
  )
  append_review_run(run_path, run)
  "Dispatched AI semantic book-quality review for `\{score.book_id}`. \{run.summary}"
}
