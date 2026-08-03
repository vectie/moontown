# Raw-First Wiki Ingest

## Status

Maintained concept surface revised to make the bootstrap/process evidence and its
current limits visible. The named bootstrap packets are absent in this worktree,
so this page describes the raw-first pattern that is actually evidenced here:
repo docs and code first, missing packet trail kept explicit, synthesis derived
from those surfaces second.

## Concept

`Raw-first wiki ingest` means durable wiki claims should be grounded in the
closest raw evidence surface before they are merged into ontology or synthesis
pages.

For this revision, the usable raw surfaces are:

- repo-maintained docs such as `docs/ARCHITECTURE.md`, `docs/PACKAGES.md`, and
  `docs/USAGE.md`
- implementation files such as `roles/mayor.mbt`, `adapters/moonbook/client.mbt`,
  `adapters/moonclaw/client.mbt`, `core/types.mbt`, and `storage/store.mbt`
- durable wiki source pages under `wiki/sources/` that summarize those raw repo
  surfaces while preserving uncertainty

## Why It Matters Here

The requested ontology/synthesis revision depends on bootstrap-lane/process
claims, but the approved `raw/bootstrap/...` packet set is missing from this
worktree. A raw-first ingest discipline prevents the wiki from silently turning
"missing packet evidence" into "confirmed packet-backed fact".

So the maintained pattern is:

```text
raw docs/code evidence
  -> durable source pages
  -> ontology and synthesis pages
  -> explicit caveat where packet-level provenance is absent
```

## Bootstrap Lane Evidence In This Worktree

The visible bootstrap lane is still substantive:

- MoonBook catalog bootstraps domain identity via `.moontown/moonbooks.json`
- MoonBook workspaces are initialized if missing
- worker context bundles are hydrated before packet creation
- keeper packet files may be persisted under `.moontown/packets/`
- MoonClaw import produces proposal/run receipts
- town snapshot bootstrap is persisted in `.moontown/town.json`

That is enough evidence to maintain bootstrap/process claims, but not enough to
collapse missing packet-trail uncertainty.

## Source-to-Synthesis Discipline

This concept exists to keep the following split visible:

- source pages preserve exact provenance, caveats, and boundary wording
- ontology pages normalize entities and concepts
- synthesis pages connect the topology, ownership split, and lifecycle evidence

Relevant sources:

- `wiki/sources/moontown-moonbook-moonclaw-topology.md`
- `wiki/sources/moonbook-keeper-call-chain.md`
- `wiki/sources/moonbook-readme.md`
- `wiki/sources/moontown-moonbook-moonclaw-stack.md` in the prior materialized
  run, which overlaps this concept but is superseded here by the more specific
  topology and call-chain pages present in this worktree

Relevant synthesis:

- `wiki/synthesis/overview.md`
- `wiki/synthesis/claims.md`
- `wiki/synthesis/evidence.md`
- `wiki/synthesis/maintenance-plan.md`

## When To Create A New Page

A new raw-first ingest page is only warranted when there is a distinct evidence
surface whose provenance or semantics would be muddied by merging it into an
existing page.

That threshold is not met here for a new `research-bootstrap-ingest` page,
because the available bootstrap evidence is cross-project and already fits
cleanly into the topology, call-chain, and synthesis pages.

The same rule applies to the earlier stack-only source page from the prior
materialization phase: once the stronger topology and call-chain pages exist,
cross-project ingest should revise those durable targets instead of spawning a
parallel duplicate concept or source page.

## Cross-links

- `wiki/concepts/provider-backed-execution.md`
- `wiki/entities/Moontown.md`
- `wiki/entities/MoonBook.md`
- `wiki/entities/MoonClaw.md`
- `wiki/synthesis/evidence.md`

## Provenance

Primary evidence:

- `docs/ARCHITECTURE.md`
- `README.mbt.md`
- `docs/PACKAGES.md`
- `docs/USAGE.md`
- `roles/mayor.mbt`
- `adapters/moonbook/client.mbt`
- `adapters/moonclaw/client.mbt`
- `storage/store.mbt`
- `wiki/sources/moontown-moonbook-moonclaw-topology.md`
- `wiki/sources/moonbook-keeper-call-chain.md`
- `wiki/sources/moonbook-readme.md`
