# MoonTown 0.1.1 procedural Energy Valley

MoonTown 0.1.1 keeps the new interactive town framework while restoring the
recognizable spatial identity of the Changping Future Science City Energy
Valley.

This candidate is ad-hoc signed and not notarized.

## Highlights

- Generate deterministic Energy Valley variants from a reusable planning
  grammar instead of loading a fixed map.
- Preserve the eastern main river, western tributary, central lake and wetland,
  farm belt, forest buffers, civic grid, district hierarchy, and three
  deliberate bridge corridors across seeds.
- Place 13 built-in civic services by district intent, collision constraints,
  and road access.
- Grow district-specific ambient urban fabric with low-rise, row, courtyard,
  campus, and tower forms.
- Reset player construction without changing the valley, or generate a new
  seed and rebuild the complete landscape.
- Save only player changes over the generated terrain baseline.

## Verification performed

- Tested deterministic replay and Energy Valley invariants across 512 generated
  variants.
- Town engine tests: 5/5.
- UI server and runtime asset tests: 6/6.
- Root MoonBit native tests: 993/993.
- TypeScript town check and production frontend build pass.
- Lepusa strict native verification and all 13 bundle materialization checks
  pass.
- Reset, same-seed reconstruction, new-seed regeneration, and visual map
  hierarchy were exercised in the running UI.

## Installation

Artifact: `MoonTown-0.1.1-macos-arm64.dmg`

SHA-256:
`3819fbe43f2669db53c3dfebb188de014e1e2ef26cea4f0075e6e2fa7573565a`

1. Open the DMG.
2. Drag MoonTown to the Applications shortcut.
3. Because this candidate is ad-hoc signed, macOS may require Control-clicking
   MoonTown and choosing **Open** on first launch.

Minimum system: macOS 11.0 on Apple silicon (`arm64`).

## Known limitation

No Developer ID Application identity is installed on the build Mac. This
candidate is therefore not notarized or stapled and must not be represented as
a notarized production build.
