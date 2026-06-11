///|
pub async fn active_review_count(
  result_dir? : String = default_review_result_dir(),
  run_path? : String = default_review_run_path(),
) -> Int {
  let ledger = load_review_run_ledger(run_path)
  active_review_count_for_runs(ledger.runs, result_dir, @env.now())
}

///|
async fn active_review_count_for_runs(
  runs : Array[BookQualityReviewRun],
  result_dir : String,
  now_ms : UInt64,
) -> Int {
  let mut active = 0
  for run in runs {
    if review_run_active(run, result_dir, now_ms~) {
      active += 1
    }
  }
  active
}

///|
async fn review_run_active(
  run : BookQualityReviewRun,
  result_dir : String,
  now_ms? : UInt64 = @env.now(),
) -> Bool {
  let has_result = @fs.exists(review_result_path(result_dir, run.book_id)) ||
    @fs.exists(run.result_path)
  let process_alive = match run.run_id {
    Some(run_id) => @moonclaw.run_process_alive(run_id)
    None => false
  }
  review_run_active_by_observation(run, has_result~, process_alive~, now_ms~)
}
