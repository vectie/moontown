///|
fn dashboard_sections() -> Array[DashboardSection] {
  [
    DistrictSystems,
    ResidentAgentsSection,
    CivicQuestsSection,
    SocialCapitalSection,
  ]
}

///|
fn dashboard_section_label(target : DashboardSection) -> String {
  match target {
    DistrictSystems => "Districts"
    ResidentAgentsSection => "Residents"
    CivicQuestsSection => "Quests"
    SocialCapitalSection => "Social"
  }
}

///|
fn dashboard_section_button_class(
  active : DashboardSection?,
  target : DashboardSection,
) -> String {
  match active {
    Some(section) =>
      if section == target {
        "dashboard-section-tab is-active"
      } else {
        "dashboard-section-tab"
      }
    None => "dashboard-section-tab"
  }
}

///|
fn render_dashboard_section_tab(
  dispatch : Dispatch[Msg],
  active : DashboardSection?,
  target : DashboardSection,
) -> @rabbita.Html {
  button(
    class=dashboard_section_button_class(active, target),
    on_click=dispatch(SetDashboardSection(target)),
    [span(class="dashboard-section-label", dashboard_section_label(target))],
  )
}

///|
fn render_dashboard_section_tabs(
  dispatch : Dispatch[Msg],
  active : DashboardSection?,
) -> @rabbita.Html {
  div(
    class="dashboard-section-tabs",
    dashboard_sections().map(target => {
      render_dashboard_section_tab(dispatch, active, target)
    }),
  )
}

///|
fn render_dashboard_section_panel(
  target : DashboardSection,
  model : Model,
) -> @rabbita.Html {
  match target {
    DistrictSystems =>
      div(class="dashboard-section-panel-stack", [
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
      h2(class="town-areas-title", "Town Areas"),
      render_dashboard_section_tabs(dispatch, model.dashboard_section),
    ]),
  ])
}

///|
fn render_dashboard_ecosystem_detail(model : Model) -> @rabbita.Html {
  match model.dashboard_section {
    Some(selected) =>
      section(class="town-area-detail", [
        render_dashboard_section_panel(selected, model),
      ])
    None => div(class="town-area-detail-empty", no_children())
  }
}
