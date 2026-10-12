# Run a captured collaboration once

The collaboration composer can now turn its existing prepared plan into actual participant work. The old composer-only portable `.tar` export is unchanged. Saving, preparing, reusing and downloading a plan never starts work.

## Operator journey

1. Open Collaboration, load existing Books, capture exact source paths and prepare the saved revision. Inspect its question, participant assignments, named reviewer and independently owned objection.
2. Choose **Run participants once**. Town freezes each brief, source and one-off skill into its own isolated workspace. It also freezes the existing configured runtime profile and includes exact source payloads in the request. No participant Book workspace/catalog is repaired or materialized by Town. Town calls no civic installer, daemon, recurring schedule or automatic Book result writer. The configured runtime retains its existing worker role, workspace scope and tool/Fort authority.
3. Inspect each actual run ID, returned contribution or failure. **Resume / reconcile same work** uses the same source-bound producer key and run. **Collect / reconcile work status** polls status and may write newly collected results and initial review history into immutable Town retention. For strictly read-only historical inspection and exact dossier downloads, use the [retained outcome library](RETAINED_OUTCOME_LIBRARY.md). A partial result clearly retains failures. A failed, cancelled or uncertain running participant is never silently replayed. A changed source/question creates a new saved revision and distinct runs.
4. Review the collected result. This first slice assembles attributed actual outputs and failures; it does not claim a model-written synthesis or invent consensus. Each decision uses the existing host operator account and must match the named owner. Approve, reject and defer retain the rationale and all earlier decision versions. The objection owner is independent. The prepared plan never acquires a result decision.
5. After every participant is terminal and every named-owner decision approves the accurate result account, choose a destination Book and author the outcome interpretation and three gap statements. A partially failed dossier is eligible learning evidence: success/failure counts and each failure remain explicit, and approving the account never labels the collaboration successful. Running/unknown/unreviewed/rejected/deferred results remain blocked. Severity 0 requires an explicit absence explanation; a present gap requires a proposed capability descriptor. Choose **Send retained outcome to chosen Book**. Book's existing receiver owns deliverable and Three-Gap review. A duplicate submission retries the same retained bytes, even if its first reply was interrupted.
6. Use Book's existing review UI. Back in Town, **Read Book disposition and reopen exact outcome** invokes the existing read-only receiver and verifies the returned package against this exact collaboration's captured sources, produced outputs and retained Chat review. A receipt is an unsigned historical local observation, never activation authority. Earlier source revisions and dissent remain reopenable.

## Host setup

The host owns all paths and runtime settings; a browser payload supplies none of them.

Set `MOONTOWN_COLLABORATION_RUNTIME_JSON` to an existing local JSON file containing:

```json
{"moonclaw_root":"/absolute/moonclaw/source-or-install","home":"/existing/moonsuite/home","profile":"existing-profile-name","profile_config_path":"/existing/workspace/moonclaw.jobs.json"}
```

`profile_config_path` names the existing job-profile file; when omitted, it defaults to `home/moonclaw.jobs.json`. Town freezes this declarative profile file into each participant workspace because Claw's existing profile loader is workspace-scoped. `home` remains the existing provider/config home. The existing model loader reads `home/.moonsuite/products/moonclaw/moonclaw.json`, `models/models.json`, and `providers.json` through the existing MoonSuite path resolver. Existing provider credentials and MoonGate connections are reused in place and are not copied into Town, the participant input packet or Book evidence. A separate provider instance, credential setup or analysis-only profile is not required. Configured tool, role, timeout and retry policies remain the runtime's own. `MOONTOWN_MOONCLAW_BIN` may select the installed Claw executable, following the existing adapter behavior. Otherwise the existing source-run path is used. The host launches one background CLI process per participant and returns promptly, so refresh/reopen can observe status without waiting for completion.

The Claw executable must support `proposal oneoff <packet> --json --home <existing-config-home> --cwd <captured-workspace> --store-home <Town-owned-private-state>`. Town derives the private state directory from the saved revision; the browser cannot choose it. Only job/proposal/run state is isolated, so the resident gateway's existing maps and stores are not touched. These runs are inspected in Town's one-off panel, not automatically listed in the resident gateway Jobs UI. The captured workspace constructor ignores `agents.defaults.workspace`, so existing user workspace defaults cannot redirect the frozen participant inputs.

The opt-in command records the exact packet/profile/workspace binding, stable proposal/run identities and an unstarted run before execution. Ordinary `proposal import` and `--home` behavior are unchanged. Participants execute sequentially per private job store because the pinned legacy store has nonblocking cross-process write locks. Before any intent or profile copy is committed, Town validates the selected profile against the same captured bytes. Missing/malformed initial setup can be fixed and retried on the same prepared question. After a valid profile is frozen and work is launched, retry never substitutes different profile bytes; changed profile inputs require a new source/question revision. A prepared `Pending` run resumes once; a `Running` outcome after a crash stays uncertain rather than being replayed. A runtime failure/cancellation requires a new source revision for new work. Pre-index CLI errors appear as bounded stdout/stderr diagnostics, with uncertainty preserved.

Named decisions reuse the existing `public_identity` operator service and active operator account ID. A localhost request, the reviewer display name, or a typed reviewer ID is not authenticated identity. If the existing identity service is not available, results remain inspectable and pending. This change installs no identity service and introduces no new approval gate.

Set `MOONTOWN_BOOK_OUTCOME_BIN` to the existing MoonBook `cmd/outcome_lessons` executable. Destination roots are resolved from the existing Book catalog and bound on the first submission. Town calls only `product-import` and `product-read`; it never automatically calls `product-continue`, writes Book review authority or activates capabilities.

## Retention and limits

- Draft/source snapshots and the composer archive remain byte-identical after execution
- Per-participant returned `report.md` and `result.json` are read from the production Claw run index/workspace, verified, and retained under the owning source revision
- Contributions must be exact nonempty UTF-8 text; no lossy decoding or invented fallback output. Each source/output file is bounded to 1 MiB
- Original binary inputs are retained in the Book evidence dossier as hex with their original byte digests. No binary source is silently omitted or decoded as text
- Book's existing 8 MiB payload limit applies. Oversize packages are refused before submission
- Fully terminal partial/failure dossiers can be submitted after all named owners approve their accurate account; failures and their counts are retained through Book readback
- Prior decision versions are immutable. The first slice allows at most 100 decision revisions per produced result
- Real provider quality, real-human authentication, live browser behavior, installed applications and production workflow acceptance require separate qualification

## Implementation boundary

Town owns the immutable work intent, participant packets, retained results, source-bound Chat settlement and product outcome envelope. The lower MoonClaw adapter is used for execution/status; no call reaches `bootstrap_civic_communication_scenario_file`, its installer or its inner workspace materializer. MoonChat remains an embedded review contract. MoonBook's canonical product-outcome receiver is unchanged.

`cmd/oneoff_fixture` in the Claw integration tree is a verification-only deterministic local AnalysisExecutor. It reads actual frozen inputs and exercises production proposal/workflow/artifact persistence. It has no external model, provider account or agent dispatch. Fixture reviewer IDs are synthetic test contexts, not authenticated real humans.
