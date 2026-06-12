///|
test "required live autonomy validation target covers planbook projection" {
  let latest = normalized_planbook_latest_change_summary(
    "1780258564852 - repair task running", 1, 1,
  )
  assert_true(latest.contains("repair task running"))
}
