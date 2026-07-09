///|
fn model_only_update(model : Model) -> (Cmd, Model) {
  (@rabbita.none, model)
}

///|
fn toggle_pause_model(model : Model) -> Model {
  { ..model, paused: !model.paused }
}

///|
fn set_viewport_mode_model(
  model : Model,
  viewport_mode : ViewportMode,
) -> Model {
  { ..model, viewport_mode, selection: Selection::Overview }
}

///|
fn set_dashboard_section_model(
  model : Model,
  dashboard_section : DashboardSection,
) -> Model {
  { ..model, dashboard_section }
}

///|
fn set_request_composer_model(
  model : Model,
  request_composer : RequestComposerFocus,
) -> Model {
  { ..model, request_composer }
}
