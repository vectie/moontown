///|
test "civic status labels latest service result states" {
  assert_eq(
    civic_service_status_label(
      workspace_exists=true,
      missing_required_paths=[],
      skill_ready=true,
      moonclaw_profile_ready=true,
      latest_result_found=false,
      latest_decision="none",
      latest_review_items=0,
    ),
    "seeded",
  )
  assert_eq(
    civic_service_status_label(
      workspace_exists=true,
      missing_required_paths=[],
      skill_ready=true,
      moonclaw_profile_ready=true,
      latest_result_found=true,
      latest_decision="update",
      latest_review_items=0,
    ),
    "changed",
  )
  assert_eq(
    civic_service_status_label(
      workspace_exists=true,
      missing_required_paths=[],
      skill_ready=true,
      moonclaw_profile_ready=true,
      latest_result_found=true,
      latest_decision="update",
      latest_review_items=2,
    ),
    "needs-review",
  )
  assert_eq(
    civic_service_status_label(
      workspace_exists=true,
      missing_required_paths=[],
      skill_ready=true,
      moonclaw_profile_ready=true,
      latest_result_found=true,
      latest_decision="blocked",
      latest_review_items=0,
    ),
    "blocked",
  )
}

///|
test "civic service status categories define portfolio buckets" {
  assert_true(civic_service_status_is_seeded("seeded"))
  assert_true(!civic_service_status_is_seeded("changed"))
  assert_true(
    civic_service_status_is_missing_or_incomplete("missing-workspace"),
  )
  assert_true(civic_service_status_is_missing_or_incomplete("incomplete"))
  assert_true(civic_service_status_is_missing_or_incomplete("misconfigured"))
  assert_true(!civic_service_status_is_missing_or_incomplete("result-unknown"))
  assert_true(civic_service_status_is_review("needs-review"))
  assert_true(civic_service_status_is_blocked("blocked"))
  assert_true(civic_service_status_is_changed("changed"))
  assert_true(civic_service_status_is_no_change("no-change"))
}

///|
test "civic service status bucket table centralizes string categories" {
  assert_eq(civic_service_status_bucket("seeded"), "seeded")
  assert_eq(
    civic_service_status_bucket("missing-workspace"),
    "missing-or-incomplete",
  )
  assert_eq(civic_service_status_bucket("incomplete"), "missing-or-incomplete")
  assert_eq(
    civic_service_status_bucket("misconfigured"),
    "missing-or-incomplete",
  )
  assert_eq(civic_service_status_bucket("needs-review"), "review")
  assert_eq(civic_service_status_bucket("blocked"), "blocked")
  assert_eq(civic_service_status_bucket("changed"), "changed")
  assert_eq(civic_service_status_bucket("no-change"), "no-change")
  assert_eq(civic_service_status_bucket("result-unknown"), "other")
}

///|
test "civic status notes centralize service outcome messages" {
  assert_true(
    civic_status_note("seeded", "none", 0) ==
    Some("no civic service result has been accepted into this book yet"),
  )
  assert_true(
    civic_status_note("needs-review", "needs_review", 2) ==
    Some("2 review item(s) require keeper/operator judgment"),
  )
  assert_true(
    civic_status_note("blocked", "blocked", 0) ==
    Some("latest service run reported a blocker"),
  )
  assert_true(
    civic_status_note("changed", "update", 0) ==
    Some("latest service run reported an accepted update"),
  )
  assert_true(
    civic_status_note("no-change", "no_change", 0) ==
    Some("latest service run checked the module and found no material change"),
  )
  assert_true(
    civic_status_note("result-unknown", "surprising", 0) ==
    Some("latest decision is `surprising`"),
  )
  assert_true(civic_status_note("result-unknown", "none", 0) is None)
}
