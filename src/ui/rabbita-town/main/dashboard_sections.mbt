///|
fn dashboard_sections() -> Array[DashboardSection] {
  [
    EcosystemOverview,
    DistrictSystems,
    ResidentAgentsSection,
    CivicQuestsSection,
    SocialCapitalSection,
  ]
}

///|
fn dashboard_section_label(target : DashboardSection) -> String {
  match target {
    EcosystemOverview => "Overview"
    DistrictSystems => "Districts"
    ResidentAgentsSection => "Residents"
    CivicQuestsSection => "Quests"
    SocialCapitalSection => "Social capital"
  }
}

///|
fn dashboard_section_kicker(target : DashboardSection) -> String {
  match target {
    EcosystemOverview => "Choose a surface"
    DistrictSystems => "Live civic modules"
    ResidentAgentsSection => "Projection-safe twins"
    CivicQuestsSection => "Service workflows"
    SocialCapitalSection => "Matches and reception"
  }
}

///|
fn dashboard_section_summary(target : DashboardSection, model : Model) -> String {
  match target {
    EcosystemOverview =>
      "Keep the default cockpit clean; open a focused ecosystem surface only when you need it."
    DistrictSystems =>
      "\{wenyu_modules().length()} district modules with worker, queue, and health signals."
    ResidentAgentsSection =>
      "\{resident_count(model)} resident projections with private memory kept out of town view."
    CivicQuestsSection =>
      "\{civic_quests(model).length()} service quests across policy, contest, AI, social, and physical bridge work."
    SocialCapitalSection =>
      "\{social_matches().length()} active match lanes plus talent evidence and reception routing."
  }
}

///|
fn dashboard_section_button_class(
  active : DashboardSection,
  target : DashboardSection,
) -> String {
  if active == target {
    "dashboard-section-tab is-active"
  } else {
    "dashboard-section-tab"
  }
}

///|
fn render_dashboard_section_tab(
  dispatch : Dispatch[Msg],
  active : DashboardSection,
  target : DashboardSection,
) -> @rabbita.Html {
  button(
    class=dashboard_section_button_class(active, target),
    on_click=dispatch(SetDashboardSection(target)),
    [
      span(class="dashboard-section-label", dashboard_section_label(target)),
      span(class="dashboard-section-kicker", dashboard_section_kicker(target)),
    ],
  )
}

///|
fn render_dashboard_section_tabs(
  dispatch : Dispatch[Msg],
  active : DashboardSection,
) -> @rabbita.Html {
  div(
    class="dashboard-section-tabs",
    dashboard_sections().map(target => {
      render_dashboard_section_tab(dispatch, active, target)
    }),
  )
}

///|
fn render_dashboard_overview_card(
  dispatch : Dispatch[Msg],
  model : Model,
  target : DashboardSection,
) -> @rabbita.Html {
  button(
    class="dashboard-overview-card",
    on_click=dispatch(SetDashboardSection(target)),
    [
      p(class="metric-label", dashboard_section_kicker(target)),
      h3(dashboard_section_label(target)),
      p(class="metric-detail", dashboard_section_summary(target, model)),
    ],
  )
}

///|
fn render_ecosystem_overview(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  div(class="dashboard-overview-grid", [
    render_dashboard_overview_card(dispatch, model, DistrictSystems),
    render_dashboard_overview_card(dispatch, model, ResidentAgentsSection),
    render_dashboard_overview_card(dispatch, model, CivicQuestsSection),
    render_dashboard_overview_card(dispatch, model, SocialCapitalSection),
  ])
}

///|
fn render_dashboard_section_panel(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  match model.dashboard_section {
    EcosystemOverview => render_ecosystem_overview(dispatch, model)
    DistrictSystems => div(class="dashboard-section-panel-stack", [
      render_civic_context(model),
      render_civic_modules(model),
    ])
    ResidentAgentsSection => render_resident_agents(model)
    CivicQuestsSection => render_civic_quests(model)
    SocialCapitalSection => render_social_talent(model)
  }
}

///|
fn render_dashboard_ecosystem_workspace(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  section(class="dashboard-ecosystem", [
    div(class="dashboard-ecosystem-head", [
      div([
        p(class="eyebrow", "Ecosystem"),
        h2("Focused town surfaces"),
        p(
          class="summary",
          "District, resident, quest, and social-capital detail is available on purpose. The default cockpit stays centered on watches, reviews, requests, and map entry.",
        ),
      ]),
      render_dashboard_section_tabs(dispatch, model.dashboard_section),
    ]),
    render_dashboard_section_panel(dispatch, model),
  ])
}
