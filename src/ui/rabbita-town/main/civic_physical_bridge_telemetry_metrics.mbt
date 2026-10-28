///|
fn physical_bridge_load_bonus(
  robot_calls : Int32,
  telemetry_signals : Int32,
) -> Int32 {
  robot_calls + telemetry_signals * 4
}

///|
fn physical_bridge_telemetry_bonus(telemetry_signals : Int32) -> Int32 {
  telemetry_signals * 5
}

///|
fn physical_bridge_coverage_label(model : Model) -> String {
  ignore(model)
  "未接入设备与遥测"
}

///|
fn physical_bridge_telemetry_signal_count(model : Model) -> Int32 {
  ignore(model)
  // No device adapter supplies telemetry yet. This compatibility value is not
  // an observed zero; user surfaces render the unavailable label above.
  0
}
