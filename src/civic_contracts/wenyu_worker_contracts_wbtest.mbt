///|
test "wenyu worker contracts own base and civic skill paths" {
  assert_true(wenyu_base_skill_paths().contains(wenyu_build_skill_path()))
  assert_true(wenyu_base_skill_paths().contains(wenyu_code_patch_skill_path()))
  assert_true(
    wenyu_base_skill_paths().contains(
      @research_policy.web_first_research_skill_path(),
    ),
  )
  assert_true(
    wenyu_civic_skill_paths(["skills/domain-specialist/SKILL.md"]).contains(
      wenyu_civic_service_skill_path(),
    ),
  )
}

///|
test "wenyu worker contracts own context and output contracts" {
  assert_eq(wenyu_prd_path(), "raw/bootstrap/WENYU_VALLEY_PRD.md")
  assert_eq(wenyu_vision_path(), "raw/bootstrap/WENYU_VISION.md")
  assert_eq(wenyu_build_report_path(), "raw/bootstrap/deep-report.md")
  assert_true(wenyu_base_context_pages().contains(wenyu_prd_path()))
  assert_true(
    wenyu_civic_context_pages().contains(wenyu_civic_service_contract_path()),
  )
  assert_true(
    wenyu_civic_context_pages().contains(wenyu_moonbook_ui_state_path()),
  )
  let contract = wenyu_civic_output_contract_lines().join("\n")
  assert_true(contract.contains("civic_service_decision"))
  assert_true(contract.contains("changed_pages"))
  assert_true(contract.contains("protocol_decision_basis"))
}
