# Wenyu Valley Town Status

Last updated: 2026-05-28 12:49 CST

This document answers one question: how far is the current Wenyu Valley
implementation from a fully functioning town?

The short answer is:

- as a visual, inspectable town shell: about 72% complete
- as a local 24/7 AI control-plane prototype: about 68% complete
- as a fully functioning civic AI town with real services, persistent memory,
  execution, generated projections, and operator workflow: about 52-56% complete
- as a true civic-building protocol town where buildings aggregate, exchange,
  reduce, and distribute agent/info packets: about 55-58% complete
- as a stable definition system with a generated cookbook/control book: about
  38-42% complete

The project is no longer just markdown or a static map. It now has a real
terrain viewport, modular civic buildings, daemon/watch state, MoonBook/MoonClaw
boundaries, operator visibility, first-class module runtime projection, and the
first civic-building protocol runtime slice. The browser can build a MoonBook
projection index and serve/copy generated book outputs into the Wenyu module UI.
The Wenyu buildings now have generated civic MoonBook workspace seeds, schemas,
review queues, projections, role-specific MoonClaw skill contracts, and building
protocol contracts. Social Square has a durable protocol proof slice with
inbox, contribution, reduction, outbox, review, home-return, and effectiveness
metric ledgers. The template-driven communication-pattern path now covers all
11 Wenyu buildings through JSON scenarios and a manifest installer, and the
final integration portfolio adds five long-horizon research watches for OPC,
LLM training, robotics, agents, and hardware. The current local daemon is
healthy under a supervisor, but the remaining work is still integration depth:
most civic buildings need repeated real MoonClaw reductions, MoonBook
accept/reject persistence, and reviewable service histories before they can be
called reliable civic services.
The plan is tracked in
[WENYU_BUILDING_PROTOCOL_PLAN.md](/Users/kq/Workspace/moontown/docs/WENYU_BUILDING_PROTOCOL_PLAN.md).
The structural refactor plan is tracked in
[REFACTOR_PLAN.md](/Users/kq/Workspace/moontown/docs/REFACTOR_PLAN.md).
The stable-state cookbook plan is tracked in
[COOKBOOK.md](/Users/kq/Workspace/moontown/docs/COOKBOOK.md).

## Distance To Fully Functioning Town

The current system is past the pure shell stage. The map, supervised local
daemon, standing watchers, truthful runtime projection, civic workspace
bootstrap, and recurring communication-pattern schedules are real. The main
missing layer is repeated, reviewed, service-specific execution for each civic
module.

| Layer | Current Distance | Why |
|---|---:|---|
| Visual town shell | Near | The 256 x 144 Wenyu map, drag/zoom, module buildings, interiors, water overlays, and validation are in place |
| Truthful runtime UI | Medium-near | `visual-projection.json` now has module status, module interiors can read MoonBook UI fragments, and the viewport avoids fake busy state; civic books still need full coverage |
| Long-running mayor loop | Medium-near | The daemon worker is healthy locally with zero recorded failures in the current runtime file, and standing-watch dispatch is now nonblocking so long MoonClaw runs do not serialize the whole town; install/service hardening and multi-day recovery evidence are still required |
| Research watchers | Medium-near | The final integration portfolio installs five standing watches: OPC, LLM training, Robotics, Agents, and Hardware. They are visible in the watch portfolio and run through real books/ledgers, but overnight proof still depends on repeated accepted deltas rather than only operational records |
| Civic modules | Medium | Policy, contest, social, talent, market, bridge, story, education, resident, vitality, and town-shell modules now have generated MoonBook workspaces, schemas, review queues, projections, and skill contracts; accepted service-result histories are still missing |
| Building protocol layer | Medium-near | Buildings have modes, skills, protocol definitions, ledgers, default communication-pattern scenario templates, and recurring schedules; accepted MoonBook persistence and UI protocol history still need repeated live evidence |
| Runtime architecture | Medium-near | Civic protocol behavior now has a documented refactor path, the communication-pattern scheduler is split away from generic daemon code, daemon scheduled jobs use a dispatcher, and protocol registry/store/status/fixtures are separated; package-level civic runtime splits and stronger contract validation are still pending |
| Designer/operator tooling | Medium | JSON config works, the standalone viewport has view/editor/output modes, editor mode shows town-level Moondesk handoff lanes, and detailed single-agent/workspace editing remains in Moondesk |
| Cookbook/control book | Medium-far | `cookbook bootstrap` creates a MoonBook-backed stable-state cookbook, generated wiki pages, generated site, and `.moontown/cookbook/stable-state.json`; needs Moondesk-native browsing/editing, drift review UI, import/export, and MoonBook-native templates upstream |
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
| Civic module registry | `wenyu-town-modules.json` can add, remove, move, size, style, and configure feature buildings; runtime validation now catches missing bindings, bad footprints, and bad placement | 70% | Needs standalone schema checks, asset checks, write-back editor, and designer preview |
| Building protocol registry | Protocol definitions exist for every Wenyu civic building; Social Square has durable inbox/contribution/reduction/outbox/review/home-return proof slices plus effectiveness metrics; the UI can show protocol review pressure | 48% | Need real scenario packets, AI reducers, MoonBook accept/reject persistence, and UI protocol history for every building |
| Module buildings | 16 configurable white-tech pavilion buildings render above terrain, including 11 civic modules and 5 research-domain homes; entrances bind to the existing map road/urban fabric | 62% | Needs base/roof/shadow/glow split layers and more precise collision/occlusion |
| Module interiors | Click opens module-specific interior furniture with runtime source, counters, validation state, worker roster slots, MoonBook fragments, and output links when available | 64% | Seeded civic books exist; interiors still need accepted-change history and live service run evidence |
| Water effects | Runtime overlay adds depth, reflection, and bridge shadow | 35% | Needs richer segmented river logic and seasonal/weather response |
| Agents on map | Visual agent projection exists; active module workers route to module entrances and idle/completed workers stay hidden | 60% | Needs Wenyu-specific task projection coverage for every civic module |
| Operator dashboard | Shows daemon/watch progress, a multi-topic watch portfolio, request composer, portal to canonical viewport, output mode, and Moondesk bridge visibility | 68% | Needs approval queues and richer per-book progress panels |
| Mayor daemon | Local run/start/doctor/stop, heartbeat, stale detection, standing-goal dispatch, supervisor/worker runtime health, and nonblocking MoonClaw supervision | 68% | Needs multi-day soak evidence, deployment hardening, and recovery playbooks |
| Standing watchers | Data-driven standing goals and watcher ledgers exist; the final portfolio installs OPC, LLM training, Robotics, Agents, and Hardware watches | 68% | Need stronger accepted-change views and longer evidence that no-change cycles do not inflate progress |
| MoonBook memory binding | Research books and generated projections work for research lanes; Wenyu civic books can be bootstrapped with canonical schemas, wiki pages, review queues, and `moonbook-ui-state.json` fragments | 62% | MoonBook should eventually own native civic templates upstream instead of relying on Moontown-generated seeds |
| MoonClaw execution binding | Proposal/run boundary and worker execution path exist; every Wenyu civic module now has a role-specific skill pack path and output contract injected into worker context | 56% | Need repeated successful module-specific service executions and stricter result parsing per contract |
| Real civic services | Moontown can create civic lanes, install recurring protocol schedules, and run building communication patterns | 40% | Policy, contest, social, talent, bridge, market, story, and education modules still need service-specific accepted output histories |
| Designer workflow | Manual JSON config plus standalone editor mode and handoff/bridge visibility | 48% | Needs write-back import/export, asset manifest checks, richer collision preview, and automatic Moondesk artifact ingestion |
| Stable-state cookbook | MoonBook cookbook workspace, stable-state manifest, ownership pages, generated site, and CLI status are in place | 38% | Needs Moondesk management UI, drift comparison, review workflow, and integration into operator dashboard |
| Production readiness | Local development works; build/check pass | 25% | Needs packaged daemon, auth, permissions, backups, observability, and deployment model |

## What Is Real Today

Implemented and validated:

- `viewport.html?assets=generated&v=wenyu-modules` renders the canonical Wenyu
  tile viewport.
- `ui/assets/tilemap/modules/wenyu-town-modules.json` defines 16 enabled Wenyu
  modules: 11 civic buildings and 5 long-horizon research-domain homes.
- The Rabbita bootstrap loads the module registry at runtime.
- MoonBit parses enabled modules and renders them as a separate layer above the
  terrain.
- Building labels stay hidden until hover/focus.
- Clicking a module opens an interior scene.
- The HUD reports total modules, cleanly validated modules, loaded MoonBook
  fragments, and module-config load version.
- Module placement validation reports missing bindings, missing assets, invalid
  footprints, and bad water/road placement.
- Module buildings now declare `style_family`, `asset_base`, `footprint_w`,
  `footprint_h`, `display_w`, `display_h`, `protocol_pattern`, `use_case`, and
  `agent_flow`, so placement, behavior, and art are config-driven.
- The viewport now treats the reference terrain as the only visible road
  system. Module entrances are still configured for routing, but synthetic
  overlay roads are hidden to avoid two competing map systems.
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
- `moon run cmd/main -- civic protocols patterns` lists reusable communication
  patterns: `research-salon`, `signal-watch`, `triage-desk`, `review-council`,
  `match-market`, `learning-cohort`, `story-forge`, and `incident-bridge`.
- `moon run cmd/main -- civic protocols pattern-template <path>` now runs the
  same communication-pattern envelope from a `CivicSalonScenario` JSON file, so
  future domains can be added by template and schedule instead of editing
  MoonBit runner code.
- `moon run cmd/main -- civic protocols pattern-install <path>` installs one
  scenario as a recurring schedule without immediately running MoonClaw.
- `moon run cmd/main -- civic protocols pattern-manifest templates/civic-patterns/wenyu-civic-patterns.json`
  installs the default Wenyu scenario set for all 11 civic buildings with
  staggered due times.
- `moon run cmd/main -- civic protocols schedules status` and
  `moon run cmd/main -- civic protocols schedules tick` expose the recurring
  communication-pattern scheduler. The daemon now checks the same schedule on
  every tick and runs enabled sessions when real wall-clock `next_due_ms` has arrived.
- Research-salon templates write template-defined metrics pages,
  `.moontown/civic/protocols/social-square/metrics.json`, and a
  `home_returns.jsonl` ledger. The structural effectiveness metric tracks
  participant workspaces, reduced ideas, research questions, participant-idea links,
  covered books, and returned idea-home records.
- Recurring salon rounds write an additional
  `.moontown/civic/pattern-runs/<session-id>.jsonl` ledger for long-horizon audit
  and restart inspection.
- Each research-salon participant workspace receives
  `wiki/queries/salon-returned-ideas.md`, so the Social Square building output
  returns to the relevant home workspaces instead of staying as a central
  summary only.
- Social Square currently has protocol status `review`; pattern templates can
  add inbox packets, contributions, reductions, outbox records, home-return
  records, and review gates without adding new MoonBit domain branches.
- The default civic pattern templates cover Town Shell, Resident Twins, Policy
  Hall, Contest Express, Social Square, Talent Avenue, Vitality Tower, AI
  Garden, Physical Bridge, Valley Market, and Broadcast Tower as data.
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

Checked on 2026-05-28 12:49 CST with:

```bash
moon run cmd/main -- status
moon run cmd/main -- daemon doctor
moon run cmd/main -- integration final status
moon run cmd/main -- civic status
moon run cmd/main -- civic protocols schedules status
```

Observed state:

- daemon doctor reports `runtime=healthy`
- daemon status is `running`
- supervisor process and worker process are both alive
- heartbeat age is below the stale threshold
- daemon runtime is at tick `10069` with `6032` successful cycles and `0`
  recorded failures
- town snapshot contains `4` books, `20` workers, `237` tasks, `237`
  executions, and `370` watcher records
- current execution mix is `1` running, `228` review, `0` failed, and `0`
  stale
- final integration domain watch coverage is `5/5`
- active long-horizon books are:
  - `research-opc`
  - `research-how-llms-are-trained-in-very-detail`
  - `research-embodied-robotics`
  - `research-ai-agents`
  - `research-ai-hardware`
- the current planned daemon actions are:
  - `run-start`: `standing-watch-ai-agents-tick-10069` / `RunConfirmed`
  - `standing-goal-due`: `watch-ai-agents` -> `research-ai-agents`
- the latest watcher record is `watch-ai-agents/Deferred`
- the next due watcher tick is scheduled for tick `10070`
- all 11 Wenyu civic service workspaces are operable, with `0` blocked and `0`
  missing/incomplete modules
- civic service `proven by result` is still `0`, meaning the workspaces are
  seeded and schedulable but not yet backed by accepted service-result histories
- 12 recurring communication-pattern schedules are enabled at 30-minute
  intervals: the embodied robotics Social Square salon plus 11 Wenyu civic
  building patterns
- current schedule history includes rounds for Town Shell, Resident Twins,
  Policy Hall, Contest Express, Social Square, Talent Avenue, Vitality Tower,
  AI Garden, Physical Bridge, Valley Market, and Broadcast Tower

Interpretation:

- the local daemon/watch loop is alive under supervisor/worker management
- the five-domain research portfolio is installed and visible to the operator
  console
- the current active watch is the Agents lane, while the other standing goals
  are waiting for their next cadence tick
- communication-pattern schedules are running as recurring civic work, but
  accepted civic service results are not yet flowing back into the civic
  MoonBooks
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
- the viewport was validated with 16 modules, 16 clean placements, 0 issue
  badges, working view/editor/output modes, zoom controls, and direct module
  interior links

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

- Generate final transparent PNG sprites for each module. The first white-tech
  pavilion pack is complete and registered for the 16 active modules.
- Split each building into base, roof, shadow, and optional glow layers.
- Add asset prompts under `ui/assets/tilemap/prompts/`. The white-tech pavilion
  prompt set is now documented for reuse.
- Validate image dimensions and transparency before rendering.
- Reject buildings that overlap water or roads unless the module is explicitly a
  bridge/harbor.

Acceptance:

- Policy Hall, Contest Express, Social Square, Talent Avenue, AI Garden,
  Physical Bridge, Valley Market, Broadcast Tower, Resident Twin Homes, Vitality
  Tower, Town Shell, OPC, LLM Training, Robotics, Agents, and Hardware are
  visually distinguishable at a glance.

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

Implemented:

- Local supervisor/worker process model.
- Launchd installation path for local macOS development.
- Heartbeat, stale worker detection, restart counters, and daemon doctor.
- Nonblocking MoonClaw supervision by default so one long watch does not block
  other standing goals or civic pattern schedules.
- Watcher summary separated into operational activity and domain knowledge
  changes.
- Five standing watches installed through the final integration portfolio.
- Recurring civic communication-pattern schedules installed from JSON.

Remaining:

- Multi-day soak evidence with restart/recovery logs.
- Daily digest generation.
- No-progress alerts.
- Backup and recovery of `.moontown`, MoonBook workspaces, and watcher ledgers.
- Production service packaging beyond the current local launchd development
  seam.

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

1. Let the current supervised daemon run through another overnight window and
   inspect whether each of the five standing watches produced update,
   no-change, deferred, review, or failed records with strict accounting.
2. Turn civic communication-pattern rounds into accepted civic service results:
   Policy Hall, Contest Express, Social Square, Talent Avenue, AI Garden,
   Physical Bridge, Valley Market, Broadcast Tower, Resident Twin Homes,
   Vitality Tower, and Town Shell should each have at least one accepted or
   reviewed service result in its MoonBook.
3. Add accepted-change summaries to the MoonBook UI-state contract and surface
   them in module interiors and output mode.
4. Add daily digest generation for watcher and civic-pattern cycles.
5. Split the current single-layer building PNGs into optional base, roof,
   shadow, and glow layers for stronger 2.5D depth.
6. Add a standalone module config, placement, and asset validator with editor
   write-back.
7. Move reusable civic workspace templates into MoonBook so Moontown only
   requests service creation rather than generating all initial files itself.
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
