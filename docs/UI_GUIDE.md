# MoonTown UI guide

MoonTown opens directly on the Energy Valley map. The map answers one
question: **what is happening in town right now, and where should I act?**

## First actions

1. Read the four top-right metrics for population, vitality, budget, and active
   Agents.
2. Open **Dashboard** to compare civic services or recent activity without
   scrolling through one long mixed list.
3. Choose **Inspect** and select a building or resident on the map.
4. Choose a build tool only when you want to change the town.

The in-app **Guide** is available from the lower-right actions and from the
Dashboard header. Press `Escape` to return to Inspect and close open panels.

## Map and simulation controls

- Drag in **Inspect** mode to pan. Use the mouse wheel to zoom.
- Click a building to see vitality, construction progress, and occupancy.
- Click a resident to see purpose and state, then follow or stop following.
- Weather buttons choose a manual condition. **Auto** returns weather control
  to the simulation.
- Pause/resume and `1×`, `2×`, `8×` change the simulation clock, not wall time.

The top metrics are local simulation values refreshed roughly every 0.4
seconds. The Dashboard chart is historical simulation data, not a live
municipal or external service feed.

- **Residents** is the simulated town population.
- **Vitality** is a 0–100 composite of town activity and civic-building health.
- **Budget** is the local amount available for roads, trees, and buildings.
- **Agents** are the mayor, keeper, and worker roles currently on duty; they
  are simulated town actors, not external AI-provider connections.

## Building and recovery

The dock exposes Inspect, Road, Forest, Demolish, and four building types.
Their shortcuts are `1` through `8`.

- Move over the map after choosing a tool. A valid preview shows where the
  change will land.
- If placement conflicts with terrain, another building, or the available
  budget, MoonTown explains the reason and stays usable.
- A placed building starts construction, is saved automatically, and appears
  under the Dashboard's self-built section.
- Select a self-built building to demolish it for the displayed 50% refund.
- **Reset Town** first explains exactly which local data will be cleared. Cancel
  leaves the town unchanged.

## Page

### Energy Valley

Purpose: observe and change the simulated town.

Normal first action: inspect a civic building or open Dashboard.

Empty/error behavior: the town always contains built-in civic services. Invalid
building actions show a short recovery message instead of navigating away.

### Guide

Purpose: explain the map, unfamiliar metrics, build tools, persistence, and
recovery. It is always reopenable from the main UI.

## Persistence and privacy

Custom buildings, changed terrain, budget, day, and time are stored locally in
the WebView's browser storage. MoonTown does not ask for credentials or connect
to third-party providers. Reset removes only that local town save; built-in
civic content returns on reload.
