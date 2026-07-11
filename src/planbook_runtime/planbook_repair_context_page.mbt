///|
fn planbook_repair_context_markdown(
  criterion : PlanbookCriterionStatus,
) -> String {
  [
    planbook_repair_context_header(criterion),
    planbook_repair_context_target_files_section(criterion),
    planbook_repair_context_boundary_section(),
    planbook_repair_context_editor_feature_section(),
  ].join("\n")
}

///|
fn planbook_repair_context_header(
  criterion : PlanbookCriterionStatus,
) -> String {
  [
    "# PlanBook Repair Context",
    "",
    "- Criterion: `\{criterion.id}`",
    "- Plan: `\{criterion.plan_id}`",
    "- Title: \{criterion.title}",
    "- Owner: \{criterion.owner}",
    "- Satisfied: `\{criterion.satisfied}`",
    "- Evidence: \{criterion.evidence}",
    "- Next action: \{criterion.next_action}",
  ].join("\n")
}

///|
fn planbook_repair_context_target_files_section(
  criterion : PlanbookCriterionStatus,
) -> String {
  ["## Target Files", "", planbook_repair_target_files_markdown(criterion.id)].join(
    "\n",
  )
}

///|
fn planbook_repair_context_boundary_section() -> String {
  ["## Boundary Rule", "", planbook_repair_boundary_rule()].join("\n")
}

///|
fn planbook_repair_boundary_rule() -> String {
  "MoonTown may repair routing, daemon, live-spine, UI projection, and PlanBook evidence plumbing. MoonBook owns native book profiles, templates, and projections. MoonClaw owns execution runtime behavior and provider retry stability. Do not copy another project into MoonTown to fake ownership."
}

///|
fn planbook_repair_context_editor_feature_section() -> String {
  ["## AI-Selected Editor Feature", "", planbook_repair_editor_feature_rule()].join(
    "\n",
  )
}

///|
fn planbook_repair_editor_feature_rule() -> String {
  "When the criterion is `editor-selected-feature-implementation`, use `raw/editor-pipeline/next-feature.json` as the durable AI decision record. The repair worker may implement the chosen feature, but must not silently choose a different feature. Accepted work must write `raw/editor-pipeline/selected-feature-implementation.md` after validation."
}
