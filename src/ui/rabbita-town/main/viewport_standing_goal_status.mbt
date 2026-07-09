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
  operator_detail : String
  portal_label : String
  idle_detail : String
}

///|
fn standing_goal_next_check_view(model : Model) -> StandingGoalNextCheckView {
  let active_goal = standing_goal_summary(model).active_goal
  match active_goal {
    Some(goal) => {
      let remaining = ticks_until_next_goal_check(model, goal)
      {
        operator_detail: "Next check in \{remaining} ticks. Town check \{daemon_tick_count(model)}.",
        portal_label: "\{remaining} ticks",
        idle_detail: standing_goal_idle_wait_detail(goal, remaining),
      }
    }
    None =>
      {
        operator_detail: "No enabled standing goal found.",
        portal_label: "not scheduled",
        idle_detail: "Waiting for a configured standing watch. Save a watch to activate this worker.",
      }
  }
}

///|
fn standing_goal_idle_wait_detail(
  goal : StandingGoalSnapshot,
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

///|
fn standing_goal_progress(model : Model, goal : StandingGoalSnapshot) -> Int {
  match goal.last_run_tick {
    Some(last_tick) => {
      let span = goal.next_due_tick - last_tick
      if span <= 0 {
        100
      } else {
        clamp_metric((daemon_tick_count(model) - last_tick) * 100 / span)
      }
    }
    None => if goal.next_due_tick <= daemon_tick_count(model) { 100 } else { 0 }
  }
}
