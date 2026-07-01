///|
test "wenyu build profile uses shared MoonClaw runtime policy" {
  let profile = wenyu_build_moonclaw_profile_json().stringify()
  assert_true(profile.contains("\"family\":\"wenyu_build_controller\""))
  assert_true(profile.contains("\"profile_metadata\":{"))
  assert_true(profile.contains("\"disable_waiting_for_input\":true"))
  assert_true(profile.contains("\"best_effort_on_missing_input\":true"))
  assert_true(profile.contains("\"role_runtime\":{"))
  assert_true(
    profile.contains(
      "\"output_contract\":\"\{@build_pipeline.wenyu_build_packet_contract()}\"",
    ),
  )
}

///|
test "wenyu build step metadata keeps builder controls" {
  let metadata = wenyu_build_step_metadata(
    preferred_skills=["wenyu-build", "wenyu-code-patch"],
    board_lane="Build",
    board_order=0,
  ).stringify()
  assert_true(
    metadata.contains(
      "\"preferred_skills\":[\"wenyu-build\",\"wenyu-code-patch\"]",
    ),
  )
  assert_true(metadata.contains("\"model\":\"gpt-5.5\""))
  assert_true(metadata.contains("\"enable_tools\":true"))
  assert_true(metadata.contains("\"web_search\":false"))
  assert_true(metadata.contains("\"timeout_ms\":600000"))
  assert_true(metadata.contains("\"board_lane\":\"Build\""))
  assert_true(metadata.contains("\"board_order\":0"))
  assert_true(metadata.contains("\"disable_waiting_for_input\":true"))
  assert_true(metadata.contains("\"best_effort_on_missing_input\":true"))
}

///|
test "wenyu build prompts preserve execution and review contracts" {
  let execute = @build_pipeline.wenyu_build_execute_prompt_template()
  assert_true(execute.contains("This is not a wiki query."))
  assert_true(execute.contains("external_packet"))
  assert_true(execute.contains("code patch"))
  assert_true(execute.contains("asset pack"))
  assert_true(execute.contains("validation results"))
  let review = @build_pipeline.wenyu_build_review_prompt_template()
  assert_false(review.contains(".moonclaw/run.json"))
  assert_true(review.contains("`run.json`"))
  assert_true(review.contains("source_workspace"))
  assert_true(review.contains("build/CODE_PATCH.md"))
  assert_true(review.contains("build/CODE_BLOCKERS.md"))
  assert_true(review.contains("repository absolute paths"))
}
