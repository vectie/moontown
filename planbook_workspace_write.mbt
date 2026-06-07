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
    planbook_contract_markdown(),
  )
}

///|
async fn write_planbook_seed_plan_files(root : String) -> Unit {
  write_text_file(
    "\{root}/plans/2026-05-29-book-quality-upgrade/plan.md",
    planbook_seed_plan_markdown(),
  )
  write_text_file(
    "\{root}/plans/2026-05-29-live-autonomy-spine/plan.md",
    planbook_live_autonomy_plan_markdown(),
  )
  write_text_file(
    "\{root}/plans/2026-05-31-editor-mode-real-pipeline/plan.md",
    planbook_editor_pipeline_plan_markdown(),
  )
  write_text_file("\{root}/plans/index.md", planbook_plans_index_markdown())
}

///|
async fn write_planbook_wiki_seed_files(root : String) -> Unit {
  write_text_file(
    "\{root}/wiki/planning/quality-gates.md",
    planbook_quality_gates_markdown(),
  )
  write_text_file(
    "\{root}/wiki/planning/execution-evidence.md",
    planbook_execution_evidence_markdown(),
  )
  write_text_file(
    "\{root}/wiki/planning/open-questions.md",
    planbook_open_questions_markdown(),
  )
  write_text_file(
    "\{root}/wiki/planning/role-model.md",
    planbook_role_model_markdown(),
  )
  write_text_file(
    "\{root}/wiki/planning/operating-architecture.md",
    planbook_operating_architecture_markdown(),
  )
  write_text_file(
    "\{root}/wiki/reviews/active-plan-review.md",
    planbook_active_review_markdown(),
  )
  write_text_file(
    "\{root}/wiki/history/decision-log.md",
    planbook_decision_log_markdown(),
  )
  write_text_file(
    "\{root}/wiki/history/change-log.md",
    planbook_change_log_seed_markdown(),
  )
  write_text_file(
    "\{root}/wiki/history/daily-engineering-digest.md",
    planbook_daily_engineering_digest_seed_markdown(),
  )
}

///|
async fn write_planbook_schema_and_skill_files(root : String) -> Unit {
  write_text_file(
    "\{root}/schemas/plan-record.schema.md",
    planbook_record_schema_markdown(),
  )
  write_text_file(
    "\{root}/skills/code-plan/SKILL.md",
    code_plan_skill_markdown(),
  )
  write_text_file(
    "\{root}/skills/code-review/SKILL.md",
    code_review_skill_markdown(),
  )
  write_text_file("\{root}/skills/doc-sync/SKILL.md", doc_sync_skill_markdown())
}

///|
async fn write_planbook_projection_files(
  entry : @moonbook.BookCatalogEntry,
) -> Unit {
  let root = entry.workspace_root
  write_text_file(
    "\{root}/book/moonbook-ui-state.json",
    planbook_ui_state_json(entry),
  )
  let html = planbook_generated_site_html(entry)
  write_text_file("\{root}/book/Home.html", html)
  write_text_file("\{root}/book/site/generated/index.html", html)
}
