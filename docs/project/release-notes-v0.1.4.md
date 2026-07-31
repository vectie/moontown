# MoonTown 0.1.4 canonical town and placement reliability

MoonTown 0.1.4 makes the seeded Wenyu Energy Valley the canonical published
town, connects the governed research handoff surfaces, and fixes custom
building placement so ordinary open-land clicks behave predictably.

This candidate is ad-hoc signed and not notarized.

## Highlights

- Publish `index.html?seed=20260727` as the canonical Energy Valley experience
  and route the former viewport entry point to the same product surface.
- Keep the older map available only through an explicit legacy route so tests,
  documentation, and operator links all target one town.
- Surface governed research-salon and MoonFlow handoffs directly in the town
  without replacing MoonBook, MoonClaw, or MoonFlow ownership boundaries.
- Accept suitable forest, field, grass, meadow, urban, and plaza land for
  custom buildings while preserving roads, water, wetlands, user parks, and
  existing structures.
- Snap a requested building to the nearest valid roadside parcel when the
  clicked parcel is close but not directly buildable.
- Report specific placement blockers instead of collapsing every failure into
  a road-or-water message.
- Dispatch each canvas action exactly once and clear accepted building
  footprints visually without mutating the authored Wenyu terrain evidence.

## Verification performed

- All 1,028 native MoonBit tests pass.
- The Rabbita production build passes MoonBit checks and verifies 153 static
  files totaling 46.6 MiB.
- UI-to-UI placement verification creates one research tower, charges its
  800-credit cost once, retains the success receipt, and rejects a subsequent
  lake placement without changing the remaining budget.
- Lepusa strict native verification, bundle materialization, release planning,
  DMG packaging, installed-runtime smoke checks, ad-hoc signature validation,
  and disk-image checksum verification pass.

## Installation

Artifact: `MoonTown-0.1.4-macos-arm64.dmg`

SHA-256:
`a65aca8c17255760eaf9b786901c5972ec08e519e407dd40d83668b6d2555ddb`

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
