# username/moontown

`moontown` is the town-level orchestration layer above multiple `moonbook`
workspaces and multiple `moonclaw` workers.

- A `Town` hosts many `MoonbookHost` instances.
- Each book owns its own workspace root, memory scope, and worker pool.
- Tasks route to the best matching worker with isolation rules that can differ
  by domain, so coding and finance work do not have to share memory or runtime.
- Town state is persisted so the demo can reboot from a saved snapshot instead
  of rebuilding everything from scratch each run.

Run the demo:

```bash
moon run cmd/main
```

The demo prints a room-style dashboard with books loaded from the moonbook
catalog:

- a coding moonbook for harness engineering
- a finance moonbook for private ledger work

## Current bootstrap flow

The current control path is:

```text
moonbook catalog -> town bootstrap -> worker/task demo state -> routing -> dashboard
```

More concretely:

- `adapters/moonbook/` persists the town's available books in
  `.moontown/moonbooks.json`
- `storage/` persists the seeded town snapshot in `.moontown/town.json`
- `moontown` loads the book catalog first, then seeds the initial town state
  from that catalog when the snapshot does not already exist
- workers and tasks are still demo data, but books are now sourced from the
  persisted moonbook registry boundary

## Current status

What is real today:

- persisted town snapshot bootstrap
- persisted moonbook catalog bootstrap
- embedded `Mayor` role adapter over a constrained `moonclaw` runtime profile
- routing and isolation decisions
- dashboard rendering
- scheduler/health/storage package boundaries

What is still stubbed:

- moonbook task planning
- moonbook result persistence
- moonclaw task execution
- long-running daemon patrol
- experiment runtime

## Embedded Roles

Moontown now treats MoonClaw as the shared agent substrate, but it does not
expose a raw generic worker brain directly to town code.

Current town-side role adapters:

- `Mayor`
  - town-level strategic planner
  - planner-only runtime envelope
  - limited tool visibility
  - global town memory scope
  - no direct workspace writes or execution tools by default
- `keeper` handoff target
  - modeled as the book-level domain runtime that receives strategic handoffs
  - town delegates toward a keeper contract instead of invoking a generic agent
    loop
- worker runtime profiles
  - still modeled separately as execution-layer profiles with full tool access

The design intent is:

- `moontown` calls `Mayor.decide_dispatch(...)`
- `moontown` calls `Mayor.patrol(...)`
- `moontown` produces keeper handoff packets for book-local planning

This keeps town orchestration logic in `moontown`, keeps domain harness logic in
`moonbook`, and leaves execution-heavy behavior in `moonclaw`.

Planned package layout:

```text
core/                  pure town model and shared types
dispatch/              routing and isolation decisions
experiment/            social experiment definitions and runs
health/                watchdog and anomaly reporting
storage/               snapshots and checkpoints
scheduler/             daemon tick planning
adapters/moonbook/     boundary to moonbook
adapters/moonclaw/     boundary to moonclaw
ui/                    operator dashboard model/rendering
```
