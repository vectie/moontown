///|
pub fn standing_watch_empty_completion_is_no_change(
  goal : @core.StandingGoal,
  execution : @core.TaskExecutionRecord,
  decision : @core.WatcherDecisionKind,
) -> Bool {
  !@book_quality.is_repair_goal_id(goal.id) &&
  standing_watch_needs_review_with_zero_material_delta(execution, decision) &&
  @book_quality.repair_goal_generic_empty_review_summary(execution.summary)
}

///|
pub fn standing_watch_autonomous_repair_still_open(
  goal : @core.StandingGoal,
  execution : @core.TaskExecutionRecord,
  decision : @core.WatcherDecisionKind,
) -> Bool {
  @book_quality.is_repair_goal_id(goal.id) &&
  standing_watch_needs_review_with_zero_material_delta(execution, decision) &&
  @book_quality.repair_goal_generic_empty_review_summary(execution.summary)
}

///|
pub fn standing_watch_needs_review_with_zero_material_delta(
  execution : @core.TaskExecutionRecord,
  decision : @core.WatcherDecisionKind,
) -> Bool {
  decision == @core.WatcherDecisionKind::NeedsReview &&
  standing_watch_execution_has_zero_material_delta(execution)
}

///|
pub fn standing_watch_review_superseded_by_newer_review(
  executions : Array[@core.TaskExecutionRecord],
  standing_goals : Array[@core.StandingGoal],
  goal : @core.StandingGoal,
  execution : @core.TaskExecutionRecord,
) -> Bool {
  let current_tick = match
    standing_watch_tick_for_goal_task(goal, execution.task_id) {
    Some(tick) => tick
    None => return false
  }
  for candidate in executions {
    if candidate.task_id == execution.task_id {
      continue
    }
    match standing_goal_for_execution_task(standing_goals, candidate.task_id) {
      Some(candidate_goal) => if candidate_goal.id != goal.id { continue }
      None => continue
    }
    match standing_watch_tick_for_goal_task(goal, candidate.task_id) {
      Some(candidate_tick) if candidate_tick > current_tick =>
        if standing_watch_cycle_supersedes_review(candidate) {
          return true
        }
      _ => ()
    }
  }
  false
}

///|
pub fn standing_watch_cycle_supersedes_review(
  execution : @core.TaskExecutionRecord,
) -> Bool {
  match execution.status {
    @core.TaskExecutionStatus::ReviewQueued => true
    @core.TaskExecutionStatus::Completed => {
      let decision = standing_watch_decision_from_execution(execution)
      decision == @core.WatcherDecisionKind::NoChange ||
      decision == @core.WatcherDecisionKind::Update ||
      decision == @core.WatcherDecisionKind::Deferred
    }
    _ => false
  }
}
