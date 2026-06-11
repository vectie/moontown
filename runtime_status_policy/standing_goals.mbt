///|
pub fn runtime_status_standing_goal_counts(
  goals : Array[@core.StandingGoal],
  next_tick : Int,
) -> RuntimeStatusStandingGoalCounts {
  let mut enabled = 0
  let mut due = 0
  for goal in goals {
    if goal.enabled {
      enabled += 1
    }
    if goal.is_due(next_tick) {
      due += 1
    }
  }
  { total: goals.length(), enabled, disabled: goals.length() - enabled, due }
}
