///|
fn runtime_stat_chip(
  label : String,
  value : Int,
  class_name : String,
) -> @rabbita.Html {
  article(class="runtime-stat \{class_name}", [
    p(class="metric-label", label),
    p(class="runtime-stat-value", value.to_string()),
  ])
}

///|
fn render_runtime_bar(
  model : Model,
  workers : Array[WorkerSim],
  executions : Array[@core.TaskExecutionRecord],
) -> @rabbita.Html {
  let workers_summary = worker_count_summary(workers)
  let executions_summary = execution_count_summary(executions)
  let runtime_status = runtime_status_chip_for_model(model)
  section(class="runtime-bar", [
    div(class="runtime-head", [
      div(class="runtime-copy", [
        p(class="eyebrow", "Advanced Operations"),
        h2("Town work health"),
        p(
          class="summary",
          runtime_health_detail(workers_summary, executions_summary),
        ),
      ]),
      div(class="runtime-status", [
        status_chip(runtime_status.text, runtime_status.class_name),
        status_chip(
          "Workers online: \{workers_summary.online()}",
          "chip-neutral",
        ),
        status_chip("Available: \{workers_summary.available()}", "chip-neutral"),
      ]),
    ]),
    div(class="runtime-grid", [
      runtime_stat_chip("Running", workers_summary.running, "runtime-running"),
      runtime_stat_chip("Blocked", workers_summary.blocked, "runtime-blocked"),
      runtime_stat_chip(
        "Waiting",
        executions_summary.awaiting_persistence,
        "runtime-persisting",
      ),
      runtime_stat_chip(
        "Review",
        executions_summary.review_queued,
        "runtime-review",
      ),
      runtime_stat_chip(
        "Completed",
        executions_summary.completed,
        "runtime-completed",
      ),
    ]),
  ])
}

///|
fn runtime_health_detail(
  workers : WorkerCountSummary,
  executions : ExecutionCountSummary,
) -> String {
  if workers.blocked > 0 || executions.issue_count() > 0 {
    "The town has blocked workers or unresolved issues. Open the advanced viewport before changing runtime pressure."
  } else if executions.review_queued > 0 {
    "Review work is waiting. Resolve review items before adding more book or watch pressure."
  } else {
    "Town work is stable enough for normal watch, review, and book-request operations."
  }
}
