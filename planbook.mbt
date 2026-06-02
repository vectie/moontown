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
  if @fs.exists("\{workspace_root}/wiki/index.md") {
    ensure_planbook_seed_files(workspace_root)
  }
  let checks = [
    "wiki/index.md", "raw/bootstrap/PLANBOOK_CONTRACT.md", "plans/2026-05-29-book-quality-upgrade/plan.md",
    "plans/2026-05-29-live-autonomy-spine/plan.md", "plans/2026-05-31-editor-mode-real-pipeline/plan.md",
    "plans/index.md", "wiki/planning/quality-gates.md", "wiki/planning/execution-evidence.md",
    "wiki/planning/role-model.md", "wiki/planning/operating-architecture.md", "wiki/reviews/active-plan-review.md",
    "wiki/history/decision-log.md", "wiki/history/change-log.md", "wiki/history/daily-engineering-digest.md",
    "wiki/planning/implementation-backlog.md", "wiki/planning/backlog-progress.md",
    "wiki/planning/stop-policy.md", "raw/backlog/implementation-backlog.json", "raw/backlog/progress.json",
    "schemas/plan-record.schema.md", "skills/code-plan/SKILL.md", "skills/code-review/SKILL.md",
    "skills/doc-sync/SKILL.md", "book/moonbook-ui-state.json", "book/site/generated/index.html",
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
  write_text_file(
    "\{root}/plans/2026-05-29-live-autonomy-spine/plan.md",
    planbook_live_autonomy_plan_markdown(),
  )
  write_text_file(
    "\{root}/plans/2026-05-31-editor-mode-real-pipeline/plan.md",
    planbook_editor_pipeline_plan_markdown(),
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
  ignore(ensure_planbook_backlog(root))
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
async fn ensure_planbook_seed_files(workspace_root : String) -> Unit {
  write_text_file_if_missing(
    "\{workspace_root}/wiki/planning/quality-gates.md",
    planbook_quality_gates_markdown(),
  )
  write_text_file_if_missing(
    "\{workspace_root}/wiki/planning/execution-evidence.md",
    planbook_execution_evidence_markdown(),
  )
  write_text_file_if_missing(
    "\{workspace_root}/wiki/planning/open-questions.md",
    planbook_open_questions_markdown(),
  )
  write_text_file_if_missing(
    "\{workspace_root}/wiki/planning/role-model.md",
    planbook_role_model_markdown(),
  )
  write_text_file_if_missing(
    "\{workspace_root}/wiki/planning/operating-architecture.md",
    planbook_operating_architecture_markdown(),
  )
  write_text_file_if_missing(
    "\{workspace_root}/wiki/reviews/active-plan-review.md",
    planbook_active_review_markdown(),
  )
  write_text_file_if_missing(
    "\{workspace_root}/wiki/history/decision-log.md",
    planbook_decision_log_markdown(),
  )
  write_text_file_if_missing(
    "\{workspace_root}/wiki/history/change-log.md",
    planbook_change_log_seed_markdown(),
  )
  write_text_file_if_missing(
    "\{workspace_root}/wiki/history/daily-engineering-digest.md",
    planbook_daily_engineering_digest_seed_markdown(),
  )
  write_text_file_if_missing(
    "\{workspace_root}/schemas/plan-record.schema.md",
    planbook_record_schema_markdown(),
  )
  write_text_file_if_missing(
    "\{workspace_root}/skills/code-plan/SKILL.md",
    code_plan_skill_markdown(),
  )
  write_text_file_if_missing(
    "\{workspace_root}/skills/code-review/SKILL.md",
    code_review_skill_markdown(),
  )
  write_text_file_if_missing(
    "\{workspace_root}/skills/doc-sync/SKILL.md",
    doc_sync_skill_markdown(),
  )
}

///|
fn planbook_change_log_seed_markdown() -> String {
  [
    "# PlanBook Change Log", "", "This log records live changes in the PlanBook-managed self-build system.",
    "", "## Seed", "", "- PlanBook workspace bootstrapped.",
  ].join("\n")
}

///|
fn planbook_daily_engineering_digest_seed_markdown() -> String {
  [
    "# Daily Engineering Digest", "", "This digest summarizes PlanBook self-build progress, validations, blockers, and commit readiness for overnight review.",
    "", "## Seed", "", "- No autonomy doctor run has refreshed this digest yet.",
  ].join("\n")
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
    "- `plans/2026-05-29-live-autonomy-spine/plan.md`",
    "- `plans/2026-05-29-book-quality-upgrade/plan.md`",
    "- `plans/2026-05-31-editor-mode-real-pipeline/plan.md`",
    "- `wiki/planning/quality-gates.md`",
    "- `wiki/planning/role-model.md`",
    "- `wiki/planning/operating-architecture.md`",
    "- `wiki/planning/execution-evidence.md`",
    "- `wiki/reviews/active-plan-review.md`",
    "- `wiki/history/decision-log.md`",
    "- `wiki/history/change-log.md`",
    "- `wiki/history/daily-engineering-digest.md`",
    "- `wiki/planning/implementation-backlog.md`",
    "- `wiki/planning/backlog-progress.md`",
    "- `wiki/planning/stop-policy.md`",
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
    "- MoonClaw workers are freelance bounded executors. They spawn for a job, write result/evidence/artifacts, then leave.",
    "- MoonBook bookkeepers are resident book roles. They are logically live through scheduled/event-driven keeper ticks and own what becomes memory.",
    "- Mayor owns town-wide routing and supervision; Bookkeepers own book-local memory decisions; Workers own bounded execution only.",
    "- Every registered book must have a book-scoped watcher slot. Standing-watch goals are book-local protocols and should self-heal capacity instead of deferring forever because an operational book lacks a watcher.",
    "- Buildings are protocol places. They aggregate, exchange, reduce, review, and distribute document packets; they are not generic agent containers.",
    "- Durable growth must be visible as changed books, ledgers, plans, code, tests, projections, or explicit no-change decisions.",
    "- Quality repair is allowed as review work, but the plan should aim to pass on the first implementation attempt.",
  ].join("\n")
}

///|
fn planbook_role_model_markdown() -> String {
  [
    "# Mayor, Bookkeeper, And Worker Role Model", "", "This page prevents future implementation plans from confusing durable memory ownership with temporary execution.",
    "", "## Mayor", "", "- Scope: town-wide.", "- Runtime: logically long-lived through the daemon and live autonomy spine.",
    "- Owns: standing goals, routing, scheduling, escalation, recovery, cross-book priority, and civic/building protocol dispatch.",
    "- Does not own: domain truth, book wiki contents, or low-level tool execution.",
    "", "## MoonBook Bookkeeper", "", "- Scope: one MoonBook workspace.", "- Runtime: resident role, logically live through scheduled/event-driven keeper ticks; it does not need to burn a hot process continuously.",
    "- Wakes on: new worker result, standing-watch update, review queue change, stale projection interval, explicit operator/book request, or memory-health check.",
    "- Owns: working memory, durable wiki promotion, source/evidence ledgers, review policy, generated site/projection quality, next questions, and book health.",
    "- Does not own: town-global routing or arbitrary tool-heavy execution.", "",
    "## MoonClaw Worker", "", "- Scope: one bounded task.", "- Runtime: freelance executor. Spawn when needed, execute the packet, emit structured result/evidence/artifacts, then exit.",
    "- Owns: tool use, observations, synthesis, coding, review, image generation, result packaging, and memory candidates.",
    "- Does not own: durable memory, wiki promotion, standing-goal cadence, or cross-book policy.",
    "", "## Rule", "", "A future plan should specify whether it needs Mayor supervision, Bookkeeper memory work, or freelance Worker execution. If the answer is unclear, update this PlanBook before coding.",
  ].join("\n")
}

///|
fn planbook_operating_architecture_markdown() -> String {
  [
    "# Operating Architecture", "", "This page is the PlanBook-local contract for keeping Moontown coherent while it runs and changes itself.",
    "", "## Core Doctrine", "", "- Durable state lives in MoonBook documents, ledgers, schemas, plans, reviews, and generated projections.",
    "- Active behavior is a protocol over those documents.", "- Buildings are protocol places: they accept packets, aggregate context, coordinate exchange, reduce outputs, run review gates, and distribute results home.",
    "- MoonClaw workers are temporary freelance executors. They do bounded tool-heavy work and return structured output.",
    "- Bookkeepers are resident MoonBook roles. They wake on schedules/events to decide what becomes memory and what needs review.",
    "- The Mayor owns town-wide cadence, routing, health, escalation, and cross-book priority.",
    "- Every registered book owns a watcher lane so standing goals can always be routed to the target book before any domain-specific worker is required.",
    "", "## Runtime Spine", "", "```text", "operator goal / standing goal / civic schedule / planbook gap",
    "  -> Mayor routes and schedules", "  -> target MoonBook or building protocol hydrates durable context",
    "  -> MoonClaw worker executes one bounded packet", "  -> MoonBook bookkeeper reviews memory, wiki, ledgers, projections",
    "  -> Moontown records town-level ledger, health, visual state, and next action",
    "```", "", "## Growth Contract", "", "The town is considered alive only when at least one of these changes over time:",
    "", "- research/course/plan/cookbook/civic books gain accepted pages, review items, or explicit no-change decisions",
    "- civic protocol ledgers gain inbox, contribution, reduction, outbox, review, or return-home records",
    "- PlanBook backlog items become plans, patches, validation evidence, or blockers",
    "- code changes land through the PlanBook repair loop with tests, diff hygiene, and commit readiness",
    "- UI projections refresh from runtime state rather than hand-authored demo text",
    "", "Operational activity alone is not growth. Retries, regenerated sites, no-change ticks, and logs must be accounted separately from domain knowledge or implementation progress.",
    "", "## Stable Watch State", "", "The desired mature state is healthy watching, not permanent motion: daemon healthy, active workers zero, unresolved failures zero, PlanBook open gaps zero, due standing goals zero, civic schedules enabled for the next interval, and review queues visible without being counted as accepted progress.",
    "", "Routine review-gated artifacts do not block the live loop by themselves. They stay visible for bookkeeper/operator/AI-review judgment while the Mayor continues scheduled watches and civic protocol rounds.",
    "", "## Civic Wiring Rule", "", "Every civic building must have a document protocol pack with an inbox, ledger, reducer contract, review gate, distribution policy, and return-home rule. New ideas are not complete until they are sent back to the owning MoonBook or explicitly parked in a review queue.",
    "", "## PlanBook Rule", "", "Future code work should come from a PlanBook plan or backlog item. If the daemon finds that the requested work is already done, it updates the plan/backlog/progress evidence instead of creating code churn.",
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
    "| `2026-05-29-live-autonomy-spine/plan.md` | top-priority | Moontown Mayor + MoonBook + MoonClaw | connects daemon, workers, accepted outputs, journal, projection, and operator UI |",
    "| `2026-05-31-editor-mode-real-pipeline/plan.md` | self-build-test | Moontown PlanBook + MoonClaw | turns Wenyu editor-mode guidance into a real plan-to-code pipeline |",
    "| `2026-05-29-book-quality-upgrade/plan.md` | active-review | Moontown + MoonBook | separates structural readiness from semantic quality and formalizes planbook/cookbook/course/civic workspaces |",
    "", "Planbook rule: update the existing plan and evidence pages instead of creating noisy `v1`, `v2`, `v3` copies.",
  ].join("\n")
}

///|
fn planbook_editor_pipeline_plan_markdown() -> String {
  [
    "# Plan: Editor Mode Real Pipeline", "", "## Source", "", "- Course book: `course-wenyu-game-design`.",
    "- Course page: `wiki/course/beginner-course.md`.", "- Relevant lessons: map labeling, roads before buildings, buildings as protocols, and mode separation.",
    "", "## Problem", "", "Wenyu editor mode is currently a useful validation surface, but it is not yet a complete town-owned implementation pipeline. A designer can inspect modules, runtime bindings, Moondesk handoff artifacts, and output coverage, but the editor does not create a durable PlanBook goal, dispatch bounded MoonClaw implementation work, track repair evidence, and expose final output readiness as one connected lifecycle.",
    "", "## Goal", "", "- Treat editor mode changes as plan-first town work.", "- Use the course book as teaching/source context, not as hardcoded UI logic.",
    "- Let PlanBook store the plan, acceptance criteria, evidence, and review state.",
    "- Let MoonClaw execute bounded code/docs changes from the PlanBook packet.",
    "- Let the UI show editor pipeline status from runtime state rather than static copy.",
    "- Keep Moondesk focused on detailed human workspace/file editing and portable artifacts.",
    "", "## Ownership", "", "- Moontown owns the editor-pipeline contract, command surface, runtime state, and operator UI binding.",
    "- PlanBook owns the durable plan, acceptance gates, repair packet, execution evidence, and review notes.",
    "- MoonBook owns the course book content and any generated course projection.",
    "- MoonClaw owns bounded implementation execution and structured result packaging.",
    "- Moondesk later owns rich human editing of individual files, prompts, and single-agent workspaces.",
    "", "## Implementation Shape", "", "1. Add a restartable editor-pipeline state contract under `.moontown/editor-pipeline.json` or equivalent.",
    "2. Add a Moontown command that refreshes/renders that state and references the PlanBook plan.",
    "3. Connect editor-mode UI to the contract so it shows source course, current plan, dispatch status, validation status, and output readiness.",
    "4. Ensure a bounded PlanBook repair packet can dispatch the missing implementation work through MoonClaw.",
    "5. Record validation evidence before claiming the pipeline is accepted.", "",
    "## Acceptance Criteria", "", "- [ ] A command can refresh/render editor-pipeline status without manually editing UI data.",
    "- [ ] The status links the Wenyu course book, this PlanBook plan, the current repair task, and final output mode.",
    "- [ ] Editor mode shows pipeline status from runtime state, not static prose.",
    "- [ ] A PlanBook repair dispatch can implement or repair this pipeline through MoonClaw.",
    "- [ ] Validation records command/test output in PlanBook evidence.", "- [ ] The output mode can explain whether a change is planned, running, accepted, blocked, or ready to export.",
  ].join("\n")
}

///|
fn planbook_live_autonomy_plan_markdown() -> String {
  [
    "# Plan: Live Autonomy Spine", "", "## Priority", "", "Top priority. The town already has daemon, watchers, MoonBook workspaces, MoonClaw execution, civic protocols, and UI projection. The missing work is the connective spine that makes those components behave as one live autonomous town.",
    "", "## Problem", "", "Runtime state is spread across daemon files, watcher ledgers, MoonBook outputs, civic protocol ledgers, and visual projections. The UI can show pieces, but there is no single accepted lifecycle artifact that says what is working, what changed, what is only no-change activity, what needs review, and what the Mayor should do next.",
    "", "## Goal", "", "- Maintain `.moontown/live-autonomy.json` as the current town spine.",
    "- Append `.moontown/town-journal.jsonl` on each daemon tick or manual refresh.",
    "- Refresh `visual-projection.json` from real task/worker/protocol state during daemon ticks.",
    "- Classify town activity into working, watching, or needs-recovery; keep review queues visible without letting routine review block the watch loop.",
    "- Separate accepted updates, no-change cycles, failed cycles, and review-gated outputs.",
    "- Make cookbook treat the live spine and journal as stable runtime artifacts.",
    "", "## Ownership", "", "- Moontown Mayor owns the spine, scheduling, retry, projection, and journal.",
    "- MoonBook owns accepted durable records and support workspaces.", "- MoonClaw owns worker execution and structured result packets.",
    "- Moondesk later owns human browsing/editing of the cookbook and workspace files.",
    "", "## Acceptance Criteria", "", "- [x] `moon run cmd/main -- live refresh` writes `.moontown/live-autonomy.json`.",
    "- [x] `moon run cmd/main -- live status` renders the current spine.", "- [x] Daemon tick refreshes `visual-projection.json` and live autonomy state.",
    "- [x] The spine records active workers, reviews, blocked work, accepted updates, no-change cycles, due goals, and next actions.",
    "- [x] Cookbook tracks the live spine and journal as runtime-state artifacts.",
    "- [ ] UI consumes the live spine directly for the operator message panel.",
    "- [ ] Every MoonClaw result writes a strict accepted/no-change/review/blocked contract before projection.",
    "", "## Validation", "", "- `moon run cmd/main -- live refresh`", "- `moon run cmd/main -- live status`",
    "- `moon run cmd/main -- daemon run --once`", "- `moon check --no-render`", "- `moon test`",
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
    "- Goal and non-goals", "- Operating architecture fit", "- Design decision",
    "- Alternatives considered", "- Affected files and packages", "- Implementation steps",
    "- Acceptance criteria with checkboxes", "- Validation commands", "- Growth and monitoring evidence",
    "- Rollback/recovery path", "- Follow-up tasks", "", "## Architecture Rules",
    "", "- State which durable document/book/ledger owns the truth.", "- State whether the active protocol is Mayor supervision, MoonBook bookkeeper work, MoonClaw worker execution, civic building exchange, or Moondesk human workspace.",
    "- Treat civic buildings as protocol places, not generic agent containers.",
    "- Treat MoonClaw workers as freelance bounded executors, not durable memory owners.",
    "- Treat MoonBook bookkeepers as resident roles that wake on schedules/events and decide memory promotion, review, and projection quality.",
    "- Include how accepted output returns home to the owning book or review queue.",
    "", "## Quality Bar", "", "- Be specific to this repo and this runtime.", "- Avoid generic advice.",
    "- Explain ownership boundaries.", "- Make the plan small enough to execute, but complete enough to resume.",
    "- Say what should grow over time: book pages, protocol ledgers, PlanBook evidence, code/tests, UI projections, or explicit no-change records.",
    "", "## Concrete Example", "", "```md", "# Plan: Add Book Quality Audit", "Problem: registered books can drift without a durable score.",
    "Operating architecture fit: PlanBook owns the change plan; Moontown runs the audit; MoonClaw may review; MoonBook stores review evidence.",
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
    "    {\"label\":\"Seed plans\",\"value\":\"3\",\"note\":\"quality governance, live autonomy spine, and editor pipeline\",\"tone\":\"healthy\"},",
    "    {\"label\":\"Skills\",\"value\":\"3\",\"note\":\"plan, review, doc sync\",\"tone\":\"healthy\"}",
    "  ],",
    "  \"readiness\": [",
    "    {\"title\":\"Planbook contract\",\"detail\":\"raw/bootstrap/PLANBOOK_CONTRACT.md\",\"meta\":\"Ready\"},",
    "    {\"title\":\"Top priority live spine\",\"detail\":\"plans/2026-05-29-live-autonomy-spine/plan.md\",\"meta\":\"Top Priority\"},",
    "    {\"title\":\"Editor pipeline self-build test\",\"detail\":\"plans/2026-05-31-editor-mode-real-pipeline/plan.md\",\"meta\":\"Self Build\"},",
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
