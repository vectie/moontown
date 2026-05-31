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

///|
pub impl Show for IsolationMode with fn output(
  self : IsolationMode,
  logger : &Logger,
) -> Unit {
  logger.write_string(
    match self {
      SharedWorkspace => "SharedWorkspace"
      BookWorkspace => "BookWorkspace"
      Worktree => "Worktree"
      Sandboxed => "Sandboxed"
    },
  )
}

///|
pub impl Show for TaskExecutionStatus with fn output(
  self : TaskExecutionStatus,
  logger : &Logger,
) -> Unit {
  logger.write_string(
    match self {
      PacketReady => "PacketReady"
      ProposalImported => "ProposalImported"
      RunConfirmed => "RunConfirmed"
      Running => "Running"
      AwaitingPersistence => "AwaitingPersistence"
      ReviewQueued => "ReviewQueued"
      Completed => "Completed"
      Stale => "Stale"
      Failed => "Failed"
    },
  )
}

///|
pub impl Show for WatcherDecisionKind with fn output(
  self : WatcherDecisionKind,
  logger : &Logger,
) -> Unit {
  logger.write_string(
    match self {
      Update => "Update"
      NoChange => "NoChange"
      NeedsReview => "NeedsReview"
      Failed => "Failed"
      Deferred => "Deferred"
    },
  )
}

///|
pub impl Show for TownConfig with fn output(self : TownConfig, logger : &Logger) -> Unit {
  logger.write_string(
    "TownConfig(id=\{self.id}, name=\{self.name}, heartbeat_seconds=\{self.heartbeat_seconds}, max_concurrent_tasks=\{self.max_concurrent_tasks})",
  )
}

///|
pub impl Show for BookRef with fn output(self : BookRef, logger : &Logger) -> Unit {
  logger.write_string(
    "BookRef(id=\{self.id}, name=\{self.name}, memory_scope=\{self.memory_scope}, tags=\{self.tags.length()})",
  )
}

///|
pub impl Show for WorkerRef with fn output(self : WorkerRef, logger : &Logger) -> Unit {
  logger.write_string(
    "WorkerRef(id=\{self.id}, book_id=\{self.book_id}, role=\{self.role}, status=\{self.status}, capabilities=\{self.capabilities.length()})",
  )
}

///|
pub impl Show for TownTask with fn output(self : TownTask, logger : &Logger) -> Unit {
  logger.write_string(
    "TownTask(id=\{self.id}, book_id=\{self.book_id}, domain=\{self.domain}, status=\{self.status}, required_capabilities=\{self.required_capabilities.length()})",
  )
}

///|
pub impl Show for StandingGoal with fn output(
  self : StandingGoal,
  logger : &Logger,
) -> Unit {
  let target_book_id = self.target_book_id.unwrap_or("none")
  logger.write_string(
    "StandingGoal(id=\{self.id}, target_book_id=\{target_book_id}, cadence_ticks=\{self.cadence_ticks}, next_due_tick=\{self.next_due_tick}, enabled=\{self.enabled})",
  )
}

///|
pub impl Show for WatcherRunRecord with fn output(
  self : WatcherRunRecord,
  logger : &Logger,
) -> Unit {
  logger.write_string(
    "WatcherRunRecord(goal_id=\{self.goal_id}, tick=\{self.tick}, decision=\{self.decision}, delta_score=\{self.delta_score}, new_source_count=\{self.new_source_count}, next_due_tick=\{self.next_due_tick})",
  )
}

///|
pub impl Show for AssignmentPlan with fn output(
  self : AssignmentPlan,
  logger : &Logger,
) -> Unit {
  logger.write_string(
    "AssignmentPlan(task_id=\{self.task_id}, worker_id=\{self.worker_id}, book_id=\{self.book_id}, isolation=\{self.isolation})",
  )
}

///|
pub impl Show for TaskExecutionRecord with fn output(
  self : TaskExecutionRecord,
  logger : &Logger,
) -> Unit {
  logger.write_string(
    "TaskExecutionRecord(task_id=\{self.task_id}, book_id=\{self.book_id}, status=\{self.status}, attempt=\{self.attempt}, heartbeat_tick=\{self.heartbeat_tick})",
  )
}

///|
pub impl Show for TownEvent with fn output(self : TownEvent, logger : &Logger) -> Unit {
  let related_task_id = self.related_task_id.unwrap_or("none")
  logger.write_string(
    "TownEvent(id=\{self.id}, kind=\{self.kind}, related_task_id=\{related_task_id})",
  )
}

///|
pub impl Show for TownState with fn output(self : TownState, logger : &Logger) -> Unit {
  logger.write_string(
    "TownState(config=\{self.config.id}, books=\{self.books.length()}, workers=\{self.workers.length()}, tasks=\{self.tasks.length()}, executions=\{self.executions.length()}, events=\{self.events.length()})",
  )
}

///|
pub impl Show for StaticBookProvider with fn output(
  self : StaticBookProvider,
  logger : &Logger,
) -> Unit {
  logger.write_string("StaticBookProvider(entries=\{self.entries.length()})")
}
