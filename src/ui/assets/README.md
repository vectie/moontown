# MoonTown Energy Valley Assets

This folder is the visual home for the compiled Energy Valley world rendered by
the Rabbita frontend.

The structure supports the semantic compiled-world renderer:

- terrain and public-realm tiles
- named places with compiler-owned footprints and portals
- role-specific actors
- props and effects that make status readable at a glance

## Folders

- `backgrounds/`
  - world backdrops such as the main town square
- `buildings/`
  - city hall and moonbook house exteriors
- `actors/`
  - mayor, keeper, and worker claw sprites
- `props/`
  - signs, yards, furniture, utility objects
- `effects/`
  - anomaly, patrol, sync, and alert effects
- `tilemap/`
  - generated 2.5D isometric tilesets, sliced PNG sprites, map JSON, prompts, and tile manifests

## Archived concept assets

- `buildings/city-hall.svg`
- `buildings/book-house-coding.svg`
- `buildings/book-house-finance.svg`
- `actors/mayor-claw.svg`
- `actors/keeper-claw.svg`
- `actors/worker-claw.svg`
- `props/worker-yard.svg`
- `props/gate-sign.svg`
- `effects/anomaly-signal.svg`

These SVGs are retained only as early visual references. The production
Rabbita map loads the typed tilemap/semantic assets below; it does not ship a
baked scene background.
- `tilemap/tiles/*.png`
- `tilemap/objects/*.png`
- `tilemap/actors/*.png`
  - role animation strips plus `actors/roster/resident_0.png` through `resident_63.png`
- `tilemap/buildings/*.png`
- `tilemap/maps/wenyu-valley.json`

## Ownership Rules

- Study `sou` for layout and scene semantics, not for direct asset reuse.
- `sou` art assets are non-commercial only and should not be copied into this repo.
- Treat the current SVG set as starter examples and replace them with richer
  original `moontown` art over time.
- Follow the tiled-map procedure in
  [docs/TILED_MAP_PIPELINE.md](/Users/kq/Workspace/moontown/docs/TILED_MAP_PIPELINE.md)
  when generating and assembling isometric tiles.
- Prefer complete building sprites for the Canvas renderer. Add clean
  base/roof splits only when the renderer supports actor depth sorting behind
  canopy pixels.
- Do not bake labels or UI text into art assets. Labels belong to Rabbita UI.

## World Source

Placement and navigation truth comes from `CompiledTownWorld` and
`TownSnapshot`, not from an asset-local layout specification.
