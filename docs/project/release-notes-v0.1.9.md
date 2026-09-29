# MoonTown 0.1.9 release candidate

This release integrates the Wenyu scene calibration, the preserved MoonBit
landmark studies, and local navigation previews into the Energy Valley town.
The public map can open the original 3D landmark studies, the G3 interior
study, and the multi-scale data-center study without leaving the town.

The road and building layers now use bounded, deterministic placement and
share the reviewed scene registration. Navigation uses the packaged OSM-node
graph, with pause, resume, and stop controls. It is a local demonstration, not
remote-agent execution or certified pedestrian routing. The 3D interiors and
data-center are design studies, not verified physical rooms or equipment.

The original user-supplied floor-plan photograph and the diagnostic SVGs that
embed private planning imagery are not committed or packaged. Their local
copies remain available for private review. Third-party Three.js 0.180.0
modules are bundled with the MIT license and do not require a runtime CDN.

## Verification

- MoonTown native tests: 1,207 passed.
- Landmark-studio JS tests: 17 passed.
- New town interaction and scene JS tests: 41 passed.
- Production browser build: 302 files, 71.1 MiB, artifact verifier passed.
- Browser smoke: map, indoor selection and return, data-center portal, route
  start/pause/stop and visible progress worked; no browser error logs.
- The complete Rabbita JS test run is still under investigation because it
  did not complete in a reasonable time. This candidate must not be promoted
  to a fully verified stable release on the strength of the focused tests.

The macOS artifact uses ad-hoc signing. It is not Developer ID notarized or
stapled. Real MoonClaw/MoonGate/LunaNexa integrations and the managed public
service require separate environment and end-to-end acceptance; this release
does not claim those integrations were exercised.

## macOS artifact

- Disk image: `moontown-0.1.9.dmg` (Apple silicon, 67 MiB).
- SHA-256: `494a04e3c596c2727f225241dec3eaceba05eb1923dd02f2c21e1fc30306d4b2`.
- The disk image checksum and the app signature inside the mounted image were
  verified. The signature is explicitly ad-hoc, not a trusted Developer ID.
