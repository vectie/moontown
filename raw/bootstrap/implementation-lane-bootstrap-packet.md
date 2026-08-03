# Implementation-Lane Bootstrap Packet

This packet is prepared for downstream implementation-lane use only. It reflects bounded source inspection in the current worktree, preserves raw implementation evidence immutably as cited below, and does not claim final ingest success, broader workflow completion, or cross-lane coverage.

## Lane Purpose

- Capture an implementation-lane-only bootstrap view of the local `moontown` source surface.
- Record only the code and config files actually inspected for manifest identity, package exposure, entrypoints, and the smallest adjacent runtime wiring needed to support substantive claims.
- Preserve direct evidence as file-and-line citations without rewriting inspected source into broader architectural conclusions.
- Avoid claiming docs-lane, ingest-wide, or cross-repo completion beyond what this packet can directly evidence.

## Inspected Source List

- `moon.mod.json`
- `moon.pkg`
- `cmd/main/main.mbt`
- `goal_run.mbt`
- `moontown.mbt`
- `ui/rabbita-town/moon.mod.json`
- `ui/rabbita-town/main/main.mbt`
- Prior step outputs embedded in this job run:
  - `step_1` implementation-lane scope boundary
  - `step_2` implementation evidence synthesis
  - `step_3` note that packet-ready implementation evidence had been assembled

## Provenance Notes

- This packet is grounded in direct inspection of local code/config files in the current `moontown` worktree.
- Prior step outputs are treated as workflow context only; substantive claims here are anchored to direct file citations from this step's inspected surface.
- Raw evidence is preserved by citing exact files and lines rather than paraphrasing them into unbounded completion claims.
- No claim is made here that all implementation surfaces were inspected.
- No claim is made here that downstream source materialization, wiki ingest, or broader bootstrap completed successfully.

## Evidence Bullets

- Root package identity is declared as `vectie/moontown`, with `README.mbt.md` as the readme pointer and `native` as the preferred target. Evidence: `moon.mod.json:2`, `moon.mod.json:8`, `moon.mod.json:13`
- Root package exposure explicitly imports `vectie/moontown/adapters/moonbook` and `vectie/moontown/adapters/moonclaw` alongside local subsystems, so those adapter surfaces are part of the root package boundary visible from `moon.pkg`. Evidence: `moon.pkg:1`, `moon.pkg:3`, `moon.pkg:4`, `moon.pkg:11`
- The thin root CLI entrypoint exposes a `run` command family plus a default fallback only: `['run', goal]`, `['run', '--book', book_id, goal]`, variadic `['run', .. rest]`, and `_` falling back to demo dashboard rendering. Evidence: `cmd/main/main.mbt:4`, `cmd/main/main.mbt:5`, `cmd/main/main.mbt:6`, `cmd/main/main.mbt:8`, `cmd/main/main.mbt:10`
- That root CLI does not directly implement deeper subcommands in-place; it delegates to `@moontown.render_goal_run(...)` for `run` paths and `@moontown.load_or_create_demo_dashboard()` for the fallback path. Evidence: `cmd/main/main.mbt:5`, `cmd/main/main.mbt:7`, `cmd/main/main.mbt:9`, `cmd/main/main.mbt:10`
- The `run` path is substantively wired to load or create a Moonbook catalog, select goal-relevant books, initialize empty town state, register demo books/workers, execute per-book goal handling, and save a snapshot file. Evidence: `goal_run.mbt:7`, `goal_run.mbt:9`, `goal_run.mbt:10`, `goal_run.mbt:11`, `goal_run.mbt:15`, `goal_run.mbt:16`, `goal_run.mbt:26`, `goal_run.mbt:28`
- Within per-book handling, the implementation calls Moonbook acceptance, state summary, task-batch production, execution persistence, workspace build, and follow-up summary functions, which shows adapter-mediated orchestration rather than a no-op stub. Evidence: `goal_run.mbt:58`, `goal_run.mbt:79`, `goal_run.mbt:92`, `goal_run.mbt:147`, `goal_run.mbt:150`, `goal_run.mbt:163`
- The default non-`run` path is concretely wired to load or create demo state and then render a dashboard string, not to mount a server or start a separate long-running loop in the inspected code. Evidence: `moontown.mbt:556`, `moontown.mbt:560`, `moontown.mbt:561`
- Dashboard rendering also surfaces mayor runtime metadata directly from implementation state by printing role, runtime mode, tool access, authority scope, execution count, events, tick summary, and snapshot description. Evidence: `moontown.mbt:565`, `moontown.mbt:567`, `moontown.mbt:568`, `moontown.mbt:571`, `moontown.mbt:572`, `moontown.mbt:588`
- The separate UI package identifies itself as `vectie/moontown-rabbita`, depends on local `vectie/moontown` plus a path-based Rabbita dependency, and sets preferred target `js`. Evidence: `ui/rabbita-town/moon.mod.json:2`, `ui/rabbita-town/moon.mod.json:5`, `ui/rabbita-town/moon.mod.json:8`, `ui/rabbita-town/moon.mod.json:12`, `ui/rabbita-town/moon.mod.json:17`
- The Rabbita frontend entrypoint is thin startup wiring only: it creates a Rabbita cell with `init_model()`, `update`, and `render_scene(...)`, then mounts with `.with_init(schedule_tick(dispatch)).mount("app")`. Evidence: `ui/rabbita-town/main/main.mbt:1235`, `ui/rabbita-town/main/main.mbt:1236`, `ui/rabbita-town/main/main.mbt:1237`, `ui/rabbita-town/main/main.mbt:1238`, `ui/rabbita-town/main/main.mbt:1239`, `ui/rabbita-town/main/main.mbt:1241`

## Source-Path Notes

- `moon.mod.json` is the authoritative inspected manifest for the root MoonBit package in this worktree.
- `moon.pkg` is the inspected package exposure boundary adjacent to the root manifest and should be treated as implementation evidence for imported module surfaces, not as a full architecture inventory.
- `cmd/main/main.mbt` is a thin root entrypoint and should not be overread as proving broader CLI coverage beyond the dispatch cases shown.
- `goal_run.mbt` was inspected only as the smallest adjacent runtime wiring needed to substantiate what the root `run` path actually invokes.
- `moontown.mbt` was inspected only at the `load_or_create_demo_dashboard` and dashboard-rendering adjacency needed to substantiate the default CLI fallback path.
- `ui/rabbita-town/main/main.mbt` was inspected only at the startup block needed to confirm frontend init/update/view/mount wiring.
- The packet file path is `raw/bootstrap/implementation-lane-bootstrap-packet.md`.

## Entity Candidates

- `vectie/moontown` - root MoonBit package identity declared in the local manifest
- `vectie/moontown-rabbita` - JS-targeted Rabbita frontend package declared in the local UI manifest
- `moonbook` - adapter surface imported by the root package and invoked from goal-run orchestration
- `moonclaw` - adapter surface imported by the root package boundary
- `render_goal_run` - root run-path implementation target
- `load_or_create_demo_dashboard` - root fallback-path implementation target
- `TownState` - root state object created and rendered in the inspected runtime path
- `Mayor` - runtime metadata source surfaced in rendered dashboard output

## Concept Candidates

- Thin CLI dispatch delegating into adjacent runtime helpers
- Adapter-mediated orchestration around Moonbook-backed book execution
- Snapshot-backed demo-state fallback rendering
- Package identity split between native root runtime and JS-targeted Rabbita frontend
- Thin frontend bootstrap wiring through Rabbita cell/init/mount flow
- Evidence-bounded implementation claims anchored to manifest and entrypoint inspection

## Source-Material Candidates

- `moon.mod.json` - root package identity, readme pointer, preferred target
- `moon.pkg` - imported module exposure boundary
- `cmd/main/main.mbt` - root CLI dispatch surface
- `goal_run.mbt` - adjacent `run`-path orchestration wiring
- `moontown.mbt` - adjacent fallback dashboard wiring and rendered runtime metadata
- `ui/rabbita-town/moon.mod.json` - UI package identity and dependency wiring
- `ui/rabbita-town/main/main.mbt` - UI startup and mount wiring

## Open Questions Or Blockers

- None added. The inspected code/config surface is sufficient to support the bounded implementation claims recorded here.

## Downstream Handling Note

- Treat this file as a staging packet for implementation-lane downstream source materialization.
- Preserve the cited file-and-line evidence as the immutable basis for later materialization steps.
- Do not interpret this packet as evidence that broader ingest, documentation synthesis, or cross-repo implementation coverage is complete.
