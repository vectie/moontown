///|
test "physical bridge telemetry helpers keep queue and health policy named" {
  assert_eq(physical_bridge_load_bonus(8, 3), 20)
  assert_eq(physical_bridge_telemetry_bonus(3), 15)
}

///|
test "physical bridge does not synthesize device observations from animation" {
  let model = init_model()
  assert_eq(physical_bridge_telemetry_signal_count({ ..model, tick: 0, }), 0)
  assert_eq(physical_bridge_telemetry_signal_count({ ..model, tick: 3, }), 0)
  assert_eq(physical_bridge_telemetry_signal_count({ ..model, tick: 4, }), 0)
  assert_eq(physical_bridge_coverage_label(model), "未接入设备与遥测")
}
