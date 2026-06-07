///|
fn render_operator_command_center(
  dispatch : Dispatch[Msg],
  model : Model,
  workers : Array[WorkerSim],
  executions : Array[@core.TaskExecutionRecord],
) -> @rabbita.Html {
  let metrics = operator_console_metrics(model, workers)
  section(class="operator-console", [
    render_operator_console_header(model, executions, metrics),
    div(class="operator-console-grid", [
      render_operator_watch_column(model, metrics),
      div(class="operator-request-stack", [
        render_request_composer(dispatch, model),
        render_book_template_composer(dispatch, model),
      ]),
    ]),
  ])
}
