# Frontend Guide

`moontown` has two UI layers:

- renderer-agnostic scene modeling in the root module
- Rabbita browser rendering in `ui/rabbita-town`

## UI Stack

The current UI flow is:

```text
TownState
  -> DashboardModel
  -> SceneRenderModel
  -> Rabbita view
  -> browser bundle
```

Files by layer:

- scene contract
  - [ui/scene_layout.mbt](/Users/kq/Workspace/moontown/ui/scene_layout.mbt)
- town-to-scene projection
  - [ui/dashboard.mbt](/Users/kq/Workspace/moontown/ui/dashboard.mbt)
- renderer bridge
  - [ui/scene_render.mbt](/Users/kq/Workspace/moontown/ui/scene_render.mbt)
- Rabbita frontend
  - [ui/rabbita-town/main/main.mbt](/Users/kq/Workspace/moontown/ui/rabbita-town/main/main.mbt)

## Semantic Scene Model

The frontend is intentionally not a graph viewer. It follows the `sou` lesson:

- places first
- state mapped into places
- actors and props as meaning carriers
- anomalies shown as a visible area

Current default places:

- Town Gate
- City Hall
- Moonbook / Coding
- Moonbook / Finance
- Worker Yard
- Anomaly Corner

This gives the UI a “town scene” instead of a “nodes and edges” look.

## Current Rabbita Dashboard

The Rabbita frontend already behaves like a live simulation dashboard.

Implemented:

- periodic ticks
- pause/resume/step controls
- runtime summary bar
- execution stage rail
- packet/proposal/run lifecycle visibility
- execution status projection from `TownState.executions`
- strategy modes
  - balanced
  - throughput
  - recovery
- resource metrics
  - budget
  - energy
  - queue pressure
  - stability
- moving worker avatars
- selection and inspection
- activity feed
- keyboard focus-visible affordances
- responsive scene viewport with internal scroll
- command actions
  - inject budget
  - relieve queue
  - stability drill

This makes the frontend closer to a management simulation than a static admin
panel.

The browser surface now labels its state source explicitly and can switch
between two modes:

- `Demo Simulation`
  - synthetic traffic for frontend/gameplay tuning
- `Snapshot File`
  - a non-simulated placeholder that shows the pending `.moontown/town.json` browser bridge task instead of fake worker traffic

The next frontend integration is to replace that placeholder with a local state
endpoint or generated static JSON artifact.

## Lifecycle Projection

The current frontend does not invent its own execution state. It projects
execution records from the root town model:

- `TownState.executions`
  - packet id and packet path
  - proposal id
  - run id
  - execution status

The current status vocabulary is:

- `PacketReady`
- `ProposalImported`
- `RunConfirmed`
- `Running`
- `AwaitingPersistence`
- `ReviewQueued`
- `Completed`
- `Failed`

Those states are surfaced through the dashboard cards, scene summary, and live
activity feed.

They are also surfaced in the Rabbita runtime bar and stage rail so the browser
view reads as an operator surface rather than a static postcard.

## Assets

Original example assets live under:

- [ui/assets/backgrounds](/Users/kq/Workspace/moontown/ui/assets/backgrounds)
- [ui/assets/buildings](/Users/kq/Workspace/moontown/ui/assets/buildings)
- [ui/assets/actors](/Users/kq/Workspace/moontown/ui/assets/actors)
- [ui/assets/props](/Users/kq/Workspace/moontown/ui/assets/props)
- [ui/assets/effects](/Users/kq/Workspace/moontown/ui/assets/effects)

Current examples are SVG placeholders with original `moontown` styling, not
borrowed `sou` assets.

## Build and Dev

From the frontend directory:

```bash
cd ui/rabbita-town
npm install
npm run dev
npm run build
```

From the repo root:

```bash
./scripts/build-rabbita-ui.sh
```

Build output lands in:

- `ui/rabbita-town/dist/`

The Vite build uses a relative base path, so the generated `dist/index.html`
can be opened from `file://` as well as served through Vite preview.

## UI Change Rule

When UI files change, the expected verification path is:

```bash
moon check
moon test
moon info
moon fmt
./scripts/build-rabbita-ui.sh
```

For frontend-only iteration, at minimum run:

```bash
./scripts/build-rabbita-ui.sh
```

## UI Ownership Boundary

This repo owns:

- town scene layout
- dashboard projection
- Rabbita interaction and styling

This repo does not own the generated MoonBook workspace site under live runtime
directories such as `.moontown/books/coding/site/`.

If that generated site shows generic branding or broken projection links, the
fix belongs in `moonbook`'s site generator/templates, not in the Moontown
frontend package.

## What Is Still Missing

The frontend is live, but not yet a full simulation game.

Still missing:

- real backend-fed live state
- richer movement interpolation
- deeper multi-agent coordination visuals
- fuller command system
- stronger audiovisual polish

The current target is a rich operator dashboard, not a traditional game engine.
