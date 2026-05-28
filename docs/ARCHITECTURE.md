# Architecture

`moontown` is designed as the top layer of a three-part system:

```text
moontown -> moonbook -> moonclaw
```

The Wenyu Valley product plan is tracked separately in
[WENYU_VALLEY_PRD.md](/Users/kq/Workspace/moontown/docs/WENYU_VALLEY_PRD.md).
That document defines the programmable roadmap for turning the current town
prototype into a MoonBook/MoonClaw-backed civic AI town.

The civic-building protocol correction is tracked in
[WENYU_BUILDING_PROTOCOL_PLAN.md](/Users/kq/Workspace/moontown/docs/WENYU_BUILDING_PROTOCOL_PLAN.md).
That document defines the next architecture step: each Wenyu building should
act as an AI-mediated protocol place for aggregation, exchange, reduction, and
distribution, not merely as a research book or static UI card.

The implementation refactor plan is tracked in
[REFACTOR_PLAN.md](/Users/kq/Workspace/moontown/docs/REFACTOR_PLAN.md). That
document is the source of truth for splitting the current working prototype
into stable package boundaries without changing behavior first.

The stable-state cookbook is tracked in
[COOKBOOK.md](/Users/kq/Workspace/moontown/docs/COOKBOOK.md). The cookbook is a
MoonBook-generated control book that indexes canonical docs, machine-readable
definitions, and restart-readable runtime state. Moondesk should manage the
human desktop surface for that cookbook; Moontown consumes its manifest for
stable-state checks and drift review.

## Layer Responsibilities

### `moontown`

`moontown` is the town-wide control plane.

It should own:

- global orchestration
- routing and isolation policy
- standing goals and daemon cadence
- health monitoring and recovery
- scheduling and patrol
- experiment control
- operator UI
- town-wide persistence
- cross-book research synthesis
- town-level acceptance and quality gates
- high-level civic runtime facade calls
- cookbook manifest consumption and drift checks

It should not become:

- the place where book-local memory lives
- the place where execution tooling lives
- a generic raw worker runtime
- the place where building-specific civic scenarios or reducers are hardcoded

### `moonbook`

`moonbook` is the per-domain harness layer.

It should own:

- workspace root and domain identity
- memory policy and durable memory
- context hydration
- local planning
- result review and persistence decisions
- generated cookbook workspace and stable-state wiki pages

It should not become:

- the global scheduler
- the worker execution engine

### `moonclaw`

`moonclaw` is the underlying agent substrate.

It should own:

- role-specialized runtimes
- task execution
- tools and skills
- session state
- result packaging

It should not own:

- town policy
- book-local durable memory

## Embedded Role Model

The intended design is not “copy moonclaw into each repo”. It is “embed one
agent substrate behind strong role adapters”.

### Mayor

The town embeds a constrained moonclaw runtime as `Mayor`.

Current implementation lives in:

- [roles/mayor.mbt](/Users/kq/Workspace/moontown/roles/mayor.mbt)
- [adapters/moonclaw/client.mbt](/Users/kq/Workspace/moontown/adapters/moonclaw/client.mbt)

Current properties:

- planning layer: strategic
- runtime mode: planner-only
- tool access: limited
- memory scope: global
- delegates to keepers
- no direct workspace writes
- no execution tools by default

Town code should call:

- `Mayor.decide_dispatch(...)`
- `Mayor.patrol(...)`
- `Mayor.prepare_keeper_packet(...)`
- `Mayor.handoff_to_keeper(...)`

### Keeper

The book-local embedded moonclaw runtime is modeled as `keeper`.

Current shape:

- planning layer: domain
- runtime mode: planner-only
- memory scope: domain
- tools limited to book-local control surfaces

In the current repo, `moontown` now prepares real keeper proposal packets using
book-harness-shaped context from the moonbook adapter. The actual keeper
implementation still belongs on the `moonbook` side.

### Worker

Execution claws remain separate from strategic/domain planning roles.

Current worker runtime metadata:

- planning layer: execution
- runtime mode: executor
- full tool access
- workspace memory scope
- task/result envelope boundary

## Data Ownership

The clean ownership rule is:

- if it is town-wide, it belongs to `moontown`
- if it is domain-specific and durable, it belongs to `moonbook`
- if it is task/session-specific, it belongs to `moonclaw`

Examples:

- `TownState`, `AssignmentPlan`, `TownEvent`, `TaskExecutionRecord`
  - `moontown`
- workspace root, memory records, domain summaries
  - `moonbook`
- tool traces, session state, execution logs
  - `moonclaw`

## Current Runtime Flow

### Bootstrap

```text
moonbook catalog
  -> BookProvider
  -> book task batch
  -> worker context bundle
  -> external proposal packet
  -> MoonClaw proposal import
  -> confirmed MoonClaw run
  -> terminal run polling
  -> MoonBook result persistence/build
  -> task execution records and seeded TownState
  -> persisted TownSnapshot
  -> dashboard/render/frontend
```

### Goal Run

```text
user goal
  -> Mayor.plan_goal(...)
  -> one or more isolated MoonBook lanes
  -> MoonBook accept/plan/context APIs
  -> Mayor.prepare_keeper_packet(...)
  -> MoonClaw import/run/poll lifecycle
  -> MoonBook persist/build/summary APIs
  -> mayor research quality gate
  -> town-level synthesis under .moontown/town-synthesis/
  -> persisted TownSnapshot
```

The key design rule is that Moontown can decide whether a lane is acceptable,
but it does not become the research engine. MoonBook owns the workspace and
durable wiki state. MoonClaw owns execution and tool use. Moontown owns
cross-book readiness, supervision, and operator-visible acceptance.

The town synthesis is intentionally cross-book rather than book-local. It
combines the lane outputs into an executive summary, integrated research
narrative, lane matrix, relationship model, evidence trail, comparative
findings, and maturity/gap section. The evidence trail points back to each
book's `raw/bootstrap/` research artifacts, including W-source and L-source
rows.

### Wenyu Civic Service Bootstrap

Wenyu civic modules use the same ownership rule as research lanes, but they are
configured as long-lived civic modules rather than one-off research topics. A
module can be an `agent-workspace`, `exchange-place`, `projection-surface`,
`gateway`, or `hybrid`; MoonBook is a durable support workspace only when that
module needs memory, wiki pages, review queues, or generated projections.

The stronger target model is building-as-protocol:

```text
input packets
  -> building inbox
  -> AI-guided aggregation
  -> building-specific exchange
  -> AI-guided reduction
  -> review/safety gate
  -> distribution to MoonBook, UI, agents, mayor, or external handoff
```

This is similar to map/reduce, but only the envelope, routing, ledgers,
channels, permissions, and review gates should be hardcoded. The building
skill pack should guide MoonClaw to choose the right reduction strategy for the
building's social responsibility.

Refactor rule: the daemon may run a scheduled civic communication-pattern job,
but it must not know the details of any building-specific scenario. Those
details belong in a scenario template, selected communication pattern, and
building skill rules, behind a civic protocol runtime boundary.
`research-salon` is one pattern, not the whole abstraction.

```text
civic service registry
  -> module mode + dedicated skill mode
  -> canonical wenyu-* support MoonBook catalog entries
  -> civic workspace seeds
  -> module schemas, wiki pages, review queues
  -> generic and module-specific MoonClaw skills
  -> book/moonbook-ui-state.json
  -> viewport module projection
```

Current implementation lives in:

- [civic/services.mbt](/Users/kq/Workspace/moontown/civic/services.mbt)
- [civic/protocols.mbt](/Users/kq/Workspace/moontown/civic/protocols.mbt)
- [civic_workspace.mbt](/Users/kq/Workspace/moontown/civic_workspace.mbt)
- [civic_status.mbt](/Users/kq/Workspace/moontown/civic_status.mbt)
- [civic_protocol_registry_runtime.mbt](/Users/kq/Workspace/moontown/civic_protocol_registry_runtime.mbt)
- [civic_protocol_store.mbt](/Users/kq/Workspace/moontown/civic_protocol_store.mbt)
- [civic_protocol_status_runtime.mbt](/Users/kq/Workspace/moontown/civic_protocol_status_runtime.mbt)
- [civic_protocol_social_square_fixture.mbt](/Users/kq/Workspace/moontown/civic_protocol_social_square_fixture.mbt)
- [civic_salon_scenario_types.mbt](/Users/kq/Workspace/moontown/civic_salon_scenario_types.mbt)
- [civic_salon_scenario_runtime.mbt](/Users/kq/Workspace/moontown/civic_salon_scenario_runtime.mbt)
- [civic_salon_runner.mbt](/Users/kq/Workspace/moontown/civic_salon_runner.mbt)
- [docs/CIVIC_SALON_TEMPLATES.md](/Users/kq/Workspace/moontown/docs/CIVIC_SALON_TEMPLATES.md)

Implemented protocol pieces:

- building protocol definitions for inbox, contribution, reduction,
  distribution, and review channels
- append-only protocol ledgers under `.moontown/civic/protocols/<building-id>/`
- civic workspace `BUILDING_PROTOCOL_CONTRACT.md` seed files
- Social Square proof ledgers with one consent-gated review slice
- Social Square salon slices loaded from `CivicSalonScenario` templates, with
  intermediate participant workspaces, perspective packets, cross-area idea
  reductions, and a reviewable question backlog surfaced through the building
  book
- generic `CivicSalonScenario` loading so a new domain can be added by JSON
  template and schedule entry rather than a new MoonBit branch
- salon effectiveness metrics for idea yield, research-question yield,
  cross-book links, home-book coverage, and returned idea-home records
- return-home pages in each participating internal workspace so reduced ideas
  leave the building and become local reviewable work
- public projection filtering so intermediate salon participant workspaces and stale
  retry attempts do not crowd the operator book list
- wall-clock communication-pattern schedules under `.moontown/civic/pattern-schedules.json`
- append-only communication-pattern round records under `.moontown/civic/pattern-runs/`
- daemon-tick integration that runs due salons without hard-coding them into
  the frontend

Still planned:

- MoonClaw reducer packets that read `SKILL.md` and choose the module-native
  aggregation/reduction behavior
- real scenario packets for each non-Social-Square civic building
- MoonBook accept/reject persistence for reductions
- richer viewport projection fields for inbox pressure, active reduction,
  pending review, and recent distribution history

The CLI entry is:

```bash
moon run cmd/main -- civic bootstrap
moon run cmd/main -- civic protocols bootstrap
moon run cmd/main -- civic protocols status
moon run cmd/main -- civic protocols pattern-template templates/civic-salons/robotics-mini-salon.json
moon run cmd/main -- civic protocols schedules status
moon run cmd/main -- civic protocols schedules tick
moon run cmd/main -- civic doctor
```

The recurring-salon path is intentionally schedule-driven and
template-driven. Operators can edit `.moontown/civic/pattern-schedules.json` to
enable/disable salons or adjust `interval_ms`, and can edit
`.moontown/civic/pattern-scenarios/<session-id>.json` to change the domain,
participants, skill rules, output paths, and review gate without changing
MoonBit. The daemon tick calls the same due-check as
`civic protocols schedules tick`, then records completion in JSONL for restart
inspection.

The registry covers Town Shell, Resident Twin Homes, Policy Hall, Contest
Express, Social Square, Talent Avenue, Vitality Tower, AI Science Garden,
Physical Bridge, Valley Market, and Story Radar. Each service has a book id,
module mode, book role, skill mode, schema pages, wiki pages, review queues,
worker role, skill pack, output contract, and projection summary.

Civic books intentionally bypass the Wenyu product research/bootstrap quality
gate. Their first task is the registry-defined `civic-service-workflow`, while
non-civic Wenyu books can still use product-build research, implementation,
code-patch, and asset-pack stages.

This is intentionally a bootstrap bridge. Durable civic-domain memory still
belongs in MoonBook, and tool execution still belongs in MoonClaw. As the
contract stabilizes, reusable civic workspace templates should move into
MoonBook so Moontown requests workspace creation instead of writing every seed
file itself.

Protocol ownership remains the same:

- Moontown owns building routing, inbox/outbox ledgers, review gates, protocol
  status, and mayor supervision.
- MoonBook owns durable accepted civic records, schemas, review queues, and
  generated projections.
- MoonClaw owns AI-guided aggregation, reduction, drafting, source discovery
  when required, and result packaging.

### Standing Goal Run

Standing goals are durable town-level obligations. They are not book memory and
not worker sessions.

```text
.moontown/standing-goals.json
  -> daemon tick
  -> Mayor checks due standing goals
  -> Mayor dispatches a target-book standing-watch task
  -> MoonBook hydrates book-local baseline and context
  -> MoonClaw executes bounded web/source discovery
  -> MoonBook decides update/no_change/needs_review/failed
  -> MoonBook persists wiki/source/timeline/synthesis updates when useful
  -> Moontown records a watcher ledger entry
  -> Moontown advances next_due_tick with backoff
```

Retries use the same ownership boundary. Moontown may retry or poll the
execution, but it does not reinterpret the domain result. After a retry settles,
Moontown asks the target MoonBook history for the final standing-watch decision,
records a corrected watcher ledger row, and advances the standing goal from
that MoonBook decision.

The final integration portfolio currently installs five standing goals:

- `watch-opc-news` -> `research-opc`
- `watch-llm-training` -> `research-how-llms-are-trained-in-very-detail`
- `watch-embodied-robotics` -> `research-embodied-robotics`
- `watch-ai-agents` -> `research-ai-agents`
- `watch-ai-hardware` -> `research-ai-hardware`

The Mayor owns when each goal runs. The target MoonBook keeper owns what gets
remembered. MoonClaw workers own how the bounded research job is executed.

This is the core long-standing split:

```text
Mayor decides when / where / why.
Book Keeper decides what belongs in durable memory.
Worker Claws decide how to execute bounded tasks.
```

Moontown persists the control-plane side of each watcher cycle under:

```text
.moontown/watchers/<standing-goal-id>.jsonl
```

Each line is a `WatcherRunRecord` containing the daemon tick, target book,
MoonBook decision, task/run ids, strict accounting fields, detail, and next due
tick. This ledger is the restart-readable audit trail for 24/7 operation. The
durable research truth still lives inside the target MoonBook.

Important boundary: the watcher ledger is not a wiki. It records whether a
check happened and what MoonBook decided about the check. The accounting fields
make this distinction explicit:

- `checked_sources_count`
  counts sources actually opened, fetched, or read enough to judge.
- `new_sources_found`
  counts candidate signals discovered during the check.
- `accepted_facts_count`
  counts facts MoonBook accepted into durable knowledge.
- `rejected_facts_count`
  counts candidate facts or sources rejected as duplicate, weak, stale, blocked,
  or irrelevant.
- `wiki_pages_changed_count`
  counts durable MoonBook pages changed by the cycle.
- `book_changed`
  is `yes` only when durable knowledge changed or review was queued.

This prevents a long-running town from mistaking retries, site rebuilds,
generated logs, or no-change patrols for research progress.

### Readiness and Quality Gates

Moontown now keeps a typed readiness layer for research acceptance instead of
only relying on Markdown string markers.

Current town-side readiness model:

- [research_readiness.mbt](/Users/kq/Workspace/moontown/research_readiness.mbt)

It consumes MoonBook-owned summary fields such as verified source count, entity
page count, concept page count, query note count, and pending review count.
Moontown normalizes evidence accounting before using the summary: domain
evidence remains in `evidence_count`, operational watcher/run records are
reported as `operational_evidence_count`, and the raw audit total is preserved
as `total_evidence_count`. MoonBook still owns the workspace semantics;
Moontown only decides whether a lane is acceptable for town-level synthesis.

### Runtime Status and Daemon Tick

Moontown exposes an operator-readable runtime status seam:

- [runtime_status.mbt](/Users/kq/Workspace/moontown/runtime_status.mbt)

The daemon implementation now has three levels:

- `daemon tick`
  runs one restart-safe mayor supervision cycle and bootstraps a saved town if
  no snapshot exists.
- `daemon run`
  repeats durable ticks and sleeps between iterations.
- `daemon start`
  starts a supervised background runtime with a supervisor process and a worker
  process. The supervisor watches process liveness and heartbeat age, then
  restarts a missing or stale worker.

The daemon persists:

- `.moontown/daemon.json`
  daemon tick, lease owner, heartbeat event count, active standing goal ids, and
  scheduled job metadata
- `.moontown/daemon-runtime.json`
  supervisor/worker process ids, run ids, heartbeat and tick timestamps,
  success/failure counters, stop-request state, and last error
- `.moontown/daemon.log`
  append-only supervisor/worker lifecycle and guarded tick records
- `.moontown/daemon.pid`
  current daemon worker process id
- `.moontown/daemon-supervisor.pid`
  current daemon supervisor process id
- `.moontown/standing-goals.json`
  standing goal registry, cadence, target book, source policy, and next due tick
- `.moontown/watchers/*.jsonl`
  standing-watch decisions, no-change/update/review/failure records, and next
  due ticks

This is now local multi-day process management. On macOS, the included launchd
installer runs `daemon supervise --worker` so the OS keeps the supervisor alive,
and the supervisor keeps the worker alive. Remaining hardening is
systemd/container packaging, external watchdog integration, and browser/backend
live sync.

MoonClaw supervision is nonblocking by default:

```bash
MOONTOWN_MOONCLAW_SUPERVISION_SECONDS=0
```

This is the correct default for 24/7 operation because a long-running watcher
should not serialize unrelated standing goals or civic communication-pattern
schedules. Set a positive value only when debugging one specific run inline.

The daemon launcher resolves the command from `MOONTOWN_DAEMON_COMMAND`,
`MOON_BIN`, then `$HOME/.moon/bin/moon`. The default dev path launches
`moon run cmd/main -- daemon ...`. Hosts that reap detached descendants should
run `daemon run` under their own process manager instead of relying on
`daemon start`.

### Stable-State Cookbook

The cookbook is the control book for durable definitions and operating
procedures:

```text
MoonBook cookbook workspace
  -> stable-state manifest
  -> docs / definitions / runtime-state index
  -> Moondesk human editing surface
  -> Moontown drift checks and operator guidance
```

Current implementation lives in:

- [cookbook.mbt](/Users/kq/Workspace/moontown/cookbook.mbt)
- [docs/COOKBOOK.md](/Users/kq/Workspace/moontown/docs/COOKBOOK.md)

The CLI entry is:

```bash
moon run cmd/main -- cookbook bootstrap
moon run cmd/main -- cookbook status
moon run cmd/main -- cookbook doctor
```

`cookbook bootstrap` creates `.moontown/books/moontown-cookbook/`, registers it
in `.moontown/moonbooks.json`, and writes
`.moontown/cookbook/stable-state.json`. The cookbook does not reinterpret
domain knowledge. It names the canonical artifacts and records whether the
stable state is complete enough to operate.

### Dispatch

```text
TownTask
  -> Mayor.decide_dispatch(...)
  -> Mayor.prepare_keeper_packet(...)
  -> external proposal packet
  -> proposal/run lifecycle record
```

## Packet Lifecycle Ownership

The packet lifecycle is intentionally split across package boundaries:

- `adapters/moonbook`
  - accepts goals
  - produces book task batches
  - hydrates worker context bundles
  - persists or summarizes book-local outcomes
  - refreshes generated workspace sites
- `roles/mayor`
  - decides whether work should be routed, deferred, or escalated
  - prepares keeper-facing packets from book tasks and worker context
  - performs town-level quality gating for cross-book research goals
- `adapters/moonclaw`
  - shapes `ExternalProposalPacket`
  - models `ProposalImportReceipt`
  - confirms and runs imported proposals
  - polls terminal run state
  - maps MoonClaw terminal state into town execution records
- `core`
  - records packet path, proposal id, run id, and execution status in `TaskExecutionRecord`

## Refactor Boundaries

The root package is now split so bootstrap planning is not buried inside the
goal runner:

- [goal_run.mbt](/Users/kq/Workspace/moontown/goal_run.mbt)
  - high-level goal orchestration, book launch, quality gates, and persistence handoff
- [goal_bootstrap.mbt](/Users/kq/Workspace/moontown/goal_bootstrap.mbt)
  - research bootstrap task selection and ingest-first planning
- [goal_execution.mbt](/Users/kq/Workspace/moontown/goal_execution.mbt)
  - MoonClaw proposal/run launch and MoonBook result persistence
- [goal_supervision.mbt](/Users/kq/Workspace/moontown/goal_supervision.mbt)
  - live execution polling, retry directives, worker status sync, and settle loop
- [research_quality.mbt](/Users/kq/Workspace/moontown/research_quality.mbt)
  - research quality gates, deep-report checks, and review-queue marking
- [town_synthesis.mbt](/Users/kq/Workspace/moontown/town_synthesis.mbt)
  - mayor-owned cross-book synthesis rendering and synthesis execution registration
- [file_io.mbt](/Users/kq/Workspace/moontown/file_io.mbt)
  - root-package local text/file helpers used by synthesis, status, and quality checks
- [research_readiness.mbt](/Users/kq/Workspace/moontown/research_readiness.mbt)
  - typed research readiness model
- [runtime_status.mbt](/Users/kq/Workspace/moontown/runtime_status.mbt)
  - persisted snapshot status and daemon tick entry points

### Patrol

```text
TownState
  -> health.inspect_town(...)
  -> scheduler.plan_tick(...)
  -> Mayor.patrol(...)
```

## Persistence

Current persisted files:

- `.moontown/moonbooks.json`
  - persisted moonbook catalog entries
- `.moontown/town.json`
  - persisted town snapshot
- `.moontown/daemon.json`
  - persisted daemon tick state, lease owner, heartbeat event count, active standing goals, and scheduled job metadata
- `.moontown/standing-goals.json`
  - persisted Mayor-owned standing goal registry
- `.moontown/town-synthesis/*.md`
  - mayor-owned cross-book synthesis and readiness artifacts
- `.moontown/packets/`
  - optional exported keeper packet files
- `.moontown/books/<book>/raw/bootstrap/`
  - book-lane research question, search log, source screen, evidence matrix, local source digest, and synthesis brief
- `.moontown/books/<book>/book/site/generated/index.html`
  - MoonBook-generated site projection for the lane

Current implementation:

- [adapters/moonbook/client.mbt](/Users/kq/Workspace/moontown/adapters/moonbook/client.mbt)
- [storage/store.mbt](/Users/kq/Workspace/moontown/storage/store.mbt)

## What Is Real vs Stubbed

Real now:

- book catalog persistence
- Wenyu civic service registry and `civic bootstrap` workspace creation
- snapshot persistence
- town model
- routing model
- MoonBook CLI-backed planning, context hydration, summary, and health
- MoonClaw CLI-backed packet import, run confirmation, and polling for bounded goal runs
- MoonBook persistence/build after terminal goal runs
- parallel research-lane decomposition for multi-topic goals
- mayor-level research quality gates
- town synthesis artifacts under `.moontown/town-synthesis/`
- integrated research narrative with W-source and L-source evidence references
- proposal/run lifecycle tracking
- strategic mayor role adapter
- dashboard and browser UI model
- local supervised daemon loop, heartbeat, stale detection, watcher ledgers,
  and launchd installer seam

Stubbed now:

- experiment runtime progression
- backend-synced Rabbita frontend state
- production-grade cross-platform service packaging
- repeated accepted-output histories for every Wenyu civic service

## Next Integration Milestones

The clean next order is:

1. run and validate each Wenyu civic service lane through MoonClaw and MoonBook
2. parse `wenyu.civic.*.v1` result contracts into structured service ledgers
3. move reusable civic workspace templates into MoonBook
4. add backend-synced Rabbita frontend state
5. add real experiment runtime
