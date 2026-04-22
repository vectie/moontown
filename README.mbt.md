# Moontown

> MoonBit-native town control plane + embedded strategic roles + scene dashboard + Rabbita operator UI

`MoonBit` `Town Orchestration` `MoonBook Harness` `MoonClaw Proposal Packets` `Mayor` `Keeper` `Routing` `Health` `Storage` `Scene UI` `Rabbita`

Moontown is the town-level orchestration layer above multiple `moonbook`
domains and multiple `moonclaw` runtimes.

It is designed for:

- town-wide routing and scheduling
- domain isolation across multiple books
- embedded role-specialized planning runtimes
- long-lived town state and snapshots
- scene-based operator visibility
- browser-facing simulation dashboards

## What Moontown Feels Like

```text
 moonbook catalog / keeper packets / mayor
  -> seed a town
  -> turn book-local tasks into keeper proposal packets
  -> import packets into MoonClaw proposal/run lifecycle
  -> poll terminal run state and persist results back into MoonBook
  -> write a mayor-level synthesis across parallel research lanes
  -> inspect health, anomalies, and patrol state
  -> render the town as a live scene
  -> evolve toward a 24/7 social-experiment control plane
```

Moontown is strongest when you want one system to hold together:

- global orchestration
- per-book isolation
- strategic role reasoning
- operator-facing visibility
- a town-shaped UI instead of a flat task list

## Current Status

Implemented today:

- persisted town bootstrap in `.moontown/town.json`
- persisted moonbook catalog in `.moontown/moonbooks.json`
- `BookProvider` abstraction for town bootstrap
- book-harness-shaped moonbook adapter
- external proposal packet and proposal/run receipt lifecycle
- run polling, result persistence, and review-queue surfacing for goal runs
- mayor-level cross-book research synthesis under `.moontown/town-synthesis/`
- town quality gates for provisional or non-lane-specific research output
- strategic `Mayor` role adapter over embedded moonclaw runtime metadata
- routing, isolation, scheduler, health, and storage packages
- renderer-agnostic scene dashboard model
- Rabbita live simulation frontend
- original example SVG scene assets

Still stubbed:

- long-running daemon patrol and recovery loop
- experiment lifecycle execution
- real backend/frontend sync

So the current repo is a control-plane-first prototype, not yet a fully live
24/7 town runtime.

## Current Capabilities

- `core` town, book, worker, task, and event modeling
- `dispatch` routing and isolation decisions
- `storage` snapshot persistence
- `health` anomaly and recovery reporting
- `scheduler` tick planning
- `roles` strategic `Mayor` role adapter
- `adapters/moonbook` persisted book catalog plus real MoonBook CLI-backed harness requests
- `adapters/moonclaw` embedded runtime profiles plus real MoonClaw proposal import, run, and polling boundary
- `ui` scene layout, dashboard projection, and HTML render bridge
- `ui/rabbita-town` live browser dashboard with:
  - tick loop
  - pause/resume/step controls
  - strategy switching
  - runtime summary bar
  - packet/import/run/persist/review stage rail
  - moving worker avatars
  - selection and inspector state
  - budget/energy/pressure/stability metrics
  - activity feed and anomaly surfacing
  - scroll-safe scene viewport on smaller screens

## Main Subsystems

- `core`
  pure town model and provider abstractions
- `dispatch`
  routing and isolation policy
- `experiment`
  experiment model scaffold
- `health`
  anomaly detection and recovery suggestions
- `scheduler`
  tick planning and due-work collection
- `storage`
  snapshot and checkpoint persistence
- `roles`
  strategic mayor role adapter
- `adapters/moonbook`
  moonbook catalog and book-harness boundary
- `adapters/moonclaw`
  embedded runtime profiles plus real MoonClaw proposal import, run, and polling boundary
- `ui`
  scene contract, dashboard model, and render model
- `ui/rabbita-town`
  browser simulation dashboard

## Embedded Role Model

Moontown does not expose a raw generic worker brain directly to town code.

The intended role split is:

- `Mayor`
  - strategic town runtime
  - planner-only envelope
  - limited tools
  - global memory scope
- `keeper`
  - book-local planning/runtime handoff target
  - domain-scoped memory and tools
- worker claws
  - execution runtime profiles

The design intent is:

- `moontown` calls `Mayor.decide_dispatch(...)`
- `moontown` calls `Mayor.patrol(...)`
- `moontown` produces keeper handoff packets for book-local planning
- `moontown` tracks packet, proposal, and run lifecycle records in town state

That keeps:

- town orchestration in `moontown`
- harness and memory control in `moonbook`
- execution-heavy behavior in `moonclaw`

## Quick Start

From the repo root:

```bash
cd ~/Workspace/moontown
```

Run the text dashboard:

```bash
moon run cmd/main
```

Validate the module:

```bash
moon check
moon test
moon info
moon fmt
```

Build the Rabbita frontend:

```bash
./scripts/build-rabbita-ui.sh
```

Or work directly in the frontend package:

```bash
cd ui/rabbita-town
npm install
npm run dev
```

## Runtime Flow

Current bootstrap path:

```text
moonbook catalog
  -> book task batch
  -> keeper packet
  -> MoonClaw proposal import
  -> confirmed MoonClaw run
  -> terminal run polling
  -> MoonBook result persistence
  -> book generated site
  -> town snapshot / dashboard / frontend
```

Current strategic path:

```text
TownTask
  -> Mayor.decide_dispatch(...)
  -> keeper handoff
  -> proposal packet lifecycle record
```

Current execution contract path:

```text
BookTask
  -> WorkerContextBundle
  -> ExternalProposalPacket
  -> ProposalImportReceipt
  -> ProposalPollResponse
  -> TaskExecutionRecord
  -> MoonBook persisted result
  -> dashboard / frontend
```

Current research goal path:

```text
user goal naming multiple subjects
  -> Mayor splits isolated research lanes
  -> each lane bootstraps verified research coverage
  -> MoonClaw gathers web/local evidence into raw/bootstrap/*
  -> MoonBook materializes durable wiki coverage and generated sites
  -> Moontown applies quality gates
  -> mayor writes .moontown/town-synthesis/*.md
```

Current UI path:

```text
TownState
  -> DashboardModel
  -> SceneRenderModel
  -> Rabbita simulation dashboard
```

## Town Scene

The semantic town scene lives in:

- `ui/scene_layout.mbt`
- `ui/dashboard.mbt`
- `ui/scene_render.mbt`

Current scene places:

- Town Gate
- City Hall
- Moonbook / Coding
- Moonbook / Finance
- Worker Yard
- Anomaly Corner

Current asset folders:

- `ui/assets/backgrounds/`
- `ui/assets/buildings/`
- `ui/assets/actors/`
- `ui/assets/props/`
- `ui/assets/effects/`

The current assets are original `moontown` starter SVGs, not copied `sou`
assets.

## Rabbita Frontend

`ui/rabbita-town/` is the browser-facing simulation dashboard. It is not a game
engine, but it is already game-adjacent in structure:

- live tick loop
- moving worker avatars
- packet / proposal / run lifecycle visibility
- stage-by-stage execution rail
- strategy controls
- resource feedback loops
- selection and inspector state
- activity and anomaly visibility
- responsive scene viewport with scroll instead of clipping

The current frontend is best understood as a live simulation dashboard over the
town model.

The generated MoonBook workspace site is a separate surface. If a live run
still shows generic branding or dead projection links under
`.moontown/books/*/site/`, that bug belongs to the MoonBook site generator, not
to the Moontown Rabbita dashboard.

## Docs

Detailed docs:

- [docs/USAGE.md](/Users/kq/Workspace/moontown/docs/USAGE.md)
- [docs/ARCHITECTURE.md](/Users/kq/Workspace/moontown/docs/ARCHITECTURE.md)
- [docs/PACKAGES.md](/Users/kq/Workspace/moontown/docs/PACKAGES.md)
- [docs/FRONTEND.md](/Users/kq/Workspace/moontown/docs/FRONTEND.md)
- [docs/DEVELOPMENT.md](/Users/kq/Workspace/moontown/docs/DEVELOPMENT.md)
