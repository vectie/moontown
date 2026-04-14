# Package Map

This repo is organized as multiple MoonBit packages under one module.

## Root Module

- [moon.mod.json](/Users/kq/Workspace/moontown/moon.mod.json)

Module name:

- `vectie/moontown`

## Root Package

Primary root package files:

- [moon.pkg](/Users/kq/Workspace/moontown/moon.pkg)
- [moontown.mbt](/Users/kq/Workspace/moontown/moontown.mbt)
- [moontown_test.mbt](/Users/kq/Workspace/moontown/moontown_test.mbt)
- [moontown_wbtest.mbt](/Users/kq/Workspace/moontown/moontown_wbtest.mbt)

Purpose:

- convenience facade for demo bootstrap
- current text dashboard entry surface
- package-level tests

## Core

- [core/types.mbt](/Users/kq/Workspace/moontown/core/types.mbt)

Purpose:

- core town types
- `BookProvider` abstraction
- town/book/worker/task/event records

Important public types:

- `TownConfig`
- `BookRef`
- `WorkerRef`
- `TownTask`
- `TaskExecutionStatus`
- `AssignmentPlan`
- `TaskExecutionRecord`
- `TownEvent`
- `TownState`
- `BookProvider`

## Dispatch

- [dispatch/router.mbt](/Users/kq/Workspace/moontown/dispatch/router.mbt)

Purpose:

- route tasks to workers
- choose assignment vs escalation vs deferral
- choose isolation modes

## Experiment

- [experiment/run.mbt](/Users/kq/Workspace/moontown/experiment/run.mbt)

Purpose:

- experiment data model scaffold

Current status:

- structural package only
- not yet running real experiment loops

## Health

- [health/report.mbt](/Users/kq/Workspace/moontown/health/report.mbt)

Purpose:

- health inspection
- anomaly detection
- recovery action modeling

## Scheduler

- [scheduler/daemon.mbt](/Users/kq/Workspace/moontown/scheduler/daemon.mbt)

Purpose:

- collect due work
- plan one town tick
- summarize tick actions

Current status:

- planning model only
- not yet a real long-lived daemon

## Storage

- [storage/store.mbt](/Users/kq/Workspace/moontown/storage/store.mbt)

Purpose:

- snapshot persistence
- checkpoint model

Current persisted files:

- `.moontown/town.json`
- `.moontown/packets/` when keeper packets are exported

## Roles

- [roles/mayor.mbt](/Users/kq/Workspace/moontown/roles/mayor.mbt)

Purpose:

- strategic `Mayor` role adapter
- dispatch packets
- patrol packets
- keeper handoff packets
- keeper proposal packet preparation

This package is where town code stops talking to raw agent runtime metadata and
starts talking to a role-specific API.

## Moonbook Adapter

- [adapters/moonbook/client.mbt](/Users/kq/Workspace/moontown/adapters/moonbook/client.mbt)

Purpose:

- persisted moonbook catalog
- book provider implementation
- book-harness request/result types

Current persisted file:

- `.moontown/moonbooks.json`

Current real pieces:

- catalog read/write
- catalog-backed `BookProvider`
- `accept_goal(...)`
- `produce_task_batch(...)`
- `hydrate_worker_context(...)`
- `persist_result(...)`
- `summarize_state(...)`
- `report_health(...)`

## Moonclaw Adapter

- [adapters/moonclaw/client.mbt](/Users/kq/Workspace/moontown/adapters/moonclaw/client.mbt)

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
- `import_packet(...)`
- `poll_run(...)`

Important public types:

- `ExternalProposalPacket`
- `ProposalImportReceipt`

## UI

Key files:

- [ui/scene_layout.mbt](/Users/kq/Workspace/moontown/ui/scene_layout.mbt)
- [ui/dashboard.mbt](/Users/kq/Workspace/moontown/ui/dashboard.mbt)
- [ui/scene_render.mbt](/Users/kq/Workspace/moontown/ui/scene_render.mbt)

Purpose:

- semantic town scene layout
- dashboard state projection
- renderer-facing scene model
- HTML bridge

## Rabbita Frontend

Key files:

- [ui/rabbita-town/main/main.mbt](/Users/kq/Workspace/moontown/ui/rabbita-town/main/main.mbt)
- [ui/rabbita-town/styles.css](/Users/kq/Workspace/moontown/ui/rabbita-town/styles.css)
- [ui/rabbita-town/index.html](/Users/kq/Workspace/moontown/ui/rabbita-town/index.html)
- [ui/rabbita-town/package.json](/Users/kq/Workspace/moontown/ui/rabbita-town/package.json)
- [ui/rabbita-town/vite.config.js](/Users/kq/Workspace/moontown/ui/rabbita-town/vite.config.js)

Purpose:

- browser implementation of the town dashboard
- live simulation UI
- Vite build/dev workflow

## Scripts

- [scripts/build-rabbita-ui.sh](/Users/kq/Workspace/moontown/scripts/build-rabbita-ui.sh)

Purpose:

- format/check/info the Rabbita package
- build the browser bundle
