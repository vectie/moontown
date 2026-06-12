///|
fn standing_goal_registry_replace_or_append(
  goals : Array[@core.StandingGoal],
  replacement : @core.StandingGoal,
) -> Array[@core.StandingGoal] {
  let updated : Array[@core.StandingGoal] = []
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
fn standing_goal_registry_merge_updates(
  latest : Array[@core.StandingGoal],
  updated : Array[@core.StandingGoal],
) -> Array[@core.StandingGoal] {
  let merged : Array[@core.StandingGoal] = []
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
fn standing_goal_registry_find(
  goals : Array[@core.StandingGoal],
  goal_id : String,
) -> @core.StandingGoal? {
  for goal in goals {
    if goal.id == goal_id {
      return Some(goal)
    }
  }
  None
}
