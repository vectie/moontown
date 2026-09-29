# Wenyu signature landmarks — reference design for approval

Research date: 2026-09-06. Status: **reference review only; no models or map integration authorized yet.**

The request lists four landmarks. Treat them as four distinct assets, with the two office developments represented as groups rather than arbitrary single buildings. This is an architectural visualization brief, not a measured reconstruction or engineering model.

## 1. 未来中心 — ordered courtyard offices and a paired-tower landmark

[Official project profile](https://www.kechuangfuwu.com/vue/parkService/project?id=31).

The operator identifies a seven-building office development in the southern part of Future Science City, with courtyard spaces, terraces, roof gardens and a sunken plaza. The profile describes an 80 m twin-tower element; this is not the height of every building. Its planning height limits must not be substituted for measured roof heights.

![Official aerial rendering: Future Center grouping](https://www.kechuangfuwu.com/ueditor/fileupload/file/20240725/1721893738640071636.png)

The aerial image is a **design rendering**, useful for massing, not proof of the current as-built site layout.

[Ground-facing reference photograph](https://www.kechuangfuwu.com/ueditor/fileupload/file/20240726/1721961738519014567.jpg).

Visible signatures: paired rectilinear blocks; pale facade frames against blue/dark glass; strong vertical window rhythm; open planted spaces between buildings. The aerial rendering also shows roof openings and the taller paired element.

Proposed model: a coherent landmark group with separate building children, courtyard voids and an internal landscape axis. Build the major massing and voids first; add selective facade ribs only after the silhouette reads at town zoom. Use warm off-white frames and restrained blue-grey glazing. Do not replace the entire development with two generic towers.

## 2. 未来视界 — rounded glass volumes and orange accents

[Official project profile](https://www.kechuangfuwu.com/vue/parkService/project?id=36).

The operator places this mixed business development at the northern gateway of Energy Valley. It describes glass headquarters offices, colored-glass independent offices and roof gardens. It is a different project from 未来中心.

![Future Vision entrance and rounded glass facades](https://www.kechuangfuwu.com/ueditor/fileupload/file/20240725/1721877653174082537.jpg)

[Second oblique reference: taller volume and lower offices](https://www.kechuangfuwu.com/ueditor/fileupload/file/20240725/1721877554142081908.jpg).

Visible signatures: rounded corners, a taller pale-blue glass volume behind lower curved blocks, irregularly spaced orange/amber vertical panels, rooftop planting and an open entrance court.

Proposed model: rounded rectangular footprints with individually controlled corner radii, a taller glass volume and a small group of lower offices. Preserve the orange accents as sparse geometric strips, not a uniform orange facade. Keep an entrance court and small sign as secondary details. Use broad, calm glass color changes instead of noisy photographic reflections.

## 3. 未来科学城东路桥 — open wave lattice

[Operator's bridge documentation, published 2022-07-13](https://www.kechuangfuwu.com/vue/news?id=7526).

Former project name: 神华规划四路桥. Documented total length: 541 m; main bridge: 217 m. A steel-box deck carries an open wave-shaped spatial lattice above it.

![East Road Bridge: wave lattice and river piers](https://www.kechuangfuwu.com/ueditor/fileupload/file/20220713/1657702803678022077.png)

Proposed model: separate deck, piers, outer wave envelope and crossed lattice members. Establish the changing envelope in side and end views before populating its grid. The openings must remain visibly open. Reduce member density at distant zoom while keeping the wave profile; do not turn it into a solid canopy or a generic semicircular tunnel.

## 4. 未来科学城路桥 — sculptural arch

[Operator's bridge documentation](https://www.kechuangfuwu.com/vue/news?id=7526).

Former project name: 鲁疃西路桥. Documented total length: 568 m. The source describes an irregular arch, a three-span continuous main bridge, hexagonal arch sections and V-shaped piers. Total bridge length is not the visible arch span.

![Science City Road Bridge: white arch and slender hangers](https://www.kechuangfuwu.com/ueditor/fileupload/file/20220713/1657702803493014474.png)

Proposed model: a custom swept, tapered arch profile, a separate deck, slender hangers and shaped piers. Preserve the arch's changing depth and curvature. Avoid a constant-radius tube or a cable-stayed pylon substituted for the actual arch. Exact hanger spacing and cross-sections remain provisional until additional views or drawings establish them.

## Shared art direction — proposal, not a sourced fact

Use **recognizable real architecture in the town's soft miniature-world style**. The evidence-first UI/UX review determines what must survive simplification: silhouette, open space, proportions and material grouping before small surface detail.

- One sun direction, shadow softness and restrained palette across all four models.
- Geometry that reads in three dimensions from every side, not a facade image rotated to suit one camera.
- Modest edge softness; retain sharp structural logic where it defines the landmark.
- No baked-in photo shadows, water reflections or perspective distortion.
- Keep buildings, planted courts and bridges at coherent relative scales. Do not enlarge landmark meshes independently to solve readability problems; review map-level scale compression explicitly.
- Distinguish close inspection from town-distance detail. Windows, railings and lattice members should not become visual noise at the intended camera distance.

## Standalone Three.js review — only after approval

Proposed deliverable: an isolated four-landmark study viewer, not a change to the live town.

1. Begin with grey massing: top, side, end and orbit views, plus a scale grid and north indicator.
2. Review each silhouette against its reference image. Camera matching must not distort the model to reproduce a photograph's perspective.
3. Add the shared town material and lighting treatment; compare neutral geometry and stylized views.
4. Include both perspective inspection and the town camera's intended projection. Diagnose alignment in model/world space separately from camera settings.
5. Offer a four-asset overview and focused single-asset inspection, with keyboard-accessible controls and no compulsory auto-rotation.

Suggested authoring convention: meters, Y up, +X east, -Z north. Store footprint and geographic bearing separately from viewer camera state. For later integration, use the map's calibrated local geographic basis at each asset, not the angle of a photograph or one global screenshot rotation. Bridge alignment is constrained by both road endpoints, deck elevation and bank clearances; it must not require shifting the approved road network.

Suggested implementation split: MoonBit-owned landmark parameters, entity metadata and scene assembly; a narrow Three.js rendering adapter. Keep the research viewer separate from the production renderer. Decide whether production consumes geometry or a pre-rendered atlas only after the 3D review; this brief does not select or install a new production dependency.

Each future landmark asset should carry an ID, real name, reference provenance, model version and geometry children. Building children should retain entrance/footprint metadata; bridges should expose abutments, deck centerline and clearance metadata. Visual reference buildings must not silently become invented live organizations, agents or operational facilities.

## Confidence, missing evidence and approval gate

High confidence: the identities of these four projects, their distinctly different architectural languages, the two bridge aliases and the cited bridge lengths. The six linked images were visually inspected; the Future Center aerial is explicitly treated as a rendering.

Not yet verified: surveyed footprints, exact geographic bearings, detailed floor heights, rear elevations, complete bridge transverse geometry, exact arch rise and lattice spacing. Photo perspective does not establish these measurements. The current source set is sufficient for an approved stylized study, not a survey-grade digital twin. Resolve missing dimensions with plans, orthophotos or clearly marked provisional parameters in the next phase.

Reference photographs/renderings remain owned by their respective rights holders. Links are for design review; do not ship them as textures or redistribute them as project assets without permission or an appropriate license.

Approval requested: confirm these four identities, the two developments as landmark groups, and the shared soft-miniature art direction. Then build the standalone Three.js studies. **Map integration requires a subsequent review; no model code, dependency changes or map placement are part of this reference-only step.**
