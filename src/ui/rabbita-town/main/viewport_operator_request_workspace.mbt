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
  let selected = model.request_composer == target
  button(
    class=request_action_button_class(model.request_composer, target),
    on_click=dispatch(SetRequestComposer(target)),
    attrs=@html.Attrs::build()
      .aria_pressed(if selected { "true" } else { "false" })
      .aria_expanded(if selected { "true" } else { "false" })
      .aria_controls("request-composer-panel"),
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
  div(
    class="request-action-dock",
    attrs=@html.Attrs::build().role("group").aria_label("Request type"),
    [
      render_request_action_button(
        dispatch,
        model,
        RequestComposerFocus::StandingWatchComposer,
        "Standing watch",
        "Save",
      ),
      render_request_action_button(
        dispatch,
        model,
        RequestComposerFocus::EvidenceBookComposer,
        "Evidence book",
        "Queue",
      ),
    ],
  )
}

///|
fn render_request_desk_workspace(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  match model.request_composer {
    RequestShortcuts =>
      div(
        id="request-composer-panel",
        class="request-desk-stack is-empty",
        no_children(),
      )
    StandingWatchComposer =>
      div(id="request-composer-panel", class="request-desk-stack", [
        render_request_composer(dispatch, model),
      ])
    EvidenceBookComposer =>
      div(id="request-composer-panel", class="request-desk-stack", [
        render_book_template_composer(dispatch, model),
      ])
  }
}
