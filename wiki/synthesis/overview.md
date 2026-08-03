# Overview

## Status

Maintained synthesis surface revised to make four things explicit and
cross-linked: the cross-project topology, the semantic-versus-executable
ownership split, the bootstrap lane/process evidence, and the scoped
provider-registry uncertainty.

## Core Synthesis

The strongest current synthesis is a layered system with an intentional split
between meaning and execution:

```text
moontown -> moonbook -> moonclaw
```

- `moontown` is the town-wide semantic control plane
- `moonbook` is the durable per-domain harness and memory boundary
- `moonclaw` is the executable role/runtime substrate

The current durable source set makes that synthesis more precise than the prior
stack-only page by separating layer topology from the keeper call chain and the
MoonBook-facing README surface.

The repo is clearest when read as a control-plane-first system that prepares,
hands off, records, and renders execution rather than directly owning execution
itself.

## Topology

Cross-project topology is now visible across both source and entity pages:

- `wiki/entities/Moontown.md`
- `wiki/entities/MoonBook.md`
- `wiki/entities/MoonClaw.md`
- `wiki/sources/moontown-moonbook-moonclaw-topology.md`
- `wiki/sources/moonbook-readme.md`

The embedded role topology refines that layer map:

- mayor = strategic runtime
- keeper = domain runtime/handoff target
- worker claws = execution runtimes

## Ownership Split

The central synthesis claim is the semantic-versus-executable ownership split:

- `moontown` owns town-wide orchestration semantics, policy, visibility, and
  execution records
- `moonbook` owns domain identity, durable memory, context hydration, and review
  decisions
- `moonclaw` owns executable runtimes, proposal/run state, and result packaging

This split explains why `TaskExecutionRecord` lives in town state even though
actual run execution belongs to MoonClaw.

See `wiki/concepts/provider-backed-execution.md`.

The split is also now claim-linked instead of implied only through prose; see
claim 2 and claim 5 in `wiki/synthesis/claims.md`.

## Bootstrap And Process Evidence

The current bootstrap/process evidence is strong enough to synthesize a real
lane, but not strong enough to present as fully packet-backed in this worktree.

Visible lane:

```text
moonbook catalog
  -> BookProvider
  -> book task batch
  -> WorkerContextBundle
  -> keeper-facing ExternalProposalPacket
  -> moonclaw proposal import --json
  -> ProposalImportReceipt / run state
  -> TaskExecutionRecord
  -> TownSnapshot / dashboard surfaces
```

This lane is evidenced by docs, adapter code, mayor code, and durable source
pages. The referenced `raw/bootstrap/...` packet set remains absent here, so the
synthesis keeps that caveat visible.

See `wiki/concepts/raw-first-wiki-ingest.md` and
`wiki/synthesis/evidence.md`.

## Provider-Registry Uncertainty

A narrower claim is warranted than "the system has a complete provider
registry".

What is well supported:

- provider-backed book selection via `BookProvider`
- catalog-backed MoonBook bootstrap
- runtime-visible tool/provider names in MoonClaw metadata
- durable source coverage for those surfaces in `wiki/sources/moonbook-readme.md`
  and `wiki/sources/moonbook-keeper-call-chain.md`

What remains uncertain in this worktree:

- a separately governed cross-project provider registry beyond those visible
  adapter and metadata surfaces

That uncertainty is scoped, not blocking.

## Cross-links

- `wiki/synthesis/claims.md`
- `wiki/synthesis/map.md`
- `wiki/synthesis/evidence.md`
- `wiki/entities/Moontown.md`
- `wiki/entities/MoonBook.md`
- `wiki/entities/MoonClaw.md`
- `wiki/concepts/provider-backed-execution.md`
- `wiki/concepts/raw-first-wiki-ingest.md`
