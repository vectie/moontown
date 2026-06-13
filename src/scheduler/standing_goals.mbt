///|
pub fn due_standing_goals(
  goals : Array[@core.StandingGoal],
  tick : Int,
) -> Array[@core.StandingGoal] {
  let due : Array[@core.StandingGoal] = []
  for goal in goals {
    if goal.is_due(tick) {
      due.push(goal)
    }
  }
  due
}

///|
pub fn plan_standing_goal_actions(
  goals : Array[@core.StandingGoal],
  tick : Int,
) -> Array[SchedulerAction] {
  let actions : Array[SchedulerAction] = []
  for goal in due_standing_goals(goals, tick) {
    let target = goal.target_book_id.unwrap_or("mayor-selected-book")
    actions.push({
      kind: standing_goal_due_action_kind(),
      detail: "\{goal.id} -> \{target}: \{goal.title}",
    })
  }
  actions
}
