# Architecture

`moontown` is designed as the top layer of a three-part system:

```text
moontown -> moonbook -> moonclaw
```

The Wenyu Valley product plan is tracked separately in
[WENYU_VALLEY_PRD.md](/Users/kq/Workspace/moontown/docs/WENYU_VALLEY_PRD.md).
That document defines the programmable roadmap for turning the current town
prototype into a MoonBook/MoonClaw-backed civic AI town.

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

It should not become:

- the place where book-local memory lives
- the place where execution tooling lives
- a generic raw worker runtime

### `moonbook`

`moonbook` is the per-domain harness layer.

It should own:

- workspace root and domain identity
- memory policy and durable memory
- context hydration
- local planning
- result review and persistence decisions

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
configured as long-lived civic services rather than one-off research topics.

```text
civic service registry
  -> canonical wenyu-* MoonBook catalog entries
  -> civic workspace seeds
  -> module schemas, wiki pages, review queues
  -> generic and module-specific MoonClaw skills
  -> book/moonbook-ui-state.json
  -> viewport module projection
```

Current implementation lives in:

- [civic/services.mbt](/Users/kq/Workspace/moontown/civic/services.mbt)
- [civic_workspace.mbt](/Users/kq/Workspace/moontown/civic_workspace.mbt)
- [civic_status.mbt](/Users/kq/Workspace/moontown/civic_status.mbt)

The CLI entry is:

```bash
moon run cmd/main -- civic bootstrap
```

The registry covers Town Shell, Resident Twin Homes, Policy Hall, Contest
Express, Social Square, Talent Avenue, Vitality Tower, AI Science Garden,
Physical Bridge, Valley Market, and Story Radar. Each service has a book id,
schema pages, wiki pages, review queues, worker role, skill pack, output
contract, and projection summary.

Civic books intentionally bypass the Wenyu product research/bootstrap quality
gate. Their first task is the registry-defined `civic-service-workflow`, while
non-civic Wenyu books can still use product-build research, implementation,
code-patch, and asset-pack stages.

This is intentionally a bootstrap bridge. Durable civic-domain memory still
belongs in MoonBook, and tool execution still belongs in MoonClaw. As the
contract stabilizes, reusable civic workspace templates should move into
MoonBook so Moontown requests workspace creation instead of writing every seed
file itself.

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

The first default standing goal is `watch-opc-news`, which targets the dynamic
`research-opc` book and uses a web-first source policy. The Mayor owns when it
runs. The `research-opc` keeper owns what gets remembered. MoonClaw workers own
how the bounded research job is executed.

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
installer runs `daemon run` as a foreground worker supervised by the OS. Remaining
hardening is systemd/container packaging, external watchdog integration, and
browser/backend live sync.

The daemon launcher resolves the command from `MOONTOWN_DAEMON_COMMAND`,
`MOON_BIN`, then `$HOME/.moon/bin/moon`. The default dev path launches
`moon run cmd/main -- daemon ...`. Hosts that reap detached descendants should
run `daemon run` under their own process manager instead of relying on
`daemon start`.

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
