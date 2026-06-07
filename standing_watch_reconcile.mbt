///|
fn standing_goal_for_execution_task(
  goals : Array[@core.StandingGoal],
  task_id : String,
) -> @core.StandingGoal? {
  for goal in goals {
    match standing_watch_tick_for_goal_task(goal, task_id) {
      Some(_) => return Some(goal)
      None => ()
    }
  }
  None
}

///|
fn standing_watch_tick_for_goal_task(
  goal : @core.StandingGoal,
  task_id : String,
) -> Int? {
  let prefix = "standing-\{compact_watch_segment(goal.id)}-tick-"
  if task_id.has_prefix(prefix) {
    first_non_negative_int(task_id[prefix.length():].to_owned())
  } else {
    None
  }
}

///|
fn standing_watch_record_already_exists(
  records : Array[@core.WatcherRunRecord],
  task_id : String,
  run_id : String?,
  decision : @core.WatcherDecisionKind,
) -> Bool {
  for record in records {
    if record.task_id == Some(task_id) &&
      record.run_id == run_id &&
      record.decision == decision {
      return true
    }
  }
  false
}

///|
async fn save_standing_goal_update_for_watcher(
  snapshot_path : String,
  updated_goal : @core.StandingGoal,
) -> Unit {
  let path = default_standing_goal_state_path(snapshot_path)
  let goals = @storage.load_or_create_standing_goals(path~)
  let updated = standing_goal_registry_replace_or_append(goals, updated_goal)
  @storage.save_standing_goals_file(path, updated)
}
