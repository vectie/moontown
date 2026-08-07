///|
test "canonical canvas owns default and historical frontend entry paths" {
  for pathname in ["/", "/index.html", "/viewport.html"] {
    assert_true(
      town_surface_route(pathname, "", false) is CanonicalEnergyValley,
    )
  }
  assert_true(
    town_surface_route("/viewport.html", "viewport", false)
    is CanonicalEnergyValley,
  )
}

///|
test "historical viewport and legacy surface resolve the canonical town" {
  assert_true(
    town_surface_route("/viewport.html", "legacy-viewport", false)
    is CanonicalEnergyValley,
  )
  assert_true(
    town_surface_route("/index.html", "legacy-viewport", false)
    is CanonicalEnergyValley,
  )
}

///|
test "handoffs always open on the canonical canvas" {
  assert_true(
    town_surface_route("/viewport.html", "", true) is CanonicalEnergyValley,
  )
  assert_true(
    town_surface_route("/operations.html", "operations", true)
    is CanonicalEnergyValley,
  )
  assert_true(
    town_surface_route("/viewport.html", "legacy-viewport", true)
    is CanonicalEnergyValley,
  )
}

///|
test "operations remains an explicit separate surface" {
  assert_true(
    town_surface_route("/operations.html", "", false) is OperationsConsole,
  )
  assert_true(
    town_surface_route("/index.html", "operations", false) is OperationsConsole,
  )
  assert_true(
    town_surface_route("/operations.html", "legacy-viewport", false)
    is OperationsConsole,
  )
}

///|
test "canonical canvas seed is stable unless explicitly varied" {
  assert_eq(canonical_energy_valley_seed(0), default_energy_valley_seed)
  assert_eq(
    canonical_energy_valley_seed(default_energy_valley_seed),
    default_energy_valley_seed,
  )
  assert_eq(canonical_energy_valley_seed(42), 42)
  assert_eq(canonical_energy_valley_seed(-42), 42)
}

///|
test "maintained navigation targets only the canonical town" {
  assert_eq(canonical_energy_valley_href(), "./index.html?seed=20260727")
  assert_eq(
    canonical_energy_valley_dashboard_href(),
    "./index.html?seed=20260727&panel=dashboard",
  )
  assert_eq(
    canonical_energy_valley_module_href("policy-hall"),
    "./index.html?seed=20260727&module=policy-hall",
  )
}

///|
test "dashboard panel query opens the canonical runtime board" {
  assert_true(energy_valley_dashboard_requested("dashboard"))
  assert_false(energy_valley_dashboard_requested(""))
  assert_false(energy_valley_dashboard_requested("output"))
}

///|
fn render_canonical_handoff_layer_test_html(model : Model) -> String {
  @rabbita.render_to_string(
    @rabbita.static_cell(
      render_energy_valley_handoff_layer(dashboard_test_dispatch(), model),
    ),
  )
}

///|
test "canonical canvas renders governed research handoff panels" {
  let html = render_canonical_handoff_layer_test_html({
    ..init_model(),
    energy_intro_open: false,
    research_handoff: BlockedResearchHandoff("fixture handoff blocked"),
  })
  assert_true(html.contains("energy-valley-handoff-layer"))
  assert_true(html.contains("research-handoff-panel"))
  assert_true(html.contains("fixture handoff blocked"))
}

///|
test "canonical canvas renders governed MoonFlow receiver panels" {
  let html = render_canonical_handoff_layer_test_html({
    ..init_model(),
    energy_intro_open: false,
    moonflow_receiver: BlockedMoonFlowReceiver("fixture receiver blocked"),
  })
  assert_true(html.contains("energy-valley-handoff-layer"))
  assert_true(html.contains("research-handoff-panel"))
  assert_true(html.contains("fixture receiver blocked"))
}
