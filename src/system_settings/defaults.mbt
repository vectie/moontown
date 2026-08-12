///|
pub fn system_settings_schema() -> String {
  "moontown.system-settings.v1"
}

///|
pub fn default_system_settings() -> SystemSettings {
  {
    town_heartbeat_seconds: 30,
    max_concurrent_tasks: 12,
    max_live_external_executions: 8,
    external_execution_stale_window_ticks: 30,
    polled_execution_stale_window_ticks: 120,
    detached_execution_stale_window_ticks: 15,
    standing_watch_stale_window_ticks: 120,
    standing_goal_dispatches_per_tick: 3,
    research_bootstrap_task_limit: 1,
    daemon_poll_interval_ms: 30_000,
    daemon_stale_after_ms: 900_000,
    daemon_heartbeat_interval_ms: 10_000,
    moonclaw_import_timeout_ms: 20_000,
    supervisor_max_active_workers: 3,
    account_max_active_sessions: 1000,
    account_audit_capacity: 500,
    visitor_session_ttl_ms: 86_400_000,
    managed_session_ttl_ms: 604_800_000,
    frontend_snapshot_refresh_interval_ms: 5_000,
    frontend_runtime_stale_after_ms: 75_000,
    runtime_history_projection_limit: 128,
    operator_request_projection_limit: 256,
    watcher_record_projection_limit: 256,
    analytics_ring_capacity: 160,
    town_life_phone_capacity: 80,
    town_life_report_capacity: 30,
    recent_event_feed_limit: 6,
    town_chronicle_runtime_limit: 6,
    map_lab_entity_result_limit: 40,
    http_max_connections: 32,
  }
}

///|
pub fn empty_system_settings_state() -> SystemSettingsState {
  {
    schema: system_settings_schema(),
    settings: default_system_settings(),
    revision: 1,
    audit_events: [],
  }
}

///|
let installed_system_settings : Ref[SystemSettings] = Ref(
  default_system_settings(),
)

///| Install the settings used by this process. Native services refresh this

///| value from the durable settings store; browser code reads the same schema

///|
/// from the public runtime snapshot.
pub fn install_system_settings(settings : SystemSettings) -> Unit {
  installed_system_settings.val = settings
}

///|
pub fn current_system_settings() -> SystemSettings {
  installed_system_settings.val
}
