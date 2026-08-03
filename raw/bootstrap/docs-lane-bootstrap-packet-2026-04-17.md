# Docs-Lane Bootstrap Packet: moontown / moonbook / moonclaw

- Lane: `docs`
- Job id: `job.proposal.20260417-200018-act-as-the-wiki-gather-usersk`
- Run id: `run-20260417-200034-usersk`
- Step id: `step_3_write_bootstrap_packet`
- Scope basis: bounded to the approved docs-lane slice from prior steps, centered on local product-facing markdown and architecture/workflow docs for `moontown`, `moonbook`, and `moonclaw`
- Lane stance: this packet is only a docs-lane handoff artifact for `raw/bootstrap/`; it supports later source materialization and knowledge revision, but it does not claim final ingest success, cross-lane completeness, or overall workspace readiness on its own

## What This Docs Lane Can Support

- Establish product-level topology and responsibility boundaries across `moontown`, `moonbook`, and `moonclaw`
- Capture documented workflow semantics for bootstrap, keeper packets, ingest phases, extension boundaries, and proposal import
- Identify high-confidence entity and concept candidates directly named in the inspected docs
- Preserve documented limits such as stubbed integrations, optional extensions, and architecture-vs-runtime uncertainty

## What Remains For Other Lanes Or Later Verification

- Implementation lane should verify whether the documented adapters, packet fields, commands, and ownership boundaries match current code paths
- Architecture lane should reconcile any terminology drift across repos and confirm whether the documented layering is still the preferred system model
- Later verification should confirm runtime truth for long-running polling, result persistence back into `moonbook`, extension-pack setup side effects, and actual operational preference of the MoonClaw workflow pack
- This lane does not prove that prior packets were ingested, that wiki pages are current, or that any downstream synthesis/review state is complete

## Source Packets

### 1. `moontown` product overview

- Source path: `README.mbt.md`
- Provenance:
  - Directly inspected in the current `moontown` worktree during this step
  - Repository README-style product overview for `moontown`
  - Product-facing source describing identity, capabilities, runtime flow, and documented status boundaries
- Evidence:
  - Describes `moontown` as the town-level orchestration layer above multiple `moonbook` domains and multiple `moonclaw` runtimes (`README.mbt.md:7`)
  - Frames the system as a town control plane with routing, scheduling, long-lived town state, scene dashboard, and browser-facing simulation UI (`README.mbt.md:3`, `README.mbt.md:12`, `README.mbt.md:15`, `README.mbt.md:17`)
  - Documents the handoff path from `moonbook` catalog and keeper packets into the MoonClaw proposal/run lifecycle (`README.mbt.md:22`, `README.mbt.md:25`)
  - States current real adapter boundaries for `adapters/moonbook` and `adapters/moonclaw` (`README.mbt.md:73`, `README.mbt.md:74`)
  - Splits ownership so orchestration stays in `moontown`, harness and memory control stay in `moonbook`, and execution-heavy behavior stays in `moonclaw` (`README.mbt.md:136`, `README.mbt.md:137`, `README.mbt.md:138`)
  - Gives runtime flow semantics from book task batch and keeper packet through proposal/run receipt into town snapshot and dashboard (`README.mbt.md:181`, `README.mbt.md:185`, `README.mbt.md:186`, `README.mbt.md:187`)
  - Marks key limits as still stubbed, including long-running polling and automatic result persistence back into `moonbook` (`README.mbt.md:54`, `README.mbt.md:56`, `README.mbt.md:57`)
- Source-path notes:
  - Strong source for current product framing and cross-project topology from the `moontown` side
  - Useful for capability boundaries because it distinguishes implemented vs stubbed behavior
  - Not sufficient on its own to prove live runtime behavior or downstream completion

### 2. `moontown` architecture doc

- Source path: `docs/ARCHITECTURE.md`
- Provenance:
  - Directly inspected in the current `moontown` worktree during this step
  - Repo-local architecture/topology document for `moontown`
  - Architecture-oriented source emphasizing layer ownership and packet lifecycle boundaries
- Evidence:
  - Defines the top-level stack as `moontown -> moonbook -> moonclaw` (`docs/ARCHITECTURE.md:3`, `docs/ARCHITECTURE.md:6`)
  - Assigns `moontown` to global orchestration, routing, health, scheduling, experiment control, UI, and town-wide persistence (`docs/ARCHITECTURE.md:13`, `docs/ARCHITECTURE.md:17`, `docs/ARCHITECTURE.md:23`)
  - Assigns `moonbook` to workspace root, durable memory, context hydration, local planning, and result review/persistence decisions (`docs/ARCHITECTURE.md:33`, `docs/ARCHITECTURE.md:37`, `docs/ARCHITECTURE.md:41`)
  - Assigns `moonclaw` to role-specialized runtimes, task execution, tools/skills, session state, and result packaging (`docs/ARCHITECTURE.md:48`, `docs/ARCHITECTURE.md:52`, `docs/ARCHITECTURE.md:58`)
  - States that `moontown` prepares real keeper proposal packets using book-harness-shaped context, while the actual keeper implementation belongs on the `moonbook` side (`docs/ARCHITECTURE.md:107`, `docs/ARCHITECTURE.md:109`)
  - Documents packet lifecycle ownership across `adapters/moonbook`, `roles/mayor`, `adapters/moonclaw`, and `core` (`docs/ARCHITECTURE.md:169`, `docs/ARCHITECTURE.md:171`, `docs/ARCHITECTURE.md:176`, `docs/ARCHITECTURE.md:179`, `docs/ARCHITECTURE.md:183`)
  - Distinguishes real now vs stubbed now, including MoonBook CLI-backed planning/context hydration and MoonClaw CLI-backed packet import as real, but run-status polling and automatic result persistence as stubbed (`docs/ARCHITECTURE.md:213`, `docs/ARCHITECTURE.md:219`, `docs/ARCHITECTURE.md:220`, `docs/ARCHITECTURE.md:227`, `docs/ARCHITECTURE.md:228`)
- Source-path notes:
  - Strongest local source in this worktree for explicit ownership boundaries and cross-project lifecycle semantics
  - Better for “who owns what” than for operator workflow detail
  - Should be reconciled later with MoonBook-side docs and implementation evidence before treating terminology as final

### 3. `moonbook` README

- Source path: `../../../../../../moonbook/README.md`
- Provenance:
  - Not re-opened from this isolated worktree in this step
  - Included from prior step evidence collection, which reported direct inspection of the local `moonbook` repository README in the approved docs slice
  - Treated here as prior-step carried evidence that should be re-verified later if a downstream lane requires fresh direct inspection from the current worktree context
- Evidence:
  - Defines MoonBook as an mdBook rewrite extended into a local wiki-maintainer workspace instead of stopping at static book generation (`../../../../../../moonbook/README.md:7`)
  - States the persistent maintained markdown wiki model where raw sources are not rediscovered from scratch at query time (`../../../../../../moonbook/README.md:9`)
  - Documents raw-first bootstrap staging under `raw/bootstrap/`, Keeper ingestion into durable wiki pages, and repo-owned static `SKILL.md` templates copied from `seed/` (`../../../../../../moonbook/README.md:11`, `../../../../../../moonbook/README.md:13`, `../../../../../../moonbook/README.md:15`)
  - Gives the top-level CLI split into `book`, `pack`, `skill`, `doctor`, and `wiki` (`../../../../../../moonbook/README.md:17`, `../../../../../../moonbook/README.md:19`, `../../../../../../moonbook/README.md:23`)
  - Describes `wiki ingest` as updating sources, entities, concepts, relationship sections, synthesis pages, maintenance plan, and review queue (`../../../../../../moonbook/README.md:96`, `../../../../../../moonbook/README.md:101`, `../../../../../../moonbook/README.md:104`, `../../../../../../moonbook/README.md:105`)
  - Names `moonclaw` as the first extension pack and notes that the deeper MoonClaw workflow pack still needs to become the preferred operational path rather than only an optional extension (`../../../../../../moonbook/README.md:130`, `../../../../../../moonbook/README.md:223`)
- Source-path notes:
  - Best carried source for MoonBook identity, raw/bootstrap semantics, and public-facing workflow framing
  - This packet relies on prior-step inspection notes for this file, so downstream materialization should preserve the provenance distinction between current-step direct reads and prior-step carried evidence
  - Strong for product framing, weaker than architecture docs for strict ownership boundaries

### 4. `moonbook` system architecture

- Source path: `../../../../../../moonbook/docs/SYSTEM_ARCHITECTURE.md`
- Provenance:
  - Not re-opened from this isolated worktree in this step
  - Included from prior step evidence collection, which reported direct inspection of the local `moonbook` architecture doc in the approved docs slice
  - Used here as carried architectural evidence pending later direct re-verification if needed
- Evidence:
  - Splits MoonBook into mdBook-compatible toolchain plus persistent wiki workspace layer (`../../../../../../moonbook/docs/SYSTEM_ARCHITECTURE.md:3`, `../../../../../../moonbook/docs/SYSTEM_ARCHITECTURE.md:5`, `../../../../../../moonbook/docs/SYSTEM_ARCHITECTURE.md:6`)
  - Defines the wiki workspace contract as file-based and agent-agnostic, including `raw/`, `keeper/`, `wiki/`, `wiki/SUMMARY.md`, `wiki/index.md`, `wiki/log.md`, `AGENTS.md`, and `wiki.toml` (`../../../../../../moonbook/docs/SYSTEM_ARCHITECTURE.md:89`, `../../../../../../moonbook/docs/SYSTEM_ARCHITECTURE.md:91`, `../../../../../../moonbook/docs/SYSTEM_ARCHITECTURE.md:95`, `../../../../../../moonbook/docs/SYSTEM_ARCHITECTURE.md:103`, `../../../../../../moonbook/docs/SYSTEM_ARCHITECTURE.md:109`)
  - States that runtime integration stays outside the core workspace contract, with `wiki init` creating an agent-agnostic workspace and `wiki enable <extension>` installing optional runtime-specific files (`../../../../../../moonbook/docs/SYSTEM_ARCHITECTURE.md:124`, `../../../../../../moonbook/docs/SYSTEM_ARCHITECTURE.md:126`, `../../../../../../moonbook/docs/SYSTEM_ARCHITECTURE.md:130`, `../../../../../../moonbook/docs/SYSTEM_ARCHITECTURE.md:131`)
  - Lists current extension packs as `moonclaw` and `moontown` (`../../../../../../moonbook/docs/SYSTEM_ARCHITECTURE.md:134`, `../../../../../../moonbook/docs/SYSTEM_ARCHITECTURE.md:136`, `../../../../../../moonbook/docs/SYSTEM_ARCHITECTURE.md:137`)
  - Says MoonBook exports a catalog-style book record and optional book-harness commands for `moontown`, but does not take over town scheduling or worker execution (`../../../../../../moonbook/docs/SYSTEM_ARCHITECTURE.md:139`, `../../../../../../moonbook/docs/SYSTEM_ARCHITECTURE.md:141`, `../../../../../../moonbook/docs/SYSTEM_ARCHITECTURE.md:143`)
  - States that runtime-specific orchestration and provider/model-specific logic should stay out of MoonBook core and belong in extension packs or external systems like MoonClaw and Moontown (`../../../../../../moonbook/docs/SYSTEM_ARCHITECTURE.md:158`, `../../../../../../moonbook/docs/SYSTEM_ARCHITECTURE.md:160`, `../../../../../../moonbook/docs/SYSTEM_ARCHITECTURE.md:164`)
- Source-path notes:
  - Strong carried source for MoonBook workspace contract, extension boundary, and explicit relation to both `moonclaw` and `moontown`
  - Important for lane-scoped materialization because it clarifies what belongs in core workspace semantics vs extension/runtime semantics
  - Still an architecture source, not direct proof of current operational state after extension enablement

### 5. `moonbook` wiki workflow

- Source path: `../../../../../../moonbook/docs/WIKI_WORKFLOW.md`
- Provenance:
  - Not re-opened from this isolated worktree in this step
  - Included from prior step evidence collection, which reported direct inspection of the local workflow doc in the approved docs slice
  - Used as carried workflow evidence for handoff
- Evidence:
  - Defines the goal of wiki mode as turning raw source files into a persistent markdown knowledge base instead of answering from raw docs each time (`../../../../../../moonbook/docs/WIKI_WORKFLOW.md:3`, `../../../../../../moonbook/docs/WIKI_WORKFLOW.md:7`)
  - Lists current command surface including `wiki init`, `enable`, `ingest`, `query`, `book`, `review`, and `lint` (`../../../../../../moonbook/docs/WIKI_WORKFLOW.md:9`, `../../../../../../moonbook/docs/WIKI_WORKFLOW.md:11`, `../../../../../../moonbook/docs/WIKI_WORKFLOW.md:17`)
  - Shows `wiki init` creating `raw/bootstrap/`, `keeper/`, synthesis pages, history pages, review files, and bounded Keeper memory files (`../../../../../../moonbook/docs/WIKI_WORKFLOW.md:27`, `../../../../../../moonbook/docs/WIKI_WORKFLOW.md:30`, `../../../../../../moonbook/docs/WIKI_WORKFLOW.md:42`, `../../../../../../moonbook/docs/WIKI_WORKFLOW.md:46`, `../../../../../../moonbook/docs/WIKI_WORKFLOW.md:50`)
  - States that `wiki enable moonclaw` and `wiki enable moontown` are optional and install runtime-specific files without changing the core workspace contract (`../../../../../../moonbook/docs/WIKI_WORKFLOW.md:52`, `../../../../../../moonbook/docs/WIKI_WORKFLOW.md:55`, `../../../../../../moonbook/docs/WIKI_WORKFLOW.md:56`, `../../../../../../moonbook/docs/WIKI_WORKFLOW.md:60`)
  - Defines ingest behavior including bootstrap staging under `raw/bootstrap/`, source page creation, entity/concept/synthesis updates, pending-review queuing, and index/log maintenance (`../../../../../../moonbook/docs/WIKI_WORKFLOW.md:68`, `../../../../../../moonbook/docs/WIKI_WORKFLOW.md:70`, `../../../../../../moonbook/docs/WIKI_WORKFLOW.md:72`, `../../../../../../moonbook/docs/WIKI_WORKFLOW.md:79`, `../../../../../../moonbook/docs/WIKI_WORKFLOW.md:81`)
  - Defines the town-facing book harness where MoonBook exports a catalog record, accepts town-style goals, hydrates worker context, persists results into synthesis/evidence/history, and reports state/health without requiring a town runtime (`../../../../../../moonbook/docs/WIKI_WORKFLOW.md:101`, `../../../../../../moonbook/docs/WIKI_WORKFLOW.md:103`, `../../../../../../moonbook/docs/WIKI_WORKFLOW.md:114`, `../../../../../../moonbook/docs/WIKI_WORKFLOW.md:117`, `../../../../../../moonbook/docs/WIKI_WORKFLOW.md:121`, `../../../../../../moonbook/docs/WIKI_WORKFLOW.md:129`)
- Source-path notes:
  - Strong carried source for operator workflow semantics and file/page effects
  - Useful for later source materialization because it spells out what ingest is supposed to change
  - Does not settle MoonClaw execution internals on its own

### 6. `moonbook` keeper call chain

- Source path: `../../../../../../moonbook/docs/KEEPER_CALL_CHAIN.md`
- Provenance:
  - Not re-opened from this isolated worktree in this step
  - Included from prior step evidence collection, which reported direct inspection of the local keeper handoff doc in the approved docs slice
  - Used as carried cross-project workflow evidence for this docs-lane packet
- Evidence:
  - States scope explicitly as the current workflow from `moonbook wiki ingest` packet emission to MoonClaw workflow execution, describing the code path that exists now rather than an idealized design (`../../../../../../moonbook/docs/KEEPER_CALL_CHAIN.md:3`, `../../../../../../moonbook/docs/KEEPER_CALL_CHAIN.md:8`, `../../../../../../moonbook/docs/KEEPER_CALL_CHAIN.md:12`)
  - Gives the high-level split where MoonBook ingests and emits a keeper packet, then shells out to MoonClaw proposal import, after which MoonClaw imports, profiles, compiles, executes, and delegates wiki edits/review (`../../../../../../moonbook/docs/KEEPER_CALL_CHAIN.md:32`, `../../../../../../moonbook/docs/KEEPER_CALL_CHAIN.md:34`, `../../../../../../moonbook/docs/KEEPER_CALL_CHAIN.md:35`, `../../../../../../moonbook/docs/KEEPER_CALL_CHAIN.md:38`, `../../../../../../moonbook/docs/KEEPER_CALL_CHAIN.md:41`)
  - States that MoonBook owns the semantic ingest graph with phases `bootstrap_gather`, `source_materialize`, `knowledge_revise`, and `review_finalize` (`../../../../../../moonbook/docs/KEEPER_CALL_CHAIN.md:43`, `../../../../../../moonbook/docs/KEEPER_CALL_CHAIN.md:45`, `../../../../../../moonbook/docs/KEEPER_CALL_CHAIN.md:48`)
  - States MoonClaw still compiles the semantic packet into the current executable workflow profile (`../../../../../../moonbook/docs/KEEPER_CALL_CHAIN.md:50`)
  - Documents packet fields including `semantic_phases`, `execution_mode`, `max_parallel_workers`, `gather_lanes`, `context_pages`, and `skill_paths` (`../../../../../../moonbook/docs/KEEPER_CALL_CHAIN.md:133`, `../../../../../../moonbook/docs/KEEPER_CALL_CHAIN.md:139`, `../../../../../../moonbook/docs/KEEPER_CALL_CHAIN.md:140`, `../../../../../../moonbook/docs/KEEPER_CALL_CHAIN.md:142`, `../../../../../../moonbook/docs/KEEPER_CALL_CHAIN.md:147`)
  - Defines semantic lane intent, including `bootstrap_gather` writing `raw/bootstrap/*` and gather lanes `docs`, `implementation`, and `architecture` under `parallel-lane-bootstrap` (`../../../../../../moonbook/docs/KEEPER_CALL_CHAIN.md:157`, `../../../../../../moonbook/docs/KEEPER_CALL_CHAIN.md:160`, `../../../../../../moonbook/docs/KEEPER_CALL_CHAIN.md:166`, `../../../../../../moonbook/docs/KEEPER_CALL_CHAIN.md:168`, `../../../../../../moonbook/docs/KEEPER_CALL_CHAIN.md:171`, `../../../../../../moonbook/docs/KEEPER_CALL_CHAIN.md:173`, `../../../../../../moonbook/docs/KEEPER_CALL_CHAIN.md:175`)
- Source-path notes:
  - Highest-value carried source for explaining why a docs-lane bootstrap packet exists and what downstream phases should do with it
  - Strong for semantic-owner vs execution-compiler separation between MoonBook and MoonClaw
  - Needs implementation-lane confirmation if exact packet fields or phase semantics are relied on operationally

### 7. `moonclaw` product overview

- Source path: `../../../../../../moonclaw/README.mbt.md`
- Provenance:
  - Not re-opened from this isolated worktree in this step
  - Included from prior step evidence collection, which reported direct inspection of the local `moonclaw` README in the approved docs slice
  - Used as carried product/runtime evidence
- Evidence:
  - Defines MoonClaw as an agent and automation system built as a full job runtime instead of a thin chat wrapper (`../../../../../../moonclaw/README.mbt.md:7`)
  - Frames the product around proposal drafting, workflow compilation, job execution, and persistence of artifacts, memory, and workspace state (`../../../../../../moonclaw/README.mbt.md:21`, `../../../../../../moonclaw/README.mbt.md:23`, `../../../../../../moonclaw/README.mbt.md:26`)
  - Lists external proposal packet import into the normal proposal lifecycle as a current capability (`../../../../../../moonclaw/README.mbt.md:80`)
  - Says imported external packets are validated, converted into stored proposals, mapped onto configured job profiles, and can confirm/execute through the standard workflow engine (`../../../../../../moonclaw/README.mbt.md:41`)
  - Documents CLI examples for `proposal import keeper/jobs/ingest-001.json --home ~/.moonclaw` and `--confirm` (`../../../../../../moonclaw/README.mbt.md:161`, `../../../../../../moonclaw/README.mbt.md:176`)
  - States `--home ~/.moonclaw` stores runtime state such as jobs, runs, memories, and gateway data (`../../../../../../moonclaw/README.mbt.md:179`, `../../../../../../moonclaw/README.mbt.md:181`)
- Source-path notes:
  - Strong carried corroboration for MoonClaw’s role as the proposal-import and execution runtime in the cross-project chain
  - Useful for downstream source pages about runtime identity and operator-facing CLI surfaces
  - This inspected slice does not directly establish a `moontown`-specific contract from the MoonClaw side

## Cross-Source Synthesis Candidates

- Cross-project topology candidate:
  - `moontown` sits above `moonbook`, which sits above `moonclaw`, with orchestration, harness/memory, and execution/runtime responsibilities split across those layers
- Handoff semantics candidate:
  - `moonbook` owns semantic ingest and bootstrap packet intent, `moonclaw` owns executable workflow compilation/execution, and `moontown` can consume book-harness surfaces and hand work into the proposal/run lifecycle
- Workspace-boundary candidate:
  - MoonBook core workspace is agent-agnostic; `moonclaw` and `moontown` appear as optional extension packs rather than core assumptions
- Operational-limits candidate:
  - Several docs consistently distinguish real now vs stubbed now, especially around long-running polling and automatic persistence back into MoonBook

## Entity Candidates

- `moontown`
- `moonbook`
- `moonclaw`
- `Mayor`
- `keeper`
- `BookProvider`
- `ExternalProposalPacket`
- `ProposalImportReceipt`
- `TaskExecutionRecord`
- `TownState`
- `TownSnapshot`
- `WorkerContextBundle`
- `Rabbita`
- `MoonBook CLI`
- `MoonClaw CLI`

## Concept Candidates

- town control plane
- three-layer topology
- town-wide orchestration
- per-domain harness layer
- agent substrate
- book-harness boundary
- keeper packet
- external proposal packet import
- proposal/run lifecycle
- semantic ingest graph
- `bootstrap_gather`
- `source_materialize`
- `knowledge_revise`
- `review_finalize`
- `parallel-lane-bootstrap`
- gather lanes
- agent-agnostic workspace contract
- extension pack
- raw-first bootstrap staging
- durable wiki maintenance
- real-vs-stubbed integration boundary

## Open Questions

- Does current implementation still match the exact packet fields and phase names documented in `../../../../../../moonbook/docs/KEEPER_CALL_CHAIN.md`, or have they drifted since that doc was written?
- Are `wiki enable moonclaw` and `wiki enable moontown` still the recommended operational setup, or have extension-pack assumptions changed in current practice?
- Is the statement that the deeper MoonClaw workflow pack is not yet the preferred operational path still accurate, or has later work made it the default route?
- Do the `moontown` docs and the MoonBook docs still agree on which side owns keeper implementation details versus packet preparation details?
- Are long-running run-status polling and automatic persistence back into `moonbook` still stubbed in practice, or partially implemented elsewhere?
- Should downstream source materialization treat `keeper` as an entity page, a role concept, or both?
- Are `TownSnapshot` and `TaskExecutionRecord` stable product-facing terms, or mainly code-facing names that should remain lower priority in wiki surfacing?

## Source-Path And Provenance Caveats

- This packet mixes two provenance classes:
  - current-step direct reads from the local `moontown` worktree: `README.mbt.md`, `docs/ARCHITECTURE.md`
  - prior-step carried evidence for approved local docs in sibling repos: `../../../../../../moonbook/README.md`, `../../../../../../moonbook/docs/SYSTEM_ARCHITECTURE.md`, `../../../../../../moonbook/docs/WIKI_WORKFLOW.md`, `../../../../../../moonbook/docs/KEEPER_CALL_CHAIN.md`, `../../../../../../moonclaw/README.mbt.md`
- That mixed provenance is acceptable for a bootstrap handoff packet, but downstream lanes should preserve the distinction and re-verify carried sources if they need fresh direct inspection from their own execution context
- I found no directly accessible local copies in this step of the previously named artifacts `raw/bootstrap/moontown-moonbook-moonclaw-bootstrap-2026-04-17.md` or `wiki/sources/moontown-moonbook-moonbook-claw-topology.md`; this packet therefore does not rely on them as primary evidence
- This docs lane intentionally avoids claiming final ingest success, final synthesis correctness, or overall readiness beyond the documented source packet prepared here
