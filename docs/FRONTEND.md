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

The Wenyu Valley target and implementation roadmap are specified in
[WENYU_VALLEY_PRD.md](/Users/kq/Workspace/moontown/docs/WENYU_VALLEY_PRD.md).
The frontend should be treated as a projection of the town runtime, not the
source of truth for resident memory, civic quests, social matches, or talent
graphs.

The tiled-map production workflow is specified in
[TILED_MAP_PIPELINE.md](/Users/kq/Workspace/moontown/docs/TILED_MAP_PIPELINE.md).
Use that procedure when extending the current generated isometric tilemap into
a Tiled-compatible map loader and depth-sorted actor layer.

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
- generated isometric tilemap viewport
- generated PNG tiles, objects, flowers, trees, river, bridge, and building sprites
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

The runtime state that should drive the next browser bridge now includes:

- standing goals from `.moontown/standing-goals.json`
- daemon tick and active goal ids from `.moontown/daemon.json`
- book/task/execution state from `.moontown/town.json`

For example, the `watch-opc-news` standing goal should make the OPC researcher
avatar visibly busy only when the daemon has dispatched the `research-opc` book
lane. The current resident animation is visual scaffolding; the next UI step is
to bind it to real daemon state instead of synthetic ticks.

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

## Operator Command Center

The Rabbita frontend now has a command-center section for 24/7 operation. It is
the first place to check whether progress is actually being made.

It reads:

- `.moontown/town.json` for books, workers, tasks, executions, and events.
- `.moontown/daemon.json` for real daemon tick, lease owner, cadence, and due
  standing goals.
- `.moontown/standing-goals.json` for enabled standing-watch requests and next
  due tick.
- `.moontown/watchers/watch-opc-news.jsonl` for the durable watcher ledger.
- `.moontown/operator-requests/requests.jsonl` for browser-submitted requests.

The progress surface shows:

- current running worker count
- latest watcher decision
- latest new source count
- latest checked source count
- accepted/rejected fact counts
- whether the target book actually changed
- update/review/no-change/failed decision mix
- standing-goal progress toward the next due tick
- the last five watcher records with source, delta, task, and run metadata

The UI should treat `book_changed: no` plus nonzero `checked_sources_count` as
useful operational transparency, not as failure. It means the town worker
screened material and MoonBook judged that the book should not be inflated. The
UI should reserve "progress" language for accepted facts, queued review, changed
wiki pages, or `book_changed: yes`.

The request composer writes through the Vite dev endpoint
`POST /api/operator-requests`. A successful submit appends an operator request
record and creates or replaces the matching standing goal in
`.moontown/standing-goals.json`. The daemon is still the executor; the UI only
adds durable work to the Mayor queue.

The operator dashboard does not render the Wenyu map inline. It shows a portal
card that links to `viewport.html?assets=generated&v=wenyu`, the canonical
standalone tilemap viewport. This avoids divergence between a small dashboard
map and the actual Wenyu Valley viewport.

## Wenyu Module UI

The Wenyu viewport is moving toward a modular add-on system documented in
[WENYU_UI_MODULE_SYSTEM.md](/Users/kq/Workspace/moontown/docs/WENYU_UI_MODULE_SYSTEM.md).
Current readiness is tracked in
[WENYU_TOWN_STATUS.md](/Users/kq/Workspace/moontown/docs/WENYU_TOWN_STATUS.md).

The short version:

- the base terrain stays clean and mostly rasterized for drag/zoom performance
- each civic feature is a configurable building on the map
- buildings are loaded from `ui/assets/tilemap/modules/wenyu-town-modules.json`
- each building binds to a MoonBook through `book_id`
- clicking a building opens a module-specific interior
- hover/focus reveals module details without cluttering the first screen
- water depth and reflection are rendered as cheap overlay layers, not baked
  into the base map

This keeps Moontown in charge of the visual control plane while allowing
MoonBook and MoonClaw to provide the state and work behind each building.

Current frontend maturity:

- the standalone viewport and modular building shell are real
- hover labels, clickable interiors, water overlays, and module config loading
  are real
- module lights now use visual projection data first, direct execution records
  second, and config fallback last
- `visual-projection.json` now carries first-class `modules[]` runtime status
  keyed by normalized module id
- active workers route to matched module entrances; idle, completed, and absent
  workers do not create fake busy badges
- interiors show runtime source, counters, validation state, and active worker
  roster slots
- the next hard requirement is module projection coverage: MoonBook needs to
  emit module-specific fragments so each civic building can show pages, review
  gaps, outputs, and accepted changes

## Assets

Original example assets live under:

- [ui/assets/backgrounds](/Users/kq/Workspace/moontown/ui/assets/backgrounds)
- [ui/assets/buildings](/Users/kq/Workspace/moontown/ui/assets/buildings)
- [ui/assets/actors](/Users/kq/Workspace/moontown/ui/assets/actors)
- [ui/assets/props](/Users/kq/Workspace/moontown/ui/assets/props)
- [ui/assets/effects](/Users/kq/Workspace/moontown/ui/assets/effects)

Current examples are SVG placeholders with original `moontown` styling, not
borrowed `sou` assets.

For the next-generation tiled map, generated assets should be registered under:

- [ui/assets/tilemap](/Users/kq/Workspace/moontown/ui/assets/tilemap)

That folder holds the generated tilesets, sliced tile PNGs, object sprites,
building sprites, reference map JSON, prompts, and manifest described by the
tiled-map pipeline.

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
- standing-goal and daemon-state projection into the browser
- richer movement interpolation
- deeper multi-agent coordination visuals
- fuller command system
- stronger audiovisual polish

The current target is a rich operator dashboard, not a traditional game engine.
