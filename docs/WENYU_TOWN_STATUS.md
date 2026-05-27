# Wenyu Valley Town Status

Last updated: 2026-05-27 17:20 CST

This document answers one question: how far is the current Wenyu Valley
implementation from a fully functioning town?

The short answer is:

- as a visual, inspectable town shell: about 70% complete
- as a local 24/7 AI control-plane prototype: about 64% complete
- as a fully functioning civic AI town with real services, persistent memory,
  execution, generated projections, and operator workflow: about 50-54% complete
- as a true civic-building protocol town where buildings aggregate, exchange,
  reduce, and distribute agent/info packets: about 40-45% complete

The project is no longer just markdown or a static map. It now has a real
terrain viewport, modular civic buildings, daemon/watch state, MoonBook/MoonClaw
boundaries, operator visibility, first-class module runtime projection, and the
first civic-building protocol runtime slice. The browser can build a MoonBook
projection index and serve/copy generated book outputs into the Wenyu module UI.
The Wenyu buildings now have generated civic MoonBook workspace seeds, schemas,
review queues, projections, role-specific MoonClaw skill contracts, and building
protocol contracts. Social Square has a durable protocol proof slice with
inbox, contribution, reduction, outbox, review, home-return, and effectiveness
metric ledgers. The template-driven salon path now proves that a building can
hold a multi-book exchange, reduce ideas, measure output yield, and return
reduced ideas back to each participant MoonBook. The remaining work is mostly
integration depth: the other civic buildings still need repeated scenario
packets, real MoonClaw reductions, MoonBook accept/reject persistence, and
reviewable service histories before they can be called reliable civic services.
The plan is tracked in
[WENYU_BUILDING_PROTOCOL_PLAN.md](/Users/kq/Workspace/moontown/docs/WENYU_BUILDING_PROTOCOL_PLAN.md).
The structural refactor plan is tracked in
[REFACTOR_PLAN.md](/Users/kq/Workspace/moontown/docs/REFACTOR_PLAN.md).

## Distance To Fully Functioning Town

The current system is roughly halfway to the full Wenyu Valley vision. The map,
daemon skeleton, standing watchers, truthful runtime projection, and civic
workspace bootstrap are real. The main missing layer is repeated, reviewed,
service-specific execution for each civic module.

| Layer | Current Distance | Why |
|---|---:|---|
| Visual town shell | Near | The 256 x 144 Wenyu map, drag/zoom, module buildings, interiors, water overlays, and validation are in place |
| Truthful runtime UI | Medium-near | `visual-projection.json` now has module status, module interiors can read MoonBook UI fragments, and the viewport avoids fake busy state; civic books still need full coverage |
| Long-running mayor loop | Medium | The daemon worker is healthy locally with zero recorded failures in the current runtime file; the service supervisor wrapper is not currently active, so install/service hardening and multi-day recovery evidence are still required |
| Research watchers | Medium | OPC and LLM standing watches run through real books and ledgers; both are visible in the watch portfolio, but the current latest LLM watcher is still `NeedsReview` and the OPC watcher is still running |
| Civic modules | Medium | Policy, contest, social, talent, market, bridge, story, education, resident, vitality, and town-shell modules now have generated MoonBook workspaces, schemas, review queues, projections, and skill contracts; end-to-end service runs still need soak testing |
| Building protocol layer | Far-medium | Buildings have modes and skills, but do not yet have durable inbox/contribution/reduction/outbox ledgers or AI-guided map/reduce-style protocol execution |
| Runtime architecture | Medium | Civic protocol behavior now has a documented refactor path, the salon scheduler is split away from generic daemon code, daemon scheduled jobs use a dispatcher, and protocol registry/store/status/fixtures are separated; package-level civic runtime splits and MoonClaw-driven reducers are still pending |
| Designer/operator tooling | Medium | JSON config works, the standalone viewport has view/editor/output modes, editor mode shows town-level Moondesk handoff lanes, and detailed single-agent/workspace editing remains in Moondesk |
| Production deployment | Far | Auth, backups, permissions, packaged supervisor, and recovery playbooks are not complete |

## Definition Of Fully Functioning

A fully functioning Wenyu town means:

1. The map is a stable, beautiful, navigable Wenyu Valley surface.
2. Each civic feature is a configurable building, not hardcoded UI.
3. Each building has a MoonBook workspace with durable wiki/memory state.
4. Each building also has a protocol envelope for inbox, aggregation,
   exchange, AI-guided reduction, review, and distribution.
5. MoonClaw workers execute bounded tasks for those workspaces and building
   protocols.
6. The Mayor daemon runs continuously, recovers failures, and dispatches due
   work.
7. The UI shows real worker state, not decorative animation.
8. Operators can submit requests, inspect progress, and retrieve outputs.
9. No-change cycles, failed cycles, and real knowledge updates are accounted for
   separately.
10. A town designer can add, remove, or move modules by changing config and
   assets, without editing MoonBit code.
11. The system can run overnight and still show truthful progress the next
    morning.

## Current Capability Scorecard

| Area | Current State | Completion | Main Gap |
|---|---|---:|---|
| Wenyu terrain map | 256 x 144 tiled visual surface with river, lakes, farms, roads, bridges, drag, and zoom | 70% | Needs richer depth, seasonal overlays, fog/cloud layers, and perf budgets for lower-end browsers |
| Civic module registry | `wenyu-town-modules.json` can add, remove, move, and configure feature buildings; runtime validation now catches missing bindings and bad placement | 65% | Needs standalone schema checks, asset checks, and designer preview |
| Building protocol registry | Protocol definitions exist for every Wenyu civic building; Social Square has durable inbox/contribution/reduction/outbox/review/home-return proof slices plus effectiveness metrics; the UI can show protocol review pressure | 48% | Need real scenario packets, AI reducers, MoonBook accept/reject persistence, and UI protocol history for every building |
| Module buildings | 11 configurable module buildings render above terrain and open interiors | 50% | Assets are still reused/early-stage; each module needs custom generated sprites and roof/depth variants |
| Module interiors | Click opens module-specific interior furniture with runtime source, counters, validation state, worker roster slots, MoonBook fragments, and output links when available | 64% | Seeded civic books exist; interiors still need accepted-change history and live service run evidence |
| Water effects | Runtime overlay adds depth, reflection, and bridge shadow | 35% | Needs richer segmented river logic and seasonal/weather response |
| Agents on map | Visual agent projection exists; active module workers route to module entrances and idle/completed workers stay hidden | 60% | Needs Wenyu-specific task projection coverage for every civic module |
| Operator dashboard | Shows daemon/watch progress, a multi-topic watch portfolio, request composer, portal to canonical viewport, output mode, and Moondesk bridge visibility | 68% | Needs approval queues and richer per-book progress panels |
| Mayor daemon | Local run/start/doctor/stop, heartbeat, stale detection, standing-goal dispatch | 62% | Needs long-run soak testing, service install hardening, and recovery playbooks |
| Standing watchers | Data-driven standing goals and watcher ledgers exist; the UI now aggregates all watcher ledgers instead of only the OPC lane | 64% | Need stronger MoonBook quality accounting and accepted-change views |
| MoonBook memory binding | Research books and generated projections work for research lanes; Wenyu civic books can be bootstrapped with canonical schemas, wiki pages, review queues, and `moonbook-ui-state.json` fragments | 62% | MoonBook should eventually own native civic templates upstream instead of relying on Moontown-generated seeds |
| MoonClaw execution binding | Proposal/run boundary and worker execution path exist; every Wenyu civic module now has a role-specific skill pack path and output contract injected into worker context | 56% | Need repeated successful module-specific service executions and stricter result parsing per contract |
| Real civic services | Moontown can create the civic service lanes and route civic workflow tasks | 35% | Policy, contest, social, talent, bridge, market, story, and education modules still need service-specific live runs, operator review, and accepted output histories |
| Designer workflow | Manual JSON config plus standalone editor mode and handoff/bridge visibility | 48% | Needs write-back import/export, asset manifest checks, richer collision preview, and automatic Moondesk artifact ingestion |
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
- The standalone viewport supports explicit `view`, `editor`, and `output`
  modes.
- Editor mode shows configured modules, grid/entrance placement, runtime state,
  validation issues, and whether a MoonBook output fragment is connected.
- Final output mode lists generated MoonBook projection fragments and links to
  the book HTML/report outputs copied by the browser bridge.
- The editor boundary is documented: Moontown edits town/module/multi-agent
  composition, while `../moondesk` should own detailed file/workspace,
  single-book, and single-agent authoring.
- `tilemap/modules/moondesk-handoff.json` declares portable artifact lanes for
  book workspaces, module packs, asset packs, simple agent profiles, skill-pack
  references, operator request packs, and generated output bundles.
- The Vite bridge exposes `moondesk-bridge.json` by scanning real
  `.moontown/moondesk-dispatches`, `.moontown/moondesk-requests`, and
  `.moontown/book-results` files.
- Editor mode and final output mode both show Moondesk handoff lanes and recent
  bridge records.
- `moon run cmd/main -- civic bootstrap` bootstraps 11 Wenyu civic support
  workspaces and updates `.moontown/moonbooks.json`.
- `moon run cmd/main -- civic status` reports module operability, latest civic
  service decision, review load, missing files, and accepted-change proof.
- `moon run cmd/main -- civic doctor` writes `.moontown/civic/status.json` and
  `.moontown/civic/status.md`; the viewport bridge exposes that file as
  `civic-status.json`.
- `moon run cmd/main -- civic protocols bootstrap` writes
  `.moontown/civic/protocols.json`, per-building `PROTOCOL.md` files, and the
  initial Social Square protocol ledgers.
- `moon run cmd/main -- civic protocols status` reports protocol state across
  all Wenyu civic buildings.
- `moon run cmd/main -- civic protocols salon-template <path>` now runs the
  same civic salon envelope from a `CivicSalonScenario` JSON file, so future
  domains can be added by template and schedule instead of editing MoonBit
  runner code.
- `moon run cmd/main -- civic protocols salons status` and
  `moon run cmd/main -- civic protocols salons tick` expose the recurring
  salon scheduler. The daemon now checks the same schedule on every tick and
  runs enabled salons when real wall-clock `next_due_ms` has arrived.
- Salon templates write template-defined metrics pages,
  `.moontown/civic/protocols/social-square/metrics.json`, and a
  `home_returns.jsonl` ledger. The structural effectiveness metric tracks
  participant books, reduced ideas, research questions, participant-idea links,
  covered books, and returned idea-home records.
- Recurring salon rounds write an additional
  `.moontown/civic/salon-runs/<salon-id>.jsonl` ledger for long-horizon audit
  and restart inspection.
- Each salon participant book receives
  `wiki/queries/salon-returned-ideas.md`, so the Social Square building output
  returns to the relevant home MoonBooks instead of staying as a central
  summary only.
- Social Square currently has protocol status `review`; salon templates can add
  inbox packets, contributions, reductions, outbox records, home-return records,
  and review gates without adding new MoonBit domain branches.
- The civic registry defines `town-shell`, `resident-twins`, `policy-hall`,
  `contest-express`, `social-square`, `talent-avenue`, `vitality-dashboard`,
  `ai-garden`, `physical-bridge`, `valley-market`, and `broadcast-tower`.
- Each civic module declares a mode: `agent-workspace`, `exchange-place`,
  `projection-surface`, `gateway`, or `hybrid`. Not every civic feature is
  meant to behave like a research book.
- Each generated civic support workspace receives canonical schema pages,
  civic wiki pages, review queues, a generated `book/moonbook-ui-state.json`,
  a `book/site/generated/index.html`, and a `moonclaw.jobs.json` profile for
  `wenyu_civic_service_worker`.
- Each civic module receives a generic `skills/wenyu-civic-service/SKILL.md`
  plus a dedicated module skill such as `skills/civic-policy-researcher/SKILL.md`,
  `skills/civic-social-matchmaker/SKILL.md`, or
  `skills/civic-bridge-operator/SKILL.md`.
- Mayor Wenyu decomposition now uses the civic registry, so Wenyu goals spawn
  isolated civic service lanes instead of relying on stale hardcoded module
  lists.
- Civic MoonBooks now dispatch the `civic-service-workflow` task first and are
  excluded from Wenyu research/bootstrap quality gates; Wenyu product-build
  research remains for non-civic implementation lanes.
- Module interiors now include a Civic Doctor panel that distinguishes seeded
  workspaces from real service-result proof, review-needed status, blocked
  modules, and missing workspace/config paths.
- Module interiors now include protocol status when available; Social Square
  shows the consent-gated reduction summary and protocol counters.

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
- Module interiors can consume MoonBook projection fragments, and Wenyu civic
  workspaces can now be bootstrapped locally. Those books are seeded service
  workspaces, not yet mature books with long accepted service histories.
- Agent movement is only as complete as the current visual projection; Wenyu
  civic books still need module-specific task/run fragments.
- The module registry is manually edited JSON; editor mode validates, inspects,
  and displays import contracts but does not yet write config changes back or
  automatically merge Moondesk module packs.
- The 24/7 loop is a local supervised seam, not a fully packaged service.
- Civic service flows have schemas, review queues, skill contracts, and seeded
  projections. They are not yet proven reliable end-to-end services until each
  lane has repeated MoonClaw execution, MoonBook persistence, review, and UI
  projection updates.
- Output retrieval exists in viewport output mode, but the full
  desktop/file-manager experience belongs in Moondesk and still needs a clean
  write-back/import handoff back into Moontown.
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

- Run and validate live civic service tasks for every enabled Wenyu module.
- Add accepted-change summaries to the MoonBook UI-state contract.
- Add Wenyu-specific civic task fixtures and sample service histories so every
  module can be validated against real MoonBook/MoonClaw activity.

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

Implemented:

- `civic/services.mbt` defines canonical book ids, service kinds, schema pages,
  wiki pages, review queues, target pages, worker roles, skill pack names, and
  output contracts for 11 Wenyu civic services.
- `moon run cmd/main -- civic bootstrap` writes the civic MoonBook workspace
  seeds and generated UI fragments.
- The generated workspaces include schema pages, civic wiki pages, review queue
  pages, `book/moonbook-ui-state.json`, `book/Home.html`, and
  `book/site/generated/index.html`.

Remaining:

- Move these civic templates into MoonBook when MoonBook is ready to own them
  natively.
- Add public/private projection scopes to the MoonBook-owned schema layer.
- Validate that each service workflow can update those pages through real
  MoonClaw runs instead of only bootstrap seeds.

Acceptance:

- A module can show real pages, recent tasks, review gaps, and output links from
  MoonBook without hardcoded UI copy.

### Gate 4: Worker Skill Contracts

Goal:

MoonClaw workers should know how to operate each module.

Implemented:

- Moontown now injects the generic Wenyu civic service skill, the
  module-specific skill, the service contract, projection state, and explicit
  civic result markers into civic worker context bundles.
- The civic registry assigns a module mode, book role, skill mode, worker role,
  and output contract per service.
- Wenyu book-lane worker registration creates a service-specific civic worker
  when a civic MoonBook is present.

Remaining:

- Keep execution bounded and packetized.
- Require source/evidence accounting for knowledge tasks.
- Require approval markers for external-impact tasks.
- Add MoonClaw-native validation/parsing for each `wenyu.civic.*.v1` result
  contract after real module runs exist.

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

1. Run `moon run cmd/main -- civic bootstrap` after clearing or creating a new
   Wenyu town workspace so every civic module has a MoonBook projection.
2. Execute live civic service tasks for Policy Hall, Contest Express, Social
   Square, Talent Avenue, AI Garden, Physical Bridge, Valley Market, Broadcast
   Tower, Resident Twin Homes, Vitality Tower, and Town Shell.
3. Generate final module assets and register them in the manifest.
4. Add a standalone module config, placement, and asset validator.
5. Move reusable civic workspace templates into MoonBook so Moontown only
   requests service creation rather than generating all initial files itself.
6. Add accepted-change summaries to the MoonBook UI-state contract and surface
   them in interiors.
7. Run a 24-hour daemon soak test with at least two standing goals and one
   Wenyu civic module workflow.
8. Add Moondesk-style output browsing for produced wiki pages, reports, assets,
   and task artifacts.
9. Package the daemon as a durable local service with backup/recovery checks.

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
