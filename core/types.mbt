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
pub struct TownEvent {
  id : String
  kind : String
  detail : String
  related_task_id : String?
  related_book_id : String?
} derive(Show, Eq, ToJson, FromJson)

///|
pub fn TownEvent::new(
  id~ : String,
  kind~ : String,
  detail~ : String,
  related_task_id? : String? = None,
  related_book_id? : String? = None,
) -> TownEvent {
  TownEvent::{ id, kind, detail, related_task_id, related_book_id }
}

///|
pub struct TownState {
  config : TownConfig
  books : Array[BookRef]
  workers : Array[WorkerRef]
  tasks : Array[TownTask]
  events : Array[TownEvent]
} derive(Show, Eq, ToJson, FromJson)

///|
pub fn empty_state(config : TownConfig) -> TownState {
  { config, books: [], workers: [], tasks: [], events: [] }
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
pub fn TownState::record_event(self : TownState, event : TownEvent) -> Unit {
  self.events.push(event)
}
