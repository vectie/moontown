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
