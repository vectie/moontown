///|
fn daemon_launchd_install_shell_line(command : String) -> String {
  "MOON_BIN=\{daemon_shell_quote(command)} sh ./scripts/install-launchd-daemon.sh"
}

///|
fn daemon_launchd_stop_shell_line() -> String {
  "sh ./scripts/uninstall-launchd-daemon.sh"
}

///|
fn daemon_launchd_preferred() -> Bool {
  match @sys.get_env_var("MOONTOWN_DAEMON_BACKEND") {
    Some("detached") | Some("shell") | Some("none") => false
    _ => true
  }
}

///|
async fn daemon_launchd_available() -> Bool {
  let status = @process.run("sh", [
    "-c", "[ \"$(uname -s)\" = Darwin ] && command -v launchctl >/dev/null 2>&1",
  ]) catch {
    _ => return false
  }
  status == 0
}

///|
async fn start_daemon_with_launchd(command : String) -> Bool {
  if !@fs.exists("./scripts/install-launchd-daemon.sh") {
    return false
  }
  let status = @process.run("sh", [
    "-c",
    daemon_launchd_install_shell_line(command),
  ]) catch {
    _ => return false
  }
  status == 0
}

///|
async fn stop_daemon_with_launchd() -> Bool {
  if !@fs.exists("./scripts/uninstall-launchd-daemon.sh") {
    return false
  }
  let status = @process.run("sh", ["-c", daemon_launchd_stop_shell_line()]) catch {
    _ => return false
  }
  status == 0
}
