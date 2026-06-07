///|
fn book_quality_review_stale_after_ms() -> UInt64 {
  600_000UL
}

///|
fn book_quality_review_run_within_stale_window(
  run : BookQualityReviewRun,
  now_ms : UInt64,
) -> Bool {
  now_ms < run.generated_at_ms + book_quality_review_stale_after_ms()
}

///|
async fn stale_book_quality_review_run(
  run : BookQualityReviewRun,
  root : String,
  home : String,
  now_ms? : UInt64 = @env.now(),
) -> BookQualityReviewRun {
  match run.run_id {
    Some(run_id) => {
      if @moonclaw.run_process_alive(run_id) {
        return run
      }
      if !book_quality_review_run_in_progress_status(run.status) {
        return run
      }
      if book_quality_review_run_within_stale_window(run, now_ms) {
        return run
      }
      let poll = @moonclaw.poll_run(
        "book-quality-ai-review-\{run.book_id}",
        run_id,
        cwd=root,
        home~,
      )
      {
        ..run,
        status: book_quality_review_run_orphaned_status(),
        summary: if poll.summary.is_empty() {
          "MoonClaw AI semantic review run \{run_id} is stale, has no result artifact, and no live process was found; marked orphaned so governance can retry."
        } else {
          "\{poll.summary} Marked orphaned by Book Quality reconciliation because no result artifact was produced."
        },
        generated_at_ms: now_ms,
      }
    }
    None => run
  }
}
