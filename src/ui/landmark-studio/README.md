# Wenyu Landmark Atelier

Standalone, draggable Three.js studies of 未来中心, 未来视界, 未来科学城东路桥 and 未来科学城路桥. The preserved models are also available through the town's map portal.

The source of truth for geometry, proportions and scene composition is MoonBit in `src/models/`. The browser adapter renders a small set of generic geometry commands using Three.js; it does not contain landmark-specific modeling rules. Three.js is the explicitly requested external renderer, not a replacement for the MoonBit application architecture.

## Build and open

From the repository root:

```sh
moon -C src/ui/landmark-studio check
moon -C src/ui/landmark-studio test
moon -C src/ui/landmark-studio info
moon -C src/ui/landmark-studio fmt
moon -C src/ui/landmark-studio build --target js --release
moon run scripts/assemble-landmark-studio.mbtx
python3 -m http.server 17843 --bind 127.0.0.1 --directory src/ui/landmark-studio/web
```

Open `http://127.0.0.1:17843/index.html`. The port is loopback-only. Stop the preview server with Ctrl-C in its terminal. The generated `web/models.js` is ignored; rerun build and assembly after changing model source. No production build or server modification is needed.

## Controls

The [data-center explorer](web/datacenter.html) is available at `/datacenter.html`.
It has five scales (campus → hall → rack → server → motherboard), component
inspection, exploded heatsinks, network/power/cooling teaching paths and a
statistics/report panel. Model geometry, planning calculations and read-only
snapshot validation are MoonBit-owned. Planning estimates and infrastructure
observations are kept separate; no physical placement or sensor values are
invented. Same-origin `/secret-compute-room.json` is optional; a static server
does not provide live telemetry. JSON/CSV reports can be reviewed and copied when
the embedded browser does not support downloads. See
`docs/project/datacenter-threejs-study.md` at the repository root for boundaries,
research, testing evidence and the town-integration plan. This remains an
independent review surface, not a production replacement.

The [G座三层 interior study](web/interior.html) uses a privately held functional plan, with a central atrium, both service cores, room selection, cutaway walls, optional furniture/ceiling and plan/close-up views. Source evidence and proposed fit-out are described separately; the original photograph is not committed or packaged. See `docs/project/wenyu-g3-interior-study.md` at the repository root.

- Drag: orbit horizontally and vertically. Scroll/pinch: zoom. Right-drag/two-finger drag: pan (OrbitControls conventions).
- Focus the canvas: arrow keys orbit; `+` / `-` zoom; Home resets.
- Detail close-ups plus top/front/side/rear camera presets; orthographic projection toggle.
- Daylight, golden-hour and blue-hour lighting.
- Surroundings visibility and neutral clay material; optional slow orbit, off by default.
- Four landmark selectors and an in-app source gallery. Dialog supports Escape and restores focus.

Disable Surroundings to examine undersides without the display ground obstructing the camera. There are no baked facade billboards: all sides are modeled. Unobserved details remain interpretation, not verified reconstruction.

## Rendering

Instanced repeated primitives; custom polygon extrusions and swept arch surfaces; cached geometry; soft directional shadows; an environment map generated locally; ACES tone mapping; live planar river reflections. The display plinth and studio floor are excluded from reflections. Rendering is demand-driven unless orbit is enabled, pauses in hidden tabs, and disposes model-owned GPU resources when switching studies. Pixel ratio is capped at 1.75.

Desktop and 390 × 844 responsive layouts were visually inspected. Seven MoonBit tests cover stable study identity, finite commands/materials, footprint bounds, open bridge carriageways, arch separation, rectangular lattice sections and bridge fittings. Actual browser checks covered all four models, pointer orbit, keyboard orbit/zoom, camera presets, material/context switches, lighting modes, source-gallery images and orthographic plan view. Physical touch hardware and right-button pan were not separately exercised.

## Evidence and fidelity

The source gallery contains 21 reference entries (20 distinct images; the aerial is relevant to both bridges), mixing photographs and explicitly labeled design diagrams. Sources remain on the publishers' servers; a missing connection affects the reference gallery, not the 3D scenes.

The detail pass retains the accepted massing and adds rectangular wave members, arch panel seams, hanger sleeves, railings, walkway joints, drainage grates, Y-shaped lamps and closed girder soffits. Offices now include spandrels, finer transoms, courtyard-facing grids, roof parapets, screened plant equipment, planted roof edges, door/canopy assemblies and project-name signs. Repeated parts are instanced. Equipment, fixing dimensions, signage placement and landscape furniture remain interpretive; the gallery is evidence, not an as-built specification.

See `docs/project/wenyu-signature-landmarks-reference.md` and `docs/project/wenyu-landmark-studio-review.md` in the repository root for provenance and limitations.

World units are nominal meters, Y up, +X east and -Z north. The compass is marked `N* / LOCAL AXIS`: these studies are not georeferenced. The building designs are interpreted from public images; only specific reference dimensions are documented. Bridge approaches are cropped. Site landscaping, pedestrian positions and vehicles are illustrative.

## Third-party code

`web/vendor/` contains unmodified Three.js **0.180.0** files from the npm package distributed by jsDelivr: `three.module.js`, `three.core.js`, `OrbitControls.js`, `RoomEnvironment.js`, `Reflector.js`, and `LICENSE.three` (MIT). These dependencies are local, version-pinned and used only by this standalone viewer. No remote JavaScript is required at runtime. Photo rights remain with their publishers; no source photos are redistributed or used as textures.
