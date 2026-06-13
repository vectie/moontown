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
- local root directories such as `.moontown`, `.moonclaw`, `_build`, and
  `.mooncakes` are runtime/cache state, not package homes; source ownership is
  still decided by the `src/` package tree
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

- structural package only
- not yet running real experiment loops

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
- drops retired persisted civic-salon jobs during daemon job merge without
  exposing legacy salon ids or kinds as public API

Boundary:

- runtime packages may ask whether a job is a current civic communication,
  book-quality, template-request, projection, or health job.
- runtime packages should not branch on retired `run-civic-salons` or
  `civic-salon` identifiers; those are private scheduler cleanup details.

## Standing Watch Policy

- [src/standing_watch_policy](/Users/kq/Workspace/moontown/src/standing_watch_policy)

Purpose:

- standing-watch task kind, ids, prompts, and target pages
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
- legacy standing-watch retry-accounting classification rules
- review-triage predicates for empty completions, repair-goal still-open
  cycles, and superseded review debt

Boundary:

- `src/town_runtime` may schedule standing-watch work, apply package-owned
  decisions to `TownState`, persist snapshots, and append watcher ledgers.
- `src/town_runtime` should not own standing-watch marker vocabulary, closure
  thresholds, watcher-record matching/status mapping, standing-watch event
  shape, live snapshot stale windows, transient dispatch classification, or
  empty-completion `no_change` marker text, empty review completion summary
  text, legacy retry-accounting predicates, or review-triage predicates.
- `src/town_runtime` should use `src/storage` for generic snapshot-root/base
  path derivation before appending runtime-owned subdirectories such as
  `book-results`.

## Research Policy

- [src/research_policy](/Users/kq/Workspace/moontown/src/research_policy)

Purpose:

- shared research-depth targets and source-screening thresholds
- reusable vocabulary for MoonBook research skill prompts and future quality
  gates without introducing adapter/runtime dependency cycles

Boundary:

- `src/research_policy` owns static research policy constants such as dossier
  word targets, included-source thresholds, discovery attempt limits, and
  bounded fetch command wording.
- `src/adapters/moonbook` may consume those constants while building provider
  requests and generated `SKILL.md` guidance, but should not define its own
  competing research-depth thresholds.
- `src/research_quality` owns runtime quality gates, readiness checks,
  repair/review triggers, and persisted research artifacts. It should consume
  policy vocabulary when thresholds must be shared, but should not become an
  adapter dependency.

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

- `.moontown/town.json`
- `.moontown/standing-goals.json`
- `.moontown/watchers/*.jsonl`
- `.moontown/packets/` when keeper packets are exported

Boundary:

- `src/storage` owns the generic rule that `town.json` in the current
  directory maps to `.moontown`, while `/path/to/town.json` maps to `/path/to`.
- Runtime packages may derive their own feature-specific filenames under that
  base, but should call `storage.snapshot_base_dir(...)` instead of
  reimplementing `dirname(snapshot_path)` fallback logic.
- Feature packages such as `book_templates`, `book_quality`,
  `final_integration`, `visual_projection`, and `town_runtime` should append
  their local filenames to this storage-owned base rather than owning a second
  relative-snapshot fallback.
- `scripts/audit-source-layout.sh` enforces that direct
  `Path::dirname(snapshot_path)` snapshot-base derivation appears only inside
  `src/storage`.

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
- book-harness request/result types

Current persisted file:

- `.moontown/moonbooks.json`

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
- Moontown's canonical generated-site index path is still policy-owned; adapter
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
  MoonClaw worker-profile selection, and MoonClaw-specific prompt/target-page
  adaptation.
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
- reusable execution metadata maps
- reusable step metadata maps

Boundary:

- `src/moonclaw_policy` owns cross-package MoonClaw metadata semantics such as
  no-input/best-effort behavior and standard execution/step metadata fields.
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
- HTML bridge

Boundary:

- `src/ui` owns product-agnostic dashboard, scene layout, and view-policy
  helpers that can be consumed by multiple frontends.
- UI applications should consume shared helpers such as
  `execution_view_stage_for_status(...)` instead of duplicating town execution
  status taxonomies locally.

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
- canonical legacy book labels used only as compatibility/profile keys
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
- reusable goal-text vocabulary for research, research-request, and Wenyu
  routing signals

Boundary:

- `BookPolicy` keeps serialized skill lanes as strings for stable JSON.
- `src/policy` owns legacy book label strings and source-policy strings.
  Downstream packages may consume these constants, but should not duplicate
  literal labels such as `research-book`, `civic-protocol-support`,
  `web-first`, or `book-first`.
- `src/policy/book_policy_catalog.mbt` owns only catalog classification; it
  should not accumulate output, lane, label, or source-policy definitions.
- Downstream packages should call policy classification helpers through
  catalog metadata instead of treating storage prefixes such as `research-` or
  `wenyu-` as architectural book-type gates. Prefixes may remain artifact naming
  conventions, but they are not the product boundary.
- `src/policy` owns default output path and surface constants for composed
  policies.
- `src/policy` owns lane normalization and lane-based skill selection.
- `src/policy` owns pure goal-text vocabulary. Dispatch, roles, runtime, and
  adapters may consume it, but should not redefine research/Wenyu trigger
  words locally.
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
- include `BookPolicy.required_files` in semantic review context pages so AI
  review sees the same artifacts used by health gates
- attach structured `BookPolicy` loop and internal-distance plans to semantic
  review metadata for downstream agent/tool consumers
- preserve those structured policy metadata fields through the runtime review
  dispatch boundary into MoonClaw external proposal packets

Boundary:

- `src/book_quality` consumes book labels, source-policy labels, composed
  policies, and catalog classification from `src/policy`.
- `src/book_quality` owns how quality is assessed and repaired, but it must
  read book output paths from `src/policy.BookPolicy` instead of maintaining a
  parallel generated-site path per book kind.
- Legacy book-type labels may be accepted at this boundary while migration
  continues, but scoring and review context should resolve them through
  policy profiles before deciding required output surfaces.
- `src/book_quality` must not re-export policy vocabulary such as
  `research_type`, `civic_type`, `web_first_policy`, or `book_first_policy`;
  downstream packages should import `src/policy` directly when they need those
  values.
- `src/book_quality` must also not expose pass-through policy lookup or catalog
  classification APIs; runtime packages should call `src/policy` for
  `policy_for_type`, `source_policy_for_type`, and catalog classification.
- operational-book bootstrap and projection templates may live here because
  they support quality/operating-memory workflows, but their type labels still
  come from `src/policy`.
- `src/book_quality` owns quality scoring and repair-action wording, not the
  policy taxonomy itself.
- `src/book_quality` owns score computation from catalog/workspace facts and
  supplied semantic review text. It should parse `ai_quality_score` and
  `next_repair_task`, but it must not read semantic-review result files.
- `src/book_quality` owns review-run ledger/status vocabulary, display row
  construction, active-review counting, and status Markdown rendering from
  explicit runtime observations.
- `src/book_quality` owns pure review-run ledger helpers: empty ledger,
  text parse/serialize, and append/update semantics. It should not load or
  write the ledger file.
- `src/book_quality` owns first-pending semantic-review candidate selection
  from an audit plus an observed completed-review book-id list; it should not
  inspect result files to decide which candidates are completed.
- `src/book_quality_runtime` owns review status observation: loading the run
  ledger file, checking result-file existence, observing current time, and
  passing those facts into `src/book_quality`.
- `src/book_quality_runtime` owns semantic-review completion observation:
  result-file existence checks are converted into completed book ids before
  calling `src/book_quality` candidate-selection policy.
- `src/book_quality_runtime` owns review-run ledger reconciliation IO and
  aggregation: load the ledger, observe filesystem/process/MoonClaw output,
  call package-owned per-run transitions, write accepted results, fold counts,
  and persist changed ledgers.
- `src/book_quality_runtime` owns accepted semantic-review result file writes;
  `src/book_quality` owns the result path contract and review-result parsing.
- `src/book_quality_runtime` owns semantic-review result file reads and the
  runtime `score_book(entry, result_dir)` adapter that feeds observed review
  text into `src/book_quality` scoring.
- `src/book_quality_runtime` owns review-run ledger storage APIs used by
  dispatch, reconciliation, and status rendering: load, append, and write.
- `src/book_quality/scoring_engine.mbt` owns book-type scoring orchestration.
  Reusable draft/finalization/path-scoring internals belong in
  `scoring_primitives.mbt`; civic-service scoring details belong in
  `civic_service_scoring.mbt`.

## Build Pipeline

Key files:

- [src/build_pipeline/bootstrap_task.mbt](/Users/kq/Workspace/moontown/src/build_pipeline/bootstrap_task.mbt)
- [src/build_pipeline/moonclaw_profile.mbt](/Users/kq/Workspace/moontown/src/build_pipeline/moonclaw_profile.mbt)
- [src/build_pipeline/moonclaw_profile_prompts.mbt](/Users/kq/Workspace/moontown/src/build_pipeline/moonclaw_profile_prompts.mbt)
- [src/build_pipeline/build_pipeline_tasks.mbt](/Users/kq/Workspace/moontown/src/build_pipeline/build_pipeline_tasks.mbt)
- [src/build_pipeline/build_pipeline_prompts.mbt](/Users/kq/Workspace/moontown/src/build_pipeline/build_pipeline_prompts.mbt)
- [src/build_pipeline/build_pipeline_artifacts.mbt](/Users/kq/Workspace/moontown/src/build_pipeline/build_pipeline_artifacts.mbt)
- [src/build_pipeline/preseed_workspace.mbt](/Users/kq/Workspace/moontown/src/build_pipeline/preseed_workspace.mbt)
- [src/build_pipeline/source_bundle.mbt](/Users/kq/Workspace/moontown/src/build_pipeline/source_bundle.mbt)
- [src/build_pipeline/codex_acp_target.mbt](/Users/kq/Workspace/moontown/src/build_pipeline/codex_acp_target.mbt)
- [src/build_pipeline/local_execution.mbt](/Users/kq/Workspace/moontown/src/build_pipeline/local_execution.mbt)

Purpose:

- own Wenyu bootstrap and build task contracts for bootstrap ingest,
  implementation backlog, code patch, and asset/projection work
- own the Wenyu MoonClaw build-controller profile, output contract, ACP step
  metadata, preferred skills, no-input policy, and execute/review prompts
- own Wenyu build prompts and fallback artifact materialization
- own Wenyu bootstrap workspace preseed: PRD/vision copies, research request,
  source hints, mounted source snapshots, generated Wenyu skills, civic seed,
  MoonClaw build profile, and Codex ACP target registration
- own Wenyu build/civic task-plan helpers: Wenyu detection, build-readiness
  paths, local fallback-task predicates, build task limit, positive task-limit
  normalization, and civic-service task merge that removes bootstrap duplicates
- own local Wenyu build fallback execution-record construction, including
  packet ids, local packet paths, materializer proposal id, skill paths, review
  requirement, stale window, and output contract
- keep build-stage target pages, worker roles, priorities, and review flags
  close to the build feature instead of the town scheduler

Boundary:

- `src/town_runtime` may decide when a Wenyu book is ready for bootstrap/build,
  supply the current repo root, and ask this package to preseed or build a
  Wenyu workspace.
- `src/build_pipeline` owns the Wenyu bootstrap/build task contracts and may
  compose target pages through `src/policy`, `src/research_quality`, and civic
  service definitions.
- `src/town_runtime` should not own Wenyu build output-contract ids, MoonClaw
  profile JSON, ACP step metadata, source-bundle manifests, source-hint pages,
  generated build-skill installation, Codex ACP target JSON, or build/review
  prompt templates. It also should not own Wenyu build/civic task merge policy
  beyond adapting package-owned tasks into the generic goal-book plan shape, or
  local build fallback execution-record semantics beyond dispatching to this
  package.

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
- Wenyu build skill file materialization belongs to `src/build_pipeline`;
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
- expose civic-building actions that let Moontown open reports, tools, and
  Moondesk configuration surfaces

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
- [src/research_quality/persistence_payload.mbt](/Users/kq/Workspace/moontown/src/research_quality/persistence_payload.mbt)
- [src/research_quality/bootstrap_artifacts.mbt](/Users/kq/Workspace/moontown/src/research_quality/bootstrap_artifacts.mbt)
- [src/research_quality/quality_gate_events.mbt](/Users/kq/Workspace/moontown/src/research_quality/quality_gate_events.mbt)
- [src/research_quality_runtime/review_trigger.mbt](/Users/kq/Workspace/moontown/src/research_quality_runtime/review_trigger.mbt)

Purpose:

- evaluate research-readiness and quality gate gaps
- own the generic research bootstrap ingest task contract, prompt, target pages,
  review requirement, and worker role
- detect weak source depth, process noise, generic generated-site projections,
  and missing topic-specific wiki materialization
- define the canonical `raw/bootstrap/QUALITY_REPAIR.md` path and Markdown
  contract for in-place research quality repair
- let the runtime package write and resolve that repair trigger file
- translate completed research bootstrap artifacts into persistence summaries,
  artifact paths, and MoonBook memory candidates
- own research quality-gate execution-summary suffixes and recovery/review
  event wording
- expose quality judgments that town runtime can use without reimplementing
  research semantics

Boundary:

- research quality owns the generic research bootstrap contract, judgment,
  repair-trigger file contract, repair wording, topic-specific signal checks,
  bootstrap artifact reading, persistence-summary wording, artifact list, and
  memory-candidate target-page contract. It also owns quality-gate and recovered
  bootstrap message semantics.
- `src/research_quality_runtime` owns the file side effects for active repair
  trigger writes and resolved-trigger writes.
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
- [src/civic_runtime/civic_service_persist.mbt](/Users/kq/Workspace/moontown/src/civic_runtime/civic_service_persist.mbt)
- [src/civic_runtime/civic_workspace_projection.mbt](/Users/kq/Workspace/moontown/src/civic_runtime/civic_workspace_projection.mbt)
- [src/civic_runtime/civic_communication_scenario_workspace.mbt](/Users/kq/Workspace/moontown/src/civic_runtime/civic_communication_scenario_workspace.mbt)

Purpose:

- `src/civic` owns service definitions, target page contracts, skill paths,
  protocol vocabulary, civic helper paths, and civic service result-path
  derivation.
- `src/civic` owns civic communication reducer contract helpers: reducer input,
  participant, output, blocker, step-kind, output-contract id/type, and
  MoonClaw profile-family names.
- `src/civic` exposes generic civic communication skill text and protocol note
  helpers. Public helper names should use communication-pattern vocabulary;
  `research-salon` remains one pattern constructor, not the skill API.
- `src/civic` owns communication schedule and round-record DTOs. Public records
  identify the scheduled scenario with `scenario_id`; they should not encode
  `salon` as the generic record vocabulary.
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
  not in the browser main package.

## Support

- [src/support](/Users/kq/Workspace/moontown/src/support)

Purpose:

- generic file I/O and parent-directory helpers
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
- `src/support` must not own domain policy. If a helper needs to know what
  "good research" or "good civic service" means, it belongs in the feature
  package, not here.

## Scripts

- [scripts/build-rabbita-ui.sh](/Users/kq/Workspace/moontown/scripts/build-rabbita-ui.sh)

Purpose:

- format/check/info the Rabbita package
- build the browser bundle
