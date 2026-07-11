///|
fn moondesk_bridge_records(model : Model) -> Array[MoondeskBridgeRecord] {
  match model.moondesk_bridge {
    Some(bridge) => bridge.records
    None => []
  }
}

///|
fn moondesk_root_status_label(model : Model) -> String {
  match model.moondesk_bridge {
    Some(bridge) =>
      if bridge.moondesk_root_available {
        "MoonDesk checkout found"
      } else {
        "MoonDesk checkout missing"
      }
    None => "Bridge not loaded"
  }
}

///|
fn moondesk_record_count(model : Model) -> Int {
  moondesk_bridge_records(model).length()
}

///|
fn moondesk_bridge_generated_at(model : Model) -> String {
  match model.moondesk_bridge {
    Some(bridge) =>
      if bridge.generated_at.is_empty() {
        "unknown"
      } else {
        bridge.generated_at
      }
    None => "not loaded"
  }
}

///|
fn handoff_artifact_status_tone(status : String) -> ArtifactStatusTone {
  match status {
    "ready" => Ready
    "simple-only" => Simple
    "reference-only" => Reference
    "review" => Review
    _ => Neutral
  }
}

///|
fn bridge_record_status_tone(status : String) -> ArtifactStatusTone {
  match status {
    "ready" | "accepted" | "completed" => Ready
    "review" | "needs-review" => Review
    "failed" => Alert
    _ => Neutral
  }
}

///|
fn artifact_status_class(status : String) -> String {
  artifact_status_tone_class(handoff_artifact_status_tone(status))
}

///|
fn bridge_record_status_class(status : String) -> String {
  artifact_status_tone_class(bridge_record_status_tone(status))
}
