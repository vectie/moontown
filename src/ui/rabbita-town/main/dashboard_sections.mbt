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
    EcosystemOverview => "Areas"
    DistrictSystems => "Districts"
    ResidentAgentsSection => "Residents"
    CivicQuestsSection => "Quests"
    SocialCapitalSection => "Social capital"
  }
}

///|
fn dashboard_section_kicker(target : DashboardSection) -> String {
  match target {
    EcosystemOverview => "Closed by default"
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
      "Open district, resident, quest, or social-capital detail only when that area needs work."
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
fn render_town_area_closed_panel(model : Model) -> @rabbita.Html {
  div(class="town-area-closed-panel", [
    p(class="metric-label", "Default closed"),
    p(class="metric-detail", dashboard_section_summary(EcosystemOverview, model)),
  ])
}

///|
fn render_dashboard_section_panel(model : Model) -> @rabbita.Html {
  match model.dashboard_section {
    EcosystemOverview => render_town_area_closed_panel(model)
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
  section(class="town-areas-launcher", [
    div(class="town-areas-head", [
      div([
        p(class="eyebrow", "Town Areas"),
        h2("Open detail only when needed"),
        p(
          class="summary",
          "Keep routine work centered on watches, reviews, requests, and the map. Open a town area when a specific civic surface needs inspection.",
        ),
      ]),
      render_dashboard_section_tabs(dispatch, model.dashboard_section),
    ]),
    render_dashboard_section_panel(model),
  ])
}
