///|
test "vitality dashboard points flow label uses aggregate counters" {
  let model = { ..init_model(), tick: 5 }
  let label = vitality_dashboard_points_flow_label(model)
  assert_true(label.contains("issued"))
  assert_true(label.contains("redeemed"))
  assert_true(label.contains(valley_points_issued(model).to_string()))
  assert_true(label.contains(valley_points_redeemed(model).to_string()))
}

///|
test "vitality dashboard broadcast label distinguishes bridge waiting state" {
  let model = init_model()
  assert_eq(
    vitality_dashboard_broadcast_label({
      ..model,
      state_source: StateSourceKind::SnapshotFile,
      projection_snapshot: None,
    }),
    "Bridge waiting",
  )
  assert_true(vitality_dashboard_broadcast_label(model).contains("live"))
}
