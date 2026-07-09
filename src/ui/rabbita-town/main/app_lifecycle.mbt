///|
fn schedule_tick(dispatch : Dispatch[Msg]) -> Cmd {
  @rabbita.delay(dispatch(Tick), 1200)
}

///|
fn update(dispatch : Dispatch[Msg], msg : Msg, model : Model) -> (Cmd, Model) {
  match form_model_for_msg(model, msg) {
    Some(next) => model_only_update(next)
    None => update_non_form_message(dispatch, msg, model)
  }
}

///|
fn update_non_form_message(
  dispatch : Dispatch[Msg],
  msg : Msg,
  model : Model,
) -> (Cmd, Model) {
  match msg {
    ViewportControlNoop => model_only_update(model)
    Tick => tick_update(dispatch, model)
    TogglePause => toggle_pause_update(dispatch, model)
    Step => step_update(model)
    SelectWorker(worker_id) =>
      model_only_update({ ..model, selection: Worker(worker_id) })
    SelectNode(node_key) =>
      model_only_update({ ..model, selection: Node(node_key) })
    SelectOverview => model_only_update({ ..model, selection: Overview })
    SetViewportMode(viewport_mode) =>
      model_only_update(set_viewport_mode_model(model, viewport_mode))
    SubmitOperatorRequest => submit_operator_request_update(dispatch, model)
    SubmitBookTemplateRequest =>
      submit_book_template_request_update(dispatch, model)
    OperatorRequestSubmitted(raw) => operator_request_result_update(raw, model)
    BookTemplateRequestSubmitted(raw) =>
      book_template_request_result_update(raw, model)
    _ => model_only_update(model)
  }
}

///|
