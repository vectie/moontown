///|
priv enum ModuleRuntimeStatusKind {
  Alert
  Review
  Running
  Waiting
  Complete
  Projected
}

///|
fn module_runtime_status_class(kind : ModuleRuntimeStatusKind) -> String {
  match kind {
    Alert => "module-status-alert"
    Review => "module-status-review"
    Running => "module-status-running"
    Waiting => "module-status-waiting"
    Complete => "module-status-complete"
    Projected => "module-status-projected"
  }
}

///|
fn module_runtime_status_label(kind : ModuleRuntimeStatusKind) -> String {
  match kind {
    Alert => "Recovery"
    Review => "Review"
    Running => "Running"
    Waiting => "Waiting"
    Complete => "Quiet"
    Projected => "Projected"
  }
}

///|
fn module_runtime_status_count(
  kind : ModuleRuntimeStatusKind,
  expected : ModuleRuntimeStatusKind,
) -> Int {
  match (kind, expected) {
    (Alert, Alert) | (Review, Review) | (Running, Running) |
    (Waiting, Waiting) | (Complete, Complete) | (Projected, Projected) => 1
    _ => 0
  }
}

///|
fn module_runtime_counts_from_status_kind(
  kind : ModuleRuntimeStatusKind,
) -> ModuleRuntimeCounts {
  module_runtime_counts(
    running=module_runtime_status_count(kind, Running),
    waiting=module_runtime_status_count(kind, Waiting),
    review=module_runtime_status_count(kind, Review),
    blocked=module_runtime_status_count(kind, Alert),
    completed=module_runtime_status_count(kind, Complete),
  )
}

///|
fn module_projection_explicit_status_kind(
  status : String,
) -> ModuleRuntimeStatusKind? {
  match status {
    "alert" => Some(Alert)
    "review" => Some(Review)
    "running" => Some(Running)
    "waiting" => Some(Waiting)
    "complete" => Some(Complete)
    "projected" => Some(Projected)
    _ => None
  }
}

///|
fn module_projection_status_kind(
  module_status : VisualModuleSnapshot,
) -> ModuleRuntimeStatusKind {
  match module_projection_explicit_status_kind(module_status.status) {
    Some(kind) => kind
    None =>
      module_runtime_status_kind_from_counts(
        module_runtime_counts_from_module(module_status),
      )
  }
}

///|
fn module_projection_status_class(
  module_status : VisualModuleSnapshot,
) -> String {
  module_runtime_status_class(module_projection_status_kind(module_status))
}

///|
fn module_projection_status_label(
  module_status : VisualModuleSnapshot,
) -> String {
  module_runtime_status_label(module_projection_status_kind(module_status))
}

///|
fn module_projection_source_label(source : String) -> String {
  match source {
    "runtime" => "Module"
    "projection" => "Module"
    "execution" => "Execution"
    "" => "Module"
    _ => source
  }
}

///|
priv struct ModuleRuntimeCounts {
  running : Int
  waiting : Int
  review : Int
  blocked : Int
  completed : Int
}

///|
fn module_runtime_counts(
  running~ : Int = 0,
  waiting~ : Int = 0,
  review~ : Int = 0,
  blocked~ : Int = 0,
  completed~ : Int = 0,
) -> ModuleRuntimeCounts {
  { running, waiting, review, blocked, completed }
}

///|
fn module_runtime_counts_from_module(
  module_status : VisualModuleSnapshot,
) -> ModuleRuntimeCounts {
  module_runtime_counts(
    running=module_status.running_count,
    waiting=module_status.waiting_count,
    review=module_status.review_count,
    blocked=module_status.blocked_count,
    completed=module_status.completed_count,
  )
}

///|
fn module_runtime_counts_from_building(
  building : VisualBuildingSnapshot,
) -> ModuleRuntimeCounts {
  module_runtime_counts(
    running=building.running_count,
    waiting=building.waiting_count,
    review=building.review_count,
    blocked=building.blocked_count,
    completed=building.completed_count,
  )
}

///|
fn module_runtime_status_kind_from_counts(
  counts : ModuleRuntimeCounts,
) -> ModuleRuntimeStatusKind {
  if counts.blocked > 0 {
    Alert
  } else if counts.review > 0 {
    Review
  } else if counts.running > 0 {
    Running
  } else if counts.waiting > 0 {
    Waiting
  } else if counts.completed > 0 {
    Complete
  } else {
    Projected
  }
}

///|
fn module_runtime_status_class_from_counts(
  counts : ModuleRuntimeCounts,
) -> String {
  module_runtime_status_class(module_runtime_status_kind_from_counts(counts))
}

///|
fn module_runtime_status_label_from_counts(
  counts : ModuleRuntimeCounts,
) -> String {
  module_runtime_status_label(module_runtime_status_kind_from_counts(counts))
}

///|
fn module_building_status_class(building : VisualBuildingSnapshot) -> String {
  module_runtime_status_class_from_counts(
    module_runtime_counts_from_building(building),
  )
}

///|
fn module_building_status_label(building : VisualBuildingSnapshot) -> String {
  module_runtime_status_label_from_counts(
    module_runtime_counts_from_building(building),
  )
}

///|
fn module_execution_status_kind(
  status : @core.TaskExecutionStatus,
) -> ModuleRuntimeStatusKind {
  if execution_status_is_active_run(status) {
    Running
  } else if execution_status_requires_review(status) {
    Review
  } else if execution_status_needs_attention(status) {
    Alert
  } else if status == @core.TaskExecutionStatus::Completed {
    Complete
  } else {
    Waiting
  }
}
