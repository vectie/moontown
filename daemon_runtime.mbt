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
  if self.status != "running" &&
    self.status != "ticking" &&
    self.status != "supervising" {
    return false
  }
  self.heartbeat_age_ms(now_ms) > stale_after_ms
}

///|
pub fn DaemonRuntimeHealth::healthy(self : DaemonRuntimeHealth) -> Bool {
  !self.stop_requested &&
  !self.stale &&
  self.worker_alive &&
  (self.status == "running" || self.status == "ticking")
}

///|
pub fn daemon_runtime_health_summary(health : DaemonRuntimeHealth) -> String {
  let health_label = if health.healthy() {
    "healthy"
  } else if health.stop_requested {
    "stopping"
  } else if health.stale {
    "stale"
  } else if health.status == "missing" {
    "missing"
  } else {
    "degraded"
  }
  "runtime=\{health_label} status=\{health.status} supervisor_pid=\{health.supervisor_pid} supervisor_alive=\{health.supervisor_alive} worker_pid=\{health.worker_pid} worker_alive=\{health.worker_alive} heartbeat_age_ms=\{health.heartbeat_age_ms} stale=\{health.stale} successes=\{health.tick_success_count} failures=\{health.tick_failure_count} log=\{health.log_path}"
}

///|
pub fn default_daemon_runtime_path(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  "\{daemon_base_dir(snapshot_path)}/daemon-runtime.json"
}

///|
pub fn default_daemon_log_path(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  "\{daemon_base_dir(snapshot_path)}/daemon.log"
}

///|
pub fn default_daemon_stop_path(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  "\{daemon_base_dir(snapshot_path)}/daemon.stop"
}

///|
pub fn default_daemon_pid_path(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  "\{daemon_base_dir(snapshot_path)}/daemon.pid"
}

///|
pub fn default_daemon_supervisor_pid_path(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  "\{daemon_base_dir(snapshot_path)}/daemon-supervisor.pid"
}

///|
fn daemon_base_dir(snapshot_path : String) -> String {
  let base = @path.Path::dirname(snapshot_path).to_string()
  if base == "." || base == "" {
    ".moontown"
  } else {
    base
  }
}

///|
fn daemon_run_id(prefix : String) -> String {
  "\{prefix}-\{@env.now()}"
}

///|
async fn load_daemon_runtime_state(path : String) -> DaemonRuntimeState? {
  if !@fs.exists(path) {
    return None
  }
  let text = @fs.read_file(path).text() catch { _ => return None }
  let parsed = @json.parse(text) catch { _ => return None }
  Some(@json.from_json(parsed) catch { _ => return None })
}

///|
async fn save_daemon_runtime_state(
  path : String,
  state : DaemonRuntimeState,
) -> Unit {
  write_text_file(path, state.to_json().stringify()) catch {
    _ => ()
  }
}

///|
async fn append_daemon_log(path : String, message : String) -> Unit {
  ensure_parent_directory(path) catch {
    _ => ()
  }
  let line = "[\{@env.now()}] \{message}\n"
  @fs.write_file(path, @encoding/utf8.encode(line), create=0o644, append=true) catch {
    _ => ()
  }
}

///|
async fn write_daemon_pid_file(path : String, pid : Int) -> Unit {
  write_text_file(path, "\{pid}\n") catch {
    _ => ()
  }
}

///|
async fn remove_file_if_exists(path : String) -> Unit {
  if @fs.exists(path) {
    @fs.remove(path) catch {
      _ => ()
    }
  }
}

///|
async fn daemon_pid_alive(pid : Int) -> Bool {
  if pid <= 0 {
    return false
  }
  let code = @process.run("sh", ["-c", "kill -0 \{pid} 2>/dev/null"]) catch {
    _ => return false
  }
  code == 0
}

///|
async fn daemon_stop_requested(snapshot_path : String) -> Bool {
  @fs.exists(default_daemon_stop_path(snapshot_path~))
}

///|
async fn clear_daemon_stop_request(snapshot_path : String) -> Unit {
  remove_file_if_exists(default_daemon_stop_path(snapshot_path~))
}

///|
async fn write_daemon_stop_request(snapshot_path : String) -> Unit {
  write_text_file(
    default_daemon_stop_path(snapshot_path~),
    "stop requested at \{@env.now()}\n",
  ) catch {
    _ => ()
  }
}

///|
async fn kill_daemon_pid(pid : Int) -> Bool {
  if pid <= 0 {
    return false
  }
  let code = @process.run("sh", ["-c", "kill -TERM \{pid} 2>/dev/null"]) catch {
    _ => return false
  }
  code == 0
}

///|
pub async fn inspect_daemon_runtime(
  snapshot_path? : String = @storage.default_snapshot_path(),
  stale_after_ms? : UInt64 = 900_000UL,
) -> DaemonRuntimeHealth {
  let path = default_daemon_runtime_path(snapshot_path~)
  let stop_requested = daemon_stop_requested(snapshot_path)
  match load_daemon_runtime_state(path) {
    None =>
      {
        status: "missing",
        supervisor_pid: 0,
        worker_pid: 0,
        supervisor_alive: false,
        worker_alive: false,
        heartbeat_age_ms: 0UL,
        stale: false,
        stop_requested,
        tick_success_count: 0,
        tick_failure_count: 0,
        last_error: "",
        log_path: default_daemon_log_path(snapshot_path~),
      }
    Some(state) => {
      let now = @env.now()
      let supervisor_alive = daemon_pid_alive(state.supervisor_pid)
      let worker_alive = daemon_pid_alive(state.worker_pid)
      let stale = state.is_stale(now, stale_after_ms) ||
        (
          (state.status == "running" || state.status == "ticking") &&
          state.worker_pid > 0 &&
          !worker_alive
        )
      {
        status: state.status,
        supervisor_pid: state.supervisor_pid,
        worker_pid: state.worker_pid,
        supervisor_alive,
        worker_alive,
        heartbeat_age_ms: state.heartbeat_age_ms(now),
        stale,
        stop_requested: stop_requested || state.stop_requested,
        tick_success_count: state.tick_success_count,
        tick_failure_count: state.tick_failure_count,
        last_error: state.last_error,
        log_path: state.log_path,
      }
    }
  }
}

///|
async fn mark_daemon_supervisor_started(
  snapshot_path : String,
  supervisor_pid : Int,
  supervisor_run_id : String,
) -> Unit {
  let runtime_path = default_daemon_runtime_path(snapshot_path~)
  let log_path = default_daemon_log_path(snapshot_path~)
  let now = @env.now()
  let previous = load_daemon_runtime_state(runtime_path).unwrap_or(
    DaemonRuntimeState::new(log_path~),
  )
  save_daemon_runtime_state(runtime_path, {
    ..previous,
    status: "supervising",
    supervisor_pid,
    supervisor_run_id,
    started_at_ms: now,
    last_heartbeat_ms: now,
    stop_requested: false,
    last_error: "",
    log_path,
  })
  write_daemon_pid_file(
    default_daemon_supervisor_pid_path(snapshot_path~),
    supervisor_pid,
  )
}

///|
async fn mark_daemon_worker_started(
  snapshot_path : String,
  worker_pid : Int,
  worker_run_id : String,
) -> Unit {
  let runtime_path = default_daemon_runtime_path(snapshot_path~)
  let log_path = default_daemon_log_path(snapshot_path~)
  let now = @env.now()
  let previous = load_daemon_runtime_state(runtime_path).unwrap_or(
    DaemonRuntimeState::new(log_path~),
  )
  save_daemon_runtime_state(runtime_path, {
    ..previous,
    status: "running",
    worker_pid,
    worker_run_id,
    started_at_ms: if previous.started_at_ms == 0UL {
      now
    } else {
      previous.started_at_ms
    },
    last_heartbeat_ms: now,
    stop_requested: false,
    last_error: "",
    log_path,
  })
  write_daemon_pid_file(default_daemon_pid_path(snapshot_path~), worker_pid)
}

///|
async fn mark_daemon_tick_started(
  snapshot_path : String,
  worker_run_id : String,
) -> Unit {
  let runtime_path = default_daemon_runtime_path(snapshot_path~)
  let log_path = default_daemon_log_path(snapshot_path~)
  let now = @env.now()
  let previous = load_daemon_runtime_state(runtime_path).unwrap_or(
    DaemonRuntimeState::new(log_path~),
  )
  save_daemon_runtime_state(runtime_path, {
    ..previous,
    status: "ticking",
    worker_run_id,
    started_at_ms: if previous.started_at_ms == 0UL {
      now
    } else {
      previous.started_at_ms
    },
    last_heartbeat_ms: now,
    last_tick_started_ms: now,
    stop_requested: false,
    log_path,
  })
}

///|
async fn mark_daemon_tick_finished(
  snapshot_path : String,
  ok : Bool,
  summary : String,
) -> Unit {
  let runtime_path = default_daemon_runtime_path(snapshot_path~)
  let log_path = default_daemon_log_path(snapshot_path~)
  let now = @env.now()
  let previous = load_daemon_runtime_state(runtime_path).unwrap_or(
    DaemonRuntimeState::new(log_path~),
  )
  let next = if ok {
    {
      ..previous,
      status: "running",
      last_heartbeat_ms: now,
      last_tick_finished_ms: now,
      last_success_ms: now,
      tick_success_count: previous.tick_success_count + 1,
      last_error: "",
      log_path,
    }
  } else {
    {
      ..previous,
      status: "running",
      last_heartbeat_ms: now,
      last_tick_finished_ms: now,
      last_failure_ms: now,
      tick_failure_count: previous.tick_failure_count + 1,
      last_error: summary,
      log_path,
    }
  }
  save_daemon_runtime_state(runtime_path, next)
}

///|
async fn mark_daemon_stopped(snapshot_path : String, reason : String) -> Unit {
  let runtime_path = default_daemon_runtime_path(snapshot_path~)
  let log_path = default_daemon_log_path(snapshot_path~)
  let now = @env.now()
  let previous = load_daemon_runtime_state(runtime_path).unwrap_or(
    DaemonRuntimeState::new(log_path~),
  )
  save_daemon_runtime_state(runtime_path, {
    ..previous,
    status: "stopped",
    last_heartbeat_ms: now,
    stop_requested: false,
    last_error: reason,
    log_path,
  })
  remove_file_if_exists(default_daemon_pid_path(snapshot_path~))
  remove_file_if_exists(default_daemon_supervisor_pid_path(snapshot_path~))
  clear_daemon_stop_request(snapshot_path)
}

///|
fn daemon_path_basename(path : String) -> String {
  let parts = path.split("/").to_array()
  match parts.get(parts.length() - 1) {
    Some(part) => part.to_owned()
    None => path
  }
}

///|
fn daemon_command_uses_moon_runner(command : String) -> Bool {
  let name = daemon_path_basename(command).to_lower()
  name == "moon" || name == "moon.exe"
}

///|
fn daemon_process_args(command : String, tail : Array[String]) -> Array[String] {
  let args : Array[String] = []
  if daemon_command_uses_moon_runner(command) {
    args.push("run")
    args.push("cmd/main")
    args.push("--")
  }
  for item in tail {
    args.push(item)
  }
  args
}

///|
async fn spawn_daemon_worker(command : String, snapshot_path : String) -> Int {
  let log_path = default_daemon_log_path(snapshot_path~)
  let output = @process.redirect_to_file(log_path, append=true, create=0o644)
  @process.spawn_orphan(
    command,
    daemon_process_args(command, ["daemon", "run", "--worker"]),
    stdout=output,
    stderr=output,
    cwd=@env.current_dir().unwrap_or("."),
  )
}

///|
async fn spawn_daemon_supervisor(
  command : String,
  snapshot_path : String,
) -> Int {
  let log_path = default_daemon_log_path(snapshot_path~)
  let output = @process.redirect_to_file(log_path, append=true, create=0o644)
  @process.spawn_orphan(
    command,
    daemon_process_args(command, ["daemon", "supervise", "--worker"]),
    stdout=output,
    stderr=output,
    cwd=@env.current_dir().unwrap_or("."),
  )
}

///|
fn daemon_command_or_current(command : String) -> String {
  if !command.is_empty() {
    return command
  }
  match @sys.get_env_var("MOONTOWN_DAEMON_COMMAND") {
    Some(value) if !value.is_empty() => value
    _ =>
      match @sys.get_env_var("MOON_BIN") {
        Some(value) if !value.is_empty() => value
        _ =>
          match @sys.get_env_var("HOME") {
            Some(home) if !home.is_empty() => home + "/.moon/bin/moon"
            _ => "moon"
          }
      }
  }
}

///|
pub async fn daemon_start_saved_town(
  snapshot_path? : String = @storage.default_snapshot_path(),
  command? : String = "",
  stale_after_ms? : UInt64 = 900_000UL,
) -> String {
  let command = daemon_command_or_current(command)
  let health = inspect_daemon_runtime(snapshot_path~, stale_after_ms~)
  if health.healthy() ||
    (!health.stop_requested && health.supervisor_alive && !health.stale) {
    return "Moontown daemon already active\n\{daemon_runtime_health_summary(health)}"
  }
  clear_daemon_stop_request(snapshot_path)
  let supervisor_run_id = daemon_run_id("supervisor")
  let pid = spawn_daemon_supervisor(command, snapshot_path) catch {
    error => {
      append_daemon_log(
        default_daemon_log_path(snapshot_path~),
        "supervisor spawn failed: \{error}",
      )
      return "Moontown daemon start failed: \{error}"
    }
  }
  mark_daemon_supervisor_started(snapshot_path, pid, supervisor_run_id)
  append_daemon_log(
    default_daemon_log_path(snapshot_path~),
    "supervisor started pid=\{pid} run=\{supervisor_run_id}",
  )
  let next = inspect_daemon_runtime(snapshot_path~, stale_after_ms~)
  "Moontown daemon supervisor started pid=\{pid}\n\{daemon_runtime_health_summary(next)}"
}

///|
pub async fn daemon_supervise_saved_town(
  snapshot_path? : String = @storage.default_snapshot_path(),
  command? : String = "",
  max_checks? : Int = 0,
  sleep_ms? : Int = 30_000,
  stale_after_ms? : UInt64 = 900_000UL,
) -> String {
  let command = daemon_command_or_current(command)
  let run_id = daemon_run_id("supervisor")
  append_daemon_log(
    default_daemon_log_path(snapshot_path~),
    "supervisor loop entered run=\{run_id}",
  )
  let mut checks = 0
  let mut latest = ""
  while max_checks <= 0 || checks < max_checks {
    if daemon_stop_requested(snapshot_path) {
      latest = "stop requested"
      break
    }
    let health = inspect_daemon_runtime(snapshot_path~, stale_after_ms~)
    if !health.worker_alive ||
      health.stale ||
      health.status == "missing" ||
      health.status == "stopped" {
      let worker_run_id = daemon_run_id("worker")
      let pid = spawn_daemon_worker(command, snapshot_path) catch {
        error => {
          append_daemon_log(
            default_daemon_log_path(snapshot_path~),
            "worker spawn failed: \{error}",
          )
          latest = "worker spawn failed: \{error}"
          checks += 1
          @async.sleep(sleep_ms)
          continue
        }
      }
      mark_daemon_worker_started(snapshot_path, pid, worker_run_id)
      append_daemon_log(
        default_daemon_log_path(snapshot_path~),
        "worker started pid=\{pid} run=\{worker_run_id}",
      )
      latest = "worker started pid=\{pid}"
    } else {
      latest = daemon_runtime_health_summary(health)
    }
    checks += 1
    if max_checks > 0 && checks >= max_checks {
      break
    }
    @async.sleep(sleep_ms)
  }
  if latest == "stop requested" {
    mark_daemon_stopped(snapshot_path, "supervisor stopped by request")
    append_daemon_log(
      default_daemon_log_path(snapshot_path~),
      "supervisor stopped",
    )
  }
  "Moontown daemon supervisor completed checks=\{checks}\n\{latest}"
}

///|
pub async fn daemon_stop_saved_town(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  write_daemon_stop_request(snapshot_path)
  let health = inspect_daemon_runtime(snapshot_path~)
  let worker_killed = kill_daemon_pid(health.worker_pid)
  let supervisor_killed = kill_daemon_pid(health.supervisor_pid)
  mark_daemon_stopped(snapshot_path, "stop requested")
  append_daemon_log(
    default_daemon_log_path(snapshot_path~),
    "stop requested worker_pid=\{health.worker_pid} worker_killed=\{worker_killed} supervisor_pid=\{health.supervisor_pid} supervisor_killed=\{supervisor_killed}",
  )
  "Moontown daemon stop requested\nworker_pid=\{health.worker_pid} worker_killed=\{worker_killed}\nsupervisor_pid=\{health.supervisor_pid} supervisor_killed=\{supervisor_killed}"
}

///|
pub async fn daemon_doctor_saved_town(
  snapshot_path? : String = @storage.default_snapshot_path(),
  stale_after_ms? : UInt64 = 900_000UL,
) -> String {
  let health = inspect_daemon_runtime(snapshot_path~, stale_after_ms~)
  let builder = StringBuilder::new()
  builder.write_string("Moontown daemon doctor\n")
  builder.write_string("\{daemon_runtime_health_summary(health)}\n")
  if health.healthy() {
    builder.write_string("action=none\n")
  } else if health.stop_requested {
    builder.write_string("action=wait-or-stop\n")
  } else if health.stale || !health.worker_alive {
    builder.write_string("action=daemon start\n")
  } else {
    builder.write_string("action=inspect-log\n")
  }
  if !health.last_error.is_empty() {
    builder.write_string("last_error=\{health.last_error}\n")
  }
  builder.to_string()
}
