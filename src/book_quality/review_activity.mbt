///|
pub fn active_review_count_for_observations(
  observations : Array[BookQualityReviewRunObservation],
  now_ms : UInt64,
) -> Int {
  let mut active = 0
  for observation in observations {
    if review_run_active_by_observation(
        observation.run,
        has_result=observation.has_result,
        process_alive=observation.process_alive,
        now_ms~,
      ) {
      active += 1
    }
  }
  active
}
