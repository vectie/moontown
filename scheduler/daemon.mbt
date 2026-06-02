///|
pub struct SchedulerTick {
  sequence : Int
  summary : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub impl Show for SchedulerTick with fn output(
  self : SchedulerTick,
  logger : &Logger,
) -> Unit {
  logger.write_string(
    "SchedulerTick(sequence=\{self.sequence}, summary=\{self.summary})",
  )
}

///|
pub struct ScheduledJob {
  id : String
  kind : String
  interval_seconds : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
pub impl Show for ScheduledJob with fn output(
  self : ScheduledJob,
  logger : &Logger,
) -> Unit {
  logger.write_string(
    "ScheduledJob(id=\{self.id}, kind=\{self.kind}, interval_seconds=\{self.interval_seconds})",
  )
}

///|
pub struct DaemonState {
  daemon_id : String
  lease_owner : String
  tick_sequence : Int
  last_heartbeat_event_count : Int
  active_goal_ids : Array[String]
  jobs : Array[ScheduledJob]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub impl Show for DaemonState with fn output(
  self : DaemonState,
  logger : &Logger,
) -> Unit {
  logger.write_string(
    "DaemonState(daemon_id=\{self.daemon_id}, lease_owner=\{self.lease_owner}, tick_sequence=\{self.tick_sequence}, last_heartbeat_event_count=\{self.last_heartbeat_event_count}, active_goals=\{self.active_goal_ids.length()}, jobs=\{self.jobs.length()})",
  )
}

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
    {
      id: "dispatch-standing-goals",
      kind: "standing-goal",
      interval_seconds: 30,
    },
    { id: "run-civic-patterns", kind: "civic-pattern", interval_seconds: 30 },
    {
      id: "reconcile-civic-services",
      kind: "civic-service",
      interval_seconds: 60,
    },
    { id: "refresh-book-quality", kind: "book-quality", interval_seconds: 300 },
    {
      id: "review-book-quality",
      kind: "book-quality-review",
      interval_seconds: 1800,
    },
    { id: "refresh-health", kind: "health", interval_seconds: 60 },
    { id: "project-ui-state", kind: "projection", interval_seconds: 60 },
    {
      id: "process-book-template-requests",
      kind: "book-template-request",
      interval_seconds: 30,
    },
  ]
}

///|
pub fn merge_default_daemon_jobs(
  jobs : Array[ScheduledJob],
) -> Array[ScheduledJob] {
  let merged : Array[ScheduledJob] = []
  for job in jobs {
    if !daemon_job_deprecated(job) &&
      !merged.any(fn(existing) { existing.id == job.id }) {
      merged.push(job)
    }
  }
  for job in default_daemon_jobs() {
    if !merged.any(fn(existing) { existing.id == job.id }) {
      merged.push(job)
    }
  }
  merged
}

///|
fn daemon_job_deprecated(job : ScheduledJob) -> Bool {
  job.id == "run-civic-salons" || job.kind == "civic-salon"
}

///|
pub struct SchedulerAction {
  kind : String
  detail : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub impl Show for SchedulerAction with fn output(
  self : SchedulerAction,
  logger : &Logger,
) -> Unit {
  logger.write_string(
    "SchedulerAction(kind=\{self.kind}, detail=\{self.detail})",
  )
}

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
      kind: "standing-goal-due",
      detail: "\{goal.id} -> \{target}: \{goal.title}",
    })
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
