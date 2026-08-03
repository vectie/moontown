# Moontown-MoonBook-MoonClaw stack

## Status

- Durable source page derived from repository-local documentation and code.
- This page does not replace raw bootstrap packet provenance; the packet files named in the approved revision plan were not present in this worktree during this step.
- Claims here stay at the seam and contract level and avoid provider-target diagnosis or unverified cross-repo internals.

## Core claim

`moontown` is documented and implemented as the top control-plane layer above `moonbook` domain harnesses and `moonclaw` execution/runtime surfaces.

Supporting evidence:

- `README.md` describes Moontown as "the town-level orchestration layer above multiple `moonbook` domains and multiple `moonclaw` runtimes." (`README.md:7`)
- `docs/ARCHITECTURE.md` presents the stack directly as `moontown -> moonbook -> moonclaw`. (`docs/ARCHITECTURE.md:3`)
- `docs/ARCHITECTURE.md` assigns town-wide orchestration to `moontown`, domain harness and durable memory to `moonbook`, and role-specialized runtimes plus task execution to `moonclaw`. (`docs/ARCHITECTURE.md:13`, `docs/ARCHITECTURE.md:33`, `docs/ARCHITECTURE.md:50`)

## Observed layer boundaries

### Moontown

Observed responsibilities in repo docs:

- global orchestration, routing, scheduling, health monitoring, operator UI, and town-wide persistence (`docs/ARCHITECTURE.md:15`)
- packet, proposal, and run lifecycle tracking in town state (`README.md:131`)
- a control-plane-first prototype rather than a fully live 24/7 runtime (`README.md:60`)

### MoonBook

Observed boundary claims in repo docs and adapter code:

- per-domain harness layer with workspace root, domain identity, memory policy, context hydration, local planning, and result persistence decisions (`docs/ARCHITECTURE.md:33`)
- a persisted catalog and `BookProvider` implementation (`README.md:45`, `docs/PACKAGES.md:134`)
- real CLI-backed calls for workspace init, extension enablement, goal acceptance, task batch production, context hydration, persistence, summary, and health reporting (`docs/PACKAGES.md:146`, `docs/PACKAGES.md:151`, `adapters/moonbook/client.mbt:425`)

What is evidenced here is the interface boundary from this repo into MoonBook, not MoonBook's full internal implementation.

### MoonClaw

Observed boundary claims in repo docs and adapter code:

- underlying agent substrate owning role-specialized runtimes, task execution, tools, skills, session state, and result packaging (`docs/ARCHITECTURE.md:50`)
- embedded runtime profiles for mayor, keeper, and worker roles with explicit planning layer, runtime mode, tool access, and memory scope (`adapters/moonclaw/client.mbt:584`, `adapters/moonclaw/client.mbt:609`, `adapters/moonclaw/client.mbt:629`)
- a real CLI-backed proposal import boundary via `moonclaw proposal import --json`, plus run polling (`docs/PACKAGES.md:176`, `adapters/moonclaw/client.mbt:311`)

This supports a contract boundary to MoonClaw, not a full claim about all MoonClaw persistence or orchestration internals.

## Role and handoff model

The repo consistently describes a layered role model instead of a single generic worker runtime:

- `Mayor` is a strategic planner-only runtime with limited tools, global scope, and delegation enabled (`docs/ARCHITECTURE.md:72`, `adapters/moonclaw/client.mbt:584`)
- `keeper` is modeled as a domain planner-only runtime with book-local scope and limited tools (`docs/ARCHITECTURE.md:98`, `adapters/moonclaw/client.mbt:609`)
- workers remain execution runtimes with workspace scope and full execution tools (`docs/ARCHITECTURE.md:113`, `adapters/moonclaw/client.mbt:629`)
- `Mayor.prepare_keeper_packet(...)` hydrates book context, chooses a profile, and emits a keeper packet plus handoff metadata (`roles/mayor.mbt:93`)

The docs also state that keeper implementation belongs on the MoonBook side even though Moontown prepares the packet boundary here (`docs/ARCHITECTURE.md:107`).

## Packet-first execution seam

The strongest observed runtime seam in this repo is packet-first handoff across package boundaries:

1. MoonBook-facing code accepts goals, produces task batches, and hydrates worker context bundles (`docs/PACKAGES.md:148`, `adapters/moonbook/client.mbt:425`)
2. Mayor code prepares keeper-facing packets from book tasks and hydrated context (`roles/mayor.mbt:93`)
3. MoonClaw-facing code serializes `ExternalProposalPacket`, saves packet files under `.moontown/packets`, and imports them through the MoonClaw CLI (`adapters/moonclaw/client.mbt:199`, `adapters/moonclaw/client.mbt:209`, `adapters/moonclaw/client.mbt:311`)
4. Town state records packet, proposal, and run lifecycle identifiers (`docs/ARCHITECTURE.md:184`, `README.md:131`)

This page intentionally does not claim a verified root cause for any provider-target error thread and does not infer deeper execution/result semantics than the documented packet/import/poll seam.

## Current limitations and cautions

Documented as still stubbed in this repo:

- long-running run-status polling and completion ingestion are incomplete at the system level even though a polling surface exists (`README.md:56`, `adapters/moonclaw/client.mbt:390`)
- automatic result persistence back into external MoonBook after completed runs is still presented as unfinished at the top-level product status (`README.md:57`)
- daemon patrol/recovery and full backend/frontend sync remain incomplete (`README.md:58`)

Accordingly, durable claims should stay with currently evidenced interfaces, data shapes, and intended ownership boundaries.

## Related pages

- [Layered town-book-runtime stack](../concepts/layered-town-book-runtime-stack.md)
- [Wiki index](../index.md)
- [Evidence notes](../synthesis/evidence.md)
