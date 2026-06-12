///|
async fn load_daemon_state(path : String) -> @scheduler.DaemonState {
  if !@fs.exists(path) {
    return @scheduler.DaemonState::new()
  }
  let text = @fs.read_file(path).text() catch {
    _ => return @scheduler.DaemonState::new()
  }
  let parsed = @json.parse(text) catch {
    _ => return @scheduler.DaemonState::new()
  }
  @json.from_json(parsed) catch {
    _ => @scheduler.DaemonState::new()
  }
}

///|
async fn save_daemon_state(
  path : String,
  daemon : @scheduler.DaemonState,
) -> Unit {
  @support.write_text_file(path, daemon.to_json().stringify())
}

///|
async fn load_daemon_runtime_state(path : String) -> DaemonRuntimeState? {
  let parsed = match @support.read_optional_json_file(path) {
    Some(json) => json
    None => return None
  }
  Some(@json.from_json(parsed) catch { _ => return None })
}

///|
async fn save_daemon_runtime_state(
  path : String,
  state : DaemonRuntimeState,
) -> Unit {
  @support.write_text_file(path, state.to_json().stringify()) catch {
    _ => ()
  }
}
