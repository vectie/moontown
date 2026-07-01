///|
test "editor pipeline plan preserves course source and ownership boundaries" {
  let plan = editor_pipeline_plan_markdown()
  assert_true(plan.contains("# Plan: Editor Mode Real Pipeline"))
  assert_true(plan.contains("Course book: `course-wenyu-game-design`"))
  assert_true(plan.contains("buildings as protocols"))
  assert_true(plan.contains("Moontown owns the editor-pipeline contract"))
  assert_true(plan.contains("PlanBook owns the durable plan"))
  assert_true(plan.contains("MoonBook owns the course book content"))
  assert_true(plan.contains("MoonClaw owns bounded implementation execution"))
  assert_true(plan.contains("Moondesk later owns rich human editing"))
}

///|
test "editor pipeline plan keeps implementation and acceptance gates explicit" {
  let plan = editor_pipeline_plan_markdown()
  assert_true(plan.contains("restartable editor-pipeline state contract"))
  assert_true(plan.contains("Connect editor-mode UI to the contract"))
  assert_true(plan.contains("bounded PlanBook repair packet"))
  assert_true(plan.contains("Record validation evidence"))
  assert_true(
    plan.contains("A command can refresh/render editor-pipeline status"),
  )
  assert_true(
    plan.contains("Editor mode shows pipeline status from runtime state"),
  )
  assert_true(
    plan.contains("output mode can explain whether a change is planned"),
  )
}

///|
test "quality governance seed plan keeps contract-specific goals" {
  let plan = seed_plan_markdown()
  assert_true(plan.contains("# Plan: Raise MoonBook Quality Governance"))
  assert_true(plan.contains("PlanBook was only documented"))
  assert_true(plan.contains("Make course books visibly course-shaped"))
  assert_true(plan.contains("Do not turn every book into a research report"))
  assert_true(
    plan.contains("Semantic review results are produced by AI reviewers"),
  )
}

///|
test "plans index rows keep stable-state impact explicit" {
  let index = plans_index_markdown()
  assert_true(index.contains("2026-05-29-live-autonomy-spine/plan.md"))
  assert_true(index.contains("connects daemon, workers"))
  assert_true(index.contains("2026-05-31-editor-mode-real-pipeline/plan.md"))
  assert_true(index.contains("noisy `v1`, `v2`, `v3` copies"))
}

///|
test "live autonomy plan sections preserve ownership and validation gates" {
  let plan = live_autonomy_plan_markdown()
  assert_true(plan.contains("# Plan: Live Autonomy Spine"))
  assert_true(plan.contains("connective spine"))
  assert_true(plan.contains(".moonsuite/products/moontown/live-autonomy.json"))
  assert_true(plan.contains(".moonsuite/products/moontown/town-journal.jsonl"))
  assert_true(!plan.contains(".moontown/live-autonomy.json"))
  assert_true(plan.contains("Moontown Mayor owns the spine"))
  assert_true(
    plan.contains(
      "Every MoonClaw result writes a strict accepted/no-change/review/blocked contract",
    ),
  )
  assert_true(plan.contains("moon run src/cmd/main -- daemon run --once"))
}
