# Tiled Map Pipeline

This document defines the repeatable procedure for generating and assembling a
2.5D Wenyu Valley map for the Moontown UI.

The target style is a Stardew-like isometric valley:

- pixel-art 2.5D
- 64x32 isometric ground tiles
- multi-layer map assembly
- explicit depth sorting
- semantic town zones backed by MoonTown, MoonBook, and MoonClaw runtime state

## Current State

The current viewport now uses a first-generation isometric tile layer:

```text
TownState
  -> DashboardModel
  -> SceneRenderModel
  -> Rabbita DOM/CSS isometric tile layer
  -> generated PNG ground/object/building assets
```

The grass, river, trees, flowers, paths, plaza, and bridge use generated PNG
assets under `src/ui/assets/tilemap/`. Rabbita currently assembles an overscanned
procedural map directly in `src/ui/rabbita-town/main/main.mbt`, with a smaller
reference map JSON under `src/ui/assets/tilemap/maps/wenyu-valley.json`.

The next scalable target is:

```text
asset prompt/spec
  -> generated tileset sprites
  -> tile manifest
  -> Tiled-compatible map JSON
  -> Moontown map loader
  -> Rabbita/Pixi/Canvas renderer
```

The interactive Wenyu feature layer is specified separately in
`docs/WENYU_UI_MODULE_SYSTEM.md`. The important split is:

- this document owns terrain, generated tiles, map assembly, and depth sorting
- `WENYU_UI_MODULE_SYSTEM.md` owns civic module buildings, interiors, and
  runtime bindings

Do not bake civic service UI into the base terrain raster. The base map should
remain a calm Wenyu Valley landscape; optional service buildings should be
loaded from module configuration and rendered above it.

## Asset Procedure

### 1. Define The Tile Vocabulary

Start with a small vocabulary. Do not generate hundreds of tiles first.

Required ground tiles:

- `grass_plain`
- `grass_light`
- `grass_dark`
- `grass_flower_pink`
- `grass_flower_yellow`
- `river_straight`
- `river_corner`
- `river_bank_north`
- `river_bank_south`
- `dirt_path`
- `plaza_stone`
- `wood_bridge`

Required object tiles:

- `tree_small`
- `tree_large`
- `bush`
- `sign`
- `bench`
- `lamp`
- `flower_patch`

Recommended building assets:

- `city_hall`
- `book_house`
- `worker_yard`
- optional `*_base`
- optional `*_roof`

For production maps, split `base` and `roof` when characters need to walk
behind building canopies. The current generated asset batch is composed as full
building sprites because the first generated sheet did not produce clean
base/roof pairs.

### 2. Generate Tilesets

Generate tiles in batches with fixed constraints:

- canvas: transparent background
- source ground tile: 128x96 PNG with a 64x32 isometric top diamond and visible
  tile thickness
- browser display tile: 96x72
- viewport ground: render more tiles than the visible frame needs, so buildings
  near the edge still stand on generated land rather than on the page background
- object bounds: multiples of 16px
- palette: spring valley greens, warm tan paths, blue-green river
- lighting: top-left light, bottom-right shadow
- camera: locked isometric, no perspective drift
- outline: minimal dark pixel outline
- export: PNG spritesheet plus individual PNG slices

Example prompt for image generation:

```text
Create a pixel-art isometric tileset for a spring AI innovation valley.
Use 64x32 isometric ground tiles, transparent background, top-left light,
bottom-right shadow, Stardew-like cozy rural tech town mood.
Include grass plain, grass light, grass dark, pink flower grass, yellow flower
grass, dirt path, river straight, river corner, river banks, plaza stone, and
wood bridge. Keep every tile aligned to the same isometric diamond grid.
No text, no UI, no characters, no perspective camera, no soft painterly edges.
```

Example prompt for buildings:

```text
Create pixel-art isometric building sprites for Wenyu Valley AI Innovation Town.
Transparent background, top-left light, 2.5D isometric view.
Produce clean full-building sprites first. If depth sorting behind roofs is
needed, also produce separate base and roof/canopy layers for each building:
City Hall, MoonBook house, Worker Yard, Policy Hall, AI Garden.
Style: spring valley, warm wood, cream walls, teal roofs, small civic-tech
details. No text baked into the sprite.
```

### 3. Slice And Name Assets

Store generated assets under:

```text
ui/assets/tilemap/
  tilesets/
    wenyu-ground-generated.png
    wenyu-objects-generated.png
    wenyu-buildings-generated.png
  tiles/
    grass_plain.png
    grass_flower_pink.png
    river_straight.png
  objects/
    tree_small.png
    bench.png
  buildings/
    city_hall_base.png
    book_house_base.png
    worker_yard_base.png
  maps/
    wenyu-valley.tmj
    wenyu-valley.json
  modules/
    wenyu-town-modules.json
  manifest.json
```

Naming rules:

- use lowercase kebab or snake ids consistently
- no spaces
- no model/run ids in final asset names
- preserve source prompts separately in `prompts/`

### 4. Create The Manifest

The manifest is the stable contract between generated art and the Moontown UI.

```json
{
  "sourceTileWidth": 128,
  "sourceTileHeight": 96,
  "renderTileWidth": 96,
  "renderTileHeight": 72,
  "orientation": "isometric",
  "tilesets": [
    {
      "id": "wenyu-ground",
      "image": "tilesets/wenyu-ground.png",
      "columns": 8,
      "tileCount": 64,
      "firstGid": 1
    }
  ],
  "tiles": {
    "grass_plain": { "gid": 1, "solid": false, "terrain": "grass" },
    "river_straight": { "gid": 20, "solid": true, "terrain": "water" },
    "wood_bridge": { "gid": 31, "solid": false, "terrain": "bridge", "elevation": 1 }
  },
  "objects": {
    "tree_small": {
      "image": "objects/tree_small.png",
      "anchor": "bottom-center",
      "solid": true,
      "sort": "y"
    }
  },
  "buildings": {
    "city_hall": {
      "sprite": "buildings/city_hall_base.png",
      "anchor": "bottom-center",
      "zone": "city-hall"
    }
  }
}
```

## Map Assembly Procedure

### 1. Use Layers

The map should be assembled in this order:

```text
ground
ground_detail
river
river_bank
path
building_base
objects
actors
building_roof
effects
hud
```

Layer ownership:

- `ground`, `river`, `path`: map editor or procedural generator
- `building_base`, `building_roof`: semantic scene placement
- `actors`: live runtime projection from workers/mayor/keeper
- `effects`: alerts, anomalies, health, recovery, queue pressure
- `hud`: Rabbita UI chrome

### 2. Use Isometric Projection

Use the standard 64x32 projection:

```ts
function gridToScreen(gridX: number, gridY: number) {
  return {
    x: (gridX - gridY) * 32,
    y: (gridX + gridY) * 16,
  }
}

function screenToGrid(screenX: number, screenY: number) {
  return {
    x: (screenX / 32 + screenY / 16) / 2,
    y: (screenY / 16 - screenX / 32) / 2,
  }
}
```

### 3. Sort By Depth

Render from far to near:

```ts
function sortKey(item: {
  gridX: number
  gridY: number
  elevation: number
  layerIndex: number
}) {
  return item.gridX + item.gridY + item.elevation * 4 + item.layerIndex * 0.01
}
```

Building roofs should not be sorted with the base. Roofs/canopies are rendered
after actors so workers can disappear behind them.

### 4. Keep Semantic Zones Stable

Do not place runtime concepts directly by pixel coordinates. Place semantic
zones and then attach art to them.

Required zone ids:

- `city-hall`
- `worker-yard`
- `book-wenyu-town-shell`
- `book-wenyu-resident-twins`
- `book-wenyu-policy-hall`
- `book-wenyu-contest-express`
- `book-wenyu-social-square`
- `book-wenyu-talent-avenue`
- `book-wenyu-vitality-dashboard`
- `book-wenyu-ai-garden`
- `book-wenyu-physical-bridge`
- `anomaly-corner`

Moontown owns the zone/runtime binding. MoonBook owns domain workspace content.
MoonClaw owns worker execution state.

## AI Generation Procedure

### 1. Generate Candidate Tiles

Generate 3-5 variants per tile type. Reject any asset with:

- inconsistent camera angle
- baked text
- mismatched shadow direction
- blurry anti-aliased edges
- non-transparent background
- broken 64x32 tile boundary

### 2. Normalize

Post-process each accepted asset:

- crop transparent padding
- snap anchor to bottom-center
- quantize or reduce palette if needed
- verify dimensions
- export both individual PNG and spritesheet

### 3. Register

Add every accepted asset to:

- `src/ui/assets/tilemap/manifest.json`
- `src/ui/assets/README.md`
- the map JSON or Tiled map

### 4. Assemble Map

Choose one of two assembly modes:

- `manual`: edit in Tiled, export `.tmj` or JSON
- `procedural`: script generates map JSON from semantic zone inputs

The procedural mode should start with simple rules:

- river crosses the valley horizontally with 1-2 bends
- City Hall sits north of the central bridge
- Worker Yard sits beside the bridge and dispatch path
- MoonBook houses occupy district pockets around the central plaza
- trees and flowers fill non-walkable edges
- paths connect every building to City Hall and Worker Yard

## Moontown Integration Plan

### Phase 1: Keep Current CSS, Add Manifest

Use the current CSS-rendered valley as visual reference. Add a real
`tilemap/manifest.json` and keep the CSS scene running.

### Phase 2: Add A Static Tilemap Renderer

Add a renderer that reads:

- `manifest.json`
- `maps/wenyu-valley.json`

It should output the same `SceneRenderModel` semantic nodes plus a tile layer.

### Phase 3: Add Dynamic Actors

Actors are not baked into the map. They come from `TownState.workers` and
`TownState.executions`.

Sorting rule:

```text
actor sort = gridX + gridY + elevation * 4
```

### Phase 4: Add Editor Or Generator

Use Tiled for manual editing first. Add procedural generation later when the
semantic contract is stable.

## Quality Gate

Before accepting a new map/assets batch:

- `npm run build` passes in `src/ui/rabbita-town`
- `/Users/kq/.moon/bin/moon -C src/ui/rabbita-town check main` passes
- viewport renders in Codex browser
- viewport renders in Safari
- no mayor/town control-plane book appears as a normal book house
- City Hall, Worker Yard, river, and all active book houses are visible
- workers are rendered above ground and below roof/canopy layers
- hidden/idle workers remain inside buildings until clicked
