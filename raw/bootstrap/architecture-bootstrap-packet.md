# Architecture Bootstrap Packet

Job: `job.proposal.20260417-201359-act-as-the-wiki-gather-usersk`
Run: `run-20260417-201420-usersk`
Step: `write-architecture-packet`
Lane: `architecture`
Status: handoff-ready bootstrap packet for later source materialization

## Lane scope

- Focus on architecture-specific claims about system layers, ownership boundaries, packet lifecycle, persistence boundaries, UI-shell separation, and the keeper/proposal topology.
- Prefer `docs/ARCHITECTURE.md` as the primary authority, with `README.md` and `ui/rabbita-town/README.md` only for boundary clarification.
- Use runtime files only where the architecture doc itself points to them for contradiction checks or to anchor a boundary claim.
- Exclude docs-lane summaries, product framing, usage walkthroughs, package inventories, and broad implementation wiring unless required to support an architecture claim.

## Provenance

### Direct inspection in this lane

- `docs/ARCHITECTURE.md`
- `README.md`
- `ui/rabbita-town/README.md`
- `roles/mayor.mbt`
- `adapters/moonbook/client.mbt`
- `adapters/moonclaw/client.mbt`
- `storage/store.mbt`

### Carried-forward context from previous steps

- Scope guardrails from `scope-architecture-slice`
- Evidence extraction and synthesis from `extract-architecture-evidence`

### Separation rule

- Claims labeled as direct inspection are grounded in the inspected files above.
- Claims labeled as carried-forward context are inherited from prior step outputs and should be re-materialized against source files later if they become high-value canonical assertions.

## Source-by-source evidence

### `docs/ARCHITECTURE.md` (primary authority)

- Direct inspection:
  - Declares a three-layer system with `moontown -> moonbook -> moonclaw` and places `moontown` at the top of that stack in `docs/ARCHITECTURE.md:3`.
  - Splits durable ownership into town-wide, domain-specific durable, and task-session-specific records in `docs/ARCHITECTURE.md:123`.
  - Assigns orchestration, routing/isolation, health, scheduling, persistence, and operator UI to `moontown` in `docs/ARCHITECTURE.md:15`.
  - Assigns workspace root, domain identity, memory policy, context hydration, local planning, and persistence decisions to `moonbook` in `docs/ARCHITECTURE.md:35`.
  - Assigns task execution, tools/skills, session state, and result packaging to `moonclaw` in `docs/ARCHITECTURE.md:52`.
  - Describes a split packet lifecycle where `adapters/moonbook` hydrates context, `roles/mayor` chooses route and prepares keeper-facing packets, `adapters/moonclaw` shapes proposal/import models, and core records execution status in `docs/ARCHITECTURE.md:167`.
  - Marks current real boundaries versus stubbed boundaries, including real packet import/lifecycle tracking and stubbed long-running polling plus automatic result persistence in `docs/ARCHITECTURE.md:213` and `docs/ARCHITECTURE.md:225`.
  - Calls `.moontown/packets/` optional exported keeper packet storage, while `.moontown/moonbooks.json` and `.moontown/town.json` are presented as current persisted files in `docs/ARCHITECTURE.md:197`.
  - Describes mayor as a constrained embedded moonclaw runtime and keeper as conceptually embedded but still owned on the moonbook side in `docs/ARCHITECTURE.md:72` and `docs/ARCHITECTURE.md:98`.
- Architecture interpretation:
  - Strongest source for intended package-boundary ownership, lifecycle segmentation, and explicit real-versus-stubbed boundaries.
- Uncertainty marker:
  - Proves intended architecture and current claimed implementation state, but does not by itself prove complete end-to-end live keeper execution or completion ingestion.

### `README.md` (topology corroboration only)

- Direct inspection:
  - Restates `moontown` as the town-level orchestration layer above multiple moonbook domains and multiple moonclaw runtimes in `README.md:7`.
  - Restates the semantic split as orchestration in `moontown`, harness and memory control in `moonbook`, and execution-heavy behavior in `moonclaw` in `README.md:134`.
  - Names `adapters/moonbook` as the moonbook catalog and book-harness boundary in `README.md:101`.
  - Names `adapters/moonclaw` as embedded runtime profiles and a future execution boundary in `README.md:103`.
  - Repeats the packet lifecycle path `BookTask -> WorkerContextBundle -> ExternalProposalPacket -> ProposalImportReceipt -> TaskExecutionRecord` in `README.md:199`.
  - Matches the architecture doc's implemented-versus-stubbed status in `README.md:41` and `README.md:54`.
- Architecture interpretation:
  - Secondary corroboration that `moontown` sits above both `moonbook` and `moonclaw`, not beside them.
- Uncertainty marker:
  - Descriptive and repo-level; weaker than `docs/ARCHITECTURE.md` for authoritative boundary claims.

### `ui/rabbita-town/README.md` (presentation boundary check)

- Direct inspection:
  - Identifies Rabbita as the browser-facing frontend for `moontown` in `ui/rabbita-town/README.md:3`.
  - States that renderer-agnostic scene contracts come from the root module in `ui/rabbita-town/README.md:5`.
  - States that town orchestration and scene modeling remain in the main module while the package provides a browser shell in `ui/rabbita-town/README.md:11`.
  - Notes the frontend is local/demo-driven and not attached to a real town backend in `ui/rabbita-town/README.md:29`.
- Architecture interpretation:
  - Supports a UI-shell boundary where presentation is separable from orchestration ownership.
- Uncertainty marker:
  - Does not prove anything substantial about agent execution or cross-process runtime topology beyond frontend packaging.

### `roles/mayor.mbt` (orchestration seam corroboration)

- Direct inspection:
  - `Mayor` wraps an `EmbeddedMoonclawRuntime` in `roles/mayor.mbt:2`.
  - `Mayor::decide_dispatch` delegates routing and emits a mayor-specific output contract in `roles/mayor.mbt:24`.
  - `Mayor::patrol` invokes town health and scheduler behavior in `roles/mayor.mbt:63`.
  - `Mayor::handoff_to_keeper` and `Mayor::prepare_keeper_packet` show the town layer preparing keeper-facing handoff material in `roles/mayor.mbt:76` and `roles/mayor.mbt:93`.
  - Packet preparation hydrates book context via `@moonbook`, derives a profile, and shapes a packet via `@moonclaw` in `roles/mayor.mbt:93`.
  - Keeper preparation constraints include packet-first handoff and isolated book memory in `roles/mayor.mbt:112`.
- Architecture interpretation:
  - Key runtime seam where `moontown` converts routing intent into keeper-facing proposal material through adapters instead of directly becoming the execution engine.
- Uncertainty marker:
  - Proves packet preparation, not keeper-side execution completion or final persistence choreography.

### `adapters/moonbook/client.mbt` (book-harness boundary corroboration)

- Direct inspection:
  - `BookCatalogEntry` includes `workspace_root`, `memory_scope`, tags, and skills in `adapters/moonbook/client.mbt:2`.
  - Default workspace root is `.moontown/books/{book_id}` in `adapters/moonbook/client.mbt:96`.
  - Default moonbook root is externalized as `../moonbook` in `adapters/moonbook/client.mbt:106`.
  - `WorkerContextBundle` includes prompt/policy/routines/skills/context pages/memory projection/output contract in `adapters/moonbook/client.mbt:260`.
  - Adapter entry points include `accept_goal`, `produce_task_batch`, `hydrate_worker_context`, `persist_result`, `summarize_state`, and `report_health` in `adapters/moonbook/client.mbt:380`.
  - `ensure_workspace` enables moonclaw support in a book workspace and checks for `moonclaw.jobs.json` in `adapters/moonbook/client.mbt:567`.
  - `run_book_json_command` shells into `moonbook` CLI commands rather than re-implementing harness logic in `adapters/moonbook/client.mbt:597`.
  - Temporary result staging occurs under `.moontown/book-results/{task_id}.json` in `adapters/moonbook/client.mbt:551`.
- Architecture interpretation:
  - Strong evidence that `moonbook` remains the executable harness and durable-memory authority, while `moontown` interacts through a CLI-backed adapter seam.
- Uncertainty marker:
  - Existence of `persist_result` does not prove that current orchestration automatically invokes it after run completion; the architecture doc still marks that flow stubbed.

### `adapters/moonclaw/client.mbt` (execution-envelope boundary corroboration)

- Direct inspection:
  - `EmbeddedMoonclawRuntime` models planning layer, runtime mode, tool access, memory scope, delegation, workspace-write allowance, execution-tool allowance, and authority scope in `adapters/moonclaw/client.mbt:38`.
  - Enumerations distinguish `Strategic`, `Domain`, and `Execution` layers in `adapters/moonclaw/client.mbt:2`.
  - `EmbeddedRuntimeHandoff` models strategic/domain/execution handoff kinds and associated constraints in `adapters/moonclaw/client.mbt:91`.
  - `ExternalProposalPacket`, `ProposalImportReceipt`, and `ProposalPollResponse` are first-class boundary types in `adapters/moonclaw/client.mbt:120` and `adapters/moonclaw/client.mbt:146`.
  - `proposal_packet_from_bundle` stamps producer metadata including `moontown`, `book_id`, `workspace_root`, and `task_id` in `adapters/moonclaw/client.mbt:209`.
  - Packet output contract falls back to a default JSON-object instruction when not supplied in `adapters/moonclaw/client.mbt:251`.
  - Packet storage defaults to `.moontown/packets` in `adapters/moonclaw/client.mbt:199`.
- Architecture interpretation:
  - Strong evidence that `moonclaw` is consumed as a constrained runtime/profile and packet substrate rather than as a generalized orchestration owner.
- Uncertainty marker:
  - Type support for polling and receipts does not prove long-running polling or terminal-state ingestion is operational today.

### `storage/store.mbt` (town persistence boundary corroboration)

- Direct inspection:
  - `TownSnapshot` stores `@core.TownState` plus event count in `storage/store.mbt:14`.
  - Default snapshot path is `.moontown/town.json` in `storage/store.mbt:35`.
  - Snapshot creation seeds from a town-state factory when missing in `storage/store.mbt:61`.
- Architecture interpretation:
  - Supports the claim that town-state persistence belongs to `moontown`, without pulling in domain-memory durability.
- Uncertainty marker:
  - Does not prove that every runtime lifecycle transition is always flushed into snapshot state before handoff or shutdown.

## System-boundary notes

- Direct inspection:
  - `moontown` is the semantic and orchestration owner for routing, patrol/health, scheduling, and town-wide persistence.
  - `moonbook` is the domain-harness owner for workspace identity, memory policy, context hydration, summary/health, and persistence decisions.
  - `moonclaw` is the execution substrate owner for runtime profiles, tool/session constraints, packet envelopes, receipts, and execution-oriented roles.
  - Rabbita is a browser shell boundary, not an alternative orchestration authority.
- Carried-forward context:
  - The architecture slice intentionally excludes generalized product docs and broad implementation tracing, so these boundary notes should remain architecture-only and not drift into usage or UI behavior summaries.

## Call-chain / topology interpretation

- Direct inspection:
  - The dominant architecture path is `BookTask -> WorkerContextBundle -> ExternalProposalPacket -> ProposalImportReceipt -> TaskExecutionRecord`, anchored by `README.md:199` and the lifecycle split in `docs/ARCHITECTURE.md:167`.
  - `moonbook` accepts goals and hydrates worker context; `Mayor` chooses dispatch and prepares keeper packets; `moonclaw` shapes importable proposal artifacts and receipt/poll models.
  - This reads as a packet-first topology where strategic dispatch stays in `moontown`, domain shaping stays in `moonbook`, and execution packaging/import lives at the `moonclaw` boundary.
- Carried-forward context:
  - The prior evidence pass interpreted this as a partially live lifecycle: packet preparation/import/tracking are real enough to cite, while long-running polling and automatic result persistence remain intentionally incomplete.
- Explicit uncertainty:
  - Avoid claiming a fully operational continuous keeper execution loop; the strongest sources explicitly reserve polling and result persistence as stubbed.

## Cross-component responsibility splits

- Direct inspection:
  - `moontown`: routing, patrol, scheduler/health coordination, packet-path recording, town snapshots, operator-facing orchestration.
  - `moonbook`: book catalog identity, workspace root, memory scope, context hydration, book-local planning, persistence and summary/health responses.
  - `moonclaw`: runtime-profile restrictions, handoff schema, proposal packet/receipt schema, execution-layer capability expression.
  - `ui/rabbita-town`: browser-facing shell consuming renderer-agnostic scene contracts from the main module.
- Explicit uncertainty:
  - The boundary between conceptual keeper embedding and actual keeper implementation remains asymmetric: the architecture doc says keeper is modeled as embedded but still belongs on the moonbook side.

## Relationship candidates

- `moontown` as orchestration and semantic owner over outputs sourced from `moonbook` and envelopes sourced from `moonclaw`.
- `moonbook` as the durable domain authority that can project context into packets without surrendering memory ownership to `moontown`.
- `moonclaw` as the constrained execution substrate and transport-envelope provider consumed through adapters, not as the place where town semantics live.
- `Mayor` as the seam translating strategic dispatch into keeper-facing proposal material while preserving packet-first and memory-isolation constraints.
- Rabbita as a presentation extension of `moontown`, not a peer architecture owner.

## Candidate durable source pages

- `docs/ARCHITECTURE.md`
- `README.md`
- `ui/rabbita-town/README.md`
- `roles/mayor.mbt`
- `adapters/moonbook/client.mbt`
- `adapters/moonclaw/client.mbt`
- `storage/store.mbt`

## Explicit uncertainty markers

- Missing preferred architecture sources named earlier in the process, including `docs/SYSTEM_ARCHITECTURE.md`, `docs/WIKI_WORKFLOW.md`, and `docs/KEEPER_CALL_CHAIN.md`, were not present in the workspace and should be treated as unresolved rather than backfilled.
- Packet lifecycle claims are strong for shaping/import/tracking boundaries, but weak for full run completion handling because polling and auto-persist remain documented as stubbed.
- Workspace partitioning under `.moontown/books/{book_id}` is well supported, but broader claims about agent-agnostic extension packs remain only moderately supported from the inspected material.
- The architecture docs cite current implementation locations, but those citations do not by themselves prove that every path is exercised in production traffic.
- The UI README confirms frontend-shell separation only; it should not be stretched into stronger backend topology claims.

## Handoff notes for later materialization

- Preserve the distinction between direct inspection and carried-forward context when lifting this packet into a durable source.
- Prefer `docs/ARCHITECTURE.md` for normative ownership and status claims; use runtime files as corroboration or contradiction checks, not as the primary narrative source.
- Do not expand this lane into docs-lane summaries or implementation-lane wiring unless a future architecture claim specifically requires anchoring detail.
