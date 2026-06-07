///|
priv struct LiveAutonomyWaitingState {
  stable_waiting : Bool
  stable_waiting_observation_streak : Int
  stable_waiting_blockers : Array[String]
}

///|
fn live_autonomy_waiting_state(
  metrics : LiveAutonomyMetricCounts,
  planbook_open : Int,
  planbook_repair_active : Int,
  pending_book_template_requests : Int,
  failed_book_template_requests : Int,
  prior_stable_waiting_observation_streak : Int,
) -> LiveAutonomyWaitingState {
  let stable_waiting_blockers = live_autonomy_stable_waiting_blockers_for(
    live_autonomy_blocker_context(
      metrics, planbook_open, planbook_repair_active, pending_book_template_requests,
      failed_book_template_requests,
    ),
  )
  let stable_waiting = stable_waiting_blockers.is_empty()
  {
    stable_waiting,
    stable_waiting_observation_streak: next_live_autonomy_stable_waiting_observation_streak(
      stable_waiting, prior_stable_waiting_observation_streak,
    ),
    stable_waiting_blockers,
  }
}

///|
fn next_live_autonomy_stable_waiting_observation_streak(
  stable_waiting : Bool,
  prior_stable_waiting_observation_streak : Int,
) -> Int {
  if stable_waiting {
    prior_stable_waiting_observation_streak + 1
  } else {
    0
  }
}
