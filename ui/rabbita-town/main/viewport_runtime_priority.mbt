///|
fn no_runtime_candidate_priority() -> Int {
  999
}

///|
fn priority_for_task_id(task_id : String) -> Int {
  if task_id.contains("code-patch") {
    0
  } else if task_id.contains("implementation-backlog") {
    1
  } else if task_id.contains("image-asset") || task_id.contains("asset-pack") {
    2
  } else {
    3
  }
}

///|
fn priority_beats(candidate : Int, current : Int) -> Bool {
  candidate < current
}

///|
fn matches_any_book_id(book_id : String, candidates : Array[String]) -> Bool {
  for candidate in candidates {
    if book_id == candidate {
      return true
    }
  }
  false
}

///|
fn task_matches_any_book_id(
  task : @core.TownTask,
  book_ids : Array[String],
) -> Bool {
  matches_any_book_id(task.book_id, book_ids)
}

///|
fn execution_matches_any_book_id(
  execution : @core.TaskExecutionRecord,
  book_ids : Array[String],
) -> Bool {
  matches_any_book_id(execution.book_id, book_ids)
}

///|
fn find_priority_book_worker(
  workers : Array[WorkerSim],
  book_id : String,
) -> WorkerSim? {
  find_book_worker(workers, book_id)
}

///|
fn find_priority_book_task(
  tasks : Array[@core.TownTask],
  book_id : String,
) -> @core.TownTask? {
  let mut best : @core.TownTask? = None
  let mut best_priority = no_runtime_candidate_priority()
  for task in tasks {
    if task.book_id != book_id {
      continue
    }
    let priority = priority_for_task_id(task.id)
    if priority_beats(priority, best_priority) {
      best_priority = priority
      best = Some(task)
    }
  }
  best
}

///|
fn find_priority_book_execution(
  executions : Array[@core.TaskExecutionRecord],
  book_id : String,
) -> @core.TaskExecutionRecord? {
  let mut best : @core.TaskExecutionRecord? = None
  let mut best_priority = no_runtime_candidate_priority()
  for execution in executions {
    if execution.book_id != book_id {
      continue
    }
    let priority = priority_for_task_id(execution.task_id)
    if priority_beats(priority, best_priority) {
      best_priority = priority
      best = Some(execution)
    }
  }
  best
}

///|
fn find_book_worker_by_ids(
  workers : Array[WorkerSim],
  book_ids : Array[String],
) -> WorkerSim? {
  for book_id in book_ids {
    match find_book_worker(workers, book_id) {
      Some(worker) => return Some(worker)
      None => ()
    }
  }
  None
}

///|
fn find_priority_book_task_by_ids(
  tasks : Array[@core.TownTask],
  book_ids : Array[String],
) -> @core.TownTask? {
  let mut best : @core.TownTask? = None
  let mut best_priority = no_runtime_candidate_priority()
  for task in tasks {
    if !task_matches_any_book_id(task, book_ids) {
      continue
    }
    let priority = priority_for_task_id(task.id)
    if priority_beats(priority, best_priority) {
      best_priority = priority
      best = Some(task)
    }
  }
  best
}

///|
fn find_priority_book_execution_by_ids(
  executions : Array[@core.TaskExecutionRecord],
  book_ids : Array[String],
) -> @core.TaskExecutionRecord? {
  let mut best : @core.TaskExecutionRecord? = None
  let mut best_priority = no_runtime_candidate_priority()
  for execution in executions {
    if !execution_matches_any_book_id(execution, book_ids) {
      continue
    }
    let priority = priority_for_task_id(execution.task_id)
    if priority_beats(priority, best_priority) {
      best_priority = priority
      best = Some(execution)
    }
  }
  best
}
