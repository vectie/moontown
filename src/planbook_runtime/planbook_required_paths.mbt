///|
fn planbook_generated_site_path() -> String {
  @policy.default_generated_site_projection_path()
}

///|
fn planbook_generated_site_workspace_path(root : String) -> String {
  "\{root}/\{planbook_generated_site_path()}"
}

///|
fn planbook_workspace_required_paths() -> Array[String] {
  [
    "wiki/index.md",
    "raw/bootstrap/PLANBOOK_CONTRACT.md",
    "plans/2026-05-29-book-quality-upgrade/plan.md",
    "plans/2026-05-29-live-autonomy-spine/plan.md",
    "plans/2026-05-31-editor-mode-real-pipeline/plan.md",
    "plans/index.md",
    "wiki/planning/quality-gates.md",
    "wiki/planning/execution-evidence.md",
    "wiki/planning/role-model.md",
    "wiki/planning/operating-architecture.md",
    "wiki/reviews/active-plan-review.md",
    "wiki/history/decision-log.md",
    "wiki/history/change-log.md",
    "wiki/history/daily-engineering-digest.md",
    "wiki/planning/implementation-backlog.md",
    "wiki/planning/backlog-progress.md",
    "wiki/planning/stop-policy.md",
    "raw/backlog/implementation-backlog.json",
    "raw/backlog/progress.json",
    "schemas/plan-record.schema.md",
    "skills/code-plan/SKILL.md",
    "skills/code-review/SKILL.md",
    "skills/doc-sync/SKILL.md",
    "book/moonbook-ui-state.json",
    planbook_generated_site_path(),
  ]
}

///|
async fn missing_planbook_workspace_required_paths(
  workspace_root : String,
) -> Array[String] {
  let missing : Array[String] = []
  for path in planbook_workspace_required_paths() {
    if !@fs.exists("\{workspace_root}/\{path}") {
      missing.push(path)
    }
  }
  missing
}
