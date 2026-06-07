///|
test "metric delta helper clamps control values" {
  assert_eq(metric_after_delta(96, 14), 100)
  assert_eq(metric_after_delta(3, -16), 0)
  assert_eq(metric_after_delta(40, 5), 45)
}

///|
test "runtime control delta preserves unrelated model state" {
  let model = init_model()
  let next = apply_runtime_control_delta(model, {
    budget: 40,
    energy: -80,
    pressure: 10,
    stability: -90,
  })
  assert_eq(next.budget, 100)
  assert_eq(next.energy, 0)
  assert_eq(next.pressure, model.pressure + 10)
  assert_eq(next.stability, 0)
  assert_eq(next.tick, model.tick)
  assert_true(next.selection is Selection::Overview)
}

///|
test "viewport mode helper resets selection to overview" {
  let model = { ..init_model(), selection: Selection::Node("policy-hall") }
  let next = set_viewport_mode_model(model, ViewportMode::EditorMode)
  assert_true(next.viewport_mode == ViewportMode::EditorMode)
  assert_true(next.selection is Selection::Overview)
}

///|
test "named runtime controls document operator intent" {
  let model = {
    ..init_model(),
    budget: 50,
    energy: 50,
    pressure: 50,
    stability: 50,
  }
  let funded = inject_budget_model(model)
  assert_eq(funded.budget, 64)
  assert_eq(funded.energy, 53)
  assert_eq(funded.pressure, 44)
  assert_eq(funded.stability, 50)
  let relieved = relieve_queue_model(model)
  assert_eq(relieved.budget, 50)
  assert_eq(relieved.energy, 48)
  assert_eq(relieved.pressure, 34)
  assert_eq(relieved.stability, 54)
  let drilled = stability_drill_model(model)
  assert_eq(drilled.budget, 43)
  assert_eq(drilled.energy, 55)
  assert_eq(drilled.pressure, 50)
  assert_eq(drilled.stability, 65)
}
