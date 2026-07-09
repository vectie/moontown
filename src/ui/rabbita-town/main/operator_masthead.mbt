///|
fn render_operator_masthead(
  scene : @ui.SceneRenderModel,
  alerts : Array[String],
) -> @rabbita.Html {
  header(class="operator-masthead", [
    div(class="operator-masthead-title", [
      div(class="operator-masthead-brand", [
        p(class="eyebrow", "Moontown"),
        status_chip("Wenyu Valley workspace", "chip-book"),
      ]),
      h1(scene.title),
      p(
        class="summary",
        "Civic watches, resident agents, district services, and review-ready feedback loops.",
      ),
    ]),
    div(class="operator-masthead-alerts", [
      p(class="metric-label", "Signal"),
      render_alerts(alerts),
    ]),
  ])
}
