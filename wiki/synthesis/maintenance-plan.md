# Maintenance Plan

## Immediate Maintenance Rule

Maintain the ontology and synthesis pages from raw docs/code evidence first,
then upgrade them with packet-level provenance when the missing
`raw/bootstrap/...` sources become available.

## What To Refresh Together

When topology or lifecycle details change, refresh these pages as one set:

- `wiki/sources/moontown-moonbook-moonclaw-topology.md`
- `wiki/sources/moonbook-keeper-call-chain.md`
- `wiki/sources/moonbook-readme.md`
- `wiki/entities/Moontown.md`
- `wiki/entities/MoonBook.md`
- `wiki/entities/MoonClaw.md`
- `wiki/concepts/raw-first-wiki-ingest.md`
- `wiki/concepts/provider-backed-execution.md`
- `wiki/synthesis/overview.md`
- `wiki/synthesis/claims.md`
- `wiki/synthesis/map.md`
- `wiki/synthesis/evidence.md`

## Priority Checks

### 1. Topology

Confirm whether the three-layer statement still holds and whether any new role or
adapter shifts the `moontown -> moonbook -> moonclaw` layering.

### 2. Ownership split

Check whether new persistence or execution code changes the current semantic
versus executable ownership boundary.

### 3. Bootstrap lane

Check whether bootstrap now has packet-backed evidence in `raw/bootstrap/` and
whether long-running completion ingestion has moved from stubbed to live.

### 4. Provider registry certainty

Only strengthen provider-registry claims if a distinct maintained surface or raw
packet evidence appears. Do not infer a larger registry contract from tool names
alone.

## Upgrade Conditions

Upgrade the current uncertainty language only when at least one of these exists:

- the missing `raw/bootstrap/...` packet trail is present
- an upstream MoonBook or MoonClaw maintained source page clarifies ownership or
  keeper behavior
- a distinct provider-registry spec or packet surface becomes available

If a new stack-level summary page is materialized again, prefer merging its
strongest facts into the existing topology, MoonBook README, or keeper call-chain
pages instead of keeping duplicate cross-project source summaries in parallel.

## Residual Risks

- missing packet provenance can tempt overconfident bootstrap claims
- Moontown-side adapters can look like full upstream implementation when they
  are only boundary surfaces
- runtime-visible tool names can be mistaken for a full registry design

## Cross-links

- `wiki/synthesis/evidence.md`
- `wiki/concepts/raw-first-wiki-ingest.md`
- `wiki/concepts/provider-backed-execution.md`
- `wiki/sources/moontown-moonbook-moonclaw-topology.md`
- `wiki/sources/moonbook-keeper-call-chain.md`
