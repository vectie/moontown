///|
pub impl Show for TownConfig with fn output(self : TownConfig, logger : &Logger) -> Unit {
  logger.write_string(
    "TownConfig(id=\{self.id}, name=\{self.name}, heartbeat_seconds=\{self.heartbeat_seconds}, max_concurrent_tasks=\{self.max_concurrent_tasks})",
  )
}

///|
pub impl Show for BookRef with fn output(self : BookRef, logger : &Logger) -> Unit {
  logger.write_string(
    "BookRef(id=\{self.id}, name=\{self.name}, memory_scope=\{self.memory_scope}, tags=\{self.tags.length()})",
  )
}

///|
pub impl Show for WorkerRef with fn output(self : WorkerRef, logger : &Logger) -> Unit {
  logger.write_string(
    "WorkerRef(id=\{self.id}, book_id=\{self.book_id}, role=\{self.role}, status=\{self.status}, capabilities=\{self.capabilities.length()})",
  )
}

///|
pub impl Show for TownTask with fn output(self : TownTask, logger : &Logger) -> Unit {
  logger.write_string(
    "TownTask(id=\{self.id}, book_id=\{self.book_id}, domain=\{self.domain}, status=\{self.status}, required_capabilities=\{self.required_capabilities.length()})",
  )
}

///|
pub impl Show for TownEvent with fn output(self : TownEvent, logger : &Logger) -> Unit {
  let related_task_id = self.related_task_id.unwrap_or("none")
  logger.write_string(
    "TownEvent(id=\{self.id}, kind=\{self.kind}, related_task_id=\{related_task_id})",
  )
}

///|
pub impl Show for TownState with fn output(self : TownState, logger : &Logger) -> Unit {
  logger.write_string(
    "TownState(config=\{self.config.id}, books=\{self.books.length()}, workers=\{self.workers.length()}, tasks=\{self.tasks.length()}, executions=\{self.executions.length()}, events=\{self.events.length()})",
  )
}

///|
pub impl Show for StaticBookProvider with fn output(
  self : StaticBookProvider,
  logger : &Logger,
) -> Unit {
  logger.write_string("StaticBookProvider(entries=\{self.entries.length()})")
}
