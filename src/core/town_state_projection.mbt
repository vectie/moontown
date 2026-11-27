///|
/// Limits for a bounded, read-only projection of `TownState`.
///
/// These limits never mutate or compact the authoritative state. Events are
/// projected as a recent tail. Live/nonterminal and terminal task/execution
/// rows have independent tails so operational rows take their own capacity and
/// each projected family has an absolute upper bound.
#derive(Debug, Eq)
pub struct TownStateProjectionLimits {
  recent_events : Int32
  live_tasks : Int32
  terminal_tasks : Int32
  live_executions : Int32
  terminal_executions : Int32
}

///|
pub fn TownStateProjectionLimits::new(
  recent_events~ : Int32 = 128,
  live_tasks~ : Int32 = 256,
  terminal_tasks~ : Int32 = 128,
  live_executions~ : Int32 = 256,
  terminal_executions~ : Int32 = 128,
) -> TownStateProjectionLimits {
  {
    recent_events: recent_events.max(0),
    live_tasks: live_tasks.max(0),
    terminal_tasks: terminal_tasks.max(0),
    live_executions: live_executions.max(0),
    terminal_executions: terminal_executions.max(0),
  }
}

///|
/// Explicit evidence describing what a read projection retained and omitted.
#derive(Debug, Eq, ToJson, FromJson)
pub struct TownStateProjectionEvidence {
  total_events : Int32
  retained_events : Int32
  omitted_events : Int32
  total_tasks : Int32
  retained_tasks : Int32
  omitted_tasks : Int32
  omitted_live_tasks : Int32
  omitted_terminal_tasks : Int32
  total_executions : Int32
  retained_executions : Int32
  omitted_executions : Int32
  omitted_live_executions : Int32
  omitted_terminal_executions : Int32
}

///|
/// A bounded copy for transport or rendering plus exact truncation evidence.
/// The source `TownState` remains the durable authority.
#derive(Debug, Eq)
pub struct TownStateProjection {
  state : TownState
  evidence : TownStateProjectionEvidence
}

///|
fn terminal_task_projection_status(status : TownTaskStatus) -> Bool {
  match status {
    Done | Failed => true
    _ => false
  }
}

///|
fn terminal_task_projection_count(tasks : Array[TownTask]) -> Int32 {
  let mut count = 0
  for task in tasks {
    if terminal_task_projection_status(task.status) {
      count += 1
    }
  }
  count
}

///|
fn live_task_projection_count(tasks : Array[TownTask]) -> Int32 {
  tasks.length() - terminal_task_projection_count(tasks)
}

///|
fn terminal_execution_projection_count(
  executions : Array[TaskExecutionRecord],
) -> Int32 {
  let mut count = 0
  for execution in executions {
    if terminal_execution_status(execution.status) {
      count += 1
    }
  }
  count
}

///|
fn live_execution_projection_count(
  executions : Array[TaskExecutionRecord],
) -> Int32 {
  executions.length() - terminal_execution_projection_count(executions)
}

///|
fn projection_omission_count(total : Int32, limit : Int32) -> Int32 {
  (total - limit).max(0)
}

///|
fn project_recent_events(
  source : Array[TownEvent],
  target : TownState,
  limit : Int32,
) -> Unit {
  let start = projection_omission_count(source.length(), limit)
  for index in start..<source.length() {
    target.record_event(source[index])
  }
}

///|
fn project_tasks(
  source : Array[TownTask],
  target : TownState,
  live_limit : Int32,
  terminal_limit : Int32,
) -> Unit {
  let mut live_to_omit = projection_omission_count(
    live_task_projection_count(source),
    live_limit,
  )
  let mut terminal_to_omit = projection_omission_count(
    terminal_task_projection_count(source),
    terminal_limit,
  )
  for task in source {
    if terminal_task_projection_status(task.status) && terminal_to_omit > 0 {
      terminal_to_omit -= 1
    } else if !terminal_task_projection_status(task.status) && live_to_omit > 0 {
      live_to_omit -= 1
    } else {
      target.enqueue_task(task)
    }
  }
}

///|
fn project_executions(
  source : Array[TaskExecutionRecord],
  target : TownState,
  live_limit : Int32,
  terminal_limit : Int32,
) -> Unit {
  let mut live_to_omit = projection_omission_count(
    live_execution_projection_count(source),
    live_limit,
  )
  let mut terminal_to_omit = projection_omission_count(
    terminal_execution_projection_count(source),
    terminal_limit,
  )
  for execution in source {
    if terminal_execution_status(execution.status) && terminal_to_omit > 0 {
      terminal_to_omit -= 1
    } else if !terminal_execution_status(execution.status) && live_to_omit > 0 {
      live_to_omit -= 1
    } else {
      target.register_execution(execution)
    }
  }
}

///|
/// Builds a bounded transport/rendering view without changing durable state.
/// Books and workers are current registries and are therefore always retained.
/// Operational diagnostics remain available in the durable source snapshot;
/// the projection retains independent newest live and terminal tails.
pub fn TownState::bounded_read_projection(
  self : TownState,
  limits : TownStateProjectionLimits,
) -> TownStateProjection {
  let projected = empty_state(self.config)
  for book in self.books {
    projected.register_book(book)
  }
  for worker in self.workers {
    projected.register_worker(worker)
  }
  project_tasks(self.tasks, projected, limits.live_tasks, limits.terminal_tasks)
  project_executions(
    self.executions,
    projected,
    limits.live_executions,
    limits.terminal_executions,
  )
  project_recent_events(self.events, projected, limits.recent_events)
  {
    state: projected,
    evidence: {
      total_events: self.events.length(),
      retained_events: projected.events.length(),
      omitted_events: self.events.length() - projected.events.length(),
      total_tasks: self.tasks.length(),
      retained_tasks: projected.tasks.length(),
      omitted_tasks: self.tasks.length() - projected.tasks.length(),
      omitted_live_tasks: projection_omission_count(
        live_task_projection_count(self.tasks),
        limits.live_tasks,
      ),
      omitted_terminal_tasks: projection_omission_count(
        terminal_task_projection_count(self.tasks),
        limits.terminal_tasks,
      ),
      total_executions: self.executions.length(),
      retained_executions: projected.executions.length(),
      omitted_executions: self.executions.length() -
      projected.executions.length(),
      omitted_live_executions: projection_omission_count(
        live_execution_projection_count(self.executions),
        limits.live_executions,
      ),
      omitted_terminal_executions: projection_omission_count(
        terminal_execution_projection_count(self.executions),
        limits.terminal_executions,
      ),
    },
  }
}
