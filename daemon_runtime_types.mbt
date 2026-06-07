///|
pub struct DaemonRuntimeState {
  daemon_id : String
  status : String
  supervisor_pid : Int
  worker_pid : Int
  supervisor_run_id : String
  worker_run_id : String
  started_at_ms : UInt64
  last_heartbeat_ms : UInt64
  last_tick_started_ms : UInt64
  last_tick_finished_ms : UInt64
  last_success_ms : UInt64
  last_failure_ms : UInt64
  tick_success_count : Int
  tick_failure_count : Int
  stop_requested : Bool
  last_error : String
  log_path : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn DaemonRuntimeState::new(
  daemon_id? : String = "moontown-daemon",
  status? : String = "stopped",
  supervisor_pid? : Int = 0,
  worker_pid? : Int = 0,
  supervisor_run_id? : String = "",
  worker_run_id? : String = "",
  started_at_ms? : UInt64 = 0UL,
  last_heartbeat_ms? : UInt64 = 0UL,
  last_tick_started_ms? : UInt64 = 0UL,
  last_tick_finished_ms? : UInt64 = 0UL,
  last_success_ms? : UInt64 = 0UL,
  last_failure_ms? : UInt64 = 0UL,
  tick_success_count? : Int = 0,
  tick_failure_count? : Int = 0,
  stop_requested? : Bool = false,
  last_error? : String = "",
  log_path? : String = ".moontown/daemon.log",
) -> DaemonRuntimeState {
  {
    daemon_id,
    status,
    supervisor_pid,
    worker_pid,
    supervisor_run_id,
    worker_run_id,
    started_at_ms,
    last_heartbeat_ms,
    last_tick_started_ms,
    last_tick_finished_ms,
    last_success_ms,
    last_failure_ms,
    tick_success_count,
    tick_failure_count,
    stop_requested,
    last_error,
    log_path,
  }
}

///|
pub struct DaemonRuntimeHealth {
  status : String
  supervisor_pid : Int
  worker_pid : Int
  supervisor_alive : Bool
  worker_alive : Bool
  heartbeat_age_ms : UInt64
  stale : Bool
  stop_requested : Bool
  tick_success_count : Int
  tick_failure_count : Int
  last_error : String
  log_path : String
} derive(Debug, Eq, ToJson, FromJson)
