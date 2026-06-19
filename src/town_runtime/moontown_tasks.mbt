///|
fn to_town_task(
  entry : @moonbook.BookCatalogEntry,
  task : @moonbook.BookTask,
  status : @core.TaskExecutionStatus,
) -> @core.TownTask {
  @core.TownTask::new(
    id=task.id,
    book_id=entry.id,
    title=task.title,
    prompt=task.prompt,
    domain=@dispatch.domain_for_book_task(entry, task),
    required_role=task.required_role,
    required_capabilities=entry.skills,
    status=@core.town_task_status_for_execution(status),
  )
}

///|
fn seed_catalog_tasks(
  state : @core.TownState,
  catalog : Array[@moonbook.BookCatalogEntry],
) -> Unit {
  let mut index = 0
  for entry in catalog {
    let limit = desired_task_count(entry)
    let mut emitted = 0
    for task in fixture_book_tasks(entry) {
      if emitted >= limit {
        break
      }
      let execution_status = execution_status_for_index(index)
      let town_task = to_town_task(entry, task, execution_status)
      state.enqueue_task(town_task)
      state.register_execution(
        modeled_lifecycle_execution_record(town_task, index),
      )
      emitted += 1
      index += 1
    }
  }
}

///|
fn provider_overview_task(book : @core.BookRef, index : Int) -> @core.TownTask {
  let execution_status = execution_status_for_index(index)
  @core.TownTask::new(
    id="task-\{book.id}-overview",
    book_id=book.id,
    title="Book overview for \{book.name}",
    prompt="Summarize the current state for \{book.name}.",
    domain=@dispatch.domain_for_provider_overview(book),
    required_role=Some(Planner),
    required_capabilities=book.tags,
    status=@core.town_task_status_for_execution(execution_status),
  )
}

///|
fn seed_provider_overview_tasks(state : @core.TownState) -> Unit {
  let mut index = 0
  for book in state.books {
    let task = provider_overview_task(book, index)
    state.enqueue_task(task)
    state.register_execution(modeled_lifecycle_execution_record(task, index))
    index += 1
  }
}

///|
fn town_scoped_book_task(
  entry : @moonbook.BookCatalogEntry,
  task : @moonbook.BookTask,
) -> @moonbook.BookTask {
  if task.id.has_prefix("\{entry.id}-") || task.id.contains("-\{entry.id}-") {
    return task
  }
  @moonbook.BookTask::new(
    id="\{entry.id}-\{task.id}",
    goal=task.goal,
    title=task.title,
    kind=task.kind,
    prompt=task.prompt,
    priority=task.priority,
    requires_review=task.requires_review,
    required_role=task.required_role,
    target_pages=task.target_pages,
  )
}
