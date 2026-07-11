///|
test "bootstrap planning keeps a single-task ingest-first limit" {
  assert_eq(research_bootstrap_task_limit(), 1)
}

///|
test "Wenyu Valley PRD build goals trigger bootstrap coverage" {
  assert_true(
    @dispatch.research_goal_text(
      "Build Wenyu Valley AI Innovation Town according to docs/WENYU_VALLEY_PRD.md",
    ),
  )
}

///|
test "town goal slug is stable and filesystem safe" {
  assert_eq(
    @town_synthesis.town_goal_slug("Research MoonTown, MoonBook, and MoonClaw!"),
    "research-moontown-moonbook-and-moonclaw",
  )
}
