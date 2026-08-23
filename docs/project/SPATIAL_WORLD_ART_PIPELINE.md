# MoonTown Spatial World Art Pipeline

## Decision

Outdoor, indoor, and underground are three views of one world. They share a
fixed isometric camera, blue-grey outline grammar, matte light/shadow faces,
soft contact shadows, spring civic colors, and the same resident sprite family.
Indoor and underground must not fall back to dashboard cards simply because
their data is operational.

The browser implementation remains MoonBit. MoonBit owns scene selection,
semantic projection, draw order, interaction, accessible controls, and Canvas
lifecycle. Raster plates are art assets, not an alternate application runtime.

## Structural plate versus semantic entity

Each graphical layer has two strictly separated parts:

1. A structural plate supplies the physical place: walls, windows, floor,
   rock, masonry, pipes, ventilation, fixed lighting, trenches, and plants.
2. MoonBit draws semantic props above it: `InteractionSlot` furniture,
   `ActorPresence` residents, runtime Agent consoles, LunaNexa racks, MoonGate,
   and remote routes.

Structural plates may never contain a resident, Agent, rack, provider terminal,
credential, status, label, or other object that could be mistaken for system
evidence. An empty projection therefore produces an architecturally complete
but semantically empty room.

Text does not float inside the world. Transparent keyboard-focusable hotspots
own the accessible entity name and selection target, while a separate roster or
inspector owns detailed evidence. Color is never the only state signal.

## Assets and provenance

The versioned structural plates are:

- `src/ui/assets/tilemap/rooms/moontown-spatial-v2/indoor-empty-room.jpg`;
- `src/ui/assets/tilemap/rooms/moontown-spatial-v1/underground-empty-room.jpg`.

They were generated as new raster assets with the existing MoonTown outdoor
spring-civic scene as the visual reference, then visually inspected in their
final local form. Delivery copies use compact JPEG encoding to keep the
deterministic static product compact. The original generated PNG encodings
were removed after conversion; no semantic information was lost because the
plates are opaque backgrounds.

Prompt set used for the two plates:

> Create an empty isometric cutaway civic interior background plate matching
> MoonTown's soft hand-painted spring-civic world: warm ivory walls, pale stone
> floor, blue-grey outlines, restrained cyan glazing, wood accents, plants,
> matte two-value faces, and soft late-morning light. Keep one coherent 2:1
> isometric camera. Show only fixed architecture. No people, furniture,
> computers, machines, text, icons, labels, or UI. Leave the floor open for
> runtime-drawn semantic props.

> Create an empty isometric cutaway underground compute-room background plate
> in the same MoonTown spring-civic illustration family: excavated rock canopy,
> blue-grey masonry structure, warm work lights, fixed pipes and ventilation,
> pale service floor, cable trenches, and soft matte shadows. Keep one coherent
> isometric camera. Show only architecture. No people, Agents, desks, consoles,
> racks, servers, terminals, provider marks, text, icons, labels, or UI. Leave
> the floor open for runtime-drawn semantic props; avoid neon and cyberpunk.

The transparent semantic-prop assets live under
`src/ui/assets/tilemap/props/moontown-spatial-v2/`:

- `indoor-furniture-atlas.png` — eight `InteractionKind` forms;
- `compute-props-atlas.png` — empty/occupied racks, MoonGate, Agent console,
  remote terminal, and service cabinet;
- `route-terminal.png` — a clean single-cell crop used by each real
  `SecretComputeRemoteRoute`.

The exact generation prompt for the indoor atlas was:

> Use case: stylized-concept. Asset type: transparent isometric game-prop
> atlas for MoonTown's indoor semantic world. Input images: Image 1 is the
> indoor room camera/material reference; Image 2 is the outdoor MoonTown line,
> palette, and simplification reference. Primary request: create exactly eight
> separate civic furniture cutouts arranged in a precise 4-column by 2-row
> contact sheet. Top row, left to right: compact policy workstation with desk,
> monitor and two chairs; round civic meeting table with four chairs;
> staffed-style exchange counter with no person; small service/inspection
> podium. Bottom row, left to right: glass exhibit plinth; wood-and-blue-grey
> public bench; low civic speaking stage with a modest backdrop; secure transit
> gate with two posts and overhead beam. Style/medium: polished hand-painted
> isometric game assets matching MoonTown, matte two-value faces, blue-grey
> outlines, warm ivory and wood, restrained cyan, muted gold accents, soft
> contact shadows. Composition/framing: identical 2:1 isometric camera for every
> object; each object centered in an equal cell with generous transparent
> padding; consistent footprint scale; no overlap between cells. Constraints:
> genuinely transparent background and preserved alpha; objects only; no room,
> wall, floor tile, people, agents, labels, text, icons, logos, watermark, UI,
> border, grid lines, or cell dividers.

The exact generation prompt for the compute atlas was:

> Use case: stylized-concept. Asset type: transparent isometric game-prop
> atlas for MoonTown's governed underground compute room. Input images: Image 1
> is the underground room camera/material reference; Image 2 is the MoonTown
> line, palette, and simplification reference. Primary request: create exactly
> six separate infrastructure cutouts arranged in a precise 3-column by 2-row
> contact sheet. Top row, left to right: an empty physical server-rack frame
> with visible vacant rails and no equipment; an occupied server rack with five
> clearly installed blue-grey compute units, restrained cyan status lights and
> closed sides; MoonGate as a circular ivory-and-cyan governed routing console
> on a sturdy hexagonal plinth. Bottom row, left to right: compact Agent
> operations console with monitor, control desk and one chair but no person;
> remote uplink terminal kiosk with a small abstract signal display but no logo
> or text; low cable patch cabinet and service trolley. Style/medium: polished
> hand-painted isometric game assets matching MoonTown, matte two-value faces,
> blue-grey outlines, warm ivory, subdued steel, restrained cyan and muted gold,
> soft contact shadows, not cyberpunk. Composition/framing: identical 2:1
> isometric camera for every object; each object centered in an equal square
> cell with generous transparent padding; consistent footprint scale; no
> overlap between cells. Constraints: genuinely transparent background and
> preserved alpha; objects only; no room, rock, wall, floor tile, people,
> agents, labels, readable text, provider logos, watermark, UI, border, grid
> lines, or cell dividers; the empty rack must visibly be an unoccupied frame,
> while the occupied rack must visibly contain installed machine units.

The reference inputs were `indoor-empty-room.jpg`,
`underground-empty-room.jpg`, and the visually verified outdoor capture
`tmp/ui-qa/moonpoly-layers/outdoor-final.png`.

Both generated contact sheets initially contained a painted checkerboard. The
exact indoor extraction prompt was:

> Use case: background-extraction. Asset type: transparent isometric game-prop
> atlas. Input images: Image 1 is the edit target. Primary request: remove only
> the gray-and-white checkerboard background and replace it with genuine
> transparent alpha. Constraints: preserve every furniture object exactly,
> including its position, scale, 4-column by 2-row layout, outlines, colors,
> plants, glass, and soft contact shadows; keep the full canvas dimensions and
> framing unchanged; do not redesign, move, add, crop, merge, or relight any
> object; no background fill, grid, text, border, logo, or watermark.

The exact compute extraction prompt was:

> Use case: background-extraction. Asset type: transparent isometric game-prop
> atlas. Input images: Image 1 is the edit target. Primary request: remove only
> the gray-and-white checkerboard background and replace it with genuine
> transparent alpha. Constraints: preserve every infrastructure object exactly,
> including its position, scale, 3-column by 2-row layout, empty-rack rails,
> installed rack units, MoonGate ring, consoles, cables, outlines, colors, and
> soft contact shadows; keep the full canvas dimensions and framing unchanged;
> do not redesign, move, add, crop, merge, or relight any object; no background
> fill, grid, text, border, logo, or watermark.

Alpha was checked on the final files before integration. The remote terminal
was then cropped from its atlas cell without changing its pixels because the
generated cell overlapped the adjacent service cabinet at runtime crop
boundaries.

After live compositing exposed inconsistent yaw between otherwise matching
furniture, the indoor atlas was corrected with this exact edit request:

> Use case: precise-object-edit. Asset type: transparent isometric game-prop
> atlas for MoonTown indoor scenes. Input images: Image 1 is the edit target
> furniture atlas; Image 2 is the authoritative camera, floor-grid, lighting,
> material, and line-style reference. Primary request: redraw the same eight
> furniture objects from Image 1 so every object uses exactly one locked 2:1
> isometric camera and the same world axes as the floor grid in Image 2.
> Normalize yaw and mirroring across the entire atlas. Orientation lock: camera
> looks from the front/south corner toward the back/north corner, exactly as in
> Image 2. Every rectilinear object's footprint edges must be parallel to one of
> the two diagonal floor-grid axes in Image 2. For every object with a
> user-facing side—the workstation monitor/visitor-chair side,
> exchange-counter service side, service podium front, bench seat front, stage
> audience side, and transit-gate entry face—that functional front must face
> the lower-left/front side of its cell. The perpendicular depth axis must
> recede toward the upper-right. Do not mirror or rotate individual objects to
> alternate viewpoints. Circular meeting table and exhibit plinth must still
> obey the same chair/base axis. Layout invariants: preserve the exact 4-column
> by 2-row cell order: top row workstation, meeting table, exchange counter,
> service podium; bottom row exhibit plinth, bench, speaking stage, transit
> gate. Center one complete object in each equal cell with generous transparent
> padding and no overlap. Style invariants: preserve MoonTown's polished
> hand-painted spring-civic style, blue-grey outlines, matte ivory and wood
> faces, restrained cyan glazing, muted gold accents, plants, object scale
> family, and soft contact shadows. Match Image 2's light direction.
> Constraints: genuinely transparent background and preserved alpha; furniture
> objects only; no room, walls, floor tiles, people, agents, labels, text,
> icons, logos, watermark, UI, border, checkerboard, grid lines, or cell
> dividers. Do not add, remove, merge, crop, or substitute any furniture type.

The corrected sheet was passed through the same background-extraction step and
verified to retain genuine alpha before replacing the runtime atlas.

Live compositing then proved that correcting the prop sheet alone was not
enough. The first indoor plate used a shallower architectural-illustration
camera, finer outlines, and flatter materials than the corrected atlas. The
v2 indoor plate was therefore generated as part of the same scene kit, with
the corrected furniture atlas as the authoritative camera and style reference.
The old room supplied architecture and layout ideas only.

The exact v2 room-generation prompt was:

> Use case: stylized-concept. Asset type: empty isometric cutaway indoor room
> background plate for the MoonTown game UI; runtime furniture and agents will
> be composited onto it. Input images: Image 1 is the authoritative master for
> camera, projection, viewing direction, object proportions, outline weight,
> palette, materials, and lighting. Image 2 is architecture/layout inspiration
> only; do not copy its shallower camera or fine architectural-rendering style.
> Redraw an empty civic-policy room shell built for the furniture atlas in
> Image 1. Use a locked orthographic 2:1 isometric projection: each floor axis
> rises one canvas unit for every two horizontal units, both floor axes are
> symmetric, world verticals stay canvas-vertical, and there is no perspective
> convergence. Use the same moderately thick blue-grey outlines, beveled game
> forms, warm ivory and honey wood, restrained cyan glass, slate-grey bases,
> compact detail, and upper-left lighting as Image 1. Show two cutaway rear
> walls, broad open pale-stone floor, windows, a centered rear doorway, shallow
> built-in shelves, recessed planters, and wall lamps. Keep the playable floor
> empty. No free-standing furniture, racks, people, agents, text, labels, UI,
> logos, watermark, loose oblique camera, tilted verticals, or baked floor
> props.

The generator initially produced a black exterior field. It was corrected with
this precise edit while preserving the room geometry:

> Replace only the solid black area outside the cutaway room with a uniform
> very pale warm ivory-white canvas (`#f7f6f0`). Preserve every pixel of the
> room architecture, floor, front edge, windows, plants, lighting, shadows,
> projection, viewing direction, composition, scale, and crop. Do not add or
> alter any object, text, logo, or watermark.

Generation references and outputs:

- authoritative reference:
  `src/ui/assets/tilemap/props/moontown-spatial-v2/indoor-furniture-atlas.png`;
- architecture-only reference:
  `src/ui/assets/tilemap/rooms/moontown-spatial-v1/indoor-empty-room.jpg`;
- built-in generated source:
  `/Users/kq/.codex/generated_images/01a01de0-d078-7bc1-a44f-331c9b111d43/exec-d54da366-ad27-423c-971e-e9a4cf1d383e.png`;
- built-in exterior-field correction:
  `/Users/kq/.codex/generated_images/01a01de0-d078-7bc1-a44f-331c9b111d43/exec-16dfcfd1-4b7c-40ff-9e71-6cf09476d32d.png`.

The transparent sheet is not an acceptance surface. Live room compositing
showed that an atlas can look coherent by itself while still appearing pasted
on when its elevation, baseline, contrast, and draw order do not match the
plate. The delivery atlas therefore removes isolated alpha components left by
extraction, and the MoonBit renderer applies the room calibration below.

## Rendering and layout rules

- Draw the plate first, then governed connections, semantic props, and Agents.
- Repaint the whole scene after an image or sprite becomes ready and after a
  canvas resize; never let a late plate load cover already-drawn entities.
- Indoor furnishing kind follows `InteractionKind`. The contract `WorldPoint`
  influences placement, but coincident civic-map points are collision-resolved
  into stable kind-specific furnishing bays.
- All indoor props share one camera-axis contract: footprints follow the room
  plate's two diagonal floor-grid axes, functional fronts face the lower/front
  side of their atlas cell, and depth recedes upper-right. Individual props may
  not be mirrored or yawed to an alternate isometric viewpoint.
- Each atlas cell has a measured floor-contact baseline. The renderer aligns
  that baseline—not the cell rectangle—to the semantic `WorldPoint` anchor.
- The v2 indoor plate and indoor atlas share one camera and rendering family,
  so props draw at their native aspect ratio and color. Do not reintroduce
  per-scene skew, vertical compression, or color compensation.
- Props and their occupying Agents are depth-sorted by projected floor
  position. Contract array order must never become accidental visual z-order.
- Occupancy comes only from `ActorPresence.interaction_slot_id`.
- Underground machines and routes come only from the redacted compute-room
  projection. Missing evidence stays missing.
- Four empty rack frames are fixed physical capacity. A projected
  `SecretComputeMachine` replaces its corresponding frame with the occupied
  rack cell; installed server units are never drawn without machine evidence.
- Agent requests connect to MoonGate, never directly to a rack or provider.
- The accessible hotspot geometry must use the same projection function as the
  Canvas prop beneath it.
- The mobile breakpoint scales the same world down and moves evidence below it;
  it does not substitute a different card-based representation.

## Verification checklist

For each change:

1. Run `moon info` and `moon fmt`.
2. Run the spatial journey and compute-room MoonBit tests.
3. Build and verify the deterministic browser product.
4. Open outdoor, a populated indoor building, and underground through the real
   desktop service at 1440×900.
5. Repeat indoor and underground at 400×900.
6. Confirm every visible semantic object has a real stable identity and every
   real visible identity has a focusable control or inspector entry.
7. Confirm empty machine/Agent projections do not grow decorative substitutes.
8. Judge prop quality only in the full room composite. Reject visible alpha
   debris, floating baselines, mismatched elevation, pasted-on contrast, or
   incorrect front-to-back occlusion even when the standalone atlas looks good.
