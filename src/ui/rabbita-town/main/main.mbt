///|
fn render_scene(dispatch : Dispatch[Msg], model : Model) -> @rabbita.Html {
  let context = render_scene_context(model)
  if standalone_viewport_requested() {
    render_standalone_viewport_page(dispatch, model, context)
  } else if operations_surface_requested() {
    render_dashboard_page(dispatch, model, context)
  } else {
    render_energy_valley_page(dispatch, model)
  }
}

///|
fn main {
  let model = init_model()
  let (dispatch, app) = @rabbita.cell_with_emit(model~, update~, view=(
    dispatch,
    model,
  ) => render_scene(dispatch, model))
  @rabbita.new(app)..with_init(initial_app_cmd(dispatch, model)).mount("app")
  install_viewport_drag_pan()
}

///|
