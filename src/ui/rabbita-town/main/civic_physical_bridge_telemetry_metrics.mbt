///|
fn physical_bridge_load_bonus(
  robot_calls : Int,
  telemetry_signals : Int,
) -> Int {
  robot_calls + telemetry_signals * 4
}

///|
fn physical_bridge_telemetry_bonus(telemetry_signals : Int) -> Int {
  telemetry_signals * 5
}

///|
fn physical_bridge_coverage_label(model : Model) -> String {
  "\{robot_service_count(model)} calls / \{physical_bridge_telemetry_signal_count(model)} signals"
}

///|
fn physical_bridge_telemetry_signal_count(model : Model) -> Int {
  3 + model.tick % 4
}
