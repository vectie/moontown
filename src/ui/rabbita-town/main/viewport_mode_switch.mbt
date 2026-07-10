///|
fn render_viewport_mode_button(
  dispatch : Dispatch[Msg],
  model : Model,
  mode : ViewportMode,
) -> @rabbita.Html {
  let selected = model.viewport_mode == mode
  let active = class_suffix_when(selected, " is-active")
  button(
    class="control-button viewport-mode-button\{active}",
    on_click=dispatch(SetViewportMode(mode)),
    attrs=@html.Attrs::build().aria_pressed(
      if selected {
        "true"
      } else {
        "false"
      },
    ),
    viewport_mode_label(mode),
  )
}

///|
fn render_viewport_mode_switch(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  div(
    class="viewport-mode-switch",
    attrs=@html.Attrs::build().role("group").aria_label("Viewport mode"),
    [
      render_viewport_mode_button(dispatch, model, ViewportMode::ViewMode),
      render_viewport_mode_button(dispatch, model, ViewportMode::EditorMode),
      render_viewport_mode_button(dispatch, model, ViewportMode::OutputMode),
    ],
  )
}
