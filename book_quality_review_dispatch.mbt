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
    ActiveReview(active) => active_book_quality_review_message(active)
    NoPendingReview => no_pending_book_quality_review_message(result_dir)
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
  PendingReview(BookQualityScore)
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
  let active = book_quality_ai_review_active_count(result_dir~, run_path~)
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
  match first_pending_ai_review_book(audit, result_dir) {
    Some(score) => PendingReview(score)
    None => NoPendingReview
  }
}

///|
fn active_book_quality_review_message(active : Int) -> String {
  "AI semantic book-quality review already active; daemon will not dispatch a duplicate. active=\{active}"
}

///|
fn no_pending_book_quality_review_message(result_dir : String) -> String {
  "No pending AI semantic book-quality review remains. Results are stored under \{result_dir}."
}

///|
async fn dispatch_book_quality_ai_review_for_score(
  score : BookQualityScore,
  review_dir : String,
  result_dir : String,
  run_path : String,
  run_inline : Bool,
) -> String {
  write_book_quality_review_moonclaw_profile(review_dir)
  let packet = book_quality_review_packet(score, review_dir)
  let external = book_quality_external_review_packet(packet, result_dir)
  let packet_path = book_quality_external_packet_path(review_dir, score.book_id)
  let imported = @moonclaw.import_packet(
    external,
    packet_path,
    cwd=book_quality_review_root(review_dir),
    home=book_quality_moonclaw_home(review_dir),
    confirm=true,
    run_inline~,
  ) catch {
    error => {
      let run = blocked_book_quality_review_run(
        score.book_id,
        packet_path,
        result_dir,
        error.to_string(),
      )
      append_book_quality_review_run(run_path, run)
      return run.summary
    }
  }
  let run = dispatched_book_quality_review_run(
    score.book_id,
    packet_path,
    result_dir,
    imported,
    review_dir,
    run_inline,
  )
  append_book_quality_review_run(run_path, run)
  "Dispatched AI semantic book-quality review for `\{score.book_id}`. \{run.summary}"
}
