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
      "Use this when an existing MoonBook should keep tracking useful evidence changes.",
      operator_request_submit_label(false),
    ),
    render_request_shortcut_card(
      dispatch,
      model,
      RequestComposerFocus::EvidenceBookComposer,
      "Evidence book",
      "Create a PDF evidence watch",
      "Use this less often, when the town needs a new durable book and approved PDF sources.",
      book_template_request_submit_label(false),
    ),
  ])
}

///|
fn render_request_focus_panel(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  match model.request_composer {
    RequestShortcuts => render_request_idle_panel()
    StandingWatchComposer => render_request_composer(dispatch, model)
    EvidenceBookComposer => render_book_template_composer(dispatch, model)
  }
}

///|
fn render_request_idle_panel() -> @rabbita.Html {
  article(class="request-idle-panel", [
    p(class="metric-label", "New work"),
    h3("Choose the next safe request"),
    p(
      class="metric-detail",
      "Most operators only need one request path at a time. Pick a watch or a book request when there is a concrete evidence job to create.",
    ),
  ])
}

///|
fn render_request_desk_workspace(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  div(class="request-desk-stack", [
    render_request_shortcuts(dispatch, model),
    render_request_focus_panel(dispatch, model),
  ])
}
