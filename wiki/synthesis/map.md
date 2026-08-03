# Map

## Layer Map

```text
Moontown
  semantic control plane
  - TownState
  - routing / scheduler / health
  - Mayor API
  - TaskExecutionRecord
  - TownSnapshot / dashboard

MoonBook
  domain harness and durable memory boundary
  - BookProvider / catalog
  - workspace root
  - goal acceptance
  - task shaping
  - WorkerContextBundle
  - result review / persistence decisions

MoonClaw
  executable runtime substrate
  - mayor / keeper / worker runtime metadata
  - ExternalProposalPacket
  - proposal import / run confirmation / polling
  - session and run state
```

## Handoff Map

```text
Town intent
  -> MoonBook catalog + tasks
  -> MoonBook worker-context bundle
  -> Mayor strategic-to-domain handoff
  -> keeper-facing packet
  -> MoonClaw import and run lifecycle
  -> Town execution record and dashboard visibility
```

Durable handoff sources:

- `wiki/sources/moonbook-readme.md`
- `wiki/sources/moonbook-keeper-call-chain.md`

## Ownership Map

- semantic town ownership -> `wiki/entities/Moontown.md`
- semantic durable domain ownership -> `wiki/entities/MoonBook.md`
- executable runtime ownership -> `wiki/entities/MoonClaw.md`
- provider-backed seam -> `wiki/concepts/provider-backed-execution.md`
- raw-first provenance discipline -> `wiki/concepts/raw-first-wiki-ingest.md`

## Uncertainty Map

- bootstrap lane exists and is strongly doc/code evidenced
- packet-backed bootstrap provenance is incomplete in this worktree
- provider-backed selection exists
- broader provider-registry topology remains explicitly uncertain
- the earlier stack-only durable page is now a weaker abstraction than the
  topology and call-chain pages used here

## Source Map

- `wiki/sources/moontown-moonbook-moonclaw-topology.md`
- `wiki/sources/moonbook-keeper-call-chain.md`
- `wiki/sources/moonbook-readme.md`
