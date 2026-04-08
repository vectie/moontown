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

## Ownership Rules

- Study `sou` for layout and scene semantics, not for direct asset reuse.
- `sou` art assets are non-commercial only and should not be copied into this repo.
- Treat the current SVG set as starter examples and replace them with richer
  original `moontown` art over time.

## Layout Source

The matching scene spec lives in `ui/scene_layout.mbt`.
