///|
async test "live refresh works without saved town snapshot" {
  let workspace = live_autonomy_test_workspace(
    "/tmp/moontown-live-autonomy-no-snapshot-refresh-check",
  )
  let snapshot_path = workspace.snapshot_path
  let message = refresh_live_autonomy_spine(snapshot_path~)
  assert_true(message.contains("without saved town snapshot"))
  let status = render_live_autonomy_status(snapshot_path~)
  assert_true(status.contains("# Live Autonomy Spine"))
  assert_true(status.contains("Active workers: `0`"))
}
