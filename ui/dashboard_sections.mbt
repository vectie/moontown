///|
fn build_dashboard_sections(town : @core.TownState) -> Array[DashboardSection] {
  [
    dashboard_books_section(town),
    dashboard_workers_section(town),
    dashboard_tasks_section(town),
    dashboard_pipeline_section(town),
    dashboard_executions_section(town),
  ]
}

///|
fn dashboard_books_section(town : @core.TownState) -> DashboardSection {
  {
    title: "Books",
    lines: town.books.map(book => "\{book.id}: \{book.workspace_root}"),
  }
}

///|
fn dashboard_workers_section(town : @core.TownState) -> DashboardSection {
  {
    title: "Workers",
    lines: town.workers.map(worker => {
      "\{worker.id}: \{worker.status.to_string()}"
    }),
  }
}

///|
fn dashboard_tasks_section(town : @core.TownState) -> DashboardSection {
  {
    title: "Tasks",
    lines: town.tasks.map(task => {
      let stage = task_stage_label(task)
      "\{task.id}: \{task.status.to_string()} / stage=\{stage}"
    }),
  }
}

///|
fn dashboard_pipeline_section(town : @core.TownState) -> DashboardSection {
  { title: "Pipeline", lines: build_pipeline_lines(town) }
}

///|
fn dashboard_executions_section(town : @core.TownState) -> DashboardSection {
  {
    title: "Executions",
    lines: town.executions.map(execution => {
      let proposal = execution.proposal_id.unwrap_or("draft")
      let run = execution.run_id.unwrap_or("not-started")
      let stage = execution_stage_label(town, execution)
      "\{execution.task_id}: \{execution.status.to_string()} / stage=\{stage} / proposal=\{proposal} / run=\{run}"
    }),
  }
}

///|
fn build_pipeline_lines(town : @core.TownState) -> Array[String] {
  let lines : Array[String] = []
  for task in town.tasks {
    let execution = find_execution_for_task(town, task.id)
    let status = execution
      .map(fn(record) { record.status.to_string() })
      .unwrap_or("not-started")
    let stage = execution
      .map(fn(record) { execution_stage_label(town, record) })
      .unwrap_or(task_stage_label(task))
    lines.push("\{task.book_id} / \{stage} / \{task.id} / \{status}")
  }
  lines
}

///|
fn find_execution_for_task(
  town : @core.TownState,
  task_id : String,
) -> @core.TaskExecutionRecord? {
  for execution in town.executions {
    if execution.task_id == task_id {
      return Some(execution)
    }
  }
  None
}
