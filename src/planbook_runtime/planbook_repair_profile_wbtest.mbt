///|
test "planbook repair profile prompt keeps bounded repair contract" {
  let prompt = planbook_repair_worker_prompt_template()
  assert_true(prompt.contains("Read ${proposal.request_text}."))
  assert_true(prompt.contains("context_pages and skill_paths"))
  assert_true(prompt.contains("exact target_files"))
  assert_true(prompt.contains("smallest safe repair"))
  assert_true(prompt.contains("precise ownership blocker"))
  assert_true(prompt.contains(planbook_repair_result_relative_path()))
  assert_true(prompt.contains(planbook_repair_result_contract()))
}

///|
test "planbook repair worker profile exposes ACP bounded repair metadata" {
  let profile = planbook_repair_worker_profile_json().stringify()
  assert_true(profile.contains("\"family\":\"planbook_repair_worker\""))
  assert_true(profile.contains("\"id\":\"repair_planbook_gap\""))
  assert_true(profile.contains("\"prompt_template\""))
  assert_true(profile.contains("\"execution_mode\":\"acp\""))
  assert_true(profile.contains("\"execution_target\":\"codex-main\""))
  assert_true(profile.contains("\"runtime_mode\":\"bounded-repair\""))
  assert_true(profile.contains("\"planning_layer\":\"town-self-healing\""))
  assert_true(profile.contains("\"tool_access\":\"codex-acp-repo-patch\""))
  assert_true(profile.contains(planbook_repair_result_contract()))
}
