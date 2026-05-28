# Moontown

> MoonBit-native town control plane + embedded strategic roles + scene dashboard + Rabbita operator UI

`MoonBit` `Town Orchestration` `MoonBook Harness` `MoonClaw Proposal Packets` `Mayor` `Keeper` `Routing` `Health` `Storage` `Scene UI` `Rabbita`

Moontown is the town-level orchestration layer above multiple `moonbook`
domains and multiple `moonclaw` runtimes.

It is designed for:

- town-wide routing and scheduling
- standing goals and durable mayor supervision
- domain isolation across multiple books
- embedded role-specialized planning runtimes
- long-lived town state and snapshots
- scene-based operator visibility
- stable docs/definition cookbook control
- browser-facing simulation dashboards

## What Moontown Feels Like

```text
 moonbook catalog / keeper packets / mayor
  -> seed a town
  -> load standing goals such as "track OPC news"
  -> Mayor decides when a standing goal is due
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
- persisted standing goal registry in `.moontown/standing-goals.json`
- persisted moonbook catalog in `.moontown/moonbooks.json`
- `BookProvider` abstraction for town bootstrap
- book-harness-shaped moonbook adapter
- external proposal packet and proposal/run receipt lifecycle
- run polling, result persistence, and review-queue surfacing for goal runs
- mayor-level cross-book research synthesis under `.moontown/town-synthesis/`
- town quality gates for provisional or non-lane-specific research output
- one-shot, foreground, and supervised background daemon commands for mayor supervision
- daemon runtime health, heartbeat, PID, log, stale-worker detection, and restart policy
- standing-goal due planning and dispatch into explicit MoonBook keeper lanes
- strategic `Mayor` role adapter over embedded moonclaw runtime metadata
- routing, isolation, scheduler, health, and storage packages
- renderer-agnostic scene dashboard model
- Rabbita live simulation frontend
- original example SVG scene assets
- Wenyu Valley standalone tile viewport with configurable civic module
  buildings and clickable interiors
- Wenyu civic service registry and `civic bootstrap` command that creates
  module-mode-aware support workspaces, schemas, review queues, generated
  projections, and dedicated MoonClaw skill contracts for enabled civic modules
- civic communication-pattern registry: `research-salon`, `signal-watch`,
  `triage-desk`, `review-council`, `match-market`, `learning-cohort`,
  `story-forge`, and `incident-bridge`
- final integration portfolio installer that combines the current five
  long-horizon research domains with the Wenyu civic pattern manifest
- MoonBook-generated `moontown-cookbook` control book for canonical docs,
  definitions, runtime-state indexes, and stable-state drift checks

Wenyu Valley product readiness is tracked in:

- [docs/WENYU_VALLEY_PRD.md](/Users/kq/Workspace/moontown/docs/WENYU_VALLEY_PRD.md)
- [docs/WENYU_UI_MODULE_SYSTEM.md](/Users/kq/Workspace/moontown/docs/WENYU_UI_MODULE_SYSTEM.md)
- [docs/WENYU_BUILDING_PROTOCOL_PLAN.md](/Users/kq/Workspace/moontown/docs/WENYU_BUILDING_PROTOCOL_PLAN.md)
- [docs/WENYU_TOWN_STATUS.md](/Users/kq/Workspace/moontown/docs/WENYU_TOWN_STATUS.md)
- [docs/CIVIC_COMMUNICATION_PATTERNS.md](/Users/kq/Workspace/moontown/docs/CIVIC_COMMUNICATION_PATTERNS.md)
- [docs/FINAL_INTEGRATION.md](/Users/kq/Workspace/moontown/docs/FINAL_INTEGRATION.md)
- [docs/COOKBOOK.md](/Users/kq/Workspace/moontown/docs/COOKBOOK.md)

The status document is the source of truth for the latest observed distance to
a fully functioning town. It separates the visual town shell, the local 24/7
control-plane prototype, the final research/civic integration portfolio, and
the unfinished production civic-service system.

Still incomplete:

- production-grade OS-level service installation through
  launchd/systemd/container supervision and multi-day soak evidence
- experiment lifecycle execution
- repeated successful Wenyu civic workflow executions with accepted MoonBook
  updates, structured service ledgers, and real backend/frontend sync

So the current repo now has a local supervised 24/7 daemon seam. It can run a
background supervisor/worker pair, detect stale workers, restart them, and
record runtime health. The active local portfolio currently covers OPC, LLM
training, Robotics, Agents, Hardware, and recurring Wenyu civic pattern
schedules. It is still not a production service until it has packaged
deployment, backups, auth, and multi-day recovery evidence.

## Current Capabilities

- `core` town, book, worker, task, and event modeling
- `dispatch` routing and isolation decisions
- `storage` snapshot persistence
- `health` anomaly and recovery reporting
- `scheduler` tick planning
- `scheduler` standing-goal due planning
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

## Final Integration Portfolio

Install the current all-up local portfolio with:

```bash
moon run cmd/main -- integration final install
moon run cmd/main -- integration final status
```

The manifest lives at:

- `templates/integration/wenyu-final-integration.json`

It is data-driven and currently installs:

- five standing watches: OPC, LLM training, Robotics, Agents, and Hardware
- a Robotics Social Square research-salon scenario
- the Wenyu civic pattern manifest for all 11 civic buildings

The daemon reads those standing goals and pattern schedules during normal
ticks. Domain-specific research state still belongs in each MoonBook; Moontown
only owns scheduling, dispatch, runtime accounting, and operator visibility.

## Wenyu Civic Bootstrap

Create the current Wenyu civic support workspaces with:

```bash
moon run cmd/main -- civic bootstrap
```

The bootstrap creates canonical `wenyu-*` support books for Town Shell, Resident Twin
Homes, Policy Hall, Contest Express, Social Square, Talent Avenue, Vitality
Tower, AI Science Garden, Physical Bridge, Valley Market, and Story Radar. Each
book is seeded with workspace contracts, schemas, review queues, generated
projection files, and dedicated MoonClaw skill contracts. The registry also
marks whether the building is an agent workspace, exchange place, projection
surface, gateway, or hybrid. This gives the town real civic module bindings; it
does not mean every civic feature should behave like a research book.

The building-as-protocol layer has started. Each civic building now has a
protocol definition and seeded `BUILDING_PROTOCOL_CONTRACT.md`; Social Square
has the first durable protocol proof slice with inbox, contribution, reduction,
outbox, review, home-return, and effectiveness metric ledgers. The goal is for
every civic building to accept input packets, aggregate agent/book/resident
signals, let agents exchange information under a specific social protocol, use
MoonClaw skills to reduce the gathered context into a building-native output,
and distribute the result to MoonBook, the UI, review queues, mayor alerts, or
confirmation-gated external handoff. See
[docs/WENYU_BUILDING_PROTOCOL_PLAN.md](/Users/kq/Workspace/moontown/docs/WENYU_BUILDING_PROTOCOL_PLAN.md).

Inspect protocol state with:

```bash
moon run cmd/main -- civic protocols bootstrap
moon run cmd/main -- civic protocols status
moon run cmd/main -- civic protocols patterns
moon run cmd/main -- civic protocols pattern-template templates/civic-salons/robotics-mini-salon.json
moon run cmd/main -- civic protocols pattern-template templates/civic-salons/embodied-robotics-social-square.json
moon run cmd/main -- civic protocols pattern-install templates/civic-patterns/policy-hall-triage-desk.json
moon run cmd/main -- civic protocols pattern-manifest templates/civic-patterns/wenyu-civic-patterns.json
moon run cmd/main -- civic protocols schedules status
moon run cmd/main -- civic protocols schedules tick
moon run cmd/main -- civic doctor
```

The communication-pattern runtime is template-driven. New domains and civic
services should provide a `CivicSalonScenario` JSON file with participant
books, pattern id, skill rules, quality rules, output paths, and review gates.
`civic protocols pattern-template <path>` runs a scenario directly, persists
the scenario into `.moontown/civic/pattern-scenarios/<session-id>.json`, and
upserts the recurring schedule in `.moontown/civic/pattern-schedules.json`.
`pattern-install <path>` installs one recurring scenario without running it;
`pattern-manifest <path>` installs a set of scenarios with staggered due times.
The default Wenyu manifest covers all 11 civic buildings in
`templates/civic-patterns/`. Moontown should not grow one MoonBit branch per
domain or civic service. See
[docs/CIVIC_SALON_TEMPLATES.md](/Users/kq/Workspace/moontown/docs/CIVIC_SALON_TEMPLATES.md).

The pattern scheduler is also wired into the 24/7 daemon path. `civic protocols
schedules status` shows `.moontown/civic/pattern-schedules.json`; `civic
protocols schedules tick` runs only wall-clock-due sessions, claims a due
schedule before launching MoonClaw, and appends round records under
`.moontown/civic/pattern-runs/`. Add or remove pattern sessions by editing the
JSON schedule/template files.

## Stable-State Cookbook

Generate or refresh the cookbook with:

```bash
moon run cmd/main -- cookbook bootstrap
moon run cmd/main -- cookbook status
```

This creates `.moontown/books/moontown-cookbook/`, registers it in
`.moontown/moonbooks.json`, and writes
`.moontown/cookbook/stable-state.json`. MoonBook generates and stores the
cookbook, Moondesk should become the human desktop surface for managing it, and
Moontown consumes the manifest for drift checks and operator guidance.

## Standing Goal Model

The long-standing runtime split is:

```text
Mayor -> Book Keeper -> Worker Claws
```

- `Mayor`
  owns standing goals, daemon ticks, routing, health, and recovery.
- `Book Keeper`
  owns durable book memory, wiki updates, review policy, and generated
  projection quality.
- `Worker Claws`
  execute bounded jobs such as search, fetch, synthesis, coding, image
  generation, review, and result packaging.

Standing goals are data-driven. Add long-horizon watchers by editing
`.moontown/standing-goals.json`; the daemon reads the registry on each tick, so
new topics do not require MoonBit code changes.

Example:

```json
{
  "id": "watch-llm-training",
  "title": "Track LLM training research",
  "prompt": "Maintain a long-horizon research watch on how LLMs are trained in detail. Use web search first, screen sources, compare against the book baseline, and update only when useful evidence changes the baseline.",
  "target_book_id": "research-how-llms-are-trained-in-very-detail",
  "cadence_ticks": 60,
  "next_due_tick": 0,
  "enabled": true,
  "source_policy": "web-first",
  "quality_threshold": 90
}
```

The registry is persisted at:

- `.moontown/standing-goals.json`

The daemon does not put topic memory in Moontown. Moontown only decides that a
standing goal is due and dispatches it to its `target_book_id` MoonBook lane.
MoonBook owns the durable topic wiki, and MoonClaw owns bounded research
execution.

The 24/7 watcher path now uses an explicit standing-watch contract instead of
unconditionally running a full research pass whenever a goal is due:

```text
daemon tick
  -> due standing goal
  -> book-local standing-watch task
  -> MoonBook compares the topic against its own baseline
  -> MoonClaw performs bounded web/source discovery
  -> MoonBook emits standing_goal_decision
  -> Moontown records .moontown/watchers/<goal-id>.jsonl
  -> next_due_tick advances with update/no-change/review/failure backoff
```

If a MoonClaw run is retried, the Mayor records the retry as operational
history and then re-reads the MoonBook standing-watch decision after the retry
settles. The final watcher row must contain the real task/run id and strict
accounting markers, so tomorrow's status view can distinguish "still alive and
checked sources" from "process churn happened".

Required MoonBook result marker:

```text
standing_goal_decision: update | no_change | needs_review | failed
delta_score: 0-100
new_source_count: <integer>
next_check_hint: normal | slower | faster | review
checked_sources_count: <integer>
new_sources_found: <integer>
accepted_facts_count: <integer>
rejected_facts_count: <integer>
wiki_pages_changed_count: <integer>
book_changed: yes | no
```

Moontown only consumes this marker for scheduling and UI status. It does not
decide whether topic research is novel; that remains a MoonBook keeper decision.
No-change and failed checks are operational activity, not evidence progress:
accepted facts, changed pages, and `book_changed` must stay zero/no unless
durable book knowledge changed or a review item was queued.

Validated accounting example:

```text
decision: no_change
checked_sources_count: 4
new_sources_found: 1
accepted_facts_count: 0
rejected_facts_count: 1
wiki_pages_changed_count: 0
book_changed: no
```

This means the watcher really ran and screened sources, but MoonBook rejected
the candidate as insufficient for durable knowledge. The town UI should show
activity and judgement, not pretend that the book improved.

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
  snapshot, checkpoint, standing-goal, and watcher-ledger persistence
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

Run one restart-safe daemon tick:

```bash
moon run cmd/main -- daemon tick
```

Run the durable daemon loop:

```bash
moon run cmd/main -- daemon run
```

Start the supervised background daemon:

```bash
moon run cmd/main -- daemon start
moon run cmd/main -- daemon doctor
```

Stop the supervised background daemon:

```bash
moon run cmd/main -- daemon stop
```

If the host process manager cleans up detached children, run the worker loop in
the foreground instead:

```bash
moon run cmd/main -- daemon run
```

On macOS, install the supervisor under launchd so it survives shell, Codex, and
terminal cleanup. The supervisor keeps the worker alive and restarts it when the
heartbeat becomes stale:

```bash
./scripts/install-launchd-daemon.sh
moon run cmd/main -- daemon doctor
```

Stop the launchd-managed daemon:

```bash
./scripts/uninstall-launchd-daemon.sh
```

Run a single daemon-loop iteration for verification:

```bash
moon run cmd/main -- daemon run --once
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
  -> standing goal registry
  -> Mayor due-goal decision
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

Current standing-goal path:

```text
.moontown/standing-goals.json
  -> daemon tick
  -> Mayor dispatches due standing goal
  -> explicit MoonBook keeper lane, e.g. research-opc
  -> MoonClaw bounded worker execution
  -> MoonBook durable wiki/site persistence
  -> standing goal next_due_tick advanced
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
