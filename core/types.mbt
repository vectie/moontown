///|
pub(all) enum WorkDomain {
  Coding
  Finance
  Research
  Operations
  SocialExperiment
  Custom(String)
} derive(Show, Eq, ToJson, FromJson)

///|
pub(all) enum MemoryScope {
  SharedTown
  BookPrivate
  TaskEphemeral
} derive(Show, Eq, ToJson, FromJson)

///|
pub(all) enum WorkerRole {
  Harness
  Planner
  Specialist
  Reviewer
  MemoryKeeper
  Watcher
  Operator
} derive(Show, Eq, ToJson, FromJson)

///|
pub(all) enum WorkerStatus {
  Idle
  Running
  Waiting
  Blocked
  Offline
} derive(Show, Eq, ToJson, FromJson)

///|
pub(all) enum TownTaskStatus {
  Pending
  Planned
  Assigned
  Running
  Blocked
  Done
  Failed
} derive(Show, Eq, ToJson, FromJson)

///|
pub(all) enum IsolationMode {
  SharedWorkspace
  BookWorkspace
  Worktree
  Sandboxed
} derive(Show, Eq, ToJson, FromJson)

///|
pub(all) enum TaskExecutionStatus {
  PacketReady
  ProposalImported
  RunConfirmed
  Running
  AwaitingPersistence
  ReviewQueued
  Completed
  Stale
  Failed
} derive(Show, Eq, ToJson, FromJson)

///|
pub struct TownConfig {
  id : String
  name : String
  heartbeat_seconds : Int
  max_concurrent_tasks : Int
} derive(Show, Eq, ToJson, FromJson)

///|
pub fn TownConfig::new(
  id~ : String,
  name~ : String,
  heartbeat_seconds? : Int = 30,
  max_concurrent_tasks? : Int = 12,
) -> TownConfig {
  TownConfig::{ id, name, heartbeat_seconds, max_concurrent_tasks }
}

///|
pub struct BookRef {
  id : String
  name : String
  purpose : String
  workspace_root : String
  memory_scope : MemoryScope
  tags : Array[String]
} derive(Show, Eq, ToJson, FromJson)

///|
pub fn BookRef::new(
  id~ : String,
  name~ : String,
  purpose~ : String,
  workspace_root~ : String,
  memory_scope? : MemoryScope = BookPrivate,
  tags? : Array[String] = [],
) -> BookRef {
  BookRef::{ id, name, purpose, workspace_root, memory_scope, tags }
}

///|
pub struct WorkerRef {
  id : String
  name : String
  book_id : String
  role : WorkerRole
  capabilities : Array[String]
  status : WorkerStatus
} derive(Show, Eq, ToJson, FromJson)

///|
pub fn WorkerRef::new(
  id~ : String,
  name~ : String,
  book_id~ : String,
  role~ : WorkerRole,
  capabilities? : Array[String] = [],
  status? : WorkerStatus = Idle,
) -> WorkerRef {
  WorkerRef::{ id, name, book_id, role, capabilities, status }
}

///|
pub struct TownTask {
  id : String
  book_id : String
  title : String
  prompt : String
  domain : WorkDomain
  required_role : WorkerRole?
  required_capabilities : Array[String]
  status : TownTaskStatus
} derive(Show, Eq, ToJson, FromJson)

///|
pub fn TownTask::new(
  id~ : String,
  book_id~ : String,
  title~ : String,
  prompt~ : String,
  domain~ : WorkDomain,
  required_role? : WorkerRole? = None,
  required_capabilities? : Array[String] = [],
  status? : TownTaskStatus = Pending,
) -> TownTask {
  TownTask::{
    id,
    book_id,
    title,
    prompt,
    domain,
    required_role,
    required_capabilities,
    status,
  }
}

///|
pub struct StandingGoal {
  id : String
  title : String
  prompt : String
  target_book_id : String?
  cadence_ticks : Int
  next_due_tick : Int
  last_run_tick : Int?
  enabled : Bool
  source_policy : String
  quality_threshold : Int
} derive(Show, Eq, ToJson, FromJson)

///|
pub fn StandingGoal::new(
  id~ : String,
  title~ : String,
  prompt~ : String,
  target_book_id? : String? = None,
  cadence_ticks? : Int = 60,
  next_due_tick? : Int = 0,
  last_run_tick? : Int? = None,
  enabled? : Bool = true,
  source_policy? : String = "web-first",
  quality_threshold? : Int = 80,
) -> StandingGoal {
  StandingGoal::{
    id,
    title,
    prompt,
    target_book_id,
    cadence_ticks,
    next_due_tick,
    last_run_tick,
    enabled,
    source_policy,
    quality_threshold,
  }
}

///|
pub fn StandingGoal::is_due(self : StandingGoal, tick : Int) -> Bool {
  self.enabled && tick >= self.next_due_tick
}

///|
pub fn StandingGoal::mark_dispatched(
  self : StandingGoal,
  tick : Int,
) -> StandingGoal {
  let cadence = if self.cadence_ticks < 1 { 1 } else { self.cadence_ticks }
  { ..self, last_run_tick: Some(tick), next_due_tick: tick + cadence }
}

///|
pub(all) enum WatcherDecisionKind {
  Update
  NoChange
  NeedsReview
  Failed
  Deferred
} derive(Show, Eq, ToJson, FromJson)

///|
pub struct WatcherRunRecord {
  goal_id : String
  tick : Int
  target_book_id : String
  decision : WatcherDecisionKind
  delta_score : Int
  new_source_count : Int
  detail : String
  task_id : String?
  run_id : String?
  next_due_tick : Int
} derive(Show, Eq, ToJson, FromJson)

///|
pub fn WatcherRunRecord::new(
  goal_id~ : String,
  tick~ : Int,
  target_book_id~ : String,
  decision~ : WatcherDecisionKind,
  delta_score? : Int = 0,
  new_source_count? : Int = 0,
  detail? : String = "",
  task_id? : String? = None,
  run_id? : String? = None,
  next_due_tick? : Int = tick,
) -> WatcherRunRecord {
  WatcherRunRecord::{
    goal_id,
    tick,
    target_book_id,
    decision,
    delta_score,
    new_source_count,
    detail,
    task_id,
    run_id,
    next_due_tick,
  }
}

///|
pub fn StandingGoal::next_due_after_watcher_decision(
  self : StandingGoal,
  tick : Int,
  decision : WatcherDecisionKind,
  no_change_streak? : Int = 0,
) -> Int {
  let cadence = if self.cadence_ticks < 1 { 1 } else { self.cadence_ticks }
  let _ = no_change_streak
  match decision {
    WatcherDecisionKind::Update => tick + cadence
    WatcherDecisionKind::NoChange => tick + cadence
    WatcherDecisionKind::NeedsReview => tick + max_int(1, cadence / 2)
    WatcherDecisionKind::Failed => tick + max_int(1, cadence / 4)
    WatcherDecisionKind::Deferred => tick + 1
  }
}

///|
pub fn StandingGoal::mark_watcher_decision(
  self : StandingGoal,
  tick : Int,
  decision : WatcherDecisionKind,
  no_change_streak? : Int = 0,
) -> StandingGoal {
  {
    ..self,
    last_run_tick: Some(tick),
    next_due_tick: self.next_due_after_watcher_decision(
      tick,
      decision,
      no_change_streak~,
    ),
  }
}

///|
fn max_int(left : Int, right : Int) -> Int {
  if left > right {
    left
  } else {
    right
  }
}

///|
pub struct AssignmentPlan {
  task_id : String
  worker_id : String
  book_id : String
  isolation : IsolationMode
  reason : String
} derive(Show, Eq, ToJson, FromJson)

///|
pub fn AssignmentPlan::new(
  task_id~ : String,
  worker_id~ : String,
  book_id~ : String,
  isolation~ : IsolationMode,
  reason~ : String,
) -> AssignmentPlan {
  AssignmentPlan::{ task_id, worker_id, book_id, isolation, reason }
}

///|
pub struct TaskExecutionRecord {
  task_id : String
  book_id : String
  packet_id : String
  packet_path : String
  proposal_id : String?
  run_id : String?
  status : TaskExecutionStatus
  summary : String
  output_contract : String
  context_pages : Array[String]
  skill_paths : Array[String]
  last_command : String?
  assigned_worker_id : String?
  attempt : Int
  heartbeat_tick : Int
  stale_after_tick : Int
  next_retry_tick : Int?
  requires_review : Bool
  notify_town : Bool
} derive(Show, Eq, ToJson, FromJson)

///|
pub fn TaskExecutionRecord::new(
  task_id~ : String,
  book_id~ : String,
  packet_id~ : String,
  packet_path~ : String,
  proposal_id? : String? = None,
  run_id? : String? = None,
  status~ : TaskExecutionStatus,
  summary~ : String,
  output_contract~ : String,
  context_pages? : Array[String] = [],
  skill_paths? : Array[String] = [],
  last_command? : String? = None,
  assigned_worker_id? : String? = None,
  attempt? : Int = 1,
  heartbeat_tick? : Int = 0,
  stale_after_tick? : Int = 3,
  next_retry_tick? : Int? = None,
  requires_review? : Bool = false,
  notify_town? : Bool = false,
) -> TaskExecutionRecord {
  TaskExecutionRecord::{
    task_id,
    book_id,
    packet_id,
    packet_path,
    proposal_id,
    run_id,
    status,
    summary,
    output_contract,
    context_pages,
    skill_paths,
    last_command,
    assigned_worker_id,
    attempt,
    heartbeat_tick,
    stale_after_tick,
    next_retry_tick,
    requires_review,
    notify_town,
  }
}

///|
pub struct TownEvent {
  id : String
  kind : String
  detail : String
  related_task_id : String?
  related_book_id : String?
  related_proposal_id : String?
  related_run_id : String?
} derive(Show, Eq, ToJson, FromJson)

///|
pub fn TownEvent::new(
  id~ : String,
  kind~ : String,
  detail~ : String,
  related_task_id? : String? = None,
  related_book_id? : String? = None,
  related_proposal_id? : String? = None,
  related_run_id? : String? = None,
) -> TownEvent {
  TownEvent::{
    id,
    kind,
    detail,
    related_task_id,
    related_book_id,
    related_proposal_id,
    related_run_id,
  }
}

///|
pub struct TownState {
  config : TownConfig
  books : Array[BookRef]
  workers : Array[WorkerRef]
  tasks : Array[TownTask]
  executions : Array[TaskExecutionRecord]
  events : Array[TownEvent]
} derive(Show, Eq, ToJson, FromJson)

///|
pub fn empty_state(config : TownConfig) -> TownState {
  { config, books: [], workers: [], tasks: [], executions: [], events: [] }
}

///|
pub fn TownState::register_book(self : TownState, book : BookRef) -> Unit {
  self.books.push(book)
}

///|
pub fn TownState::register_worker(self : TownState, worker : WorkerRef) -> Unit {
  self.workers.push(worker)
}

///|
pub fn TownState::enqueue_task(self : TownState, task : TownTask) -> Unit {
  self.tasks.push(task)
}

///|
pub fn TownState::register_execution(
  self : TownState,
  execution : TaskExecutionRecord,
) -> Unit {
  self.executions.push(execution)
}

///|
pub fn TownState::replace_execution(
  self : TownState,
  execution : TaskExecutionRecord,
) -> Unit {
  for index in 0..<self.executions.length() {
    if self.executions[index].task_id == execution.task_id {
      self.executions[index] = execution
      return
    }
  }
  self.executions.push(execution)
}

///|
pub fn TownState::replace_task(self : TownState, task : TownTask) -> Unit {
  for index in 0..<self.tasks.length() {
    if self.tasks[index].id == task.id {
      self.tasks[index] = task
      return
    }
  }
  self.tasks.push(task)
}

///|
pub fn TownState::set_worker_status(
  self : TownState,
  worker_id : String,
  status : WorkerStatus,
) -> Unit {
  for index in 0..<self.workers.length() {
    if self.workers[index].id == worker_id {
      self.workers[index] = { ..self.workers[index], status, }
      return
    }
  }
}

///|
pub fn TownState::record_event(self : TownState, event : TownEvent) -> Unit {
  self.events.push(event)
}

///|
pub fn find_execution(
  town : TownState,
  task_id : String,
) -> TaskExecutionRecord? {
  for execution in town.executions {
    if execution.task_id == task_id {
      return Some(execution)
    }
  }
  None
}

///|
pub fn find_task(town : TownState, task_id : String) -> TownTask? {
  for task in town.tasks {
    if task.id == task_id {
      return Some(task)
    }
  }
  None
}

///|
pub(open) trait BookProvider {
  books(self : Self) -> Array[BookRef]
}

///|
pub struct StaticBookProvider {
  entries : Array[BookRef]
} derive(Show, Eq)

///|
pub fn StaticBookProvider::new(entries : Array[BookRef]) -> StaticBookProvider {
  StaticBookProvider::{ entries, }
}

///|
pub impl BookProvider for StaticBookProvider with books(
  self : StaticBookProvider,
) -> Array[BookRef] {
  self.entries
}
