///|
pub(all) struct SystemSettings {
  town_heartbeat_seconds : Int
  max_concurrent_tasks : Int
  max_live_external_executions : Int
  external_execution_stale_window_ticks : Int
  polled_execution_stale_window_ticks : Int
  detached_execution_stale_window_ticks : Int
  standing_watch_stale_window_ticks : Int
  standing_goal_dispatches_per_tick : Int
  research_bootstrap_task_limit : Int
  daemon_poll_interval_ms : Int
  daemon_stale_after_ms : Int
  daemon_heartbeat_interval_ms : Int
  moonclaw_import_timeout_ms : Int
  supervisor_max_active_workers : Int
  account_max_active_sessions : Int
  account_audit_capacity : Int
  visitor_session_ttl_ms : Int
  managed_session_ttl_ms : Int
  frontend_snapshot_refresh_interval_ms : Int
  frontend_runtime_stale_after_ms : Int
  runtime_history_projection_limit : Int
  operator_request_projection_limit : Int
  watcher_record_projection_limit : Int
  analytics_ring_capacity : Int
  town_life_phone_capacity : Int
  town_life_report_capacity : Int
  recent_event_feed_limit : Int
  town_chronicle_runtime_limit : Int
  map_lab_entity_result_limit : Int
  http_max_connections : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct SystemSettingsAuditEvent {
  revision : Int
  actor_id : String
  changed_keys : Array[String]
  occurred_at_ms : UInt64
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct SystemSettingsState {
  schema : String
  settings : SystemSettings
  revision : Int
  audit_events : Array[SystemSettingsAuditEvent]
} derive(Debug, Eq, ToJson, FromJson)
