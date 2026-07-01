# Moontown

> MoonBit-native town control plane + embedded strategic roles + scene dashboard + Rabbita operator UI

`MoonBit` `Town Orchestration` `MoonBook Extension API` `MoonClaw Proposal Packets` `Mayor` `Keeper` `Routing` `Health` `Storage` `Scene UI` `Rabbita`

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

- persisted town bootstrap in `.moonsuite/products/moontown/town.json`
- persisted standing goal registry in
  `.moonsuite/products/moontown/standing-goals.json`
- persisted moonbook catalog in `.moonsuite/products/moontown/moonbooks.json`
- `BookProvider` abstraction for town bootstrap
- extension-API-shaped moonbook adapter
- external proposal packet and proposal/run receipt lifecycle
- run polling, result persistence, and review-queue surfacing for goal runs
- mayor-level cross-book research synthesis under
  `.moonsuite/products/moontown/town-synthesis/`
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
- planbook operating model for durable `plan.md` driven code/product changes,
  separate from research books and course books

Wenyu Valley product readiness is tracked in:

- [docs/DOC_STRUCTURE.md](/Users/kq/Workspace/moontown/docs/DOC_STRUCTURE.md)
- [docs/PLANBOOK.md](/Users/kq/Workspace/moontown/docs/PLANBOOK.md)
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

- source packages live under `src/`; root stays limited to metadata, docs,
  scripts, templates, and runtime state
- `src/` root is a facade only; implementation files must live in named
  packages, and `./scripts/audit-source-layout.sh` enforces this boundary
- generated dependency/build directories under `src/` are treated as temporary
  artifacts, not architecture; clean ignored frontend artifacts before source
  review if `src/ui/rabbita-town/{node_modules,_build,.mooncakes,dist}` exists
- `src/core` town, book, worker, task, and event modeling
- `src/dispatch` routing and isolation decisions
- `src/storage` snapshot persistence
- `src/health` anomaly and recovery reporting
- `src/scheduler` tick planning
- `src/scheduler` standing-goal due planning
- `src/roles` strategic `Mayor` role adapter
- `src/adapters/moonbook` persisted book catalog plus real MoonBook CLI-backed harness requests
- `src/adapters/moonclaw` embedded runtime profiles plus real MoonClaw proposal import, run, and polling boundary
- `src/ui` scene layout, dashboard projection, and HTML render bridge
- `src/ui/rabbita-town` live browser dashboard with:
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
moon run src/cmd/main -- integration final install
moon run src/cmd/main -- integration final status
```

The manifest lives at:

- `assets/templates/integration/wenyu-final-integration.json`

It is data-driven and currently installs:

- five standing watches: OPC, LLM training, Robotics, Agents, and Hardware
- a Robotics Social Square research-salon scenario
- the Wenyu civic pattern manifest for all 11 civic buildings

The daemon reads those standing goals and pattern schedules during normal
ticks. Domain-specific research state still belongs in each MoonBook; Moontown
only owns scheduling, dispatch, runtime accounting, and operator visibility.
The book-quality audit also merges live books from the saved town snapshot, so
standing-watch books are audited even before they are manually curated into the
MoonBook catalog.

## Wenyu Civic Bootstrap

Create the current Wenyu civic support workspaces with:

```bash
moon run src/cmd/main -- civic bootstrap
```

The bootstrap creates canonical `wenyu-*` support books for Town Shell,
Resident Twin Homes, Policy Hall, Contest Express, Social Square, Talent
Avenue, Vitality Tower, AI Science Garden, Physical Bridge, Valley Market, and
Story Radar. These are not the civic features themselves. The feature boundary
is the building protocol; the MoonBook workspace is the durable support surface
for accepted records, ledgers, review queues, and projection fragments. The
registry marks both `module_mode` and `persistence_mode`, so a building can be
an agent workspace, exchange place, projection surface, gateway, or hybrid, and
can be workspace-backed, ledger-backed, projection-backed,
handoff-ledger-backed, or mixed-memory-backed.

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
moon run src/cmd/main -- civic protocols bootstrap
moon run src/cmd/main -- civic protocols status
moon run src/cmd/main -- civic protocols patterns
moon run src/cmd/main -- civic protocols pattern-template assets/templates/civic-salons/robotics-mini-salon.json
moon run src/cmd/main -- civic protocols pattern-template assets/templates/civic-salons/embodied-robotics-social-square.json
moon run src/cmd/main -- civic protocols pattern-install assets/templates/civic-patterns/policy-hall-triage-desk.json
moon run src/cmd/main -- civic protocols pattern-manifest assets/templates/civic-patterns/wenyu-civic-patterns.json
moon run src/cmd/main -- civic protocols schedules status
moon run src/cmd/main -- civic protocols schedules tick
moon run src/cmd/main -- civic reconcile
moon run src/cmd/main -- civic doctor
```

The communication-pattern runtime is template-driven. New domains and civic
services should provide a `CivicCommunicationScenario` JSON file with participant
books, pattern id, skill rules, quality rules, output paths, and review gates.
`civic protocols pattern-template <path>` runs a scenario directly, persists
the scenario into `.moontown/civic/pattern-scenarios/<session-id>.json`, and
upserts the recurring schedule in `.moontown/civic/pattern-schedules.json`.
`pattern-install <path>` installs one recurring scenario without running it;
`pattern-manifest <path>` installs a set of scenarios with staggered due times.
The default Wenyu manifest covers all 11 civic buildings in
`assets/templates/civic-patterns/`. Moontown should not grow one MoonBit branch per
domain or civic service. See
[docs/CIVIC_COMMUNICATION_TEMPLATES.md](/Users/kq/Workspace/moontown/docs/CIVIC_COMMUNICATION_TEMPLATES.md).

The pattern scheduler is also wired into the 24/7 daemon path. `civic protocols
schedules status` shows `.moontown/civic/pattern-schedules.json`; `civic
protocols schedules tick` runs only wall-clock-due sessions, claims a due
schedule before launching MoonClaw, and appends round records under
`.moontown/civic/pattern-runs/`. Add or remove pattern sessions by editing the
JSON schedule/template files.

`civic reconcile` is the service-result bridge. It reads protocol-active
buildings, writes
`.moonsuite/products/moontown/book-results/goal-<book-id>-civic-service.json`
through MoonBook, and marks review-gated civic outputs as `needs_review`
instead of accepted facts. The daemon runs this reconciliation as a generic
scheduled job after pattern rounds.

## Stable-State Cookbook

Generate or refresh the cookbook with:

```bash
moon run src/cmd/main -- cookbook bootstrap
moon run src/cmd/main -- cookbook status
```

This creates `.moontown/books/moontown-cookbook/`, registers it in
`.moonsuite/products/moontown/moonbooks.json`, and writes
`.moonsuite/products/moontown/cookbook/stable-state.json`. MoonBook generates
and stores the cookbook, Moondesk should become the human desktop surface for
managing it, and Moontown consumes the manifest for drift checks and operator
guidance.

## Planbook Workflow

Moontown now distinguishes four active MoonBook work types:

Book templates are listed in
[assets/templates/books/templates.json](/Users/kq/Workspace/moontown/assets/templates/books/templates.json)
and can be inspected with `moon run src/cmd/main -- books templates`. Moondesk
should use that registry as its creation palette. Runtime book creation requests
can be written to `.moonsuite/products/moontown/book-template-requests.json`;
the daemon’s `book-template-request` job processes pending requests. `status`
reports pending and failed request counts so autonomous book creation is visible
in the same runtime spine as standing watchers.
`live status` and `.moonsuite/products/moontown/live-autonomy.json` also surface the same request
counts, so a Moondesk-created book request is visible before and after the
daemon turns it into a MoonBook workspace.
The Rabbita operator console also exposes this path during development through
`POST /api/book-template-requests`, currently for the `pdf-evidence-watch`
template. That endpoint writes the same config and request documents; it does
not bypass the daemon or create a browser-only workflow.
Processed requests are also appended to
`.moonsuite/products/moontown/book-template-request-events.jsonl`, which is the
durable install and failure audit trail for autonomous book creation.

- `research-book`
  discovers and maintains domain knowledge.
- `pdf-evidence-watch`
  is a specialized research-book template for website/PDF monitoring:
  discover PDFs, download, extract full text, analyze with a book-owned method,
  and notify only when accepted knowledge changes. The reusable template lives
  at [assets/templates/books/pdf-evidence-watch/](/Users/kq/Workspace/moontown/assets/templates/books/pdf-evidence-watch).
  Instantiate it with
  `moon run src/cmd/main -- books pdf-watch bootstrap <book-id>`; the command
  registers the MoonBook catalog entry and standing goal that Moondesk should
  later expose through a creation wizard. For a complete Moondesk-style handoff,
  use `moon run src/cmd/main -- books pdf-watch install <config.json>` with
  [assets/templates/books/pdf-evidence-watch/install.example.json](/Users/kq/Workspace/moontown/assets/templates/books/pdf-evidence-watch/install.example.json).
- `course-book`
  teaches a beginner through lessons, exercises, and checkpoints.
- `planbook`
  writes durable `plan.md` files for code, product, UI, daemon, docs, or civic
  implementation work.
- `cookbook`
  preserves stable definitions, current operating state, and accepted docs.

The planbook is inspired by a plan-first workflow: capture an idea, bug,
screenshot, operator note, or voice transcript; turn it into a structured
`plan.md`; then let MoonClaw execute against that plan and mark acceptance
criteria. The plan file is the restart point when context is lost.

See:

- [docs/PLANBOOK.md](/Users/kq/Workspace/moontown/docs/PLANBOOK.md)
- [docs/DOC_STRUCTURE.md](/Users/kq/Workspace/moontown/docs/DOC_STRUCTURE.md)
- [assets/templates/planbook/PLAN_TEMPLATE.md](/Users/kq/Workspace/moontown/assets/templates/planbook/PLAN_TEMPLATE.md)

Bootstrap the current first-class planbook with:

```bash
moon run src/cmd/main -- planbook bootstrap
moon run src/cmd/main -- planbook status
moon run src/cmd/main -- planbook doctor
moon run src/cmd/main -- planbook autonomy
moon run src/cmd/main -- planbook repair
moon run src/cmd/main -- planbook repair status
```

`planbook doctor` writes `.moonsuite/products/moontown/planbook/autonomy.json`
and `.moonsuite/products/moontown/planbook/autonomy.md`, updates the PlanBook workspace evidence and
review pages, and is also run during daemon ticks. This makes self-build gaps
visible in the live autonomy spine instead of leaving them as static docs.
The PlanBook workspace also owns `raw/backlog/implementation-backlog.json`,
`wiki/planning/implementation-backlog.md`,
`wiki/planning/backlog-progress.md`, `wiki/planning/stop-policy.md`, and
`wiki/history/change-log.md`, so future implementation goals, stop criteria,
cadence, and live changes are managed as MoonBook documents instead of code
constants. While backlog items are open, the town can take them one at a time;
when the backlog is clear, the code-building check decays to 30 minutes.

`planbook repair` turns the first open self-build gap into a bounded repair
packet under the PlanBook workspace. It writes repair context, a repair
`SKILL.md`, a restartable repair plan,
`.moonsuite/products/moontown/planbook/repair-task.json`, and
`.moonsuite/products/moontown/planbook/repair-task.md`. When the daemon sees an open gap and no
active repair, it dispatches one bounded repair packet through MoonClaw with
`execution_mode: acp` and `execution_target: codex-main`, so Codex ACP can patch
the Moontown source root and return software-engineering evidence. Daemon
dispatch is detached by default; the live loop records the run id and keeps
ticking instead of waiting for a long source-repair process inline. Accepted
source repairs must do more than claim success: they must include a
`planbook.repair.patch_receipt.v1` receipt proving source-root ACP execution,
changed files, validation, `git diff --check`, `git status --short`, commit
status/message, and push policy. Without that receipt, PlanBook treats ACP as
wired but not yet proven. Backlog-driven repairs must also write completion
evidence under `raw/backlog/completed/<id>.md`. Use `planbook repair --dispatch`
as an explicit operator/debug trigger; daemon ticks are the normal self-patching
route and do not duplicate active repairs. If a worker discovers the requested
work is already done, it should update the plan/progress evidence instead of
generating code churn.
Transient repair dispatch contention is treated as queued retry, not a blocked
PlanBook gap.

Every registered book also needs a book-scoped watcher lane. Built-in
operational books such as `coding` and `finance` still keep their specialized
harness/reviewer/specialist workers, but the Mayor now provisions a matching
`claw-<book-id>-watcher` slot as well. A standing watch is a book-local protocol,
so it must not retry forever only because an operational book lacks a watcher
worker.

## Book Quality Governance

Use the structural doctor first:

```bash
moon run src/cmd/main -- books bootstrap
moon run src/cmd/main -- books doctor
moon run src/cmd/main -- books quality
```

This writes `.moonsuite/products/moontown/book-quality/audit.json` and
`.moonsuite/products/moontown/book-quality/audit.md`. The structural readiness
column is
deliberately deterministic: it checks required workspaces, contracts, skills,
projections, and whether a civic service has at least one real service-loop
result. It is not a quality score.

`books bootstrap` now materializes the canonical registered book families, not
only the default operational books:

- operational books for coding and finance memory
- the stable-state cookbook
- the implementation planbook
- the Wenyu beginner course book
- the Wenyu civic protocol support workspaces

The generated workspaces are intentionally genre-specific. Course books get
lessons and exercises, planbooks get plans/evidence/review logs, cookbook gets
stable-state definitions, and civic protocol support workspaces get the minimum
durable substrate required by their persistence mode: schemas, ledgers, review
queues, service history, projections, and building-protocol contracts. A
ledger-backed exchange place should not be judged like a research book.

Generate semantic AI review packets with:

```bash
moon run src/cmd/main -- books ai-review-packets
moon run src/cmd/main -- books ai-review bridge
```

Those packets live under
`.moonsuite/products/moontown/book-quality/ai-review-packets/` and should
be reviewed by MoonClaw/MoonBook using `BOOK_QUALITY_REVIEW_SKILL.md` plus each
book's own contract and `SKILL.md`. The resulting `ai_quality_score` should be
written to
`.moonsuite/products/moontown/book-quality/ai-review-results/<book-id>.md`.
World-class
quality should be decided by that AI review layer, not by hard-coded
file-existence checks.

The daemon includes a bounded `review-book-quality` cadence that dispatches one
pending semantic review at a time, suppresses duplicate active reviews, and
launches scheduled review work detached from the daemon tick so the Mayor loop
keeps supervising other work.
Before dispatching another review, the same cadence reconciles completed weak
AI reviews into durable repair work: it writes
`wiki/reviews/book-quality-repair.md` inside the affected MoonBook workspace,
updates `.moonsuite/products/moontown/book-quality/repair-bridge.json`, and
creates or refreshes a
`book-quality-repair-<book-id>` standing goal. That makes quality findings part
of the live growth loop instead of a dead-end report. Archived, hidden, or
internal books are excluded from this repair bridge, so retired smoke proofs
stay auditable without being reactivated by semantic review. If a later AI
review shows the book has crossed the quality threshold, the bridge retires the
stale repair standing goal so the daemon can return to stable watching instead
of repeatedly polling a satisfied gap.
`books ai-review status` reports the latest current state per book first, then
keeps older blocked/orphaned attempts in a historical section. A recovered old
failure remains auditable without making the town look degraded.

## Standing Goal Model

The long-standing runtime split is:
See [Executable Book Coordination](docs/EXECUTABLE_BOOK_COORDINATION.md) for the current boundary: Moontown coordinates books, not only schedules them.


```text
Mayor -> Book Keeper -> Worker Claws
```

- `Mayor`
  owns standing goals, daemon ticks, routing, health, and recovery.
- `Book Keeper`
  is a resident book role. It is logically live through scheduled or event-driven
  keeper ticks and owns durable book memory, wiki promotion, review policy,
  source/evidence ledgers, next questions, and generated projection quality.
- `Worker Claws`
  are freelance executors. They spawn for bounded jobs such as search, fetch,
  synthesis, coding, image generation, review, and result packaging, then leave.

Bookkeepers do not need to burn a hot process continuously, but every important
MoonBook should have a keeper policy/profile that can wake on new results,
standing-watch updates, stale projections, review queue changes, or explicit
operator requests.

Standing goals are data-driven. Add long-horizon watchers by editing
`.moonsuite/products/moontown/standing-goals.json`; the daemon reads the
registry on each tick, so new topics do not require MoonBit code changes.

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

- `.moonsuite/products/moontown/standing-goals.json`

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
  -> Moontown records .moonsuite/products/moontown/watchers/<goal-id>.jsonl
  -> next_due_tick advances with update/no-change/review/failure backoff
```

Daemon-triggered standing-watch handoffs are detached from the tick loop. The
Mayor records the run id, persists a running snapshot, and later reconciles the
MoonBook standing-watch marker, instead of holding the daemon inside a long
MoonClaw import/run. When the supervised environment sets
`MOONTOWN_MOONCLAW_INLINE=1`, the detached child still asks MoonClaw to confirm
and run the proposal inline inside that child process; the Mayor loop stays
nonblocking while avoiding orphaned confirmed runs.
If a detached import times out, the stale execution summary includes the
captured `.import.json.err` excerpt so ownership is visible instead of being
reported as a generic missing-receipt timeout.
The Mayor also compacts oversized book-local MoonClaw hot-store JSON files
before standing-watch imports by archiving them under
`.moonclaw/jobs/archive/tick-<tick>/` and replacing the active files with valid
empty indexes. This keeps long-lived books from stalling on proposal-store
serialization growth while preserving historical audit material.
Transient dispatch failures such as temporary file/resource contention are
classified as `deferred` with immediate retry cadence, not as domain research
findings or durable review progress.
Likewise, an orphaned MoonClaw run that is still indexed as `Running` but has
no live proposal process is not counted as `no_change` unless MoonBook also
persisted a terminal standing-watch marker. Without that marker it remains
deferred infrastructure recovery accounting, so no-change totals measure real
baseline checks instead of hidden worker loss. When the latest watcher is
deferred, the live autonomy spine reports it as retry/accounting debt instead
of showing the generic idle “wait for cadence” action.

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
  moonbook catalog and extension API boundary
- `adapters/moonclaw`
  embedded runtime profiles plus real MoonClaw proposal import, run, and polling boundary
- `ui`
  scene contract, dashboard model, and render model
- `src/ui/rabbita-town`
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
moon run src/cmd/main
```

Run one restart-safe daemon tick:

```bash
moon run src/cmd/main -- daemon tick
```

Run the durable daemon loop:

```bash
moon run src/cmd/main -- daemon run
```

Start the supervised background daemon:

```bash
moon run src/cmd/main -- daemon start
moon run src/cmd/main -- daemon doctor
```

Stop the supervised background daemon:

```bash
moon run src/cmd/main -- daemon stop
```

If the host process manager cleans up detached children, run the worker loop in
the foreground instead:

```bash
moon run src/cmd/main -- daemon run
```

On macOS, install the supervisor under launchd so it survives shell, Codex, and
terminal cleanup. The supervisor keeps the worker alive and restarts it when the
heartbeat becomes stale:

```bash
./scripts/install-launchd-daemon.sh
moon run src/cmd/main -- daemon doctor
```

The launchd installer enables bounded inline MoonClaw execution for supervised
handoffs, so PlanBook repair and semantic book-review jobs can mature the town
without waiting for a human shell to run detached commands.

Stop the launchd-managed daemon:

```bash
./scripts/uninstall-launchd-daemon.sh
```

Run a single daemon-loop iteration for verification:

```bash
moon run src/cmd/main -- daemon run --once
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
cd src/ui/rabbita-town
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
  -> mayor writes .moonsuite/products/moontown/town-synthesis/*.md
```

Current standing-goal path:

```text
.moonsuite/products/moontown/standing-goals.json
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

- `src/ui/scene_layout.mbt`
- `ui/dashboard.mbt`
- `src/ui/scene_render.mbt`

Current scene places:

- Town Gate
- City Hall
- Moonbook / Coding
- Moonbook / Finance
- Worker Yard
- Anomaly Corner

Current asset folders:

- `src/ui/assets/backgrounds/`
- `src/ui/assets/buildings/`
- `src/ui/assets/actors/`
- `src/ui/assets/props/`
- `src/ui/assets/effects/`

The current assets are original `moontown` starter SVGs, not copied `sou`
assets.

## Rabbita Frontend

`src/ui/rabbita-town/` is the browser-facing simulation dashboard. It is not a game
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
- [docs/DOC_STRUCTURE.md](/Users/kq/Workspace/moontown/docs/DOC_STRUCTURE.md)
- [docs/PLANBOOK.md](/Users/kq/Workspace/moontown/docs/PLANBOOK.md)
- [docs/PACKAGES.md](/Users/kq/Workspace/moontown/docs/PACKAGES.md)
- [docs/FRONTEND.md](/Users/kq/Workspace/moontown/docs/FRONTEND.md)
- [docs/DEVELOPMENT.md](/Users/kq/Workspace/moontown/docs/DEVELOPMENT.md)
