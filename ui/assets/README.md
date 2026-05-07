# Moontown Scene Assets

This folder is the visual home for the town scene rendered by `moontown/ui`.

The structure follows the semantic-scene lesson from `sou`:

- one world background
- named places with stable coordinates
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

## Current Baseline Assets

- `backgrounds/town-square.svg`
- `buildings/city-hall.svg`
- `buildings/book-house-coding.svg`
- `buildings/book-house-finance.svg`
- `actors/mayor-claw.svg`
- `actors/keeper-claw.svg`
- `actors/worker-claw.svg`
- `props/worker-yard.svg`
- `props/gate-sign.svg`
- `effects/anomaly-signal.svg`
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
- Prefer complete building sprites for the current DOM renderer. Add clean
  base/roof splits only when the renderer supports actor depth sorting behind
  canopy pixels.
- Do not bake labels or UI text into art assets. Labels belong to Rabbita UI.

## Layout Source

The matching scene spec lives in `ui/scene_layout.mbt`.
