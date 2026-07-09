///|
fn render_dashboard_page(
  dispatch : Dispatch[Msg],
  model : Model,
  context : RenderSceneContext,
) -> @rabbita.Html {
  section(class="town-shell", [
    render_town_launchpad(
      model,
      context.workers,
      context.executions,
      context.scene,
      context.alerts,
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
