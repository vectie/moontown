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
- routing and isolation decisions
- dashboard rendering
- scheduler/health/storage package boundaries

What is still stubbed:

- moonbook task planning
- moonbook result persistence
- moonclaw task execution
- long-running daemon patrol
- experiment runtime

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
