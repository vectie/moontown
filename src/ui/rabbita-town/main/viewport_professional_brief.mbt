///|
fn render_professional_brief(
  model : Model,
  workers : Array[WorkerSim],
  executions : Array[@core.TaskExecutionRecord],
) -> @rabbita.Html {
  let workers_summary = worker_count_summary(workers)
  let executions_summary = execution_count_summary(executions)
  let watch_summary = standing_goal_summary(model)
  let decisions = watcher_decision_summary(model)
  section(class="professional-brief-panel", [
    h2("Operating Brief"),
    p(
      class="professional-brief-intro",
      "Scan what needs attention before opening deeper town tools.",
    ),
    div(class="professional-brief-grid", [
      professional_brief_item(
        "Town work",
        professional_work_value(workers_summary, executions_summary),
        professional_work_detail(workers_summary, executions_summary),
      ),
      professional_brief_item(
        "Standing watches",
        watch_summary.enabled_count.to_string(),
        professional_brief_watch_detail(watch_summary, decisions),
      ),
      professional_brief_item(
        "Review needs",
        professional_review_value(executions_summary, decisions),
        professional_review_detail(executions_summary, decisions),
      ),
      professional_brief_item(
        "Book queue",
        professional_book_queue_value(model),
        professional_book_queue_detail(model),
      ),
    ]),
  ])
}

///|
fn professional_brief_item(
  label : String,
  value : String,
  detail : String,
) -> @rabbita.Html {
  article(class="professional-brief-item", [
    p(class="metric-label", label),
    p(class="professional-brief-value", value),
    p(class="metric-detail", detail),
  ])
}

///|
fn professional_work_value(
  workers : WorkerCountSummary,
  executions : ExecutionCountSummary,
) -> String {
  "\{workers.online()} / \{executions.active_or_unresolved()}"
}

///|
fn professional_work_detail(
  workers : WorkerCountSummary,
  executions : ExecutionCountSummary,
) -> String {
  "\{workers.online()} workers online; \{executions.active_or_unresolved()} work items still active or unresolved."
}

///|
fn professional_brief_watch_detail(
  watches : StandingGoalSummary,
  decisions : WatcherDecisionSummary,
) -> String {
  if watches.enabled_count == 0 {
    "No durable watch is active yet."
  } else if decisions.failed_count > 0 {
    "\{decisions.failed_count} watch needs recovery."
  } else if decisions.review_count > 0 {
    "\{decisions.review_count} watch result is waiting for review."
  } else {
    "Active watches are not reporting urgent attention."
  }
}

///|
fn professional_review_value(
  executions : ExecutionCountSummary,
  decisions : WatcherDecisionSummary,
) -> String {
  (executions.review_queued + decisions.review_count + decisions.failed_count).to_string()
}

///|
fn professional_review_detail(
  executions : ExecutionCountSummary,
  decisions : WatcherDecisionSummary,
) -> String {
  let total = executions.review_queued +
    decisions.review_count +
    decisions.failed_count
  if total == 0 {
    "No review-blocked work is visible."
  } else {
    "\{total} watch or book item should be reviewed before the next handoff."
  }
}

///|
fn professional_book_queue_value(model : Model) -> String {
  live_autonomy_operator_view(model, fallback_active_workers=0).template_request_count.to_string()
}
