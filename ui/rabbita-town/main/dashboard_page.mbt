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
          "A pixel-art always-on AI town: mayor supervision, resident agents, district services, and virtual-physical feedback loops.",
        ),
        render_controls(dispatch, model),
      ]),
      render_alerts(context.alerts),
    ]),
    render_operator_command_center(
      dispatch, model, context.workers, context.executions,
    ),
    main_(class="town-main", [
      div(class="scene-column", [
        render_wenyu_viewport_portal(model, context.scene, context.executions),
      ]),
      div(class="sidebar-column", [
        render_inspector(
          dispatch, model, context.scene, context.workers, context.executions,
        ),
        render_feed(
          feed_items(
            model,
            context.workers,
            context.executions,
            context.state.events,
          ),
        ),
        aside(class="scene-legend", [
          h2("Legend"),
          p("City Hall is the mayor runtime and policy anchor."),
          p("Moonbook houses hold keeper-owned domain planning."),
          p(
            "Worker avatars now move between yard, hall, books, and anomaly response.",
          ),
          p(
            "Actions on the header feed directly back into queue pressure and town stability.",
          ),
        ]),
      ]),
    ]),
    section(class="metric-grid", render_vitality_metric_grid(model)),
    render_civic_context(model),
    render_runtime_bar(model, context.workers, context.executions),
    render_civic_modules(model),
    render_resident_agents(model),
    render_civic_quests(model),
    render_social_talent(model),
    render_bridge_contract(model),
  ])
}
