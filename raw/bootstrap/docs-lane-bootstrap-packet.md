# Docs-Lane Bootstrap Packet

This packet is prepared for downstream docs-lane use only. It reflects documentation inspection and synthesis for the docs lane, and it does not claim final ingest success, end-to-end validation, or broader workflow completion.

## Lane Purpose

- Capture a docs-lane-only bootstrap view of the local `moontown` repository.
- Record which documentation sources were actually inspected in this workspace.
- Preserve provenance, evidence, and candidate extraction in a form that downstream wiki/bootstrap steps can reuse.
- Surface open questions and blockers that limit confidence or broader ingest claims.

## Inspected Source List

- `README.mbt.md`
- `docs/ARCHITECTURE.md`
- `AGENTS.md`
- Prior step outputs embedded in this job run:
  - `step_1` missing-input notice for cross-repo scope (`moontown`, `moonbook`, `moonclaw`)
  - `step_2` docs evidence synthesis across `moontown`, `moonbook`, and `moonclaw`
  - `step_3` candidate extraction for entities, concepts, source pages, and ambiguities

## Provenance Notes

- This packet is grounded in direct inspection of local docs available in the current worktree for `moontown`.
- Cross-repo statements about `moonbook` and `moonclaw` come from prior step outputs supplied in the job context, not from fresh local inspection in this step.
- `step_1` explicitly recorded missing parent-workflow scope, repo-root guidance, and direct local access assumptions for `moontown`, `moonbook`, and `moonclaw`.
- No claim is made here that all intended upstream inputs were present.
- No claim is made here that any broader wiki ingest or multi-repo bootstrap completed successfully.

## Evidence Bullets

- `moontown` identifies itself as the town-level orchestration layer above multiple `moonbook` domains and multiple `moonclaw` runtimes. Evidence: `README.mbt.md:7`, `README.mbt.md:8`
- The documented role split keeps town orchestration in `moontown`, harness and memory control in `moonbook`, and execution-heavy behavior in `moonclaw`. Evidence: `README.mbt.md:136`, `README.mbt.md:137`, `README.mbt.md:138`
- The current repo status is explicitly partial: long-running polling, completion ingestion, automatic persistence back to `moonbook`, daemon patrol, experiment lifecycle execution, and backend/frontend sync remain stubbed. Evidence: `README.mbt.md:54`, `README.mbt.md:56`, `README.mbt.md:60`
- The runtime bootstrap path is documented as `moonbook catalog -> book task batch -> keeper packet -> MoonClaw proposal/run receipt -> town snapshot bootstrap -> dashboard / render model / frontend`. Evidence: `README.mbt.md:179`, `README.mbt.md:182`, `README.mbt.md:187`
- The repo exposes a scene/dashboard and Rabbita browser-facing simulation frontend with pause/resume/step controls, strategy switching, moving worker avatars, selection/inspector state, metrics, activity feed, and anomaly surfacing. Evidence: `README.mbt.md:76`, `README.mbt.md:77`, `README.mbt.md:83`
- `docs/ARCHITECTURE.md` is the local architecture source used to anchor subsystem and boundary interpretation for downstream docs-lane readers. Evidence: `docs/ARCHITECTURE.md:1`
- `AGENTS.md` confirms this is a MoonBit project and provides local project-structure/tooling guidance, which is useful provenance but not treated as product-behavior evidence. Evidence: `AGENTS.md:3`, `AGENTS.md:8`, `AGENTS.md:27`
- Prior step outputs indicate a coherent three-layer model across `moontown -> moonbook -> moonclaw`, but those cross-repo claims remain inherited evidence rather than newly revalidated in this step. Provenance: prior outputs `step_2`, `step_3`

## Source-Path Notes

- `README.mbt.md` functions as the primary top-level overview in this repo; downstream discovery should not assume `README.md` is the authoritative root narrative here.
- `docs/ARCHITECTURE.md` is present locally and should be treated as the main architecture-boundary companion to `README.mbt.md`.
- `raw/bootstrap/` did not exist before this step and is created here for packet staging.
- The packet file path is `raw/bootstrap/docs-lane-bootstrap-packet.md`.
- Cross-repo source paths cited in prior step outputs are not re-read in this step and should be treated as inherited references until independently re-opened.

## Entity Candidates

- `moontown` - town-level orchestration layer and control plane above multiple books and runtimes
- `moonbook` - book-local harness and durable memory/workspace layer, based on inherited prior-step evidence
- `moonclaw` - execution-heavy runtime substrate, based on inherited prior-step evidence
- `Mayor` - strategic town runtime / planner-only envelope inside the documented role model
- `keeper` - book-local planning/runtime handoff target in the documented role split
- `Rabbita` - named browser-facing simulation dashboard / operator UI surface
- `BookProvider` - provider abstraction used in town bootstrap
- `keeper packet` - handoff artifact in the documented runtime bootstrap path
- `ProposalImportReceipt` - receipt artifact named in the execution contract path
- `TaskExecutionRecord` - execution lifecycle record named in the current contract path

## Concept Candidates

- Town-level orchestration above domain-local and runtime-local layers
- Three-layer split: `moontown -> moonbook -> moonclaw`
- Control-plane-first prototype status rather than a fully live 24/7 runtime
- Keeper handoff packets as the bridge from planning to proposal/run lifecycle
- Scene-based operator visibility rather than a flat task-list interface
- External proposal/run receipt lifecycle and town-state tracking
- Clear boundary between orchestration, harness/memory ownership, and execution runtime ownership
- Partial implementation caveat as a core trust qualifier for current docs interpretation

## Source-Material Candidates

- `README.mbt.md` - top-level product identity, role split, current status, runtime flow, UI overview
- `docs/ARCHITECTURE.md` - architecture boundaries, subsystem relationships, and integration framing
- `AGENTS.md` - local project/tooling context for future maintainers and agents
- Prior `step_2` output - cross-repo docs evidence synthesis for `moontown`, `moonbook`, and `moonclaw`
- Prior `step_3` output - candidate extraction for entities, concepts, source pages, and ambiguities
- Prior `step_1` output - explicit record of missing scope-defining inputs and access assumptions

## Open Questions Or Blockers

- Parent-workflow outputs defining the intended docs-lane scope for `moontown`, `moonbook`, and `moonclaw` were missing in `step_1`, so cross-repo inclusion criteria remain partially inferred.
- Workspace notes or local guidance that define allowed repo roots or in-bounds paths for all three projects were missing in `step_1`.
- Fresh local inspection in this step covered only the current `moontown` worktree; cross-repo `moonbook` and `moonclaw` claims rely on inherited prior-step outputs.
- The current docs explicitly say important runtime pieces are still stubbed, so architectural intent is better supported than end-to-end operational success.
- It remains unclear whether downstream workflow expects a single combined packet for all repos or a repo-local packet per worktree.
- This packet does not establish final ingest success for any broader workflow, only a docs-lane-ready bootstrap artifact.

## Downstream Handling Note

- Treat this file as a staging packet for docs-lane downstream use.
- Revalidate inherited cross-repo references before promoting them into any final ingest, wiki, or canonical knowledge surface.
- If broader workflow inputs become available later, this packet should be updated rather than interpreted as final completion evidence.
