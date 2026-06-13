///|
async fn load_final_integration_manifest(
  manifest_path : String,
) -> @final_integration.FinalIntegrationManifest? {
  let parsed = match @support.read_optional_json_file(manifest_path) {
    Some(json) => json
    None => return None
  }
  Some(@json.from_json(parsed)) catch {
    _ => None
  }
}

///|
async fn load_integration_daemon_tick(snapshot_path : String) -> Int {
  let path = "\{@storage.snapshot_base_dir(snapshot_path)}/daemon.json"
  if !@fs.exists(path) {
    return 0
  }
  let text = @fs.read_file(path).text() catch { _ => return 0 }
  let parsed = @json.parse(text) catch { _ => return 0 }
  let daemon : @scheduler.DaemonState = @json.from_json(parsed) catch {
    _ => return 0
  }
  daemon.tick_sequence
}
