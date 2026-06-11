///|
pub fn daemon_runtime_health_summary(health : DaemonRuntimeHealth) -> String {
  let health_label = daemon_runtime_health_label(health)
  daemon_runtime_health_summary_fields(health_label, health).join(" ")
}

///|
pub fn daemon_runtime_health_label(health : DaemonRuntimeHealth) -> String {
  if health.healthy() {
    "healthy"
  } else if health.supervisor_active() {
    "supervising"
  } else if health.stop_requested {
    "stopping"
  } else if health.stale {
    "stale"
  } else if health.status == "missing" {
    "missing"
  } else {
    "degraded"
  }
}

///|
pub fn daemon_runtime_health_summary_fields(
  health_label : String,
  health : DaemonRuntimeHealth,
) -> Array[String] {
  [
    daemon_runtime_health_field("runtime", health_label),
    daemon_runtime_health_field("status", health.status),
    daemon_runtime_health_field(
      "supervisor_pid",
      health.supervisor_pid.to_string(),
    ),
    daemon_runtime_health_field(
      "supervisor_alive",
      health.supervisor_alive.to_string(),
    ),
    daemon_runtime_health_field("worker_pid", health.worker_pid.to_string()),
    daemon_runtime_health_field("worker_alive", health.worker_alive.to_string()),
    daemon_runtime_health_field(
      "heartbeat_age_ms",
      health.heartbeat_age_ms.to_string(),
    ),
    daemon_runtime_health_field("stale", health.stale.to_string()),
    daemon_runtime_health_field(
      "successes",
      health.tick_success_count.to_string(),
    ),
    daemon_runtime_health_field(
      "failures",
      health.tick_failure_count.to_string(),
    ),
    daemon_runtime_health_field("log", health.log_path),
  ]
}

///|
fn daemon_runtime_health_field(name : String, value : String) -> String {
  "\{name}=\{value}"
}
