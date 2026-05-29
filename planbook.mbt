///|
pub fn default_planbook_book_id() -> String {
  "plan-moontown-quality"
}

///|
pub fn default_planbook_workspace_root() -> String {
  @moonbook.default_workspace_root(default_planbook_book_id())
}

///|
pub async fn bootstrap_moontown_planbook(
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  workspace_root? : String = default_planbook_workspace_root(),
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
pub async fn render_moontown_planbook_status(
  workspace_root? : String = default_planbook_workspace_root(),
) -> String {
  let checks = [
    "wiki/index.md", "raw/bootstrap/PLANBOOK_CONTRACT.md", "plans/2026-05-29-book-quality-upgrade/plan.md",
    "plans/index.md", "wiki/planning/quality-gates.md", "wiki/planning/execution-evidence.md",
    "wiki/reviews/active-plan-review.md", "wiki/history/decision-log.md", "schemas/plan-record.schema.md",
    "skills/code-plan/SKILL.md", "skills/code-review/SKILL.md", "skills/doc-sync/SKILL.md",
    "book/moonbook-ui-state.json", "book/site/generated/index.html",
  ]
  let missing : Array[String] = []
  for path in checks {
    if !@fs.exists("\{workspace_root}/\{path}") {
      missing.push(path)
    }
  }
  [
    "# Moontown Planbook Status",
    "",
    "- Book: `\{default_planbook_book_id()}`",
    "- Workspace: `\{workspace_root}`",
    "- Ready: `\{missing.is_empty()}`",
    "- Missing required: `\{missing.length()}`",
    "",
    "## Missing",
    "",
    if missing.is_empty() {
      "- none"
    } else {
      markdown_bullets(missing)
    },
  ].join("\n")
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
async fn write_planbook_workspace(entry : @moonbook.BookCatalogEntry) -> Unit {
  let root = entry.workspace_root
  write_text_file("\{root}/wiki/index.md", planbook_index_markdown(entry))
  write_text_file(
    "\{root}/raw/bootstrap/PLANBOOK_CONTRACT.md",
    planbook_contract_markdown(),
  )
  write_text_file(
    "\{root}/plans/2026-05-29-book-quality-upgrade/plan.md",
    planbook_seed_plan_markdown(),
  )
  write_text_file("\{root}/plans/index.md", planbook_plans_index_markdown())
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
    "\{root}/wiki/reviews/active-plan-review.md",
    planbook_active_review_markdown(),
  )
  write_text_file(
    "\{root}/wiki/history/decision-log.md",
    planbook_decision_log_markdown(),
  )
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
  write_text_file(
    "\{root}/book/moonbook-ui-state.json",
    planbook_ui_state_json(entry),
  )
  let html = planbook_generated_site_html(entry)
  write_text_file("\{root}/book/Home.html", html)
  write_text_file("\{root}/book/site/generated/index.html", html)
}

///|
fn planbook_index_markdown(entry : @moonbook.BookCatalogEntry) -> String {
  [
    "# Moontown Quality Planbook",
    "",
    "This MoonBook manages implementation intent. It is not a research book and not a course. It stores plans, acceptance criteria, execution evidence, review notes, and stable-state handoffs.",
    "",
    "## Ownership",
    "",
    "- Mayor decides when a change needs a planbook plan.",
    "- MoonBook stores plans, review state, quality gates, and execution evidence.",
    "- MoonClaw executes bounded work against a plan and updates evidence.",
    "- Cookbook only changes after a plan is accepted as stable state.",
    "",
    "## Book",
    "",
    "- Book id: `\{entry.id}`",
    "- Workspace: `\{entry.workspace_root}`",
    "",
    "## Start Here",
    "",
    "- `raw/bootstrap/PLANBOOK_CONTRACT.md`",
    "- `plans/index.md`",
    "- `plans/2026-05-29-book-quality-upgrade/plan.md`",
    "- `wiki/planning/quality-gates.md`",
    "- `wiki/planning/execution-evidence.md`",
    "- `wiki/reviews/active-plan-review.md`",
    "- `wiki/history/decision-log.md`",
    "- `skills/code-plan/SKILL.md`",
  ].join("\n")
}

///|
fn planbook_contract_markdown() -> String {
  [
    "# Planbook Contract", "", "A planbook exists to make non-trivial change safe, resumable, and reviewable.",
    "", "## Rules", "", "- Write one durable plan per coherent change area.", "- Preserve the decision trail instead of creating noisy `v1`, `v2`, `v3` plan copies.",
    "- Include problem, current state, decision, alternatives, affected files, steps, acceptance criteria, validation, rollback, and follow-up.",
    "- If the task changes Moontown/MoonBook/MoonClaw/Moondesk ownership, state the boundary explicitly.",
    "- Execution must update evidence and review notes before claiming completion.",
    "- Quality repair is allowed as review work, but the plan should aim to pass on the first implementation attempt.",
  ].join("\n")
}

///|
fn planbook_seed_plan_markdown() -> String {
  [
    "# Plan: Raise MoonBook Quality Governance", "", "## Problem", "", "Moontown has strong research outputs in some workspaces, but book governance is uneven: planbook was only documented, course workspaces could inherit research-shaped metadata, and civic service books can remain scaffold-only without visible quality pressure.",
    "", "## Goal", "", "- Make planbook first-class and registered.", "- Make course books visibly course-shaped.",
    "- Score every registered book against its own contract.", "- Feed the weakest-book list back into cookbook and mayor supervision.",
    "", "## Non-Goals", "", "- Do not turn every book into a research report.", "- Do not hardcode civic domain answers.",
    "- Do not move MoonBook-owned projection internals into Moontown.", "", "## Acceptance Criteria",
    "", "- [x] `moon run cmd/main -- planbook bootstrap` creates a real MoonBook workspace.",
    "- [x] `moon run cmd/main -- books quality` renders per-book structural readiness and pending semantic review.",
    "- [x] `moon run cmd/main -- books doctor` writes durable JSON and Markdown audit artifacts.",
    "- [x] Course and civic books are scored by different structural expectations.",
    "- [ ] Semantic review results are produced by AI reviewers and written back to the review-result directory.",
    "- [ ] Validation passes with `moon check`, `moon test`, `moon fmt`, and `moon info`.",
  ].join("\n")
}

///|
fn planbook_plans_index_markdown() -> String {
  [
    "# Plans Index", "", "| Plan | Status | Owner | Stable-State Impact |", "| --- | --- | --- | --- |",
    "| `2026-05-29-book-quality-upgrade/plan.md` | active-review | Moontown + MoonBook | separates structural readiness from semantic quality and formalizes planbook/cookbook/course/civic workspaces |",
    "", "Planbook rule: update the existing plan and evidence pages instead of creating noisy `v1`, `v2`, `v3` copies.",
  ].join("\n")
}

///|
fn planbook_quality_gates_markdown() -> String {
  [
    "# Planbook Quality Gates", "", "| Gate | Required Evidence |", "| --- | --- |",
    "| Intent | problem, goal, non-goals, owner boundary |", "| Design | selected approach plus alternatives |",
    "| Execution | changed files or explicit blocker |", "| Validation | commands and results |",
    "| Review | accepted criteria, unresolved risks, cookbook impact |",
  ].join("\n")
}

///|
fn planbook_execution_evidence_markdown() -> String {
  [
    "# Execution Evidence", "", "This page records what changed for active plans. It is intentionally separate from the plan text so execution can continue without rewriting the intent.",
    "", "## Current Evidence", "", "- Planbook workspace exists as a registered MoonBook.",
    "- Course, cookbook, civic, operational, and planbook workspaces have separate structural expectations.",
    "- Book-quality audit now separates structural readiness from semantic AI review.",
    "", "## Required Future Evidence", "", "- Commands run and results.", "- Files changed.",
    "- Review findings.", "- Cookbook impact.", "- Remaining risks.",
  ].join("\n")
}

///|
fn planbook_active_review_markdown() -> String {
  [
    "# Active Plan Review", "", "## Review State", "", "- Status: active-review",
    "- Reviewer: keeper/operator or MoonClaw reviewer", "- Decision: pending semantic review",
    "", "## Findings To Check", "", "- Does the course book avoid research-report language?",
    "- Do civic books contain real service ledgers and review history, not just contracts?",
    "- Does the cookbook explain stable-state boundaries clearly enough for Moondesk and Moontown?",
    "- Does the planbook provide execution evidence and review state, not just templates?",
  ].join("\n")
}

///|
fn planbook_decision_log_markdown() -> String {
  [
    "# Decision Log", "", "| Date | Decision | Reason |", "| --- | --- | --- |",
    "| 2026-05-29 | Separate structural readiness from semantic quality | File completeness cannot judge usefulness, originality, correctness, or genre fit. |",
    "| 2026-05-29 | Treat planbook as a first-class MoonBook workspace | Complex code/product changes need durable plan, evidence, review, and cookbook handoff state. |",
  ].join("\n")
}

///|
fn planbook_record_schema_markdown() -> String {
  [
    "# Plan Record Schema", "", "- `id`: stable plan id", "- `status`: proposed, active, blocked, active-review, accepted, superseded",
    "- `problem`: why the plan exists", "- `owner_boundary`: Moontown, MoonBook, MoonClaw, Moondesk responsibility split",
    "- `affected_files`: expected implementation/doc files", "- `acceptance_criteria`: checklist",
    "- `execution_evidence`: changed files, commands, result links", "- `review_decision`: accepted, needs-fix, blocked",
    "- `cookbook_impact`: none, update-needed, updated",
  ].join("\n")
}

///|
fn planbook_open_questions_markdown() -> String {
  [
    "# Open Planning Questions", "", "- Which book has the weakest current quality score?",
    "- Is the weakness a MoonBook skill/profile issue, a Moontown routing issue, or a MoonClaw execution issue?",
    "- Does fixing the weakness change the stable cookbook contract?",
  ].join("\n")
}

///|
fn code_plan_skill_markdown() -> String {
  [
    "---", "name: code-plan", "description: Produce implementation-grade plans for code, product, UI, daemon, documentation, or multi-agent changes.",
    "---", "", "# Code Plan Skill", "", "Create a durable plan that a fresh MoonClaw or Codex session can execute without hidden chat context.",
    "", "## Required Shape", "", "- Problem", "- Current state with file/doc references",
    "- Goal and non-goals", "- Design decision", "- Alternatives considered", "- Affected files and packages",
    "- Implementation steps", "- Acceptance criteria with checkboxes", "- Validation commands",
    "- Rollback/recovery path", "- Follow-up tasks", "", "## Quality Bar", "", "- Be specific to this repo and this runtime.",
    "- Avoid generic advice.", "- Explain ownership boundaries.", "- Make the plan small enough to execute, but complete enough to resume.",
    "", "## Concrete Example", "", "```md", "# Plan: Add Book Quality Audit", "Problem: registered books can drift without a durable score.",
    "Affected files: `book_quality.mbt`, `cmd/main/main.mbt`, `docs/USAGE.md`.",
    "Acceptance: `books doctor` writes JSON/Markdown; weak books are listed first; `moon check` passes.",
    "```",
  ].join("\n")
}

///|
fn code_review_skill_markdown() -> String {
  [
    "---", "name: code-review", "description: Review a completed plan for regressions, missing validation, boundary leaks, and unresolved acceptance criteria.",
    "---", "", "# Code Review Skill", "", "Review the plan outcome before it is promoted into stable state.",
    "", "## Checklist", "", "- Did the implementation satisfy each acceptance criterion?",
    "- Were tests run and recorded?", "- Did public APIs change intentionally?",
    "- Did any book type inherit the wrong skill/profile/projection?", "- Did operational evidence inflate domain evidence?",
    "- Is cookbook impact explicit?", "", "## Concrete Example", "", "```md", "review_decision: needs_fix",
    "finding: course book still uses research index metadata.", "fix_owner: MoonBook projection layer",
    "validation_needed: rerun course bootstrap and inspect `wiki/index.md`.", "```",
  ].join("\n")
}

///|
fn doc_sync_skill_markdown() -> String {
  [
    "---", "name: doc-sync", "description: Synchronize accepted implementation changes into Moontown docs and cookbook stable-state definitions.",
    "---", "", "# Doc Sync Skill", "", "Update documentation only after the plan evidence proves the behavior changed.",
    "", "## Rules", "", "- Update operator commands, architecture ownership, and known limitations.",
    "- Link from cookbook when the stable state changes.", "- Do not document aspirational behavior as already working.",
    "", "## Concrete Example", "", "```md", "doc_sync_decision: update", "docs_changed: `docs/USAGE.md`, `docs/ARCHITECTURE.md`",
    "cookbook_changed: yes", "reason: new `books doctor` command is now validated.",
    "```",
  ].join("\n")
}

///|
fn planbook_ui_state_json(entry : @moonbook.BookCatalogEntry) -> String {
  [
    "{",
    "  \"book_id\": \{json_string(entry.id)},",
    "  \"title\": \"Moontown Quality Planbook\",",
    "  \"summary\": \"Implementation plans, acceptance gates, execution evidence, and review notes for Moontown quality work.\",",
    "  \"status_chips\": [",
    "    {\"label\":\"planbook\",\"tone\":\"healthy\"},",
    "    {\"label\":\"acceptance-gated\",\"tone\":\"review\"},",
    "    {\"label\":\"cookbook handoff\",\"tone\":\"info\"}",
    "  ],",
    "  \"metrics\": [",
    "    {\"label\":\"Seed plans\",\"value\":\"1\",\"note\":\"quality upgrade plan\",\"tone\":\"healthy\"},",
    "    {\"label\":\"Skills\",\"value\":\"3\",\"note\":\"plan, review, doc sync\",\"tone\":\"healthy\"}",
    "  ],",
    "  \"readiness\": [",
    "    {\"title\":\"Planbook contract\",\"detail\":\"raw/bootstrap/PLANBOOK_CONTRACT.md\",\"meta\":\"Ready\"},",
    "    {\"title\":\"Quality plan\",\"detail\":\"plans/2026-05-29-book-quality-upgrade/plan.md\",\"meta\":\"Ready\"}",
    "  ],",
    "  \"review_queue\": [",
    "    {\"title\":\"Book quality audit\",\"detail\":\"Run `books doctor` and fix the lowest score first.\",\"meta\":\"Open\"}",
    "  ],",
    "  \"page_families\": [",
    "    {\"title\":\"Quality Gates\",\"detail\":\"wiki/planning/quality-gates.md\",\"meta\":\"Planning\"}",
    "  ],",
    "  \"journey\": [",
    "    {\"title\":\"Planbook bootstrap\",\"stage\":\"generated\",\"status\":\"review\",\"summary\":\"Moontown registered a first-class planbook workspace for world-class book quality governance.\",\"highlights\":[]}",
    "  ]",
    "}",
  ].join("\n")
}

///|
fn planbook_generated_site_html(entry : @moonbook.BookCatalogEntry) -> String {
  [
    "<!doctype html><html lang=\"en\"><head><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width,initial-scale=1\"><title>Moontown Quality Planbook</title>",
    "<style>body{margin:0;background:#101820;color:#f7f3e8;font-family:Georgia,serif}main{max-width:980px;margin:auto;padding:56px 24px}.hero{border:1px solid #d8c58a;border-radius:28px;padding:34px;background:linear-gradient(135deg,#172536,#263f4c)}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(230px,1fr));gap:16px}.card{margin-top:18px;padding:18px;border:1px solid rgba(216,197,138,.35);border-radius:18px;background:rgba(255,255,255,.07)}code{color:#ffe08a}</style></head><body><main>",
    "<section class=\"hero\"><p>MoonBook managed / Mayor routed / MoonClaw executed</p><h1>Moontown Quality Planbook</h1><p>Workspace <code>\{html_escape(entry.workspace_root)}</code>. Plans are the durable checkpoint before implementation and cookbook promotion.</p></section>",
    "<section class=\"grid\"><article class=\"card\"><h2>Plan</h2><p>Problem, current state, decision, steps, and acceptance criteria.</p></article><article class=\"card\"><h2>Execute</h2><p>MoonClaw works against the plan and records evidence.</p></article><article class=\"card\"><h2>Review</h2><p>Quality gates decide whether the result becomes stable state.</p></article></section>",
    "</main></body></html>",
  ].join("\n")
}
