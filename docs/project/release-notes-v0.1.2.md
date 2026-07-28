# MoonTown 0.1.2 real-work Energy Valley

MoonTown 0.1.2 turns the procedural Energy Valley interface into a truthful
spatial work console. Operator requests, standing goals, MoonClaw stages,
MoonBook results, and building occupancy are now derived from durable runtime
state instead of animation.

This candidate is ad-hoc signed and not notarized.

## Highlights

- Keep the deterministic procedural Energy Valley map and construction system.
- Submit real standing research work directly from the town UI.
- Correlate operator request, standing goal, town task, MoonClaw run, and
  MoonBook result IDs.
- Show persisted sequential or parallel collaborators, detailed progress,
  review state, and allowlisted current-book result links.
- Route research, coding, finance, and Wenyu work to real civic buildings.
- Keep idle, stale, blocked, review-pending, failed, and completed states
  visually distinct.
- Store shared runtime state under `~/moonsuite`, outside the source checkout.
- Bundle the production UI and a native MoonBit localhost service with Lepusa.

## Real-work validation

A UI-originated research request completed four persisted stages:

1. source screening;
2. source expansion;
3. report synthesis;
4. quality repair.

The run inspected eight included sources, expanded the report to 12,284 words,
materialized MoonBook wiki pages, and reached review-pending state with working
evidence, review, and generated-site links.

## Verification performed

- Root MoonBit tests: 1,010/1,010.
- Native desktop projection tests: 4/4.
- Town engine/runtime tests: 30/30.
- UI server, projection, storage, and security tests: 47/47.
- TypeScript check and production frontend build pass.
- Lepusa strict native verification and all 15 bundle checks pass.
- DMG mount, isolated install, ad-hoc signature, installed-runtime, native
  sidecar, real projection, and allowlisted result-link smoke tests pass.
- MoonBook result-page reconciliation regression: 1/1.

## Installation

Artifact: `MoonTown-0.1.2-macos-arm64.dmg`

SHA-256:
`cbebd58a44c06a8571e15bf5240af943c08f6e20942f4dadfcd92255fa828719`

1. Open the DMG.
2. Drag MoonTown to the Applications shortcut.
3. Because this candidate is ad-hoc signed, macOS may require Control-clicking
   MoonTown and choosing **Open** on first launch.

Minimum system: macOS 11.0 on Apple silicon (`arm64`).

## Known limitations

- No Developer ID Application identity is installed on the build Mac, so this
  release is not notarized or stapled.
- Real-work execution requires a compatible MoonSuite runtime. If the daemon is
  stopped, the UI intentionally marks the last durable observation as stale.
- The research dossier is strong enough for cautious general conclusions, but
  Energy-sector-specific evidence remains thin and awaits review.
