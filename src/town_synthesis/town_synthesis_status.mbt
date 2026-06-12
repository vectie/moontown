///|
fn town_synthesis_execution_status(
  state : @core.TownState,
  plan : @roles.MayorGoalPlan,
) -> @core.TaskExecutionStatus {
  if town_synthesis_ready(state, plan) {
    @core.TaskExecutionStatus::Completed
  } else {
    @core.TaskExecutionStatus::ReviewQueued
  }
}

///|
fn town_synthesis_task_status(
  state : @core.TownState,
  plan : @roles.MayorGoalPlan,
) -> @core.TownTaskStatus {
  if town_synthesis_ready(state, plan) {
    @core.TownTaskStatus::Done
  } else {
    @core.TownTaskStatus::Blocked
  }
}

///|
fn town_synthesis_ready(
  state : @core.TownState,
  plan : @roles.MayorGoalPlan,
) -> Bool {
  for lane in plan.lanes {
    if lane_research_status(state, lane.entry.id) != "complete" {
      return false
    }
  }
  true
}

///|
fn town_synthesis_execution_summary(
  state : @core.TownState,
  plan : @roles.MayorGoalPlan,
  path : String,
) -> String {
  if town_synthesis_ready(state, plan) {
    "Mayor synthesized \{plan.lanes.length()} research lanes into \{path}."
  } else {
    "Mayor wrote an interim town synthesis at \{path}, but lane work is not ready for final acceptance."
  }
}

///|
fn town_synthesis_decision(
  state : @core.TownState,
  plan : @roles.MayorGoalPlan,
) -> String {
  if count_lanes_by_status(state, plan, "running") > 0 {
    return "The mayor should keep supervising because at least one lane is still running.\n"
  }
  if count_lanes_by_status(state, plan, "failed") > 0 {
    return "The mayor should retry or escalate failed lanes before accepting the research goal as complete.\n"
  }
  if count_lanes_by_status(state, plan, "review queued") > 0 {
    return "The mayor should keep the goal in review because one or more lanes have quality-gate or pending-review blockers.\n"
  }
  "The mayor can treat the town goal as complete and use this artifact as the cross-lane synthesis entry point.\n"
}

///|
fn count_lanes_by_status(
  state : @core.TownState,
  plan : @roles.MayorGoalPlan,
  status : String,
) -> Int {
  let mut count = 0
  for lane in plan.lanes {
    if lane_research_status(state, lane.entry.id) == status {
      count += 1
    }
  }
  count
}

///|
pub fn lane_research_status(
  state : @core.TownState,
  book_id : String,
) -> String {
  let mut saw_running = false
  let mut saw_review = false
  let mut saw_failed = false
  let mut saw_completed = false
  for execution in state.executions {
    if execution.book_id != book_id {
      continue
    }
    match execution.status {
      @core.TaskExecutionStatus::Completed => saw_completed = true
      @core.TaskExecutionStatus::ReviewQueued => saw_review = true
      @core.TaskExecutionStatus::Failed | @core.TaskExecutionStatus::Stale =>
        saw_failed = true
      _ =>
        if @core.active_work_execution_status(execution.status) {
          saw_running = true
        }
    }
  }
  if saw_running {
    "running"
  } else if saw_failed {
    "failed"
  } else if saw_review {
    "review queued"
  } else if saw_completed {
    "complete"
  } else {
    "planned"
  }
}
