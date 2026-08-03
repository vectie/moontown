# Architecture Lane Bootstrap Packet

- Lane label: `architecture`
- Job id: `job.proposal.20260417-193710-act-as-the-wiki-gather-usersk`
- Run id: `run-20260417-193726-usersk`
- Step id: `step_4_write_architecture_packet`
- Packet intent: concrete handoff artifact for later architecture-source materialization, limited to system boundaries, topology, ownership seams, persisted artifact layout, and cross-component call-chain notes.

## Non-duplication boundary

This packet is intentionally architecture-lane scoped and should not duplicate the neighboring lane artifacts.

- Relative to the docs lane: do not re-harvest broad repository overview, user-facing behavior, UI walkthroughs, setup guidance, feature inventory, or generic documentation synthesis. Only retain documentation excerpts when they directly establish architecture boundaries, role layering, ownership splits, topology, or persisted control-plane artifacts.
- Relative to the implementation lane: do not restate manifest identity, package exposure, CLI/frontend entrypoints, startup wiring, or low-level codepath walkthroughs except where a source is needed to prove an architecture seam or control-plane boundary.
- Materialization target for this lane: architecture notes should answer who owns what, which component hands off to which other component, what durable artifacts exist, what the high-level runtime topology is, and where the verified versus inherited boundaries stop.

## Provenance model

Use the following provenance tags during later materialization.

- `direct`: explicitly stated in inspected architecture/docs sources.
- `implementation-backed`: directly evidenced by inspected local MoonBit source.
- `inherited`: asserted via local docs or adapter contracts about cross-repo components that were not directly inspected in this worktree.
- `unverified`: plausible from naming/types/flow shape but not directly confirmed end-to-end.

## Inspected sources

Primary architecture evidence sources inspected or designated from prior scope and evidence extraction:

- `docs/ARCHITECTURE.md` — principal architecture intent for stack order, role model, ownership split, runtime flow, and persisted topology.
- `README.mbt.md` — supporting high-level cross-component responsibility restatement; secondary evidence only.
- `docs/PACKAGES.md` — package-boundary map, especially for `adapters/moonclaw` and adjacent seams.
- `roles/mayor.mbt` — control-plane strategic adapter and keeper-packet preparation boundary.
- `adapters/moonbook/client.mbt` — moonbook seam for catalog entries, task-batch production, worker-context hydration, and result-persistence surface.
- `adapters/moonclaw/client.mbt` — moonclaw seam for runtime metadata, external proposal packet shaping, import, polling, and packet-path generation.
- `core/types.mbt` — cross-layer contract types including memory scope, isolation, assignment plans, and `TaskExecutionRecord`.
- `moontown.mbt` — orchestration span joining moonbook task generation, mayor packet prep, moonclaw import/poll, and town execution recording.
- `storage/store.mbt` — persisted town snapshot topology and `.moontown` store behavior.

## Evidence bullets

### Control-plane and layering

- `direct`: `docs/ARCHITECTURE.md` defines a top-down stack of `moontown -> moonbook -> moonclaw`, with `moontown` as the town-wide control plane.
- `direct` + `implementation-backed`: responsibility is split by durability and scope, not only package name: town-wide state in `moontown`, domain-durable state in `moonbook`, task/session execution state in `moonclaw`.
- `direct` + `implementation-backed`: runtime roles are layered as Mayor (strategic planner), Keeper (domain planner), and Worker claws (execution), with explicit authority/tool/memory controls surfaced in `adapters/moonclaw/client.mbt`.
- `implementation-backed`: `roles/mayor.mbt` shows Mayor as the architectural boundary where routing decisions and strategic rationale become keeper-facing handoff content and packet preparation.

### Handoff and call-chain

- `implementation-backed`: `moontown.mbt` shows the live handoff span as moonbook task production -> Mayor keeper-packet preparation -> moonclaw packet import -> optional poll/run confirmation -> persistence of `TaskExecutionRecord` into town state.
- `implementation-backed`: `roles/mayor.mbt` hydrates worker context from `@moonbook`, chooses a MoonClaw profile, and forms packet material through MoonClaw-facing helpers rather than directly embedding execution behavior.
- `implementation-backed`: `adapters/moonbook/client.mbt` provides a `WorkerContextBundle` that carries workspace root, prompt/context material, policy/routines, skill paths, and memory fields needed for packet shaping.
- `implementation-backed`: `adapters/moonclaw/client.mbt` converts that context into an `ExternalProposalPacket`, persists packet files, shells into `moonclaw proposal import --json`, and returns a typed receipt containing proposal/run identifiers and status.

### Persistence and topology

- `direct` + `implementation-backed`: persisted control-plane topology includes `.moontown/moonbooks.json`, `.moontown/town.json`, and optional `.moontown/packets/` exports.
- `implementation-backed`: `core/types.mbt` makes cross-boundary lifecycle identifiers first-class in `TaskExecutionRecord` via fields such as `packet_id`, `packet_path`, `proposal_id`, `run_id`, and execution status.
- `implementation-backed`: isolation and memory boundaries are represented in typed forms (`SharedTown`, `BookPrivate`, `TaskEphemeral`; `SharedWorkspace`, `BookWorkspace`, `Worktree`, `Sandboxed`) and carried into assignment/execution contracts.
- `direct` + `implementation-backed`: patrol is a separate control-plane chain from dispatch, combining health inspection, recovery planning, scheduler actions, and Mayor patrol packaging, but the always-on supervisor loop remains stubbed.

### Lifecycle closure and incompleteness

- `direct` + `implementation-backed`: architecture intent assigns result summarization/persistence to moonbook-side seams after moonclaw execution, while town state keeps cross-boundary lifecycle tracking.
- `direct`: long-running polling and automatic persistence back into MoonBook are explicitly described as incomplete/stubbed in architecture docs.
- `implementation-backed`: local code exposes polling and a moonbook persistence seam, but the end-to-end closure from polled run result into persisted moonbook outcomes is not fully demonstrated in the inspected slice.

## Relationship candidates

### Directly supported candidates

- `moontown -> moonbook`: moontown depends on moonbook for catalog entries, goal acceptance/task-batch production, and worker-context hydration before packet creation.
- `moontown -> Mayor`: Mayor is the embedded strategic adapter that moontown calls for dispatch, patrol, and keeper-packet preparation.
- `Mayor -> Keeper`: Mayor is the strategic-to-domain handoff boundary; it prepares keeper-facing handoff content while keeper implementation remains moonbook-side.
- `moonbook -> Keeper`: moonbook owns the domain-local planning context and memory surface that Keeper is expected to consume.
- `Keeper -> Worker`: role layering implies planner-to-executor delegation from keeper to worker claws.
- `moonclaw -> Mayor/ Keeper/ Worker`: moonclaw provides the shared runtime substrate and authority metadata model for all three role layers.
- `moonbook -> packets`: moonbook supplies the source context transformed into packets, even if it does not directly write packet files in the inspected flow.
- `Mayor -> packets`: packet construction is Mayor-owned at the orchestration boundary.
- `packets -> moonclaw`: packets are the import boundary into MoonClaw proposal/run lifecycle handling.
- `moontown -> packets`: moontown owns optional exported packet files under `.moontown/packets` as control-plane artifacts.
- `moontown -> town persistence`: moontown owns `.moontown/town.json` and the visible cross-boundary execution record trail.
- `moonbook -> catalog/domain persistence`: moonbook-facing catalog/domain identity is surfaced through `.moontown/moonbooks.json` and related book metadata.
- `core -> cross-layer contract`: core normalizes orchestration-visible lifecycle state and isolation/memory enums across seams.

### Tentative or inherited candidates

- `Keeper -> packets -> Worker`: plausible and strongly suggested by the role and handoff model, but not locally traced end-to-end in this repo.
- `moonbook -> post-run persistence from moonclaw`: documented as intended, partially surfaced in adapters, but not fully proven in local execution flow.
- `packets as stable inter-repo API`: likely true from adapter/docs shape, but only one-sided from this repo because `../moonclaw` was not inspected.
- `Worker -> moonbook review loop`: implied by review/notification fields, not directly verified end-to-end.
- `assignment isolation -> worker runtime enforcement`: intended by types and constraints, but concrete enforcement point is not visible in the inspected architecture slice.

## Topology notes

- Topology is hierarchical rather than peer-flat: `moontown` governs the control plane, `moonbook` holds domain-local planning and durable knowledge, and `moonclaw` hosts execution/runtime substrate.
- The architectural seam is packet-first for strategic-to-execution handoff: town and domain context are assembled before crossing into moonclaw import semantics.
- `.moontown` acts as the locally inspectable control-plane persistence envelope, with catalog, town snapshot, and optional packet exports exposed in the working repo.
- Cross-repo boundaries are visible through adapters and docs, but only `moontown` sources were directly inspectable in this step; moonbook and moonclaw internals remain adapter-mediated.
- Patrol and dispatch are sibling control-plane flows rather than one unified loop in the locally verified code; the daemonized or 24/7 supervisory aspect remains incomplete.

## Cross-component responsibility notes

- `moontown`: owns orchestration, routing/isolation policy, patrol/recovery coordination, UI-facing town control concerns, packet trail visibility, and town-wide persisted lifecycle state.
- `moonbook`: owns domain identity, per-book memory policy, task-batch production, worker-context hydration, and intended durable result summarization/persistence.
- `moonclaw`: owns runtime metadata, external packet intake, proposal/run import mechanics, polling surfaces, and task/session execution substrate.
- `Mayor`: owns strategic routing, rationale generation, patrol packaging, and transformation of moonbook-derived context into keeper-facing/packet-ready form.
- `core`: owns cross-boundary contract vocabulary for isolation, memory scope, assignment plans, and execution records visible to the town control plane.
- `storage`: owns local persistence behavior for town snapshot state; packet export persistence is surfaced through adapter logic under `.moontown/packets`.

## Explicit uncertainty markers

Keep these markers intact during later source materialization.

- `UNCERTAIN: cross-repo-internals` — `../moonbook` and `../moonclaw` were not inspected in this worktree; any internal behavior claims about those repos are inherited unless separately materialized later.
- `UNCERTAIN: keeper-runtime-definition` — exact runtime definitions for keeper/worker role constructors are not confirmed here beyond docs and call-site evidence.
- `UNCERTAIN: packet-contract-stability` — packet structure looks like an inter-repo contract, but stability/versioning is not directly proven from both sides.
- `UNCERTAIN: result-closure` — the path from moonclaw poll results into moonbook durable persistence/review handling is only partially evidenced.
- `UNCERTAIN: isolation-enforcement-point` — typed isolation is visible, but enforcement at execution runtime is not directly observed.
- `UNCERTAIN: packet-retention-policy` — `.moontown/packets/` exists as optional export storage, but cleanup/retention/versioning policy is not resolved.
- `UNCERTAIN: supervisor-loop` — patrol architecture exists, but no direct proof of a durable long-running supervisor loop was captured here.

## Blockers

- `../moonbook` unavailable in this worktree; no direct source inspection of keeper internals, result persistence internals, or moonbook-owned lifecycle closure.
- `../moonclaw` unavailable in this worktree; no direct source inspection of packet import internals, runtime constructors, worker execution enforcement, or run-state storage internals.
- Parent workflow scope artifacts for intended multi-repo inclusion were only partially available, so some cross-repo scope assumptions remain inferred from local docs.
- Architecture docs explicitly note some intended behaviors are still stubbed, preventing stronger end-to-end proof for supervisor and result-closure paths.

## Ready-for-materialization notes

- Preserve evidence as architecture-boundary notes, not as repo overview.
- Carry provenance tags into any future extracted claims.
- Separate `direct`/`implementation-backed` facts from `inherited`/`unverified` hypotheses.
- Prefer citing the exact files listed in this packet when materializing architecture source notes.
- Do not expand this packet into docs-lane narrative or implementation-lane startup detail unless a later step explicitly widens the boundary.
