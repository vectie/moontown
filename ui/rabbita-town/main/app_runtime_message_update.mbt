///|
fn schedule_tick_if_running(dispatch : Dispatch[Msg], model : Model) -> Cmd {
  if model.paused {
    @rabbita.none
  } else {
    schedule_tick(dispatch)
  }
}

///|
fn tick_update(dispatch : Dispatch[Msg], model : Model) -> (Cmd, Model) {
  let next = advance_model(model)
  (schedule_tick_if_running(dispatch, next), next)
}

///|
fn toggle_pause_update(dispatch : Dispatch[Msg], model : Model) -> (Cmd, Model) {
  let next = toggle_pause_model(model)
  (schedule_tick_if_running(dispatch, next), next)
}

///|
fn step_update(model : Model) -> (Cmd, Model) {
  if model.paused {
    model_only_update(advance_model(model))
  } else {
    model_only_update(model)
  }
}
