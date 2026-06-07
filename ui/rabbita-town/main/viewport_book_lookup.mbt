///|
priv struct CivicModuleRuntimeContext {
  worker : WorkerSim?
  task : @core.TownTask?
  execution : @core.TaskExecutionRecord?
}

///|
fn civic_module_runtime_context(
  model : Model,
  book_id : String,
) -> CivicModuleRuntimeContext {
  {
    worker: find_book_worker(workers_for_model(model), book_id),
    task: find_book_task(task_specs(model), book_id),
    execution: find_book_execution(execution_specs(model), book_id),
  }
}

///|
fn civic_module_priority_runtime_context(
  model : Model,
  book_id : String,
) -> CivicModuleRuntimeContext {
  {
    worker: find_priority_book_worker(workers_for_model(model), book_id),
    task: find_priority_book_task(tasks_for_model(model), book_id),
    execution: find_priority_book_execution(
      executions_for_model(model),
      book_id,
    ),
  }
}

///|
fn civic_module_priority_runtime_context_by_ids(
  model : Model,
  book_ids : Array[String],
) -> CivicModuleRuntimeContext {
  {
    worker: find_book_worker_by_ids(workers_for_model(model), book_ids),
    task: find_priority_book_task_by_ids(tasks_for_model(model), book_ids),
    execution: find_priority_book_execution_by_ids(
      executions_for_model(model),
      book_ids,
    ),
  }
}

///|
fn find_book_execution(
  executions : Array[@core.TaskExecutionRecord],
  book_id : String,
) -> @core.TaskExecutionRecord? {
  for execution in executions {
    if execution.book_id == book_id {
      return Some(execution)
    }
  }
  None
}

///|
fn find_book_worker(workers : Array[WorkerSim], book_id : String) -> WorkerSim? {
  for worker in workers {
    if worker.book_id == book_id {
      return Some(worker)
    }
  }
  None
}

///|
fn find_book_task(
  tasks : Array[@core.TownTask],
  book_id : String,
) -> @core.TownTask? {
  for task in tasks {
    if task.book_id == book_id {
      return Some(task)
    }
  }
  None
}
