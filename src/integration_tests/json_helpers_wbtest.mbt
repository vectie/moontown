///|
test "acp target upsert preserves existing targets" {
  let base = @json.parse(
    "{\"acp\":{\"targets\":{\"existing\":{\"backend\":\"noop\"}},\"enabled\":true},\"keep\":\"yes\"}",
  ) catch {
    _ => fail("expected base config to parse")
  }
  let next = @codex.upsert_acp_target_json(
    base,
    @codex.codex_main_target_id(),
    { "backend": "codex", "label": "Codex" },
  )
  let text = next.stringify()
  assert_true(text.contains("\"existing\":{\"backend\":\"noop\"}"))
  assert_true(
    text.contains("\"codex-main\":{\"backend\":\"codex\",\"label\":\"Codex\"}"),
  )
  assert_true(text.contains("\"enabled\":true"))
  assert_true(text.contains("\"keep\":\"yes\""))
}

///|
test "moonclaw job profile upsert preserves existing profiles" {
  let base = @json.parse(
    "{\"jobs\":{\"profiles\":{\"existing\":{\"family\":\"noop\"}},\"enabled\":true},\"keep\":\"yes\"}",
  ) catch {
    _ => fail("expected base config to parse")
  }
  let next = @support.upsert_moonclaw_job_profile_json(base, "worker", {
    "family": "worker",
    "role": "worker",
  })
  let text = next.stringify()
  assert_true(text.contains("\"existing\":{\"family\":\"noop\"}"))
  assert_true(
    text.contains("\"worker\":{\"family\":\"worker\",\"role\":\"worker\"}"),
  )
  assert_true(text.contains("\"enabled\":true"))
  assert_true(text.contains("\"keep\":\"yes\""))
}

///|
test "moonclaw no-input policy helper emits both nonblocking flags" {
  let text = @moonclaw_runtime.moonclaw_no_input_policy_json().stringify()
  assert_true(text.contains("\"disable_waiting_for_input\":true"))
  assert_true(text.contains("\"best_effort_on_missing_input\":true"))
  let fields : Map[String, Json] = { "kind": "packet".to_json() }
  @moonclaw_runtime.add_moonclaw_no_input_policy(fields)
  let merged = Json::object(fields).stringify()
  assert_true(merged.contains("\"kind\":\"packet\""))
  assert_true(merged.contains("\"disable_waiting_for_input\":true"))
  assert_true(merged.contains("\"best_effort_on_missing_input\":true"))
}

///|
test "moonclaw execution metadata fields include target and no-input policy" {
  let fields = @moonclaw_runtime.moonclaw_execution_metadata_fields(
    preferred_skills=["planbook-repair", "code-review"],
    execution_mode="acp",
    execution_target=Some(@codex.codex_main_target_id()),
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
test "moonclaw execution metadata fields omit optional target" {
  let fields = @moonclaw_runtime.moonclaw_execution_metadata_fields(
    preferred_skills=["editor-feature-rater"],
    execution_mode="local",
    output_contract="moontown.editor.feature-selection.v1",
  )
  let text = Json::object(fields).stringify()
  assert_true(text.contains("\"preferred_skills\":[\"editor-feature-rater\"]"))
  assert_true(text.contains("\"execution_mode\":\"local\""))
  assert_true(
    text.contains(
      "\"output_contract\":\"moontown.editor.feature-selection.v1\"",
    ),
  )
  assert_true(!text.contains("\"execution_target\""))
  assert_true(text.contains("\"disable_waiting_for_input\":true"))
  assert_true(text.contains("\"best_effort_on_missing_input\":true"))
}

///|
test "moonclaw step metadata fields include shared runtime controls" {
  let fields = @moonclaw_runtime.moonclaw_step_metadata_fields(
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

///|
test "json string field helper reads object string fields safely" {
  let parsed = @json.parse(
    "{\"content\":\"accepted result\",\"summary\":\"fallback\",\"count\":2}",
  ) catch {
    _ => fail("expected json to parse")
  }
  assert_eq(
    @support.json_string_field(parsed, "content").unwrap(),
    "accepted result",
  )
  assert_eq(@support.json_string_field(parsed, "summary").unwrap(), "fallback")
  assert_true(@support.json_string_field(parsed, "count") is None)
  assert_true(@support.json_string_field(parsed, "missing") is None)
  assert_true(
    @support.json_string_field("not object".to_json(), "content") is None,
  )
}

///|
test "json object field summary preserves non-string values" {
  let parsed = @json.parse(
    "{\"name\":\"moontown\",\"score\":3,\"flags\":[\"a\",\"b\"]}",
  ) catch {
    _ => fail("expected json to parse")
  }
  let object = match parsed {
    Object(object) => object
    _ => fail("expected object")
  }
  assert_eq(@support.json_object_string(object, "name").unwrap(), "moontown")
  assert_eq(
    @support.json_object_field_summary(object, "name").unwrap(),
    "\"moontown\"",
  )
  assert_eq(@support.json_object_field_summary(object, "score").unwrap(), "3")
  assert_eq(
    @support.json_object_field_summary(object, "flags").unwrap(),
    "[\"a\",\"b\"]",
  )
  assert_true(@support.json_object_field_summary(object, "missing") is None)
}
