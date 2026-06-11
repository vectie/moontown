///|
pub fn change_log_seed_markdown() -> String {
  [
    "# PlanBook Change Log", "", "This log records live changes in the PlanBook-managed self-build system.",
    "", "## Seed", "", "- PlanBook workspace bootstrapped.",
  ].join("\n")
}

///|
pub fn daily_engineering_digest_seed_markdown() -> String {
  [
    "# Daily Engineering Digest", "", "This digest summarizes PlanBook self-build progress, validations, blockers, and commit readiness for overnight review.",
    "", "## Seed", "", "- No autonomy doctor run has refreshed this digest yet.",
  ].join("\n")
}
