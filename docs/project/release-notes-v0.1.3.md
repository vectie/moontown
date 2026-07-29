# MoonTown 0.1.3 Wenyu map integration

MoonTown 0.1.3 brings the large typed Wenyu reference map into the pure
MoonBit Energy Valley product without giving up procedural generation or real
agent work.

This candidate is ad-hoc signed and not notarized.

## Highlights

- Bridge the original typed Wenyu terrain and building data into the current
  procedural world model.
- Derive a deterministic, connected road graph that separates land parcels,
  reaches building entrances, and preserves the reference map's large-scale
  pattern.
- Render continuous road shoulders, surfaces, markings, and smooth bends while
  retaining grid-exact routing for agents.
- Keep building placement, procedural interiors, workstations, building
  exchange, and visible agent travel aligned with the migrated map.
- Preserve real-work projections and building occupancy instead of replacing
  work state with decorative animation.
- Separate town contracts, application behavior, and projections from the
  desktop and mini-app backend adapters so multiple frontends can share the
  product model.
- Keep generated workspaces and books under `~/moonsuite` instead of polluting
  the source checkout.

## Verification performed

- MoonBit checks, tests, generated interfaces, and formatting pass.
- Pure MoonBit frontend tests pass.
- Wenyu road topology, parcel separation, building access, pathfinding,
  procedural interior, runtime manifest, and projection regressions pass.
- Deterministic static frontend assembly and verification pass.
- Lepusa strict native verification, bundle materialization, DMG packaging,
  and installed-app smoke checks pass.
- The migrated map and smooth road rendering were exercised in the running UI.

## Installation

Artifact: `MoonTown-0.1.3-macos-arm64.dmg`

SHA-256:
`ca305d32bacb3d9c60070ab74260ef89b84404f8ba8084e08552dc76ca1013e0`

1. Open the DMG.
2. Drag MoonTown to the Applications shortcut.
3. Because this candidate is ad-hoc signed, macOS may require Control-clicking
   MoonTown and choosing **Open** on first launch.

Minimum system: macOS 11.0 on Apple silicon (`arm64`).

## Known limitations

- No Developer ID Application identity is installed on the build Mac, so this
  release is not notarized or stapled.
- Real-work execution requires a compatible MoonSuite runtime. When no live
  runtime is available, the UI keeps the last durable observation and marks it
  stale rather than inventing work.
