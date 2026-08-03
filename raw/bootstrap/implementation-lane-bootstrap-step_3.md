# Implementation-Lane Bootstrap Packet

## Packet Status
- Packet type: implementation-lane bootstrap artifact
- Step id: `step_3_write_impl_packet`
- Job id: `job.proposal.20260417-200752-act-as-the-wiki-gather-usersk`
- Run id: `run-20260417-200810-usersk`
- Readiness: handoff-ready for later source materialization
- Constraint: contributes only this lane's implementation findings; no docs-lane or topology-only claims are promoted here unless explicitly marked as carried-forward context
- Source basis: direct inspection findings are carried from step outputs for the scoped implementation slice; this packet does not add new repository inspection beyond confirming the destination path was absent and needed creation

## Lane Scope
- Focus: runtime handoff path for `moontown` and the directly adjacent adapter/package surfaces that explain how `moonbook` and `moonclaw` are invoked
- In-scope source families:
  - repo/module manifests and package wiring
  - CLI entrypoint and top-level orchestration
  - mayor orchestration and keeper packet preparation
  - `moonbook` adapter CLI/workspace/catalog surfaces
  - `moonclaw` adapter packet/import/run/polling surfaces
  - subprocess integration substrate used by both adapters
- Explicitly out of scope for durable claims in this packet:
  - narrative docs under `docs/`
  - UI/frontend surfaces under `ui/`
  - unrelated scheduler/health/dispatch internals except where surfaced through `roles/mayor.mbt`
  - external repo internals for `../moonbook` and `../moonclaw`
  - provider-registry or extension implementation details not directly visible in the inspected code

## Inspected Source Paths

### Directly inspected in prior implementation-lane steps
- `AGENTS.md`
- `moon.mod.json`
- `moon.pkg`
- `cmd/main/moon.pkg`
- `cmd/main/main.mbt`
- `goal_run.mbt`
- `moontown.mbt`
- `roles/moon.pkg`
- `roles/mayor.mbt`
- `adapters/moonbook/moon.pkg`
- `adapters/moonbook/client.mbt`
- `adapters/moonclaw/moon.pkg`
- `adapters/moonclaw/client.mbt`
- `integration/moon.pkg`
- `integration/command.mbt`

### Directly inspected in this step
- workspace root listing only, to determine whether `raw/bootstrap/` already existed before writing this packet

### Not directly inspected here; referenced only as external invocation targets or unresolved boundaries
- `../moonbook` command surfaces invoked by `moon -C ../moonbook run cmd/main -- ...`
- `../moonclaw` command surfaces invoked by `moon -C ../moonclaw run cmd/main -- ...`
- `.moonclaw/jobs/index/runs.json` and workspace-local result files as runtime data surfaces mentioned by inspected code, not source-inspected artifacts in this lane packet

## Provenance Notes
- Direct inspection provenance in this packet is inherited from prior implementation-lane collection steps and should be treated as source-backed within the scoped file list above.
- Carried-forward context is included only when needed to preserve handoff continuity from earlier step outputs; such context is explicitly labeled and should not be upgraded to a durable claim without source materialization.
- This packet distinguishes:
  - direct inspection = claims tied to concrete file paths and line-cited observations from the scoped implementation slice
  - carried-forward context = workflow framing, scope rationale, or unresolved topology hints coming from prior step outputs rather than fresh code reads in this step
- Later source materialization should re-open the cited files and capture exact excerpts for any claim chosen for publication.

## Evidence Bullets Grouped By Source

### `moon.mod.json`
- Direct inspection: module identity is `vectie/moontown`, and preferred target is `native`, establishing that the inspected code belongs to the main `moontown` runtime module.

### `moon.pkg`
- Direct inspection: root package wiring imports `vectie/moontown/adapters/moonbook`, `vectie/moontown/adapters/moonclaw`, `vectie/moontown/integration`, and `vectie/moontown/roles`, placing those packages in the live module graph.

### `cmd/main/moon.pkg`
- Direct inspection: the CLI package imports `vectie/moontown` and sets `options("is-main": true)`, marking `cmd/main` as the executable main-entry surface.

### `cmd/main/main.mbt`
- Direct inspection: `main` dispatches `run` commands to `@moontown.render_goal_run(...)` with optional `--book`, otherwise falling back to `@moontown.load_or_create_demo_dashboard()`.

### `roles/moon.pkg`
- Direct inspection: the `roles` package imports both `vectie/moontown/adapters/moonbook` and `vectie/moontown/adapters/moonclaw`, positioning role orchestration between semantic context prep and proposal execution.

### `roles/mayor.mbt`
- Direct inspection: `Mayor::decide_dispatch` delegates routing to `@dispatch.route_task(...)` and emits an output contract from runtime metadata with fallback `mayor.dispatch.packet.v1`.
- Direct inspection: `Mayor::prepare_keeper_packet` hydrates worker context via `@moonbook.hydrate_worker_context(...)` and converts it into a MoonClaw packet via `@moonclaw.proposal_packet_from_bundle(...)`.
- Direct inspection: task kinds are mapped to hard-wired MoonClaw profiles such as `wiki_ingest_controller`, `wiki_lint_controller`, and `wiki_query_controller`.
- Direct inspection: the mayor-to-keeper handoff includes explicit constraints such as `follow packet-first handoff` and `keep book memory isolated`.

### `adapters/moonbook/moon.pkg`
- Direct inspection: the MoonBook adapter depends on `vectie/moontown/integration` plus filesystem/json/path support, but not on MoonClaw directly.

### `adapters/moonbook/client.mbt`
- Direct inspection: `MoonbookCatalogProvider` implements `@core.BookProvider`, and provider loading returns that implementation from catalog-backed state.
- Direct inspection: default books include `coding` and `finance`; workspaces live under `.moontown/books/<book_id>` and catalog state persists at `.moontown/moonbooks.json`.
- Direct inspection: semantic book operations `accept_goal`, `produce_task_batch`, `hydrate_worker_context`, `persist_result`, and `summarize_state` all shell through MoonBook `wiki book ...` JSON commands.
- Direct inspection: `ensure_workspace(...)` checks for `wiki/index.md`, runs `wiki init` if needed, and expects both the wiki marker and `moonclaw.jobs.json` before treating the workspace as already initialized.
- Direct inspection: extension enablement is explicit via `moon run cmd/main -- wiki enable moonclaw <root>` in the external MoonBook repo.
- Direct inspection: `build_workspace(...)` shells to MoonBook `build <root>` and returns `book/site/generated/index.html`, placing rendered-site generation on the MoonBook side.

### `adapters/moonclaw/moon.pkg`
- Direct inspection: the MoonClaw adapter depends on both `vectie/moontown/adapters/moonbook` and `vectie/moontown/integration`, indicating it consumes MoonBook-produced context and uses subprocess execution.

### `adapters/moonclaw/client.mbt`
- Direct inspection: `EmbeddedMoonclawRuntime` models role, planning layer, runtime mode, tool access, memory scope, visible tools, skills, and optional output contract.
- Direct inspection: `proposal_packet_from_bundle(...)` transforms a MoonBook `WorkerContextBundle` into an `ExternalProposalPacket` carrying request text, profile, context pages, skills, output contract, and metadata including `producer: "moontown"`, `book_id`, `workspace_root`, and `task_id`.
- Direct inspection: packet metadata also includes step/profile metadata such as `disable_waiting_for_input: true` and `best_effort_on_missing_input: true`.
- Direct inspection: `build_import_command(...)` emits `proposal import`, and `build_run_command(...)` emits `proposal run`.
- Direct inspection: MoonClaw home defaults to `.moonclaw`.
- Direct inspection: `import_packet(...)` writes a packet file and shells to `moon -C ../moonclaw run cmd/main -- proposal import <packet> --json --cwd <cwd> --home <home> [--confirm]`, then parses `proposal_id` and optional `run_id`.
- Direct inspection: `run_confirmed_run(...)` shells to `moon -C ../moonclaw run cmd/main -- proposal run <run_id> --cwd <cwd> --home <home>`.
- Direct inspection: `poll_run(...)` reads `.moonclaw/jobs/index/runs.json` plus `<workspace>/result.json` to derive status/review/notify state rather than using an in-process runtime API.

### `goal_run.mbt`
- Direct inspection: `run_goal(...)` loads the MoonBook catalog, selects books, registers them into town state, iterates each through `run_goal_for_book(...)`, and saves a snapshot.
- Direct inspection: for each book, Moontown calls MoonBook first for `accept_goal(...)`, `summarize_state(...)`, and `produce_task_batch(...)` before MoonClaw execution is invoked.
- Direct inspection: when coverage is weak, Moontown injects an `ingest` task instructing discovery, source ingest into the book boundary, raw evidence population, and revision of maintained wiki pages.
- Direct inspection: `execute_goal_book_task(...)` asks the mayor to prepare a keeper packet, resolves the workspace root, and calls `@moonclaw.import_packet(...)` with `confirm=true`.
- Direct inspection: if MoonClaw returns a `run_id`, Moontown polls via `@moonclaw.poll_run(...)` and may invoke `@moonclaw.run_confirmed_run(...)` until terminal state.
- Direct inspection: after execution, Moontown converts execution output into a `@moonbook.BookResult` and calls `@moonbook.persist_result(...)`.
- Direct inspection: final post-execution steps include MoonBook `build_workspace(...)` and `summarize_state(...)`.

### `moontown.mbt`
- Direct inspection: `live_execution_record_for_book_task(...)` repeats the same core boundary in the live/dashboard path by preparing a packet, importing it into MoonClaw, and optionally launching `proposal run` against the workspace root.
- Direct inspection: `build_live_state_from_catalog(...)` gets tasks from MoonBook via `produce_task_batch(...)` and executes them through `live_execution_record_for_book_task(...)`.
- Direct inspection: `snapshot_requires_refresh(...)` treats summaries like `Synthetic lifecycle`, `metadata must be object`, and `Unknown external proposal profile` as refresh triggers, revealing defensive handling for synthetic or mismatched external runtime state.

### `integration/moon.pkg`
- Direct inspection: package wiring confirms the integration layer is the shared substrate used by adapter command execution.

### `integration/command.mbt`
- Direct inspection: the integration layer exposes `run`, `run_checked`, and `run_json`, confirming CLI subprocess execution rather than direct in-process library linkage.
- Direct inspection: `run_json(...)` and `parse_json_stdout(...)` expect JSON on stdout and attempt recovery from noisy output by scanning trailing lines for JSON.

### `AGENTS.md`
- Carried-forward context from scoped inspection: used only as repo-level guardrails for module/package layout assumptions during source selection; no implementation claim in this packet depends materially on AGENTS content.

## Candidate Durable Claims
- `moontown` runtime entry starts at `cmd/main/main.mbt` and hands `run` invocations into top-level orchestration in `moontown`, not directly into adapter code.
- The live runtime path is package-wired through `moonbook`, `moonclaw`, `roles`, and `integration`, all of which are part of the root module graph.
- `Mayor::prepare_keeper_packet` is the key implementation boundary where MoonBook-provided worker context is transformed into a MoonClaw proposal packet.
- Moontown assigns MoonClaw execution profiles by task kind, with concrete mappings for ingest, review/planning, and analysis/synthesis tasks.
- MoonBook owns semantic book-side operations in the inspected path: goal acceptance, task batch production, worker-context hydration, result persistence, summary generation, workspace init, and site build.
- MoonClaw owns proposal-packet import/run execution in the inspected path, with explicit CLI surfaces for `proposal import` and `proposal run` and a default runtime home at `.moonclaw`.
- The inspected integration between projects is subprocess/CLI based, not an in-process library call path.
- Moontown returns execution results to MoonBook for durable book persistence and post-run build/summary generation.
- Polling in the inspected code is file/index-backed through `.moonclaw/jobs/index/runs.json` and workspace result files, which is a narrower and more concrete claim than any broader runtime-API narrative.
- Moontown stamps outbound MoonClaw proposal packets with its own orchestration metadata, including `producer: "moontown"` and non-interactive/best-effort execution flags.

## Entity Candidates
- `vectie/moontown`
- `moontown`
- `moonbook`
- `moonclaw`
- `MoonbookCatalogProvider`
- `@core.BookProvider`
- `Mayor`
- `EmbeddedMoonclawRuntime`
- `WorkerContextBundle`
- `ExternalProposalPacket`
- `BookResult`
- `cmd/main`
- `.moontown/moonbooks.json`
- `.moontown/books/<book_id>`
- `.moonclaw`
- `.moonclaw/jobs/index/runs.json`
- `moonclaw.jobs.json`

## Concept Candidates
- runtime handoff path
- packet-first handoff
- keeper packet preparation
- semantic context hydration
- proposal packet transformation
- profile selection by task kind
- MoonBook workspace initialization
- MoonBook extension enablement
- CLI subprocess adapter boundary
- proposal import
- proposal run confirmation
- file-backed run polling
- result persistence back into book state
- post-execution site build
- isolated book memory
- output contract propagation
- non-interactive best-effort execution metadata

## Cross-Project Linkage Notes
- Direct inspection: Moontown invokes MoonBook through external CLI commands shaped as `moon -C ../moonbook run cmd/main -- wiki ...` rather than through embedded imports from the MoonBook repo.
- Direct inspection: Moontown invokes MoonClaw through external CLI commands shaped as `moon -C ../moonclaw run cmd/main -- proposal ...`.
- Direct inspection: the implementation boundary is asymmetric by responsibility: MoonBook provides semantic/book state operations; MoonClaw provides proposal import/run execution; Moontown orchestrates between them.
- Direct inspection: roles-level code ties the two adapters together by taking MoonBook-generated worker context and converting it into MoonClaw proposal packets.
- Direct inspection: the inspected code proves enablement invocation for `moonbook wiki enable moonclaw`, but not the internal mechanics of that enablement inside the external MoonBook project.
- Carried-forward context: prior scoping explicitly warned against inferring MoonClaw provider-registry schema or MoonBook extension internals from these adapter calls alone.

## Unresolved Questions
- What exact schema does `moonclaw.jobs.json` carry, and is it generated by MoonBook extension enablement, MoonClaw import, or both?
- What is the concrete schema and lifecycle of `.moonclaw/jobs/index/runs.json`, beyond the fields consumed by `poll_run(...)`?
- Under what circumstances does MoonClaw return `run_id` during import versus requiring a later explicit `proposal run` call?
- What exact packet fields are mandatory versus optional in the external `proposal import` surface, beyond the fields populated by `proposal_packet_from_bundle(...)`?
- How does `moonbook wiki enable moonclaw` alter workspace state internally, and which files besides `moonclaw.jobs.json` does it provision?
- What provider-selection or registry behavior exists inside external MoonClaw home state under `.moonclaw`, if any?
- Are there additional task kinds or profile mappings elsewhere in the codebase that were intentionally excluded from this scoped slice?
- How stable are the synthetic/error snapshot markers used by `snapshot_requires_refresh(...)`, and are they contractually defined anywhere else?

## Handoff Notes For Later Source Materialization
- Re-materialize claims from source before publication by reopening the cited files and extracting exact line-anchored excerpts.
- Preserve the direct-inspection versus carried-forward distinction when converting this packet into downstream wiki/source artifacts.
- Treat external repo behavior as unresolved unless later inspection includes source from `../moonbook` or `../moonclaw`.
- Do not widen current claims about provider registries, extension internals, or richer runtime APIs beyond the subprocess commands and file surfaces already evidenced here.
- If a later packet merges topology and implementation lanes, keep this packet's contribution scoped to concrete implementation wiring and adapter boundaries only.
