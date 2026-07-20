# Package Map

This repo is organized as multiple MoonBit packages under one module. Source
packages live under [src](/Users/kq/Workspace/moontown/src); the repository root
is intentionally kept thin.

## Root Module

- [moon.mod](/Users/kq/Workspace/moontown/moon.mod)

Module name:

- `vectie/moontown`

Source root:

- `src`

Source tree hygiene:

- repository root should stay limited to metadata, docs, scripts, assets,
  templates, and runtime state directories
- `src/` is for source packages only; its root package is a facade and
  implementation code belongs in named package directories
- the only intended `src/` root source file is
  [src/facade.mbt](/Users/kq/Workspace/moontown/src/facade.mbt); if a change
  needs real behavior, create or use a cohesive package under `src/` instead
  of adding more root-package implementation files
- local runtime/cache directories such as `.moonsuite`, `.tmp`, `_build`, and
  `.mooncakes` are not package homes; source ownership is still decided by the
  `src/` package tree
- ignored generated/dependency directories such as `node_modules`, `_build`,
  `.mooncakes`, and `dist` must not be left under `src/` during architecture
  review; run `git clean -fdX src/ui/rabbita-town` after frontend builds if
  those artifacts need to be removed from the visible source tree
- `scripts/audit-source-layout.sh` enforces both the thin repository root and
  the source-tree hygiene rule

## Root Package

Primary root package files:

- [src/moon.pkg](/Users/kq/Workspace/moontown/src/moon.pkg)
- [src/facade.mbt](/Users/kq/Workspace/moontown/src/facade.mbt)
- [src/town_runtime](/Users/kq/Workspace/moontown/src/town_runtime)
- [src/integration_tests](/Users/kq/Workspace/moontown/src/integration_tests)

Purpose:

- `src/facade.mbt` preserves the public `vectie/moontown` API without keeping
  root-local implementation logic.
- `src/town_runtime` owns modeled bootstrap fixtures, saved-state bootstrap,
  dashboard rendering, goal runs, daemon entry points, standing-watch dispatch,
  and supervision internals.
- `src/town_runtime` may schedule package-provided task contracts, but
  feature-specific task contracts should live in the owning feature package.
- `src/town_runtime` registers books and applies role-provided worker refs, but
  must not own worker persona names, role/capability tables, or civic
  service-worker projection policy.
- `src/integration_tests` owns cross-package API and skill-quality tests.
- No implementation package should be added directly at repository root.

## Core

- [src/core/types.mbt](/Users/kq/Workspace/moontown/src/core/types.mbt)
- [src/core/task_lifecycle.mbt](/Users/kq/Workspace/moontown/src/core/task_lifecycle.mbt)

Purpose:

- core town types
- `BookProvider` abstraction
- town/book/worker/task/event records
- pure lifecycle policy for mapping execution status into town task status
- shared task-status predicates for which tasks remain schedulable
- shared execution-status predicates, stale-window defaults, retry-pending
  detection, and live external execution cap/counting
- shared distinction between live run-backed execution and broader active work
  such as awaiting persistence
- shared lifecycle rank/precedence for deduping repeated execution records
- shared task-id conventions such as daemon tick extraction from
  `*-tick-N` task ids
- pure path joining from an explicit base path

Important public types:

- `TownConfig`
- `BookRef`
- `WorkerRef`
- `TownTask`
- `StandingGoal`
- `TaskExecutionStatus`
- `AssignmentPlan`
- `TaskExecutionRecord`
- `TownEvent`
- `TownState`
- `BookProvider`

Boundary:

- `src/core` owns generic lifecycle translation such as
  `TaskExecutionStatus` to `TownTaskStatus` and safe task-status copying,
  because that mapping is part of the shared town data model.
- `src/core` owns generic task-status lifecycle predicates such as whether a
  task remains schedulable by the daemon loop.
- `src/core` owns generic execution-status categories such as terminal, live,
  active work, pollable, retry-pending, no-run stale, and live external
  execution capacity, plus execution-status lifecycle ranking.
- `src/core` owns generic task identity parsing such as extracting daemon ticks
  from execution task ids. Runtime packages should consume this helper instead
  of keeping duplicate parsers.
- `src/core` must not read process environment, current working directory,
  filesystem state, or clocks. If code needs cwd-aware path resolution, use
  `src/support.absolute_path_from_cwd(...)` from a runtime/adapter package.
- `StandingGoal.source_policy` is an uninterpreted string in `src/core`.
  `src/core` must not choose defaults such as `web-first` or `book-first`;
  policy-aware packages must supply values from `src/policy`.
- `src/town_runtime` may apply those pure helpers while polling and
  supervising runs, but it should not maintain a second execution-to-task
  status table, live-run cap, stale-window table, or task-id tick parser.

## Dispatch

- [src/dispatch/router.mbt](/Users/kq/Workspace/moontown/src/dispatch/router.mbt)
- [src/dispatch/domain_policy.mbt](/Users/kq/Workspace/moontown/src/dispatch/domain_policy.mbt)

Purpose:

- route tasks to workers
- classify books and MoonBook task kinds into town `WorkDomain` values
- apply policy-owned goal text for routing/planning purposes
- prioritize MoonBook task batches for dispatch order
- classify special MoonBook task routes such as research bootstrap tasks
- choose assignment vs escalation vs deferral
- choose isolation modes

Boundary:

- `src/dispatch` owns task-domain classification and isolation policy because
  both decisions affect routing.
- `src/dispatch` owns MoonBook task ordering policy and may expose routing
  helpers that apply `src/policy` goal-text vocabulary.
- `src/dispatch` owns shared MoonBook task route classifiers that are consumed
  by Mayor role planning and MoonClaw packet/profile routing.
- `src/dispatch` also owns route-facing task-id predicates such as research
  bootstrap task identity. Runtime recovery code may consume those predicates,
  but it should not duplicate task-id substring checks.
- `src/town_runtime` may construct `TownTask` records from MoonBook tasks, but
  should not maintain its own mapping from book ids or task kinds to
  `WorkDomain`.
- `src/town_runtime` may ask for prioritized task batches, but should not own
  task-kind score tables or Wenyu/research goal-text classifiers.

## Experiment

- [src/experiment/run.mbt](/Users/kq/Workspace/moontown/src/experiment/run.mbt)

Purpose:

- experiment data model scaffold

Current status:

- deterministic baseline/challenger assignment and outcome evaluation are real
- promotion, rollback, and hold remain recommendations requiring a separate
  human-reviewed MoonFlow settlement
- durable scheduling and repeated experiment persistence are still pending

## Health

- [src/health/report.mbt](/Users/kq/Workspace/moontown/src/health/report.mbt)

Purpose:

- health inspection
- anomaly detection
- recovery action modeling

## Scheduler

- [src/scheduler/daemon.mbt](/Users/kq/Workspace/moontown/src/scheduler/daemon.mbt)

Purpose:

- collect due work
- collect due standing goals
- plan one town tick
- summarize tick actions

Current status:

- plans normal execution lifecycle actions
- plans standing-goal due actions for the daemon
- records active standing goal ids in daemon state
- owns current daemon scheduled-job vocabulary such as `civic-pattern`,
  `civic-service`, `book-quality`, and `book-template-request`
- preserves configured jobs during daemon job merge without exposing
  scenario-specific ids or kinds as public API

Boundary:

- runtime packages may ask whether a job is a current civic communication,
  book-quality, template-request, projection, or health job.
- runtime packages should not branch on scenario-specific ids or kinds outside
  the scheduler vocabulary.

## Standing Watch Policy

- [src/standing_watch_policy](/Users/kq/Workspace/moontown/src/standing_watch_policy)
- [src/standing_watch_contracts](/Users/kq/Workspace/moontown/src/standing_watch_contracts)

Purpose:

- standing-watch task kind, ids, prompts, and target pages
- standing-watch worker skill paths, context pages, and output-contract lines
- strict watcher accounting markers and marker parsers
- MoonBook standing-watch history parsing and provider-decision collapse policy
- material-delta metrics, watcher-record matching, and watcher-record decision
  selection
- standing-watch event shape for watcher run records
- standing-watch live snapshot stale-window policy and transient dispatch-error
  classification
- empty completion `no_change` marker summary contract
- empty review completion keeper-triage summary contract
- keeper auto-triage/recovery closure policy, thresholds, and summary wording
- standing-watch retry-accounting classification rules
- review-triage predicates for empty completions, repair-goal still-open
  cycles, and superseded review debt

Boundary:

- `src/standing_watch_contracts` owns the adapter-safe standing-watch worker
  contract: task kind, skill path set, context page set, and result output-contract lines.
  It is intentionally dependency-light so MoonBook adapters can consume it
  without importing the full standing-watch policy package.
- `src/standing_watch_policy` owns standing-watch prompts, ids, marker
  vocabulary/parser, history semantics, material-delta accounting, keeper
  closure policy, event kind/id/related-field shape, stale windows, transient dispatch
  classification, and recovery/review predicates.
- `src/town_runtime` may schedule standing-watch work, apply package-owned
  decisions to `TownState`, persist snapshots, append watcher ledgers, and
  construct the concrete MoonBook `BookTask` from standing-watch policy values.
- `src/town_runtime` should not own standing-watch marker vocabulary, closure
  thresholds, watcher-record matching/status mapping, standing-watch event
  shape/id/related-field construction, live snapshot stale windows, transient dispatch classification, or
  empty-completion `no_change` marker text, empty review completion summary
  text, retry-accounting predicates, or review-triage predicates.
- `src/adapters/moonbook` may enrich standing-watch worker context using
  `src/standing_watch_contracts`, but should not hardcode standing-watch skill
  path tables, context-page tables, output-contract lines, or task-kind checks.
  If the adapter needs to recognize a standing-watch task, it should call the
  adapter-safe contract package.
- `src/town_runtime` should use `src/storage` for generic snapshot-root/base
  path derivation before appending runtime-owned subdirectories such as
  `book-results`.

## MoonBook Worker Contracts

Key files:

- [src/moonbook_contracts/worker_contracts.mbt](/Users/kq/Workspace/moontown/src/moonbook_contracts/worker_contracts.mbt)

Purpose:

- `src/moonbook_contracts` owns adapter-safe generic MoonBook worker contracts:
  default keeper skill paths, default keeper context pages, fallback policy and
  routine lines, fallback memory summary, and fallback output-contract fields.

Boundary:

- `src/adapters/moonbook` may construct `WorkerContextBundle` records and
  apply `src/moonbook_contracts` defaults when book/task context is sparse.
- `src/adapters/moonbook` must not hardcode generic keeper skill paths, default
  context pages, fallback policy/routine wording, fallback memory-summary
  wording, or fallback output-contract field lists.
- Specialized contracts such as standing-watch, course, and Wenyu civic work
  remain in their own adapter-safe contract packages.

## Course Worker Contracts

Key files:

- [src/course_contracts/worker_contracts.mbt](/Users/kq/Workspace/moontown/src/course_contracts/worker_contracts.mbt)

Purpose:

- `src/course_contracts` owns adapter-safe beginner-course worker contracts:
  Wenyu beginner-course and wiki-course skill paths, course context page sets,
  required artifact paths, course policy and routine lines, prompt wording,
  memory summary, and output-contract lines.

Boundary:

- `src/adapters/moonbook` may detect course context, derive a book display
  name, and append `src/course_contracts` values into a worker bundle.
- `src/adapters/moonbook` must not hardcode course skill paths, course context
  pages, required course artifact paths, course prompt wording, or course
  output-contract lines.
- `src/course_contracts` may consume `src/research_policy` for shared research
  support paths, but it should own course-specific artifact and quality wording.

## Research Policy

- [src/research_policy](/Users/kq/Workspace/moontown/src/research_policy)

Purpose:

- shared research-depth targets and source-screening thresholds
- canonical research topic normalization, display naming, and
  local-vs-external routing hints
- canonical raw/bootstrap artifact paths and topic-specific wiki page paths
- canonical research skill path contracts and reusable skill-path sets
- canonical research context-page sets and bootstrap output-contract lines
- canonical research-report reference input, reference-length, and no-reference
  deep-research rules
- reusable vocabulary for MoonBook research skill prompts and future quality
  gates without introducing adapter/runtime dependency cycles

Boundary:

- `src/research_policy` owns static research policy constants such as dossier
  word targets, included-source thresholds, discovery attempt limits, and
  bounded fetch command wording.
- `src/research_policy` owns source-class vocabulary used by web-first and
  source-depth prompts, such as primary/official, independent, research
  institution, market/adoption, critique/risk, source-data, and paper classes.
- `src/research_policy` owns bootstrap prompt policy text for reference leads,
  native web search, command fallback, search-result fetch, front-door
  discovery, harvest-to-inspection, source-depth, and plain-Markdown/no-JSON
  worker behavior.
- `src/adapters/moonbook` should call those `src/research_policy` constants
  directly when assembling research prompts; it should not keep adapter-local
  `research_policy_*` wrapper functions, source-class mirror helpers,
  bootstrap policy prompt helpers, or threshold mirror tests.
- `src/research_policy` owns topic policy such as attempt-suffix stripping,
  display-name derivation, web-query/reference/local-source hints, and whether a
  topic should begin as local-project or external-domain research.
- `src/research_policy` owns canonical research artifact paths such as
  `raw/bootstrap/research-question.md`, `raw/bootstrap/search-log.md`,
  `raw/bootstrap/deep-report.md`, and topic-specific `wiki/sources`,
  `wiki/entities`, `wiki/concepts`, and `wiki/synthesis` pages.
- `src/research_policy` owns canonical bootstrap stage artifact groups such as
  report-stage input artifacts, report-stage output targets, and quality-repair
  input artifacts.
- `src/adapters/moonbook` should call those path helpers directly; it should
  not keep adapter-local `research_*_path` facade helpers or duplicate
  artifact-path mirror tests.
- `src/research_policy` owns reusable bootstrap report-stage policy text such
  as repair-mode handling, evidence boundaries, no-reference quality authority,
  quality targets, and self-review expectations.
- `src/adapters/moonbook` should call those report-stage policy helpers
  directly while assembling provider prompts; it should not keep adapter-local
  report policy prompt helpers that duplicate policy-owned wording.
- `src/research_policy` owns reusable bootstrap source-stage policy text such
  as missing-source handling and source-expansion harvested-candidate fetching.
- `src/adapters/moonbook` should call those source-stage policy helpers
  directly while assembling provider prompts; it should not keep adapter-local
  source policy prompt helpers that duplicate policy-owned wording.
- `src/research_policy` owns reusable bootstrap quality-repair policy text such
  as depth targets, length floors, evidence-bounded expansion axes, and
  no-churn repair standards.
- `src/adapters/moonbook` should call those quality-repair policy helpers
  directly while assembling provider prompts; it should not keep adapter-local
  quality policy prompt helpers that duplicate policy-owned wording.
- `src/research_policy` owns reusable generated-request source-screen policy
  text such as screened-source row fields, included-source depth targets,
  discovery-artifact exclusion, and source-depth blocker wording.
- `src/adapters/moonbook` should call those request policy helpers directly
  while assembling generated request pages; it should not keep adapter-local
  request policy helpers that duplicate policy-owned wording.
- `src/research_policy` owns reusable generated-request discovery/fallback
  policy text such as native-search fallback, search-result fetch,
  front-door discovery, command-fallback logging, candidate-page fetch, and
  source-class exhaustion wording.
- `src/adapters/moonbook` should call those discovery policy helpers directly
  while assembling generated request pages; it should not keep adapter-local
  discovery policy helpers that duplicate policy-owned wording.
- `src/research_policy` owns reusable generated-request output policy text such
  as claim traceability quality bars, deep-report depth targets, and
  reference-style use bullets.
- `src/adapters/moonbook` should call those request-output policy helpers
  directly while assembling generated request pages; it should not keep
  adapter-local output policy helpers that duplicate policy-owned wording.
- `src/research_policy` owns research skill path contracts such as
  `skills/web-first-research/SKILL.md`,
  `skills/research-evidence-synthesis/SKILL.md`,
  `skills/research-report/SKILL.md`, and the grouped skill sets for bootstrap,
  enrichment, and standing-watch research support.
- `src/research_policy` owns the context pages and raw-artifact output contract
  that define a research bootstrap handoff, including the `REFERENCE_*` context
  pages and the required raw artifact sentence.
- `src/research_policy` owns bootstrap reference-context use policy: reference
  style/output files are craft guidance, and reference source hints are
  candidate leads, not evidence.
- `src/adapters/moonbook` should call those reference-context policy helpers
  directly while assembling worker prompts; it should not keep adapter-local
  context policy prompt helpers that duplicate policy-owned wording.
- `src/research_policy` owns research-report policy helpers such as reference
  input lists, reference-length rules, no-reference deep-research rules, and
  report threshold aliases. MoonBook prompt builders should call those helpers
  directly instead of keeping adapter-local report-policy aliases.
- `src/research_policy` owns research-report output requirements such as
  title/section/table/diagram/source-id/evidence-limit requirements and the
  required-input section. MoonBook prompt builders should call those helpers
  directly instead of keeping adapter-local report-requirement helpers.
- `src/research_policy` owns research-report article-shape and quality-rubric
  sections. MoonBook prompt builders should call those helpers directly instead
  of keeping adapter-local report-shape helpers.
- `src/adapters/moonbook` may consume those constants while building provider
  requests and generated `SKILL.md` guidance, but should not define its own
  competing research-depth thresholds, topic routing rules, query hint tables,
  research skill path tables, research context-page sets, output-contract
  lines, research artifact path tables, report-shape sections, or path facade
  helpers.
- `src/research_quality` owns research quality semantics from explicit
  observations: readiness DTOs, required research paths, quality gates,
  repair/review trigger contracts, and persistence wording contracts.
  `src/research_quality_runtime` owns collecting filesystem/MoonBook
  observations and persisted research-artifact handoff. Research quality should
  consume policy vocabulary when thresholds must be shared, but should not
  become an adapter or filesystem dependency.

## Storage

- [src/storage/store.mbt](/Users/kq/Workspace/moontown/src/storage/store.mbt)

Purpose:

- snapshot persistence
- checkpoint model
- generic snapshot-base directory derivation
- standing-goal registry persistence
- watcher ledger persistence
- watcher ledger path derivation from town snapshot paths
- watcher run record append/load helpers

Current persisted files:

- `.moonsuite/products/moontown/town.json`
- `.moonsuite/products/moontown/standing-goals.json`
- `.moonsuite/products/moontown/watchers/*.jsonl`
- `.moonsuite/products/moontown/packets/` when keeper packets are exported

Boundary:

- `src/storage` owns the generic rule that `town.json` in the current
  workspace maps to the MoonSuite MoonTown product home, while explicit
  snapshot paths keep their explicit parent directory.
- Runtime packages may derive their own feature-specific filenames under that
  base, but should call `storage.snapshot_base_dir(...)` instead of
  reimplementing `dirname(snapshot_path)` fallback logic.
- Feature packages such as `book_templates`, `book_quality`,
  `final_integration_runtime`, `visual_projection_runtime`, and `town_runtime`
  should append their local filenames to this storage-owned base rather than
  owning a second relative-snapshot fallback.
- `scripts/audit-source-layout.sh` enforces that direct
  `Path::dirname(snapshot_path)` snapshot-base derivation appears only inside
  `src/storage`.

## Final Integration

- [src/final_integration](/Users/kq/Workspace/moontown/src/final_integration)
- [src/final_integration_runtime](/Users/kq/Workspace/moontown/src/final_integration_runtime)

Purpose:

- final-integration manifest schema
- pure standing-goal merge and coverage policy
- status JSON shaping
- runtime portfolio install/status command execution
- civic workspace/protocol/scenario installation wiring

Boundary:

- `src/final_integration` owns only policy and DTOs. It must not read files,
  inspect daemon runtime state, save standing goals, call civic runtime
  bootstrap, or write integration status artifacts.
- `src/final_integration_runtime` owns the IO path: manifest loading,
  daemon-tick inspection, standing-goal persistence, civic bootstrap and
  scenario installation, and durable status JSON writes.
- CLI commands should call `final_integration_runtime`; tests for pure merge
  policy stay in `final_integration`, while filesystem/runtime tests stay in
  `final_integration_runtime`.

## Town Synthesis

- [src/town_synthesis](/Users/kq/Workspace/moontown/src/town_synthesis)
- [src/town_synthesis_runtime](/Users/kq/Workspace/moontown/src/town_synthesis_runtime)

Purpose:

- mayor-owned cross-book synthesis rendering
- synthesis slug/path/task-id policy
- synthesis task/execution registration policy
- lane-report observation DTOs
- runtime lane-report file loading and synthesis artifact persistence

Boundary:

- `src/town_synthesis` owns rendering and town-state mutation policy from
  explicit observations. It must not read `raw/bootstrap/deep-report.md` files
  or write `.moonsuite/products/moontown/town-synthesis/*` artifacts.
- `src/town_synthesis_runtime` owns synthesis IO: reading each lane's deep
  report, writing the goal-specific and `latest.md` synthesis artifacts, and
  calling the package-owned registration/event policy.
- `src/town_synthesis` should consume `src/policy` goal vocabulary for choosing
  synthesis surfaces such as Wenyu output. It should not maintain local
  `wenyu`/research trigger-word checks.
- Remaining MoonBook summary and research-quality observations inside
  `town_synthesis` are an explicit next seam: they should eventually follow
  the same observation-fed pattern used for lane report text.

## Roles

- [src/roles/mayor.mbt](/Users/kq/Workspace/moontown/src/roles/mayor.mbt)

Purpose:

- strategic `Mayor` role adapter
- dispatch packets
- patrol packets
- standing-goal target book routing
- keeper handoff packets
- keeper proposal packet preparation
- worker provisioning policy for built-in town workers, book-local watcher
  lanes, generic book execution lanes, and civic service worker lanes

This package is where town code stops talking to raw agent runtime metadata and
starts talking to a role-specific API.

Boundary:

- `src/roles` may compose Mayor prompts, lane plans, dispatch packets, and
  keeper handoffs.
- `src/roles` owns worker personas and capability envelopes. Runtime code
  should ask it for `WorkerRef` values and then only dedupe/register them.
- `src/roles` should consume `src/policy` goal-text vocabulary and
  `src/dispatch` routing helpers instead of redefining research/Wenyu trigger
  words or task-domain tables.
- `src/town_runtime` must not construct production worker personas directly;
  `scripts/audit-source-layout.sh` enforces this for non-test runtime files.

## Moonbook Adapter

- [src/adapters/moonbook/client.mbt](/Users/kq/Workspace/moontown/src/adapters/moonbook/client.mbt)

Purpose:

- persisted moonbook catalog
- book provider implementation
- extension API request/result types

Current persisted file:

- `.moonsuite/products/moontown/moonbooks.json`

Current real pieces:

- catalog read/write
- catalog-backed `BookProvider`
- workspace initialization through real `moonbook wiki init`
- MoonClaw extension seeding through real `moonbook wiki enable moonclaw`
- `accept_goal(...)`
- `produce_task_batch(...)`
- `hydrate_worker_context(...)`
- `persist_result(...)`
- `summarize_state(...)`
- `report_health(...)`

`summarize_state(...)` preserves MoonBook's raw evidence total but normalizes
the town-facing readiness count: domain evidence stays in `evidence_count`,
watcher/run bookkeeping moves to `operational_evidence_count`, and the raw audit
total is exposed as `total_evidence_count`.

Boundary:

- adapter fallback discovery may recognize MoonBook's historical generated-site
  layouts after a build.
- MoonTown's canonical generated-site index path is still policy-owned; adapter
  canonical path helpers delegate to
  `policy.default_generated_site_projection_path()`.

## Moonclaw Adapter

- [src/adapters/moonclaw/import.mbt](/Users/kq/Workspace/moontown/src/adapters/moonclaw/import.mbt)

Purpose:

- embedded runtime metadata
- strategic/domain/execution role profiles
- external proposal packet boundary
- proposal/run lifecycle receipts

Boundary:

- `src/adapters/moonclaw` owns packet construction, command wiring, receipts,
  task-kind worker-profile selection, and MoonClaw-specific prompt/target-page
  adaptation. Catalog policy-type profile overrides belong in
  `src/moonclaw_policy`, not in the adapter.
- Catalog-backed keeper packets preserve the composed book architecture by
  attaching `book_type`, `book_policy`, `book_loop_plan`, and
  `book_internal_distance_plan` to packet metadata. Mayor code may decide when
  to prepare a packet, but it should pass the catalog entry instead of
  reconstructing book policy fields or worker profile strings itself.
- shared task-route classification belongs in semantic owner packages:
  `src/dispatch` owns research-bootstrap routing, and `src/course_book` owns
  course-book intent detection. MoonClaw adapter code should not duplicate
  BookTask kind/id/prompt classifiers.
- shared MoonClaw packet wait policy belongs in `src/moonclaw_policy`.
  The adapter may merge those fields into external proposal packets, but it
  should not redefine `disable_waiting_for_input` or
  `best_effort_on_missing_input` locally.
- shared MoonClaw keeper-profile override policy belongs in
  `src/moonclaw_policy`. The adapter may ask for an override from catalog
  metadata, but it should not branch on PlanBook/civic policy labels or
  duplicate dedicated worker-profile strings.

Current real pieces:

- `mayor_runtime()`
- `keeper_runtime(...)`
- `worker_runtime(...)`
- `mayor_to_keeper_handoff(...)`
- `build_import_command(...)`
- `packet_file_path(...)`
- `proposal_packet_from_bundle(...)`
- `save_packet_file(...)`
- `import_packet(...)` via real `moonclaw proposal import --json`
- `poll_run(...)`

## MoonClaw Policy

- [src/moonclaw_policy](/Users/kq/Workspace/moontown/src/moonclaw_policy)

Purpose:

- reusable MoonClaw packet wait policy
- reusable non-adaptive/no-input profile metadata
- reusable execution metadata maps
- reusable step metadata maps

Boundary:

- `src/moonclaw_policy` owns cross-package MoonClaw metadata semantics such as
  no-input/best-effort behavior and standard execution/step metadata fields.
- `src/moonclaw_policy` owns non-adaptive/no-input profile metadata used by
  direct worker profiles such as research bootstrap. MoonBook adapters should
  call this helper rather than defining `disable_adaptive` or no-input flags
  locally.
- `src/moonclaw_policy` owns BookPolicy-shape to MoonClaw keeper-profile
  overrides. Book-type/catalog-entry adapters delegate to policy composition
  and capability introspection first instead of duplicating
  `planbook_repair_worker` or `wenyu_civic_service_worker` routing rules.
- `src/moonclaw_runtime`, `src/adapters/moonclaw`, `src/adapters/moonbook`,
  and `src/book_quality` may consume these helpers when building packets or
  profile metadata.
- Higher-level packages must not duplicate these fields directly. If the
  MoonClaw packet contract changes, update this package first and let callers
  inherit the new shape.

Important public types:

- `ExternalProposalPacket`
- `ProposalImportReceipt`

## UI

Key files:

- [src/ui/scene_layout.mbt](/Users/kq/Workspace/moontown/src/ui/scene_layout.mbt)
- [src/ui/dashboard.mbt](/Users/kq/Workspace/moontown/src/ui/dashboard.mbt)
- [src/ui/scene_render.mbt](/Users/kq/Workspace/moontown/src/ui/scene_render.mbt)

Purpose:

- semantic town scene layout
- dashboard state projection
- renderer-facing scene model
- reusable UI view-policy helpers such as execution-status stage grouping
- reusable runtime visual priority helpers for choosing which task/execution a
  civic module should surface first
- HTML bridge

Boundary:

- `src/ui` owns product-agnostic dashboard, scene layout, and view-policy
  helpers that can be consumed by multiple frontends.
- UI applications should consume shared helpers such as
  `execution_view_stage_for_status(...)` and
  `runtime_task_priority_for_id(...)` instead of duplicating town execution
  status or runtime-priority taxonomies locally.

## Loop Policy

Key files:

- [src/policy/book_policy.mbt](/Users/kq/Workspace/moontown/src/policy/book_policy.mbt)
- [src/policy/book_policy_labels.mbt](/Users/kq/Workspace/moontown/src/policy/book_policy_labels.mbt)
- [src/policy/book_policy_paths.mbt](/Users/kq/Workspace/moontown/src/policy/book_policy_paths.mbt)
- [src/policy/book_policy_source.mbt](/Users/kq/Workspace/moontown/src/policy/book_policy_source.mbt)
- [src/policy/book_policy_catalog.mbt](/Users/kq/Workspace/moontown/src/policy/book_policy_catalog.mbt)
- [src/policy/book_policy_lanes.mbt](/Users/kq/Workspace/moontown/src/policy/book_policy_lanes.mbt)
- [src/policy/book_policy_loop.mbt](/Users/kq/Workspace/moontown/src/policy/book_policy_loop.mbt)
- [src/policy/book_policy_distance.mbt](/Users/kq/Workspace/moontown/src/policy/book_policy_distance.mbt)
- [src/policy/goal_text.mbt](/Users/kq/Workspace/moontown/src/policy/goal_text.mbt)

Purpose:

- typed `BookPolicy` model
- canonical book labels used as profile keys
- canonical source-policy labels such as web-first and book-first
- catalog-entry classification helpers that map observed book metadata into
  composed policy profiles
- policy-owned default projection paths and surface names
- canonical `control`, `execute`, and `tend` lane parsing
- policy-composed loop plans and health gates
- policy-derived internal-distance plans for information, recognition, and
  decisiveness
- policy-owned serialized context metadata that combines book type,
  `BookPolicy`, loop plan, and internal-distance plan for packet producers
- policy-owned capability introspection over composed policy choices such as
  `standing-watch`, `research-evidence`, `course-curriculum`,
  `stable-cookbook`, `pdf-watch`, `web-tool-surface`, `civic-protocol`, and
  `generated-site`
- reusable goal-text vocabulary for research, research-request, and Wenyu
  routing signals

Boundary:

- `BookPolicy` keeps serialized skill lanes as strings for stable JSON.
- `src/policy` owns canonical book label strings and source-policy strings.
  Downstream packages may consume these constants, but should not duplicate
  literal labels such as `research-book`, `civic-protocol-support`,
  `web-first`, or `book-first`.
- `src/policy/book_policy_catalog.mbt` owns only catalog classification; it
  should not accumulate output, lane, label, or source-policy definitions.
- Downstream packages should call policy classification helpers through
  catalog metadata instead of treating storage prefixes such as `research-` or
  `wenyu-` as architectural book-type gates. Prefixes may remain artifact naming
  conventions, but they are not the product boundary.
- Downstream packages should call `capability_ids(policy)` or
  `has_capability(policy, ...)` when they need to inspect composed
  capabilities. They should not duplicate capability detection from skill ids,
  tags, or path names outside `src/policy`.
- If a downstream package only has MoonBook catalog metadata, it should call
  policy-owned catalog capability helpers such as
  `catalog_entry_runs_standing_watch(...)` and
  `catalog_entry_runs_research_evidence(...)`, and
  `catalog_entry_runs_civic_protocol(...)`. It should not re-run catalog
  classification and compare book-type labels locally.
- MoonBook adapter routing follows the same rule: existing catalog metadata is
  authoritative first; when an explicit research request names a non-canonical
  book id, the research topic should be derived from the goal/request text and
  stored under the stable research slug. Do not reject such requests solely
  because the requested id lacks a `research-` prefix.
- `src/policy` owns default output path and surface constants for composed
  policies.
- `src/policy` owns lane normalization and lane-based skill selection.
- `src/policy` owns pure goal-text vocabulary. Dispatch, roles, runtime, and
  adapters may consume it, but should not redefine research/Wenyu trigger
  words or research-topic extraction locally.
- `src/policy` owns catalog research-topic hints from `topic:` tags and
  canonical `research-*` storage slugs. Adapters and quality packages should
  consume that helper instead of parsing research tags or slugs themselves.
  Dynamic MoonBook research-book lookup is included in this rule: it asks
  policy for a topic hint, then only normalizes the returned topic before
  creating the stable storage entry.
- `src/policy` owns the internal-distance growth-vector view; downstream
  packages may render it but should not redefine how execute/tend/quality
  map to information, recognition, and decisiveness.
- `src/policy` owns the JSON field shape for policy context metadata. Packet
  producers should merge that object instead of rebuilding `book_policy`,
  `book_loop_plan`, or `book_internal_distance_plan` fields locally.
- downstream packages may read lane text but should not redefine lane semantics.

## Book Quality

Key files:

- [src/book_quality/policy_specs.mbt](/Users/kq/Workspace/moontown/src/book_quality/policy_specs.mbt)
- [src/book_quality/scoring_engine.mbt](/Users/kq/Workspace/moontown/src/book_quality/scoring_engine.mbt)
- [src/book_quality/scoring_primitives.mbt](/Users/kq/Workspace/moontown/src/book_quality/scoring_primitives.mbt)
- [src/book_quality/civic_service_scoring.mbt](/Users/kq/Workspace/moontown/src/book_quality/civic_service_scoring.mbt)
- [src/book_quality/review_context.mbt](/Users/kq/Workspace/moontown/src/book_quality/review_context.mbt)
- [src/book_quality/repair_goal_policy.mbt](/Users/kq/Workspace/moontown/src/book_quality/repair_goal_policy.mbt)
- [src/book_quality_runtime/book_quality_review_run_render.mbt](/Users/kq/Workspace/moontown/src/book_quality_runtime/book_quality_review_run_render.mbt)

Purpose:

- evaluate book quality using policy profiles, structural evidence, semantic
  review results, and repair context
- translate policy profiles into quality-review and repair actions
- build quality-review context pages and repair standing-goal policy
- check required output surfaces from the effective `BookPolicy`
- include `BookPolicy.required_files` in structural path scoring without
  double-counting paths that also have package-specific weights
- expose the canonical required-path profile lookup for a policy book type, so
  structural observers and runtime code do not rebuild research/course/
  PlanBook/Cookbook/civic/operational switches
- include `BookPolicy.required_files` in semantic review context pages so AI
  review sees the same artifacts used by health gates
- attach structured `BookPolicy` loop and internal-distance plans to semantic
  review metadata for downstream agent/tool consumers
- preserve those structured policy metadata fields through the runtime review
  dispatch boundary into MoonClaw external proposal packets

Boundary:

- `src/book_quality` consumes book labels, source-policy labels, composed
  policies, and catalog classification from `src/policy`.
- `src/book_quality` may judge observed content shape such as a course page
  looking like a research report, but book-id/type interpretation must come
  from `src/policy.catalog_entry_type(...)`, not direct storage-prefix checks.
- `src/book_quality` owns how quality is assessed and repaired, but it must
  read book output paths from `src/policy.BookPolicy` instead of maintaining a
  parallel generated-site path per book kind.
- `src/book_quality/scoring_profiles.mbt` owns table-driven required-path
  profile selection for book types. Other `book_quality` files should call
  that helper instead of duplicating type-to-path switches.
- `src/book_quality` must remain observation-fed: it may accept semantic review
  text and structural facts, but it must not derive snapshot-relative storage
  paths or read review-result files.
- Book-type labels accepted at this boundary must resolve through policy
  profiles/capabilities before deciding required output surfaces or
  content-specific signal gates.
- `src/book_quality` must not re-export policy vocabulary such as
  `research_type`, `civic_type`, `web_first_policy`, or `book_first_policy`;
  downstream packages should import `src/policy` directly when they need those
  values.
- `src/book_quality` must also not expose pass-through policy lookup or catalog
  classification APIs; runtime packages should call `src/policy` for
  `policy_for_type`, `source_policy_for_type`, and catalog classification.
- `src/book_quality_runtime` owns snapshot-relative review-result directory
  derivation, semantic-review file reads, required-path existence checks, and
  filesystem observations passed into pure scoring.
- operational-book bootstrap and projection templates may live here because
  they support quality/operating-memory workflows, but their type labels still
  come from `src/policy`.
- `src/book_quality` owns quality scoring and repair-action wording, not the
  policy taxonomy itself.
- `src/book_quality` owns score computation from supplied
  `BookQualityStructuralObservation` and `BookQualityContentObservation`
  values. It owns required-relative-path derivation for runtime observers and
  parses `ai_quality_score` / `next_repair_task`, but it must not read
  workspaces, semantic-review result files, deep-report content, course index
  content, civic result files, or cookbook audit files directly.
- `src/book_quality` owns review-run ledger/status vocabulary, display row
  construction, active-review counting, and status Markdown rendering from
  explicit runtime observations.
- `src/book_quality` owns pure review-run ledger helpers: empty ledger,
  text parse/serialize, and append/update semantics. It should not load or
  write the ledger file.
- `src/book_quality` owns first-pending semantic-review candidate selection
  from an audit plus an observed completed-review book-id list; it should not
  inspect result files to decide which candidates are completed.
- `src/book_quality` owns path-explicit semantic-review proposal contracts:
  request text, notes, tags, metadata, result-path contract, context-page
  shaping, and skill-path attachment. It should not call current-working-
  directory helpers or resolve process-local paths itself.
- `src/book_quality_runtime` owns review status observation: loading the run
  ledger file, checking result-file existence, observing current time, and
  passing those facts into `src/book_quality`.
- `src/book_quality_runtime` owns process-local semantic-review proposal
  adaptation: resolving workspace roots and review skill paths against the
  current working directory, then feeding explicit paths into
  `src/book_quality`.
- `src/book_quality_runtime` owns semantic-review completion observation:
  result-file existence checks are converted into completed book ids before
  calling `src/book_quality` candidate-selection policy.
- `src/book_quality_runtime` owns review-run ledger reconciliation IO and
  aggregation: load the ledger, observe filesystem/process/MoonClaw output,
  call package-owned per-run transitions, write accepted results, fold counts,
  and persist changed ledgers.
- `src/book_quality_runtime` owns accepted semantic-review result file writes;
  `src/book_quality` owns the result path contract and review-result parsing.
- `src/book_quality_runtime` owns structural and content observation for scoring:
  workspace existence checks, required-relative-path existence checks, civic
  latest-result checks,
  semantic-review result file reads, research deep-report word counts, course
  index text reads, cookbook audit existence checks, and the runtime
  `score_book(entry, result_dir)` adapter that feeds those observations into
  `src/book_quality` scoring.
- `src/book_quality_runtime` owns review-run ledger storage APIs used by
  dispatch, reconciliation, and status rendering: load, append, and write.
- `src/book_quality/scoring_engine.mbt` owns the generic policy-type scoring
  flow. It should not branch into one full scorer per book archetype; it should
  classify through `src/policy`, score `required_paths_for_book_type(...)`,
  apply `scoring_signals.mbt`, and finalize through policy health. Reusable
  draft/finalization/path-scoring internals belong in `scoring_primitives.mbt`;
  civic-service scoring details belong in `civic_service_scoring.mbt`.

## Build Pipeline

Key files:

- [src/build_pipeline/bootstrap_task.mbt](/Users/kq/Workspace/moontown/src/build_pipeline/bootstrap_task.mbt)
- [src/build_pipeline/contract.mbt](/Users/kq/Workspace/moontown/src/build_pipeline/contract.mbt)
- [src/build_pipeline/moonclaw_profile_prompts.mbt](/Users/kq/Workspace/moontown/src/build_pipeline/moonclaw_profile_prompts.mbt)
- [src/build_pipeline/build_pipeline_tasks.mbt](/Users/kq/Workspace/moontown/src/build_pipeline/build_pipeline_tasks.mbt)
- [src/build_pipeline/build_pipeline_prompts.mbt](/Users/kq/Workspace/moontown/src/build_pipeline/build_pipeline_prompts.mbt)
- [src/build_pipeline/local_execution.mbt](/Users/kq/Workspace/moontown/src/build_pipeline/local_execution.mbt)
- [src/build_pipeline_runtime/moonclaw_profile.mbt](/Users/kq/Workspace/moontown/src/build_pipeline_runtime/moonclaw_profile.mbt)
- [src/build_pipeline_runtime/preseed_workspace.mbt](/Users/kq/Workspace/moontown/src/build_pipeline_runtime/preseed_workspace.mbt)
- [src/build_pipeline_runtime/source_bundle.mbt](/Users/kq/Workspace/moontown/src/build_pipeline_runtime/source_bundle.mbt)
- [src/build_pipeline_runtime/codex_acp_target.mbt](/Users/kq/Workspace/moontown/src/build_pipeline_runtime/codex_acp_target.mbt)
- [src/build_pipeline_runtime/build_pipeline_artifacts.mbt](/Users/kq/Workspace/moontown/src/build_pipeline_runtime/build_pipeline_artifacts.mbt)

Purpose:

- own Wenyu bootstrap and build task contracts for bootstrap ingest,
  implementation backlog, code patch, and asset/projection work
- own pure Wenyu build prompts, output-contract id, execute/review prompt
  templates, task target pages, worker roles, priorities, and review flags
- own Wenyu build/civic task-plan helpers: Wenyu detection, local
  fallback-task predicates, build task limit, positive task-limit
  normalization, and civic-service task merge that removes bootstrap duplicates
- own local Wenyu build fallback execution-record construction, including
  packet ids, local packet paths, materializer proposal id, skill paths, review
  requirement, stale window, and output contract
- let `src/build_pipeline_runtime` own all filesystem/provider side effects:
  build-readiness path checks, PRD/vision copies, research request/source-hint
  writes, mounted source snapshots, generated Wenyu skill files, civic seed
  dispatch, MoonClaw profile installation, Codex ACP target registration, and
  fallback artifact materialization

Boundary:

- `src/town_runtime` may decide when a Wenyu book is ready for bootstrap/build,
  supply the current repo root, and ask `src/build_pipeline_runtime` to
  preseed or build a Wenyu workspace.
- `src/town_runtime` should ask `src/civic` whether an entry is a Wenyu build
  book instead of inspecting `wenyu-*` storage slugs directly; civic owns Wenyu
  module identity and registered-service exclusion rules.
- `src/build_pipeline` owns the Wenyu bootstrap/build task contracts and may
  compose target pages through `src/policy`, `src/research_quality`, and civic
  service definitions. It should consume `src/civic` Wenyu identity helpers
  rather than branching on Wenyu storage prefixes itself.
- `src/build_pipeline_runtime` consumes those contracts and performs the
  workspace/profile/source/artifact side effects.
- `src/town_runtime` should not own Wenyu build output-contract ids, MoonClaw
  profile JSON, ACP step metadata, source-bundle manifests, source-hint pages,
  generated build-skill installation, Codex ACP target JSON, or build/review
  prompt templates. It also should not own Wenyu build/civic task merge policy
  beyond adapting package-owned tasks into the generic goal-book plan shape.

## PlanBook Policy And Runtime

Key files:

- [src/planbook_policy/run_status.mbt](/Users/kq/Workspace/moontown/src/planbook_policy/run_status.mbt)
- [src/planbook_policy/repair_commands.mbt](/Users/kq/Workspace/moontown/src/planbook_policy/repair_commands.mbt)
- [src/planbook_policy/repair_metadata.mbt](/Users/kq/Workspace/moontown/src/planbook_policy/repair_metadata.mbt)
- [src/planbook_policy/validation_evidence.mbt](/Users/kq/Workspace/moontown/src/planbook_policy/validation_evidence.mbt)
- [src/planbook_policy/backlog_types.mbt](/Users/kq/Workspace/moontown/src/planbook_policy/backlog_types.mbt)
- [src/planbook_policy/backlog_defaults.mbt](/Users/kq/Workspace/moontown/src/planbook_policy/backlog_defaults.mbt)
- [src/planbook_policy/backlog_rendering.mbt](/Users/kq/Workspace/moontown/src/planbook_policy/backlog_rendering.mbt)
- [src/planbook_runtime/planbook_repair_run_status.mbt](/Users/kq/Workspace/moontown/src/planbook_runtime/planbook_repair_run_status.mbt)
- [src/planbook_runtime/planbook_repair_result.mbt](/Users/kq/Workspace/moontown/src/planbook_runtime/planbook_repair_result.mbt)
- [src/planbook_runtime/planbook_daemon_phase.mbt](/Users/kq/Workspace/moontown/src/planbook_runtime/planbook_daemon_phase.mbt)

Purpose:

- `src/planbook_policy` owns pure PlanBook contracts, repair command policy,
  PlanBook validation-evidence contract/readiness/required-command policy, and
  raw MoonClaw run-status normalization.
- `src/planbook_policy` owns repair metadata policy such as required
  engineering steps, patch-receipt required fields, and git policy JSON.
- `src/planbook_policy` also owns PlanBook backlog DTOs, canonical backlog
  paths, default seed items, projection Markdown, cadence/stop-policy text,
  backlog criterion ids/evidence/next-action wording, and target-file hints.
- `src/planbook_policy` owns repair target-file selection for known criteria.
  Runtime may provide resolved source/workspace paths, but should not own the
  criterion-to-target-file map.
- `src/planbook_runtime` owns workspace IO, run reconciliation, and
  evidence-aware repair lifecycle decisions.
- `src/planbook_runtime` owns the daemon-facing PlanBook phase: write autonomy
  status, avoid duplicate repair tasks, dispatch one bounded repair task when
  no repair is active, and return the summaries that town projection records.

Boundary:

- raw MoonClaw `Succeeded` means the external run completed.
- `planbook_runtime` may still mark a repair task failed when a completed run
  lacks required PlanBook repair evidence.
- do not encode missing-evidence decisions in raw status normalization.
- PlanBook runtime may write `planbook/latest-validation.md`, but the
  `planbook.validation.v1` contract, required validation commands, and
  readiness predicate belong in `src/planbook_policy`.
- PlanBook runtime may assemble MoonClaw packet metadata, but repair
  contract vocabulary, required engineering steps, patch-receipt required
  fields, and git policy belong in `src/planbook_policy`.
- PlanBook runtime may resolve dynamic roots such as the current source root,
  PlanBook workspace root, or course workspace root before calling policy
  target-file helpers.
- PlanBook runtime may load/write `raw/backlog/...`, progress pages, completion
  evidence, and the live change log, but backlog schema/path/default/cadence/
  rendering/criterion wording belongs in `src/planbook_policy`.
- default generated-site path semantics belong to `src/policy`; PlanBook
  runtime consumes `policy.default_generated_site_projection_path()` rather
  than redefining the projection path.
- town runtime may call the PlanBook daemon phase and record its summaries, but
  should not own duplicate-repair wording or PlanBook repair dispatch policy.

## Course Book

Key files:

- [src/course_book/core.mbt](/Users/kq/Workspace/moontown/src/course_book/core.mbt)
- [src/course_book/content.mbt](/Users/kq/Workspace/moontown/src/course_book/content.mbt)
- [src/course_book/projection_content.mbt](/Users/kq/Workspace/moontown/src/course_book/projection_content.mbt)

Purpose:

- bootstrap the Wenyu beginner course MoonBook workspace
- keep course output course-shaped rather than research-shaped
- write generated course projection content
- classify course-book task intent for adapter routing

Boundary:

- course-specific content and course workspace files belong here.
- course-book identity and positive course prompt signals belong here; adapters
  may consume the classifier but should keep only adapter-specific packet
  prompts and target-page lists locally.
- course projection content may render the course type, but the label itself
  comes from `src/policy`; CourseBook should not redefine `course-book`.
- default generated-site path semantics belong to `src/policy`; CourseBook
  consumes `policy.default_generated_site_projection_path()` rather than
  redefining the projection path.

## Book Templates

Key files:

- [src/book_templates/types.mbt](/Users/kq/Workspace/moontown/src/book_templates/types.mbt)
- [src/book_templates/registry_policy.mbt](/Users/kq/Workspace/moontown/src/book_templates/registry_policy.mbt)
- [src/book_templates/request_policy.mbt](/Users/kq/Workspace/moontown/src/book_templates/request_policy.mbt)
- [src/book_templates/request_paths.mbt](/Users/kq/Workspace/moontown/src/book_templates/request_paths.mbt)
- [src/book_templates_runtime/runtime.mbt](/Users/kq/Workspace/moontown/src/book_templates_runtime/runtime.mbt)
- [src/book_templates_runtime/requests.mbt](/Users/kq/Workspace/moontown/src/book_templates_runtime/requests.mbt)
- [src/book_templates_runtime/request_storage.mbt](/Users/kq/Workspace/moontown/src/book_templates_runtime/request_storage.mbt)
- [src/book_templates_runtime/registry_storage.mbt](/Users/kq/Workspace/moontown/src/book_templates_runtime/registry_storage.mbt)

Purpose:

- define reusable book-template descriptors, request ledgers, request events,
  request status vocabulary, registry readiness, and installer outcome wording
- derive canonical template registry, request inbox, and request-event paths
- let a runtime package process template requests, observe registry files, call
  concrete installers, and render operator-facing template status pages

Boundary:

- `src/book_templates` owns pure contracts: DTOs, path derivation,
  registry-policy construction/rendering, request lifecycle/status/event
  semantics, install-success marker interpretation, and Wenyu build skill text.
- `src/book_templates` must not load registry/request files, write request
  ledgers, append event JSONL files, call PDF/AppTool installers, or mutate
  workspaces.
- `src/book_templates_runtime` owns those side effects: registry file
  observation, request ledger/event storage, request processing, event
  reconciliation, installer dispatch, and runtime status rendering entrypoints.
- Higher-level runtime packages and CLI code should call
  `src/book_templates_runtime` for side effects and `src/book_templates` for
  pure path/status/policy helpers.
- Wenyu build skill file materialization belongs to `src/build_pipeline_runtime`;
  `src/book_templates` only owns the reusable skill text.

## Cookbook

Key files:

- [src/cookbook/manifest.mbt](/Users/kq/Workspace/moontown/src/cookbook/manifest.mbt)
- [src/cookbook/pages.mbt](/Users/kq/Workspace/moontown/src/cookbook/pages.mbt)
- [src/cookbook_runtime/cookbook_runtime.mbt](/Users/kq/Workspace/moontown/src/cookbook_runtime/cookbook_runtime.mbt)
- [src/cookbook_runtime/workspace.mbt](/Users/kq/Workspace/moontown/src/cookbook_runtime/workspace.mbt)

Purpose:

- define the stable-state control book identity, manifest, durable definitions,
  ownership rules, operating procedures, and codebase describer pages
- render cookbook status wording and stable-state drift accounting
- let the runtime package materialize those contracts into a MoonBook workspace

Boundary:

- stable-state definitions, cookbook page content, manifest accounting, and
  cookbook status wording belong here.
- catalog registration, filesystem artifact observation, manifest writes,
  workspace writes, generated-site writes, and command entrypoints belong in
  `src/cookbook_runtime`.
- default generated-site path semantics belong to `src/policy`; Cookbook
  consumes `policy.default_generated_site_projection_path()` rather than
  redefining the projection path.

## App ToolBook

Key files:

- [src/app_tool_book/contracts.mbt](/Users/kq/Workspace/moontown/src/app_tool_book/contracts.mbt)
- [src/app_tool_book/workspace_runtime.mbt](/Users/kq/Workspace/moontown/src/app_tool_book/workspace_runtime.mbt)
- [src/app_tool_book/standing_watch.mbt](/Users/kq/Workspace/moontown/src/app_tool_book/standing_watch.mbt)

Purpose:

- bootstrap MoonBook workspaces that include a durable generated web tool
- install tool specs, report paths, app manifests, generated tool pages, and
  standing-watch loops
- expose civic-building actions that let MoonTown open reports, tools, and
  MoonDesk configuration surfaces

Boundary:

- App ToolBook is a template/capability package, not a separate policy book
  type. Generated-tool books should use a composed policy type such as
  `policy.general_type()` plus tags/specialization such as `generated-tool`,
  `web-tool-surface`, and `template:app-tool-book`.
- App ToolBook owns the generated tool page path and generated-tool workspace
  contract because those are tool-specific.
- default generated-site index path semantics belong to `src/policy`; App
  ToolBook consumes `policy.default_generated_site_projection_path()` rather
  than redefining the projection path.

## PDF Evidence Watch

Key files:

- [src/pdf_evidence_watch/workspace.mbt](/Users/kq/Workspace/moontown/src/pdf_evidence_watch/workspace.mbt)
- [src/pdf_evidence_watch/standing_goal.mbt](/Users/kq/Workspace/moontown/src/pdf_evidence_watch/standing_goal.mbt)
- [src/pdf_evidence_watch/status.mbt](/Users/kq/Workspace/moontown/src/pdf_evidence_watch/status.mbt)
- [src/pdf_evidence_watch_runtime/book.mbt](/Users/kq/Workspace/moontown/src/pdf_evidence_watch_runtime/book.mbt)
- [src/pdf_evidence_watch_runtime/install.mbt](/Users/kq/Workspace/moontown/src/pdf_evidence_watch_runtime/install.mbt)
- [src/pdf_evidence_watch_runtime/status.mbt](/Users/kq/Workspace/moontown/src/pdf_evidence_watch_runtime/status.mbt)
- [src/pdf_archive/archive.mbt](/Users/kq/Workspace/moontown/src/pdf_archive/archive.mbt)
- [src/pdf_archive_runtime/archive_command.mbt](/Users/kq/Workspace/moontown/src/pdf_archive_runtime/archive_command.mbt)

Purpose:

- define domain-specific PDF watcher MoonBook identity, config schema,
  standing-watch instructions, required workspace paths, skill/page contracts,
  and generated evidence-watch projection shape
- let the runtime package install those contracts into real MoonBook
  workspaces, catalog entries, standing goals, and status reports

Boundary:

- PDF Evidence Watch is a research-book capability package, not a separate
  policy book type. Runtime-generated `book.json` should use
  `policy.research_type()` plus PDF-specific template id, tags, skills, and
  watch contracts.
- PDF source discovery, extraction, analysis-method, and notification contract
  semantics belong here.
- PDF runtime behavior belongs in `src/pdf_evidence_watch_runtime`: config file
  loading, relative path resolution, template copying, workspace writes,
  catalog writes, standing-goal writes, status inspection, and command
  entrypoints.
- PDF archive policy belongs in `src/pdf_archive`: archived/hidden/internal
  catalog tagging, standing-goal disable rules, disabled-goal counting, and
  archive summary wording.
- PDF archive runtime mutation belongs in `src/pdf_archive_runtime`: catalog
  persistence, standing-goal persistence, request-event journaling, status
  inspection, and the command entrypoint.
- default generated-site path semantics belong to `src/policy`; PDF Evidence
  Watch consumes `policy.default_generated_site_projection_path()` rather than
  redefining the projection path.

## Research Quality

Key files:

- [src/research_quality/bootstrap_task.mbt](/Users/kq/Workspace/moontown/src/research_quality/bootstrap_task.mbt)
- [src/research_quality/readiness.mbt](/Users/kq/Workspace/moontown/src/research_quality/readiness.mbt)
- [src/research_quality/projection_gaps.mbt](/Users/kq/Workspace/moontown/src/research_quality/projection_gaps.mbt)
- [src/research_quality/source_depth_gaps.mbt](/Users/kq/Workspace/moontown/src/research_quality/source_depth_gaps.mbt)
- [src/research_quality/review_trigger.mbt](/Users/kq/Workspace/moontown/src/research_quality/review_trigger.mbt)
- [src/research_quality/quality_gate_events.mbt](/Users/kq/Workspace/moontown/src/research_quality/quality_gate_events.mbt)
- [src/research_quality_runtime/quality_observation.mbt](/Users/kq/Workspace/moontown/src/research_quality_runtime/quality_observation.mbt)
- [src/research_quality_runtime/persistence_payload.mbt](/Users/kq/Workspace/moontown/src/research_quality_runtime/persistence_payload.mbt)
- [src/research_quality_runtime/review_trigger.mbt](/Users/kq/Workspace/moontown/src/research_quality_runtime/review_trigger.mbt)

Purpose:

- evaluate research-readiness and quality gate gaps
- own the generic research bootstrap ingest task contract, prompt, target pages,
  review requirement, and worker role
- detect weak source depth, process noise, generic generated-site projections,
  and missing topic-specific wiki materialization
- define the canonical `raw/bootstrap/QUALITY_REPAIR.md` path and Markdown
  contract for in-place research quality repair
- define observation-fed research quality judgment so runtime can collect facts
  without moving semantics into filesystem code
- let the runtime package collect observations, write and resolve the repair
  trigger file, and translate completed research bootstrap artifacts into
  persistence summaries, artifact paths, and MoonBook memory candidates
- own research quality-gate execution-summary suffixes and recovery/review
  event wording
- expose quality judgments that town runtime can use without reimplementing
  research semantics

Boundary:

- research quality owns the generic research bootstrap contract, observation
  DTOs, judgment from observations, repair-trigger file contract, repair
  wording, topic-specific signal checks, persistence-summary wording,
  artifact-list contract, memory-candidate target-page contract, and
  quality-gate/recovered-bootstrap message semantics.
- `src/research_quality_runtime` owns filesystem/MoonBook observation for
  quality gates: required-path checks, source-marker scans, MoonBook summary
  reads, bootstrap artifact reads, generated-site reads, topic page scans,
  active repair trigger writes, and resolved-trigger writes.
- `src/town_runtime` may decide that a repair trigger should be written or
  resolved, may choose between Wenyu and research bootstrap, and may dispatch
  persistence to the owning package. It may apply review/recovery transitions to
  town executions and workers, but should not own research bootstrap
  prompt/target pages, the trigger path/prose, research persistence payload
  semantics, or quality-gate/recovery wording.
- default generated-site path semantics belong to `src/policy`; Research
  Quality consumes `policy.default_generated_site_projection_path()` rather
  than redefining the projection path.

## Civic Definitions And Runtime

Key files:

- [src/civic/services.mbt](/Users/kq/Workspace/moontown/src/civic/services.mbt)
- [src/civic/services_paths.mbt](/Users/kq/Workspace/moontown/src/civic/services_paths.mbt)
- [src/civic/services_result_paths.mbt](/Users/kq/Workspace/moontown/src/civic/services_result_paths.mbt)
- [src/civic_contracts/wenyu_worker_contracts.mbt](/Users/kq/Workspace/moontown/src/civic_contracts/wenyu_worker_contracts.mbt)
- [src/civic_runtime/civic_service_persist.mbt](/Users/kq/Workspace/moontown/src/civic_runtime/civic_service_persist.mbt)
- [src/civic_runtime/civic_workspace_projection.mbt](/Users/kq/Workspace/moontown/src/civic_runtime/civic_workspace_projection.mbt)
- [src/civic_runtime/civic_communication_scenario_workspace.mbt](/Users/kq/Workspace/moontown/src/civic_runtime/civic_communication_scenario_workspace.mbt)

Purpose:

- `src/civic` owns service definitions, target page contracts, skill paths,
  protocol vocabulary, civic helper paths, and civic service result-path
  derivation.
- `src/civic` owns Wenyu module/book identity helpers, including the difference
  between configured civic-service books and Wenyu build books. Runtime
  packages, build-pipeline packages, and quality packages should call those
  helpers instead of branching on `wenyu-*` slugs.
- `src/civic` owns civic communication reducer contract helpers: reducer input,
  participant, output, blocker, step-kind, output-contract id/type, and
  MoonClaw profile-family names.
- `src/civic` exposes generic civic communication skill text and protocol note
  helpers. Public helper names should use communication-pattern vocabulary;
  `research-salon` remains one pattern constructor, not the skill API.
- `src/civic` owns communication schedule and round-record DTOs. Public records
  identify the scheduled scenario with `scenario_id`; they should not encode
  `salon` as the generic record vocabulary.
- `src/civic_contracts` owns adapter-safe Wenyu worker contracts: Wenyu build
  and civic-service skill path sets, Wenyu context page sets, bootstrap artifact
  paths, and civic output-contract lines.
- `src/civic_runtime` owns workspace writes, ledgers, generated pages, and
  scenario execution persistence.
- `src/civic_runtime` exposes generic civic communication-pattern runtime APIs
  for schedule paths, scenario paths, schedule load/save/upsert, due execution,
  scenario bootstrap, and schedule status rendering.
- `src/civic_runtime` owns civic-service MoonBook persistence payloads:
  execution detection, summary text, artifact lists, memory candidates, review
  candidate routing, and civic target-page trimming.

Boundary:

- civic runtime writes generated pages through `@civic` path helpers.
- civic runtime public APIs should use communication-pattern vocabulary.
  `research-salon` is one configured pattern; runtime helper names should use
  `civic_communication_*` vocabulary rather than treating salon as the generic
  abstraction.
- civic runtime writes reducer workspaces through `@civic` reducer-contract
  helpers; it should not hardcode reducer filenames or profile family ids.
- civic runtime reducer helpers use `civic_communication_reducer_*` names.
- civic runtime schedule/path helpers use `civic_communication_*` names and
  should preserve persisted `pattern-*` file locations.
- civic runtime owns civic-specific filenames under `civic/`, but
  snapshot-relative base directory fallback belongs to `src/storage`; do not
  reimplement `dirname(snapshot_path)` for civic communication schedule,
  scenario, run-ledger, or projection paths.
- persisted scenario ids and template filenames may still contain
  domain-specific names such as `research-salon`, but implementation helpers
  should stay generic so new communication patterns do not require MoonBit
  branches.
- `src/town_runtime` may choose when a civic service result should be persisted,
  but should not assemble civic persistence summaries, artifact lists, or memory
  candidates.
- `src/book_quality` and `src/civic_runtime` must consume
  `@civic.civic_service_result_path(...)` instead of keeping separate result
  path derivation rules.
- `src/civic` delegates default generated-site semantics to `src/policy`;
  civic modules should not redefine the generated-site path locally.
- `src/adapters/moonbook` may consume `src/civic_contracts` to enrich Wenyu
  worker bundles, but it must not hardcode Wenyu skill paths, Wenyu context
  pages, bootstrap artifact path tables, or civic service output-contract lines.

## Daemon Runtime Policy And Runtime

Key files:

- [src/daemon_runtime_policy/health.mbt](/Users/kq/Workspace/moontown/src/daemon_runtime_policy/health.mbt)
- [src/daemon_runtime_policy/transitions.mbt](/Users/kq/Workspace/moontown/src/daemon_runtime_policy/transitions.mbt)
- [src/daemon_runtime/daemon_runtime_inspection.mbt](/Users/kq/Workspace/moontown/src/daemon_runtime/daemon_runtime_inspection.mbt)
- [src/daemon_runtime/daemon_runtime_tick_infra.mbt](/Users/kq/Workspace/moontown/src/daemon_runtime/daemon_runtime_tick_infra.mbt)
- [src/daemon_runtime/daemon_scheduled_jobs.mbt](/Users/kq/Workspace/moontown/src/daemon_runtime/daemon_scheduled_jobs.mbt)
- [src/town_runtime/daemon_runtime_supervise.mbt](/Users/kq/Workspace/moontown/src/town_runtime/daemon_runtime_supervise.mbt)

Purpose:

- `src/daemon_runtime_policy` owns daemon state vocabulary, health labels,
  heartbeat staleness, transition builders, doctor actions, and the pure
  `daemon_runtime_should_spawn_worker(...)` supervision predicate.
- `src/daemon_runtime` owns filesystem/process inspection, PID files, logs,
  launchd integration, request files, runtime state persistence, scheduled-job
  execution, scheduled-job activity/noise filtering, tick path construction,
  tick phase log formatting/appending, and live tick-lock inspection.
- `src/town_runtime` owns the town-level supervisor loop and worker spawning.
- `src/town_runtime` owns mayor-specific daemon tick orchestration: loading the
  town state, running supervision, dispatching standing goals, invoking
  scheduled jobs, invoking PlanBook, and writing projections/checkpoints.

Boundary:

- supervisor loops must ask `daemon_runtime_policy` whether worker spawn is due.
- town runtime may spawn or stop processes, but should not compare raw daemon
  status strings such as `missing`, `stopped`, `running`, or `ticking`.
- daemon-state and standing-goal paths derived from a town snapshot path must
  come from `daemon_runtime_policy`; live-autonomy and book-quality runtime code
  may read those files, but should not reimplement `dirname(snapshot)` path
  logic locally.
- town runtime may call the scheduled-job phase during a tick, but should not
  own scheduled-job interval math, scheduled-job dispatch, or the decision that
  a summary is meaningful enough to become a town event.
- town runtime may orchestrate tick phases, but daemon tick paths, phase log
  line format, phase-log append behavior, and runtime-lock checks belong in
  `src/daemon_runtime`.

## Rabbita Frontend

Key files:

- [src/ui/rabbita-town/main/main.mbt](/Users/kq/Workspace/moontown/src/ui/rabbita-town/main/main.mbt)
- [src/ui/rabbita-town/styles.css](/Users/kq/Workspace/moontown/src/ui/rabbita-town/styles.css)
- [src/ui/rabbita-town/index.html](/Users/kq/Workspace/moontown/src/ui/rabbita-town/index.html)
- [src/ui/rabbita-town/package.json](/Users/kq/Workspace/moontown/src/ui/rabbita-town/package.json)
- [src/ui/rabbita-town/vite.config.js](/Users/kq/Workspace/moontown/src/ui/rabbita-town/vite.config.js)

Purpose:

- browser implementation of the town dashboard
- live simulation UI
- Vite build/dev workflow

Boundary:

- `src/ui/rabbita-town/main` owns browser bridges, event handlers, concrete
  HTML/CSS view composition, and app-specific fallback wording.
- Vite request handlers may translate browser forms into durable document
  records, but defaults such as standing-goal source policy must come from
  document contracts such as
  [assets/templates/operator-request-policy.json](/Users/kq/Workspace/moontown/assets/templates/operator-request-policy.json),
  not raw JavaScript literals.
- reusable projection policy belongs in `src/ui` or `src/visual_projection`,
  while durable projection writes belong in `src/visual_projection_runtime`,
  not in the browser main package.
- `src/ui/rabbita-town/main` should not maintain app-local task-priority
  substring tables; it should call `src/ui` view-policy helpers when selecting
  which runtime task or execution to show first.

## Support

- [src/support](/Users/kq/Workspace/moontown/src/support)

Purpose:

- generic file I/O and parent-directory helpers
- cwd-aware and explicit-base absolute path helpers
- workspace-relative path readiness helpers
- JSON helper functions
- Markdown, HTML, and text-label helpers
- shared text metrics such as English word-token counting

Boundary:

- `src/support` may own product-agnostic utility behavior used by multiple
  packages.
- Feature packages such as `src/book_quality` and `src/research_quality`
  should consume `src/support` helpers instead of keeping local copies of file,
  path, or text-metric logic.
- Runtime packages and adapters should use `src/support` for cwd-aware path
  helpers. `src/core` only owns pure path joins from an explicit base.
- `src/support` must not own domain policy. If a helper needs to know what
  "good research" or "good civic service" means, it belongs in the feature
  package, not here.

## Scripts

- [scripts/build-rabbita-ui.sh](/Users/kq/Workspace/moontown/scripts/build-rabbita-ui.sh)

Purpose:

- format/check/info the Rabbita package
- build the browser bundle
