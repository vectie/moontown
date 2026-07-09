///|
fn render_operator_masthead(
  scene : @ui.SceneRenderModel,
  alerts : Array[String],
) -> @rabbita.Html {
  header(class="town-status-bar", [
    div(class="town-status-title", [
      p(class="eyebrow", "Moontown"),
      h1(scene.title),
    ]),
    div(class="town-status-alerts", [
      render_alerts(alerts),
    ]),
  ])
}
