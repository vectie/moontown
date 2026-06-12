///|
fn daemon_parse_positive_int(text : String) -> Int {
  let mut seen = false
  let mut value = 0
  for char in text.trim() {
    if char >= '0' && char <= '9' {
      value = value * 10 + (char.to_int() - '0'.to_int())
      seen = true
    } else {
      return 0
    }
  }
  if seen && value > 0 {
    value
  } else {
    0
  }
}

///|
async fn daemon_current_process_pid(snapshot_path : String) -> Int {
  let tmp_path = "\{@daemon_runtime_policy.daemon_base_dir_for_snapshot(snapshot_path)}/daemon-current.pid.tmp"
  @support.ensure_parent_directory(tmp_path) catch {
    _ => return 0
  }
  let status = @process.run("sh", [
    "-c", "ppid=\"$PPID\"; gpid=\"$(ps -o ppid= -p \"$ppid\" | tr -d ' ')\"; if [ -n \"$gpid\" ] && [ \"$gpid\" != \"0\" ]; then printf '%s\\n' \"$gpid\" > \"$1\"; else printf '%s\\n' \"$ppid\" > \"$1\"; fi",
    "moontown-pid", tmp_path,
  ]) catch {
    _ => return 0
  }
  if status != 0 {
    return 0
  }
  let text = @fs.read_file(tmp_path).text() catch { _ => return 0 }
  remove_file_if_exists(tmp_path)
  daemon_parse_positive_int(text)
}

///|
async fn write_daemon_pid_file(path : String, pid : Int) -> Unit {
  @support.write_text_file(path, "\{pid}\n") catch {
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
  let ps_code = @process.run("sh", [
    "-c",
    "ps -p \"$1\" >/dev/null 2>&1",
    "moontown-pid-probe",
    "\{pid}",
  ]) catch {
    _ => -1
  }
  ps_code == 0
}

///|
fn daemon_pid_effectively_alive(
  probed_alive : Bool,
  pid : Int,
  heartbeat_fresh : Bool,
  runtime_active : Bool,
) -> Bool {
  ignore(pid)
  ignore(heartbeat_fresh)
  ignore(runtime_active)
  probed_alive
}
