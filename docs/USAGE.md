# Usage Guide

This guide is the practical “how to use everything” entry for the current
`moontown` repo.

It covers:

- the text dashboard
- the persisted town state
- the moonbook catalog
- the keeper packet and proposal/run lifecycle
- the scene assets
- the Rabbita frontend
- the current limits of the repo

## What You Can Use Right Now

Right now, `moontown` is usable as:

- a MoonBit town model
- a persisted demo bootstrap
- a packet-first keeper/proposal/run control-plane model
- a scene-based dashboard
- a Rabbita simulation frontend
- a starter asset pipeline

It is not yet usable as:

- a real 24/7 autonomous town daemon
- a real external moonbook process runner
- a real external moonclaw process runner

So the right way to use the repo today is as a live architectural and frontend
prototype.

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

If those files do not exist, `moontown` creates them during bootstrap.

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
book task -> keeper packet -> imported proposal -> confirmed run -> persistence -> review
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

## 9. Run The Rabbita Frontend

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

## 10. Use The Live Simulation Controls

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

Current visual behaviors:

- moving worker avatars
- activity feed
- anomaly surfacing
- scene selection/inspector

This is currently local simulation state, not backend-synced town state.

## 11. Validate Changes

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

## 12. Know The Current Boundaries

There are three important “real vs stubbed” boundaries.

Real now:

- persisted book catalog
- persisted town snapshot
- keeper packet generation
- proposal/run lifecycle records
- strategic mayor role model
- dispatch and health model
- scene dashboard model
- Rabbita simulation frontend

Stubbed now:

- real process execution against external moonbook/moonclaw CLIs
- experiment runtime loop
- 24/7 daemon supervision

So the correct expectation is:

- use `moontown` today as a control-plane and frontend prototype
- do not assume it already runs a real multi-agent backend

## 13. Best Entry Points By Goal

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
