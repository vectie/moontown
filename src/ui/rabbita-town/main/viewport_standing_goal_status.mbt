///|
priv struct StandingGoalSummary {
  enabled_count : Int
  disabled_count : Int
  active_goal : StandingGoalSnapshot?
}

///|
fn standing_goal_summary(model : Model) -> StandingGoalSummary {
  let mut enabled_count = 0
  let mut disabled_count = 0
  let mut active_goal : StandingGoalSnapshot? = None
  for goal in model.standing_goals {
    if goal.enabled {
      enabled_count += 1
      match active_goal {
        None => active_goal = Some(goal)
        Some(_) => ()
      }
    } else {
      disabled_count += 1
    }
  }
  { enabled_count, disabled_count, active_goal }
}

///|
priv struct StandingGoalNextCheckView {
  idle_detail : String
}

///|
fn standing_goal_next_check_view(model : Model) -> StandingGoalNextCheckView {
  let active_goal = standing_goal_summary(model).active_goal
  match active_goal {
    Some(goal) => {
      let remaining = ticks_until_next_goal_check(model, goal)
      {
        idle_detail: standing_goal_idle_wait_detail(goal, remaining),
      }
    }
    None =>
      {
        idle_detail: "Waiting for a configured standing watch. Save a watch to activate this worker.",
      }
  }
}

///|
fn standing_goal_idle_wait_detail(
  _goal : StandingGoalSnapshot,
  remaining_ticks : Int,
) -> String {
  let wait = if remaining_ticks > 0 {
    "\{remaining_ticks} town checks"
  } else {
    "the next town check"
  }
  "Waiting until \{wait}. The next due check will move a watcher into an active run."
}

///|
fn ticks_until_next_goal_check(
  model : Model,
  goal : StandingGoalSnapshot,
) -> Int {
  let remaining = goal.next_due_tick - daemon_tick_count(model)
  if remaining < 0 {
    0
  } else {
    remaining
  }
}
