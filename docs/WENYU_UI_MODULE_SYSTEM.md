# Wenyu Valley Modular UI System

This document defines the next UI architecture for the Wenyu Valley viewport.
The goal is to keep the current clean map, while making civic functionality
rich, inspectable, and configurable.

## Product Intent

The Wenyu Valley UI should behave like a living civic town, not a decorative
dashboard. The terrain remains calm and readable. Complexity appears through
optional buildings, interiors, agents, effects, and runtime state.

The proposal document describes the town as:

- a 2D pixel-art game-like gateway
- an always-on AI Agent community platform
- a virtual-real bridge for OPC services
- a 1:1 Wenyu Valley terrain replica
- a set of civic modules that can grow over time

That maps naturally to a modular add-on system:

```text
base terrain
  + enabled civic modules
  + module-specific buildings
  + module-specific interiors
  + MoonBook projection fragments
  + MoonClaw worker activity
  + Moontown mayor supervision
```

## Design Principle

Keep three layers separate:

1. Terrain layer
   Static or slowly changing map: grass, farms, roads, river, lakes, bridges,
   wetlands, haze, and seasonal surface details.

2. Civic module layer
   Configurable buildings that represent product features: Policy Hall, Social
   Square, Talent Avenue, AI Garden, Physical Bridge, and other optional civic
   services.

3. Runtime layer
   Agents, messages, alerts, active runs, daemon ticks, watcher decisions,
   review queues, and MoonBook/MoonClaw status.

The UI should never require code edits just to add, remove, or move one civic
feature building.

## Module Registry

The first config file lives at:

```text
ui/assets/tilemap/modules/wenyu-town-modules.json
```

Each module entry is a town add-on:

```json
{
  "id": "policy-hall",
  "enabled": true,
  "title": "Policy Hall",
  "book_id": "policy-hall",
  "district": "central-innovation",
  "building_kind": "policy-hall",
  "grid_x": 108,
  "grid_y": 63,
  "footprint_w": 8,
  "footprint_h": 6,
  "entrance_x": 111,
  "entrance_y": 69,
  "interior_kind": "policy",
  "asset_base": "tilemap/districts/policy_hall.png",
  "asset_roof": "",
  "summary": "Policy quests, eligibility checks, and cited application packets."
}
```

Required fields:

- `id`: stable module id used by the UI and selection state
- `enabled`: whether the module is present on the map
- `title`: user-facing building name
- `book_id`: MoonBook workspace binding
- `district`: semantic area on the map
- `building_kind`: CSS/art variant
- `grid_x`, `grid_y`: isometric tile anchor
- `footprint_w`, `footprint_h`: approximate placement footprint
- `entrance_x`, `entrance_y`: actor routing target
- `interior_kind`: furniture/interior variant
- `asset_base`: visible building sprite
- `asset_roof`: optional separate roof layer for later depth sorting
- `summary`: short inspection copy

## Feature-To-Building Map

| Proposal Feature | Module Building | Owner Split |
|---|---|---|
| 政策发布馆 | Policy Hall | Moontown routes, MoonBook stores policy wiki, MoonClaw researches and drafts |
| 赛事直通车 | Contest Express | Moontown schedules, MoonBook stores readiness records, MoonClaw reviews decks |
| 社交广场 | Social Square | Moontown shows matches, MoonBook stores social graph, MoonClaw drafts introductions |
| 人才星光大道 | Talent Avenue | Moontown projects public cards, MoonBook owns talent graph, MoonClaw verifies evidence |
| 街区活力看板 | Vitality Tower | Moontown owns counters, MoonBook exposes book counters, MoonClaw emits run packets |
| AI 科普花园 | AI Garden | Moontown schedules learning quests, MoonBook stores tutorials, MoonClaw drafts examples |
| 虚实连接器 | Physical Bridge | Moontown gates actions, MoonBook stores venue/robot knowledge, MoonClaw executes approved calls |
| 数字分身 | Resident Twin Homes | Moontown displays projections, MoonBook owns memory, MoonClaw emits candidates |
| 河谷积分 | Valley Market | Moontown projects point flow, MoonBook stores ledger records, MoonClaw drafts reward paths |
| Agent 故事雷达 | Broadcast Tower | Moontown highlights stories, MoonBook stores reviewed stories, MoonClaw summarizes events |

## Visual Richness Without Clutter

The current map is clean, which is valuable. Do not solve richness by filling
every tile. Add detail where it communicates state.

Recommended upgrades:

- River depth: darker river centers, lighter banks, reed clusters, bridge
  shadows, and shallow edge highlights.
- Water reflection: subtle, slow shimmer strips near bridges and civic
  buildings. These should be CSS/runtime overlays, not destructive edits to the
  base raster.
- Buildings: each civic module gets a distinct silhouette and roof language.
- Interiors: clicking a module switches to an interior scene with furniture
  matched to the module function.
- Agents: working agents appear outside and move toward their active module;
  idle or finished agents stay inside relevant buildings.
- Labels: building info stays hidden by default and appears on hover/focus.
- Seasonal detail: flowers, window glow, weather, and day phase should be
  driven by real-world time and config, not random virtual time.

## Runtime Binding

Each module binds to a MoonBook through `book_id`.

```text
module.book_id
  -> MoonBook projection fragment
  -> module-projections.json bridge
  -> Moontown runtime projection
  -> viewport building status
  -> actor destination
  -> interior worker roster
  -> generated output links
```

The visual state should come from real runtime data when available:

- active runs -> building pulse and visible workers
- review queues -> amber review light
- failed/stale runs -> recovery marker
- no work due -> calm/idle building
- projection missing -> explicit integration-gap panel inside the module

## Implementation Stages

Current implementation status is tracked in
[WENYU_TOWN_STATUS.md](/Users/kq/Workspace/moontown/docs/WENYU_TOWN_STATUS.md).
Use that document as the readiness checklist before claiming the town is fully
functioning.

### Stage 1: Configurable Buildings

- Load `wenyu-town-modules.json` in the Rabbita bootstrap.
- Parse enabled modules in MoonBit.
- Render module buildings as a separate layer above the raster terrain.
- Clicking a module opens a module-specific interior.
- Hover/focus reveals the building info panel.

### Stage 2: Visual Water System

- Add a water-effect layer over the base map.
- Add depth, bank glow, bridge shadow, and shimmer overlays.
- Keep effects pointer-transparent and cheap to animate.

### Stage 3: Agent Routing

- Route visible agents to `entrance_x` and `entrance_y` from the module config.
- Show only working or blocked agents outside.
- Keep idle, waiting, and completed agents inside buildings unless a user opens
  that building.

Current status:

- active visual agents now route to a matched module entrance when their
  book/task maps to a configured module
- idle, completed, and absent module agents do not create fake overworld badges
- the remaining gap is projection coverage: each Wenyu civic workflow still
  needs to emit module-specific book/task/run fragments

### Stage 4: Runtime Projection

- Extend Moontown projection JSON with module status.
- Merge MoonBook projection fragments by `book_id`.
- Bind building lights, counters, badges, and messages to real data.

Current status:

- the viewport uses visual projection data first, direct execution records
  second, and config fallback last
- module lights distinguish running, waiting, review, alert, complete,
  projected, unbound, and calm states
- module interiors show runtime source, status counters, validation state, and
  active worker roster slots
- `visual-projection.json` now includes first-class `modules[]` status objects
  keyed by normalized module id
- the Vite bridge now scans `.moontown/books/*/book/moonbook-ui-state.json`
  and publishes `module-projections.json`
- module interiors now show MoonBook summary, chips, metrics, readiness,
  review queue, page families, output links, and latest journey when a bound
  book fragment exists
- the remaining gap is civic content coverage: most Wenyu feature buildings
  still need real MoonBook workspaces and service-specific schemas

### Stage 5: Asset Pipeline

- Generate missing building variants with image generation.
- Keep prompts in `ui/assets/tilemap/prompts/`.
- Slice assets into transparent PNG sprites.
- Register assets in `manifest.json`.
- Never bake text into building sprites.

### Stage 6: Designer Tooling

- Validate module JSON before rendering.
- Detect buildings placed on water or blocked roads.
- Preview changed modules without rebuilding MoonBit code.
- Report missing assets, oversized sprites, non-transparent backgrounds, and
  broken `book_id` bindings.
- Export a placement diff that can be reviewed before committing map changes.

Current status:

- viewport runtime validation catches missing `book_id`, missing assets, invalid
  footprints, building anchors on blocked terrain, and entrances on water
- bridge/river/harbor modules can opt into water or bridge placement
- standalone schema validation and designer preview tooling are still pending

### Stage 7: Civic Runtime Integration

- Require every enabled module to bind to a populated MoonBook projection
  fragment.
- Require every active worker avatar to derive from a MoonClaw run or standing
  watcher record.
- Show output links, review gaps, and last accepted knowledge changes in the
  interior view.
- Keep decorative animation separate from truth-bearing runtime status.

## Acceptance Criteria

- A designer can remove a building by setting `enabled` to `false`.
- A designer can move a building by changing `grid_x` and `grid_y`.
- A designer can add a new building by adding one JSON object and one asset.
- The viewport still loads if a module asset is missing.
- Hover/focus reveals building information; labels are hidden otherwise.
- The base terrain remains visually calm.
- River depth/reflection is visible but not noisy.
- The UI builds with `npm run build`.
- MoonBit checks pass with `moon check`.
- Runtime labels distinguish configured modules from real active work.
- Worker avatars are not shown as busy unless a real task/run/watch record says
  they are busy.
