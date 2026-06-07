///|
fn render_operator_console_header(
  model : Model,
  executions : Array[@core.TaskExecutionRecord],
  metrics : OperatorConsoleMetrics,
) -> @rabbita.Html {
  div(class="operator-console-head", [
    div([
      p(class="eyebrow", "Progress And Requests"),
      h2("Mayor command center"),
      p(
        class="summary",
        "This panel reads real runtime files: `town.json`, `daemon.json`, `standing-goals.json`, and the watcher ledger. It also lets you submit new standing-watch requests into the local daemon queue.",
      ),
    ]),
    div(class="operator-console-status", [
      status_chip(daemon_cadence_label(model), "chip-clock"),
      status_chip("Live spine \{metrics.live_status}", "chip-neutral"),
      status_chip("Daemon \{metrics.daemon_identity}", "chip-neutral"),
      status_chip(
        "Active due goals \{metrics.active_goal_count}",
        "chip-neutral",
      ),
      status_chip(
        "Requests \{model.operator_requests.length()}",
        "chip-neutral",
      ),
      status_chip(
        "Book requests \{metrics.pending_template_requests}/\{metrics.failed_template_requests}",
        operator_template_request_chip_class(metrics),
      ),
      status_chip("Executions \{executions.length()}", "chip-neutral"),
    ]),
  ])
}

///|
fn operator_template_request_chip_class(
  metrics : OperatorConsoleMetrics,
) -> String {
  chip_class_for_tone(metrics.template_request_tone)
}
