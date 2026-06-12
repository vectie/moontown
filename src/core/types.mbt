///|
pub(all) enum WorkDomain {
  Coding
  Finance
  Research
  Operations
  SocialExperiment
  Custom(String)
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) enum MemoryScope {
  SharedTown
  BookPrivate
  TaskEphemeral
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) enum WorkerRole {
  Harness
  Planner
  Specialist
  Reviewer
  MemoryKeeper
  Watcher
  Operator
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) enum WorkerStatus {
  Idle
  Running
  Waiting
  Blocked
  Offline
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) enum TownTaskStatus {
  Pending
  Planned
  Assigned
  Running
  Blocked
  Done
  Failed
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) enum IsolationMode {
  SharedWorkspace
  BookWorkspace
  Worktree
  Sandboxed
} derive(Debug, Eq, ToJson, FromJson)

///|
pub struct TownConfig {
  id : String
  name : String
  heartbeat_seconds : Int
  max_concurrent_tasks : Int
} derive(Debug, Eq, ToJson, FromJson)

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
} derive(Debug, Eq, ToJson, FromJson)

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
} derive(Debug, Eq, ToJson, FromJson)

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
} derive(Debug, Eq, ToJson, FromJson)

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
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) enum WatcherDecisionKind {
  Update
  NoChange
  NeedsReview
  Failed
  Deferred
} derive(Debug, Eq, ToJson, FromJson)
