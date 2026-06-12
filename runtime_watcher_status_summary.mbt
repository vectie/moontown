///|
fn watcher_status_summary(
  records : Array[@core.WatcherRunRecord],
  goals : Array[@core.StandingGoal],
) -> String {
  if records.is_empty() {
    return "latest=none"
  }
  let latest = latest_preferred_watcher_record(records)
  let current_next = current_goal_next_due_tick(latest.goal_id, goals)
  let latest_decision = @standing_watch_policy.watcher_record_effective_decision(
    latest,
  ).to_string()
  match current_next {
    Some(next_due_tick) =>
      if next_due_tick == latest.next_due_tick {
        "latest=\{latest.goal_id}/\{latest_decision} next_due_tick=\{latest.next_due_tick}"
      } else {
        "latest=\{latest.goal_id}/\{latest_decision} recorded_next_due_tick=\{latest.next_due_tick} current_next_due_tick=\{next_due_tick}"
      }
    None =>
      "latest=\{latest.goal_id}/\{latest_decision} next_due_tick=\{latest.next_due_tick}"
  }
}

///|
fn latest_preferred_watcher_record(
  records : Array[@core.WatcherRunRecord],
) -> @core.WatcherRunRecord {
  let mut latest = records[0]
  for record in records {
    if @standing_watch_policy.watcher_record_prefer_candidate(latest, record) {
      latest = record
    }
  }
  latest
}

///|
fn latest_watcher_record_tick(records : Array[@core.WatcherRunRecord]) -> Int {
  let mut tick = 0
  for record in records {
    if record.tick > tick {
      tick = record.tick
    }
  }
  tick
}

///|
fn latest_standing_goal_tick(goals : Array[@core.StandingGoal]) -> Int {
  let mut tick = 0
  for goal in goals {
    match goal.last_run_tick {
      Some(last_run_tick) => if last_run_tick > tick { tick = last_run_tick }
      None => ()
    }
  }
  tick
}

///|
fn current_goal_next_due_tick(
  goal_id : String,
  goals : Array[@core.StandingGoal],
) -> Int? {
  match @core.standing_goal_registry_find(goals, goal_id) {
    Some(goal) => Some(goal.next_due_tick)
    None => None
  }
}
