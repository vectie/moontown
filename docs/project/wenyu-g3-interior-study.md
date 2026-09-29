# Future Center G / Level 3 — reference-plan interior study

Source: user-supplied local floor-plan photograph, inspected on 2026-09-06. A local unchanged copy may be kept as `src/ui/landmark-studio/web/interior-reference.jpg` for private review. It is ignored by Git and excluded from public release assets; the public viewer does not request it.

Preview: `http://127.0.0.1:17843/interior.html`. This is a **new standalone interior model**, not a patch to the generic courtyard model and not a replacement of the live town indoor layer yet. The four exterior studies remain independently available.

## What the photograph establishes

The photographed board is titled “未来中心G座 三层功能分区”, under the Changping youth talent demonstration-district heading. It is a functional floor plan, not an interior rendering or a measured CAD drawing.

Preserved relationships:

- Asymmetric outer boundary, with the upper-right wing extending beyond the upper-left wing.
- A long central atrium/void, with circulation around it. No third-floor slab or furniture fills it.
- Two lift/stair/restroom service cores at opposite ends of the atrium.
- North/upper edge: 306 enterprise office, 307 split into two public meeting rooms, 308 欧中创新中心 office; 309 and 310 associated with the roadshow hall; 301 at the upper right.
- South/lower edge: 305 office/venture investment consultation partitions; 304 split into five independent rental offices; public exchange/rest/water-bar zone; 303 and 302.

The viewer records 14 parent zones, including both cores, the water bar and the atrium. It preserves subdivision IDs `304-1` through `304-5` and `307-A/B` in the model data. Parent zones are currently selectable; these are proposed local semantic identifiers, not connections to existing live agents, rooms, leases or tasks.

## What remains uncertain

Photo perspective was squared into an orthogonal schematic using manually selected image coordinates. A presentation factor of 0.06 converts photograph coordinates to model units. It is **not a calibrated physical scale**, and model floor areas must not be compared directly with the printed areas. No north bearing is inferred.

Printed areas are retained as source annotations, not model calculations. Room 305's area is obscured and is not invented; 307's apparent 116.44 m² reading is marked for verification. The exact extension of 306 into the western area, hall divisions, doorway dimensions and service-core details need confirmation.

The photograph does not specify finishes, furniture, lighting, wall heights or current tenants. This pass proposes oak desktops, muted sage/rose floor zones, glazed office fronts, pale walls, task chairs, monitors, conference tables, soft seating, planting, a water counter and roadshow furniture. Rooms 301–303 explicitly retain “function to be confirmed”; their furnishing is optional fit-out, not evidence of current use.

Wall height 3.3, fixture sizes, lift doors, stair flights and accessible clearances are visual assumptions. This is not a construction, capacity, accessibility, fire-egress or engineering-certified model. Ceiling/wall cutaway changes are inspection aids, not changes to the underlying layout.

## Architecture and interaction

MoonBit owns the traced plan, room evidence/proposals, partitions, openings, cores and furniture. New cohesive files are `interior_plan.mbt`, `interior_shell.mbt`, and `interior_furniture.mbt`. `interior_study() -> Json` is an intentional additional public export; the four-study `studies()` contract is unchanged.

The generic Three.js adapter now supports named model layers and per-instance semantic captions. The interior viewer uses these for floor-zone picking and furniture/wall/ceiling visibility. Repeated furniture is instanced. Geometry is not replaced with flat reference-image billboards.

Controls: drag to orbit; wheel to zoom; right-drag to pan; arrow keys to orbit; plus/minus to zoom; Home to reset. Choose a parent room, then “查看此空间” for a close-up, or double-click its label. Switch between 3D, orthographic plan and reverse views; toggle wall cutaway, furniture, labels and ceiling; switch daylight/warm light. The original image is available in a modal dialog. No animation runs continuously while the view is idle.

The UI/UX skill prioritized direct inspection and explicit separation of evidence from design proposals. The MoonBit skill kept model construction and verification in the MoonBit module; the browser is the requested rendering boundary.

## Validation

Module tests: 11 passing, including the seven exterior tests plus interior provenance, atrium slab exclusion, furniture exclusion from the atrium, and the five/two independent door openings. MoonBit check, info, formatting, release build and assembly are required for handoff.

Desktop visual review covers the furnished whole floor, five-office close-up, orthographic bare plan, source image, layers, lighting and camera orbit. No runtime JavaScript errors were observed in the checks. Physical touch, mobile hardware, measured clearances and actual building correspondence beyond this photograph remain unverified.

Next gate: user review of the spatial topology and fit-out. Only after approval should this become a reusable interior scene and be bound to real Moontown room/agent/workflow entities. Production indoor assets, roads, underground scenes and backend entities were not changed in this pass.
