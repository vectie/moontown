///|
async test "final integration daemon tick loads beside snapshot" {
  let root = "/tmp/moontown-final-integration-daemon-tick"
  @support.ignore_checked_command("rm", ["-rf", root])
  let snapshot_path = "\{root}/town.json"
  let daemon = @scheduler.DaemonState::new(tick_sequence=87)
  @support.write_text_file("\{root}/daemon.json", daemon.to_json().stringify())
  assert_eq(load_integration_daemon_tick(snapshot_path), 87)
}

///|
async test "final integration manifest declares five domains and Wenyu patterns" {
  let manifest = load_final_integration_manifest(
    "assets/templates/integration/wenyu-final-integration.json",
  ).unwrap()
  assert_eq(manifest.domain_watches.length(), 5)
  assert_eq(manifest.domain_watches[0].domain, "OPC")
  assert_eq(manifest.domain_watches[4].domain, "Hardware")
  assert_eq(manifest.civic_pattern_manifests.length(), 1)
  assert_eq(manifest.civic_scenarios.length(), 1)
}
