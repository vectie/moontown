///|
pub fn DaemonRuntimeState::heartbeat_age_ms(
  self : DaemonRuntimeState,
  now_ms : UInt64,
) -> UInt64 {
  if self.last_heartbeat_ms == 0UL || now_ms < self.last_heartbeat_ms {
    0UL
  } else {
    now_ms - self.last_heartbeat_ms
  }
}

///|
pub fn DaemonRuntimeState::is_stale(
  self : DaemonRuntimeState,
  now_ms : UInt64,
  stale_after_ms : UInt64,
) -> Bool {
  if !daemon_runtime_status_active(self.status) {
    return false
  }
  self.heartbeat_age_ms(now_ms) > stale_after_ms
}

///|
pub fn DaemonRuntimeHealth::healthy(self : DaemonRuntimeHealth) -> Bool {
  !self.stop_requested &&
  !self.stale &&
  self.worker_alive &&
  daemon_runtime_status_requires_worker(self.status)
}

///|
fn DaemonRuntimeHealth::supervisor_active(self : DaemonRuntimeHealth) -> Bool {
  !self.stop_requested &&
  !self.stale &&
  self.supervisor_alive &&
  daemon_runtime_status_requires_supervisor(self.status)
}

///|
fn DaemonRuntimeHealth::durable_worker_active(
  self : DaemonRuntimeHealth,
) -> Bool {
  self.healthy() && self.supervisor_alive
}

///|
fn daemon_runtime_start_already_active(health : DaemonRuntimeHealth) -> Bool {
  health.durable_worker_active() || health.supervisor_active()
}

///|
fn daemon_runtime_doctor_action(health : DaemonRuntimeHealth) -> String {
  if daemon_runtime_start_already_active(health) {
    "none"
  } else if health.healthy() {
    "daemon start"
  } else if health.stop_requested {
    "wait-or-stop"
  } else if health.stale || !health.worker_alive {
    "daemon start"
  } else {
    "inspect-log"
  }
}
