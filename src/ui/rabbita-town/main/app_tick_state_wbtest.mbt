///|
test "tick refresh application preserves runtime metrics" {
  let model = {
    ..init_model(),
    budget: 12,
    energy: 34,
    pressure: 56,
    stability: 78,
  }
  let refresh = refresh_tick_state(model)
  let next = apply_tick_refresh_state(model, refresh)
  assert_eq(next.budget, 12)
  assert_eq(next.energy, 34)
  assert_eq(next.pressure, 56)
  assert_eq(next.stability, 78)
  assert_eq(next.snapshot_version, refresh.snapshot_version)
  assert_eq(next.operator_requests_version, refresh.operator_requests_version)
}

///|
test "tick refresh state propagates all runtime versions" {
  let model = init_model()
  let versions = read_tick_refresh_versions()
  let refresh = refresh_tick_state(model)
  assert_eq(refresh.snapshot_version, versions.snapshot)
  assert_eq(refresh.visual_projection_version, versions.visual_projection)
  assert_eq(refresh.module_projections_version, versions.module_projections)
  assert_eq(refresh.moondesk_handoff_version, versions.moondesk_handoff)
  assert_eq(refresh.moondesk_bridge_version, versions.moondesk_bridge)
  assert_eq(refresh.daemon_snapshot_version, versions.daemon_snapshot)
  assert_eq(refresh.live_autonomy_version, versions.live_autonomy)
  assert_eq(refresh.editor_pipeline_version, versions.editor_pipeline)
  assert_eq(refresh.standing_goals_version, versions.standing_goals)
  assert_eq(refresh.watcher_records_version, versions.watcher_records)
  assert_eq(refresh.operator_requests_version, versions.operator_requests)
}

///|
test "tick refresh helpers preserve arrays when versions are unchanged" {
  let model = init_model()
  assert_eq(
    refresh_module_projections(model.module_projections_version, model).length(),
    model.module_projections.length(),
  )
  assert_eq(
    refresh_moondesk_handoff_artifacts(model.moondesk_handoff_version, model).length(),
    model.moondesk_handoff_artifacts.length(),
  )
  assert_eq(
    refresh_standing_goals(model.standing_goals_version, model).length(),
    model.standing_goals.length(),
  )
  assert_eq(
    refresh_watcher_records(model.watcher_records_version, model).length(),
    model.watcher_records.length(),
  )
  assert_eq(
    refresh_operator_requests(model.operator_requests_version, model).length(),
    model.operator_requests.length(),
  )
}

///|
test "tick metric application preserves refresh and selection state" {
  let model = {
    ..init_model(),
    tick: 7,
    selection: Selection::Node("policy-hall"),
  }
  let next = apply_tick_metric_state(model, {
    budget: 11,
    energy: 22,
    pressure: 33,
    stability: 44,
  })
  assert_eq(next.budget, 11)
  assert_eq(next.energy, 22)
  assert_eq(next.pressure, 33)
  assert_eq(next.stability, 44)
  assert_eq(next.tick, 7)
  assert_true(next.selection is Selection::Node("policy-hall"))
}

///|
test "advance model increments tick after composing refresh and metrics" {
  let model = {
    ..init_model(),
    tick: 4,
    budget: 50,
    energy: 50,
    pressure: 50,
    stability: 50,
  }
  let next = advance_model(model)
  assert_eq(next.tick, 5)
  assert_true(next.budget >= 0 && next.budget <= 100)
  assert_true(next.energy >= 0 && next.energy <= 100)
  assert_true(next.pressure >= 0 && next.pressure <= 100)
  assert_true(next.stability >= 0 && next.stability <= 100)
}
