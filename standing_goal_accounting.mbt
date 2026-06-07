///|
priv struct StandingGoalCounts {
  total : Int
  enabled : Int
  disabled : Int
  due : Int
}

///|
fn standing_goal_counts(
  goals : Array[@core.StandingGoal],
  next_tick : Int,
) -> StandingGoalCounts {
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
