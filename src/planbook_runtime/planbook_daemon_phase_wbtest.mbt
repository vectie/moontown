///|
test "PlanBook daemon duplicate repair message is package-owned" {
  assert_eq(
    planbook_daemon_repair_duplicate_message(),
    "PlanBook repair already active; daemon did not create a duplicate repair task.",
  )
}

///|
test "PlanBook daemon live-work deferral explains the run-id race guard" {
  let message = planbook_daemon_repair_deferred_for_live_work_message()
  assert_true(message.contains("deferred"))
  assert_true(message.contains("run-id"))
}
