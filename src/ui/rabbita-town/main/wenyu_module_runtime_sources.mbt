///|
fn wenyu_module_runtime_state_from_counts(
  status_class : String,
  status_label : String,
  source_label : String,
  detail : String,
  counts : ModuleRuntimeCounts,
  visible_agent_count : Int,
  issue_count : Int,
) -> WenyuModuleRuntimeState {
  {
    status_class,
    status_label,
    source_label,
    detail,
    running_count: counts.running,
    waiting_count: counts.waiting,
    review_count: counts.review,
    blocked_count: counts.blocked,
    completed_count: counts.completed,
    visible_agent_count,
    issue_count,
  }
}

///|
fn runtime_state_from_visual_module(
  module_status : VisualModuleSnapshot,
  issue_count : Int,
) -> WenyuModuleRuntimeState {
  wenyu_module_runtime_state_from_counts(
    module_projection_status_class(module_status),
    module_projection_status_label(module_status),
    module_projection_source_label(module_status.source),
    module_status.message,
    module_runtime_counts_from_module(module_status),
    module_status.active_agent_count,
    issue_count,
  )
}

///|
fn runtime_state_from_visual_building(
  building : VisualBuildingSnapshot,
  active_agent_count : Int,
  issue_count : Int,
) -> WenyuModuleRuntimeState {
  let detail = "\{building.message} Projection building: \{building.title}; zone: \{building.zone_key}; effect: \{building.effect}."
  wenyu_module_runtime_state_from_counts(
    module_building_status_class(building),
    module_building_status_label(building),
    "Projection",
    detail,
    module_runtime_counts_from_building(building),
    active_agent_count,
    issue_count,
  )
}

///|
fn runtime_state_from_execution(
  execution : @core.TaskExecutionRecord,
  active_agent_count : Int,
  issue_count : Int,
) -> WenyuModuleRuntimeState {
  let status_kind = module_execution_status_kind(execution.status)
  wenyu_module_runtime_state_from_counts(
    module_runtime_status_class(status_kind),
    execution.status.to_string(),
    "Execution",
    execution.summary,
    module_runtime_counts_from_status_kind(status_kind),
    active_agent_count,
    issue_count,
  )
}

///|
fn runtime_state_from_civic_health(
  health : CivicServiceHealthSnapshot,
  active_agent_count : Int,
  issue_count : Int,
) -> WenyuModuleRuntimeState {
  let status_kind = civic_health_status_kind(health.status)
  wenyu_module_runtime_state_from_counts(
    civic_health_status_class_for_kind(status_kind),
    civic_health_status_label(health.status),
    "Civic Doctor",
    civic_health_detail(health),
    civic_health_runtime_counts(health, status_kind),
    active_agent_count,
    civic_health_runtime_issue_count(issue_count, health),
  )
}

///|
fn civic_health_runtime_counts(
  health : CivicServiceHealthSnapshot,
  status_kind : CivicHealthStatusKind,
) -> ModuleRuntimeCounts {
  module_runtime_counts(
    waiting=if status_kind is Waiting { 1 } else { 0 },
    review=health.latest_review_items,
    blocked=if civic_health_status_kind_is_blocked(status_kind) { 1 } else { 0 },
    completed=if health.proven_by_result { 1 } else { 0 },
  )
}

///|
fn civic_health_runtime_issue_count(
  base_issue_count : Int,
  health : CivicServiceHealthSnapshot,
) -> Int {
  base_issue_count + health.missing_required_paths.length()
}

///|
priv struct ModuleConfigRuntimeStatus {
  class : String
  label : String
}

///|
fn module_config_runtime_status(issue_count : Int) -> ModuleConfigRuntimeStatus {
  if issue_count > 0 {
    { class: "module-status-unbound", label: "Needs config" }
  } else {
    { class: "module-status-calm", label: "Configured" }
  }
}

///|
fn runtime_state_from_config(
  civic : WenyuTownModule,
  active_agent_count : Int,
  issue_count : Int,
) -> WenyuModuleRuntimeState {
  let status = module_config_runtime_status(issue_count)
  wenyu_module_runtime_state_from_counts(
    status.class,
    status.label,
    "Config",
    civic.summary,
    module_runtime_counts(),
    active_agent_count,
    issue_count,
  )
}
