# MoonTown UI and Lepusa release test report

Date: 2026-07-23
Release candidate: `0.1.0`
Surface under test: the packaged-static Energy Valley town

## Outcome

The town interaction flow passes in a DMG-installed Lepusa app. It is ready as
a local release candidate. Public publication is not yet complete because the
artifact is ad-hoc signed, not notarized, and has not been attached to a GitHub
tag/release.

The release surface intentionally contains one product page plus its in-app
Guide. The older operations and viewport projections were removed from the
packaged page set because they depend on Vite-only runtime snapshots and showed
an indefinite, untruthful “connecting” state in a static desktop build.

## Page inventory

| Surface | Purpose understood | All actions | Error/recovery | Restart | Narrow |
| --- | --- | --- | --- | --- | --- |
| Energy Valley | Pass | Pass | Pass | Pass | Pass |
| Dashboard: services | Pass | Pass | N/A | Pass | Pass |
| Dashboard: activity | Pass | Pass | N/A | Pass | Pass |
| Building/resident inspector | Pass | Pass | Pass | Pass | Pass |
| Guide | Pass | Pass | N/A | Pass | Pass |
| Reset confirmation | Pass | Pass | Pass | Pass | Pass |

The narrow native screenshot is 768×825 pixels after dragging the window to a
720-pixel target width. This is the smallest size exposed by the current Lepusa
window on the test display. It is shorter than the handover’s 720×900 reference,
so it is the stricter vertical case. No document-level horizontal scrolling,
clipping, or control overlap remains.

## Human use cases

### Understand the town without hunting

- Open the app from a copy installed out of the DMG.
- Read weather/time and four summary metrics.
- Open Dashboard.
- Switch between the 13 civic services and recent activity.
- Select City Hall.

Result: every service is visible in a two-column grid without scrolling.
Selecting a service closes Dashboard, centers the map, and opens the inspector
instead of stacking two panels.

### Inspect a resident

- Select Inspect.
- Click a moving resident.
- Start Follow View, then cancel it.
- Press Escape.

Result: purpose and state are understandable, follow state changes visibly,
cancel restores the ordinary camera, and Escape returns to Inspect and closes
the panel.

### Build, validate, persist, and demolish

- Select each of the eight dock tools.
- Trigger building-on-building, building-on-road, missing-road-adjacency, and
  non-grass errors.
- Place and complete a research tower, laboratory, and innovation workshop.
- Verify budget deductions and Dashboard’s self-built count.
- Inspect a self-built building and demolish it.
- Verify the 50% refund and removal.
- Place road and forest tiles; verify explicit success feedback.
- Quit and reopen the installed app.

Result: invalid placement explains the exact recovery, construction events and
budget agree, the inspector and Dashboard agree, demolition refunds correctly,
and saved day/time/budget/terrain return after restart.

### Control and reset the simulation

- Exercise sunny, cloudy, rain, snow, and automatic weather.
- Exercise pause/resume and 1×, 2×, and 8×.
- Exercise Space, Escape, and a numeric tool shortcut.
- Open Reset, cancel it, reopen it, and confirm.

Result: selected states are now exposed as toggle state as well as visual
styling. Pause holds the clock. Cancel preserves the town. Confirm reloads at
Day 1 with custom construction removed.

## Bugs found and fixed

| Finding | Fix |
| --- | --- |
| Dashboard covered the inspector after selecting a service | Selecting a row now closes Dashboard before opening the inspector |
| Services and logs were hidden in one long internal scroll | Split Dashboard into Services and Activity tabs; use a compact two-column service grid |
| No way to reopen onboarding help | Added a persistent Guide action and a full in-app Guide |
| Reset deleted local work immediately | Added an explicit cancel/confirm alert dialog |
| Onboarding said 11 civic buildings while the app showed 13 | Corrected onboarding to 13 |
| Tool/weather/speed selection was visual only | Added accessible labels and pressed/expanded state |
| Road, forest, and tile demolition lacked success feedback | Added truthful success and empty-target messages |
| Narrow event feed collided with the tool dock | Hide the nonessential feed at narrow widths |
| Narrow Dashboard collided with bottom controls | Hide the nonessential chart at narrow widths; all services/activity remain visible |
| Packaged Operations stayed on “connecting” and had no return flow | Removed legacy Operations/Viewport from the release page set and primary navigation |
| Packaged town still copied 51 MiB of unused legacy projections, sprites, and snapshot JSON | Release build now contains only the town entry point and its three hashed assets; the verifier rejects legacy data and enforces a 2 MiB web-payload budget |
| Guide named “vitality,” “budget,” and “Agent” without defining them | Added concise definitions in both the native in-app Guide and repository guide |
| New logo import lacked a TypeScript SVG declaration | Added the Vite client type reference |
| Root strict gate failed on deprecated MoonBit file/HTTP APIs | Migrated writes to explicit create modes/permissions and the current HTTP constructor |
| Moon package repository metadata was blank | Pointed the root and Rabbita module metadata at the verified GitHub repository |

## Build and release evidence

- Published package provenance: Rabbita `0.12.4`, Lepusa `0.1.4`, and
  `@rabbita/vite` `0.2.0`.
- Lepusa `verify macos --strict`: pass.
- Lepusa bundle materialization: `verified: true`.
- DMG contains MoonTown and an `/Applications` shortcut; visually inspected in
  Finder.
- DMG-installed copy launches at
  `lepusa://packaged/main/index.html`.
- Packaged web surface: 4 files, 0.3 MiB; installed app: 3.4 MiB; DMG:
  2,182,907 bytes.
- Signature is valid before and after first launch.
- No `.moontown` or `.moonsuite` state was written inside
  `Contents/Resources`.
- No legacy projection JSON, watcher data, or unused tilemap assets are present
  in the installed app.
- Bundled `lepusa-runtime` declares macOS `minos 11.0`.
- Root strict native check: pass.
- Root strict native tests: 993/993 pass.
- Rabbita module tests: 368/368 pass on JavaScript and 993/993 pass on native.
- TypeScript town check: pass.
- Town engine tests: 3/3 pass.
- UI server/asset tests: 6/6 pass.
- Production frontend build: pass, 4 files, 0.3 MiB.
- Generated Lepusa install-smoke script: pass.
- Native close leaves no MoonTown launcher or Lepusa runtime process behind.
- DMG SHA-256:
  `71d885b48558f12ba26cd0d3d803412bd1dc0da31317d5e769354b5eb3d342c2`.
- High-confidence credential/private-key scan: no matches.

Current temporary artifact:
`/tmp/moontown-release.OCxxsQ/bundle/moontown-0.1.0.dmg`.
Superseded release/install directories were detached and moved to Trash; this
final candidate and its installed smoke-test copy remain available.

Publication-ready local files:

- `/tmp/moontown-release.OCxxsQ/publish/MoonTown-0.1.0-macos-arm64.dmg`
- `/tmp/moontown-release.OCxxsQ/publish/MoonTown-0.1.0-macos-arm64.dmg.sha256`
- [Prepared release notes](release-notes-v0.1.0.md)

## Preserved UI evidence

- [DMG in Finder](ui-release-evidence/dmg-finder.jpeg)
- [Installed town](ui-release-evidence/native-installed-main.jpeg)
- [Installed in-app Guide](ui-release-evidence/native-installed-guide.jpeg)
- [Installed narrow town](ui-release-evidence/native-installed-narrow.jpeg)
- [Installed narrow Dashboard](ui-release-evidence/native-installed-narrow-dashboard.jpeg)

## Handover completion audit

| Handover requirement | Status | Authoritative evidence |
| --- | --- | --- |
| Published Rabbita and Lepusa versions | Pass | Nested `moon.mod` pins Rabbita 0.12.4; root `moon.mod` pins Lepusa 0.1.4 |
| Standalone manifest, icon, least privilege | Pass | Strict Lepusa verification reports one packaged WebView, zero routes/plugins/capabilities, and zero audit findings |
| Product logo and padded macOS icon | Pass | Native title area, app bundle, and Finder DMG were visually inspected |
| Every released page/action/state through UI | Pass | Page inventory and human use cases above; final installed-copy smoke repeated Guide, Dashboard tabs, service selection, inspector transition, Escape, narrow layout, and native close |
| Guide and understandable vocabulary | Pass | In-app Guide plus `docs/UI_GUIDE.md`, including definitions for all four headline metrics |
| Counts, selections, mutations, refresh, restart | Pass | Construction, refund, self-built count, selected states, reset cancel/confirm, and saved town restoration were exercised through the packaged UI |
| Real external integrations | N/A | The released town is a self-contained local simulation with no provider setup, network route, credential form, or sidecar service |
| MoonBit, TypeScript, engine, and adapter gates | Pass | Exact totals recorded above |
| Minimum macOS for all executables | Pass | Only the Lepusa runtime is a compiled service executable; `vtool` reports `minos 11.0` |
| DMG/install smoke/post-launch integrity | Pass | Final DMG mounted read-only, copied out, launched through Lepusa, closed cleanly, and passed post-launch `codesign`; app resources remained unchanged |
| Secret and private data exclusion | Pass | High-confidence scan passed and packaged resources contain only the four release web files |
| Developer ID signing/notarization | Blocked externally | `security find-identity -v -p codesigning` reports zero valid identities; current artifact is explicitly ad-hoc signed |
| Intended commit, tag, and GitHub assets | Not performed | Local and GitHub `main` both point to pre-change commit `3eb2d1a58c1fbb611297eb13f44c50628bed736b`; work remains uncommitted, `v0.1.0` does not exist, and publication was not authorized |

## Remaining release work

- Replace ad-hoc signing with a Developer ID Application identity, notarize,
  staple, and run `spctl`/Stapler verification.
- Publish only after the intended branch/commit/tag are chosen; upload the DMG
  and checksum to the matching GitHub release.
- Lepusa’s direct development command
  `run macos --launch --project lepusa.json` crashed with an invalid-memory
  error. The handover’s bundled-runtime/DMG path works; the framework dev-launch
  issue should still be tracked separately.
- The production manifest correctly has `devtools: false`, so browser console
  and failed-request panels were not directly inspectable in the native
  release window. The shipped page is static and declares no localhost
  services, routes, permissions, or integrations.

External-provider tests and service-readiness checks are not applicable: this
release surface has no external provider configuration and no localhost
sidecar.
