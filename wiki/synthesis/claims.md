# Claims

## Maintained Claims

### 1. Cross-project topology is three-layered.

High confidence.

```text
moontown -> moonbook -> moonclaw
```

Supported by architecture docs, README language, and the durable topology page.

Cross-links:

- `wiki/sources/moontown-moonbook-moonclaw-topology.md`
- `wiki/entities/Moontown.md`
- `wiki/entities/MoonBook.md`
- `wiki/entities/MoonClaw.md`

### 2. Ownership is split by semantic durability versus executable runtime.

High confidence.

- `moontown` owns town-wide semantic state and policy
- `moonbook` owns domain-specific durable semantics and review/persistence
- `moonclaw` owns executable runtime, packet import, session/run state, and
  result packaging

This is directly supported by `docs/ARCHITECTURE.md`, `core/types.mbt`, and the
MoonBook/MoonClaw adapters.

Durable source anchors:

- `wiki/sources/moontown-moonbook-moonclaw-topology.md`
- `wiki/sources/moonbook-readme.md`
- `wiki/sources/moonbook-keeper-call-chain.md`

### 3. The bootstrap lane is visible end to end at the doc/code level.

Moderate-to-high confidence.

Visible sequence:

```text
moonbook catalog
  -> WorkerContextBundle
  -> Mayor.prepare_keeper_packet(...)
  -> ExternalProposalPacket
  -> moonclaw proposal import --json
  -> ProposalImportReceipt
  -> TaskExecutionRecord / TownSnapshot
```

Confidence is slightly below claim 1/2 because the named `raw/bootstrap/...`
packet trail is missing in this worktree.

Durable source anchors:

- `wiki/sources/moonbook-readme.md`
- `wiki/sources/moonbook-keeper-call-chain.md`
- `wiki/sources/moontown-moonbook-moonclaw-topology.md`

### 4. `BookProvider` is real, but the wider provider registry remains scoped
uncertainty.

Moderate confidence.

Supported:

- `BookProvider`
- `MoonbookCatalogProvider`
- provider-backed bootstrap/loading
- runtime-visible tool/provider names in MoonClaw metadata

Not yet established here:

- an independently documented registry contract spanning the projects beyond
  those surfaces

This claim is intentionally narrower than the prior stack-only materialization;
the current source set supports provider-backed execution but not a broader
registry specification.

### 5. The keeper boundary is real as a handoff seam, but not fully implemented
inside this repo.

High confidence.

The docs explicitly say keeper implementation still belongs on the MoonBook
side. This repo strongly shows mayor-to-keeper handoff semantics and packet
preparation, but should not be read as containing the whole keeper runtime.

Primary durable anchor:

- `wiki/sources/moonbook-keeper-call-chain.md`

## Cross-links

- `wiki/synthesis/overview.md`
- `wiki/synthesis/evidence.md`
- `wiki/concepts/provider-backed-execution.md`
- `wiki/concepts/raw-first-wiki-ingest.md`
- `wiki/sources/moonbook-keeper-call-chain.md`
