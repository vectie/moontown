///|
priv struct RuntimeControlDelta {
  budget : Int
  energy : Int
  pressure : Int
  stability : Int
}

///|
fn model_only_update(model : Model) -> (Cmd, Model) {
  (@rabbita.none, model)
}

///|
fn metric_after_delta(value : Int, delta : Int) -> Int {
  clamp_metric(value + delta)
}

///|
fn apply_runtime_control_delta(
  model : Model,
  delta : RuntimeControlDelta,
) -> Model {
  {
    ..model,
    budget: metric_after_delta(model.budget, delta.budget),
    energy: metric_after_delta(model.energy, delta.energy),
    pressure: metric_after_delta(model.pressure, delta.pressure),
    stability: metric_after_delta(model.stability, delta.stability),
  }
}

///|
fn inject_budget_model(model : Model) -> Model {
  apply_runtime_control_delta(model, {
    budget: 14,
    energy: 3,
    pressure: -6,
    stability: 0,
  })
}

///|
fn relieve_queue_model(model : Model) -> Model {
  apply_runtime_control_delta(model, {
    budget: 0,
    energy: -2,
    pressure: -16,
    stability: 4,
  })
}

///|
fn stability_drill_model(model : Model) -> Model {
  apply_runtime_control_delta(model, {
    budget: -7,
    energy: 5,
    pressure: 0,
    stability: 15,
  })
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
fn toggle_state_source_model(model : Model) -> Model {
  { ..model, state_source: next_state_source(model.state_source) }
}
