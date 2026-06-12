///|
test "physical bridge telemetry helpers keep queue and health policy named" {
  assert_eq(physical_bridge_load_bonus(8, 3), 20)
  assert_eq(physical_bridge_telemetry_bonus(3), 15)
}

///|
test "physical bridge telemetry count follows the town tick window" {
  let model = init_model()
  assert_eq(physical_bridge_telemetry_signal_count({ ..model, tick: 0 }), 3)
  assert_eq(physical_bridge_telemetry_signal_count({ ..model, tick: 3 }), 6)
  assert_eq(physical_bridge_telemetry_signal_count({ ..model, tick: 4 }), 3)
}
