# MoonClaw

## Status

Maintained entity surface revised against the MoonClaw-facing adapter,
architecture docs, and durable source pages. This page intentionally scopes
claims to the MoonClaw surfaces visible from the Moontown repo rather than
asserting undocumented upstream behavior.

## Role

`MoonClaw` is the underlying agent substrate in the documented stack:

```text
moontown -> moonbook -> moonclaw
```

The current maintained docs assign `moonclaw` ownership of:

- role-specialized runtimes
- task execution
- tools and skills
- session state
- result packaging

This is the executable side of the semantic-versus-executable split.

## Executable Ownership

High-confidence MoonClaw-owned surfaces visible in this worktree:

- `EmbeddedMoonclawRuntime` with planning layer, runtime mode, tool access,
  memory scope, and authority metadata
- `EmbeddedRuntimeHandoff` and `EmbeddedHandoffKind`
- `ExternalProposalPacket`
- `ProposalImportReceipt`
- `ProposalPollResponse`
- run import, confirmation, and polling helpers
- packet persistence under `.moontown/packets/`

Moontown records these surfaces, but it does not own them semantically in the
same way it owns `TownState`.

## Embedded Role Topology

The adapter exposes a three-part runtime topology:

- `mayor_runtime()` for the strategic planner-only town role
- `keeper_runtime(book)` for the domain planner-only role
- `worker_runtime(worker)` for the execution role with full tool access

This is important because it shows `moonclaw` is not just an opaque executor.
It is the executable role substrate behind the semantic town/book topology.

## Relationship To Moontown

`Moontown` embeds and constrains MoonClaw through role adapters instead of
calling a raw worker runtime directly.

Evidence:

- `Mayor::new()` uses `@moonclaw.mayor_runtime()`
- `Mayor.handoff_to_keeper(...)` uses `@moonclaw.mayor_to_keeper_handoff(...)`
- `Mayor.prepare_keeper_packet(...)` builds an `ExternalProposalPacket`
- `TaskExecutionRecord` stores packet path, proposal id, run id, and status in
  town state

This means `moontown` semantically owns orchestration and recording, while
`moonclaw` owns the executable run boundary.

## Relationship To MoonBook

MoonBook feeds MoonClaw through the worker-context seam.

Code-level evidence shows `proposal_packet_from_bundle(...)` copying
MoonBook-originated fields into the executable packet:

- `bundle.prompt` -> `request_text`
- `bundle.context_pages` -> `context_pages`
- `bundle.skill_paths` -> `skill_paths`
- `bundle.output_contract` -> output contract
- metadata including `book_id`, `workspace_root`, `task_id`, and
  `memory_summary`

So MoonClaw execution depends on MoonBook-provided context, but ownership of
that context remains with MoonBook.

The maintained source set makes this seam visible from both sides:

- `wiki/sources/moonbook-keeper-call-chain.md` traces the handoff into the
  packet boundary
- `wiki/sources/moontown-moonbook-moonclaw-topology.md` keeps the broader
  ownership split visible so the handoff is not mistaken for MoonBook owning
  execution

## Bootstrap And Lifecycle Evidence

The bootstrap/process lane visible here is stronger than a generic architecture
claim. The adapter shows a concrete command boundary:

```text
moon -C {moonclaw_root} run cmd/main -- proposal import {packet_path} --json --cwd {cwd} --home {home}
```

And the resulting lifecycle evidence is concrete enough to maintain:

- packet file path
- proposal id
- run id
- status transitions such as `ProposalImported`, `RunConfirmed`, `Running`,
  `Completed`, and `Failed`

Caveat: the architecture docs still classify long-running polling and automatic
result persistence back into MoonBook as not yet fully live end to end.

## Provider Registry Uncertainty

MoonClaw runtime metadata exposes visible tool names and authority scopes, but
this worktree does not provide a separate maintained provider registry surface.

Scoped conclusion:

- runtime-visible tools/providers are represented in metadata
- a broader provider-registry contract remains uncertain and should not be
  overstated

## Cross-links

- `wiki/entities/Moontown.md`
- `wiki/entities/MoonBook.md`
- `wiki/concepts/provider-backed-execution.md`
- `wiki/synthesis/map.md`
- `wiki/synthesis/claims.md`
- `wiki/sources/moontown-moonbook-moonclaw-topology.md`
- `wiki/sources/moonbook-keeper-call-chain.md`

## Provenance

Primary evidence:

- `docs/ARCHITECTURE.md`
- `docs/PACKAGES.md`
- `docs/USAGE.md`
- `roles/mayor.mbt`
- `adapters/moonclaw/client.mbt`
- `adapters/moonbook/client.mbt`
- `core/types.mbt`
- `wiki/sources/moontown-moonbook-moonclaw-topology.md`
- `wiki/sources/moonbook-keeper-call-chain.md`
