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
        p(class="eyebrow", "Operator Surface"),
        h2("Town traffic, keeper queue, and review flow"),
        p(class="summary", state_source_detail(model)),
      ]),
      div(class="runtime-status", [
        status_chip(runtime_status.text, runtime_status.class_name),
        status_chip(
          "Source: \{state_source_label(model.state_source)}",
          "chip-book",
        ),
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
        "Persisting",
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
