///|
/// Claim one queued run under the Contest Express ledger lock. All callers use
/// the same store claim, so two desktop workers cannot execute the same run.
pub async fn process_next_competition_benchmark(
  path? : String = default_hackathon_path(),
  registry_path? : String = competition_runner_registry_path(),
  receipt_root? : String = @storage.moontown_product_state_dir() +
    "/contest-express/benchmark-receipts",
) -> Bool {
  let state = load_hackathons(path~)
  let now = @env.now()
  guard state.benchmark_runs
    .iter()
    .find_first(r => {
      if r.state != "queued" {
        return false
      }
      try {
        require_competition_reviewer(state, r.submission_id, r.reviewer_id, now)
        true
      } catch {
        _ => false
      }
    })
    is Some(run) else {
    return false
  }
  let claimed = apply_hackathon_action(
    "start-benchmark",
    { "run_id": run.id },
    @env.now(),
    path~,
  ) catch {
    _ => return false
  }
  let result = execute_configured_benchmark(
    claimed,
    run.id,
    registry_path~,
    receipt_root~,
  ) catch {
    error => failed_benchmark_result(claimed, run.id, error.to_string())
  }
  let _ = apply_hackathon_action(
    "record-benchmark-result",
    result.to_json(),
    @env.now(),
    path~,
  )
  true
}
