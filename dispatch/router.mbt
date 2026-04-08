///|
pub struct RouteRequest {
  task : @core.TownTask
} derive(Show, Eq)

///|
pub fn RouteRequest::new(task~ : @core.TownTask) -> RouteRequest {
  RouteRequest::{ task, }
}

///|
pub enum RouteDecision {
  Assigned(@core.AssignmentPlan)
  Escalated(String)
  Deferred(String)
} derive(Show, Eq)

///|
fn worker_matches(task : @core.TownTask, worker : @core.WorkerRef) -> Bool {
  if worker.status != @core.WorkerStatus::Idle {
    return false
  }
  if worker.book_id != task.book_id {
    return false
  }
  match task.required_role {
    Some(role) => worker.role == role
    None => true
  }
}

///|
pub fn choose_isolation(
  task : @core.TownTask,
  worker : @core.WorkerRef,
  book : @core.BookRef,
) -> @core.IsolationMode {
  ignore(worker)
  match task.domain {
    @core.WorkDomain::Finance => @core.IsolationMode::Sandboxed
    @core.WorkDomain::SocialExperiment =>
      match book.memory_scope {
        @core.MemoryScope::SharedTown => @core.IsolationMode::BookWorkspace
        _ => @core.IsolationMode::Worktree
      }
    @core.WorkDomain::Coding => @core.IsolationMode::Worktree
    _ => @core.IsolationMode::BookWorkspace
  }
}

///|
pub fn route_task(
  town : @core.TownState,
  request : RouteRequest,
) -> RouteDecision {
  for worker in town.workers {
    if worker_matches(request.task, worker) {
      let maybe_book = find_book(town, worker.book_id)
      match maybe_book {
        Some(book) =>
          return Assigned(
            @core.AssignmentPlan::new(
              task_id=request.task.id,
              worker_id=worker.id,
              book_id=worker.book_id,
              isolation=choose_isolation(request.task, worker, book),
              reason="same-book starter route",
            ),
          )
        None => ()
      }
    }
  }
  Deferred("no eligible worker in the target book")
}

///|
fn find_book(town : @core.TownState, book_id : String) -> @core.BookRef? {
  for book in town.books {
    if book.id == book_id {
      return Some(book)
    }
  }
  None
}
