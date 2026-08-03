# Moontown MoonBook MoonClaw Topology

## Status

This page is a durable source surface built from the strongest evidence present in
this worktree. The previously referenced bootstrap packets under `raw/bootstrap/`
and any pre-existing maintained wiki pages were not present during this revision,
so claims here are grounded in repo docs and implementation files only.

## Topology Claim

The repo consistently describes a three-layer system:

```text
moontown -> moonbook -> moonclaw
```

The clearest maintained architecture statement is in `docs/ARCHITECTURE.md`,
which defines:

- `moontown` as the town-wide control plane
- `moonbook` as the per-domain harness layer
- `moonclaw` as the underlying agent substrate

`README.mbt.md` repeats the same layering and frames `moontown` as the
orchestration layer above multiple `moonbook` domains and multiple `moonclaw`
runtimes.

## Layer Responsibilities

### `moontown`

Strongest source: `docs/ARCHITECTURE.md`.

Documented responsibilities:

- global orchestration
- routing and isolation policy
- health monitoring and recovery
- scheduling and patrol
- experiment control
- operator UI
- town-wide persistence

The same document explicitly says `moontown` should not become the place where
book-local memory lives, where execution tooling lives, or a generic raw worker
runtime.

### `moonbook`

Strongest sources: `docs/ARCHITECTURE.md`, `docs/PACKAGES.md`,
`adapters/moonbook/client.mbt`.

Documented responsibilities:

- workspace root and domain identity
- memory policy and durable memory
- context hydration
- local planning
- result review and persistence decisions

Current implemented adapter evidence in `adapters/moonbook/client.mbt` and
`docs/PACKAGES.md` includes:

- persisted catalog entries in `.moontown/moonbooks.json`
- book provider implementation
- workspace initialization through real `moonbook wiki init`
- MoonClaw extension seeding through real `moonbook wiki enable moonclaw`
- goal acceptance, task-batch production, worker-context hydration,
  persistence, summary, and health surfaces

Caveat: this repo exposes the town-side adapter boundary to MoonBook, not the
full MoonBook-side keeper implementation. `docs/ARCHITECTURE.md` explicitly says
that the actual keeper implementation still belongs on the `moonbook` side.

### `moonclaw`

Strongest sources: `docs/ARCHITECTURE.md`, `docs/PACKAGES.md`,
`adapters/moonclaw/client.mbt`.

Documented responsibilities:

- role-specialized runtimes
- task execution
- tools and skills
- session state
- result packaging

The repo's current MoonClaw-facing implementation evidence includes:

- embedded runtime metadata for mayor, keeper, and worker profiles
- external proposal packet shaping
- packet-file persistence under `.moontown/packets/`
- real `moonclaw proposal import --json` import boundary
- proposal/run receipt and polling model types

Caveat: the docs distinguish between what is modeled and what is fully live.
Long-running run-status polling and completion ingestion are still described as
stubbed at the system level even though `adapters/moonclaw/client.mbt` contains
polling-oriented types and functions.

## Embedded Role Topology

Strongest sources: `docs/ARCHITECTURE.md`, `README.mbt.md`, `roles/mayor.mbt`,
`adapters/moonclaw/client.mbt`.

The intended role model is not to copy MoonClaw into each repo, but to embed one
agent substrate behind strong role adapters.

### `Mayor`

Documented and implemented as the strategic town runtime.

Evidence across docs and code:

- `docs/ARCHITECTURE.md` lists planning layer `strategic`, runtime mode
  `planner-only`, limited tool access, global memory scope, delegated keeper
  handoff, and no direct workspace writes.
- `roles/mayor.mbt` implements `Mayor.decide_dispatch(...)`,
  `Mayor.patrol(...)`, `Mayor.handoff_to_keeper(...)`, and
  `Mayor.prepare_keeper_packet(...)`.

### `keeper`

Documented as the book-local planning/runtime handoff target.

Evidence:

- `docs/ARCHITECTURE.md` describes keeper as domain-scoped and planner-only.
- `roles/mayor.mbt` produces keeper-facing handoff and proposal packets.
- `adapters/moonclaw/client.mbt` includes `EmbeddedHandoffKind::StrategicToDomain`
  and keeper runtime metadata.

Caveat: in this repo, keeper is represented mainly as a handoff target and
runtime profile. The actual keeper-side execution remains outside the current
worktree's implementation boundary.

### worker claws

Documented as separate from strategic and domain planning roles.

Evidence:

- `docs/ARCHITECTURE.md` assigns execution behavior, full tool access, and
  workspace memory scope to worker runtimes.
- `adapters/moonclaw/client.mbt` defines execution-layer runtime metadata and
  task/result response types.

## Ownership Split

Strongest source: `docs/ARCHITECTURE.md`.

The clearest ownership rule in the current repo is:

- if it is town-wide, it belongs to `moontown`
- if it is domain-specific and durable, it belongs to `moonbook`
- if it is task/session-specific, it belongs to `moonclaw`

Examples directly documented there:

- `TownState`, `AssignmentPlan`, `TownEvent`, `TaskExecutionRecord`
  -> `moontown`
- workspace root, memory records, domain summaries
  -> `moonbook`
- tool traces, session state, execution logs
  -> `moonclaw`

## Current Runtime Path

Strongest sources: `docs/ARCHITECTURE.md`, `README.mbt.md`, `docs/USAGE.md`.

The maintained docs agree on a runtime path that starts from the MoonBook
catalog/task layer, moves through mayor-prepared keeper packets, and crosses into
MoonClaw proposal/run lifecycle tracking.

Representative path from `docs/ARCHITECTURE.md`:

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

This is consistent with the README and usage guide, though wording differs by
surface.

## Real vs Stubbed

Strongest source: `docs/ARCHITECTURE.md`.

Documented as real now:

- book catalog persistence
- snapshot persistence
- town model
- routing model
- MoonBook CLI-backed planning, context hydration, summary, and health
- MoonClaw CLI-backed packet import
- proposal/run lifecycle tracking
- strategic mayor role adapter
- dashboard and browser UI model

Documented as stubbed now:

- long-running run-status polling after the initial MoonClaw handoff
- automatic result persistence back into MoonBook after run completion
- experiment runtime progression
- 24/7 supervisor loop

Caveat: where docs and implementation expose slightly different maturity signals,
this page preserves the docs' stronger caveat instead of upgrading modeled code
surfaces into confirmed live behavior.

## Provenance

Primary evidence used for this revision:

- `docs/ARCHITECTURE.md`
- `README.mbt.md`
- `docs/PACKAGES.md`
- `docs/USAGE.md`
- `roles/mayor.mbt`
- `adapters/moonbook/client.mbt`
- `adapters/moonclaw/client.mbt`

Missing during revision:

- `raw/bootstrap/moontown-moonbook-moonclaw-bootstrap-2026-04-17.md`
- `raw/bootstrap/docs-lane-bootstrap-packet-2026-04-17.md`
- `raw/bootstrap/implementation-lane-bootstrap-step_3.md`
- `raw/bootstrap/architecture-bootstrap-packet.md`
- `raw/bootstrap/consolidated-lane-evidence.packet.json`

Any future merge should prefer the raw packet trail for contested or more precise
claims.
