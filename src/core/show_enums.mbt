///|
pub impl Show for WorkDomain with fn output(self : WorkDomain, logger : &Logger) -> Unit {
  logger.write_string(
    match self {
      Coding => "Coding"
      Finance => "Finance"
      Research => "Research"
      Operations => "Operations"
      SocialExperiment => "SocialExperiment"
      Custom(value) => "Custom(\{value})"
    },
  )
}

///|
pub impl Show for MemoryScope with fn output(
  self : MemoryScope,
  logger : &Logger,
) -> Unit {
  logger.write_string(
    match self {
      SharedTown => "SharedTown"
      BookPrivate => "BookPrivate"
      TaskEphemeral => "TaskEphemeral"
    },
  )
}

///|
pub impl Show for WorkerRole with fn output(self : WorkerRole, logger : &Logger) -> Unit {
  logger.write_string(
    match self {
      Harness => "Harness"
      Planner => "Planner"
      Specialist => "Specialist"
      Reviewer => "Reviewer"
      MemoryKeeper => "MemoryKeeper"
      Watcher => "Watcher"
      Operator => "Operator"
    },
  )
}

///|
pub impl Show for WorkerStatus with fn output(
  self : WorkerStatus,
  logger : &Logger,
) -> Unit {
  logger.write_string(
    match self {
      Idle => "Idle"
      Running => "Running"
      Waiting => "Waiting"
      Blocked => "Blocked"
      Offline => "Offline"
    },
  )
}

///|
pub impl Show for TownTaskStatus with fn output(
  self : TownTaskStatus,
  logger : &Logger,
) -> Unit {
  logger.write_string(
    match self {
      Pending => "Pending"
      Planned => "Planned"
      Assigned => "Assigned"
      Running => "Running"
      Blocked => "Blocked"
      Done => "Done"
      Failed => "Failed"
    },
  )
}
