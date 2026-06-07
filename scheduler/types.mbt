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
