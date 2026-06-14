///|
test "standing watch contracts own context and worker contract" {
  assert_eq(standing_watch_task_kind(), "standing-watch")
  assert_true(standing_watch_task_kind_matches(standing_watch_task_kind()))
  assert_false(standing_watch_task_kind_matches("watch"))
  assert_eq(standing_watch_skill_path(), "skills/standing-watch/SKILL.md")
  assert_true(
    standing_watch_skill_paths().contains(
      @research_policy.web_first_research_skill_path(),
    ),
  )
  assert_true(
    standing_watch_context_pages().contains("wiki/history/standing-watch.md"),
  )
  let contract = standing_watch_output_contract_lines().join("\n")
  assert_true(contract.contains("standing_goal_decision"))
  assert_true(contract.contains("checked_sources_count"))
  assert_true(contract.contains("book_changed: yes | no"))
}
