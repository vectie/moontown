///|
priv struct ResearchBootstrapPlan {
  tasks : Array[@moonbook.BookTask]
  task_limit : Int
  bootstrap_active : Bool
}

///|
async fn research_bootstrap_plan(
  entry : @moonbook.BookCatalogEntry,
  goal : String,
  summary : @moonbook.BookStateSummary,
  tasks : Array[@moonbook.BookTask],
  task_limit : Int,
) -> ResearchBootstrapPlan {
  let ordered = @dispatch.prioritized_book_tasks(tasks, goal)
  let quality_gaps = @research_quality.research_quality_gaps(entry)
  let bootstrap_active = research_goal_needs_bootstrap(
    entry,
    goal,
    summary,
    quality_gaps~,
  )
  if !bootstrap_active {
    return { tasks: ordered, task_limit, bootstrap_active: false }
  }
  if !quality_gaps.is_empty() {
    @research_quality_runtime.write_research_quality_review_trigger(
      entry, quality_gaps, "preflight quality gate",
    )
  }
  let bootstrap_task = bootstrap_ingest_task(entry, goal)
  let planned = [
    bootstrap_task,
    ..ordered.filter(fn(task) { task.id != bootstrap_task.id }),
  ]
  let effective_limit = research_bootstrap_task_limit()
  { tasks: planned, task_limit: effective_limit, bootstrap_active: true }
}

///|
fn research_bootstrap_task_limit() -> Int {
  1
}
