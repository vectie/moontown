# Energy Valley Real Work Projection

Energy Valley has two deliberately separate layers:

- the procedural map, weather, construction, residents, vitality, and budget are
  a local visual simulation;
- tasks, runs, workers, artifacts, and work destinations come only from the
  MoonTown runtime projection.

The UI must never infer real work from motion, occupancy, vitality, or a random
simulation event.

## Runtime contract

The development server and bundled Lepusa desktop service expose
`GET /energy-valley-runtime.json` using schema
`moontown.energy-valley.runtime.v1`. They read the durable MoonTown town
snapshot, daemon tick, standing goals, watcher ledgers, operator request ledger,
and persisted MoonClaw step records. Missing or malformed sources produce:

```json
{
  "schema": "moontown.energy-valley.runtime.v1",
  "mode": "unavailable",
  "tasks": [],
  "agents": []
}
```

That response is a valid honest state, not an error and not a prompt to
generate demo tasks.

The browser polls the endpoint, validates untrusted JSON, and distinguishes:

- `loading`: no response has arrived;
- `live`: the runtime supplied a valid live projection;
- `stale`: the last real projection is retained, but no new work is inferred;
- `unavailable`: the runtime is absent or has no valid durable state;
- `error`: transport or validation failed.

## Work-to-building resolution

Work is placed only when its `buildingModuleKey` exactly matches a completed
procedural-map building. Authored Wenyu modules resolve through the module
registry. Runtime aliases include:

- `vitality-dashboard` to `vitality-tower`;
- `broadcast-tower` to `story-radar`;
- authored research books to `energy-lab`;
- coding work to `ai-garden`;
- finance work to `valley-market`;
- Wenyu book IDs to their corresponding Energy Valley civic module.

The Wenyu physical-bridge service is projected at the civic hub because the
current procedural layout has no standalone bridge-service building. Missing
book IDs and unknown module IDs remain unlocated.

## Agent lifecycle

Runtime agents are projections of real worker records. Their task, run,
status, source, and requested building IDs remain attached to the visual
agent.

- assigned, running, waiting-review, and blocked work routes to its exact
  building;
- queued, completed, and failed work remains parked;
- idle and offline workers never acquire a generated purpose;
- runtime agents removed from the next snapshot are removed from the map;
- non-resident ambient agents pause while live runtime projection is active;
- ambient residents may continue moving, but the UI labels them as scenery.

The runtime projection does not create arrival events or increase building
vitality. Building and agent inspectors expose the real task and run IDs so an
operator can distinguish evidence from animation.

## Packaging boundary

The Lepusa package bundles a narrow native MoonBit desktop service. Lepusa
starts it on localhost, waits for `/health`, and stops it with the application.
The service exposes only:

- the production UI;
- the validated runtime projection;
- bounded same-origin operator-request submission;
- an allowlisted, realpath-contained set of current-book result pages.

Runtime state remains under `~/moonsuite` (or an explicit
`MOONTOWN_SUITE_ROOT`) and is never written into the source checkout or frozen
into the application. The packaged UI reports stopped or stale daemon state
truthfully instead of inventing activity.
