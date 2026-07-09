///|
fn render_scene(dispatch : Dispatch[Msg], model : Model) -> @rabbita.Html {
  let context = render_scene_context(model)
  if standalone_viewport_requested() {
    render_standalone_viewport_page(dispatch, model, context)
  } else {
    render_dashboard_page(dispatch, model, context)
  }
}

///|
fn main {
  let (dispatch, app) = @rabbita.cell_with_emit(model=init_model(), update~, view=(
    dispatch,
    model,
  ) => render_scene(dispatch, model))
  @rabbita.new(app)..with_init(schedule_tick(dispatch)).mount("app")
  install_viewport_drag_pan()
}

///|
