///|
fn worker_role_from_id(worker_id : String) -> @core.WorkerRole {
  match worker_id {
    "agent-town-shell" => @core.WorkerRole::Harness
    "agent-resident" => @core.WorkerRole::MemoryKeeper
    "agent-policy" => @core.WorkerRole::Specialist
    "agent-contest" => @core.WorkerRole::Planner
    "agent-social" => @core.WorkerRole::Operator
    "agent-talent" => @core.WorkerRole::MemoryKeeper
    "agent-garden" => @core.WorkerRole::Planner
    "agent-robot" => @core.WorkerRole::Watcher
    _ => @core.WorkerRole::MemoryKeeper
  }
}

///|
fn worker_capabilities(worker_id : String) -> Array[String] {
  match worker_id {
    "agent-town-shell" => ["projection", "ui-state", "build-records"]
    "agent-resident" => ["resident-memory", "reflection", "projection"]
    "agent-policy" => ["policy", "rag", "checklist"]
    "agent-contest" => ["contest", "mock-judge", "readiness"]
    "agent-social" => ["matching", "event-planning", "community"]
    "agent-talent" => ["talent-graph", "projection", "reception"]
    "agent-garden" => ["tutorial", "tool-trial", "workshop"]
    "agent-robot" => ["robot", "venue", "digital-twin"]
    _ => ["reporting", "planning"]
  }
}
