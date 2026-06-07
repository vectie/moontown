///|
pub struct TownEvent {
  id : String
  kind : String
  detail : String
  related_task_id : String?
  related_book_id : String?
  related_proposal_id : String?
  related_run_id : String?
} derive(Debug, Eq, ToJson, FromJson)

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
} derive(Debug, Eq, ToJson, FromJson)

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
  let mut replaced = false
  for index in 0..<self.executions.length() {
    if self.executions[index].task_id == execution.task_id {
      self.executions[index] = execution
      replaced = true
    }
  }
  if !replaced {
    self.executions.push(execution)
  }
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
  fn books(self : Self) -> Array[BookRef]
}

///|
pub struct StaticBookProvider {
  entries : Array[BookRef]
} derive(Debug, Eq)

///|
pub fn StaticBookProvider::new(entries : Array[BookRef]) -> StaticBookProvider {
  StaticBookProvider::{ entries, }
}

///|
pub impl BookProvider for StaticBookProvider with fn books(
  self : StaticBookProvider,
) -> Array[BookRef] {
  self.entries
}
