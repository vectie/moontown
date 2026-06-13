///|
test "no-input policy helper emits both nonblocking flags" {
  let text = no_input_policy_json().stringify()
  assert_true(text.contains("\"disable_waiting_for_input\":true"))
  assert_true(text.contains("\"best_effort_on_missing_input\":true"))
  let fields : Map[String, Json] = { "kind": "packet".to_json() }
  add_no_input_policy(fields)
  let merged = Json::object(fields).stringify()
  assert_true(merged.contains("\"kind\":\"packet\""))
  assert_true(merged.contains("\"disable_waiting_for_input\":true"))
  assert_true(merged.contains("\"best_effort_on_missing_input\":true"))
}

///|
test "execution metadata fields include optional target and no-input policy" {
  let fields = execution_metadata_fields(
    preferred_skills=["planbook-repair", "code-review"],
    execution_mode="acp",
    execution_target=Some("codex-main"),
    output_contract="moontown.planbook.repair.v1",
  )
  let text = Json::object(fields).stringify()
  assert_true(
    text.contains("\"preferred_skills\":[\"planbook-repair\",\"code-review\"]"),
  )
  assert_true(text.contains("\"execution_mode\":\"acp\""))
  assert_true(text.contains("\"execution_target\":\"codex-main\""))
  assert_true(
    text.contains("\"output_contract\":\"moontown.planbook.repair.v1\""),
  )
  assert_true(text.contains("\"disable_waiting_for_input\":true"))
  assert_true(text.contains("\"best_effort_on_missing_input\":true"))
}

///|
test "execution metadata fields can omit optional target" {
  let fields = execution_metadata_fields(
    preferred_skills=["editor-feature-rater"],
    execution_mode="local",
    output_contract="moontown.editor.feature-selection.v1",
  )
  let text = Json::object(fields).stringify()
  assert_true(text.contains("\"preferred_skills\":[\"editor-feature-rater\"]"))
  assert_true(text.contains("\"execution_mode\":\"local\""))
  assert_true(!text.contains("\"execution_target\""))
  assert_true(text.contains("\"disable_waiting_for_input\":true"))
  assert_true(text.contains("\"best_effort_on_missing_input\":true"))
}

///|
test "step metadata fields include shared runtime controls" {
  let fields = step_metadata_fields(
    preferred_skills=["skill-a", "skill-b"],
    enable_tools=true,
    web_search=false,
    timeout_ms=300000,
    board_lane="Review",
    board_order=2,
  )
  let text = Json::object(fields).stringify()
  assert_true(text.contains("\"preferred_skills\":[\"skill-a\",\"skill-b\"]"))
  assert_true(text.contains("\"enable_tools\":true"))
  assert_true(text.contains("\"web_search\":false"))
  assert_true(text.contains("\"timeout_ms\":300000"))
  assert_true(text.contains("\"board_lane\":\"Review\""))
  assert_true(text.contains("\"board_order\":2"))
  assert_true(text.contains("\"disable_waiting_for_input\":true"))
  assert_true(text.contains("\"best_effort_on_missing_input\":true"))
}
