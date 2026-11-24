///|
priv enum TownSurfaceRenderPlan {
  CanonicalTownProduct
  OperationsProduct(OperationsContext)
}

///|
fn town_surface_render_plan_with_context_builder(
  route : TownSurfaceRoute,
  model : Model,
  build_context : (Model) -> OperationsContext,
) -> TownSurfaceRenderPlan {
  match route {
    CanonicalEnergyValley => CanonicalTownProduct
    OperationsConsole => OperationsProduct(build_context(model))
  }
}

///|
fn town_surface_render_plan(
  route : TownSurfaceRoute,
  model : Model,
) -> TownSurfaceRenderPlan {
  town_surface_render_plan_with_context_builder(
    route, model, build_operations_context,
  )
}

///|
fn render_town_surface_for_route(
  route : TownSurfaceRoute,
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  match town_surface_render_plan(route, model) {
    CanonicalTownProduct => render_energy_valley_page(dispatch, model)
    OperationsProduct(context) =>
      render_dashboard_page(dispatch, model, context)
  }
}

///|
fn render_town_surface(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  render_account_surface_for_route(
    current_town_surface_route(),
    dispatch,
    model,
    parse_bootstrap_account_experience(),
  )
}

///|
fn main {
  if building_public_baseline() {
    let world = energy_valley_base_contract_world_for_seed(
      default_energy_valley_seed,
    )
    let issues = @energy_valley_contract.validate_world(world)
    if !browser_energy_valley_authoritative_reference_ready() ||
      @energy_valley_contract.has_errors(issues) {
      abort("Cannot package an unvalidated public baseline")
    }
    publish_build_baseline(world, [..issues])
    return
  }
  let model = init_model()
  let (dispatch, app) = @rabbita.cell_with_emit(model~, update~, view=(
    dispatch,
    model,
  ) => render_town_surface(dispatch, model))
  @rabbita.new(app)..with_init(initial_app_cmd(dispatch, model)).mount("app")
  install_viewport_drag_pan()
}

///|
