# username/moontown

`moontown` is the town-level orchestration layer above multiple `moonbook`
workspaces and multiple `moonclaw` workers.

- A `Town` hosts many `MoonbookHost` instances.
- Each book owns its own workspace root, memory scope, and worker pool.
- Tasks route to the best matching worker with isolation rules that can differ
  by domain, so coding and finance work do not have to share memory or runtime.

Run the demo:

```bash
moon run cmd/main
```

The demo prints a room-style dashboard with two books:

- a coding moonbook for harness engineering
- a finance moonbook for private ledger work

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
