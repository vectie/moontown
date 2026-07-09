///|
fn request_shortcut_card_class(
  active : RequestComposerFocus,
  target : RequestComposerFocus,
) -> String {
  if active == target {
    "request-shortcut-card is-active"
  } else {
    "request-shortcut-card"
  }
}

///|
fn render_request_shortcut_card(
  dispatch : Dispatch[Msg],
  model : Model,
  target : RequestComposerFocus,
  eyebrow : String,
  title : String,
  detail : String,
  action : String,
) -> @rabbita.Html {
  button(
    class=request_shortcut_card_class(model.request_composer, target),
    on_click=dispatch(SetRequestComposer(target)),
    [
      p(class="metric-label", eyebrow),
      h3(title),
      p(class="metric-detail", detail),
      span(class="request-shortcut-action", action),
    ],
  )
}

///|
fn render_request_shortcuts(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  div(class="request-shortcut-grid", [
    render_request_shortcut_card(
      dispatch,
      model,
      RequestComposerFocus::StandingWatchComposer,
      "Standing watch",
      "Keep watching a topic",
      "Track useful evidence changes in an existing MoonBook.",
      operator_request_submit_label(false),
    ),
    render_request_shortcut_card(
      dispatch,
      model,
      RequestComposerFocus::EvidenceBookComposer,
      "Evidence book",
      "Create a PDF evidence watch",
      "Use when a new durable book needs approved PDF sources.",
      book_template_request_submit_label(false),
    ),
  ])
}

///|
fn render_request_desk_workspace(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  let children = [render_request_shortcuts(dispatch, model)]
  match model.request_composer {
    RequestShortcuts => ()
    StandingWatchComposer => children.push(render_request_composer(dispatch, model))
    EvidenceBookComposer => children.push(render_book_template_composer(dispatch, model))
  }
  div(class="request-desk-stack", children)
}
