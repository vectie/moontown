# Architecture

`moontown` is designed as the top layer of a three-part system:

```text
moontown -> moonbook -> moonclaw
```

## Layer Responsibilities

### `moontown`

`moontown` is the town-wide control plane.

It should own:

- global orchestration
- routing and isolation policy
- health monitoring and recovery
- scheduling and patrol
- experiment control
- operator UI
- town-wide persistence

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
  -> proposal import receipt
  -> seeded TownState
  -> task execution records
  -> persisted TownSnapshot
  -> dashboard/render/frontend
```

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
- `roles/mayor`
  - decides whether work should be routed, deferred, or escalated
  - prepares keeper-facing packets from book tasks and worker context
- `adapters/moonclaw`
  - shapes `ExternalProposalPacket`
  - models `ProposalImportReceipt`
  - models run confirmation polling
- `core`
  - records packet path, proposal id, run id, and execution status in `TaskExecutionRecord`

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
- `.moontown/packets/`
  - optional exported keeper packet files

Current implementation:

- [adapters/moonbook/client.mbt](/Users/kq/Workspace/moontown/adapters/moonbook/client.mbt)
- [storage/store.mbt](/Users/kq/Workspace/moontown/storage/store.mbt)

## What Is Real vs Stubbed

Real now:

- book catalog persistence
- snapshot persistence
- town model
- routing model
- book-harness-shaped moonbook adapter
- external proposal packet adapter
- proposal/run lifecycle tracking
- strategic mayor role adapter
- dashboard and browser UI model

Stubbed now:

- real process-level execution against external `moonbook` and `moonclaw` repos
- experiment runtime progression
- 24/7 supervisor loop

## Next Integration Milestones

The clean next order is:

1. real moonbook planning/hydration/persist integration
2. town task expansion from book plans
3. real moonclaw execution integration
4. daemon patrol and recovery loop
5. real experiment runtime
