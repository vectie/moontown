///|
fn visual_latest_execution_for_worker(
  state : @core.TownState,
  worker : @core.WorkerRef,
) -> @core.TaskExecutionRecord? {
  let mut matched : @core.TaskExecutionRecord? = None
  for execution in state.executions {
    match execution.assigned_worker_id {
      Some(worker_id) => if worker_id == worker.id { matched = Some(execution) }
      None => ()
    }
  }
  match matched {
    Some(record) => Some(record)
    None =>
      if worker.status == Running || worker.status == Waiting {
        visual_latest_book_execution_without_worker(state, worker.book_id)
      } else {
        None
      }
  }
}

///|
fn visual_latest_book_execution_without_worker(
  state : @core.TownState,
  book_id : String,
) -> @core.TaskExecutionRecord? {
  let mut matched : @core.TaskExecutionRecord? = None
  for execution in state.executions {
    if execution.book_id == book_id &&
      execution.assigned_worker_id == None &&
      visual_execution_is_live(execution.status) {
      matched = Some(execution)
    }
  }
  matched
}

///|
fn visual_book_title(state : @core.TownState, book_id : String) -> String {
  for book in state.books {
    if book.id == book_id {
      return book.name
    }
  }
  book_id
}

///|
fn visual_task_title(state : @core.TownState, task_id : String) -> String {
  match @core.find_task(state, task_id) {
    Some(task) => task.title
    None => task_id
  }
}
