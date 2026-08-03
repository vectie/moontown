# Implementation-Lane Bootstrap Packet

## Lane Label
- `implementation-lane: runtime-entry-and-packet-handoff`

## Scope
- Narrow scope only: the runtime entry, orchestration loop, and packet/handoff wiring that connect `moontown`, `moonbook`, and `moonclaw`.
- In scope: manifest anchor, CLI dispatch, Moontown goal-run/bootstrap flow, Moonbook command delegation, MoonClaw packet import/polling, and mayor-to-keeper handoff construction.
- Out of scope: whole-system architecture summaries, UI surfaces, docs synthesis, unrelated packages, and internals of sibling repos not directly evidenced from inspected source.

## Inspected Source List
- `moon.mod.json`
- `cmd/main/main.mbt`
- `moontown.mbt`
- `goal_run.mbt`
- `adapters/moonbook/client.mbt`
- `adapters/moonclaw/client.mbt`
- `roles/mayor.mbt`

## Provenance Notes
- Packet assembled from the bounded implementation slice confirmed in prior lane-selection work for job `job.proposal.20260417-193133-act-as-the-wiki-gather-usersk` / run `run-20260417-193149-usersk` / step `step_4_write_bootstrap_packet`.
- Evidence is restricted to direct file/line anchors already inspected in the implementation lane; no repo-wide expansion was used for claims below.
- The hinted path `adapters/moontown/client.mbt` was not present in the inspected tree; effective `moontown` runtime behavior is evidenced through `cmd/main/main.mbt`, `moontown.mbt`, and `goal_run.mbt` instead.
- This packet is intentionally source-materialization-ready: it favors directly citable claims, concrete paths, candidate entities/concepts, and explicit uncertainty over narrative synthesis.

## Concrete Source Paths
- `moon.mod.json`
- `cmd/main/main.mbt`
- `moontown.mbt`
- `goal_run.mbt`
- `adapters/moonbook/client.mbt`
- `adapters/moonclaw/client.mbt`
- `roles/mayor.mbt`

## Evidence Bullets
- `cmd/main/main.mbt:2` defines the async CLI `main`, and `cmd/main/main.mbt:5`, `cmd/main/main.mbt:6`, `cmd/main/main.mbt:10` route both explicit `run` requests and default fallback behavior through `@moontown`, making it the inspected runtime entry surface.
- `moon.mod.json:2` names the package `vectie/moontown`, `moon.mod.json:4` lists only `moonbitlang/async` and `moonbitlang/x`, and `moon.mod.json:13` sets `"preferred-target": "native"`; this anchors the package identity but does not expose how `@moonbook` or `@moonclaw` resolve.
- `goal_run.mbt:9`, `goal_run.mbt:10`, `goal_run.mbt:11`, `goal_run.mbt:15`, `goal_run.mbt:28` show the main orchestration loop: load/create catalog, select books, create town state, register books, and save a snapshot.
- `goal_run.mbt:58`, `goal_run.mbt:79`, `goal_run.mbt:92` show the Moonbook preflight chain for each book: accept goal, summarize state, and generate task batches.
- `goal_run.mbt:105`, `goal_run.mbt:372`, `goal_run.mbt:416` show a research-bootstrap guardrail that injects an ingest-first planning prompt oriented toward durable wiki coverage before later synthesis.
- `roles/mayor.mbt:93`, `roles/mayor.mbt:112`, `roles/mayor.mbt:119` show the mayor hydrating Moonbook worker context, attaching a `mayor_to_keeper_handoff(...)`, and computing the packet file path for keeper handoff storage.
- `adapters/moonclaw/client.mbt:231` stamps proposal packets with producer/provenance fields including `producer = "moontown"`, `book_id`, `workspace_root`, `task_id`, and step metadata flags, which is the strongest packet-origin evidence in-slice.
- `adapters/moonclaw/client.mbt:311` shells out to MoonClaw import via `moon -C ../moonclaw run cmd/main -- proposal import ... --json --cwd <cwd> --home <home>`, while `goal_run.mbt:247` is the Moontown-side call site passing the prepared keeper packet into `@moonclaw.import_packet(...)`.
- `adapters/moonclaw/client.mbt:399` polls `.moonclaw/jobs/index/runs.json` plus `<workspace>/result.json` and maps external run state into `@core.TaskExecutionStatus`, showing that Moontown consumes MoonClaw-produced execution state rather than producing it in this slice.
- `goal_run.mbt:134`, `goal_run.mbt:147`, `goal_run.mbt:204` anchor the round-trip `Moonbook plans -> MoonClaw executes -> Moonbook persists` by executing tasks, persisting execution into the book, and converting results into a Moonbook persistence envelope.
- `adapters/moonbook/client.mbt:386`, `adapters/moonbook/client.mbt:397`, `adapters/moonbook/client.mbt:414`, `adapters/moonbook/client.mbt:431`, `adapters/moonbook/client.mbt:441` all funnel through `run_book_json_command(...)` for accept/tasks/context/persist/summary operations, and `adapters/moonbook/client.mbt:452` builds a site by invoking `../moonbook` and returning `book/site/generated/index.html`.
- `adapters/moonclaw/client.mbt:566`, `adapters/moonclaw/client.mbt:590`, `adapters/moonclaw/client.mbt:615` define distinct mayor, keeper, and worker runtime descriptors with sharply different tool/memory/write permissions, making runtime separation one of the most strongly evidenced concepts in the lane.
- `adapters/moonclaw/client.mbt:635` defines the mayor-to-keeper handoff as `StrategicToDomain` targeting `keeper:{book_id}` with output contract `keeper.plan.packet.v1`, and `roles/mayor.mbt:84` is the in-lane Moontown call site that binds this handoff into book-specific orchestration.

## Entity Candidates
- `Moontown` — orchestration/runtime entry surface for CLI dispatch, town/book registration, task execution routing, and persistence handoff.
- `Moonbook` — external book-planning and book-persistence harness reached through command delegation.
- `MoonClaw` — external proposal-import and execution runtime that ingests packets and emits run/result state.
- `Mayor` — strategic planning role that prepares keeper handoffs from hydrated book context.
- `Keeper` — domain-scoped planning recipient targeted by mayor handoff packets.
- `Worker` — execution-capable runtime with fuller tools and workspace-write authority than mayor/keeper.
- `Book` — unit of selection, planning, execution, and persistence inside the goal-run loop.
- `Proposal packet` / `keeper packet` — interchange artifact materialized by Moontown and imported by MoonClaw.
- `Town state` — tentative persisted runtime model created and snapshotted during goal runs.
- `Catalog` — tentative registry/source of books/workspaces loaded or created during run bootstrap.

## Concept Candidates
- `runtime entry dispatch through @moontown`
- `Moonbook plans -> MoonClaw executes -> Moonbook persists`
- `packet-first handoff with memory isolation`
- `research-bootstrap / ingest-first planning for durable wiki coverage`
- `external command delegation to sibling repos rather than in-process integration`
- `role-separated runtimes with different tool, memory, and write permissions`
- `native-target CLI package anchored as vectie/moontown`
- `proposal-packet provenance stamping for downstream import`

## Unresolved Questions
- How are `@moonbook` and `@moonclaw` actually resolved and versioned if the inspected `moon.mod.json` slice does not declare them?
- Where do `run_book_json_command(...)`, `@integration.run_json(...)`, and `@integration.run_checked(...)` live, and what retry/error semantics do they impose on these shell-outs?
- Is the mayor/keeper planning runtime physically hosted inside MoonClaw, or merely described by MoonClaw adapter types while operational control remains with Moontown?
- Which repo or protocol layer owns `keeper.plan.packet.v1`, and what exact schema governs compatible packets?
- What process produces `.moonclaw/jobs/index/runs.json` and `<workspace>/result.json`, and are those files authoritative state or only integration-facing mirrors?
- Does `research_bootstrap_plan(...)` itself create durable source artifacts, or does it only inject planning intent that later execution may or may not realize?
- Is `load_or_create_demo_dashboard()` a Moontown-native output surface or a wrapper around Moonbook-generated site artifacts?

## Blockers And Confidence Limits
- Missing hinted adapter path: `adapters/moontown/client.mbt` was not present, so Moontown adapter claims must stay anchored to the inspected entry/runtime files instead of the absent path.
- Dependency linkage is not fully inspectable from this lane: `moon.mod.json` does not reveal how sibling repo packages are wired, so cross-repo resolution/version claims would be speculative.
- Command-spawn internals are out of lane: the implementations of `run_book_json_command(...)`, `@integration.run_json(...)`, and `@integration.run_checked(...)` were not inspected here.
- External state producers are out of lane: the code reads MoonClaw run indexes and workspace results, but this slice does not show who writes them.
- Site-generation internals are out of lane: `adapters/moonbook/client.mbt` invokes Moonbook build output, but the generation pipeline itself is not evidenced here.
- Confidence is moderate-high for wiring/path claims and role/runtime separation, and only moderate for ownership, schema, and lifecycle claims that depend on sibling-repo internals outside the bounded slice.
