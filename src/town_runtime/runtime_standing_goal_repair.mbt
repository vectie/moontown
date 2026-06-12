///|
async fn reconcile_budget_deferred_standing_goal_state(
  state : @core.TownState,
  goals : Array[@core.StandingGoal],
  snapshot_path : String,
) -> Array[@core.StandingGoal] {
  let watcher_records = load_watcher_records_for_goals(snapshot_path, goals)
  goals.map(fn(goal) {
    match goal.last_run_tick {
      Some(last_run_tick) =>
        if standing_goal_has_nonexecuted_deferred_event(
            state,
            goal.id,
            last_run_tick,
          ) &&
          !standing_goal_has_watcher_record_at_tick(
            watcher_records,
            goal.id,
            last_run_tick,
          ) {
          repair_budget_deferred_standing_goal(
            state, goal, watcher_records, last_run_tick,
          )
        } else {
          goal
        }
      None => goal
    }
  })
}

///|
fn repair_budget_deferred_standing_goal(
  state : @core.TownState,
  goal : @core.StandingGoal,
  watcher_records : Array[@core.WatcherRunRecord],
  last_run_tick : Int,
) -> @core.StandingGoal {
  state.record_event(
    @core.TownEvent::new(
      id="event-standing-goal-\{last_run_tick}-\{goal.id}-budget-state-repaired",
      kind="standing-goal",
      detail="Mayor restored standing goal \{goal.id} to due state because tick \{last_run_tick} was only scheduler-deferred and produced no watcher ledger record.",
      related_book_id=goal.target_book_id,
    ),
  )
  @core.StandingGoal::new(
    id=goal.id,
    title=goal.title,
    prompt=goal.prompt,
    target_book_id=goal.target_book_id,
    cadence_ticks=goal.cadence_ticks,
    next_due_tick=last_run_tick,
    last_run_tick=latest_watcher_record_tick_for_goal_before(
      watcher_records,
      goal.id,
      last_run_tick,
    ),
    enabled=goal.enabled,
    source_policy=goal.source_policy,
    quality_threshold=goal.quality_threshold,
  )
}

///|
fn standing_goal_has_nonexecuted_deferred_event(
  state : @core.TownState,
  goal_id : String,
  tick : Int,
) -> Bool {
  let budget_event_id = "event-standing-goal-\{tick}-\{goal_id}-deferred-budget"
  let cap_event_id = "event-standing-goal-\{tick}-\{goal_id}-deferred-cap"
  state.events.any(fn(event) {
    event.id == budget_event_id || event.id == cap_event_id
  })
}

///|
fn standing_goal_has_watcher_record_at_tick(
  records : Array[@core.WatcherRunRecord],
  goal_id : String,
  tick : Int,
) -> Bool {
  records.any(fn(record) { record.goal_id == goal_id && record.tick == tick })
}

///|
fn latest_watcher_record_tick_for_goal_before(
  records : Array[@core.WatcherRunRecord],
  goal_id : String,
  tick : Int,
) -> Int? {
  let mut latest = 0
  for record in records {
    if record.goal_id == goal_id && record.tick < tick && record.tick > latest {
      latest = record.tick
    }
  }
  if latest > 0 {
    Some(latest)
  } else {
    None
  }
}

///|
async fn load_watcher_records_for_goals(
  snapshot_path : String,
  goals : Array[@core.StandingGoal],
) -> Array[@core.WatcherRunRecord] {
  let records : Array[@core.WatcherRunRecord] = []
  let ledger_dir = @storage.watcher_ledger_dir_for_snapshot(snapshot_path)
  for goal in goals {
    for record in @storage.load_watcher_run_records(goal.id, dir=ledger_dir) {
      records.push(record)
    }
  }
  records
}
