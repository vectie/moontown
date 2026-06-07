///|
fn standing_goal_registry_upsert(
  goals : Array[@core.StandingGoal],
  replacement : @core.StandingGoal,
) -> Array[@core.StandingGoal] {
  let updated : Array[@core.StandingGoal] = []
  for goal in goals {
    if goal.id != replacement.id {
      updated.push(goal)
    }
  }
  updated.push(replacement)
  updated
}

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
fn standing_goal_registry_with_enabled(
  goal : @core.StandingGoal,
  enabled : Bool,
) -> @core.StandingGoal {
  @core.StandingGoal::new(
    id=goal.id,
    title=goal.title,
    prompt=goal.prompt,
    target_book_id=goal.target_book_id,
    cadence_ticks=goal.cadence_ticks,
    next_due_tick=goal.next_due_tick,
    last_run_tick=goal.last_run_tick,
    enabled~,
    source_policy=goal.source_policy,
    quality_threshold=goal.quality_threshold,
  )
}

///|
fn standing_goal_registry_contains(
  goals : Array[@core.StandingGoal],
  goal_id : String,
) -> Bool {
  standing_goal_registry_find(goals, goal_id) is Some(_)
}

///|
fn standing_goal_registry_enabled(
  goals : Array[@core.StandingGoal],
  goal_id : String,
) -> Bool {
  match standing_goal_registry_find(goals, goal_id) {
    Some(goal) => goal.enabled
    None => false
  }
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
