///|
fn daemon_detached_shell_line(
  command : String,
  tail : Array[String],
  cwd : String,
  log_path : String,
  pid_path : String,
) -> String {
  let invocation = daemon_process_command_line(command, tail)
  "cd \{daemon_shell_quote(cwd)} && { nohup \{invocation} >> \{daemon_shell_quote(log_path)} 2>&1 < /dev/null & echo $! > \{daemon_shell_quote(pid_path)}; }"
}

///|
fn daemon_supervisor_should_run_inline_for_service_name(
  service_name : String,
) -> Bool {
  service_name.contains("moontown.daemon")
}

///|
fn daemon_supervisor_should_run_inline_worker() -> Bool {
  match @sys.get_env_var("XPC_SERVICE_NAME") {
    Some(value) => daemon_supervisor_should_run_inline_for_service_name(value)
    None => false
  }
}

///|
async fn spawn_daemon_detached(
  command : String,
  tail : Array[String],
  snapshot_path : String,
  kind : String,
) -> Int {
  let base_dir = daemon_base_dir(snapshot_path)
  let log_path = default_daemon_log_path(snapshot_path~)
  let pid_path = "\{base_dir}/daemon-\{kind}-spawn.pid.tmp"
  ensure_parent_directory(log_path) catch {
    _ => return 0
  }
  remove_file_if_exists(pid_path)
  let cwd = @env.current_dir().unwrap_or(".")
  let shell_line = daemon_detached_shell_line(
    command, tail, cwd, log_path, pid_path,
  )
  let status = @process.run("sh", ["-c", shell_line]) catch { _ => return 0 }
  if status != 0 {
    return 0
  }
  let text = @fs.read_file(pid_path).text() catch { _ => return 0 }
  remove_file_if_exists(pid_path)
  daemon_parse_positive_int(text)
}

///|
async fn spawn_daemon_worker(command : String, snapshot_path : String) -> Int {
  spawn_daemon_detached(
    command,
    ["daemon", "run", "--worker"],
    snapshot_path,
    "worker",
  )
}

///|
async fn spawn_daemon_supervisor(
  command : String,
  snapshot_path : String,
) -> Int {
  spawn_daemon_detached(
    command,
    ["daemon", "supervise", "--worker"],
    snapshot_path,
    "supervisor",
  )
}
