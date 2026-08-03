# Provider-Backed Execution

## Status

Maintained concept surface revised to show the provider-backed and executable
ownership split without overstating registry certainty. The current repo offers
strong evidence for provider-backed book selection and strong evidence for the
MoonClaw execution boundary, but only limited evidence for a separately governed
provider registry.

## Concept

`Provider-backed execution` names the pattern where semantic ownership and
selection happen on the Moontown/MoonBook side, while executable work crosses a
provider or adapter boundary into MoonClaw.

Current high-confidence chain:

```text
BookProvider / moonbook catalog
  -> MoonBook goal + task shaping
  -> WorkerContextBundle
  -> mayor keeper packet preparation
  -> MoonClaw external proposal import
  -> proposal/run lifecycle receipts
  -> TownState execution records
```

## Semantic Versus Executable Ownership Split

This is the key maintained split across the project topology:

- `moontown` owns town-wide semantic topology, routing, patrol state, and town
  execution records
- `moonbook` owns domain identity, durable memory policy, context hydration, and
  review/persistence decisions
- `moonclaw` owns executable role runtimes, packet import, run state, and result
  packaging

The concept matters because several pages can look like execution happens "in
Moontown" when the repo actually shows Moontown preparing and recording
execution while MoonClaw remains the executable substrate.

## Provider Evidence

Strong provider-backed evidence visible in this worktree:

- `BookProvider` in `core/types.mbt`
- `MoonbookCatalogProvider` in `adapters/moonbook/client.mbt`
- `load_or_create_provider(...)` and the persisted catalog
- mayor-visible tool/provider surfaces such as `town-registry`, `event-log`, and
  `scheduler-state` in MoonClaw runtime metadata

These provider-backed surfaces are now backed by durable source coverage instead
of remaining only implicit in code references:

- `wiki/sources/moonbook-readme.md` for the catalog/provider boundary
- `wiki/sources/moonbook-keeper-call-chain.md` for the packet import seam
- `wiki/sources/moontown-moonbook-moonclaw-topology.md` for the ownership map

This is enough to say execution is provider/adaptor backed. It is not enough to
claim a fully specified cross-project provider registry beyond the catalog and
runtime metadata that are actually visible.

## Execution Evidence

Strong executable evidence visible in this worktree:

- `proposal_packet_from_bundle(...)` shapes executable packets from MoonBook
  context
- `build_import_command(...)` and `import_packet(...)` call real MoonClaw CLI
  import
- `ProposalImportReceipt` records packet path, proposal id, run id, command, and
  status
- `poll_run(...)` maps MoonClaw run states back into town execution states
- `TaskExecutionRecord` stores the imported execution lifecycle in town state

## Scoped Registry Uncertainty

The job asked for scoped provider-registry uncertainty to be visible.

Maintained conclusion:

- the repo definitely has provider-backed book selection and execution handoff
- the repo definitely has runtime-visible tool/provider names
- whether those names are backed by a distinct registry contract across projects
  is uncertain in this worktree
- synthesis pages should preserve that uncertainty rather than invent a larger
  registry topology

## Cross-links

- `wiki/entities/Moontown.md`
- `wiki/entities/MoonBook.md`
- `wiki/entities/MoonClaw.md`
- `wiki/concepts/raw-first-wiki-ingest.md`
- `wiki/synthesis/overview.md`
- `wiki/synthesis/claims.md`
- `wiki/sources/moonbook-readme.md`
- `wiki/sources/moonbook-keeper-call-chain.md`

## Provenance

Primary evidence:

- `docs/ARCHITECTURE.md`
- `docs/PACKAGES.md`
- `docs/USAGE.md`
- `core/types.mbt`
- `roles/mayor.mbt`
- `adapters/moonbook/client.mbt`
- `adapters/moonclaw/client.mbt`
- `wiki/sources/moontown-moonbook-moonclaw-topology.md`
- `wiki/sources/moonbook-keeper-call-chain.md`
