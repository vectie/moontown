///|
async fn render_moontown_planbook_status(
  workspace_root? : String = @moonbook.default_workspace_root(
    default_planbook_book_id(),
  ),
) -> String {
  let missing = missing_planbook_workspace_required_paths(workspace_root)
  [
    "# MoonTown Planbook Status",
    "",
    "- Book: `\{default_planbook_book_id()}`",
    "- Workspace: `\{workspace_root}`",
    "- Ready: `\{missing.is_empty()}`",
    "- Missing required: `\{missing.length()}`",
  ].join("\n")
}

///|
async fn missing_planbook_workspace_required_paths(
  workspace_root : String,
) -> Array[String] {
  let required = [
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
    @book_quality.generated_site_path(),
  ]
  let missing : Array[String] = []
  for path in required {
    if !@fs.exists("\{workspace_root}/\{path}") {
      missing.push(path)
    }
  }
  missing
}

///|
async fn render_wenyu_game_design_course_status(
  workspace_root? : String = @course_book.default_wenyu_course_workspace_root(),
) -> String {
  @course_book_runtime.render_wenyu_game_design_course_status(workspace_root~)
}
