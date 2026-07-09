///|
fn render_dashboard_page(
  dispatch : Dispatch[Msg],
  model : Model,
  context : RenderSceneContext,
) -> @rabbita.Html {
  section(class="town-shell", [
    render_operator_masthead(context.scene, context.alerts),
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
