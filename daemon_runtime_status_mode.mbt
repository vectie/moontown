///|
priv enum DaemonRuntimeMode {
  WorkerRuntime
  SupervisorRuntime
  InactiveRuntime
}

///|
fn daemon_runtime_status_active(status : String) -> Bool {
  match daemon_runtime_mode(status) {
    WorkerRuntime | SupervisorRuntime => true
    InactiveRuntime => false
  }
}

///|
fn daemon_runtime_status_requires_worker(status : String) -> Bool {
  daemon_runtime_mode(status) is WorkerRuntime
}

///|
fn daemon_runtime_status_requires_supervisor(status : String) -> Bool {
  daemon_runtime_mode(status) is SupervisorRuntime
}

///|
fn daemon_runtime_mode(status : String) -> DaemonRuntimeMode {
  match status {
    "running" | "ticking" => WorkerRuntime
    "supervising" => SupervisorRuntime
    _ => InactiveRuntime
  }
}
