# Usage Guide

This guide is the practical “how to use everything” entry for the current
`moontown` repo.

It covers:

- the text dashboard
- the persisted town state
- the moonbook catalog
- the keeper packet and proposal/run lifecycle
- parallel research goal runs
- mayor-level town synthesis
- the scene assets
- the Rabbita frontend
- the current limits of the repo

## What You Can Use Right Now

Right now, `moontown` is usable as:

- a MoonBit town model
- a persisted demo bootstrap
- a real MoonBook CLI-backed planning and context-hydration boundary
- a real MoonClaw CLI-backed proposal import/run/polling boundary
- a real MoonBook result-persistence and generated-site refresh boundary for goal runs
- a mayor-level synthesis and quality-gate surface for parallel research lanes
- a scene-based dashboard
- a Rabbita simulation frontend
- a starter asset pipeline

It is not yet usable as:

- a real 24/7 autonomous town daemon
- a durable multi-day restart/recovery supervisor
- a backend-synced browser UI

So the right way to use the repo today is as a real goal-run control plane plus
a live architectural and frontend prototype. It can launch and observe bounded
MoonBook/MoonClaw research runs, but it is not yet a days-long daemon.

## 1. Run The Text Dashboard

From the repo root:

```bash
moon run cmd/main
```

What you get:

- a text dashboard
- current town map summary
- books, workers, tasks
- executions with packet / proposal / run ids
- real failure details when MoonBook or MoonClaw rejects a handoff
- mayor role summary
- scheduler tick summary
- snapshot summary

The CLI entry is:

- [cmd/main/main.mbt](/Users/kq/Workspace/moontown/cmd/main/main.mbt)

The root demo/bootstrap surface is:

- [moontown.mbt](/Users/kq/Workspace/moontown/moontown.mbt)

## 2. Use The Persisted Town State

The demo town persists runtime bootstrap files under:

- `.moontown/moonbooks.json`
- `.moontown/town.json`
- `.moontown/packets/` when packet files are exported

What they do:

- `.moontown/moonbooks.json`
  - stores the available books loaded into town bootstrap
- `.moontown/town.json`
  - stores the seeded town snapshot

Current persistence code:

- [adapters/moonbook/client.mbt](/Users/kq/Workspace/moontown/adapters/moonbook/client.mbt)
- [storage/store.mbt](/Users/kq/Workspace/moontown/storage/store.mbt)

If those files do not exist, `moontown` creates them during bootstrap. It also
initializes missing MoonBook workspaces and seeds the MoonBook MoonClaw
extension pack before attempting proposal import.

## 3. Edit The Town Books

The simplest real customization point is the moonbook catalog.

Edit:

- `.moontown/moonbooks.json`

Each catalog entry describes one book:

- `id`
- `name`
- `purpose`
- `workspace_root`
- `memory_scope`
- `tags`
- `skills`

Current defaults are created by:

- `default_catalog()` in [adapters/moonbook/client.mbt](/Users/kq/Workspace/moontown/adapters/moonbook/client.mbt)

Current built-in books:

- `coding`
- `finance`

If you want a different town shape, this is the first file to change.

## 4. Understand The Current Town Model

Core town types live in:

- [core/types.mbt](/Users/kq/Workspace/moontown/core/types.mbt)

Important concepts:

- `TownConfig`
- `BookRef`
- `WorkerRef`
- `TownTask`
- `TaskExecutionStatus`
- `TaskExecutionRecord`
- `TownEvent`
- `TownState`
- `BookProvider`

This is the current ownership split:

- town data model
  - `core/`
- dispatch
  - `dispatch/`
- health
  - `health/`
- scheduling
  - `scheduler/`
- persistence
  - `storage/`

If you want to “use the system as code”, start there.

## 5. Use The Mayor Role

The strategic town runtime is modeled as `Mayor`.

Code:

- [roles/mayor.mbt](/Users/kq/Workspace/moontown/roles/mayor.mbt)

Current Mayor capabilities:

- decide dispatch
- run patrol
- produce keeper handoff packets
- prepare keeper proposal packets

Current embedded moonclaw runtime metadata:

- [adapters/moonclaw/client.mbt](/Users/kq/Workspace/moontown/adapters/moonclaw/client.mbt)

Important current functions:

- `Mayor.decide_dispatch(...)`
- `Mayor.patrol(...)`
- `Mayor.handoff_to_keeper(...)`
- `Mayor.prepare_keeper_packet(...)`

This is the right entry if you want to extend strategic orchestration.

## 6. Use The Scene Dashboard Model

The renderer-agnostic town scene lives in:

- [ui/scene_layout.mbt](/Users/kq/Workspace/moontown/ui/scene_layout.mbt)
- [ui/dashboard.mbt](/Users/kq/Workspace/moontown/ui/dashboard.mbt)
- [ui/scene_render.mbt](/Users/kq/Workspace/moontown/ui/scene_render.mbt)

Current flow:

```text
TownState -> DashboardModel -> SceneRenderModel -> HTML / Rabbita
```

Current semantic places:

- Town Gate
- City Hall
- Moonbook / Coding
- Moonbook / Finance
- Worker Yard
- Anomaly Corner

Use this layer when you want to:

- change the town layout
- add new scene areas
- change asset slots
- add more dashboard-projected state

## 7. Use The Scene Assets

Current example assets live under:

- [ui/assets/backgrounds](/Users/kq/Workspace/moontown/ui/assets/backgrounds)
- [ui/assets/buildings](/Users/kq/Workspace/moontown/ui/assets/buildings)
- [ui/assets/actors](/Users/kq/Workspace/moontown/ui/assets/actors)
- [ui/assets/props](/Users/kq/Workspace/moontown/ui/assets/props)
- [ui/assets/effects](/Users/kq/Workspace/moontown/ui/assets/effects)

Current starter assets:

- `backgrounds/town-square.svg`
- `buildings/city-hall.svg`
- `buildings/book-house-coding.svg`
- `buildings/book-house-finance.svg`
- `actors/mayor-claw.svg`
- `actors/keeper-claw.svg`
- `actors/worker-claw.svg`
- `props/worker-yard.svg`
- `props/gate-sign.svg`
- `effects/anomaly-signal.svg`

These are original starter examples. You can replace them with richer art while
keeping the same scene keys.

## 8. Use The Keeper Packet Lifecycle

The current town model now tracks:

- keeper packet id
- packet path
- proposal id
- run id
- execution status

These lifecycle records live in:

- `TownState.executions`
- `TaskExecutionRecord`

The relevant code is in:

- [core/types.mbt](/Users/kq/Workspace/moontown/core/types.mbt)
- [adapters/moonbook/client.mbt](/Users/kq/Workspace/moontown/adapters/moonbook/client.mbt)
- [adapters/moonclaw/client.mbt](/Users/kq/Workspace/moontown/adapters/moonclaw/client.mbt)
- [roles/mayor.mbt](/Users/kq/Workspace/moontown/roles/mayor.mbt)

The current lifecycle is:

```text
book task
  -> keeper packet
  -> imported proposal
  -> confirmed run
  -> run polling
  -> MoonBook persistence
  -> generated site refresh
  -> mayor quality gate
  -> review or complete
```

Current execution statuses include:

- `PacketReady`
- `ProposalImported`
- `RunConfirmed`
- `Running`
- `AwaitingPersistence`
- `ReviewQueued`
- `Completed`
- `Failed`

## 9. Run A Parallel Research Goal

The goal runner can split a multi-topic research request into isolated
MoonBook lanes. For example:

```bash
moon run cmd/main -- run "research moontown, moonbook, and moonclaw"
```

For that goal, the mayor currently creates one book lane per named subject:

- `research-moontown`
- `research-moonbook`
- `research-moonclaw`

Each lane gets its own MoonBook workspace under:

- `.moontown/books/research-moontown`
- `.moontown/books/research-moonbook`
- `.moontown/books/research-moonclaw`

The mayor then imports keeper packets into MoonClaw, polls run status, persists
terminal results back into the lane's MoonBook workspace, and asks MoonBook to
refresh the generated site.

## 10. Read The Town Synthesis

After a parallel research goal settles or times out, Moontown writes a
town-level synthesis artifact under:

- `.moontown/town-synthesis/<goal-slug>.md`
- `.moontown/town-synthesis/latest.md`

The synthesis is a mayor-owned control-plane projection. It summarizes:

- lane count
- running/completed/review/failed lane status
- verified source counts
- evidence, entity, and concept counts
- generated-site paths
- lane readiness gaps
- the mayor decision for whether the goal is complete or still blocked

This is intentionally not a MoonBook page. MoonBook owns durable domain
knowledge; Moontown owns cross-book supervision and acceptance.

## 11. Understand The Research Quality Gate

Moontown now blocks weak research instead of accepting file existence as
success. For research lanes, the mayor checks for required bootstrap artifacts
and rejects output that still contains provisional-only markers.

Examples of blockers:

- missing bootstrap files such as `search-log.md` or `evidence-matrix.md`
- no verified source digest under `wiki/sources/`
- synthesis brief is not lane-specific
- web candidates were listed but not fetched and screened
- search log says the web pass may be enriched later
- wiki synthesis still says review is pending

When those gaps exist, Moontown marks the lane as `ReviewQueued` and the town
synthesis remains blocked or interim.

## 12. Run The Rabbita Frontend

The browser frontend lives in:

- [ui/rabbita-town](/Users/kq/Workspace/moontown/ui/rabbita-town)

From that directory:

```bash
cd ui/rabbita-town
npm install
npm run dev
```

Or from the repo root:

```bash
./scripts/build-rabbita-ui.sh
```

Important frontend files:

- [ui/rabbita-town/main/main.mbt](/Users/kq/Workspace/moontown/ui/rabbita-town/main/main.mbt)
- [ui/rabbita-town/styles.css](/Users/kq/Workspace/moontown/ui/rabbita-town/styles.css)
- [ui/rabbita-town/index.html](/Users/kq/Workspace/moontown/ui/rabbita-town/index.html)
- [ui/rabbita-town/bootstrap.js](/Users/kq/Workspace/moontown/ui/rabbita-town/bootstrap.js)
- [ui/rabbita-town/vite.config.js](/Users/kq/Workspace/moontown/ui/rabbita-town/vite.config.js)

## 13. Use The Live Simulation Controls

The current Rabbita frontend is a live simulation dashboard.

What you can do in the UI:

- let ticks run continuously
- pause
- resume
- step one tick
- switch strategy
  - balanced
  - throughput
  - recovery
- inspect nodes and workers
- issue simulation actions
  - inject budget
  - relieve queue
  - stability drill

Current live metrics:

- budget
- energy
- pressure
- stability

Current dashboard surfaces:

- runtime summary bar
- packet/import/run/persist/review stage rail
- scene viewport with worker movement
- inspector sidebar
- activity feed

Current visual behaviors:

- moving worker avatars
- activity feed
- anomaly surfacing
- scene selection/inspector

On narrower screens, the scene now scrolls internally instead of clipping the
town layout.

This is currently local simulation state, not backend-synced town state.

## 14. Validate Changes

For normal repo validation:

```bash
moon check
moon test
moon info
moon fmt
```

For UI changes, also run:

```bash
./scripts/build-rabbita-ui.sh
```

That is the expected workflow for this repo now.

## 15. Know The Current Boundaries

There are three important “real vs stubbed” boundaries.

Real now:

- persisted book catalog
- persisted town snapshot
- keeper packet generation
- proposal/run lifecycle records
- MoonClaw run polling for bounded goal runs
- MoonBook persistence and generated-site refresh after terminal goal runs
- mayor-level research synthesis and quality gating
- strategic mayor role model
- dispatch and health model
- scene dashboard model
- Rabbita simulation frontend

Stubbed now:

- experiment runtime loop
- 24/7 daemon supervision
- restart-safe multi-day process supervision
- backend-synced Rabbita state

Separate ownership note:

- the Rabbita town dashboard belongs to `moontown`
- the generated workspace website under `.moontown/books/*/site/` belongs to
  `moonbook`

So the correct expectation is:

- use `moontown` today as a bounded control-plane runner and frontend prototype
- do not assume it already runs a durable 24/7 multi-agent backend

## 16. Best Entry Points By Goal

If you want to:

- change town data model
  - start in [core/types.mbt](/Users/kq/Workspace/moontown/core/types.mbt)
- change routing or isolation
  - start in [dispatch/router.mbt](/Users/kq/Workspace/moontown/dispatch/router.mbt)
- change strategic role behavior
  - start in [roles/mayor.mbt](/Users/kq/Workspace/moontown/roles/mayor.mbt)
- change persisted books
  - start in [adapters/moonbook/client.mbt](/Users/kq/Workspace/moontown/adapters/moonbook/client.mbt)
- change scene layout or assets
  - start in [ui/scene_layout.mbt](/Users/kq/Workspace/moontown/ui/scene_layout.mbt)
- change browser UI behavior
  - start in [ui/rabbita-town/main/main.mbt](/Users/kq/Workspace/moontown/ui/rabbita-town/main/main.mbt)
- change browser styling
  - start in [ui/rabbita-town/styles.css](/Users/kq/Workspace/moontown/ui/rabbita-town/styles.css)
