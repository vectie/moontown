# Moonbook Keeper Call Chain

## Status

- Durable source page created from currently accessible local repo materials plus preserved bootstrap-packet provenance.
- Scope is intentionally limited to the `moontown` side of the `moonbook -> keeper -> MoonClaw` handoff chain.
- Cross-repo behavior on the `moonbook` and `moonclaw` sides is linked as context, not restated as fully revalidated fact here.

## Why this page exists

- The local repo documents and code expose a concrete keeper-packet preparation and import chain that is important enough to preserve as a standalone durable source page.
- The prepared bootstrap packet already distilled the strongest locally inspected claims and explicitly recorded where cross-repo statements remain inherited rather than freshly re-read.
- This page preserves that packet provenance while grounding each durable claim in local source files whenever possible.

## Scoped claims

- `moontown` treats the keeper as the book-local planning/runtime handoff target rather than as a town-owned execution runtime. Evidence: `README.mbt.md:121`, `README.mbt.md:131`, `docs/ARCHITECTURE.md:98`, `docs/ARCHITECTURE.md:109`
- The documented bootstrap path includes `moonbook catalog -> book task batch -> keeper packet -> MoonClaw proposal/run receipt -> town snapshot bootstrap -> dashboard / render model / frontend`. Evidence: `README.mbt.md:177`, `README.mbt.md:182`, `README.mbt.md:187`
- The Mayor role is the local orchestration surface that prepares keeper proposal packets and strategic handoffs. Evidence: `docs/USAGE.md:160`, `docs/USAGE.md:163`, `docs/USAGE.md:171`, `docs/USAGE.md:174`, `roles/mayor.mbt:93`
- `Mayor::prepare_keeper_packet(...)` hydrates worker context from the `moonbook` adapter, derives a task-specific MoonClaw profile, builds an external proposal packet, and records the expected packet file path. Evidence: `roles/mayor.mbt:93`, `roles/mayor.mbt:99`, `roles/mayor.mbt:101`, `roles/mayor.mbt:102`, `roles/mayor.mbt:119`
- The generated handoff is strategic-to-domain and targets `keeper:{book_id}` with output contract `keeper.plan.packet.v1`. Evidence: `roles/mayor.mbt:112`, `adapters/moonclaw/client.mbt:635`, `adapters/moonclaw/client.mbt:642`, `adapters/moonclaw/client.mbt:646`, `adapters/moonclaw/client.mbt:647`
- The local keeper runtime model is planner-only, domain-scoped, limited-tool, and authority-scoped to the book, which supports the repo's boundary claims without proving downstream execution success. Evidence: `docs/ARCHITECTURE.md:100`, `docs/ARCHITECTURE.md:103`, `docs/ARCHITECTURE.md:105`, `adapters/moonclaw/client.mbt:590`, `adapters/moonclaw/client.mbt:595`, `adapters/moonclaw/client.mbt:601`, `adapters/moonclaw/client.mbt:609`, `adapters/moonclaw/client.mbt:610`
- Packet import writes the packet file locally and invokes a MoonClaw `proposal import` command, returning either `ProposalImported` or `RunConfirmed` depending on whether a run id is present. Evidence: `adapters/moonclaw/client.mbt:311`, `adapters/moonclaw/client.mbt:321`, `adapters/moonclaw/client.mbt:322`, `adapters/moonclaw/client.mbt:329`, `adapters/moonclaw/client.mbt:354`, `adapters/moonclaw/client.mbt:357`

## Local call-chain outline

```text
BookCatalogEntry + BookTask
  -> moonbook.hydrate_worker_context(...)
  -> Mayor.prepare_keeper_packet(...)
  -> moonclaw.proposal_packet_from_bundle(...)
  -> moonclaw.packet_file_path(...)
  -> moonclaw.import_packet(...)
  -> ProposalImportReceipt / TaskExecutionStatus
```

## What the local code establishes

### 1. Task context comes from the moonbook adapter

- `Mayor::prepare_keeper_packet(...)` starts by calling `@moonbook.hydrate_worker_context(entry, task)`. Evidence: `roles/mayor.mbt:99`
- `hydrate_worker_context(...)` shells out through the moonbook-facing JSON command path using `context`, the book workspace root, the goal or prompt, and the task id. Evidence: `adapters/moonbook/client.mbt:410`, `adapters/moonbook/client.mbt:414`, `adapters/moonbook/client.mbt:417`, `adapters/moonbook/client.mbt:419`
- This supports a narrow claim: `moontown` depends on `moonbook` to materialize the worker/keeper context bundle; it does not construct that bundle entirely by itself.

### 2. The mayor shapes both a handoff and a packet

- The mayor returns a `MayorKeeperPacket` containing both `handoff` and `packet`, plus `packet_path` and rationale. Evidence: `roles/mayor.mbt:46`, `roles/mayor.mbt:47`, `roles/mayor.mbt:49`, `roles/mayor.mbt:50`
- The handoff path calls `Mayor::handoff_to_keeper(...)`, which delegates to `@moonclaw.mayor_to_keeper_handoff(...)`. Evidence: `roles/mayor.mbt:76`, `roles/mayor.mbt:84`
- The packet path calls `@moonclaw.proposal_packet_from_bundle(...)` and adds notes/tags that mark the packet as mayor-produced keeper work. Evidence: `roles/mayor.mbt:102`, `roles/mayor.mbt:108`, `roles/mayor.mbt:109`

### 3. The keeper target is intentionally constrained

- The keeper runtime is not modeled as a general executor in local code; it is `Domain` + `PlannerOnly` with limited tools and no workspace writes. Evidence: `adapters/moonclaw/client.mbt:595`, `adapters/moonclaw/client.mbt:596`, `adapters/moonclaw/client.mbt:597`, `adapters/moonclaw/client.mbt:600`
- The visible tools list is book-local in character: `book-workspace`, `book-memory`, `review-queue`, and `local-summaries`. Evidence: `adapters/moonclaw/client.mbt:602`, `adapters/moonclaw/client.mbt:603`
- This matches the architecture note that the actual keeper implementation belongs on the `moonbook` side. Evidence: `docs/ARCHITECTURE.md:107`, `docs/ARCHITECTURE.md:109`

### 4. Import crosses from packet preparation into proposal lifecycle tracking

- `import_packet(...)` persists the JSON packet before calling the external MoonClaw import command. Evidence: `adapters/moonclaw/client.mbt:321`, `adapters/moonclaw/client.mbt:322`, `adapters/moonclaw/client.mbt:343`, `adapters/moonclaw/client.mbt:344`
- The returned receipt records packet id/path, proposal id, optional run id, command, summary, and task-execution status. Evidence: `adapters/moonclaw/client.mbt:349`, `adapters/moonclaw/client.mbt:351`, `adapters/moonclaw/client.mbt:352`, `adapters/moonclaw/client.mbt:353`, `adapters/moonclaw/client.mbt:359`
- The lifecycle wording in docs remains consistent with this code path: `book task -> keeper packet -> imported proposal -> confirmed run -> persistence -> review`. Evidence: `docs/USAGE.md:256`, `docs/USAGE.md:259`

## Source-path notes

- Primary repo overview page: `README.mbt.md`
- Primary repo topology/boundary page: `docs/ARCHITECTURE.md`
- Role and lifecycle usage page: `docs/USAGE.md`
- Local implementation anchors: `roles/mayor.mbt`, `adapters/moonbook/client.mbt`, `adapters/moonclaw/client.mbt`
- Preserved raw packet provenance: `../step-4-write-bootstrap-packet/raw/bootstrap/docs-lane-bootstrap-packet.md`
- This page intentionally links readers back to the repo overview and topology sources rather than duplicating broader architecture claims not needed for the call-chain itself.

## Provenance and uncertainty

- Direct local grounding in this page comes from current `moontown` docs and implementation files listed above.
- The preserved bootstrap packet explicitly says cross-repo `moonbook` and `moonclaw` statements were inherited from prior workflow outputs rather than freshly revalidated in that packet step. Provenance: `../step-4-write-bootstrap-packet/raw/bootstrap/docs-lane-bootstrap-packet.md:24`, `../step-4-write-bootstrap-packet/raw/bootstrap/docs-lane-bootstrap-packet.md:25`
- Because the current worktree does not expose the separate `moonbook` and `moonclaw` repos directly, this page does not claim to verify the downstream keeper implementation, packet ingestion semantics beyond the local import command wrapper, or end-to-end persistence back into `moonbook`.
- The local repo docs also describe important runtime pieces as still partial or stubbed, so this page should be read as a durable source on interface shape and ownership boundaries, not as proof of full operational completeness. Evidence: `../step-4-write-bootstrap-packet/raw/bootstrap/docs-lane-bootstrap-packet.md:34`, `README.mbt.md:54`, `README.mbt.md:57`

## Related pages to consult next

- Repo overview: `README.mbt.md`
- Repo topology and ownership boundaries: `docs/ARCHITECTURE.md`
- Keeper packet lifecycle wording: `docs/USAGE.md`
- If a wiki overview/topology page exists later, link this page from that page rather than expanding this source page into a full architecture summary.
