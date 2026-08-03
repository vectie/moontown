# Consolidated MoonBook Bootstrap Handoff

## Packet Metadata
- Job id: `job.proposal.20260417-151800-act-as-the-wiki-gather-usersk`
- Run id: `run-20260417-151814-usersk`
- Step id: `step_3`
- Packet purpose: merge the bounded `docs`, `implementation`, and `architecture` lane outputs into one ingestable raw handoff for MoonBook.
- Assembly basis: prior outputs from `step_1` and `step_2`, plus the repo-visible sources they cite.
- Boundaries: preserve raw provenance, keep claims bounded to cited docs/code, and do not infer concrete runtime artifacts for this specific job unless observed.
- Input mutation note: no existing raw gather inputs were edited or rewritten during assembly.

## Source Summaries

### docs lane
- `docs/USAGE.md:234` documents the keeper packet lifecycle as tracked town-state flow and names persisted lifecycle fields such as packet id, packet path, proposal id, run id, and execution status. This is descriptive documentation rather than direct runtime proof.
- `docs/ARCHITECTURE.md:140` describes bootstrap/runtime flow from MoonBook catalog through external proposal packet/import receipt to seeded `TownState`; `docs/ARCHITECTURE.md:167` assigns ownership across `adapters/moonbook`, `roles/mayor`, `adapters/moonclaw`, and `core`; `docs/ARCHITECTURE.md:197` lists persisted files including optional `.moontown/packets/`.
- `docs/PACKAGES.md:155` summarizes the MoonClaw adapter surface involved in packet file pathing, packet shaping, save/import operations, and run polling.
- `docs/DEVELOPMENT.md:100` is normative guidance that lifecycle wording for keeper packets and execution state should stay aligned across `README.mbt.md`, `docs/USAGE.md`, `docs/ARCHITECTURE.md`, and `docs/PACKAGES.md`.
- `README.mbt.md:129` and `README.mbt.md:177` restate the bootstrap path and package-boundary split at a higher level.

### implementation lane
- `roles/mayor.mbt:93` shows `Mayor::prepare_keeper_packet(...)` hydrating worker context, deriving a packet id of the form `keeper-<book_id>-<task_id>`, building the packet payload, and computing `packet_path`.
- `adapters/moonclaw/client.mbt:199` sets the default packet root to `.moontown/packets`; `adapters/moonclaw/client.mbt:204` materializes packet file paths as `.moontown/packets/<packet_id>.json` under defaults.
- `adapters/moonclaw/client.mbt:209` shapes `ExternalProposalPacket` from the MoonBook bundle and embeds metadata fields including `disable_waiting_for_input` and `best_effort_on_missing_input`.
- `adapters/moonclaw/client.mbt:260` writes packet files; `adapters/moonclaw/client.mbt:311` imports them and returns a `ProposalImportReceipt` with `packet_id`, `packet_path`, `proposal_id`, and optional `run_id`.
- `moontown.mbt:319` orchestrates prepare/import/poll/persist for keeper-packet execution.
- `core/types.mbt:188` defines the durable `TaskExecutionRecord` schema used to persist bounded packet/proposal/run fields.

### architecture lane
- `docs/ARCHITECTURE.md:169` assigns ownership boundaries: MoonBook hydrates context, mayor prepares keeper packets, MoonClaw shapes/imports packets and polls runs, and core owns durable execution records.
- `docs/ARCHITECTURE.md:197` identifies persisted artifact locations: `.moontown/moonbooks.json`, `.moontown/town.json`, and `.moontown/packets/`.
- `README.mbt.md:134` restates the same high-level split: orchestration in `moontown`, memory/context in `moonbook`, and execution in `moonclaw`.
- The architecture-layer flow is a high-level model and should be treated as inherited unless directly corroborated by cited implementation points.

## Evidence Bullets
- Documented lifecycle fields include keeper packet id, packet path, proposal id, run id, and execution status. Provenance: `docs/USAGE.md:236`. Claim status: documented/descriptive.
- Lifecycle records are described as living in `TownState.executions`, with durable schema evidence in `TaskExecutionRecord`. Provenance: `docs/USAGE.md:244`, `core/types.mbt:188`. Claim status: doc plus implemented.
- The documented lifecycle is `book task -> keeper packet -> imported proposal -> confirmed run -> persistence -> review`. Provenance: `docs/USAGE.md:256`. Claim status: partially implemented in this evidence slice because code here shows prepare/import/poll/persist, not a full review subsystem.
- Bootstrap/runtime flow is described as `worker context bundle -> external proposal packet -> proposal import receipt -> seeded TownState -> task execution records`. Provenance: `docs/ARCHITECTURE.md:144`. Claim status: architecture summary; inherited/high-level.
- Ownership split across `adapters/moonbook`, `roles/mayor`, `adapters/moonclaw`, and `core` is stated in architecture docs and corroborated by code locations. Provenance: `docs/ARCHITECTURE.md:169`, `roles/mayor.mbt:93`, `adapters/moonclaw/client.mbt:209`, `core/types.mbt:188`. Claim status: documented plus corroborated.
- Persisted artifact locations include `.moontown/moonbooks.json`, `.moontown/town.json`, and optional `.moontown/packets/`. Provenance: `docs/ARCHITECTURE.md:197`. Claim status: documented; packet directory remains optional and should not be overstated.
- MoonClaw adapter surface includes `packet_file_path(...)`, `proposal_packet_from_bundle(...)`, `save_packet_file(...)`, `import_packet(...)`, and `poll_run(...)`. Provenance: `docs/PACKAGES.md:166`. Claim status: documented and corroborated by implementation.
- Default packet directory is `.moontown/packets`. Provenance: `adapters/moonclaw/client.mbt:199`. Claim status: implemented.
- Packet file path resolves as `.moontown/packets/<packet_id>.json` under defaults. Provenance: `adapters/moonclaw/client.mbt:204`. Claim status: implemented.
- Mayor-generated packet ids use the shape `keeper-<book_id>-<task_id>`, yielding the derived default path `.moontown/packets/keeper-<book_id>-<task_id>.json`. Provenance: `roles/mayor.mbt:100`, `adapters/moonclaw/client.mbt:204`. Claim status: implemented for id shape, derived/inherited for the combined path in this run because no generated file is visible here.
- `Mayor::prepare_keeper_packet(...)` hydrates worker context from MoonBook and passes packet content, notes, tags, and computed `packet_path` downstream. Provenance: `roles/mayor.mbt:99`, `roles/mayor.mbt:102`, `roles/mayor.mbt:119`. Claim status: implemented; worker context contents remain inherited from MoonBook.
- `proposal_packet_from_bundle(...)` shapes `ExternalProposalPacket` with prompt, output contract, context pages, skill paths, and metadata. Provenance: `adapters/moonclaw/client.mbt:209`. Claim status: implemented.
- Packet metadata includes `disable_waiting_for_input=true` and `best_effort_on_missing_input=true` in both `profile_metadata` and `step_metadata`. Provenance: `adapters/moonclaw/client.mbt:236`, `adapters/moonclaw/client.mbt:242`. Claim status: implemented in code, but inherited relative to this job instance because no concrete packet artifact from this run is present.
- Packet files are written before import. Provenance: `adapters/moonclaw/client.mbt:260`, `adapters/moonclaw/client.mbt:322`. Claim status: implemented.
- `import_packet(...)` returns `ProposalImportReceipt` with packet/proposal/run tracking fields. Provenance: `adapters/moonclaw/client.mbt:311`. Claim status: implemented.
- Main orchestration prepares the packet, imports it, optionally polls the run, and persists a `TaskExecutionRecord`. Provenance: `moontown.mbt:319`, `moontown.mbt:341`. Claim status: implemented.
- Persisted execution records store `packet_id`, `packet_path`, `proposal_id`, `run_id`, `status`, `output_contract`, `context_pages`, and `skill_paths`. Provenance: `core/types.mbt:188`, `moontown.mbt:341`. Claim status: implemented.
- `README.mbt.md` restates that `moontown` produces keeper handoff packets and tracks packet/proposal/run lifecycle while MoonBook owns memory/context and MoonClaw owns execution. Provenance: `README.mbt.md:129`, `README.mbt.md:134`. Claim status: high-level/inherited summary.
- Doc alignment requirements for lifecycle wording are normative maintenance guidance, not runtime evidence. Provenance: `docs/DEVELOPMENT.md:109`. Claim status: normative.

## Candidate Pages To Update
- `raw/bootstrap/` intake pages or follow-on packets that need a consolidated source summary, packet path contract, persisted execution fields, and explicit note that no runtime packet instance for this job was observed.
- `README.mbt.md` because it carries the high-level bootstrap/runtime wording that must stay aligned with keeper-packet lifecycle docs. Provenance: `docs/DEVELOPMENT.md:109`.
- `docs/USAGE.md` because it contains lifecycle/status wording likely to need synchronization if bootstrap claims are normalized. Provenance: `docs/DEVELOPMENT.md:112`.
- `docs/ARCHITECTURE.md` because it defines ownership boundaries and persisted artifact locations used by this bootstrap extraction. Provenance: `docs/DEVELOPMENT.md:113`.
- `docs/PACKAGES.md` because it enumerates the MoonClaw adapter surface backing packet-path, save/import, and polling claims. Provenance: `docs/DEVELOPMENT.md:114`.
- Any future raw/bootstrap page covering persisted artifacts or execution receipts should preserve the documented qualifier that `.moontown/packets/` is optional. Provenance: `docs/ARCHITECTURE.md:203`.

## Source-Path Notes
- Packet directory contract comes from `adapters/moonclaw/client.mbt:199` and defaults to `.moontown/packets`.
- Packet file naming contract comes from `adapters/moonclaw/client.mbt:204` and resolves to `.moontown/packets/<packet_id>.json` under defaults.
- Mayor packet id generation comes from `roles/mayor.mbt:100`, so the derived default keeper path is `.moontown/packets/keeper-<book_id>-<task_id>.json`.
- Durable execution records keep the resolved packet path in `TaskExecutionRecord.packet_path`. Provenance: `core/types.mbt:191`, population at `moontown.mbt:345`.
- Persisted artifact inventory is documented in `docs/ARCHITECTURE.md:197`; `.moontown/packets/` is called out as optional at `docs/ARCHITECTURE.md:203`.
- No repo-local runtime artifact was found for `job.proposal.20260417-151800-act-as-the-wiki-gather-usersk`, `run-20260417-151814-usersk`, or `step_1`; path claims for this specific run therefore remain contract-derived rather than directly observed.

## Explicit Blockers Or Gaps
- No checked-in runtime packet, import receipt, or execution artifact for `job.proposal.20260417-151800-act-as-the-wiki-gather-usersk`, `run-20260417-151814-usersk`, or `step_1` is visible in this worktree. Impact: claims about this specific run's concrete packet contents or resolved packet file remain unobserved.
- No `.moontown/packets/` runtime artifacts are present in the repo-visible worktree. Impact: packet-path claims are bounded to documented and implemented contracts, not artifact observation.
- No separate lane-specific bounded gather manifests for `docs`, `implementation`, or `architecture` were found beyond the cited `step_1` and `step_2` outputs. Impact: consolidation relies on those prior bounded summaries plus cited repo sources.
- The documented lifecycle includes `review`, but the cited implementation slice only proves prepare/import/poll/persist. Impact: end-to-end review wording should remain marked partially implemented.
- Architecture ownership and flow statements are design-layer summaries. Impact: use them as inherited/high-level framing unless paired with cited implementation evidence.
- `disable_waiting_for_input` and `best_effort_on_missing_input` are code-proven defaults, but not verified in a generated packet file for this run. Impact: mark as inherited for this job instance.

## Claim-Handling Notes For MoonBook Ingest
- Treat code-backed path and schema claims as strongest when they point to `roles/mayor.mbt`, `adapters/moonclaw/client.mbt`, `moontown.mbt`, and `core/types.mbt`.
- Treat architecture and README restatements as high-level corroboration, not standalone proof of run-specific behavior.
- Treat `docs/DEVELOPMENT.md` guidance as normative maintenance metadata, not evidence that behavior occurred.
- Avoid converting optional packet-file persistence into an unconditional statement.
- Avoid stating that a concrete packet file or receipt was observed for this job/run/step unless a runtime artifact becomes visible in a later gather.
