///|
fn count_enabled_standing_goals(goals : Array[@core.StandingGoal]) -> Int {
  let mut count = 0
  for goal in goals {
    if goal.enabled {
      count += 1
    }
  }
  count
}

///|
fn count_disabled_standing_goals(goals : Array[@core.StandingGoal]) -> Int {
  goals.length() - count_enabled_standing_goals(goals)
}
