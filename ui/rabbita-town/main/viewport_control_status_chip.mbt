///|
priv struct ControlStatusChip {
  text : String
  class_name : String
}

///|
fn control_status_chip_for_model(model : Model) -> ControlStatusChip {
  control_status_chip_from_inputs(
    projection_ready=model_projection_snapshot_ready(model),
    projection_waiting=model_projection_snapshot_waiting(model),
    paused=model.paused,
  )
}

///|
fn control_status_chip_from_inputs(
  projection_ready~ : Bool,
  projection_waiting~ : Bool,
  paused~ : Bool,
) -> ControlStatusChip {
  {
    text: control_status_text(
      projection_ready~,
      projection_waiting~,
      paused~,
    ),
    class_name: if paused { "chip-alert" } else { "chip-live" },
  }
}

///|
fn control_status_text(
  projection_ready~ : Bool,
  projection_waiting~ : Bool,
  paused~ : Bool,
) -> String {
  if projection_ready {
    if paused {
      "Bridge paused"
    } else {
      "Bridge ready"
    }
  } else if projection_waiting {
    "Bridge waiting"
  } else if paused {
    "Paused"
  } else {
    "Live"
  }
}
