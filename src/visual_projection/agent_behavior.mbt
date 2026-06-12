///|
fn visual_behavior_for_phase(phase : String) -> String {
  match phase {
    "packet" => "queueing"
    "importing" => "handoff"
    "running" => "working"
    "persisting" => "carrying-memory"
    "review" => "reviewing"
    "failed" => "recovering"
    "stale" => "recovering"
    "blocked" => "recovering"
    "waiting" => "waiting"
    "offline" => "offline"
    _ => "inside-idle"
  }
}

///|
fn visual_effect_for_phase(phase : String) -> String {
  match phase {
    "packet" => "packet-pulse"
    "importing" => "packet-pulse"
    "running" => "work-particles"
    "persisting" => "memory-glow"
    "review" => "review-glow"
    "failed" => "alert-pulse"
    "stale" => "alert-pulse"
    "blocked" => "alert-pulse"
    "waiting" => "packet-pulse"
    _ => "none"
  }
}

///|
fn visual_agent_visible_on_overworld(phase : String) -> Bool {
  visual_phase_is_handoff(phase) ||
  visual_phase_is_working(phase) ||
  visual_phase_is_keeper_bound(phase) ||
  visual_phase_is_recovery(phase) ||
  phase == "waiting"
}
