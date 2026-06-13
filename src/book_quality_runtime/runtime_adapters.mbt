///|
fn optional_env_text(key : String) -> String? {
  match @sys.get_env_var(key) {
    Some(value) => {
      let trimmed = value.trim().to_owned()
      if trimmed.is_empty() {
        None
      } else {
        Some(trimmed)
      }
    }
    None => None
  }
}

///|
fn moontown_moonclaw_inline_enabled() -> Bool {
  match optional_env_text("MOONTOWN_MOONCLAW_INLINE") {
    Some(value) => {
      let lower = value.to_lower()
      lower == "1" || lower == "true" || lower == "yes" || lower == "on"
    }
    None => false
  }
}

///|
async fn bootstrap_moontown_cookbook(
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  workspace_root? : String = @cookbook.default_workspace_root(),
  manifest_path? : String = @cookbook.default_manifest_path(),
) -> String {
  let entry = @cookbook.book_entry(workspace_root)
  let catalog = @moonbook.load_or_create_catalog(path=book_catalog_path)
  @moonbook.save_catalog_file(
    book_catalog_path,
    @cookbook.merge_catalog(catalog, entry),
  )
  let manifest = @cookbook.manifest(workspace_root, manifest_path)
  @support.write_text_file(
    manifest_path,
    manifest.to_json().stringify(indent=2),
  )
  @cookbook.write_workspace(entry, manifest)
  "Bootstrapped MoonBook cookbook `\{entry.id}` at \{workspace_root}; wrote \{manifest_path}."
}

///|
fn default_planbook_book_id() -> String {
  "plan-moontown-quality"
}

///|
fn planbook_catalog_entry(
  workspace_root : String,
) -> @moonbook.BookCatalogEntry {
  @moonbook.BookCatalogEntry::new(
    id=default_planbook_book_id(),
    name="MoonBook / Moontown Quality Planbook",
    purpose="Durable planbook for implementation plans, acceptance criteria, execution evidence, review notes, and stable-state handoffs for Moontown quality work.",
    workspace_root~,
    memory_scope=@core.MemoryScope::BookPrivate,
    tags=["planbook", "code-plan", "quality-gates", "implementation", "review"],
    skills=["code-plan", "code-review", "doc-sync", "acceptance-gates"],
  )
}

///|
fn merge_single_book(
  catalog : Array[@moonbook.BookCatalogEntry],
  book : @moonbook.BookCatalogEntry,
) -> Array[@moonbook.BookCatalogEntry] {
  let merged : Array[@moonbook.BookCatalogEntry] = []
  for entry in catalog {
    if entry.id != book.id {
      merged.push(entry)
    }
  }
  merged.push(book)
  merged
}

///|
async fn bootstrap_moontown_planbook(
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  workspace_root? : String = @moonbook.default_workspace_root(
    default_planbook_book_id(),
  ),
) -> String {
  let entry = planbook_catalog_entry(workspace_root)
  let catalog = @moonbook.load_or_create_catalog(path=book_catalog_path)
  @moonbook.save_catalog_file(
    book_catalog_path,
    merge_single_book(catalog, entry),
  )
  write_planbook_workspace(entry)
  "Bootstrapped planbook `\{entry.id}` at \{workspace_root} and registered it in \{book_catalog_path}."
}

///|
async fn write_planbook_workspace(entry : @moonbook.BookCatalogEntry) -> Unit {
  let root = entry.workspace_root
  @support.write_text_file(
    "\{root}/wiki/index.md",
    @planbook.generated_site_html(entry),
  )
  @support.write_text_file(
    "\{root}/raw/bootstrap/PLANBOOK_CONTRACT.md",
    @planbook.contract_markdown(),
  )
  @support.write_text_file(
    "\{root}/plans/2026-05-29-book-quality-upgrade/plan.md",
    @planbook.seed_plan_markdown(),
  )
  @support.write_text_file(
    "\{root}/plans/2026-05-29-live-autonomy-spine/plan.md",
    @planbook.live_autonomy_plan_markdown(),
  )
  @support.write_text_file(
    "\{root}/plans/2026-05-31-editor-mode-real-pipeline/plan.md",
    @planbook.editor_pipeline_plan_markdown(),
  )
  @support.write_text_file(
    "\{root}/plans/index.md",
    @planbook.plans_index_markdown(),
  )
  @support.write_text_file(
    "\{root}/wiki/planning/quality-gates.md",
    @planbook.quality_gates_markdown(),
  )
  @support.write_text_file(
    "\{root}/wiki/planning/execution-evidence.md",
    @planbook.execution_evidence_markdown(),
  )
  @support.write_text_file(
    "\{root}/wiki/planning/open-questions.md",
    @planbook.open_questions_markdown(),
  )
  @support.write_text_file(
    "\{root}/wiki/planning/role-model.md",
    @planbook.role_model_markdown(),
  )
  @support.write_text_file(
    "\{root}/wiki/planning/operating-architecture.md",
    @planbook.operating_architecture_markdown(),
  )
  @support.write_text_file(
    "\{root}/wiki/reviews/active-plan-review.md",
    @planbook.active_review_markdown(),
  )
  @support.write_text_file(
    "\{root}/wiki/history/decision-log.md",
    @planbook.decision_log_markdown(),
  )
  @support.write_text_file(
    "\{root}/wiki/history/change-log.md",
    @planbook.change_log_seed_markdown(),
  )
  @support.write_text_file(
    "\{root}/wiki/history/daily-engineering-digest.md",
    @planbook.daily_engineering_digest_seed_markdown(),
  )
  @support.write_text_file(
    "\{root}/wiki/planning/implementation-backlog.md",
    "# Implementation Backlog\n",
  )
  @support.write_text_file(
    "\{root}/wiki/planning/backlog-progress.md",
    "# Backlog Progress\n",
  )
  @support.write_text_file(
    "\{root}/wiki/planning/stop-policy.md",
    "# Stop Policy\n",
  )
  @support.write_text_file(
    "\{root}/raw/backlog/implementation-backlog.json",
    "[]",
  )
  @support.write_text_file("\{root}/raw/backlog/progress.json", "{}")
  @support.write_text_file(
    "\{root}/schemas/plan-record.schema.md",
    @planbook.record_schema_markdown(),
  )
  @support.write_text_file(
    "\{root}/skills/code-plan/SKILL.md",
    @planbook.code_plan_skill_markdown(),
  )
  @support.write_text_file(
    "\{root}/skills/code-review/SKILL.md",
    @planbook.code_review_skill_markdown(),
  )
  @support.write_text_file(
    "\{root}/skills/doc-sync/SKILL.md",
    @planbook.doc_sync_skill_markdown(),
  )
  @support.write_text_file(
    "\{root}/book/moonbook-ui-state.json",
    @planbook.ui_state_json(entry),
  )
  let html = @planbook.generated_site_html(entry)
  @support.write_text_file("\{root}/book/Home.html", html)
  @support.write_text_file(
    @book_quality.workspace_path(root, @book_quality.generated_site_path()),
    html,
  )
}

///|
async fn bootstrap_wenyu_game_design_course_book(
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  workspace_root? : String = @course_book.default_wenyu_course_workspace_root(),
  source_workspace_root? : String = "",
) -> String {
  @course_book_runtime.bootstrap_wenyu_game_design_course_book(
    book_catalog_path~,
    workspace_root~,
    source_workspace_root~,
  )
}
