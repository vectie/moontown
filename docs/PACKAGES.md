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

## Root Package

Primary root package files:

- [src/moon.pkg](/Users/kq/Workspace/moontown/src/moon.pkg)
- [src/facade.mbt](/Users/kq/Workspace/moontown/src/facade.mbt)
- [src/town_runtime](/Users/kq/Workspace/moontown/src/town_runtime)
- [src/integration_tests](/Users/kq/Workspace/moontown/src/integration_tests)

Purpose:

- `src/facade.mbt` preserves the public `vectie/moontown` API.
- `src/town_runtime` owns demo bootstrap, dashboard rendering, goal runs,
  daemon entry points, standing-watch dispatch, and supervision internals.
- `src/town_runtime` may schedule package-provided task contracts, but
  feature-specific task contracts should live in the owning feature package.
- `src/integration_tests` owns cross-package API and skill-quality tests.
- No implementation package should be added directly at repository root.

## Core

- [src/core/types.mbt](/Users/kq/Workspace/moontown/src/core/types.mbt)

Purpose:

- core town types
- `BookProvider` abstraction
- town/book/worker/task/event records

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

## Dispatch

- [src/dispatch/router.mbt](/Users/kq/Workspace/moontown/src/dispatch/router.mbt)

Purpose:

- route tasks to workers
- choose assignment vs escalation vs deferral
- choose isolation modes

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

## Standing Watch Policy

- [src/standing_watch_policy](/Users/kq/Workspace/moontown/src/standing_watch_policy)

Purpose:

- standing-watch task kind, ids, prompts, and target pages
- strict watcher accounting markers and marker parsers
- MoonBook standing-watch history parsing and provider-decision collapse policy
- material-delta metrics and watcher-record decision selection
- keeper auto-triage/recovery closure policy, thresholds, and summary wording

Boundary:

- `src/town_runtime` may schedule standing-watch work, apply package-owned
  decisions to `TownState`, persist snapshots, and append watcher ledgers.
- `src/town_runtime` should not own standing-watch marker vocabulary, closure
  thresholds, or auto-triage/recovery summary text.

## Storage

- [src/storage/store.mbt](/Users/kq/Workspace/moontown/src/storage/store.mbt)

Purpose:

- snapshot persistence
- checkpoint model
- standing-goal registry persistence
- watcher ledger persistence

Current persisted files:

- `.moontown/town.json`
- `.moontown/standing-goals.json`
- `.moontown/watchers/*.jsonl`
- `.moontown/packets/` when keeper packets are exported

## Roles

- [src/roles/mayor.mbt](/Users/kq/Workspace/moontown/src/roles/mayor.mbt)

Purpose:

- strategic `Mayor` role adapter
- dispatch packets
- patrol packets
- standing-goal target book routing
- keeper handoff packets
- keeper proposal packet preparation

This package is where town code stops talking to raw agent runtime metadata and
starts talking to a role-specific API.

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
- HTML bridge

## Loop Policy

Key files:

- [src/policy/book_policy.mbt](/Users/kq/Workspace/moontown/src/policy/book_policy.mbt)
- [src/policy/book_policy_paths.mbt](/Users/kq/Workspace/moontown/src/policy/book_policy_paths.mbt)
- [src/policy/book_policy_lanes.mbt](/Users/kq/Workspace/moontown/src/policy/book_policy_lanes.mbt)
- [src/policy/book_policy_loop.mbt](/Users/kq/Workspace/moontown/src/policy/book_policy_loop.mbt)
- [src/policy/book_policy_distance.mbt](/Users/kq/Workspace/moontown/src/policy/book_policy_distance.mbt)

Purpose:

- typed `BookPolicy` model
- policy-owned default projection paths and surface names
- canonical `control`, `execute`, and `tend` lane parsing
- policy-composed loop plans and health gates
- policy-derived internal-distance plans for information, recognition, and
  decisiveness

Boundary:

- `BookPolicy` keeps serialized skill lanes as strings for stable JSON.
- `src/policy` owns default output path and surface constants for composed
  policies.
- `src/policy` owns lane normalization and lane-based skill selection.
- `src/policy` owns the internal-distance growth-vector view; downstream
  packages may render it but should not redefine how execute/tend/quality
  map to information, recognition, and decisiveness.
- downstream packages may read lane text but should not redefine lane semantics.

## Build Pipeline

Key files:

- [src/build_pipeline/build_pipeline_tasks.mbt](/Users/kq/Workspace/moontown/src/build_pipeline/build_pipeline_tasks.mbt)
- [src/build_pipeline/build_pipeline_prompts.mbt](/Users/kq/Workspace/moontown/src/build_pipeline/build_pipeline_prompts.mbt)
- [src/build_pipeline/build_pipeline_artifacts.mbt](/Users/kq/Workspace/moontown/src/build_pipeline/build_pipeline_artifacts.mbt)

Purpose:

- own Wenyu build task contracts for implementation backlog, code patch, and
  asset/projection work
- own Wenyu build prompts and fallback artifact materialization
- keep build-stage target pages, worker roles, priorities, and review flags
  close to the build feature instead of the town scheduler

Boundary:

- `src/town_runtime` may decide when a Wenyu book is ready for build and supply
  the current repo root.
- `src/build_pipeline` owns the build task contract and may compose target pages
  through `src/policy` and civic service definitions.

## PlanBook Policy And Runtime

Key files:

- [src/planbook_policy/run_status.mbt](/Users/kq/Workspace/moontown/src/planbook_policy/run_status.mbt)
- [src/planbook_policy/repair_commands.mbt](/Users/kq/Workspace/moontown/src/planbook_policy/repair_commands.mbt)
- [src/planbook_runtime/planbook_repair_run_status.mbt](/Users/kq/Workspace/moontown/src/planbook_runtime/planbook_repair_run_status.mbt)
- [src/planbook_runtime/planbook_repair_result.mbt](/Users/kq/Workspace/moontown/src/planbook_runtime/planbook_repair_result.mbt)

Purpose:

- `src/planbook_policy` owns pure PlanBook contracts, repair command policy,
  and raw MoonClaw run-status normalization.
- `src/planbook_runtime` owns workspace IO, run reconciliation, and
  evidence-aware repair lifecycle decisions.

Boundary:

- raw MoonClaw `Succeeded` means the external run completed.
- `planbook_runtime` may still mark a repair task failed when a completed run
  lacks required PlanBook repair evidence.
- do not encode missing-evidence decisions in raw status normalization.
- default generated-site path semantics belong to `src/policy`; PlanBook
  runtime consumes `policy.default_generated_site_projection_path()` rather
  than redefining the projection path.

## Course Book

Key files:

- [src/course_book/core.mbt](/Users/kq/Workspace/moontown/src/course_book/core.mbt)
- [src/course_book/content.mbt](/Users/kq/Workspace/moontown/src/course_book/content.mbt)
- [src/course_book/projection_content.mbt](/Users/kq/Workspace/moontown/src/course_book/projection_content.mbt)

Purpose:

- bootstrap the Wenyu beginner course MoonBook workspace
- keep course output course-shaped rather than research-shaped
- write generated course projection content

Boundary:

- course-specific content and course workspace files belong here.
- default generated-site path semantics belong to `src/policy`; CourseBook
  consumes `policy.default_generated_site_projection_path()` rather than
  redefining the projection path.

## Cookbook

Key files:

- [src/cookbook/workspace.mbt](/Users/kq/Workspace/moontown/src/cookbook/workspace.mbt)
- [src/cookbook/manifest.mbt](/Users/kq/Workspace/moontown/src/cookbook/manifest.mbt)
- [src/cookbook/pages.mbt](/Users/kq/Workspace/moontown/src/cookbook/pages.mbt)

Purpose:

- bootstrap the stable-state control MoonBook workspace
- materialize durable definitions, ownership rules, operating procedures, and
  codebase describer pages
- render cookbook status and stable-state drift accounting

Boundary:

- stable-state definitions, cookbook page content, manifest accounting, and
  cookbook status wording belong here.
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

Purpose:

- bootstrap domain-specific PDF watcher MoonBook workspaces
- install source-first analysis contracts, skills, schemas, and watcher state
- write the initial generated evidence-watch projection

Boundary:

- PDF source discovery, extraction, analysis-method, and notification contract
  semantics belong here.
- default generated-site path semantics belong to `src/policy`; PDF Evidence
  Watch consumes `policy.default_generated_site_projection_path()` rather than
  redefining the projection path.

## Research Quality

Key files:

- [src/research_quality/readiness.mbt](/Users/kq/Workspace/moontown/src/research_quality/readiness.mbt)
- [src/research_quality/projection_gaps.mbt](/Users/kq/Workspace/moontown/src/research_quality/projection_gaps.mbt)
- [src/research_quality/source_depth_gaps.mbt](/Users/kq/Workspace/moontown/src/research_quality/source_depth_gaps.mbt)
- [src/research_quality/review_trigger.mbt](/Users/kq/Workspace/moontown/src/research_quality/review_trigger.mbt)

Purpose:

- evaluate research-readiness and quality gate gaps
- detect weak source depth, process noise, generic generated-site projections,
  and missing topic-specific wiki materialization
- write and resolve the canonical `raw/bootstrap/QUALITY_REPAIR.md` repair
  trigger for in-place research quality repair
- expose quality judgments that town runtime can use without reimplementing
  research semantics

Boundary:

- research quality owns the judgment, repair-trigger file contract, repair
  wording, and topic-specific signal checks.
- `src/town_runtime` may decide that a repair trigger should be written or
  resolved, but should not own the trigger path or prose.
- default generated-site path semantics belong to `src/policy`; Research
  Quality consumes `policy.default_generated_site_projection_path()` rather
  than redefining the projection path.

## Civic Definitions And Runtime

Key files:

- [src/civic/services.mbt](/Users/kq/Workspace/moontown/src/civic/services.mbt)
- [src/civic/services_paths.mbt](/Users/kq/Workspace/moontown/src/civic/services_paths.mbt)
- [src/civic_runtime/civic_workspace_projection.mbt](/Users/kq/Workspace/moontown/src/civic_runtime/civic_workspace_projection.mbt)
- [src/civic_runtime/civic_salon_scenario_workspace.mbt](/Users/kq/Workspace/moontown/src/civic_runtime/civic_salon_scenario_workspace.mbt)

Purpose:

- `src/civic` owns service definitions, target page contracts, skill paths,
  protocol vocabulary, and civic helper paths.
- `src/civic_runtime` owns workspace writes, ledgers, generated pages, and
  scenario execution persistence.

Boundary:

- civic runtime writes generated pages through `@civic` path helpers.
- `src/civic` delegates default generated-site semantics to `src/policy`;
  civic modules should not redefine the generated-site path locally.

## Daemon Runtime Policy And Runtime

Key files:

- [src/daemon_runtime_policy/health.mbt](/Users/kq/Workspace/moontown/src/daemon_runtime_policy/health.mbt)
- [src/daemon_runtime_policy/transitions.mbt](/Users/kq/Workspace/moontown/src/daemon_runtime_policy/transitions.mbt)
- [src/daemon_runtime/daemon_runtime_inspection.mbt](/Users/kq/Workspace/moontown/src/daemon_runtime/daemon_runtime_inspection.mbt)
- [src/town_runtime/daemon_runtime_supervise.mbt](/Users/kq/Workspace/moontown/src/town_runtime/daemon_runtime_supervise.mbt)

Purpose:

- `src/daemon_runtime_policy` owns daemon state vocabulary, health labels,
  heartbeat staleness, transition builders, doctor actions, and the pure
  `daemon_runtime_should_spawn_worker(...)` supervision predicate.
- `src/daemon_runtime` owns filesystem/process inspection, PID files, logs,
  launchd integration, request files, and runtime state persistence.
- `src/town_runtime` owns the town-level supervisor loop and worker spawning.

Boundary:

- supervisor loops must ask `daemon_runtime_policy` whether worker spawn is due.
- town runtime may spawn or stop processes, but should not compare raw daemon
  status strings such as `missing`, `stopped`, `running`, or `ticking`.

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

## Scripts

- [scripts/build-rabbita-ui.sh](/Users/kq/Workspace/moontown/scripts/build-rabbita-ui.sh)

Purpose:

- format/check/info the Rabbita package
- build the browser bundle
