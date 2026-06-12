# Architecture

`moontown` is designed as the top layer of a three-part system:

```text
moontown -> moonbook -> moonclaw
```

The Wenyu Valley product plan is tracked separately in
[WENYU_VALLEY_PRD.md](/Users/kq/Workspace/moontown/docs/WENYU_VALLEY_PRD.md).
That document defines the programmable roadmap for turning the current town
prototype into a MoonBook/MoonClaw-backed civic AI town.

The civic-building protocol correction is tracked in
[WENYU_BUILDING_PROTOCOL_PLAN.md](/Users/kq/Workspace/moontown/docs/WENYU_BUILDING_PROTOCOL_PLAN.md).
That document defines the next architecture step: each Wenyu building should
act as an AI-mediated protocol place for aggregation, exchange, reduction, and
distribution, not merely as a research book or static UI card.

The document/book-first doctrine is tracked in
[DOCUMENT_PROTOCOL_PHILOSOPHY.md](/Users/kq/Workspace/moontown/docs/DOCUMENT_PROTOCOL_PHILOSOPHY.md).
The core rule is: durable state lives in documents/books, active behavior is a
protocol over those documents, agents are temporary workers, and buildings are
protocol places. This rule should guide future PlanBook self-build work and
prevent agent runs from becoming hidden source of truth.

For Wenyu civic modules, “book” is not the primary abstraction. The primary
abstraction is a building protocol with typed inboxes, ledgers, review gates,
and distribution policies. A MoonBook may support that building as durable
memory, but the support mode differs by building: workspace-backed,
ledger-backed, projection-backed, handoff-ledger-backed, or mixed-memory-backed.

For generated tools, the durable abstraction is an App ToolBook: a MoonBook
that owns accepted data, analysis reports, tool source, tool manifest,
generated web pages, and review state. Moontown may expose that tool from a
civic building, but Moontown should not become the tool source owner. Moondesk
edits the book config/spec, MoonClaw performs bounded watch/analyze/build work,
MoonBook persists the result, and Moontown links to it.

The implementation refactor plan is tracked in
[REFACTOR_PLAN.md](/Users/kq/Workspace/moontown/docs/REFACTOR_PLAN.md). That
document is the source of truth for splitting the current working prototype
into stable package boundaries without changing behavior first.

The stable-state cookbook is tracked in
[COOKBOOK.md](/Users/kq/Workspace/moontown/docs/COOKBOOK.md). The cookbook is a
MoonBook-generated control book that indexes canonical docs, machine-readable
definitions, and restart-readable runtime state. Moondesk should manage the
human desktop surface for that cookbook; Moontown consumes its manifest for
stable-state checks and drift review.

## Canonical Operating Architecture

The system should be understood as a live document/protocol machine, not a pile
of agents:

```text
documents/books/ledgers
  -> protocol places and schedules
  -> temporary worker execution
  -> bookkeeper memory/review/projection
  -> mayor supervision and next action
  -> updated documents/books/ledgers
```

The non-negotiable boundaries are:

- Durable truth lives in MoonBook documents, ledgers, schemas, review queues,
  plans, cookbook entries, and generated projections.
- Active behavior is a protocol over those durable artifacts.
- Wenyu buildings are protocol places. They aggregate packets, let participants
  exchange information, reduce outputs, run review gates, and distribute results
  back to the right homes.
- The Mayor is a town-level supervisor. It owns cadence, routing, health,
  escalation, cross-book priority, and operator-visible next actions.
- MoonBook bookkeepers are resident book roles. They wake on schedules/events
  and decide what becomes memory, what is rejected, what needs review, and what
  gets projected.
- MoonClaw workers are freelance bounded executors. They spawn for one packet,
  use tools, produce structured results/artifacts/memory candidates, and leave.
- Moondesk is the future human desktop over books/files; it should not become
  the town supervisor or worker runtime.

Growth must be visible and accountable. A live town should grow through changed
MoonBook pages, civic protocol ledgers, PlanBook plans/evidence, code/tests,
projections, or explicit no-change decisions. Retries, regenerated sites,
daemon logs, and operational journals are useful telemetry, but they must not
inflate domain knowledge or implementation progress.

## Core Book Policy Loop

The long-term architecture has one fundamental loop:

```text
for each book:
  read its policy
  execute its skills
  record results
  evaluate health
```

The policy is the durable contract for a book. It says which skills run, which
files prove the book is real, what quality means, and which output surface the
book owns. The implementation now has a first-class `policy` package:

- [policy/book_policy.mbt](/Users/kq/Workspace/moontown/src/policy/book_policy.mbt)
  owns the typed `BookPolicy`, skill, file, quality, and output model.
- [policy/book_policy_paths.mbt](/Users/kq/Workspace/moontown/src/policy/book_policy_paths.mbt)
  owns default policy projection paths and output surface names, including the
  generated-site projection path used by composed archetypes.
- [policy/book_policy_lanes.mbt](/Users/kq/Workspace/moontown/src/policy/book_policy_lanes.mbt)
  owns the canonical loop lane model: `control`, `execute`, and `tend`.
  `BookPolicy` still serializes lane fields as strings for stable JSON
  contracts, but lane parsing, normalization, and lane-based skill selection
  now pass through this typed boundary instead of ad hoc string comparisons.
- [policy/book_policy_archetypes.mbt](/Users/kq/Workspace/moontown/src/policy/book_policy_archetypes.mbt)
  owns reusable policy presets.
- [policy/book_policy_capabilities.mbt](/Users/kq/Workspace/moontown/src/policy/book_policy_capabilities.mbt)
  owns reusable policy capability composition.
- [policy/book_policy_health.mbt](/Users/kq/Workspace/moontown/src/policy/book_policy_health.mbt)
  owns policy-level health evaluation.
- [policy/book_policy_loop.mbt](/Users/kq/Workspace/moontown/src/policy/book_policy_loop.mbt)
  owns the first-class loop plan: read policy, run execute-lane skills, record
  results, run tend-lane skills, and evaluate health. Downstream packages
  should call `@policy.loop_plan(...)` or embed `@policy.loop_markdown(...)`
  instead of reconstructing the loop order in prompts, reviews, or status pages.
- [policy/book_policy_distance.mbt](/Users/kq/Workspace/moontown/src/policy/book_policy_distance.mbt)
  owns the typed internal-distance plan: information, recognition, and
  decisiveness. It derives the growth-vector view from the composed policy
  without changing the persisted `BookPolicy` JSON schema.
- [book_quality/taxonomy.mbt](/Users/kq/Workspace/moontown/src/book_quality/taxonomy.mbt)
  owns legacy book-quality labels such as research/course/civic while the
  migration away from runtime categories continues.
- [book_quality/policy_specs.mbt](/Users/kq/Workspace/moontown/src/book_quality/policy_specs.mbt)
  maps those legacy labels into composed `BookPolicy` values and repair
  actions.
- [book_quality/skill_quality.mbt](/Users/kq/Workspace/moontown/src/skill_quality/contract.mbt)
  owns the shared exploration quality contract used by generated skills: depth,
  breadth, new questions, new directions, curiosity, judgment, long-horizon
  memory, and auditable progress.
- [book_templates/types.mbt](/Users/kq/Workspace/moontown/src/book_templates/types.mbt)
  owns book-template registry, registry-file manifest, request, request-ledger,
  event, status, process-result, and processing-outcome DTOs.
- [book_templates/registry_policy.mbt](/Users/kq/Workspace/moontown/src/book_templates/registry_policy.mbt)
  owns registry readiness construction, descriptor filesystem check-path
  expansion, and registry Markdown rendering. Root may observe missing files,
  but it should not decide what a ready registry means, which descriptor paths
  prove a template exists, or assemble the operator-facing registry page.
- [book_templates/installer_policy.mbt](/Users/kq/Workspace/moontown/src/book_templates/installer_policy.mbt)
  owns unsupported/unknown template installer outcome wording. Root may dispatch
  concrete installers, but it should not phrase installer availability failures.
- [book_templates/request_policy.mbt](/Users/kq/Workspace/moontown/src/book_templates/request_policy.mbt)
  owns request lifecycle counting, retry-as-pending runtime accounting,
  lifecycle status vocabulary and predicates, install-success marker/classification,
  post-install request-state transitions, terminal-event reconcile gating,
  request-status construction/readiness/summary wording, empty request-status
  shape, request inbox Markdown rendering, request-event identity/DTO
  construction, request-event summary wording, request-event JSONL text
  normalization/append format, request-event line parsing/latest-summary/
  request-id extraction, process-summary wording,
  process-result construction, processed/reconciled outcome aggregation, and
  request-relative path resolution.
- [book_templates/request_paths.mbt](/Users/kq/Workspace/moontown/src/book_templates/request_paths.mbt)
  owns canonical book-template registry, request inbox, and request-event file
  names plus path derivation from observed snapshot/request paths. Root may
  supply the current snapshot path, but it should not duplicate those filenames
  or keep root-local default path shim functions.
- [book_templates/](/Users/kq/Workspace/moontown/src/book_templates)
  also owns concrete template runtime dispatch, request processing, request
  reconciliation, request status rendering, registry rendering, and installer
  dispatch. Root Moontown may expose CLI-compatible wrapper functions, but it
  should not keep template lifecycle code in the root package.
- [app_tool_book/contracts.mbt](/Users/kq/Workspace/moontown/src/app_tool_book/contracts.mbt)
  owns App ToolBook defaults, required workspace paths, template-copy path
  policy, config/manifest schema construction, catalog-identity-aware config
  construction, and readiness-gate construction for books with generated web
  tool surfaces. It owns the generated tool page path, but delegates the
  default generated-site index path to `policy.default_generated_site_projection_path()`.
- [app_tool_book/catalog.mbt](/Users/kq/Workspace/moontown/src/app_tool_book/catalog.mbt)
  owns the App ToolBook catalog name, tags, and skill list. Root may adapt
  those fields into a MoonBook catalog entry, but it must not fork ToolBook
  identity.
- [app_tool_book/rendering.mbt](/Users/kq/Workspace/moontown/src/app_tool_book/rendering.mbt)
  owns the App ToolBook bootstrap/install summaries, history, generated site
  index, and tool-page rendering contracts. Root may write those pages and
  return those summaries, but it must not redefine their canonical shape.
- [app_tool_book/status_rendering.mbt](/Users/kq/Workspace/moontown/src/app_tool_book/status_rendering.mbt)
  owns the operator-facing App ToolBook status Markdown. Root may inspect
  filesystem/catalog/standing-goal state, but it should not format status
  independently.
- [app_tool_book/standing_watch.mbt](/Users/kq/Workspace/moontown/src/app_tool_book/standing_watch.mbt)
  owns the App ToolBook standing-watch goal id, prompt language, `StandingGoal`
  construction policy, and goal-list membership/enabled checks. Root may
  persist those goals, but it must not fork the loop instructions or goal
  semantics.
- [app_tool_book/](/Users/kq/Workspace/moontown/src/app_tool_book)
  owns App ToolBook bootstrap, config installation, workspace materialization,
  status inspection, and status rendering. Root Moontown may keep wrapper
  functions for existing commands, but generated-tool book behavior belongs in
  this package.
- [pdf_evidence_watch/](/Users/kq/Workspace/moontown/src/pdf_evidence_watch)
  owns PDF Evidence Watch bootstrap, config installation, workspace
  materialization, standing-watch goal construction, and status inspection.
  Root Moontown may coordinate archive lifecycle events because archiving spans
  catalog state, standing-goal state, and book-template request-event logs.
- [visual_projection/](/Users/kq/Workspace/moontown/src/visual_projection)
  owns town-state-to-visual-projection DTOs and derivation: agent phases,
  routing, behavior/effect labels, building activity summaries, module
  projection rows, grid placement, and projection persistence. Root Moontown may
  expose compatibility wrappers and provide test fixtures, but visual semantics
  should not live in the root package.
- [support/](/Users/kq/Workspace/moontown/src/support)
  owns generic support helpers for file I/O, JSON string/object extraction,
  Markdown shaping, HTML escaping, text-label formatting, and nested runtime
  config JSON upserts. Root Moontown may keep private compatibility wrappers,
  but generic utility implementation should not be scattered across the root
  package.
- [research_quality/](/Users/kq/Workspace/moontown/src/research_quality)
  owns research-readiness DTOs and quality-gate semantics: required research
  artifacts, source-depth checks, topic matching, deep-report structure/length
  checks, wiki materialization checks, generated-site specificity checks, and
  process-noise rejection. It also owns the generic research bootstrap ingest
  task contract: title, prompt clauses, target pages, review requirement, and
  worker role. It owns the `raw/bootstrap/QUALITY_REPAIR.md` trigger/resolution
  file contract used for in-place research repair. It also owns research
  bootstrap artifact reading and the persistence payload that turns those
  artifacts into MoonBook summaries, artifact paths, and durable memory
  candidates. Research quality also owns quality-gate summary suffixes and
  recovery/review event wording. Root Moontown may mutate town executions when a
  gate fails, decide when to schedule bootstrap or repair, dispatch persistence
  through this package, and apply review/recovery state transitions, but it
  should call this package for the actual quality judgment, bootstrap research
  contract, repair-trigger path, repair-trigger wording, research persistence
  semantics, and quality-gate/recovery messages.
  Generated-site quality checks consume `policy.default_generated_site_projection_path()`
  for the default projection path instead of redefining it locally.
- [course_book/](/Users/kq/Workspace/moontown/src/course_book)
  owns the Wenyu game-design course book: catalog entry construction,
  workspace materialization, course contract/outline/exercises/rubric text,
  course-builder skill text, generated course UI state, and generated course
  site HTML. Root Moontown may keep CLI-compatible wrappers, but course content
  and projection semantics should not live in the root package.
- [moonclaw_runtime/](/Users/kq/Workspace/moontown/src/moonclaw_runtime)
  owns Moontown-side MoonClaw runtime helpers: no-input metadata flags,
  execution/step metadata maps, run result payload lookup, and MoonClaw job
  store compaction. Root Moontown may expose command-compatible wrappers, but
  MoonClaw runtime maintenance details should not live as loose root files.
- [cookbook/](/Users/kq/Workspace/moontown/src/cookbook)
  owns Cookbook DTOs, stable-state artifact summary accounting, and the
  operator-facing Cookbook status Markdown. Root Moontown may discover artifact
  existence, register the MoonBook workspace, write files, and call MoonBook
  catalog APIs, but it should not redefine docs/definition/runtime-state counts,
  required-missing drift semantics, or Cookbook status wording locally. Cookbook
  generated-site writes consume `policy.default_generated_site_projection_path()`
  for the default projection path instead of redefining it locally.
- [planbook/](/Users/kq/Workspace/moontown/src/planbook)
  owns PlanBook static content: contract pages, governance pages, role model,
  operating architecture, seed plans, generated-site templates, and PlanBook
  skill templates. Root Moontown may bootstrap/update the workspace and dispatch
  PlanBook repair/autonomy runtime work, but it should not keep root-local
  copies of durable PlanBook prose, generated-site markup, or skill text.
- [standing_watch_policy/](/Users/kq/Workspace/moontown/src/standing_watch_policy)
  owns the generic standing-watch `BookTask` contract: task kind, task id
  derivation, compact id segment formatting, target page set, prompt text,
  strict accounting markers, marker parsing, MoonBook standing-watch history
  block parsing, provider-decision collapse policy, material-delta metrics, and
  book-quality repair appendix composition. It also owns keeper auto-triage and
  recovery closure policy: whether no-change/update markers satisfy a goal
  threshold, how terminal markers supersede failed transport status, and the
  accepted keeper metadata appended to execution summaries. Root may decide
  when a standing goal is due, route it through the Mayor, persist snapshots,
  read/write MoonBook history files, apply package-owned reconciliation
  decisions to `TownState`, and append watcher ledgers, but it must not redefine
  the standing-watch prompt, marker vocabulary/parser, history parser/collapse
  semantics, material-delta accounting, task kind, id format, keeper closure
  thresholds, or auto-triage/recovery summary wording locally.

The root package must not re-export every policy constructor. Root systems may
map legacy book labels into a `BookPolicy` while migration continues, but new
code should import `vectie/moontown/policy` directly.

Book types such as research, course, PlanBook, Cookbook, civic support, and
operational memory are no longer the intended runtime foundation. They are
policy presets: convenient constructors that combine skill lanes, required
files, quality criteria, and output contracts. Future work should compose or
override policies instead of adding more hardcoded type branches.

Policy extension should use pure capability constructors. For example:

- `with_pdf_watch(...)` adds PDF discovery/extraction skills and PDF evidence
  files to any base policy.
- `with_web_tool_surface(...)` turns any book policy into a book-owned usable
  web tool surface with its own manifest, source, review skill, and output
  contract.
- `with_standing_watch(...)` adds the recurring watch loop without forcing the
  book to become a research book.

These functions are intentionally not separate book types. They are policy
composition tools, so a future book can be a course with a tool surface, a
research book with PDF watch, or a civic support book with standing watch
without adding more runtime categories.

Default output paths are also policy-owned. Packages such as `book_quality/`
may expose compatibility helpers like `generated_site_path()`, but those should
delegate to `policy.default_generated_site_projection_path()` rather than
redefining the path locally.
Adapters may still detect legacy external layouts for compatibility. For
example, the MoonBook adapter can discover older site output locations after a
build, but its canonical Moontown generated-site path must delegate to the
policy default.

Every policy has two lanes:

- `execute`: the fast lane. It runs known procedures such as standing watch,
  source diarization, protocol rounds, course projection, or repair dispatch.
- `tend`: the slow lane. It reflects on output quality, audits claims, revises
  synthesis, reviews architecture fit, and decides whether the book is learning
  the right way over time.

The policy loop should also cultivate three internal distances:

- information: discover what is unknown
- recognition: decide what matters
- decisiveness: act when confidence, urgency, and safety allow action

These distances are not a separate book type or a third runtime lane. They are
a policy-owned derived view in
[policy/book_policy_distance.mbt](/Users/kq/Workspace/moontown/src/policy/book_policy_distance.mbt):
execute-lane skills bridge information, tend-lane skills bridge recognition,
and the quality/output contract bridges decisiveness.

This is the current refactor direction. Existing book-quality orchestration
still lives mostly in the root package, but the legacy label-to-policy map,
catalog string/tag classification policy, path contract helpers, base workspace
scoring, per-path scoring, typed path-set scoring/wording, scoring/action primitives, public
audit/review DTOs, context-page selection, static scoring profile required-path
lists, research/course/civic/cookbook scoring signal thresholds and wording,
review packet/readme construction, review output contract, review skill
text, review-run ledger storage/lifecycle contracts, review result paths,
review-run construction, review reconciliation result contracts, review ledger
view/rendering contracts, repair bridge ledger/item schemas, and
structural/semantic assessment rules have moved to `book_quality/`. Root may
adapt MoonBook catalog entries into string/tag classifier calls, but it should
not own the meaning of archived/transient/cookbook/planbook/course/research/
civic/operational classification. AI review result parsing and repair-contract
interpretation also live there, so the meaning of fields such as `ai_quality_score`,
`repair_owner`, and `next_repair_task` is not duplicated in root orchestration.
Audit summary aggregation and audit Markdown rendering are package-owned too.
Review packets attach the composed `BookPolicy`, readiness uses policy-owned
health checks, semantic-review candidate ordering is package-owned too, and
book-quality review-status summary rendering is package-owned. Semantic review
profile policy is package-owned too: review profile id, execution target,
preferred skills, role-runtime envelope, MoonClaw jobs profile JSON, packet
step metadata, external packet request text, notes, tags, and review metadata
belong to `book_quality/`, while root only materializes those values into
MoonClaw profile/config files and resolves paths for external packets. The
semantic-review ACP target JSON shape is package-owned too; root may supply the
observed source root, resolved Codex command, args, and model, but it should not
define the `codex-main` target schema or reviewer label. Root
orchestration may pass observed directories, process facts, and audits into the
package, but it should not rebuild package policy from those observations. The
selection of the first pending semantic review, result-file filtering, the
meaning of "weaker candidate should be reviewed first", the summary shape of the
review ledger, and the active-run lifecycle decision from observed state belong
to `book_quality/`.

Codex ACP defaults belong to the `adapters/codex` package. PlanBook repair,
book-quality semantic review, and Wenyu source-build workers should not each
hard-code their own Codex model string. The adapter owns `model()`,
`command()`, `args()`, `moontown_args()`, reusable `codex-main` target JSON,
ACP target upsert, and the Moontown ACP target JSON.
Those builders must include `--model <model>` because MoonClaw's ACP runner
treats the `model` field as launch metadata/env, not as an automatic CLI
argument. The default is `gpt-5.5`, with `MOONTOWN_CODEX_ACP_MODEL` as the
operator override.
PlanBook source repair must use this adapter-owned `codex-main` target builder
instead of hand-assembling backend/label/cwd/workspace/command/args/model JSON
in root code.
Book-quality's package-owned semantic-review ACP config preserves the same
invariant by normalizing caller-provided Codex args: missing `--model` is
appended, and stale `--model <old>` is rewritten to match the config `model`.
Metadata-only model fields are not executable proof.

PlanBook self-repair policy belongs to the `planbook_policy/` package. That
package owns PlanBook autonomy DTOs, repair-task DTOs, required validation
commands, repair result contract ids, accepted/blocked/no-change decision
semantics, `planbook.repair.patch_receipt.v1` validation, and MoonClaw run
status bucket classification. It also owns the pure durable repair workspace
layout: `raw/repair/PLANBOOK_REPAIR_CONTEXT.md`, `raw/repair/repair-result.md`,
repair packet filenames, skill/plan page paths, result target pages, and
MoonClaw repair index paths. It owns the pure repair request task-rule wording
too: context loading, ownership handoff, exact-target-first edits, selected
editor-feature repair instructions, validation/diff/commit gates, stale-plan
handling, backlog completion, result writing, and satisfaction gating. It also
owns the generated `planbook-repair` skill text because that text defines the
worker contract, concrete example, accepted patch-receipt requirements, and
no-churn rules. Root
Moontown may resolve source roots, write PlanBook files, read MoonClaw run
indexes, dispatch ACP packets, and reconcile filesystem evidence, but it should
not redefine repair paths, repair request rules, repair decisions, validation
gates, receipt fields, generated repair skill text, or status bucket semantics
locally.
PlanBook generated-site writes follow the global output rule as well:
`planbook_runtime/` consumes `policy.default_generated_site_projection_path()`
for the default projection path instead of redefining it locally.

Wenyu build-pipeline task contracts belong to `build_pipeline/`. The package
owns Wenyu bootstrap ingest, implementation-backlog, code-patch, and asset-pack
task construction, including prompts, target pages, priorities, review flags,
worker roles, and fallback artifact materialization. It also owns the Wenyu
MoonClaw build-controller profile: output contract id, ACP execution/review
steps, preferred skills, no-input metadata, model metadata, and execute/review
prompt templates. `town_runtime/` may decide that a Wenyu book is ready for
bootstrap/build, pass the current repository root, and ask `build_pipeline/` to
install the profile, but it should not reconstruct those build tasks, Wenyu
bootstrap tasks, or MoonClaw profile contracts locally.

Live-autonomy policy belongs to the `live_autonomy_policy/` package. That
package owns the `LiveAutonomySpine` JSON contract, journal/probe DTOs, live
worker/execution counting, transient-infrastructure-debt recognition, autonomy
tick calculation, aggregate metric-count DTO/assembly, stable-waiting blocker
policy, next-action wording, status classification, and the canonical operator
Markdown renderer. It also owns canonical live-autonomy path derivation for the
spine, journal, digest, standing-goal mirror, and PlanBook history/digest pages.
Root Moontown may supply storage and PlanBook workspace defaults, read/write
snapshots, journals, digests,
watcher ledgers, and PlanBook counts, may inspect health reports, and may derive
latest watcher decisions from raw records, but it should not redefine what
"live", "stable waiting", "transient infrastructure debt", metric count shape,
live-autonomy file naming, or the autonomy status surface means locally.

Health anomaly semantics belong to the `health/` package. That package owns
anomaly detection and exact-title anomaly counting. Runtime-status and
live-autonomy code may consume a `HealthReport`, but they should not duplicate
how execution failures, stale runs, worker health, or other anomaly titles are
counted.

Runtime-status policy belongs to the `runtime_status_policy/` package. That
package owns the `TownRuntimeStatus` DTO, effective execution de-duplication,
execution lifecycle ranking, active/review execution-status set membership,
standing-goal runtime counts, empty-status shape, stable summary metric
language, and the reusable operator report renderer. Root Moontown and
live-autonomy code may load snapshot files, daemon state, watcher ledgers,
standing goals, and book-template request inboxes, may compute root-only daemon
health summary strings, and may plan scheduler actions from observed state, but
they should not redefine runtime status buckets, duplicate lifecycle ranking,
own active/review execution lists, or assemble operator status report text
locally.

Daemon-runtime policy belongs to the `daemon_runtime_policy/` package. That
package owns daemon runtime state/health DTOs, status-mode classification,
heartbeat/staleness rules, durable-worker/supervisor activity predicates,
doctor/start decision vocabulary, health labels, health summary field ordering,
pure daemon path derivation from snapshot paths, and pure runtime
transition-state builders. Root Moontown may supply storage defaults, inspect
PID liveness, read/write runtime files, write/remove PID files, clear
stop/restart request files, spawn or stop supervisor/worker processes, and
install launchd services, but it should not redefine what "running",
"supervising", "stale", "healthy", "already active", "worker started", "tick
finished", "reload requested", or canonical daemon file naming means.

Editor-pipeline policy text belongs to the `editor_pipeline/` package. The
package owns the editor pipeline DTOs, feature-selection result contract,
selected-feature implementation contract, editor feature-rater `SKILL.md` body,
canonical editor pipeline Markdown renderer, stage/status policy, and reusable
style metadata labels/asset references. It also owns reusable selected-style
lookup and selected-feature readiness gates for style comparison, movement-loop
evidence, placement diff preview, and terrain label mapping. Module placement
semantics also belong there: the package owns the `EditorPipelineModulePlacement`
DTO plus movement-loop records, placement-diff records, terrain layers, and
terrain-reason records. Root Moontown may inspect source/runtime state,
materialize PlanBook workspace files, dispatch MoonClaw packets, read/write
result files, compute evidence paths, choose output paths, and convert loaded
JSON config entries into package DTOs, but it should not redefine editor
pipeline record shapes, contract ids, rubric text, stage readiness decisions,
status Markdown sections, style selection policy, selected-feature readiness
gates, module placement policy, terrain labeling policy, or style catalog naming
locally. Root should also avoid compatibility shims over those package APIs;
callers should use `editor_pipeline/` directly.

Book-quality repair standing-goal semantics also belong there: repair goal id
prefix, id construction, id recognition, cadence, source policy, base prompt
language, `StandingGoal` construction, existing-goal refresh/upsert behavior,
repair-goal id filtering, disabled-state transition, standing-watch repair-mode
appendix, and generic empty repair-output classification are package-owned
policy. Root may iterate and persist the registry, append the package-provided
mode text to a watcher prompt, and combine package classifiers with observed
execution state, but it should not duplicate the repair-goal prefix, collect
repair goal ids locally, construct/refresh/disable repair standing goals
locally, or redefine what a book-quality repair loop asks for, when that loop
recurs, or which generic completion text still leaves a repair gap open.
Book-quality review dispatch status language is package-owned too; root may
decide that an active run blocks dispatch or that no pending review exists, but
the operator-facing review message contract should stay with the review domain.
Book-quality review status section and table rendering are package-owned as
well. Root may observe whether a result file exists and pass that state through
a display row, but headings, historical-attempt explanation, table headers, and
row formatting belong to `book_quality/`.
Book-quality stale-run reconciliation vocabulary is package-owned too. Root may
check process liveness and poll MoonClaw for a run summary, but the transition
to `orphaned`, retry-facing summary text, and timestamped review-run record
belong to `book_quality/`.
Accepted-result reconciliation records are package-owned too. Root may harvest
MoonClaw content and write the accepted result file, but the transition to
`written`, harvested summary text, written-count flag, and changed flag belong
to `book_quality/`. Ledger-level reconciliation aggregation is package-owned
as well: root may reconcile each run after filesystem/process observation, but
run order preservation, written-count accumulation, and changed-state folding
belong to the review domain package.
Book-quality repair-goal retirement policy is package-owned as well. Root may
observe whether a standing goal is enabled, which book it targets, whether a
score/result file exists, and whether a result score is semantically ready; the
decision vocabulary and "should retire" rule belong to `book_quality/`.
The predicate for whether a `BookQualityScore` set contains a book id is also
package-owned; root should not duplicate score-table semantics while deciding
retirement.
Book-quality repair bridge summary wording is package-owned too: root may
apply repair candidates and retire goals, but the meaning and language of
"queued", "refreshed", "no weak review", and "retired stale repair" belongs to
the book-quality domain package.
Book-quality repair review page Markdown is also package-owned. Root may write
`wiki/reviews/book-quality-repair.md`, but it should not define the page
sections, accounting rule, or review-contract presentation.
Book-quality repair bridge item construction is package-owned too. Root may
provide observed inputs such as score, result path, result text, parsed semantic
score, and current time, but it should not assemble the durable repair bridge
item schema, decide whether review text is weak enough to become a repair
candidate, or decide how AI review contract fields map into that schema.
Operational book bootstrap templates are package-owned too. The reusable index,
contract, review-policy, journey, operational-keeper skill,
`moonbook-ui-state.json`, and generated-site shell content belong to
`book_quality/`; root code may translate MoonBook catalog entries into title,
summary, focus, and workspace-root inputs and then write the resulting files,
but it must not redefine the template text or projection schema.
New systems should start from `BookPolicy` and
`@book_quality.*` contracts; legacy book-type checks should become package
adapters rather than root APIs. The root package may still perform filesystem
audits, evaluate file existence, read/write review files, dispatch MoonClaw
jobs, and bind repair bridge items to Mayor standing goals, but it must not own
semantic packet templates, static profile rules, assessment policy, review
result parsing, audit rendering, candidate filtering/ordering policy,
review-status summary policy, active-review counting/status policy,
stale/orphan review reconciliation policy, review result-state wording,
semantic-review profile policy, active-review lifecycle policy,
repair-goal prompt/cadence policy, review dispatch message policy, review-run
accepted-result storage, reconciliation record construction, ledger reconciliation aggregation,
repair-goal identity/prompt/cadence policy,
repair-goal retirement policy, repair bridge summary policy, or repair bridge
candidate/item construction, repair review page Markdown contracts, or book-quality data
schemas. It also must not own catalog classification rules beyond adapting
external MoonBook catalog records into package-owned classifier inputs.
The package also owns the pure transformation from a `BookQualityReviewPacket`
to the MoonClaw external proposal packet used for semantic review. Root may
choose when to dispatch that packet and where to store imported run state, but
it must not redefine packet id, title, profile, context-page expansion,
skill-path expansion, request text, tags, notes, or metadata.
It should call package path helpers such as `workspace_path`,
`wiki_index_path`, `projection_state_path`, and `generated_site_path` instead of
maintaining root-local wrappers for book-quality file contracts.
When root needs filesystem-backed typed-page scoring, it may compute the
missing relative paths, but the points calculation and strength/gap note wording
come from `book_quality.path_set_assessment`.
Likewise, root may observe whether the workspace, wiki index, projection state,
or a required relative path exists, but base workspace and per-path points plus
operator-facing note wording come from `book_quality` assessment helpers.
For book-type-specific scoring, root may pass observations such as deep-report
word count, course index text, latest civic result existence, or audit-file
existence, but the thresholds, points, and strength/gap wording belong to
`book_quality/`.
Book-template request semantics follow the same rule. Root may read and write
the request ledger, inspect the template registry file, invoke PDF/AppTool
installers, and append event logs, but it should not define the durable request
DTOs, registry readiness/output wording, descriptor check-path policy,
descriptor lookup semantics, count status buckets, decide that retry is pending
runtime work, or own
operator-facing process summary or request-inbox rendering language. It also
should not hard-code request status terms such as pending, retry, installed,
and failed when package predicates can express the decision, or format request
event identities, event DTOs, or event summaries locally. It should also not
normalize/append event JSONL text, parse event lines, or decide latest-event
fallback locally. It should not construct post-install request records, decide
terminal event backfill gates, count processed requests, count reconciled
terminal events, rebuild updated request ledgers, or construct empty inbox
status fields locally. It should also not duplicate canonical request inbox or
event-log filenames locally. It should call package path helpers directly
instead of re-exporting local path wrappers. It should also not phrase unknown-template or
registered-without-installer failures locally.
Installers must emit the
`book_templates/` success marker for installed state; request processing must
not infer success from human-readable installer prose. Those lifecycle
contracts belong to `book_templates/`.
App ToolBook semantics also follow this split. `app_tool_book/` owns the
ToolBook install/status DTOs, stable template root, default book id and purpose,
required paths, copied-template paths, config/manifest schemas,
catalog-identity-aware config construction, generated history/site/tool HTML
shape, status Markdown, catalog identity, standing-goal construction/list
semantics, and readiness rule, plus bootstrap/install summary wording. Generic
standing-watch task kind, prompt/id contract, target pages, accounting markers,
marker parsing, effective watcher-record decision selection, execution-summary
classification, ledger preference ordering, keeper closure policy, and
auto-triage/recovery summary wording belong to
`standing_watch_policy/`. Reusable transient external dependency vocabulary
belongs to `runtime_error_policy/`; standing-watch and recovery code may
consume that package, but root should not fork its own provider-infrastructure
classifier. Root may still load config JSON, copy template files, inspect
filesystem/catalog/goal state, write package-rendered pages, return
package-rendered summaries, adapt package identity into MoonBook catalog
entries, persist standing goals, and append watcher ledgers, but it should not
redefine what makes a ToolBook workspace real, how it appears in the catalog,
what its generated/status pages look like, how its watch loop is described, how
no-change/update/deferred/review decisions are inferred from MoonBook/MoonClaw
output, or which terminal watcher record is preferred. Root should also avoid
default/config/manifest compatibility shims; callers should use
`app_tool_book/`, `standing_watch_policy/`, and `runtime_error_policy/`
directly for those pure policy values.

## Layer Responsibilities

### `moontown`

`moontown` is the town-wide control plane.

It should own:

- global orchestration
- routing and isolation policy
- standing goals and daemon cadence
- health monitoring and recovery
- scheduling and patrol
- experiment control
- operator UI
- town-wide persistence
- cross-book research synthesis
- town-level acceptance and quality gates
- high-level civic runtime facade calls
- cookbook manifest consumption and drift checks

It should not become:

- the place where book-local memory lives
- the place where execution tooling lives
- a generic raw worker runtime
- the place where building-specific civic scenarios or reducers are hardcoded

### `moonbook`

`moonbook` is the per-domain harness layer.

It should own:

- workspace root and domain identity
- memory policy and durable memory
- context hydration
- local planning
- native book-type skills and profiles, including research, course, PlanBook,
  ToolBook/AppBook, and standing-watch workflows
- result review and persistence decisions
- generated cookbook workspace and stable-state wiki pages
- generated app/tool source and site projection for App ToolBooks

It should not become:

- the global scheduler
- the worker execution engine

### `moonclaw`

`moonclaw` is the underlying agent substrate.

It should own:

- role-specialized runtimes
- task execution
- tools and skills
- session state
- result packaging

It should not own:

- town policy
- book-local durable memory

## Embedded Role Model

The intended design is not “copy moonclaw into each repo”. It is “embed one
agent substrate behind strong role adapters”.

### Mayor

The town embeds a constrained moonclaw runtime as `Mayor`.

Current implementation lives in:

- [roles/mayor.mbt](/Users/kq/Workspace/moontown/src/roles/mayor.mbt)
- [adapters/moonclaw/import.mbt](/Users/kq/Workspace/moontown/src/adapters/moonclaw/import.mbt)

Current properties:

- planning layer: strategic
- runtime mode: planner-only
- tool access: limited
- memory scope: global
- delegates to keepers
- no direct workspace writes
- no execution tools by default

Town code should call:

- `Mayor.decide_dispatch(...)`
- `Mayor.patrol(...)`
- `Mayor.prepare_keeper_packet(...)`
- `Mayor.handoff_to_keeper(...)`

### Keeper

The book-local embedded moonclaw runtime is modeled as `keeper`.

Current shape:

- planning layer: domain
- runtime mode: planner-only
- memory scope: domain
- tools limited to book-local control surfaces

The keeper is a resident book role, not a freelance worker. It should be
logically live through scheduled or event-driven MoonBook keeper ticks:

- wake when a worker result arrives
- wake when standing-watch history changes
- wake when review queues or projections are stale
- wake when source/evidence ledgers need cleanup
- wake when an operator asks the book to act

The keeper owns book-local memory decisions: what stays as working memory, what
is promoted to durable wiki/source/evidence pages, what is rejected as
operational noise, what needs review, and what questions should be pursued next.
It should not hold town-global authority and should not run arbitrary
tool-heavy execution directly.

In the current repo, `moontown` now prepares real keeper proposal packets using
book-harness-shaped context from the moonbook adapter. The actual keeper
implementation still belongs on the `moonbook` side. MoonBook now provides a
native PlanBook skill plus `wiki_planbook_controller` and
`wiki_planbook_worker` extension profiles so code-planning books do not fall
back to research or course profiles.

### Worker

Execution claws remain separate from strategic/domain planning roles.

Current worker runtime metadata:

- planning layer: execution
- runtime mode: executor
- full tool access
- workspace memory scope
- task/result envelope boundary

Workers are freelance executors. They should spawn when a bounded packet needs
tool-heavy work, emit structured results/evidence/artifacts/memory candidates,
and then leave. They do not own durable memory, book wiki promotion,
standing-goal cadence, or cross-book policy.

Every registered book must still expose a book-scoped watcher lane. Built-in
operational books such as `coding` and `finance` can keep specialized harness,
review, or domain workers, but standing-watch goals are book-local protocols.
The Mayor therefore provisions `claw-<book-id>-watcher` for each registered
book so a standing goal does not become an endless deferred retry just because
the target book lacks a watcher slot.

## Data Ownership

The clean ownership rule is:

- if it is town-wide, it belongs to `moontown`
- if it is domain-specific and durable, it belongs to `moonbook`
- if it is task/session-specific, it belongs to `moonclaw`

Examples:

- `TownState`, `AssignmentPlan`, `TownEvent`, `TaskExecutionRecord`
  - `moontown`
- workspace root, memory records, domain summaries
  - `moonbook`
- tool traces, session state, execution logs
  - `moonclaw`

## Current Runtime Flow

### Bootstrap

```text
moonbook catalog
  -> BookProvider
  -> book task batch
  -> worker context bundle
  -> external proposal packet
  -> MoonClaw proposal import
  -> confirmed MoonClaw run
  -> terminal run polling
  -> MoonBook result persistence/build
  -> task execution records and seeded TownState
  -> persisted TownSnapshot
  -> dashboard/render/frontend
```

### Goal Run

```text
user goal
  -> Mayor.plan_goal(...)
  -> one or more isolated MoonBook lanes
  -> MoonBook accept/plan/context APIs
  -> Mayor.prepare_keeper_packet(...)
  -> MoonClaw import/run/poll lifecycle
  -> MoonBook persist/build/summary APIs
  -> mayor research quality gate
  -> town-level synthesis under .moontown/town-synthesis/
  -> persisted TownSnapshot
```

The key design rule is that Moontown can decide whether a lane is acceptable,
but it does not become the research engine. MoonBook owns the workspace and
durable wiki state. MoonClaw owns execution and tool use. Moontown owns
cross-book readiness, supervision, and operator-visible acceptance.

The town synthesis is intentionally cross-book rather than book-local. It
combines the lane outputs into an executive summary, integrated research
narrative, lane matrix, relationship model, evidence trail, comparative
findings, and maturity/gap section. The evidence trail points back to each
book's `raw/bootstrap/` research artifacts, including W-source and L-source
rows.

### Wenyu Civic Service Bootstrap

Wenyu civic modules use the same ownership rule as research lanes, but they are
configured as long-lived civic modules rather than one-off research topics. A
module can be an `agent-workspace`, `exchange-place`, `projection-surface`,
`gateway`, or `hybrid`; MoonBook is a durable support workspace only when that
module needs memory, wiki pages, review queues, or generated projections.

The stronger target model is building-as-protocol:

```text
input packets
  -> building inbox
  -> AI-guided aggregation
  -> building-specific exchange
  -> AI-guided reduction
  -> review/safety gate
  -> distribution to MoonBook, UI, agents, mayor, or external handoff
```

This is similar to map/reduce, but only the envelope, routing, ledgers,
channels, permissions, and review gates should be hardcoded. The building
skill pack should guide MoonClaw to choose the right reduction strategy for the
building's social responsibility.

Refactor rule: the daemon may run a scheduled civic communication-pattern job,
but it must not know the details of any building-specific scenario. Those
details belong in a scenario template, selected communication pattern, and
building skill rules, behind a civic protocol runtime boundary.
`research-salon` is one pattern, not the whole abstraction.

Reusable communication-pattern semantics are owned by the `civic/` package.
That package defines the `CivicCommunicationPattern` model, the pattern
registry, civic service-kind to pattern mapping, and reusable salon/scenario
DTOs such as `CivicSalonScenario`, `CivicSalonIdea`, `CivicSalonMetric`, and
`CivicSalonHomeReturn`, plus the structural effectiveness calculation that
turns participant and idea packets into metrics. It also owns
`CivicSalonSchedule`, `CivicSalonRoundRecord`, and pure schedule transition
semantics. Scenario pattern resolution, pattern-label fallback, generic
building-protocol derivation, and reusable salon protocol notes live in
`civic/salon_scenario_policy.mbt`; root may pass scenario templates into those
functions, but it must not rebuild those protocol contracts manually. Civic
service skill text, module-specific skill text, salon participant skill text,
and salon reducer skill/contract/input text live in `civic/skill_text.mbt`;
root may write those files into MoonBook workspaces, but it must not assemble
the skill contracts itself. Civic workspace seed text is package-owned too:
workspace index pages, service contracts, building protocol contracts, schema
pages, wiki seed pages, review queue pages, service ledgers, exchange ledgers,
and history pages live in `civic/workspace_text.mbt`; root may choose paths and
write those generated files, but it must not rebuild their civic semantics
locally. Civic service and protocol status labels are also civic-owned:
status buckets, readiness decisions, result-proven checks, and health-note
wording live in `civic/status_labels.mbt`. Civic service reconciliation policy
is package-owned too: the decision vocabulary, page/review accounting,
result-current checks, reconcilable-work gate, result-contract block, and
reconciliation narrative live in `civic/service_reconcile_policy.mbt`. Root
Moontown files may render the registry, materialize scenario workspaces,
dispatch runtime packets, inspect book files, turn health observations into
package policy inputs, persist MoonBook results, and persist schedules/round
ledgers, but they must not own the
reusable pattern taxonomy, scenario record shapes, metric semantics, schedule
vocabulary, status vocabulary, or civic service result-contract wording.
MoonBook persistence payloads for civic service executions are runtime-owned by
`civic_runtime/`: service-result summaries, artifact lists, memory candidates,
review-candidate routing, execution detection, and civic target-page trimming
belong there. Root may ask for those payloads when a service execution is
persisted, but it must not reconstruct civic persistence summaries or memory
candidate targets locally.
Building-protocol portfolio semantics are package-owned too: ready/active/
review/blocked bucket predicates, portfolio count construction, and compact
Markdown row rendering live in `civic/protocol_portfolio.mbt`. Root may write
status files and higher-level section headers, but it should not duplicate those
bucket or row-format rules. Building protocol contract Markdown is package-
owned in `civic/protocol_contract_text.mbt`; root may write the generated file
beside protocol ledgers, but it should not assemble reusable protocol contract
text locally.
Building-protocol snapshot construction is package-owned as well. Root may
count JSONL ledger records and read latest summaries, but
`civic/protocol_snapshot.mbt` owns how those observations combine with a
`BuildingProtocolDefinition` into `BuildingProtocolSnapshot`, including status
and readiness derivation.

```text
civic service registry
  -> module mode + dedicated skill mode
  -> canonical wenyu-* support MoonBook catalog entries
  -> civic workspace seeds
  -> module schemas, wiki pages, review queues
  -> generic and module-specific MoonClaw skills
  -> book/moonbook-ui-state.json
  -> viewport module projection
```

Current implementation lives in:

- [civic/services.mbt](/Users/kq/Workspace/moontown/src/civic/services.mbt)
- [civic/protocols.mbt](/Users/kq/Workspace/moontown/src/civic/protocols.mbt)
- [civic/communication_pattern_registry.mbt](/Users/kq/Workspace/moontown/src/civic/communication_pattern_registry.mbt)
- [civic/salon_scenario_types.mbt](/Users/kq/Workspace/moontown/src/civic/salon_scenario_types.mbt)
- [civic/salon_scenario_policy.mbt](/Users/kq/Workspace/moontown/src/civic/salon_scenario_policy.mbt)
- [civic/skill_text.mbt](/Users/kq/Workspace/moontown/src/civic/skill_text.mbt)
- [civic/workspace_text.mbt](/Users/kq/Workspace/moontown/src/civic/workspace_text.mbt)
- [civic/salon_metrics.mbt](/Users/kq/Workspace/moontown/src/civic/salon_metrics.mbt)
- [civic/salon_schedule_types.mbt](/Users/kq/Workspace/moontown/src/civic/salon_schedule_types.mbt)
- [civic/salon_schedule_policy.mbt](/Users/kq/Workspace/moontown/src/civic/salon_schedule_policy.mbt)
- [civic/status_labels.mbt](/Users/kq/Workspace/moontown/src/civic/status_labels.mbt)
- [civic/service_reconcile_policy.mbt](/Users/kq/Workspace/moontown/src/civic/service_reconcile_policy.mbt)
- [civic/protocol_contract_text.mbt](/Users/kq/Workspace/moontown/src/civic/protocol_contract_text.mbt)
- [civic/protocol_portfolio.mbt](/Users/kq/Workspace/moontown/src/civic/protocol_portfolio.mbt)
- [civic/protocol_snapshot.mbt](/Users/kq/Workspace/moontown/src/civic/protocol_snapshot.mbt)
- [civic_workspace.mbt](/Users/kq/Workspace/moontown/src/civic_runtime/civic_workspace.mbt)
- [civic_status.mbt](/Users/kq/Workspace/moontown/src/civic_runtime/civic_status.mbt)
- [civic_protocol_registry_runtime.mbt](/Users/kq/Workspace/moontown/src/civic_runtime/civic_protocol_registry_runtime.mbt)
- [civic_protocol_store.mbt](/Users/kq/Workspace/moontown/src/civic_runtime/civic_protocol_store.mbt)
- [civic_protocol_status_runtime.mbt](/Users/kq/Workspace/moontown/src/civic_runtime/civic_protocol_status_runtime.mbt)
- [civic_protocol_social_square_fixture.mbt](/Users/kq/Workspace/moontown/src/civic_runtime/civic_protocol_social_square_fixture.mbt)
- [civic_salon_scenario_types.mbt](/Users/kq/Workspace/moontown/src/civic_runtime/civic_salon_scenario_types.mbt)
- [civic_salon_scenario_runtime.mbt](/Users/kq/Workspace/moontown/src/civic_runtime/civic_salon_scenario_runtime.mbt)
- [civic_salon_runner.mbt](/Users/kq/Workspace/moontown/src/civic_runtime/civic_salon_runner.mbt)
- [docs/CIVIC_SALON_TEMPLATES.md](/Users/kq/Workspace/moontown/docs/CIVIC_SALON_TEMPLATES.md)

Implemented protocol pieces:

- building protocol definitions for inbox, contribution, reduction,
  distribution, and review channels
- append-only protocol ledgers under `.moontown/civic/protocols/<building-id>/`
- civic workspace `BUILDING_PROTOCOL_CONTRACT.md` seed files
- Social Square proof ledgers with one consent-gated review slice
- Social Square salon slices loaded from `CivicSalonScenario` templates, with
  intermediate participant workspaces, perspective packets, cross-area idea
  reductions, and a reviewable question backlog surfaced through the building
  book
- generic `CivicSalonScenario` loading so a new domain can be added by JSON
  template and schedule entry rather than a new MoonBit branch
- salon effectiveness metrics for idea yield, research-question yield,
  cross-book links, home-book coverage, and returned idea-home records
- return-home pages in each participating internal workspace so reduced ideas
  leave the building and become local reviewable work
- public projection filtering so intermediate salon participant workspaces and stale
  retry attempts do not crowd the operator book list
- wall-clock communication-pattern schedules under `.moontown/civic/pattern-schedules.json`
- append-only communication-pattern round records under `.moontown/civic/pattern-runs/`
- daemon-tick integration that runs due salons without hard-coding them into
  the frontend

Still planned:

- MoonClaw reducer packets that read `SKILL.md` and choose the module-native
  aggregation/reduction behavior
- real scenario packets for each non-Social-Square civic building
- MoonBook accept/reject persistence for reductions
- richer viewport projection fields for inbox pressure, active reduction,
  pending review, and recent distribution history

The CLI entry is:

```bash
moon run src/cmd/main -- civic bootstrap
moon run src/cmd/main -- civic protocols bootstrap
moon run src/cmd/main -- civic protocols status
moon run src/cmd/main -- civic protocols pattern-template assets/templates/civic-salons/robotics-mini-salon.json
moon run src/cmd/main -- civic protocols schedules status
moon run src/cmd/main -- civic protocols schedules tick
moon run src/cmd/main -- civic doctor
```

The recurring-salon path is intentionally schedule-driven and
template-driven. Operators can edit `.moontown/civic/pattern-schedules.json` to
enable/disable salons or adjust `interval_ms`, and can edit
`.moontown/civic/pattern-scenarios/<session-id>.json` to change the domain,
participants, skill rules, output paths, and review gate without changing
MoonBit. The daemon tick calls the same due-check as
`civic protocols schedules tick`, then records completion in JSONL for restart
inspection.

The registry covers Town Shell, Resident Twin Homes, Policy Hall, Contest
Express, Social Square, Talent Avenue, Vitality Tower, AI Science Garden,
Physical Bridge, Valley Market, and Story Radar. Each service has a book id,
module mode, book role, skill mode, schema pages, wiki pages, review queues,
worker role, skill pack, output contract, and projection summary.

Civic books intentionally bypass the Wenyu product research/bootstrap quality
gate. Their first task is the registry-defined `civic-service-workflow`, while
non-civic Wenyu books can still use product-build research, implementation,
code-patch, and asset-pack stages.

This is intentionally a bootstrap bridge. Durable civic-domain memory still
belongs in MoonBook, and tool execution still belongs in MoonClaw. Reusable
civic workspace text now lives in the `civic/` package so root Moontown can act
as a thin workspace materializer. A later MoonBook-side evolution may accept
these package-owned contracts through an API so Moontown requests workspace
creation instead of writing every seed file itself.

Protocol ownership remains the same:

- Moontown owns building routing, inbox/outbox ledgers, review gates, protocol
  status, and mayor supervision.
- MoonBook owns durable accepted civic records, schemas, review queues, and
  generated projections.
- MoonClaw owns AI-guided aggregation, reduction, drafting, source discovery
  when required, and result packaging.

### Standing Goal Run

Standing goals are durable town-level obligations. They are not book memory and
not worker sessions.

```text
.moontown/standing-goals.json
  -> daemon tick
  -> Mayor checks due standing goals
  -> Mayor dispatches a target-book standing-watch task
  -> MoonBook hydrates book-local baseline and context
  -> MoonClaw executes bounded web/source discovery
  -> MoonBook decides update/no_change/needs_review/failed
  -> MoonBook persists wiki/source/timeline/synthesis updates when useful
  -> Moontown records a watcher ledger entry
  -> Moontown advances next_due_tick with backoff
```

Retries use the same ownership boundary. Moontown may retry or poll the
execution, but it does not reinterpret the domain result. After a retry settles,
Moontown asks the target MoonBook history for the final standing-watch decision,
records a corrected watcher ledger row, and advances the standing goal from
that MoonBook decision.

The final integration portfolio currently installs five standing goals:

- `watch-opc-news` -> `research-opc`
- `watch-llm-training` -> `research-how-llms-are-trained-in-very-detail`
- `watch-embodied-robotics` -> `research-embodied-robotics`
- `watch-ai-agents` -> `research-ai-agents`
- `watch-ai-hardware` -> `research-ai-hardware`

The Mayor owns when each goal runs. The target MoonBook keeper owns what gets
remembered and what should be forgotten, reviewed, or promoted. MoonClaw workers
own how a bounded execution job is carried out and then exit.

This is the core long-standing split:

```text
Mayor decides when / where / why.
Book Keeper decides what belongs in durable memory.
Worker Claws decide how to execute bounded tasks.
```

Moontown persists the control-plane side of each watcher cycle under:

```text
.moontown/watchers/<standing-goal-id>.jsonl
```

Each line is a `WatcherRunRecord` containing the daemon tick, target book,
MoonBook decision, task/run ids, strict accounting fields, detail, and next due
tick. This ledger is the restart-readable audit trail for 24/7 operation. The
durable research truth still lives inside the target MoonBook.

Important boundary: the watcher ledger is not a wiki. It records whether a
check happened and what MoonBook decided about the check. The accounting fields
make this distinction explicit:

- `checked_sources_count`
  counts sources actually opened, fetched, or read enough to judge.
- `new_sources_found`
  counts candidate signals discovered during the check.
- `accepted_facts_count`
  counts facts MoonBook accepted into durable knowledge.
- `rejected_facts_count`
  counts candidate facts or sources rejected as duplicate, weak, stale, blocked,
  or irrelevant.
- `wiki_pages_changed_count`
  counts durable MoonBook pages changed by the cycle.
- `book_changed`
  is `yes` only when durable knowledge changed or review was queued.

This prevents a long-running town from mistaking retries, site rebuilds,
generated logs, or no-change patrols for research progress.
The same rule applies to worker-loss recovery. If MoonClaw still indexes a run
as `Running` but Moontown can no longer find the live proposal process, the
Mayor treats that as deferred infrastructure recovery unless MoonBook has
persisted a terminal standing-watch marker. Those orphaned-run records are not
counted as effective no-change cycles in the live autonomy spine. If the latest
watcher record is deferred, the operator-facing next action says so explicitly
instead of presenting the town as simply idle and waiting for cadence.
Historical transient infrastructure records remain visible as
`transient_infrastructure_debt` in the live autonomy spine. They are separated
from unresolved failures and no-change cycles so the town can mature its
operational reliability without counting infrastructure retries as book
knowledge growth.

Stable waiting is also explicit live-spine evidence. `stable_waiting` is true
only when the town has no active workers/executions, review queue, unresolved
failure, due standing goal, PlanBook open/repair gap, or pending/failed book
template request. `stable_waiting_observation_streak` counts consecutive quiet
daemon observations from `town-journal.jsonl`, and
`stable_waiting_blockers` explains why a tick is not cleanly waiting. This lets
overnight checks prove durability instead of inferring health from one latest
status line.

### Readiness and Quality Gates

Moontown now keeps a typed readiness layer for research acceptance instead of
only relying on Markdown string markers.

Current town-side readiness model:

- [research_readiness.mbt](/Users/kq/Workspace/moontown/src/research_quality/readiness.mbt)

It consumes MoonBook-owned summary fields such as verified source count, entity
page count, concept page count, query note count, and pending review count.
Moontown normalizes evidence accounting before using the summary: domain
evidence remains in `evidence_count`, operational watcher/run records are
reported as `operational_evidence_count`, and the raw audit total is preserved
as `total_evidence_count`. MoonBook still owns the workspace semantics;
Moontown only decides whether a lane is acceptable for town-level synthesis.

### Runtime Status and Daemon Tick

Moontown exposes an operator-readable runtime status seam:

- [runtime_status.mbt](/Users/kq/Workspace/moontown/src/runtime_status/runtime_status_snapshot.mbt)
- [runtime_status_policy](/Users/kq/Workspace/moontown/src/runtime_status_policy)
  owns reusable status DTO/count/summary/rendering policy.

The daemon implementation now has three levels:

- `daemon tick`
  runs one restart-safe mayor supervision cycle and bootstraps a saved town if
  no snapshot exists.
- `daemon run`
  repeats durable ticks and sleeps between iterations.
- `daemon start`
  starts a supervised background runtime with a supervisor process and a worker
  process. The supervisor watches process liveness and heartbeat age, then
  restarts a missing or stale worker.

Standing-goal execution uses bounded parallelism. A daemon tick may dispatch up
to three due standing goals, while the global live external execution cap remains
eight runs. This lets quality-repair and watch work mature faster without
turning the mayor into an unbounded launcher.

The daemon persists:

- `.moontown/daemon.json`
  daemon tick, lease owner, heartbeat event count, active standing goal ids, and
  scheduled job metadata
- `.moontown/daemon-runtime.json`
  supervisor/worker process ids, run ids, heartbeat and tick timestamps,
  success/failure counters, stop-request state, and last error
- `.moontown/daemon.log`
  append-only supervisor/worker lifecycle and guarded tick records
- `.moontown/daemon.restart`
  reload request marker written after validated self-patches. The worker
  consumes it between ticks, preserves supervisor state, exits cleanly, and lets
  the supervisor or launchd start a fresh worker with current source.
- `.moontown/daemon.pid`
  current daemon worker process id
- `.moontown/daemon-supervisor.pid`
  current daemon supervisor process id
- `.moontown/standing-goals.json`
  standing goal registry, cadence, target book, source policy, and next due tick
- `.moontown/watchers/*.jsonl`
  standing-watch decisions, no-change/update/review/failure records, and next
  due ticks
- `.moontown/book-template-requests.json`
  document-first book creation inbox used by Moondesk, Mayor, or other
  operators. The scheduled `book-template-request` job installs pending
  template requests, and the runtime/live-autonomy status exposes request,
  pending, and failed counts.
- `.moontown/book-template-request-events.jsonl`
  append-only lifecycle journal for processed book-template requests. Each
  event records the request id, template id, resolved config, status, tick,
  timestamp, and installer summary, so unattended book creation is auditable
  without relying on transient daemon logs.

The book-template registry currently includes:

- `pdf-evidence-watch`
  for source/PDF/text evidence watching and notification.
- `app-tool-book`
  for books that watch data, produce analysis reports, maintain app source, and
  publish a generated web tool through a civic building.

Both use the same durable inbox. Future book types should add a template
descriptor, template assets, installer, and skills, then let the daemon process
request documents. They should not require Codex to hand-create workspaces.

Template-created books may also be archived instead of deleted. For
`pdf-evidence-watch`, archiving disables every standing goal targeting that
book, including the PDF watcher and any `book-quality-repair-<book-id>` repair
goal. The workspace is kept for audit, the catalog entry is tagged
hidden/internal, and an `archived` event is written to the lifecycle journal.
That keeps smoke proofs and retired watches out of the autonomous cadence while
preserving evidence. Runtime status and the live autonomy spine therefore report
both enabled and disabled standing-goal counts. Enabled goals are active 24/7
workload; disabled goals are preserved audit state and must not be interpreted
as current town capacity demand.

Standing goals have two important operating modes:

- Topic watches are cadence checks. They compare new evidence against the
  current MoonBook baseline and can legitimately return `no_change`.
- Book-quality repair goals are active gap-closing loops. They are created from
  semantic review output, read the affected book's
  `wiki/reviews/book-quality-repair.md`, and should create or revise the named
  artifacts before returning a terminal marker. They should not degrade into a
  passive watch while the review queue still names missing artifacts.

This is now local multi-day process management. On macOS, the included launchd
installer runs `daemon supervise --worker` so the OS keeps the supervisor alive,
and the supervisor keeps the worker alive. Remaining hardening is
systemd/container packaging, external watchdog integration, and browser/backend
live sync.

MoonClaw supervision is nonblocking by default:

```bash
MOONTOWN_MOONCLAW_SUPERVISION_SECONDS=0
```

This is the correct default for 24/7 operation because a long-running watcher
should not serialize unrelated standing goals or civic communication-pattern
schedules. Set a positive value only when debugging one specific run inline.
Standing-watch imports are still launched as detached child processes, but the
child honors `MOONTOWN_MOONCLAW_INLINE=1` and passes `--inline` to MoonClaw
after confirmation. That keeps the Mayor loop nonblocking while preventing
confirmed runs from sitting in storage without a runner. If the detached import
fails before producing a receipt, Moontown preserves the `.import.json.err`
excerpt in the stale execution summary so MoonClaw/runtime errors are visible
to the supervision layer.
Before launching a standing-watch import, Moontown also checks the target
book-local MoonClaw job store for oversized active JSON indexes. When
`job_proposals.json`, `definitions.json`, or `index/artifacts.json` exceeds the
runtime safety threshold, the Mayor archives the file under
`.moonclaw/jobs/archive/tick-<tick>/` and replaces the active file with a valid
empty index. Historical files remain available for audit, while the hot store
stays small enough for MoonClaw proposal import/save operations.

The daemon launcher resolves the command from `MOONTOWN_DAEMON_COMMAND`,
`MOON_BIN`, then `$HOME/.moon/bin/moon`. The default dev path launches
`moon run src/cmd/main -- daemon ...`. Hosts that reap detached descendants should
run `daemon run` under their own process manager instead of relying on
`daemon start`.

### Stable-State Cookbook

The cookbook is the control book for durable definitions and operating
procedures:

```text
MoonBook cookbook workspace
  -> stable-state manifest
  -> docs / definitions / runtime-state index
  -> Moondesk human editing surface
  -> Moontown drift checks and operator guidance
```

Current implementation lives in:

- [cookbook.mbt](/Users/kq/Workspace/moontown/src/cookbook/pages.mbt)
- [docs/COOKBOOK.md](/Users/kq/Workspace/moontown/docs/COOKBOOK.md)

The CLI entry is:

```bash
moon run src/cmd/main -- cookbook bootstrap
moon run src/cmd/main -- cookbook status
moon run src/cmd/main -- cookbook doctor
```

`cookbook bootstrap` creates `.moontown/books/moontown-cookbook/`, registers it
in `.moontown/moonbooks.json`, and writes
`.moontown/cookbook/stable-state.json`. The cookbook does not reinterpret
domain knowledge. It names the canonical artifacts and records whether the
stable state is complete enough to operate.

Book governance now has two inputs: the curated MoonBook catalog and the saved
town snapshot. The catalog defines canonical books; the snapshot proves which
books are actually alive at runtime. The book-quality audit merges both views so
live standing-watch books cannot avoid review simply because they were spawned
by the Mayor rather than hand-entered into the catalog.

### Planbook

The planbook is the control book for code/product change plans:

```text
operator idea / bug / voice note / town anomaly
  -> Mayor routes to a planbook
  -> MoonBook writes plans/<date>-<slug>/plan.md
  -> MoonClaw executes against the plan
  -> acceptance criteria and execution evidence are recorded
  -> cookbook is updated only if stable state changed
```

This is intentionally separate from research and course books:

- research books maintain domain truth
- course books teach workflows
- planbooks control implementation work and quality gates
- the cookbook records stable definitions after plans are accepted

Current documentation and bootstrap commands:

- [docs/PLANBOOK.md](/Users/kq/Workspace/moontown/docs/PLANBOOK.md)
- [docs/DOC_STRUCTURE.md](/Users/kq/Workspace/moontown/docs/DOC_STRUCTURE.md)
- [assets/templates/planbook/PLAN_TEMPLATE.md](/Users/kq/Workspace/moontown/assets/templates/planbook/PLAN_TEMPLATE.md)

```bash
moon run src/cmd/main -- planbook bootstrap
moon run src/cmd/main -- planbook status
moon run src/cmd/main -- planbook doctor
moon run src/cmd/main -- planbook autonomy
moon run src/cmd/main -- planbook repair
moon run src/cmd/main -- planbook repair status
```

Moontown can now register and bootstrap a first-class planbook workspace with
plan index, implementation backlog, backlog progress, stop policy, execution
evidence, active review, decision log, live change log, schema, generated site,
and code-plan/code-review/doc-sync skills. It also runs a PlanBook autonomy doctor during daemon ticks. That doctor writes
`.moontown/planbook/autonomy.json`, updates the PlanBook evidence/review pages,
updates the backlog projection/progress/stop policy and change log, and adds
`planbook_open_count` plus repair actions to the live autonomy spine.

When the doctor finds open gaps, the daemon queues exactly one bounded repair
packet through the PlanBook repair bridge. The bridge materializes a repair
context, repair `SKILL.md`, repair plan, and MoonClaw packet under the PlanBook
workspace, then records `.moontown/planbook/repair-task.json`. The packet uses
the `planbook.repair.result.v1` contract and, during daemon ticks, is dispatched
through MoonClaw with `execution_mode: acp` and `execution_target: codex-main`.
The Codex ACP target is rooted at the Moontown source tree, so the town can patch
its own repository instead of stopping at plan-only output.
Moontown's ACP adapter layer owns the Codex command, argument list, and model
default for this route. The same default must be used by PlanBook source repair,
book-quality semantic review, and Wenyu source-build workers so the system does
not silently split into different Codex runtimes.
Book-quality review config also normalizes executable Codex args to match the
recorded model metadata, so repair/review profiles should pass adapter defaults
and avoid post-processing generated ACP JSON.

Current accounting separates route configuration from proof. ACP wiring alone is
not accepted self-patching evidence. A Moontown-owned source repair is accepted
only when the MoonClaw result carries a `planbook.repair.patch_receipt.v1`
receipt proving source-root ACP execution, changed files, validation command
results, `git diff --check`, `git status --short`, commit status/message, and
push policy. If the result lacks that receipt, PlanBook can record diagnostics or
ownership blockers, but it must not close the source-patch/software-engineering
criteria.

`planbook repair --dispatch` remains an explicit operator/debug trigger. This is
the current self-build spine: detect gaps, turn the top gap into executable
source work, preserve ownership boundaries, validate, inspect git status/diff
hygiene, record commit evidence, and rerun the doctor. The default policy can
prepare a local commit after validation, while push remains disabled unless an
explicit future policy enables it. If no stricter self-build criterion is open, the
doctor can surface the highest-priority open item from
`raw/backlog/implementation-backlog.json` as the next bounded repair. Open items
are taken one at a time. Once the backlog is clear, the code-building check
decays to a 30-minute interval. If a worker discovers the item is already done,
the right output is completion/progress/plan evidence, not code churn.

Daemon supervision also preserves the supervisor-recorded worker PID instead of
letting a worker loop overwrite it with an unreliable self-detected PID. That
matters for live autonomy: if the recorded worker PID is corrupted, the
supervisor can wrongly conclude the worker died and spawn duplicate workers.
The current daemon path keeps one live worker pair and exposes stale/duplicate
conditions through `daemon doctor`.

The remaining MoonBook-side work is to make `planbook` a native
provider/profile so future plan creation, plan repair, and review can run as
normal MoonBook book work instead of only through Moontown bootstrap and
deterministic self-inspection.

`books bootstrap` is the canonical bootstrap repair command for the currently
registered book families. It materializes operational, cookbook, planbook,
course, and civic service workspaces with different contracts and skill packs
instead of treating every book as research.

### Book Quality Governance

Book quality has two layers:

- Structural doctor
  checks whether each registered book has the expected workspace, contracts,
  skill files, projections, and role-specific evidence. This is readiness, not
  quality.
- Semantic AI review
  asks MoonClaw/MoonBook to judge usefulness, correctness, originality, role
  fit, evidence accounting, and next repair using the book's own `SKILL.md`.

The structural layer is implemented in
[book_quality.mbt](/Users/kq/Workspace/moontown/src/book_quality/assessment.mbt). It should
not pretend to know whether a report, course, plan, or civic service is
world-class. It only prevents obvious scaffold-only books from being reported
as ready.

Current structural readiness expectations are book-type specific:

- course books require course contract, outline, source boundary, lessons,
  exercises, rubric, course skill, and generated projection
- planbooks require plan index, plan, quality gates, execution evidence, active
  review, decision log, schema, skills, and generated projection
- cookbooks require stable-state definitions, ownership, book types, runtime
  boundaries, doctor/governance procedures, schema, and generated projection
- civic protocol support workspaces require service contract, building protocol
  contract, generic and module-specific civic skills, schemas, wiki pages when
  needed, ledgers, review queues, service history, MoonClaw profile, and
  generated projection. The expected shape depends on `persistence_mode`; a
  ledger-backed exchange place is not judged like a research book.

The semantic review packet layer writes:

- `.moontown/book-quality/ai-review-packets/BOOK_QUALITY_REVIEW_SKILL.md`
- `.moontown/book-quality/ai-review-packets/<book-id>.json`

The semantic review result layer reads:

- `.moontown/book-quality/ai-review-results/<book-id>.md`

Those packets are the handoff to AI judgment. The Mayor should use structural
failures for routing and use semantic review findings for quality repair.
The status surface collapses the run ledger into a current row per book and a
separate historical-attempt table. This keeps recovered orphaned or blocked
MoonClaw attempts visible for audit without presenting them as current live
degradation after a later review result has been harvested.
The repair bridge is also responsible for retirement: when a later semantic
review reaches the quality threshold, or when the target book is archived,
hidden/internal, or no longer managed, the corresponding
`book-quality-repair-<book-id>` standing goal is disabled. That prevents the
autonomous loop from polling satisfied or retired gaps forever.

The daemon owns the cadence for this semantic layer through the
`review-book-quality` scheduled job. That job is deliberately bounded: it
reconciles finished results, dispatches only one pending MoonClaw review, and
does not enqueue a duplicate while an active review process is alive. This keeps
book maturation live while preserving the Mayor -> MoonBook -> MoonClaw
responsibility boundary.

Scheduled jobs honor their declared `interval_seconds` against the daemon's
real worker tick. Thirty-second jobs can run every tick; sixty-second jobs run
every two ticks; the semantic book-review job runs on the thirty-minute cadence
unless an operator dispatches a manual review.

### Dispatch

```text
TownTask
  -> Mayor.decide_dispatch(...)
  -> Mayor.prepare_keeper_packet(...)
  -> external proposal packet
  -> proposal/run lifecycle record
```

## Packet Lifecycle Ownership

The packet lifecycle is intentionally split across package boundaries:

- `adapters/moonbook`
  - accepts goals
  - produces book task batches
  - hydrates worker context bundles
  - persists or summarizes book-local outcomes
  - refreshes generated workspace sites
- `roles/mayor`
  - decides whether work should be routed, deferred, or escalated
  - prepares keeper-facing packets from book tasks and worker context
  - performs town-level quality gating for cross-book research goals
- `adapters/moonclaw`
  - shapes `ExternalProposalPacket`
  - models `ProposalImportReceipt`
  - confirms and runs imported proposals
  - polls terminal run state
  - maps MoonClaw terminal state into town execution records
- `core`
  - records packet path, proposal id, run id, and execution status in `TaskExecutionRecord`

## Refactor Boundaries

The root package is now split so bootstrap planning is not buried inside the
goal runner:

- [goal_run.mbt](/Users/kq/Workspace/moontown/src/town_runtime/goal_run.mbt)
  - high-level goal orchestration, book launch, quality gates, and persistence handoff
- [goal_bootstrap.mbt](/Users/kq/Workspace/moontown/src/town_runtime/goal_bootstrap.mbt)
  - research bootstrap task selection and ingest-first planning
- [goal_execution.mbt](/Users/kq/Workspace/moontown/src/town_runtime/goal_execution.mbt)
  - MoonClaw proposal/run launch and MoonBook result persistence
- [goal_supervision.mbt](/Users/kq/Workspace/moontown/src/town_runtime/goal_supervision.mbt)
  - live execution polling, retry directives, worker status sync, and settle loop
- [research_quality.mbt](/Users/kq/Workspace/moontown/src/research_quality/core.mbt)
  - research quality gates, deep-report checks, and review-queue marking
- [town_synthesis.mbt](/Users/kq/Workspace/moontown/src/town_synthesis/town_synthesis.mbt)
  - mayor-owned cross-book synthesis rendering and synthesis execution registration
- [file_io.mbt](/Users/kq/Workspace/moontown/src/support/file_io.mbt)
  - root-package local text/file helpers used by synthesis, status, and quality checks
- [research_readiness.mbt](/Users/kq/Workspace/moontown/src/research_quality/readiness.mbt)
  - typed research readiness model
- [runtime_status.mbt](/Users/kq/Workspace/moontown/src/runtime_status/runtime_status_snapshot.mbt)
  - persisted snapshot status and daemon tick entry points

### Patrol

```text
TownState
  -> health.inspect_town(...)
  -> scheduler.plan_tick(...)
  -> Mayor.patrol(...)
```

## Persistence

Current persisted files:

- `.moontown/moonbooks.json`
  - persisted moonbook catalog entries
- `.moontown/town.json`
  - persisted town snapshot
- `.moontown/daemon.json`
  - persisted daemon tick state, lease owner, heartbeat event count, active standing goals, and scheduled job metadata
- `.moontown/standing-goals.json`
  - persisted Mayor-owned standing goal registry
- `.moontown/town-synthesis/*.md`
  - mayor-owned cross-book synthesis and readiness artifacts
- `.moontown/packets/`
  - optional exported keeper packet files
- `.moontown/books/<book>/raw/bootstrap/`
  - book-lane research question, search log, source screen, evidence matrix, local source digest, and synthesis brief
- `.moontown/books/<book>/book/site/generated/index.html`
  - MoonBook-generated site projection for the lane

Current implementation:

- [adapters/moonbook/client.mbt](/Users/kq/Workspace/moontown/src/adapters/moonbook/client.mbt)
- [storage/store.mbt](/Users/kq/Workspace/moontown/src/storage/store.mbt)

## What Is Real vs Stubbed

Real now:

- book catalog persistence
- Wenyu civic service registry and `civic bootstrap` workspace creation
- snapshot persistence
- town model
- routing model
- MoonBook CLI-backed planning, context hydration, summary, and health
- MoonClaw CLI-backed packet import, run confirmation, and polling for bounded goal runs
- MoonBook persistence/build after terminal goal runs
- parallel research-lane decomposition for multi-topic goals
- mayor-level research quality gates
- generic civic service reconciliation from building protocol ledgers into
  MoonBook service-result records
- town synthesis artifacts under `.moontown/town-synthesis/`
- integrated research narrative with W-source and L-source evidence references
- proposal/run lifecycle tracking
- strategic mayor role adapter
- dashboard and browser UI model
- local supervised daemon loop, heartbeat, stale detection, watcher ledgers,
  and launchd installer seam

Stubbed now:

- experiment runtime progression
- backend-synced Rabbita frontend state
- production-grade cross-platform service packaging
- repeated externally accepted-output histories for every Wenyu civic service

## Next Integration Milestones

The clean next order is:

1. let every Wenyu civic service accumulate multiple reconciled result
   histories over real daemon time
2. parse `wenyu.civic.*.v1` result contracts into structured service ledgers
3. expose package-owned civic workspace contracts through a MoonBook workspace
   creation API
4. add backend-synced Rabbita frontend state
5. add real experiment runtime
