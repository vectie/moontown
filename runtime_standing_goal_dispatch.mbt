///|
async fn dispatch_due_standing_goals(
  state : @core.TownState,
  mayor : @roles.Mayor,
  catalog : Array[@moonbook.BookCatalogEntry],
  goals : Array[@core.StandingGoal],
  tick : Int,
  snapshot_path : String,
) -> Array[@core.StandingGoal] {
  let updated : Array[@core.StandingGoal] = []
  let mut dispatches = 0
  for offset in 0..<goals.length() {
    let goal = goals[standing_goal_dispatch_index(offset, goals.length(), tick)]
    if goal.is_due(tick) {
      if dispatches >= max_standing_goal_dispatches_per_tick() {
        record_standing_goal_dispatch_deferred_for_budget(state, goal, tick)
        updated.push(goal)
        continue
      }
      if live_external_execution_count(state) >= max_live_external_executions() {
        record_standing_goal_dispatch_deferred_for_capacity(state, goal, tick)
        updated.push(goal)
        continue
      }
      record_standing_goal_dispatched(state, goal, tick)
      dispatches += 1
      updated.push(
        run_standing_goal_watch_cycle(
          state, mayor, catalog, goal, tick, snapshot_path,
        ),
      )
    } else {
      updated.push(goal)
    }
  }
  updated
}

///|
fn record_standing_goal_dispatch_deferred_for_budget(
  state : @core.TownState,
  goal : @core.StandingGoal,
  tick : Int,
) -> Unit {
  state.record_event(
    @core.TownEvent::new(
      id="event-standing-goal-\{tick}-\{goal.id}-deferred-budget",
      kind="standing-goal",
      detail="Mayor deferred standing goal \{goal.id} because this daemon tick already used its bounded standing-goal dispatch budget.",
      related_book_id=goal.target_book_id,
    ),
  )
}

///|
fn record_standing_goal_dispatch_deferred_for_capacity(
  state : @core.TownState,
  goal : @core.StandingGoal,
  tick : Int,
) -> Unit {
  state.record_event(
    @core.TownEvent::new(
      id="event-standing-goal-\{tick}-\{goal.id}-deferred-cap",
      kind="standing-goal",
      detail="Mayor deferred standing goal \{goal.id} because live external execution count reached \{max_live_external_executions()}.",
      related_book_id=goal.target_book_id,
    ),
  )
}

///|
fn record_standing_goal_dispatched(
  state : @core.TownState,
  goal : @core.StandingGoal,
  tick : Int,
) -> Unit {
  let target = goal.target_book_id.unwrap_or("mayor-selected-book")
  state.record_event(
    @core.TownEvent::new(
      id="event-standing-goal-\{tick}-\{goal.id}",
      kind="standing-goal",
      detail="Mayor dispatched standing goal \{goal.id} to \{target}: \{goal.title}",
      related_book_id=goal.target_book_id,
    ),
  )
}

///|
fn standing_goal_dispatch_index(
  offset : Int,
  goal_count : Int,
  tick : Int,
) -> Int {
  if goal_count <= 0 {
    0
  } else {
    (tick + offset) % goal_count
  }
}

///|
fn max_standing_goal_dispatches_per_tick() -> Int {
  3
}

///|
fn merge_standing_goal_updates(
  latest : Array[@core.StandingGoal],
  updated : Array[@core.StandingGoal],
) -> Array[@core.StandingGoal] {
  standing_goal_registry_merge_updates(latest, updated)
}
