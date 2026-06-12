///|
pub fn next_tick(
  sequence : Int,
  actions : Array[SchedulerAction],
) -> SchedulerTick {
  { sequence, summary: "\{actions.length()} town actions planned" }
}

///|
pub fn plan_daemon_tick(
  daemon : DaemonState,
  town : @core.TownState,
  report : @health.HealthReport,
  standing_goals? : Array[@core.StandingGoal] = [],
) -> (DaemonState, SchedulerTick, Array[SchedulerAction]) {
  let next_sequence = daemon.tick_sequence + 1
  let actions = plan_tick(town, report)
  let standing_actions = plan_standing_goal_actions(
    standing_goals, next_sequence,
  )
  for action in standing_actions {
    actions.push(action)
  }
  let active_goal_ids = due_standing_goals(standing_goals, next_sequence).map(fn(
    goal,
  ) {
    goal.id
  })
  let jobs = merge_default_daemon_jobs(daemon.jobs)
  let next_daemon = {
    ..daemon,
    tick_sequence: next_sequence,
    last_heartbeat_event_count: town.events.length(),
    active_goal_ids,
    jobs,
  }
  (next_daemon, next_tick(next_sequence, actions), actions)
}
