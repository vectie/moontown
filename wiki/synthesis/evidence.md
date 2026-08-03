# Evidence

## Strongest Available Evidence

This synthesis revision is grounded in the strongest evidence currently present
in the worktree and the copied durable source pages under `wiki/sources/`.

### Repo docs

- `docs/ARCHITECTURE.md`
- `README.mbt.md`
- `docs/PACKAGES.md`
- `docs/USAGE.md`
- `ui/assets/README.md`

### Implementation

- `core/types.mbt`
- `storage/store.mbt`
- `roles/mayor.mbt`
- `adapters/moonbook/client.mbt`
- `adapters/moonclaw/client.mbt`
- `ui/scene_layout_test.mbt`

### Durable wiki sources

- `wiki/sources/moontown-moonbook-moonclaw-topology.md`
- `wiki/sources/moonbook-keeper-call-chain.md`
- `wiki/sources/moonbook-readme.md`

## Evidence By Theme

### Cross-project topology

Best evidence:

- `docs/ARCHITECTURE.md`
- `README.mbt.md`
- `wiki/sources/moontown-moonbook-moonclaw-topology.md`

### Semantic-versus-executable ownership split

Best evidence:

- `docs/ARCHITECTURE.md`
- `core/types.mbt`
- `adapters/moonbook/client.mbt`
- `adapters/moonclaw/client.mbt`

### Bootstrap lane/process

Best evidence:

- `docs/ARCHITECTURE.md`
- `docs/USAGE.md`
- `roles/mayor.mbt`
- `adapters/moonbook/client.mbt`
- `adapters/moonclaw/client.mbt`
- `storage/store.mbt`
- `wiki/sources/moonbook-keeper-call-chain.md`

### Provider-backed boundary and registry uncertainty

Best evidence:

- `core/types.mbt` for `BookProvider`
- `adapters/moonbook/client.mbt` for `MoonbookCatalogProvider`
- `adapters/moonclaw/client.mbt` for runtime-visible tool/provider metadata

## Missing Evidence Kept Explicit

The following packet-level sources were referenced by the job metadata but are
not present in this worktree:

- `raw/bootstrap/moontown-moonbook-moonclaw-bootstrap-2026-04-17.md`
- `raw/bootstrap/docs-lane-bootstrap-packet-2026-04-17.md`
- `raw/bootstrap/implementation-lane-bootstrap-step_3.md`
- `raw/bootstrap/architecture-bootstrap-packet.md`
- `raw/bootstrap/consolidated-lane-evidence.packet.json`

Because of that gap, the synthesis explicitly treats packet-backed bootstrap and
registry-level claims as bounded uncertainty rather than hidden assumptions.

## Cross-links

- `wiki/synthesis/overview.md`
- `wiki/synthesis/claims.md`
- `wiki/entities/Moontown.md`
- `wiki/entities/MoonBook.md`
- `wiki/entities/MoonClaw.md`
- `wiki/concepts/raw-first-wiki-ingest.md`
