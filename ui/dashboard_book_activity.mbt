///|
priv struct BookHouseActivity {
  worker_count : Int
  task_count : Int
  execution_count : Int
  active_stage : String
}

///|
fn inspect_book_house_activity(
  town : @core.TownState,
  book_id : String,
) -> BookHouseActivity {
  let mut worker_count = 0
  for worker in town.workers {
    if worker.book_id == book_id {
      worker_count += 1
    }
  }
  let mut task_count = 0
  let mut active_stage = "Planning"
  for task in town.tasks {
    if task.book_id == book_id {
      task_count += 1
      active_stage = highest_priority_stage(
        active_stage,
        task_stage_label(task),
      )
    }
  }
  let mut execution_count = 0
  for execution in town.executions {
    if execution.book_id == book_id {
      execution_count += 1
      active_stage = highest_priority_stage(
        active_stage,
        execution_stage_label(town, execution),
      )
    }
  }
  { worker_count, task_count, execution_count, active_stage }
}
