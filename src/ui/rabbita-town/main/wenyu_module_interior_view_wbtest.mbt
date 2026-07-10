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
test "module interior presents professional operating content by default" {
  let civic = { ..wenyu_module_building_test_module(), district: "civic-core" }
  let runtime = wenyu_module_building_test_runtime()
  let html = render_module_interior_overview_test_html(civic, runtime, None)
  assert_true(html.contains("Policy Hall building"))
  assert_eq(module_interior_district_label(civic.district), "Civic Core")
  assert_true(html.contains("Current operation"))
  assert_true(html.contains("policy triage"))
  assert_true(html.contains("2 active"))
  assert_true(html.contains("Book pending"))
  assert_true(html.contains("Open output status"))
  assert_true(!html.contains("10,13"))
  assert_true(!html.contains("research-salon"))
  assert_true(!html.contains("policy-hall / policy-hall"))
}

///|
test "module interior action routes setup and output intervention" {
  let civic = wenyu_module_building_test_module()
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
  assert_true(blocked.unwrap().href.contains("mode=output"))
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
