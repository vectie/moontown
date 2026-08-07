///|
fn reject_operations_context_build(_model : Model) -> OperationsContext {
  abort("canonical town must not build an Operations context")
}

///|
test "canonical render plan never requests the retired scene pipeline" {
  let plan = town_surface_render_plan_with_context_builder(
    CanonicalEnergyValley,
    init_model(),
    reject_operations_context_build,
  )
  assert_true(plan is CanonicalTownProduct)
}

///|
test "explicit Operations route builds its separate operating context" {
  match town_surface_render_plan(OperationsConsole, init_model()) {
    OperationsProduct(context) => {
      assert_eq(context.town_title, "Wenyu Valley / AI Innovation Town")
      assert_true(!context.workers.is_empty())
    }
    CanonicalTownProduct => abort("Operations must keep its separate surface")
  }
}
