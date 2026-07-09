///|
fn request_action_button_class(
  active : RequestComposerFocus,
  target : RequestComposerFocus,
) -> String {
  if active == target {
    "request-action-button is-active"
  } else {
    "request-action-button"
  }
}

///|
fn render_request_action_button(
  dispatch : Dispatch[Msg],
  model : Model,
  target : RequestComposerFocus,
  label : String,
  action : String,
) -> @rabbita.Html {
  button(
    class=request_action_button_class(model.request_composer, target),
    on_click=dispatch(SetRequestComposer(target)),
    [
      span(class="request-action-label", label),
      span(class="request-action-command", action),
    ],
  )
}

///|
fn render_request_shortcuts(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  div(class="request-action-dock", [
    render_request_action_button(
      dispatch,
      model,
      RequestComposerFocus::StandingWatchComposer,
      "Standing watch",
      operator_request_submit_label(false),
    ),
    render_request_action_button(
      dispatch,
      model,
      RequestComposerFocus::EvidenceBookComposer,
      "Evidence book",
      book_template_request_submit_label(false),
    ),
  ])
}

///|
fn render_request_desk_workspace(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  match model.request_composer {
    RequestShortcuts => div(class="request-desk-stack is-empty", no_children())
    StandingWatchComposer => div(class="request-desk-stack", [
      render_request_composer(dispatch, model),
    ])
    EvidenceBookComposer => div(class="request-desk-stack", [
      render_book_template_composer(dispatch, model),
    ])
  }
}
