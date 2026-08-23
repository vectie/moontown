///|
fn model_only_update(model : Model) -> (Cmd, Model) {
  (@rabbita.none, model)
}

///|
fn set_town_spatial_layer_model(
  model : Model,
  layer : TownSpatialLayer,
) -> Model {
  replace_browser_query_param(
    "layer",
    match layer {
      Outdoor => ""
      Indoor(_) => "indoor"
      Underground(_) => "compute"
    },
  )
  replace_browser_query_param(
    "building",
    match layer {
      Indoor(building) => golden_valley_building_civic_id(building)
      _ => ""
    },
  )
  { ..model, town_spatial_layer: layer }
}

///|
fn toggle_pause_model(model : Model) -> Model {
  { ..model, paused: !model.paused }
}

///|
fn set_dashboard_section_model(
  model : Model,
  dashboard_section : DashboardSection,
) -> Model {
  let next = match model.dashboard_section {
    Some(active) =>
      if active == dashboard_section {
        None
      } else {
        Some(dashboard_section)
      }
    None => Some(dashboard_section)
  }
  replace_browser_query_param(
    "area",
    match next {
      Some(section) => dashboard_section_param(section)
      None => ""
    },
  )
  { ..model, dashboard_section: next }
}

///|
fn dashboard_section_param(section : DashboardSection) -> String {
  match section {
    DistrictSystems => "districts"
    ResidentAgentsSection => "residents"
    CivicQuestsSection => "quests"
    SocialCapitalSection => "social"
  }
}

///|
fn set_request_composer_model(
  model : Model,
  request_composer : RequestComposerFocus,
) -> Model {
  replace_browser_query_param(
    "request",
    match request_composer {
      RequestShortcuts => ""
      StandingWatchComposer => "watch"
      EvidenceBookComposer => "book"
    },
  )
  { ..model, request_composer, }
}
