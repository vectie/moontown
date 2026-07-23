# MoonTown 0.1.0 release candidate

MoonTown 0.1.0 introduces the Energy Valley native desktop experience: a
self-contained isometric town simulation packaged with Lepusa for Apple
silicon Macs.

This candidate is published as the
[GitHub `v0.1.0` prerelease](https://github.com/vectie/moontown/releases/tag/v0.1.0).
It is ad-hoc signed and not notarized.

## Highlights

- Observe a living town with weather, day/night, time-speed, resident, Agent,
  vitality, and budget state.
- Inspect all 13 civic buildings and moving residents directly on the map.
- Build roads, forest, a research tower, laboratory, innovation workshop, and
  talent housing with visible validation and success feedback.
- Follow residents, inspect construction, demolish custom work for the stated
  refund, and restore saved town state after restart.
- Compare civic services and recent activity in separate Dashboard tabs rather
  than searching through one long scrolling panel.
- Reopen a concise in-app Guide that defines every headline metric and explains
  construction, recovery, persistence, and shortcuts.

## Installation

Artifact: `MoonTown-0.1.0-macos-arm64.dmg`

SHA-256:
`71d885b48558f12ba26cd0d3d803412bd1dc0da31317d5e769354b5eb3d342c2`

1. Open the DMG.
2. Drag MoonTown to the Applications shortcut.
3. Because this candidate is ad-hoc signed, macOS may require
   Control-clicking MoonTown and choosing **Open** on first launch.

Minimum system: macOS 11.0 on Apple silicon (`arm64`).

## Verification performed

- Exercised every released page, button, tab, tool, weather state, time state,
  confirmation action, inspector transition, keyboard shortcut, success state,
  and representative validation error through a DMG-installed native Lepusa
  window.
- Verified normal 1182×768 and minimum native 768×825 layouts without
  document-level horizontal scrolling, clipped controls, or panel/dock
  collisions.
- Verified build, demolition/refund, Dashboard count, reset cancel/confirm,
  local persistence, restart restoration, and native process cleanup.
- Lepusa strict verification, bundle materialization, generated install smoke,
  pre/post-launch code-signature verification, and Finder DMG inspection pass.
- Root MoonBit strict native tests: 993/993.
- Rabbita module tests: 368/368 on JavaScript and 993/993 on native.
- Town engine tests: 3/3.
- UI server/asset tests: 6/6.
- TypeScript town check and production build pass.

The packaged web surface contains four files totaling 0.3 MiB. Legacy
projection snapshots, watcher data, and unused tilemap assets are excluded.

## Privacy and data

MoonTown is a local simulation. It has no provider setup, credentials, external
integration, localhost sidecar, or declared Lepusa capability. Town state is
stored in the WebView's external local storage and is not written into the
signed app bundle.

## Known limitations

- This candidate is ad-hoc signed. No Developer ID Application identity is
  installed on the build Mac, so the app is not notarized or stapled.
- The published release must not be described as notarized until Developer ID
  signing, notarization, `spctl`, and Stapler validation pass.
- Lepusa's separate direct development-launch command previously raised an
  invalid-memory error. The bundled runtime, copied DMG app, and generated
  install-smoke path all pass.

Detailed evidence:
[`docs/project/ui-release-ux-test-report.md`](ui-release-ux-test-report.md).
