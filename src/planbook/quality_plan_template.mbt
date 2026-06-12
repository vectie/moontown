///|
fn planbook_quality_problem_section() -> String {
  [
    "", "## Problem", "", "Moontown has strong research outputs in some workspaces, but book governance is uneven.",
    "PlanBook was only documented, course workspaces could inherit research-shaped metadata, and civic service books can remain scaffold-only without visible quality pressure.",
  ].join("\n")
}

///|
fn planbook_quality_goal_section() -> String {
  [
    "", "## Goal", "", "- Make planbook first-class and registered.", "- Make course books visibly course-shaped.",
    "- Score every registered book against its own contract.", "- Feed the weakest-book list back into cookbook and mayor supervision.",
  ].join("\n")
}

///|
fn planbook_quality_non_goals_section() -> String {
  [
    "", "## Non-Goals", "", "- Do not turn every book into a research report.", "- Do not hardcode civic domain answers.",
    "- Do not move MoonBook-owned projection internals into Moontown.",
  ].join("\n")
}

///|
fn planbook_quality_acceptance_section() -> String {
  [
    "", "## Acceptance Criteria", "", "- [x] `moon run src/cmd/main -- planbook bootstrap` creates a real MoonBook workspace.",
    "- [x] `moon run src/cmd/main -- books quality` renders per-book structural readiness and pending semantic review.",
    "- [x] `moon run src/cmd/main -- books doctor` writes durable JSON and Markdown audit artifacts.",
    "- [x] Course and civic books are scored by different structural expectations.",
    "- [ ] Semantic review results are produced by AI reviewers and written back to the review-result directory.",
    "- [ ] Validation passes with `moon check`, `moon test`, `moon fmt`, and `moon info`.",
  ].join("\n")
}
