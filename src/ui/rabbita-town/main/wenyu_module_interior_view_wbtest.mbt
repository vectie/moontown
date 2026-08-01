///|
fn module_interior_test_projection() -> BookProjectionFragment {
  {
    book_id: "wenyu-policy-hall",
    title: "Policy Hall",
    summary: "Policy output",
    status_chips: [],
    metrics: [],
    readiness: [],
    review_queue: [],
    page_families: [],
    journey: [],
    links: [],
    acceptance_receipt: None,
  }
}

///|
fn render_module_interior_overview_test_html(
  civic : WenyuTownModule,
  runtime : WenyuModuleRuntimeState,
  projection : BookProjectionFragment?,
) -> String {
  @rabbita.render_to_string(
    @rabbita.static_cell(
      render_module_interior_overview(civic, runtime, projection),
    ),
  )
}

///|
fn module_interior_test_civic() -> WenyuTownModule {
  procedural_energy_valley_modules(
    [
      {
        ..wenyu_module_building_test_module(),
        district: "civic-core",
        grid_x: 114,
        grid_y: 66,
        footprint_w: 7,
        footprint_h: 5,
        entrance_x: 114,
        entrance_y: 71,
      },
    ],
    default_energy_valley_seed,
  )[0]
}

///|
test "module interior presents professional operating content by default" {
  let civic = { ..module_interior_test_civic(), district: "civic-core" }
  let runtime = wenyu_module_building_test_runtime()
  let html = render_module_interior_overview_test_html(civic, runtime, None)
  assert_true(html.contains("Policy Hall building"))
  assert_eq(module_interior_district_label(civic.district), "Civic Core")
  assert_true(html.contains("Current operation"))
  assert_true(html.contains(civic.use_case))
  assert_true(html.contains("2 active"))
  assert_true(html.contains("Book pending"))
  assert_true(html.contains("Open output status"))
  assert_true(!html.contains("10,13"))
  assert_true(!html.contains("research-salon"))
  assert_true(!html.contains("policy-hall / policy-hall"))
}

///|
test "module interior action routes setup and output intervention" {
  let civic = module_interior_test_civic()
  let runtime = wenyu_module_building_test_runtime()
  let setup = module_interior_action({ ..civic, asset_base: "" }, runtime, None)
  assert_eq(setup.unwrap().label, "Review setup")
  assert_true(setup.unwrap().href.contains("mode=editor"))
  let blocked = module_interior_action(
    civic,
    { ..runtime, blocked_count: 1 },
    Some(module_interior_test_projection()),
  )
  assert_eq(blocked.unwrap().label, "Review output")
  assert_eq(blocked.unwrap().href, canonical_energy_valley_dashboard_href())
  assert_true(
    module_interior_action(
      civic,
      runtime,
      Some(module_interior_test_projection()),
    )
    is None,
  )
}

///|
test "module interior signal prioritizes recovery review and active work" {
  let runtime = wenyu_module_building_test_runtime()
  assert_true(
    module_interior_signal({ ..runtime, blocked_count: 1 }, None).contains(
      "recovery",
    ),
  )
  assert_true(
    module_interior_signal(
      { ..runtime, running_count: 0, review_count: 1 },
      None,
    ).contains("Review work"),
  )
  assert_true(module_interior_signal(runtime, None).contains("Active work"))
  assert_true(
    module_interior_signal(
      { ..runtime, running_count: 0 },
      Some(module_interior_test_projection()),
    ).contains("connected"),
  )
}

///|
test "module diagnostics stay collapsed behind semantic disclosure" {
  let civic = wenyu_module_building_test_module()
  let runtime = wenyu_module_building_test_runtime()
  let html = @rabbita.render_to_string(
    @rabbita.static_cell(
      render_module_interior_diagnostics(init_model(), civic, runtime),
    ),
  )
  assert_true(html.contains("<details"))
  assert_true(html.contains("<summary"))
  assert_true(html.contains("Diagnostics"))
  assert_true(!html.contains("<details open"))
}

///|
test "full module interior keeps the town seed and repaired work systems" {
  let runtime = energy_valley_runtime_state_from_text(
    energy_valley_runtime_test_projection_text(
      "1970-01-01T00:01:40.000Z", "live",
    ),
    1,
    110000.0,
  )
  let html = @rabbita.render_to_string(
    @rabbita.static_cell(
      render_wenyu_module_interior(
        dashboard_test_dispatch(),
        { ..init_model(), energy_valley_runtime: runtime },
        module_interior_test_civic(),
        [],
        [],
      ),
    ),
  )
  assert_true(html.contains("Procedural work floor"))
  assert_true(html.contains("Agent exchange"))
  assert_true(html.contains("Recorded building work"))
  assert_true(html.contains("seed=20260727"))
}
