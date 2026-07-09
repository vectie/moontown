///|
fn render_attention_workbench(
  model : Model,
  workers : Array[WorkerSim],
  executions : Array[@core.TaskExecutionRecord],
  events : Array[@core.TownEvent],
) -> @rabbita.Html {
  let focus = attention_focus_view(model, workers, executions)
  section(class="attention-workbench attention-workbench-\{focus.tone}", [
    div(class="attention-workbench-head", [
      div([
        p(class="eyebrow", "Attention Workbench"),
        h2(focus.title),
        p(class="summary", focus.detail),
      ]),
      div(class="attention-workbench-signal", [
        p(class="metric-label", "Signal"),
        p(class="attention-workbench-value", focus.signal),
      ]),
    ]),
    div(class="attention-workbench-grid", [
      article(class="attention-next-card", [
        p(class="metric-label", focus.next_label),
        p(class="attention-workbench-detail", focus.next_detail),
      ]),
      render_feed(
        feed_items(
          model,
          workers,
          executions,
          events,
        ),
      ),
    ]),
  ])
}
