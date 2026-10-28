///|
test "vitality dashboard points flow does not present missing metrics as zero" {
  let model = { ..init_model(), tick: 5, }
  let label = vitality_dashboard_points_flow_label(model)
  assert_eq(label, "积分服务未接入")
  assert_false(label.contains("0"))
}

///|
test "vitality dashboard does not turn completed work into public broadcasts" {
  let model = init_model()
  assert_eq(
    vitality_dashboard_broadcast_label({
      ..model,
      state_source: StateSourceKind::SnapshotFile,
      projection_snapshot: None,
    }),
    "暂无已发布成果记录",
  )
  assert_false(vitality_dashboard_broadcast_label(model).contains("live"))
}
