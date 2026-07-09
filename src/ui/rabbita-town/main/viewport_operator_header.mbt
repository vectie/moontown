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
        "Track live town work, review needs, standing watches, and new requests from one professional operating surface.",
      ),
    ]),
    div(class="operator-console-status", [
      status_chip(daemon_cadence_label(model), "chip-clock"),
      status_chip("Live status \{metrics.live_status}", "chip-neutral"),
      status_chip("Town loop active", "chip-neutral"),
      status_chip("Due checks \{metrics.active_goal_count}", "chip-neutral"),
      status_chip(
        "Requests \{model.operator_requests.length()}",
        "chip-neutral",
      ),
      status_chip(
        "Book queue \{metrics.pending_template_requests}/\{metrics.failed_template_requests}",
        operator_template_request_chip_class(metrics),
      ),
      status_chip("Active work \{executions.length()}", "chip-neutral"),
    ]),
  ])
}

///|
fn operator_template_request_chip_class(
  metrics : OperatorConsoleMetrics,
) -> String {
  chip_class_for_tone(metrics.template_request_tone)
}
