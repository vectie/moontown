///|
test "moonbook worker contracts own generic keeper defaults" {
  assert_eq(wiki_maintainer_skill_path(), "skills/wiki-maintainer/SKILL.md")
  assert_true(
    default_keeper_skill_paths().contains(wiki_maintainer_skill_path()),
  )
  assert_true(default_keeper_context_pages().contains("wiki/index.md"))
  assert_true(default_keeper_context_pages().contains("wiki/log.md"))
  assert_true(
    fallback_keeper_policy_lines()
    .join("\n")
    .contains("responsibility boundaries"),
  )
  assert_true(
    fallback_keeper_routine_lines().join("\n").contains("target pages"),
  )
  assert_true(
    fallback_keeper_memory_summary("coding", "sync").contains(
      "task `sync` in book `coding`",
    ),
  )
  assert_true(fallback_keeper_output_contract_lines().contains("notify_town"))
}
