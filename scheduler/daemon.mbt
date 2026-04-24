///|
pub struct SchedulerTick {
  sequence : Int
  summary : String
} derive(Show, Eq, ToJson, FromJson)

///|
pub struct ScheduledJob {
  id : String
  kind : String
  interval_seconds : Int
} derive(Show, Eq, ToJson, FromJson)

///|
pub struct DaemonState {
  daemon_id : String
  lease_owner : String
  tick_sequence : Int
  last_heartbeat_event_count : Int
  active_goal_ids : Array[String]
  jobs : Array[ScheduledJob]
} derive(Show, Eq, ToJson, FromJson)

///|
pub fn DaemonState::new(
  daemon_id? : String = "moontown-daemon",
  lease_owner? : String = "local",
  tick_sequence? : Int = 0,
  last_heartbeat_event_count? : Int = 0,
  active_goal_ids? : Array[String] = [],
  jobs? : Array[ScheduledJob] = default_daemon_jobs(),
) -> DaemonState {
  {
    daemon_id,
    lease_owner,
    tick_sequence,
    last_heartbeat_event_count,
    active_goal_ids,
    jobs,
  }
}

///|
pub fn default_daemon_jobs() -> Array[ScheduledJob] {
  [
    { id: "supervise-live-runs", kind: "supervision", interval_seconds: 30 },
    { id: "refresh-health", kind: "health", interval_seconds: 60 },
    { id: "project-ui-state", kind: "projection", interval_seconds: 60 },
  ]
}

///|
pub struct SchedulerAction {
  kind : String
  detail : String
} derive(Show, Eq, ToJson, FromJson)

///|
pub fn collect_due_tasks(town : @core.TownState) -> Array[@core.TownTask] {
  let tasks : Array[@core.TownTask] = []
  for task in town.tasks {
    if task.status == @core.TownTaskStatus::Pending ||
      task.status == @core.TownTaskStatus::Planned ||
      task.status == @core.TownTaskStatus::Assigned ||
      task.status == @core.TownTaskStatus::Running {
      tasks.push(task)
    }
  }
  tasks
}

///|
fn execution_action_kind(execution : @core.TaskExecutionRecord) -> String {
  match execution.status {
    @core.TaskExecutionStatus::PacketReady => "proposal-import"
    @core.TaskExecutionStatus::ProposalImported => "run-confirm"
    @core.TaskExecutionStatus::RunConfirmed => "run-start"
    @core.TaskExecutionStatus::Running => "poll-run"
    @core.TaskExecutionStatus::AwaitingPersistence => "persist-result"
    @core.TaskExecutionStatus::ReviewQueued => "review-sync"
    @core.TaskExecutionStatus::Completed => "archive"
    @core.TaskExecutionStatus::Stale => "recover-stale"
    @core.TaskExecutionStatus::Failed => "recovery"
  }
}

///|
pub fn plan_tick(
  town : @core.TownState,
  report : @health.HealthReport,
) -> Array[SchedulerAction] {
  let actions : Array[SchedulerAction] = []
  for task in collect_due_tasks(town) {
    match @core.find_execution(town, task.id) {
      Some(execution) =>
        actions.push({
          kind: execution_action_kind(execution),
          detail: "\{task.id} / \{execution.status.to_string()}",
        })
      None =>
        actions.push({
          kind: "prepare-packet",
          detail: "\{task.id} for \{task.book_id}",
        })
    }
  }
  for recovery in @health.recovery_actions(report) {
    actions.push({ kind: recovery.kind, detail: recovery.detail })
  }
  actions
}

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
) -> (DaemonState, SchedulerTick, Array[SchedulerAction]) {
  let actions = plan_tick(town, report)
  let next_sequence = daemon.tick_sequence + 1
  let next_daemon = {
    ..daemon,
    tick_sequence: next_sequence,
    last_heartbeat_event_count: town.events.length(),
  }
  (next_daemon, next_tick(next_sequence, actions), actions)
}
