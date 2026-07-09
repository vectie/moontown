///|
fn render_dashboard_page(
  dispatch : Dispatch[Msg],
  model : Model,
  context : RenderSceneContext,
) -> @rabbita.Html {
  section(class="town-shell", [
    header(class="town-header", [
      div(class="title-block", [
        p(class="eyebrow", "Moontown"),
        h1(context.scene.title),
        p(
          class="summary",
          "Professional town workspace for civic watches, resident agents, district services, and review-ready feedback loops.",
        ),
      ]),
      render_alerts(context.alerts),
    ]),
    render_town_launchpad(
      model,
      context.workers,
      context.executions,
      context.scene,
    ),
    render_request_desk(dispatch, model),
    render_attention_workbench(
      model,
      context.workers,
      context.executions,
      context.state.events,
    ),
    render_dashboard_ecosystem_workspace(dispatch, model),
  ])
}
