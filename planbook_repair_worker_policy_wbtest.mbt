///|
test "planbook repair treats temporary dispatch contention as retryable" {
  assert_true(
    planbook_repair_transient_dispatch_error(
      "MoonClaw repair dispatch failed: Resource temporarily unavailable",
    ),
  )
  assert_true(
    planbook_repair_transient_dispatch_error(
      "MoonClaw repair dispatch failed: {bad request}",
    ),
  )
  assert_true(
    planbook_repair_transient_dispatch_error(
      "Error: Failed to resolve the module dependency graph\nUnable to lock folder `/Users/kq/Workspace/moonclaw/.mooncakes` for downloading dependencies\nOperation not permitted (os error 1)",
    ),
  )
  assert_true(
    planbook_repair_transient_dispatch_error(
      "RUNTIME ERROR: abort() called\nStringBuilder::grow_if_necessary\n@vectie/moonclaw/job.SystemStore::save_job_proposals",
    ),
  )
  assert_true(
    !planbook_repair_transient_dispatch_error(
      "MoonClaw repair dispatch failed: schema violation",
    ),
  )
}

///|
test "planbook repair packet helpers expose stable worker policy" {
  assert_eq(
    planbook_repair_preferred_skills().join(","),
    "planbook-repair,code-plan,code-review",
  )
  assert_true(
    planbook_repair_required_engineering_steps().contains("run-validation"),
  )
  assert_true(
    planbook_repair_required_engineering_steps().contains(
      "prepare-commit-summary",
    ),
  )
  let wait_policy = planbook_repair_wait_policy_json().stringify()
  assert_true(wait_policy.contains("\"disable_waiting_for_input\":true"))
  assert_true(wait_policy.contains("\"best_effort_on_missing_input\":true"))
  assert_true(wait_policy.contains("\"best_effort_on_timeout\":false"))
  assert_true(wait_policy.contains("\"timeout_ms\":600000"))
  let git_policy = planbook_repair_git_policy_json().stringify()
  assert_true(git_policy.contains("\"commit_after_validation\":true"))
  assert_true(git_policy.contains("\"push_after_commit\":false"))
  assert_true(git_policy.contains("\"commit_message_required\":true"))
}

///|
test "planbook bounded wait policy is shared by repair-style workers" {
  let fields : Map[String, Json] = { "kind": "editor".to_json() }
  add_planbook_bounded_wait_policy(fields)
  let text = Json::object(fields).stringify()
  assert_true(text.contains("\"kind\":\"editor\""))
  assert_true(text.contains("\"disable_waiting_for_input\":true"))
  assert_true(text.contains("\"best_effort_on_missing_input\":true"))
  assert_true(text.contains("\"best_effort_on_timeout\":false"))
  assert_true(text.contains("\"timeout_ms\":600000"))
  assert_true(
    planbook_bounded_wait_policy_json().stringify() ==
    planbook_repair_wait_policy_json().stringify(),
  )
}

///|
test "planbook bounded step metadata uses shared nonblocking policy" {
  let metadata = planbook_bounded_step_metadata_json(
    preferred_skills=["planbook-repair"],
    execution_mode="acp",
    execution_target=Some("codex-main"),
    output_contract="planbook.repair.result.v1",
    source_root="/tmp/moontown",
    target_files=["planbook.mbt"],
    target_pages=["wiki/reviews/active-plan-review.md"],
    planning_layer="town-self-build",
    runtime_mode="bounded-repair",
    tool_access="workspace-write",
  ).stringify()
  assert_true(metadata.contains("\"preferred_skills\":[\"planbook-repair\"]"))
  assert_true(metadata.contains("\"execution_mode\":\"acp\""))
  assert_true(metadata.contains("\"execution_target\":\"codex-main\""))
  assert_true(metadata.contains("\"disable_waiting_for_input\":true"))
  assert_true(metadata.contains("\"best_effort_on_missing_input\":true"))
  assert_true(metadata.contains("\"best_effort_on_timeout\":false"))
  assert_true(metadata.contains("\"timeout_ms\":600000"))
  assert_true(metadata.contains("\"role_runtime\":{"))
}
