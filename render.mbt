///|
fn memory_scope_label(scope : MemoryScope) -> String {
  match scope {
    SharedTown => "shared-town"
    BookPrivate => "book-private"
    TaskEphemeral => "task-ephemeral"
  }
}

///|
fn worker_status_label(status : WorkerStatus) -> String {
  match status {
    Idle => "idle"
    Running => "running"
    Waiting => "waiting"
    Blocked => "blocked"
    Offline => "offline"
  }
}

///|
fn task_status_label(status : TaskStatus) -> String {
  match status {
    Backlog => "backlog"
    Assigned => "assigned"
    InProgress => "in-progress"
    Blocked => "blocked"
    Done => "done"
  }
}

///|
fn write_line(builder : StringBuilder, text : String) -> Unit {
  builder.write_string(text)
  builder.write_char('\n')
}

///|
fn join_strings(items : Array[String]) -> String {
  if items.is_empty() {
    return "-"
  }
  let builder = StringBuilder::new()
  for i in 0..<items.length() {
    if i > 0 {
      builder.write_string(", ")
    }
    builder.write_string(items[i])
  }
  builder.to_string()
}

///|
fn render_book_panel(
  builder : StringBuilder,
  town : Town,
  book : MoonbookHost,
) -> Unit {
  let workers = town.workers_for_book(book.id)
  let tasks = town.tasks_for_book(book.id)
  write_line(builder, "+----------------------------------------+")
  write_line(builder, "| book: \{book.name}")
  write_line(builder, "| purpose: \{book.purpose}")
  write_line(builder, "| workspace: \{book.workspace_root}")
  write_line(builder, "| memory: \{memory_scope_label(book.memory_scope)}")
  write_line(builder, "| skills: \{join_strings(book.skills)}")
  write_line(builder, "|")
  write_line(builder, "| workers")
  if workers.is_empty() {
    write_line(builder, "|   - none")
  } else {
    for worker in workers {
      let active = match worker.active_task_id {
        Some(task_id) => " task=\{task_id}"
        None => ""
      }
      write_line(
        builder,
        "|   - \{worker.name} [\{role_label(worker.role)} / \{worker_status_label(worker.status)}]\{active}",
      )
    }
  }
  write_line(builder, "|")
  write_line(builder, "| tasks")
  if tasks.is_empty() {
    write_line(builder, "|   - none")
  } else {
    for task in tasks {
      let assignee = match task.assigned_worker_id {
        Some(worker_id) => " -> \{worker_id}"
        None => ""
      }
      write_line(
        builder,
        "|   - [\{task_status_label(task.status)}] \{task.title}\{assignee}",
      )
    }
  }
  write_line(builder, "+----------------------------------------+")
}

///|
pub fn Town::render_dashboard(self : Town) -> String {
  let builder = StringBuilder::new()
  write_line(builder, "MOONTOWN / \{self.name}")
  write_line(
    builder,
    "books=\{self.book_count()} workers=\{self.worker_count()} tasks=\{self.task_count()} backlog=\{self.backlog_count()} assignments=\{self.active_assignment_count()}",
  )
  write_line(builder, "")
  write_line(builder, "Town Square")
  for book in self.books {
    render_book_panel(builder, self, book)
  }
  write_line(builder, "")
  write_line(builder, "Dispatch Log")
  if self.events.is_empty() {
    write_line(builder, "- no events")
  } else {
    for event in self.events {
      write_line(builder, "- \{event.title}: \{event.detail}")
    }
  }
  builder.to_string()
}
