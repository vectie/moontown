///|
pub fn standing_goal_registry_replace_or_append(
  goals : Array[StandingGoal],
  replacement : StandingGoal,
) -> Array[StandingGoal] {
  let updated : Array[StandingGoal] = []
  let mut replaced = false
  for goal in goals {
    if goal.id == replacement.id {
      updated.push(replacement)
      replaced = true
    } else {
      updated.push(goal)
    }
  }
  if !replaced {
    updated.push(replacement)
  }
  updated
}

///|
pub fn standing_goal_registry_merge_updates(
  latest : Array[StandingGoal],
  updated : Array[StandingGoal],
) -> Array[StandingGoal] {
  let merged : Array[StandingGoal] = []
  for goal in latest {
    match standing_goal_registry_find(updated, goal.id) {
      Some(next) => merged.push(next)
      None => merged.push(goal)
    }
  }
  for goal in updated {
    if standing_goal_registry_find(merged, goal.id) is None {
      merged.push(goal)
    }
  }
  merged
}

///|
pub fn standing_goal_registry_find(
  goals : Array[StandingGoal],
  goal_id : String,
) -> StandingGoal? {
  for goal in goals {
    if goal.id == goal_id {
      return Some(goal)
    }
  }
  None
}
