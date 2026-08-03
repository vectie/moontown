# Implementation Evidence Notes

## Provenance
- Job: `job.proposal.20260417-145956-act-as-the-wiki-gather-usersk`
- Run: `run-20260417-150010-usersk`
- Step: `step_3`
- Scope lane: implementation-confirmed CLI surface, manifest-backed repo identity, and runtime wiring boundaries only.
- Evidence base: direct inspection of the files listed below plus the prior step outputs supplied in this run context.

## Exact source paths
- `moon.mod.json`
- `moon.pkg`
- `cmd/main/main.mbt`
- `goal_run.mbt`
- `moontown.mbt`
- `ui/rabbita-town/moon.mod.json`
- `ui/rabbita-town/main/main.mbt`

## Evidence bullets
- Root repo identity is manifest-backed as package `vectie/moontown`, version `0.1.0`, preferred target `native`, with readme pointer `README.mbt.md`; this is the strongest inspected identity source for the root package rather than README prose. Source: `moon.mod.json:2`, `moon.mod.json:3`, `moon.mod.json:8`, `moon.mod.json:13`.
- Root package exposure includes adapter modules `vectie/moontown/adapters/moonbook` and `vectie/moontown/adapters/moonclaw` inside the same package import boundary, which confirms in-repo module wiring but not separate package manifests for those adapters. Source: `moon.pkg:2`, `moon.pkg:3`, `moon.pkg:4`.
- The implementation-confirmed CLI surface at the thin native entrypoint is narrow: `run <goal>`, `run --book <book_id> <goal>`, variadic `run ...rest` joined into a goal string, and a default fallback path for all other arg shapes. Source: `cmd/main/main.mbt:3`, `cmd/main/main.mbt:4`, `cmd/main/main.mbt:5`, `cmd/main/main.mbt:6`, `cmd/main/main.mbt:8`, `cmd/main/main.mbt:10`.
- The root entrypoint only confirms dispatch targets, not deeper subsystem behavior by itself: `run` delegates to `@moontown.render_goal_run(...)`, while the default branch delegates to `@moontown.load_or_create_demo_dashboard()`. Any stronger behavior claim has to come from adjacent implementations, not from `cmd/main/main.mbt` alone. Source: `cmd/main/main.mbt:5`, `cmd/main/main.mbt:7`, `cmd/main/main.mbt:9`, `cmd/main/main.mbt:10`.
- The `run` dispatch target is implemented in `goal_run.mbt` as `pub async fn render_goal_run`, which calls `run_goal(...)` and then `render_state_dashboard(state)`. This confirms the CLI returns a rendered dashboard string after goal execution wiring, not a long-running service loop from this path. Source: `goal_run.mbt:33`, `goal_run.mbt:40`, `goal_run.mbt:47`.
- Adjacent runtime wiring for `run_goal(...)` confirms a bounded orchestration path: load or create a Moonbook catalog, select books, create fresh town state, register demo books and workers, run per-book goal handling, and save a snapshot. This is enough to support high-level runtime wiring claims, but not detailed guarantees about downstream Moonbook or role internals. Source: `goal_run.mbt:7`, `goal_run.mbt:9`, `goal_run.mbt:10`, `goal_run.mbt:11`, `goal_run.mbt:14`, `goal_run.mbt:15`, `goal_run.mbt:16`, `goal_run.mbt:25`, `goal_run.mbt:26`, `goal_run.mbt:28`.
- The default non-`run` path is also implementation-confirmed as a rendered-dashboard path: `load_or_create_demo_dashboard(...)` loads or creates demo state and returns `render_state_dashboard(state)`. The inspected code does not show server startup, REPL startup, or browser launch from this CLI fallback. Source: `moontown.mbt:556`, `moontown.mbt:560`, `moontown.mbt:561`.
- `render_state_dashboard(...)` crosses a visible runtime boundary by pulling `mayor.runtime()` metadata and composing dashboard output from health, UI, scheduler, and storage-derived data. This confirms the dashboard reflects runtime metadata, but only at the reporting/assembly level; it does not by itself confirm how those subsystems compute their internals. Source: `moontown.mbt:567`, `moontown.mbt:568`, `moontown.mbt:569`, `moontown.mbt:570`, `moontown.mbt:571`, `moontown.mbt:572`.
- The JS UI package identity is separately manifest-backed as `vectie/moontown-rabbita`, version `0.1.0`, preferred target `js`, with a local path dependency on `vectie/moontown`. Source: `ui/rabbita-town/moon.mod.json:2`, `ui/rabbita-town/moon.mod.json:3`, `ui/rabbita-town/moon.mod.json:8`, `ui/rabbita-town/moon.mod.json:9`, `ui/rabbita-town/moon.mod.json:17`.
- The Rabbita app entrypoint is thin startup wiring only: it creates a Rabbita cell with `model=init_model()`, `update`, and a `view` that calls `render_scene(dispatch, model)`, then mounts with `with_init(schedule_tick(dispatch)).mount("app")`. This confirms init/update/view/mount wiring, but not the deeper semantics of scene rendering or scheduled ticks beyond dispatch hookup. Source: `ui/rabbita-town/main/main.mbt:1235`, `ui/rabbita-town/main/main.mbt:1236`, `ui/rabbita-town/main/main.mbt:1237`, `ui/rabbita-town/main/main.mbt:1238`, `ui/rabbita-town/main/main.mbt:1239`, `ui/rabbita-town/main/main.mbt:1241`.

## Source-path notes
- `moon.mod.json`: authoritative inspected manifest for root package identity; use this before README-level claims.
- `moon.pkg`: package/module exposure boundary; confirms in-repo adapters are imported modules, not separate inspected package manifests here.
- `cmd/main/main.mbt`: authoritative root CLI dispatch surface; thin enough that it mainly proves argument shapes and delegate functions.
- `goal_run.mbt`: authoritative adjacent implementation for the `run` delegate; supports wiring claims only up to orchestration and rendering handoff.
- `moontown.mbt`: authoritative adjacent implementation for the default dashboard delegate and dashboard assembly boundary.
- `ui/rabbita-town/moon.mod.json`: authoritative manifest for the JS-targeted UI package identity and local dependency on the root package.
- `ui/rabbita-town/main/main.mbt`: authoritative UI startup wiring point; inspected only at the `main` block to avoid over-claiming simulation or rendering internals.

## Entity candidates
- `vectie/moontown`
- `vectie/moontown-rabbita`
- `cmd/main/main.mbt`
- `render_goal_run`
- `run_goal`
- `load_or_create_demo_dashboard`
- `render_state_dashboard`
- `vectie/moontown/adapters/moonbook`
- `vectie/moontown/adapters/moonclaw`
- `@rabbita.cell_with_dispatch`

## Concept candidates
- manifest-backed package identity
- thin CLI dispatch surface
- dispatch-only confirmation boundary
- goal-run orchestration path
- rendered dashboard fallback
- runtime metadata projection
- package/module exposure boundary
- JS UI mount wiring
- local path dependency wiring
- startup dispatch hookup

## Unresolved questions
- Is there a broader CLI surface elsewhere in the repo or in generated packaging that is not exercised by `cmd/main/main.mbt`, or is this file the complete public native entrypoint?
- Are `moonbook` and `moonclaw` documented or packaged as independent repos/packages outside this tree, given that this inspected evidence only confirms adapter-module imports and not standalone local manifests?
- What exact behaviors occur inside `select_goal_books`, `demo_mayor`, `register_demo_books`, `register_demo_workers`, `schedule_tick`, and `render_scene`? Current evidence intentionally stops at wiring boundaries and does not validate subsystem semantics.
- Does the default dashboard path always operate on persisted snapshot state, or can `load_or_create_demo_state(...)` synthesize new state under additional conditions not inspected here?
