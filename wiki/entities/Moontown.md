# Moontown

## Status

Maintained entity surface revised against the strongest evidence present in this
worktree plus the durable source pages in `wiki/sources/`. The approved
`raw/bootstrap/...` packets referenced by the job are still absent here, so this
page keeps bootstrap-lane uncertainty explicit instead of upgrading missing
packet evidence into settled fact.

## Role

`Moontown` is the town-wide control plane in the documented three-layer stack:

```text
moontown -> moonbook -> moonclaw
```

The maintained architecture description assigns `moontown` ownership of global
orchestration, routing and isolation policy, scheduling, health monitoring,
operator UI, and town-wide persistence. It is not supposed to become the place
where book-local durable memory lives or the place where execution tooling
lives.

See also:

- `wiki/sources/moontown-moonbook-moonclaw-topology.md`
- `wiki/concepts/provider-backed-execution.md`
- `wiki/concepts/raw-first-wiki-ingest.md`

## Owned Surfaces

High-confidence `moontown`-owned semantic surfaces visible in repo docs and code:

- `TownState`, `AssignmentPlan`, `TownEvent`, and `TaskExecutionRecord`
- routing, isolation, health, scheduler, and snapshot persistence
- the semantic town scene and dashboard projection
- the mayor-facing strategic role API
- the persisted town snapshot at `.moontown/town.json`

This is the semantic side of the ownership split: `moontown` holds town-level
meaning, coordination state, and visibility surfaces, while delegating
book-local durable context to `moonbook` and executable run machinery to
`moonclaw`.

## Relationship To MoonBook

`Moontown` depends on `MoonBook` as the per-domain harness layer.

Current maintained evidence shows `moontown` using a catalog-backed
`BookProvider` plus a real MoonBook CLI-backed planning/context boundary to:

- load and persist book catalog entries from `.moontown/moonbooks.json`
- initialize missing book workspaces
- accept goals and produce book task batches
- hydrate worker context bundles before keeper packet creation

The important ownership boundary is semantic versus executable:

- `moontown` owns town-wide semantic topology and execution records
- `moonbook` owns domain identity, workspace root, memory policy, and durable
  review/persistence decisions

The maintained source set now gives this boundary two distinct durable anchors:

- `wiki/sources/moontown-moonbook-moonclaw-topology.md` for the layered control
  plane and ownership split
- `wiki/sources/moonbook-readme.md` for the MoonBook-facing catalog, workspace,
  and memory boundary that Moontown relies on

See `wiki/entities/MoonBook.md` and
`wiki/sources/moonbook-keeper-call-chain.md`.

## Relationship To MoonClaw

`Moontown` does not directly become a raw worker runtime. Instead it embeds
role-shaped MoonClaw metadata behind the mayor/keeper/worker split and crosses
into real execution through the external proposal import boundary.

Current evidence supports this path:

```text
book task
  -> worker context bundle
  -> Mayor.prepare_keeper_packet(...)
  -> ExternalProposalPacket
  -> moonclaw proposal import --json
  -> ProposalImportReceipt
  -> TaskExecutionRecord in TownState
```

So `moontown` owns the semantic and recording surfaces around execution, but the
executable substrate remains `moonclaw`.

See `wiki/entities/MoonClaw.md` and
`wiki/concepts/provider-backed-execution.md`.

## Bootstrap Lane Evidence

The bootstrap lane that is visible in this worktree is doc/code backed rather
than packet backed.

Visible evidence:

- `README.mbt.md` and `docs/ARCHITECTURE.md` describe a bootstrap path from the
  MoonBook catalog to seeded `TownState`
- `adapters/moonbook/client.mbt` persists and normalizes the catalog
- `storage/store.mbt` persists the seeded town snapshot
- `docs/USAGE.md` documents bootstrap files under `.moontown/`

Missing evidence:

- `raw/bootstrap/moontown-moonbook-moonclaw-bootstrap-2026-04-17.md`
- `raw/bootstrap/docs-lane-bootstrap-packet-2026-04-17.md`
- `raw/bootstrap/implementation-lane-bootstrap-step_3.md`
- `raw/bootstrap/architecture-bootstrap-packet.md`

Because those packet sources are absent, this page only claims that the
bootstrap lane is strongly documented and partially implemented, not that the
full approved packet trail has been reverified here.

## Provider Registry Uncertainty

The repo clearly exposes provider abstractions, especially `BookProvider`, and
mayor runtime metadata exposes stable visible tool names such as
`town-registry`, `event-log`, and `scheduler-state`. But this worktree does not
show a separately maintained provider registry specification that would justify
stronger claims about a broader registry topology.

Scoped maintained conclusion:

- `BookProvider` is real and town bootstrap depends on it
- role-visible tool/provider names exist in embedded MoonClaw runtime metadata
- a wider provider-registry surface, if intended, remains uncertain in this
  worktree and should stay explicitly scoped as uncertainty

## Cross-links

- `wiki/entities/MoonBook.md`
- `wiki/entities/MoonClaw.md`
- `wiki/concepts/raw-first-wiki-ingest.md`
- `wiki/concepts/provider-backed-execution.md`
- `wiki/synthesis/claims.md`
- `wiki/synthesis/overview.md`
- `wiki/sources/moontown-moonbook-moonclaw-topology.md`
- `wiki/sources/moonbook-readme.md`

## Provenance

Primary evidence:

- `docs/ARCHITECTURE.md`
- `README.mbt.md`
- `docs/PACKAGES.md`
- `docs/USAGE.md`
- `core/types.mbt`
- `storage/store.mbt`
- `roles/mayor.mbt`
- `adapters/moonbook/client.mbt`
- `adapters/moonclaw/client.mbt`
- `wiki/sources/moontown-moonbook-moonclaw-topology.md`
- `wiki/sources/moonbook-keeper-call-chain.md`
