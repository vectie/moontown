# Frontend Guide

`moontown` has two UI layers:

- renderer-agnostic scene modeling in the root module
- Rabbita browser rendering in `src/ui/rabbita-town`

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
  - [src/ui/scene_layout.mbt](/Users/kq/Workspace/moontown/src/ui/scene_layout.mbt)
- town-to-scene projection
  - [ui/dashboard.mbt](/Users/kq/Workspace/moontown/src/ui/dashboard.mbt)
- renderer bridge
  - [src/ui/scene_render.mbt](/Users/kq/Workspace/moontown/src/ui/scene_render.mbt)
- Rabbita frontend
  - [src/ui/rabbita-town/main/main.mbt](/Users/kq/Workspace/moontown/src/ui/rabbita-town/main/main.mbt)

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

- standing goals from `.moonsuite/products/moontown/standing-goals.json`
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
- `.moonsuite/products/moontown/standing-goals.json` for enabled standing-watch
  requests and next due tick.
- `.moonsuite/products/moontown/watchers/*.jsonl` through `watchers/index.json`
  for the durable multi-topic watcher ledger.
- `.moonsuite/products/moontown/operator-requests/requests.jsonl` for
  browser-submitted requests.
- `.moonsuite/products/moontown/live-autonomy.json` for the live spine,
  including PlanBook self-build status and the Moondesk/Major book-template
  request inbox.

The progress surface shows:

- current running worker count
- latest watcher decision
- latest new source count
- latest checked source count
- accepted/rejected fact counts
- whether the target book actually changed
- update/review/no-change/failed decision mix
- book-template request totals, pending count, failed count, and inbox summary
- latest book-template lifecycle event, so an operator can see whether the
  newest specialized book request was installed or failed
- active versus archived standing-watch counts, so disabled audit records do
  not appear as live work
- a standing-watch portfolio for every enabled long-horizon topic
- per-goal progress toward the next due tick
- the last five watcher records with source, delta, task, and run metadata

The UI should treat `book_changed: no` plus nonzero `checked_sources_count` as
useful operational transparency, not as failure. It means the town worker
screened material and MoonBook judged that the book should not be inflated. The
UI should reserve "progress" language for accepted facts, queued review, changed
wiki pages, or `book_changed: yes`.

The request composer writes through the Vite dev endpoint
`POST /api/operator-requests`. A successful submit appends an operator request
record and creates or replaces the matching standing goal in
`.moonsuite/products/moontown/standing-goals.json`. The daemon is still the
executor; the UI only adds durable work to the Mayor queue.

The default source policy for browser-submitted standing goals comes from
[assets/templates/operator-request-policy.json](/Users/kq/Workspace/moontown/assets/templates/operator-request-policy.json).
The Vite endpoint reads that document before writing records; it should not
hard-code `web-first` in JavaScript. This keeps the browser as a request
surface and leaves policy vocabulary in document/policy-owned contracts.

The book-template composer writes through the Vite dev endpoint
`POST /api/book-template-requests`. The first supported template is
`pdf-evidence-watch`: the operator provides a title, book id, websites,
cadence, purpose, and optional method override; the endpoint writes a config
file under `.moonsuite/products/moontown/book-template-configs/` and queues a
durable request in `.moonsuite/products/moontown/book-template-requests.json`.
The daemon or `books template requests process` installs the actual MoonBook
workspace and standing goal. This keeps browser UI, Moondesk, and Mayor
automation on the same document-first creation path.

The operator dashboard does not render the Wenyu map inline. It shows a portal
card that links to `viewport.html?assets=generated&v=wenyu`, the canonical
standalone tilemap viewport. This avoids divergence between a small dashboard
map and the actual Wenyu Valley viewport.

Current operator-console expectations:

- show every enabled standing watch as a portfolio card
- distinguish watcher no-change, review, update, deferred, and failed states
- reserve "progress" wording for accepted facts, queued review, changed wiki
  pages, or `book_changed: yes`
- link to the standalone Wenyu viewport instead of rendering an inline map
- expose request submission through the Mayor queue rather than executing work
  directly in the browser
- expose pending and failed book-template requests so Moondesk-created books
  are visible before the daemon installs them as MoonBook workspaces
- show active and archived standing-watch counts from
  `.moonsuite/products/moontown/live-autonomy.json` before drilling into
  individual watch cards

## Standalone Viewport Modes

The canonical Wenyu viewport now has three explicit modes. These modes are
selected from the viewport HUD and can also be opened directly by URL:

- `viewport.html?assets=generated&mode=view&v=wenyu`
  - clean public town presentation
  - click buildings to inspect live module interiors
  - no editor panel or output-browser chrome
- `viewport.html?assets=generated&mode=view&module=town-shell&v=module-town-shell`
  - direct deep link to a building interior
  - `module=<module-id>` is the URL-addressable building contract
  - Back To Town returns to the canonical map view
- `viewport.html?assets=generated&mode=editor&v=wenyu`
  - town-designer workspace
  - shows module placement, entrance tile, runtime state, validation issues,
    and whether each building has a connected MoonBook output fragment
  - changing a module still happens in
    `src/ui/assets/tilemap/modules/wenyu-town-modules.json`
  - scope is multi-agent/town composition, not deep single-agent editing
- `viewport.html?assets=generated&mode=output&v=wenyu`
  - final retrieval surface
  - lists generated MoonBook projection fragments, metrics, review queues,
    page families, journey entries, and links to generated HTML/report outputs
  - also shows the Moondesk handoff contract and recent portable bridge
    records from `.moonsuite/products/moontown/moondesk-*` and
    `.moonsuite/products/moontown/book-results`

This separation is intentional:

- view mode is for presentation
- editor mode is for map/module design validation
- output mode is for retrieving produced work

The mode switch uses the same runtime data in all cases. It does not invent
book content or duplicate the Wenyu map.

Decorator/runtime boundary:

- Wenyu building placement and style live in
  `src/ui/assets/tilemap/modules/wenyu-town-modules.json`.
- The Rabbita viewport renders the module registry directly for building
  sprites, labels, interiors, and editor metadata.
- The persisted runtime projection also reads the same registry through a
  generic visual decorator placement contract, so active agents route toward
  configured building entrances instead of hardcoded Wenyu coordinates.
- Core projection code may keep deterministic fallback placement for unknown
  books, but Wenyu customization must remain in data/assets/templates rather
  than MoonBit core lookup tables.

Latest validated UI behavior:

- main console shows the five-domain standing-watch portfolio
- viewport loads 11 civic building links
- clicking a building opens a module interior by URL
- Back To Town returns to the map view without leaving a stale interior shell
- output mode lists generated MoonBook outputs and Moondesk bridge context
- browser console validation reported no runtime errors for the checked paths

Editor-mode boundary:

- Moontown editor manages modules, books, worker lanes, runtime bindings,
  placement, and output availability.
- Moontown can expose only simple per-agent controls such as role, capacity,
  cadence, home building, and permission envelope.
- Complex single-agent or single-book editing belongs in `../moondesk`, where a
  human can browse files, edit wiki pages, author skills/prompts, inspect
  generated outputs, and package reusable artifacts.
- Moondesk outputs should be portable back into Moontown as MoonBook folders,
  `moonbook-ui-state.json` projections, skill/profile manifests, asset packs,
  or module-pack JSON. Moontown consumes those artifacts; it should not
  duplicate Moondesk as an IDE.

Implemented handoff surfaces:

- `tilemap/modules/moondesk-handoff.json`
  - declares portable artifact lanes such as book workspace packs, module
    packs, asset packs, simple agent profiles, skill-pack references, operator
    request packs, and generated output bundles
- `moondesk-bridge.json`
  - Vite bridge output that scans real
    `.moonsuite/products/moontown/moondesk-dispatches`,
    `.moonsuite/products/moontown/moondesk-requests`, and
    `.moonsuite/products/moontown/book-results` records
- editor mode
  - shows the boundary panel, handoff manifest, and bridge ledger beside module
    validation
- final output mode
  - shows MoonBook outputs plus the same Moondesk artifact lanes and recent
    bridge records as retrieval context

## Wenyu Module UI

The Wenyu viewport is moving toward a modular add-on system documented in
[WENYU_UI_MODULE_SYSTEM.md](/Users/kq/Workspace/moontown/docs/WENYU_UI_MODULE_SYSTEM.md).
Current readiness is tracked in
[WENYU_TOWN_STATUS.md](/Users/kq/Workspace/moontown/docs/WENYU_TOWN_STATUS.md).

The short version:

- the base terrain stays clean and mostly rasterized for drag/zoom performance
- each civic feature is a configurable building on the map
- buildings are loaded from `src/ui/assets/tilemap/modules/wenyu-town-modules.json`
- each building binds to a MoonBook through `book_id`
- clicking a building opens a module-specific interior
- the Vite bridge scans `.moontown/books/*/book/moonbook-ui-state.json` and
  publishes `module-projections.json`
- projection visibility is metadata-driven: generated fragments can set
  `projection_scope` or `visibility`, and operators can override visibility
  through `.moontown/book-projection-policy.json` using the template at
  `assets/templates/book-projection-policy.json`
- `moon run src/cmd/main -- civic bootstrap` can create the canonical Wenyu civic
  MoonBook projection fragments consumed by the module interiors
- `moon run src/cmd/main -- civic status` prints the civic-service portfolio without
  changing files
- `moon run src/cmd/main -- civic doctor` writes `.moontown/civic/status.json` and
  `.moontown/civic/status.md` so the viewport can show seeded, changed,
  blocked, review, and misconfigured civic modules from real workspace state
- generated MoonBook HTML outputs are served and copied under
  `book-output/<book-id>/...` for module interior links
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
- interiors show MoonBook summary, status chips, metrics, readiness, review
  queue, page families, output links, and latest journey when the bound book
  publishes `moonbook-ui-state.json`
- interiors now show Civic Doctor readiness even before a rich MoonBook
  projection exists, including schema/wiki/review/projection/skill/profile
  checks and the last civic service result
- the next hard requirement is civic execution maturity: each Wenyu feature
  building needs repeated live service runs, accepted MoonBook updates, and
  structured review/change history, not only a seeded workspace

## Assets

Original example assets live under:

- [src/ui/assets/backgrounds](/Users/kq/Workspace/moontown/src/ui/assets/backgrounds)
- [src/ui/assets/buildings](/Users/kq/Workspace/moontown/src/ui/assets/buildings)
- [src/ui/assets/actors](/Users/kq/Workspace/moontown/src/ui/assets/actors)
- [src/ui/assets/props](/Users/kq/Workspace/moontown/src/ui/assets/props)
- [src/ui/assets/effects](/Users/kq/Workspace/moontown/src/ui/assets/effects)

Current examples are SVG placeholders with original `moontown` styling, not
borrowed `sou` assets.

For the next-generation tiled map, generated assets should be registered under:

- [src/ui/assets/tilemap](/Users/kq/Workspace/moontown/src/ui/assets/tilemap)

That folder holds the generated tilesets, sliced tile PNGs, object sprites,
building sprites, reference map JSON, prompts, and manifest described by the
tiled-map pipeline.

## Build and Dev

From the frontend directory:

```bash
cd src/ui/rabbita-town
npm install
npm run dev
npm run build
```

From the repo root:

```bash
./scripts/build-rabbita-ui.sh
```

Build output lands in:

- `src/ui/rabbita-town/dist/`

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

- full Wenyu civic-service execution coverage
- richer movement interpolation
- deeper multi-agent coordination visuals
- fuller command system
- stronger audiovisual polish

The current target is a rich operator dashboard, not a traditional game engine.
