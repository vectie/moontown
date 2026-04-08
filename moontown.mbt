///|
pub enum WorkDomain {
  Coding
  Finance
  Research
  Operations
  Custom(String)
} derive(Show, Eq)

///|
pub enum WorkerRole {
  Harness
  Planner
  Specialist
  Reviewer
  MemoryKeeper
  Watcher
} derive(Show, Eq)

///|
pub enum WorkerStatus {
  Idle
  Running
  Waiting
  Blocked
  Offline
} derive(Show, Eq)

///|
pub enum TaskStatus {
  Backlog
  Assigned
  InProgress
  Blocked
  Done
} derive(Show, Eq)

///|
pub enum MemoryScope {
  SharedTown
  BookPrivate
  TaskEphemeral
} derive(Show, Eq)

///|
pub enum IsolationMode {
  SharedWorkspace
  BookWorkspace
  Worktree
} derive(Show, Eq)

///|
pub struct MoonbookHost {
  id : String
  name : String
  purpose : String
  workspace_root : String
  memory_scope : MemoryScope
  skills : Array[String]
} derive(Show, Eq)

///|
pub fn MoonbookHost::new(
  id~ : String,
  name~ : String,
  purpose~ : String,
  workspace_root~ : String,
  memory_scope? : MemoryScope = BookPrivate,
  skills? : Array[String] = [],
) -> MoonbookHost {
  MoonbookHost::{ id, name, purpose, workspace_root, memory_scope, skills }
}

///|
pub struct Worker {
  id : String
  name : String
  book_id : String
  role : WorkerRole
  status : WorkerStatus
  skills : Array[String]
  preferred_isolation : IsolationMode
  active_task_id : String?
} derive(Show, Eq)

///|
pub fn Worker::new(
  id~ : String,
  name~ : String,
  book_id~ : String,
  role~ : WorkerRole,
  status? : WorkerStatus = Idle,
  skills? : Array[String] = [],
  preferred_isolation? : IsolationMode = BookWorkspace,
  active_task_id? : String? = None,
) -> Worker {
  Worker::{
    id,
    name,
    book_id,
    role,
    status,
    skills,
    preferred_isolation,
    active_task_id,
  }
}

///|
pub struct Task {
  id : String
  title : String
  summary : String
  book_id : String
  domain : WorkDomain
  status : TaskStatus
  required_role : WorkerRole?
  required_skills : Array[String]
  assigned_worker_id : String?
} derive(Show, Eq)

///|
pub fn Task::new(
  id~ : String,
  title~ : String,
  summary~ : String,
  book_id~ : String,
  domain~ : WorkDomain,
  status? : TaskStatus = Backlog,
  required_role? : WorkerRole? = None,
  required_skills? : Array[String] = [],
  assigned_worker_id? : String? = None,
) -> Task {
  Task::{
    id,
    title,
    summary,
    book_id,
    domain,
    status,
    required_role,
    required_skills,
    assigned_worker_id,
  }
}

///|
pub struct Assignment {
  task_id : String
  worker_id : String
  book_id : String
  isolation : IsolationMode
  rationale : String
} derive(Show, Eq)

///|
pub fn Assignment::new(
  task_id~ : String,
  worker_id~ : String,
  book_id~ : String,
  isolation~ : IsolationMode,
  rationale~ : String,
) -> Assignment {
  Assignment::{ task_id, worker_id, book_id, isolation, rationale }
}

///|
pub struct TownEvent {
  title : String
  detail : String
} derive(Show, Eq)

///|
pub fn TownEvent::new(title~ : String, detail~ : String) -> TownEvent {
  TownEvent::{ title, detail }
}

///|
pub struct Town {
  name : String
  books : Array[MoonbookHost]
  workers : Array[Worker]
  tasks : Array[Task]
  assignments : Array[Assignment]
  events : Array[TownEvent]
} derive(Show, Eq)

///|
pub fn new(name : String) -> Town {
  { name, books: [], workers: [], tasks: [], assignments: [], events: [] }
}

///|
pub fn Town::add_book(self : Town, book : MoonbookHost) -> Unit {
  self.books.push(book)
}

///|
pub fn Town::add_worker(self : Town, worker : Worker) -> Unit {
  self.workers.push(worker)
}

///|
pub fn Town::add_task(self : Town, task : Task) -> Unit {
  self.tasks.push(task)
}

///|
pub fn Town::add_event(self : Town, event : TownEvent) -> Unit {
  self.events.push(event)
}

///|
pub fn Town::book_count(self : Town) -> Int {
  self.books.length()
}

///|
pub fn Town::worker_count(self : Town) -> Int {
  self.workers.length()
}

///|
pub fn Town::task_count(self : Town) -> Int {
  self.tasks.length()
}

///|
pub fn Town::book(self : Town, book_id : String) -> MoonbookHost? {
  for book in self.books {
    if book.id == book_id {
      return Some(book)
    }
  }
  None
}

///|
pub fn Town::workers_for_book(self : Town, book_id : String) -> Array[Worker] {
  let workers : Array[Worker] = []
  for worker in self.workers {
    if worker.book_id == book_id {
      workers.push(worker)
    }
  }
  workers
}

///|
pub fn Town::tasks_for_book(self : Town, book_id : String) -> Array[Task] {
  let tasks : Array[Task] = []
  for task in self.tasks {
    if task.book_id == book_id {
      tasks.push(task)
    }
  }
  tasks
}

///|
pub fn Town::active_assignment_count(self : Town) -> Int {
  self.assignments.length()
}

///|
pub fn Town::backlog_count(self : Town) -> Int {
  let mut count = 0
  for task in self.tasks {
    if task.status == Backlog {
      count += 1
    }
  }
  count
}
