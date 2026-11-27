///|
#derive(Debug, Eq, ToJson, FromJson)
pub(all) struct SystemSettings {
  town_heartbeat_seconds : Int32
  max_concurrent_tasks : Int32
  max_live_external_executions : Int32
  external_execution_stale_window_ticks : Int32
  polled_execution_stale_window_ticks : Int32
  detached_execution_stale_window_ticks : Int32
  standing_watch_stale_window_ticks : Int32
  standing_goal_dispatches_per_tick : Int32
  research_bootstrap_task_limit : Int32
  daemon_poll_interval_ms : Int32
  daemon_stale_after_ms : Int32
  daemon_heartbeat_interval_ms : Int32
  moonclaw_import_timeout_ms : Int32
  supervisor_max_active_workers : Int32
  account_max_active_sessions : Int32
  account_audit_capacity : Int32
  visitor_session_ttl_ms : Int32
  managed_session_ttl_ms : Int32
  frontend_snapshot_refresh_interval_ms : Int32
  frontend_runtime_stale_after_ms : Int32
  runtime_history_projection_limit : Int32
  operator_request_projection_limit : Int32
  watcher_record_projection_limit : Int32
  analytics_ring_capacity : Int32
  town_life_phone_capacity : Int32
  town_life_report_capacity : Int32
  recent_event_feed_limit : Int32
  town_chronicle_runtime_limit : Int32
  map_lab_entity_result_limit : Int32
  http_max_connections : Int32
}

///|
#derive(Debug, Eq, ToJson, FromJson)
pub(all) struct SystemSettingsAuditEvent {
  revision : Int32
  actor_id : String
  changed_keys : Array[String]
  occurred_at_ms : UInt64
}

///|
#derive(Debug, Eq, ToJson, FromJson)
pub(all) struct SystemSettingsState {
  schema : String
  settings : SystemSettings
  revision : Int32
  audit_events : Array[SystemSettingsAuditEvent]
}
