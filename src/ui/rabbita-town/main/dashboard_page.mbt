///|
fn render_dashboard_page(
  dispatch : Dispatch[Msg],
  model : Model,
  context : OperationsContext,
) -> @rabbita.Html {
  section(class="town-shell", [
    render_town_launchpad(
      model,
      context.workers,
      context.executions,
      context.town_title,
      context.alerts,
    ),
    div(class="town-operations-deck", [
      render_request_desk(dispatch, model),
      render_attention_workbench(
        model,
        context.workers,
        context.executions,
        context.state.events,
      ),
      render_dashboard_ecosystem_workspace(dispatch, model),
      render_operations_migration_tools(model),
    ]),
    render_dashboard_ecosystem_detail(model),
    render_dashboard_ecosystem_preview(),
  ])
}

///|
fn render_operations_migration_tools(model : Model) -> @rabbita.Html {
  if current_browser_query_param("panel") != "migration" {
    return a(
      class="town-operations-migration-link",
      href="./operations.html?panel=migration",
      "Integration tools",
    )
  }
  section(class="town-operations-migration-tools", [
    render_editor_pipeline_panel(model),
    render_town_editor_boundary_panel(model),
    render_moondesk_handoff_panel(model),
    render_moondesk_bridge_panel(model),
  ])
}
