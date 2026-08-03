# MoonBook

## Status

Maintained entity surface revised from repo docs, adapter code, and the durable
source pages under `wiki/sources/`. The direct upstream MoonBook repo/pages and
approved bootstrap packet trail are absent in this worktree, so this page is
strict about separating well-supported Moontown-side evidence from unresolved
upstream detail.

## Role

`MoonBook` is the per-domain harness layer between `moontown` and `moonclaw`.

The current maintained docs consistently assign `moonbook` ownership of:

- workspace root and domain identity
- memory policy and durable memory
- context hydration
- local planning
- result review and persistence decisions

This is the semantic durable side of the split below `moontown` and above the
MoonClaw execution substrate.

See `wiki/sources/moonbook-readme.md` and
`wiki/sources/moontown-moonbook-moonclaw-topology.md`.

## Durable Ownership

High-confidence MoonBook-owned surfaces visible from this repo:

- catalog entries persisted in `.moontown/moonbooks.json`
- per-book workspace roots such as `.moontown/books/{book_id}`
- `BookTask`, `BookTaskBatch`, `BookGoalAcceptance`, `WorkerContextBundle`, and
  `BookResult` as the harness boundary types visible in the adapter
- persistence, summary, and health functions exposed on the MoonBook adapter

Important ownership rule:

- semantic durable domain memory belongs to `moonbook`
- executable run/session state does not

That means `moonbook` is where domain meaning is shaped and reviewed, even when
Moontown temporarily stores catalog/bootstrap mirrors of book metadata.

## Relationship To Moontown

`MoonBook` is surfaced to `moontown` through a provider-backed harness boundary.
The current repo shows:

- catalog-backed `BookProvider`
- bootstrap loading and normalization of book entries
- workspace initialization through real `moonbook wiki init`
- MoonClaw extension seeding through real `moonbook wiki enable moonclaw`
- goal acceptance, task batch production, and worker-context hydration

This makes `MoonBook` the main domain/harness dependency that `moontown` uses to
turn town-level intent into book-local planning material.

That dependency is now durable in two complementary source pages rather than only
in repo docs:

- `wiki/sources/moonbook-readme.md` captures the MoonBook-facing harness and
  durable-memory role
- `wiki/sources/moonbook-keeper-call-chain.md` captures how MoonBook task and
  context outputs feed mayor packet preparation

## Relationship To MoonClaw

The strongest current evidence shows MoonBook upstream of execution, not as the
execution runtime itself.

Current handoff path:

```text
BookTask
  -> WorkerContextBundle
  -> Mayor.prepare_keeper_packet(...)
  -> ExternalProposalPacket
  -> moonclaw proposal import --json
```

`WorkerContextBundle` is the clearest seam: it carries prompt, context pages,
skill paths, memory summary, and output contract into the externally imported
proposal packet.

This is the executable ownership split:

- `moonbook` owns domain context and review policy
- `moonclaw` owns role runtime metadata, proposal/run lifecycle, and execution
  state

## Keeper Boundary

The docs are explicit that the actual keeper implementation still belongs on the
MoonBook side, even though this repo now prepares real keeper-facing proposal
packets using MoonBook-hydrated context.

So the strongest maintained claim is not "keeper is implemented here". It is:

- the keeper handoff target is modeled here
- the MoonBook-side context source is modeled and partly executed here
- the downstream keeper implementation boundary remains external to this
  worktree

See `wiki/sources/moonbook-keeper-call-chain.md`.

## Bootstrap Lane Evidence

Bootstrap-lane evidence for MoonBook in this worktree is substantive enough to
merge here rather than creating a separate concept page.

Visible evidence:

- `default_catalog_path()` and `load_or_create_catalog(...)`
- `default_workspace_root(book_id)`
- `load_or_create_provider(...)`
- usage docs saying missing MoonBook workspaces are initialized during bootstrap
- architecture docs placing the MoonBook catalog at the start of the bootstrap
  flow

This supports a concrete claim that MoonBook provides the durable bootstrap lane
for domain identity and planning context.

It also ties the bootstrap lane to a specific durable source path:

- `wiki/sources/moonbook-readme.md` for catalog/workspace expectations
- `wiki/sources/moonbook-keeper-call-chain.md` for worker-context and packet
  handoff evidence

## Provider Registry Uncertainty

There is solid evidence for a provider-backed MoonBook boundary via
`BookProvider`, but not for a broader, independently documented registry model.

Scoped conclusion:

- the book catalog/provider layer is real
- whether a wider provider registry exists beyond this adapter boundary is not
  established in this worktree

## Cross-links

- `wiki/entities/Moontown.md`
- `wiki/entities/MoonClaw.md`
- `wiki/concepts/provider-backed-execution.md`
- `wiki/concepts/raw-first-wiki-ingest.md`
- `wiki/synthesis/claims.md`
- `wiki/synthesis/map.md`
- `wiki/sources/moonbook-readme.md`
- `wiki/sources/moonbook-keeper-call-chain.md`

## Provenance

Primary evidence:

- `docs/ARCHITECTURE.md`
- `README.mbt.md`
- `docs/PACKAGES.md`
- `docs/USAGE.md`
- `adapters/moonbook/client.mbt`
- `roles/mayor.mbt`
- `adapters/moonclaw/client.mbt`
- `wiki/sources/moonbook-readme.md`
- `wiki/sources/moonbook-keeper-call-chain.md`
