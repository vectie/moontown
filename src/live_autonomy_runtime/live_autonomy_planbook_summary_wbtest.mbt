///|
test "live autonomy hides historical repair entries when planbook is stable" {
  let latest = normalized_planbook_latest_change_summary(
    "1780258564852 - repair task running\n\nRepair `planbook-repair-live-runtime-recovery` is `running`.",
    0, 0,
  )
  assert_true(latest.contains("PlanBook is stable"))
  let still_active = normalized_planbook_latest_change_summary(
    "1780258564852 - repair task running", 1, 1,
  )
  assert_true(still_active.contains("repair task running"))
}
