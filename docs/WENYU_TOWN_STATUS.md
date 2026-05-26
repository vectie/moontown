# Wenyu Valley Town Status

Last updated: 2026-05-26 16:59 CST

This document answers one question: how far is the current Wenyu Valley
implementation from a fully functioning town?

The short answer is:

- as a visual, inspectable town shell: about 70% complete
- as a local 24/7 AI control-plane prototype: about 62% complete
- as a fully functioning civic AI town with real services, persistent memory,
  execution, generated projections, and operator workflow: about 39-42% complete

The project is no longer just markdown or a static map. It now has a real
terrain viewport, modular civic buildings, daemon/watch state, MoonBook/MoonClaw
boundaries, operator visibility, and first-class module runtime projection. The
browser can now build a MoonBook projection index and serve/copy generated book
outputs into the Wenyu module UI. The remaining work is mostly integration
depth: every civic building needs a real bound MoonBook workspace, real worker
activity, meaningful module-specific output, and real service workflows.

## Distance To Fully Functioning Town

The current system is roughly one third to two fifths of the way to the full
Wenyu Valley vision. The map, daemon skeleton, standing watchers, and truthful
runtime projection are real. The civic service layer is still mostly missing.

| Layer | Current Distance | Why |
|---|---:|---|
| Visual town shell | Near | The 256 x 144 Wenyu map, drag/zoom, module buildings, interiors, water overlays, and validation are in place |
| Truthful runtime UI | Medium-near | `visual-projection.json` now has module status, module interiors can read MoonBook UI fragments, and the viewport avoids fake busy state; civic books still need full coverage |
| Long-running mayor loop | Medium | The daemon worker is healthy locally with zero recorded failures in the current runtime file; the service supervisor wrapper is not currently active, so install/service hardening and multi-day recovery evidence are still required |
| Research watchers | Medium | OPC and LLM standing watches run through real books and ledgers; both are visible in the watch portfolio, but the current latest LLM watcher is still `NeedsReview` and the OPC watcher is still running |
| Civic modules | Far | Policy, contest, social, talent, market, bridge, and story modules are mostly product specs, not end-to-end workflows |
| Designer/operator tooling | Far | JSON config works, but there is no module editor, asset checker, or Moondesk-style output browser yet |
| Production deployment | Far | Auth, backups, permissions, packaged supervisor, and recovery playbooks are not complete |

## Definition Of Fully Functioning

A fully functioning Wenyu town means:

1. The map is a stable, beautiful, navigable Wenyu Valley surface.
2. Each civic feature is a configurable building, not hardcoded UI.
3. Each building has a MoonBook workspace with durable wiki/memory state.
4. MoonClaw workers execute bounded tasks for those workspaces.
5. The Mayor daemon runs continuously, recovers failures, and dispatches due
   work.
6. The UI shows real worker state, not decorative animation.
7. Operators can submit requests, inspect progress, and retrieve outputs.
8. No-change cycles, failed cycles, and real knowledge updates are accounted for
   separately.
9. A town designer can add, remove, or move modules by changing config and
   assets, without editing MoonBit code.
10. The system can run overnight and still show truthful progress the next
    morning.

## Current Capability Scorecard

| Area | Current State | Completion | Main Gap |
|---|---|---:|---|
| Wenyu terrain map | 256 x 144 tiled visual surface with river, lakes, farms, roads, bridges, drag, and zoom | 70% | Needs richer depth, seasonal overlays, fog/cloud layers, and perf budgets for lower-end browsers |
| Civic module registry | `wenyu-town-modules.json` can add, remove, move, and configure feature buildings; runtime validation now catches missing bindings and bad placement | 65% | Needs standalone schema checks, asset checks, and designer preview |
| Module buildings | 11 configurable module buildings render above terrain and open interiors | 50% | Assets are still reused/early-stage; each module needs custom generated sprites and roof/depth variants |
| Module interiors | Click opens module-specific interior furniture with runtime source, counters, validation state, worker roster slots, MoonBook fragments, and output links when available | 60% | Most Wenyu civic modules still need real bound books and service-specific page schemas |
| Water effects | Runtime overlay adds depth, reflection, and bridge shadow | 35% | Needs richer segmented river logic and seasonal/weather response |
| Agents on map | Visual agent projection exists; active module workers route to module entrances and idle/completed workers stay hidden | 60% | Needs Wenyu-specific task projection coverage for every civic module |
| Operator dashboard | Shows daemon/watch progress, a multi-topic watch portfolio, request composer, and portal to canonical viewport | 62% | Needs output retrieval, approval queues, and richer per-book progress panels |
| Mayor daemon | Local run/start/doctor/stop, heartbeat, stale detection, standing-goal dispatch | 62% | Needs long-run soak testing, service install hardening, and recovery playbooks |
| Standing watchers | Data-driven standing goals and watcher ledgers exist; the UI now aggregates all watcher ledgers instead of only the OPC lane | 64% | Need stronger MoonBook quality accounting and accepted-change views |
| MoonBook memory binding | Research books and generated projections work for research lanes; the Wenyu UI can consume `moonbook-ui-state.json` fragments generically | 50% | Civic modules need canonical book schemas, real workspaces, and service-specific content |
| MoonClaw execution binding | Proposal/run boundary and worker execution path exist | 45% | Civic service tasks need role-specific skills and output contracts |
| Real civic services | PRD describes policy, contest, social, talent, bridge, market, and story modules | 15% | Most services are still product specs, not reliable end-to-end workflows |
| Designer workflow | Manual JSON config works | 30% | Needs editor, validation, asset manifest checks, and map collision checks |
| Production readiness | Local development works; build/check pass | 25% | Needs packaged daemon, auth, permissions, backups, observability, and deployment model |

## What Is Real Today

Implemented and validated:

- `viewport.html?assets=generated&v=wenyu-modules` renders the canonical Wenyu
  tile viewport.
- `ui/assets/tilemap/modules/wenyu-town-modules.json` defines 11 enabled civic
  modules.
- The Rabbita bootstrap loads the module registry at runtime.
- MoonBit parses enabled modules and renders them as a separate layer above the
  terrain.
- Building labels stay hidden until hover/focus.
- Clicking a module opens an interior scene.
- The HUD reports total modules, cleanly validated modules, loaded MoonBook
  fragments, and module-config load version.
- Module placement validation reports missing bindings, missing assets, invalid
  footprints, and bad water/road placement.
- Module interiors show runtime source, status counters, current detail,
  validation state, and active worker roster slots.
- The Vite bridge exposes `module-projections.json` by scanning
  `.moontown/books/*/book/moonbook-ui-state.json`.
- The build copies important MoonBook generated HTML outputs under
  `dist/book-output/<book-id>/...`.
- Module interiors show MoonBook summary, status chips, metrics, readiness,
  review queue, page families, output links, and latest journey when the bound
  book publishes a fragment.
- Missing MoonBook fragments are called out as real integration gaps instead
  of being hidden behind decorative fallback copy.
- Active module workers route to the configured `entrance_x`/`entrance_y`;
  idle, completed, and absent workers are not shown as fake busy avatars.
- Water depth, reflection, and bridge-shadow effects render as pointer-safe
  overlays.
- The repo has daemon commands, standing goals, watcher ledgers, and runtime
  health summaries.
- The operator dashboard aggregates all watcher ledgers through
  `watchers/index.json` and shows a standing-watch portfolio instead of only a
  single focused watcher card.
- The operator dashboard links to the standalone Wenyu viewport instead of
  duplicating a second map.

## Current Runtime Snapshot

Checked on 2026-05-26 16:59 CST with:

```bash
moon run cmd/main -- status
moon run cmd/main -- daemon doctor
```

Observed state:

- daemon doctor reports `runtime=healthy`
- daemon status is `ticking`
- worker process is alive and heartbeat age is still below the stale threshold
- no new completed daemon tick was observed since the 16:47 status update;
  the runtime is still healthy, but the current OPC watch remains in progress
- service supervisor wrapper is not currently alive (`supervisor_pid=0`), so
  this is a live local worker loop, not yet a packaged durable service
- daemon runtime is at tick 5875 with 1836 successful cycles and 0 recorded
  failures
- town snapshot contains 2 active research books, 12 workers, 77 tasks, 77
  executions, and 190 watcher records
- current execution mix is 1 running, 75 review, 0 failed, and 0 stale
- active long-horizon books are:
  - `research-opc`
  - `research-how-llms-are-trained-in-very-detail`
- the current planned daemon actions are:
  - `poll-run`: `standing-watch-opc-news-tick-5876` / `Running`
  - `standing-goal-due`: `watch-opc-news` -> `research-opc`
- the latest watcher record is `watch-llm-training/NeedsReview`
- the next due watcher tick is scheduled for tick 5892
- there is currently 1 due standing goal and 2 planned daemon actions

Interpretation:

- the local daemon/watch loop is alive
- the town can run background research maintenance, but the current snapshot
  has not advanced past tick 5875 since the prior check
- the LLM watcher has produced a reviewable event, and the OPC watcher is still
  in progress
- the current background work is still research-book maintenance, not yet the
  full Wenyu civic service layer
- the inactive supervisor wrapper means this is not yet production-grade 24/7
  supervision, even though the worker loop itself is healthy
- the UI should present no-change watcher cycles as operational diligence,
  review-needed cycles as pending judgment, and accepted changes as real
  knowledge progress

## What Is Still A Prototype

The following items are visible but not fully real yet:

- Module buildings do not all have final custom art.
- Module interiors can consume MoonBook projection fragments, but most Wenyu
  civic modules do not yet have populated civic workspaces behind them.
- Agent movement is only as complete as the current visual projection; Wenyu
  civic books still need module-specific task/run fragments.
- The module registry is manually edited JSON; there is no designer tool.
- The 24/7 loop is a local supervised seam, not a fully packaged service.
- Civic service flows are mostly planned modules, not all implemented workflows.
- Output retrieval is not yet a full desktop/file-manager experience.
- Production safety boundaries, auth, operator approvals, and backups are not
  complete.

## Next Implementation Gates

### Gate 1: Truthful Runtime Binding

Goal:

Every visible module building should reflect real runtime state.

Implemented:

- module state now uses visual projection first, direct execution records
  second, and config-only fallback last
- the operator command center aggregates all `.moontown/watchers/*.jsonl`
  records and shows every enabled standing watch as a portfolio card
- status lights distinguish running, waiting, review, alert, complete,
  projected, unbound, and calm states
- active workers are routed to module entrances when their book/task matches a
  configured module
- zero-count worker and issue badges are not rendered
- interiors display runtime counters, source labels, validation status, and
  active worker rosters
- `visual-projection.json` now includes a first-class `modules[]` status array
  keyed by normalized module id
- the browser bridge now merges MoonBook UI fragments by `book_id`
- interiors now expose module-specific output links, review gaps, metrics, and
  recent MoonBook journey entries when the bound book has generated state
- the viewport was validated with 11 modules, 11 clean placements, 0 issue
  badges, and 0 fake active-agent badges

Remaining:

- Create or populate the civic MoonBook workspaces for every enabled Wenyu
  module.
- Add accepted-change summaries to the MoonBook UI-state contract.
- Add Wenyu-specific civic task fixtures so every module can be validated
  against real MoonBook/MoonClaw activity.

Acceptance:

- Starting a watcher or research task makes the correct building pulse.
- The correct worker appears outside only while working.
- Clicking the building shows the task/run/book state that caused the visual.

### Gate 2: Module Asset Quality

Goal:

Each module should look like a distinct civic building.

Required work:

- Generate final transparent PNG sprites for each module.
- Split each building into base, roof, shadow, and optional glow layers.
- Add asset prompts under `ui/assets/tilemap/prompts/`.
- Validate image dimensions and transparency before rendering.
- Reject buildings that overlap water or roads unless the module is explicitly a
  bridge/harbor.

Acceptance:

- Policy Hall, Contest Express, Social Square, Talent Avenue, AI Garden,
  Physical Bridge, Valley Market, Broadcast Tower, Resident Twin Homes, Vitality
  Tower, and Town Shell are visually distinguishable at a glance.

### Gate 3: Civic Book Schemas

Goal:

Each civic module should have a MoonBook schema.

Required work:

- Define canonical wiki folders for each module type.
- Define projection JSON fragments per module.
- Define review queues and public/private projection scopes.
- Add MoonBook skills for policy, contest, social matching, talent graph,
  education garden, physical bridge, market ledger, and story radar.
- Publish `book/moonbook-ui-state.json` for each civic module so Moontown can
  render it without hardcoded module copy.

Acceptance:

- A module can show real pages, recent tasks, review gaps, and output links from
  MoonBook without hardcoded UI copy.

### Gate 4: Worker Skill Contracts

Goal:

MoonClaw workers should know how to operate each module.

Required work:

- Add role-specific skill packs and output contracts.
- Keep execution bounded and packetized.
- Require source/evidence accounting for knowledge tasks.
- Require approval markers for external-impact tasks.

Acceptance:

- A user request enters Moontown, routes to the right module book, runs through
  MoonClaw, persists into MoonBook, and changes the visible module state.

### Gate 5: Long-Run Operation

Goal:

The town should run unattended for days.

Required work:

- Installable supervisor for local machines.
- Heartbeat, stale worker restart, and no-progress alerts.
- Daily digest generation.
- Watcher summary separated into operational activity and domain knowledge
  changes.
- Backup and recovery of `.moontown`, MoonBook workspaces, and watcher ledgers.

Acceptance:

- Leave the daemon running overnight.
- The next morning, the UI shows which checks ran, what changed, what did not
  change, which workers recovered, and which books were updated.

### Gate 6: Designer And Operator Tools

Goal:

The town should be maintainable by a designer/operator, not only a developer.

Required work:

- Module config validator.
- Map collision/placement preview.
- Asset manifest checker.
- Request/output file browser or Moondesk integration.
- Module enable/disable workflow.

Acceptance:

- A designer can add a new building, place it, point it at a book, and validate
  it without editing MoonBit code.

## Recommended Next Order

1. Create or populate MoonBook workspaces for each Wenyu civic building and
   ensure each publishes `book/moonbook-ui-state.json`.
2. Add MoonClaw skill/output contracts per civic module.
3. Generate final module assets and register them in the manifest.
4. Add a standalone module config, placement, and asset validator.
5. Add accepted-change summaries to the MoonBook UI-state contract and surface
   them in interiors.
6. Run a 24-hour daemon soak test with at least two standing goals and one
   Wenyu civic module workflow.
7. Add Moondesk-style output browsing for produced wiki pages, reports, assets,
   and task artifacts.
8. Package the daemon as a durable local service with backup/recovery checks.

## Health Check Commands

Use these checks after town UI or runtime changes:

```bash
cd ui/rabbita-town
npm run build
```

```bash
moon check
```

```bash
moon run cmd/main -- daemon doctor
```

```bash
moon run cmd/main -- status
```

Browser validation target:

```text
http://127.0.0.1:5173/viewport.html?assets=generated&v=wenyu-modules
```
