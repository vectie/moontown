///|
priv struct RuntimeStatusChip {
  text : String
  class_name : String
}

///|
fn runtime_status_chip_for_model(model : Model) -> RuntimeStatusChip {
  runtime_status_chip_for_state(model.state_source, paused=model.paused)
}

///|
fn runtime_status_chip_for_state(
  source : StateSourceKind,
  paused~ : Bool,
) -> RuntimeStatusChip {
  match source {
    SnapshotFile => { text: "Town data connected", class_name: "chip-neutral" }
    DemoSimulation =>
      if paused {
        { text: "Preview paused", class_name: "chip-alert" }
      } else {
        { text: "Preview live", class_name: "chip-live" }
      }
  }
}
