///|
test "live autonomy status detail includes operational sections" {
  let spine = test_live_autonomy_snapshot(
    pending_templates=2,
    failed_templates=1,
    open_plan_gaps=3,
    enabled_goals=4,
    disabled_goals=1,
  )
  let detail = live_autonomy_status_view(spine).detail_label()
  assert_true(detail.contains("tick 42 generated at test-time"))
  assert_true(detail.contains("accepted 2, no-change 3, review 1"))
  assert_true(detail.contains("goals 4 active / 1 archived"))
  assert_true(detail.contains("plan gaps 3, template inbox 2/1"))
  assert_true(detail.contains("Latest watcher: latest watcher summary"))
  assert_true(detail.contains("Latest: latest change summary"))
}
