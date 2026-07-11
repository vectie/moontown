///|
fn editor_pipeline_plan_source_section() -> String {
  [
    "## Source", "", "- Course book: `course-wenyu-game-design`.", "- Course page: `wiki/course/beginner-course.md`.",
    "- Relevant lessons: map labeling, roads before buildings, buildings as protocols, and mode separation.",
  ].join("\n")
}

///|
fn editor_pipeline_plan_problem_section() -> String {
  [
    "",
    "## Problem",
    "",
    "Wenyu editor mode is currently a useful validation surface, but it is not yet a complete town-owned implementation pipeline.",
    editor_pipeline_problem_missing_lifecycle_sentence(),
  ].join("\n")
}

///|
fn editor_pipeline_problem_missing_lifecycle_sentence() -> String {
  [
    "A designer can inspect modules, runtime bindings, MoonDesk handoff artifacts, and output coverage.",
    "The missing lifecycle is durable PlanBook goal creation, bounded MoonClaw implementation dispatch, repair evidence tracking, and final output readiness.",
  ].join(" ")
}

///|
fn editor_pipeline_plan_goal_section() -> String {
  [
    "", "## Goal", "", "- Treat editor mode changes as plan-first town work.", "- Use the course book as teaching/source context, not as hardcoded UI logic.",
    "- Let PlanBook store the plan, acceptance criteria, evidence, and review state.",
    "- Let MoonClaw execute bounded code/docs changes from the PlanBook packet.",
    "- Let the UI show editor pipeline status from runtime state rather than static copy.",
    "- Keep MoonDesk focused on detailed human workspace/file editing and portable artifacts.",
  ].join("\n")
}

///|
fn editor_pipeline_plan_ownership_section() -> String {
  [
    "", "## Ownership", "", "- MoonTown owns the editor-pipeline contract, command surface, runtime state, and operator UI binding.",
    "- PlanBook owns the durable plan, acceptance gates, repair packet, execution evidence, and review notes.",
    "- MoonBook owns the course book content and any generated course projection.",
    "- MoonClaw owns bounded implementation execution and structured result packaging.",
    "- MoonDesk later owns rich human editing of individual files, prompts, and single-agent workspaces.",
  ].join("\n")
}

///|
fn editor_pipeline_plan_implementation_section() -> String {
  [
    "",
    "## Implementation Shape",
    "",
    "1. Add a restartable editor-pipeline state contract under `\{@storage.moontown_product_display_artifact("editor-pipeline.json")}` or equivalent.",
    "2. Add a MoonTown command that refreshes/renders that state and references the PlanBook plan.",
    "3. Connect editor-mode UI to the contract so it shows source course, current plan, dispatch status, validation status, and output readiness.",
    "4. Ensure a bounded PlanBook repair packet can dispatch the missing implementation work through MoonClaw.",
    "5. Record validation evidence before claiming the pipeline is accepted.",
  ].join("\n")
}

///|
fn editor_pipeline_plan_acceptance_section() -> String {
  [
    "",
    "## Acceptance Criteria",
    "",
    "- [ ] A command can refresh/render editor-pipeline status without manually editing UI data.",
    "- [ ] The status links the Wenyu course book, this PlanBook plan, the current repair task, and final output mode.",
    "- [ ] Editor mode shows pipeline status from runtime state, not static prose.",
    "- [ ] A PlanBook repair dispatch can implement or repair this pipeline through MoonClaw.",
    editor_pipeline_validation_evidence_gate(),
    editor_pipeline_output_mode_gate(),
  ].join("\n")
}

///|
fn editor_pipeline_validation_evidence_gate() -> String {
  "- [ ] Validation records command/test output in PlanBook evidence."
}

///|
fn editor_pipeline_output_mode_gate() -> String {
  "- [ ] The output mode can explain whether a change is planned, running, accepted, blocked, or ready to export."
}
