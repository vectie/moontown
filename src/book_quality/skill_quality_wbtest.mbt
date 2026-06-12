///|
test "skill quality contract exposes simple metrics" {
  let text = @skill_quality.exploration_quality_contract_section()
  assert_true(text.contains("Go deeper"))
  assert_true(text.contains("Go broader"))
  assert_true(text.contains("Generate new questions"))
  assert_true(text.contains("Generate new directions"))
  assert_true(text.contains("longer meaningful text"))
  assert_true(@skill_quality.exploration_quality_contract_is_strong(text))
}
