///|
async fn write_planbook_workspace(entry : @moonbook.BookCatalogEntry) -> Unit {
  let root = entry.workspace_root
  write_planbook_core_files(entry)
  write_planbook_seed_plan_files(root)
  write_planbook_wiki_seed_files(root)
  ignore(ensure_planbook_backlog(root))
  write_planbook_schema_and_skill_files(root)
  write_planbook_projection_files(entry)
}

///|
async fn write_planbook_core_files(entry : @moonbook.BookCatalogEntry) -> Unit {
  let root = entry.workspace_root
  write_text_file("\{root}/wiki/index.md", planbook_index_markdown(entry))
  write_text_file(
    "\{root}/raw/bootstrap/PLANBOOK_CONTRACT.md",
    @planbook.contract_markdown(),
  )
}

///|
async fn write_planbook_seed_plan_files(root : String) -> Unit {
  write_text_file(
    "\{root}/plans/2026-05-29-book-quality-upgrade/plan.md",
    @planbook.seed_plan_markdown(),
  )
  write_text_file(
    "\{root}/plans/2026-05-29-live-autonomy-spine/plan.md",
    @planbook.live_autonomy_plan_markdown(),
  )
  write_text_file(
    "\{root}/plans/2026-05-31-editor-mode-real-pipeline/plan.md",
    @planbook.editor_pipeline_plan_markdown(),
  )
  write_text_file("\{root}/plans/index.md", @planbook.plans_index_markdown())
}

///|
async fn write_planbook_wiki_seed_files(root : String) -> Unit {
  write_text_file(
    "\{root}/wiki/planning/quality-gates.md",
    @planbook.quality_gates_markdown(),
  )
  write_text_file(
    "\{root}/wiki/planning/execution-evidence.md",
    @planbook.execution_evidence_markdown(),
  )
  write_text_file(
    "\{root}/wiki/planning/open-questions.md",
    @planbook.open_questions_markdown(),
  )
  write_text_file(
    "\{root}/wiki/planning/role-model.md",
    @planbook.role_model_markdown(),
  )
  write_text_file(
    "\{root}/wiki/planning/operating-architecture.md",
    @planbook.operating_architecture_markdown(),
  )
  write_text_file(
    "\{root}/wiki/reviews/active-plan-review.md",
    @planbook.active_review_markdown(),
  )
  write_text_file(
    "\{root}/wiki/history/decision-log.md",
    @planbook.decision_log_markdown(),
  )
  write_text_file(
    "\{root}/wiki/history/change-log.md",
    @planbook.change_log_seed_markdown(),
  )
  write_text_file(
    "\{root}/wiki/history/daily-engineering-digest.md",
    @planbook.daily_engineering_digest_seed_markdown(),
  )
}

///|
async fn write_planbook_schema_and_skill_files(root : String) -> Unit {
  write_text_file(
    "\{root}/schemas/plan-record.schema.md",
    @planbook.record_schema_markdown(),
  )
  write_text_file(
    "\{root}/skills/code-plan/SKILL.md",
    @planbook.code_plan_skill_markdown(),
  )
  write_text_file(
    "\{root}/skills/code-review/SKILL.md",
    @planbook.code_review_skill_markdown(),
  )
  write_text_file(
    "\{root}/skills/doc-sync/SKILL.md",
    @planbook.doc_sync_skill_markdown(),
  )
}

///|
async fn write_planbook_projection_files(
  entry : @moonbook.BookCatalogEntry,
) -> Unit {
  let root = entry.workspace_root
  write_text_file(
    "\{root}/book/moonbook-ui-state.json",
    @planbook.ui_state_json(entry),
  )
  let html = @planbook.generated_site_html(entry)
  write_text_file("\{root}/book/Home.html", html)
  write_text_file("\{root}/book/site/generated/index.html", html)
}
