///|
fn render_viewport_mode_button(
  dispatch : Dispatch[Msg],
  model : Model,
  mode : ViewportMode,
) -> @rabbita.Html {
  let active = class_suffix_when(model.viewport_mode == mode, " is-active")
  button(
    class="control-button viewport-mode-button\{active}",
    on_click=dispatch(SetViewportMode(mode)),
    viewport_mode_label(mode),
  )
}

///|
fn render_viewport_mode_switch(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  div(class="viewport-mode-switch", [
    span(
      class="viewport-mode-current",
      viewport_mode_label(model.viewport_mode),
    ),
    render_viewport_mode_button(dispatch, model, ViewportMode::ViewMode),
    render_viewport_mode_button(dispatch, model, ViewportMode::EditorMode),
    render_viewport_mode_button(dispatch, model, ViewportMode::OutputMode),
    a(
      href="./viewport.html?assets=generated&mode=\{viewport_mode_slug(model.viewport_mode)}&v=wenyu",
      class="viewport-mode-link",
      "Copyable Mode URL",
    ),
  ])
}
