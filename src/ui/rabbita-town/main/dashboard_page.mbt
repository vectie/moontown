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
        render_professional_status_strip(model),
      ]),
      render_alerts(context.alerts),
    ]),
    render_professional_overview(model, context.workers, context.executions),
    main_(class="town-main", [
      div(class="scene-column", [
        render_wenyu_viewport_portal(model, context.scene, context.executions),
      ]),
      div(class="sidebar-column", [
        render_professional_brief(model, context.workers, context.executions),
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
            "Open the Wenyu viewport when you need the full map and deeper runtime tools.",
          ),
        ]),
      ]),
    ]),
    section(class="metric-grid", render_vitality_metric_grid(model)),
    render_operator_command_center(
      dispatch,
      model,
      context.workers,
      context.executions,
    ),
    render_civic_context(model),
    render_advanced_operations(
      dispatch,
      model,
      context.workers,
      context.executions,
    ),
    render_civic_modules(model),
    render_resident_agents(model),
    render_civic_quests(model),
    render_social_talent(model),
  ])
}
