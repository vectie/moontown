///|
test "launchd supervisor service runs worker inline" {
  assert_true(
    daemon_supervisor_should_run_inline_for_service_name(
      "com.vectie.moontown.daemon",
    ),
  )
  assert_true(
    !daemon_supervisor_should_run_inline_for_service_name(
      "com.apple.some-other-service",
    ),
  )
}

///|
async test "manual worker only clears missing supervisor when requested" {
  assert_true(daemon_worker_should_keep_supervisor(0, false))
  assert_true(!daemon_worker_should_keep_supervisor(0, true))
}
