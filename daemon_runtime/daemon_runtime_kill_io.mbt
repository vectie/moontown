///|
async fn kill_daemon_pid(pid : Int) -> Bool {
  if pid <= 0 {
    return false
  }
  let code = @process.run("kill", ["-TERM", "\{pid}"]) catch {
    _ => return false
  }
  code == 0
}

///|
async fn kill_daemon_pid_force(pid : Int) -> Bool {
  if pid <= 0 {
    return false
  }
  if !kill_daemon_pid(pid) {
    return false
  }
  @async.sleep(300)
  if !daemon_pid_alive(pid) {
    return true
  }
  let code = @process.run("kill", ["-KILL", "\{pid}"]) catch {
    _ => return false
  }
  @async.sleep(100)
  code == 0 && !daemon_pid_alive(pid)
}
