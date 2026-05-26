# Wenyu Valley Town Status

Last updated: 2026-05-26

This document answers one question: how far is the current Wenyu Valley
implementation from a fully functioning town?

The short answer is:

- as a visual, inspectable town shell: about 60% complete
- as a local 24/7 AI control-plane prototype: about 50% complete
- as a fully functioning civic AI town with real services, persistent memory,
  execution, generated projections, and operator workflow: about 30% complete

The project is no longer just markdown or a static map. It now has a real
terrain viewport, modular civic buildings, daemon/watch state, MoonBook/MoonClaw
boundaries, and operator visibility. The remaining work is mostly integration
depth: every visible building needs a real MoonBook, real worker activity, real
projection data, and real service workflows.

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
| Civic module registry | `wenyu-town-modules.json` can add, remove, move, and configure feature buildings | 55% | Needs validation tooling, schema checks, and designer preview |
| Module buildings | 11 configurable module buildings render above terrain and open interiors | 45% | Assets are still reused/early-stage; each module needs custom generated sprites and roof/depth variants |
| Module interiors | Click opens module-specific interior furniture | 35% | Interiors are not yet backed by book projections, task queues, or real resident state |
| Water effects | Runtime overlay adds depth, reflection, and bridge shadow | 35% | Needs richer segmented river logic and seasonal/weather response |
| Agents on map | Visual agent projection exists and can show working agents | 45% | Agent destinations must be bound to module entrances and live task assignment for every module |
| Operator dashboard | Shows daemon/watch progress, request composer, and portal to canonical viewport | 60% | Needs stronger multi-book progress panels and output retrieval |
| Mayor daemon | Local run/start/doctor/stop, heartbeat, stale detection, standing-goal dispatch | 55% | Needs long-run soak testing, service install hardening, and recovery playbooks |
| Standing watchers | Data-driven standing goals and watcher ledgers exist | 55% | Need stronger MoonBook quality accounting and per-topic progress views |
| MoonBook memory binding | Research books and generated projections work for research lanes | 45% | Civic modules need canonical book schemas and module projection fragments |
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
- The HUD reports module count and module-config load version.
- Water depth, reflection, and bridge-shadow effects render as pointer-safe
  overlays.
- The repo has daemon commands, standing goals, watcher ledgers, and runtime
  health summaries.
- The operator dashboard links to the standalone Wenyu viewport instead of
  duplicating a second map.

## Current Runtime Snapshot

Checked on 2026-05-26 with:

```bash
moon run cmd/main -- runtime status
moon run cmd/main -- daemon doctor
```

Observed state:

- daemon doctor reports `runtime=healthy`
- worker process is alive and heartbeat is fresh
- daemon runtime has 1653 successful cycles and 0 recorded failures
- town snapshot contains 2 active research books, 12 workers, 68 tasks, and
  2422 events
- active long-horizon books are:
  - `research-opc`
  - `research-how-llms-are-trained-in-very-detail`
- both books are being checked through standing-watch tasks
- recent watcher decisions are mostly `no_change`
- LLM training book currently reports ready with one pending review item
- OPC book currently reports not-ready because source coverage and quality gates
  still need improvement

Interpretation:

- the local daemon/watch loop is alive
- the town can run background research maintenance
- the current background work is still research-book maintenance, not yet the
  full Wenyu civic service layer
- the UI should present no-change watcher cycles as operational diligence, not
  new knowledge progress

## What Is Still A Prototype

The following items are visible but not fully real yet:

- Module buildings do not all have final custom art.
- Module interiors are not yet populated from each module's MoonBook projection.
- Agent movement is not yet guaranteed to match real task assignment for every
  building.
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

Required work:

- Add a `module_status` projection keyed by module id.
- Merge MoonBook projection fragments by `book_id`.
- Bind lights, labels, counters, and interior rosters to the projection.
- Route active workers to `entrance_x` and `entrance_y`.
- Hide idle workers inside buildings.

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

1. Implement module runtime projection.
2. Bind active workers to module entrances and interiors.
3. Generate final module assets and register them in the manifest.
4. Add module config validation.
5. Add MoonBook module projection fragments.
6. Add MoonClaw skill/output contracts per civic module.
7. Run a 24-hour daemon soak test with at least two standing goals.
8. Add Moondesk-style output browsing for produced wiki pages, reports, assets,
   and task artifacts.

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
moon run cmd/main -- runtime status
```

Browser validation target:

```text
http://127.0.0.1:5173/viewport.html?assets=generated&v=wenyu-modules
```
