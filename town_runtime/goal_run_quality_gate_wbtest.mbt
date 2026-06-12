///|
test "deep report quality gate accepts research-shaped report" {
  let entry = goal_run_research_entry(
    id="research-moonbook",
    name="MoonBook Research",
    workspace_root="/tmp/moonbook",
  )
  assert_eq(
    @research_quality.deep_report_quality_gaps(
      entry,
      goal_run_research_shaped_report(),
    ).length(),
    0,
  )
}

///|
test "deep report quality gate rejects shallow process output" {
  let entry = goal_run_research_entry(
    id="research-moonclaw",
    name="MoonClaw Research",
    workspace_root="/tmp/moonclaw",
  )
  let gaps = @research_quality.deep_report_quality_gaps(
    entry,
    goal_run_shallow_process_report(),
  )
  assert_true(gaps.length() >= 5)
}

///|
async test "Wenyu civic books are excluded from research quality gates" {
  let entry = goal_run_wenyu_policy_hall_entry()
  assert_true(@research_quality.research_quality_gaps(entry).is_empty())
}

///|
test "Wenyu deep report quality gate uses module topic" {
  let entry = goal_run_wenyu_town_shell_entry()
  assert_eq(
    @research_quality.deep_report_quality_gaps(
      entry,
      goal_run_wenyu_deep_report(),
    ).length(),
    0,
  )
}
