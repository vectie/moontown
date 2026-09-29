# Town scene generation: a coherent game-world foundation

## Current authority: fit OSM to the design

Latest follow-up: [global camera and registration audit](town-global-calibration.md).
The local-warp candidate below is still unaccepted. A fresh direct affine fit
and a full perspective fit were tested without that warp; neither passed
whole-map checks, and neither was applied to the live scene.

The designed town is the target, not the present-day geographic map. Preserve
the authored terrain, water, and art. Keep OSM evidence immutable, but derive
separate design-space road coordinates. The earlier proposal to replace the
terrain with geographic water boundaries was rejected by the user.

## Diagnosis

The spring architectural kit has a recognizable identity, but the outdoor
composition was exposing its authoring machinery. The main problems were in
generation and rendering contracts, not a shortage of decorative assets.

| Problem found | Change made |
| --- | --- |
| Projected road centerlines were stroked in screen pixels, including minimum pixel widths. Roads looked like cables and changed relative scale while zooming. | Stroke complete surfaces in the town's world-to-screen ground transform. Primary/secondary/local widths are 1.50/1.15/0.80 world units, including sidewalks. |
| Placement reserved centerline cells, not road width. | Build conservative corridor cells from the same width rules; reject footprints and aprons intersecting those cells. |
| All procedural buildings occupied a 5×5 lot regardless of archetype. | Use 3/4/5-unit square masses for small homes/towers, courtyard/row/block, and campuses/civic/industrial respectively. Keep curated five-unit landmarks intact. |
| Candidate limits were consumed before rejected legacy placements were removed. | Relocate and validate legacy candidates first; infill counts only accepted buildings. |
| Infill scanned north-to-south and chose styles from collection length. | Distribute candidate order across the map using a coprime permutation; choose related architectural styles by stable neighborhood coordinates. |
| IDs/cache keys included literal `{...}` placeholders. | Use actual MoonBit interpolation for source IDs, grid IDs, graph identity, and snapshot cache keys. |
| Permanent procedural/vector buildings mixed with the authored illustration kit. | Use the authored kit for infill; retain procedural drawing as an asset-loading/error fallback. |
| Dashed lot rectangles, junction dots, and coordinates appeared in the normal town. | Landscape lots with planted borders and stone plinths. Gate coordinate/junction overlays on Map Lab state. |
| Individual dark forest squares, per-tile variation, and repeated water gradients overwhelmed the architecture. | Use low-frequency lawn shading, light woodland ground, sparse water highlights, and larger, thinned background canopies. Explicit user-planted trees remain intact. |
| Road-fronting lots had no visible connection. | Draw a short ground-plane approach to the nearest reviewed road before the street surface pass. |

## Generation contract

1. Read the immutable geographic graph and semantic snapshot.
2. Preserve exact geographic coordinates as source evidence. Apply the shared
   design-space registration to nodes, paths, and bridge spans, then derive
   road surface corridors from world-unit widths. Do not independently rotate
   the camera or move the terrain. Preserve the complete source graph while
   matching candidates; do not hide unmatched roads or invent bridge evidence.
   Keep all road ranks visible at every zoom; only markings lose detail.
3. Reserve curated lots, then admit source/infill lots only after terrain,
   road frontage, corridor clearance, and inter-lot overlap checks pass.
   Water, wetlands, and reference woodland remain exclusions. The 96-building
   infill budget is a ceiling, never a density quota that overrides exclusions.
4. Assign a stable neighborhood kit and proportional square footprint. Never
   rotate or non-uniformly stretch an already rendered building sprite.
5. Draw ground, landscaped lots/approaches, and streets using the same 2:1
   dimetric projection: X=(32,16), Y=(-32,16), then apply camera zoom/translation.
6. Depth-sort buildings, actors, and vegetation by their world ground anchors.
   Keep backgrounds subdued so architectural silhouettes carry the hierarchy.
7. Add interaction UI separately. Authoring overlays belong to Map Lab.

`town_scene_generation.mbt` owns the MoonBit scale, neighborhood, candidate
distribution, and landscape rules. Existing Canvas/asset bridges remain the
browser boundary. No new raster assets, dependencies, or standalone JavaScript
generation scripts were added. Derived terrain/placement caches remain bounded
to their active key; offscreen lots are culled before approach rendering.

## Boundaries and remaining work

This is a **2.5D scene improvement**, not a conversion to a real-time 3D engine.
The current buildings are pre-rendered illustrations. Their camera, material,
and light directions are documented in the existing asset manifest, but that
manifest alone cannot prove every painted edge obeys a mathematical camera.
Future asset production should use one orthographic 3D prefab/camera/light rig,
exporting footprint, pivot, entrance socket, height, and collision envelope
alongside each render. Review prefabs together on a shared ground plane, not
as isolated thumbnails. Avoid generating independent backgrounds and props
and trying to repair their perspectives afterward.

The active outdoor view still combines a reviewed **display road graph** with
the legacy semantic snapshot. Decorative infill and road walkers do not become
real places, working agents, or navigation authority through these changes.
The new approach paths are landscaping, not accepted walkability edges or
verified entrance sockets. A subsequent authority migration must compile
roads, parcels, entrances, collision, and actor routes into one shared scene
model before claiming agents navigate these displayed buildings.

Shorelines still inherit the coarse tile/reference outline and boardwalk
segments. A continuous terrain/shore mesh is the next substantial visual
improvement. It should preserve water/land authority and bridge registration,
not replace the town with another disconnected background image.

## Verification

- Added six focused regression tests covering world widths/corridor clearance,
  graph preservation, candidate distribution, bounded archetypes, scaled lot
  reservation, landscape stability, and real cache-key interpolation.
- Existing preview-placement, road-graph, and canvas-frame suites were run.
- Focused result: 26 tests passed (6 scene-generation, 10 preview-placement,
  2 road-graph, 8 canvas-frame).
- Browser checks used the built local product at desktop and 390×844 sizes;
  reviewed scene placement counters and horizontal overflow, not a mockup.
  The final local scene reported 61 image-backed buildings, zero invalid lots,
  zero overlapping lot pairs, and no horizontal document overflow on mobile.
- `build-rabbita-ui.sh` performs formatting, checking, interface generation,
  release build, assembly, and asset verification. No asset-budget increase.
- The full repository test suite is not claimed as run for this scene change.

The UI/UX review skill shaped the work around the existing spring art direction
and rendered desktop/mobile evidence; the MoonBit guide kept generation rules
and regression tests in the existing frontend module.

## Correction: preserve location and the complete road network

This section records the preceding correction. The subsequent user decision
below changes the target coordinate authority from source geography to design.

The attempted inverse-yaw fix was a regression. The source calibration angle
`22.924436871°` describes geographic registration **already applied** to the
source coordinates. It is not an additional road-camera rotation to remove.
Rotating roads around (128,72) moved their locations relative to terrain and
curated landmarks, changed generated lot placement, and pushed boundary paths
outside the visible terrain. Earlier tests checked rigid rotation and source
immutability, which did not prove correct display locations.

Terrain's `golden_screen_x/y` and the road Canvas matrix already share
X=(32,16), Y=(-32,16). The world-space stroke correction remains valid and is
retained. Geographic diagonals and curves must not be forced onto tile axes.

The display compiler now copies source millitile coordinates without rotation,
rounding, endpoint replacement, node merging, or edge deduplication. It retains
loops, parallel streets, isolated nodes, every polyline vertex, and bridge
slices. Cache version 5 (`source-geography-v1`) invalidates the displaced graph.
Corridors, decorative approaches, lot validation, and display walkers consume
that same exact derived geometry.

The renderer also previously hid secondary and local streets below zoom 0.34.
It now retains every rank at every zoom; viewport culling remains, and fine
lane markings can still disappear. This preserves the network rather than
turning an overview into a trunk-road diagram.

`town_scene_registration.mbt` is now a source-parity audit, not a transform.
On graph creation it checks every node coordinate, source-edge identity,
connectivity, path vertex, and bridge slice. It publishes counts and mismatch
diagnostics to the document dataset for browser verification. Regression tests
include nonzero calibration metadata, curved and parallel paths, a self-loop,
coincident/isolated nodes, endpoint offsets, cache reuse, and deliberate
corruption to prove that equal counts alone cannot pass a shifted graph.

The source asset and semantic navigation authority remain unchanged. This
guarantees fidelity to the reviewed display dataset, not survey accuracy or
authority over the coarse terrain shoreline.

Verification for this correction:

- 28 focused tests passed: source registration/parity (2), road graph/zoom (2),
  scene generation (6), preview placement (10), canvas frame (8).
- The production build and asset verification passed: 275 files, 68.2 MiB.
  Generated public interfaces were unchanged.
- The rebuilt browser reported exact parity: 495/495 nodes, 775/775 edges,
  3,980 polyline vertices, 22 bridge spans, zero node/edge mismatches.
- Browser screenshots were reviewed at neighborhood and zoomed-out town
  scales. The smaller-road network remains visible in the overview.
- Placement reported 61 image-backed buildings, zero invalid building lots,
  and zero overlapping pairs. The full repository suite was not run.

## Design-targeted registration: candidate, not accepted final alignment

`design_registration/` is a pure MoonBit numerical package. It fits a regular
8-tile triangular displacement mesh toward the unchanged design road/bridge
rows, excluding water from ordinary-road matching targets. Its limits are:

- Fixed outer perimeter, maximum 10-tile displacement, and triangle area ratio
  at least 0.4. Rejecting local updates that violate these limits prevents
  mesh folds and collapse. No source intersections or edges are merged.
- Laplacian regularization discourages the extra bends seen in the first
  browser-reviewed candidate. Fine-scale fits are not allowed to win merely
  by improving nearest-corridor distance.
- Source segments are split at vertical, horizontal, and diagonal mesh edges.
  This maps the entire polyline piecewise-affinely, rather than drawing chords
  between independently transformed endpoints. Shared endpoints remain shared.
- Road widths, lot clearance, access decoration, and display walkers use the
  same resulting graph. Source coordinates and original vertex indices remain
  attached to each displayed node/edge; original bridge evidence is retained.
- All source/design/terrain identities participate in fit caching; an explicit
  registration revision invalidates downstream placement/frame caches.

The fit is **geometric candidate matching**, not verified landmark matching or
a claim that current and planned road topology are identical. The latest fit
reduces RMS candidate-corridor distance from 5.261 to 4.338 tiles and sampled
non-bridge water-conflicting edges from 96 to 72. These residuals are material:
the map is not yet fully aligned. Do not manufacture bridges or erase source
roads merely to get a zero-conflict score. A reviewed correspondence pass and,
where current and future circulation truly differ, explicit design overrides
are still needed.

Map Lab identifies the fit as pending review and overlays original OSM paths
as orange dashes and water-conflicting fitted portions in rose. Normal terrain
and raster assets are unchanged. DOM diagnostics distinguish preservation of
source evidence (`townSourceEvidencePreserved`) from intentionally changed
display coordinates (`townSourceGeometryExact=false`) and mapping consistency
(`townDesignRegistrationValid`).

Regression coverage includes immutable source/design/terrain inputs, complete
775-edge/495-node/291-cycle connectivity, original vertex correspondence,
bridge mapping, fixed boundaries, positive mesh areas, displacement bounds,
invalid-input identity fallback, exact segment splitting, and cache reuse.
This is presentation only: the old semantic navigation graph is not silently
promoted into an accepted future-design road network.

Verification: 42 focused tests pass (4 numerical registration, 3 graph
registration, 6 scene generation, 2 graph/zoom, 10 placement, 8 canvas frame,
9 Map Lab). Production assembly verifies 275 files / 68.3 MiB. The browser
reports 58 image-backed buildings with zero invalid lots or overlapping pairs.
The only new public interface is the cohesive numerical registration package.
The full repository suite was not run.

Use `?scene=6&registration-review=1` for the read-only road comparison, without
opening or granting access to operational Map Lab. This preview intentionally
remains `candidate-needs-review`, not a claim of completed design alignment.

## Botanical variation in the production town

Woodland installations now use six illustrated silhouettes: broad oak, narrow
poplar, tiered pine, drooping willow, flowering cherry, and fan-crowned ginkgo.
Stable tile/installation seeds select local grove palettes and modest size
variation; nearby water favors willows. These are presentation choices, not
new species assertions or changes to semantic installation identities.

Four sparse flower drifts—cream daisies, golden buttercups, violet spikes, and
pink cosmos—decorate clear ground. Patches exclude the corrected scene's road,
water, wetland, forest, and building-lot masks. Generated woodland trees also
use the displayed unshifted road mask; user-authored installations are retained.
Road geometry, terrain registration, buildings, and character positions are
unchanged. The renderer keeps the existing muted Canvas palette, upright
trunks, isometric ground shadows, and camera-scaled detail without new bitmaps.

Verification: two botanical selection/scale/density tests pass; the production
build and asset verification pass (277 files, 69.0 MiB), with no public interface
changes. The live town overview was visually inspected. Full repository tests
were not run for this presentation-only change.

## Geographic building bearings: orientation-aware prefab review

Open `index.html?building-bearing=geo` for the new geometric review. The normal
entry still uses the authored illustration pack. This is an explicit art-review
gate, not a silent replacement of the established outdoor style. The old assets
are untouched; switching back to `index.html` restores them.

The previous building record had position, axis-aligned dimensions, and an
image path, but no geographic facing. The image renderer only translated and
uniformly scaled fixed-view WebP artwork. Rotating that finished image cannot
change its ground bearing while preserving vertical walls and revealing the
correct faces.

`town_building_bearing.mbt` now derives a separate geographic frame at each lot:
WGS84 / UTM 50N → retained four-corner affine → pole-safe 21-point homography →
gentle unshifted projection. Coefficients are taken from the same reviewed road
reports, with a regression fixture against equal-longitude source vertices.
The north arrow samples the town center (~78.24° clockwise from screen-up);
that screen angle is not applied as a global building rotation. Local true
east/north derivatives retain the map's shear and foreshortening.

The nearest nontrivial road segment is examined in geographic coordinates. A
deviation within ±10° of either cardinal axis is accepted; more diagonal roads
leave the building cardinal rather than forcing an arbitrary clipped angle.
These are design defaults, not claims about surveyed building orientations.

`town_bearing_prefab.mbt` constructs eight architectural families in MoonBit:
lowrise, row, tower, block, courtyard, campus, civic, and industrial. Footprints,
flat roofs, glazing, timber accents, south-facing doors/canopies, planting beds,
and entrance courts share that geographic frame. Walls extrude vertically;
browser FFI only paints the resulting quads. The entire oriented lot fits inside
the previous cleared reservation, so no road or terrain geometry is moved and
the existing clearance rules are not relaxed. Decorative approaches start at
the south gate and are omitted if they would point back through the lot.

This remains a **presentation prototype**, not the final regenerated illustration
pack or a migration of semantic parcels, user-authored buildings, hit areas, or
agent navigation. Existing user buildings retain their artwork and semantics.
Guaranteed wraparound entrance routing is not implemented. The prefab art is
simpler than the authored pack; validate its bearing and massing before refining
or re-rendering the final artwork. A real prefab export should retain the same
axes, entrance socket, footprint envelope, height, and fixed world light.

The browser review reports 36 oriented display buildings, zero invalid reserved
lots, and zero overlapping lot pairs. Six new tests cover source-coordinate
parity, local north, bounded street adaptation, lot envelopes, all eight meshes,
verticals, and opt-in isolation. Together with ten existing placement tests,
three scene tests, and eight canvas-frame tests, 27 focused tests pass. The
full repository suite was not run. Public interfaces are unchanged.
The production build verifies 277 files at
68.3 MiB without changing the size limit. To accommodate the new code,
`scripts/compact-town-reference.mbtx` removes only JSON formatting whitespace
from the shipped intersection reference and asserts parsed-value equality;
all coordinates, IDs, and topology are unchanged.

### Architectural diversity correction

The first bearing prototype retained seven visible families but made them look
too similar: every building used the same office-window treatment and flat
planted roof. Its nominal variants mostly changed floor count. Actual browser
counts were lowrise 12, block 9, courtyard 5, campus 5, industrial 2, tower 2,
row 1, civic 0 (36 total: 17 curated, 7 source-derived, 12 generated infill).
The larger original lot requirements also filtered out some intended families.

The geometric review now has 24 named designs across eight families, with
different massings and construction: hip/gable-roof garden houses, stepped
maisonettes, market arcades, parallel and L-shaped apartments, siheyuan and
cloister courts, research wings, school courts, glazed conservatories,
colonnaded halls, terraced libraries, pavilions, sawtooth factories, workshops,
logistics halls, stepped offices, and twin/slender towers. Roofs, eaves,
colonnades and canopies use geographic 3D vertices, not rotated sprites.
Muted slate, timber, brick and glass accents retain the spring palette.

`town_bearing_diversity.mbt` adds at most one new decorative lot per missing
family/variant after the normal placement pass. It first tries four-tile lots,
then compact three-tile versions; both require a full apron, clear ground,
road frontage, and no overlap. Existing source/curated identities, styles and
locations are preserved. Lack of valid land leaves a visible coverage deficit
rather than bypassing constraints. Separate cache keys isolate this review
from the normal authored-sprite entry.

Browser verification: 44 total buildings, all eight families and all 24 designs
present, zero invalid reserved lots, zero overlapping pairs. Eight additional
decorative lots supply the previously missing designs. Overview and
neighborhood screenshots were inspected. Four new tests cover unique geometry
and names, complete roof/fixture envelopes, stable variants, evidence-required
placement and a compact legal pocket that becomes unavailable when occupied.
Alongside bearing (6), placement (10), and frame (8) tests, 28 focused tests
pass. The build verifies 277 files / 68.4 MiB, with unchanged public interfaces;
the full repository suite was not run. Normal production artwork remains
unchanged; these improvements appear in `?building-bearing=geo`.

### Fourfold building density

The bearing preview now targets **176 individual display-building records**,
four times the previous 44, not four roof volumes per old record. Its original
44 buildings retain their IDs, styles, locations and dimensions; 132 compact
homes/market rows are added. All 24 architectural designs remain represented.
Normal `index.html` and semantic/user-authored buildings are unchanged.

`town_bearing_density.mbt` scans every integer anchor in the 256×144 map,
interleaving 144 districts for deterministic tie-breaking. Candidates must pass
the existing terrain/road mask and frontage checks. A spatially indexed conflict
graph selects the currently least-conflicting anchor, removing its conflicting
neighbors and updating their scores. Generation is cached with the preview's
active scene key, not repeated per frame; its target never forces invalid land.

New housing uses two-unit masses, with the same local geographic frame,
proportional geometry and full one-tile apron against roads, water and woodland.
Only explicitly tagged density housing can use this compact size; larger civic
or industrial designs and the legacy illustration pack retain their scale rules.
Planting margins can overlap as **shared garden strips** when either neighbor
is new density housing. Footprints must remain separated by at least one full
tile, so new walls never enter another building's apron. Existing-to-existing
reservation rules remain unchanged. The reported overlap diagnostic therefore
means a footprint/required-spacing conflict, not overlapping shared planting.
Reserved land continues to exclude generated trees and flowers.

Trials explain why raising the old count limit was insufficient: the all-tile
three-unit scan reached 64; first-fit compact housing reached 137; conflict-aware
packing with exclusive aprons reached 148. A broader frontage trial only reached
152 and was removed. Shared margins among new houses reached 168; allowing the
same shared planting next to retained buildings reaches 176, without changing
road/terrain clearance, frontage or any existing building footprint. No road
geometry, riverside translation or camera calibration was modified.

Browser verification: 176 buildings, 24 designs, zero invalid terrain/road lots,
zero footprint/spacing conflicts; overview and neighborhood views inspected.
Five density tests cover exhaustive/distributed sampling, absent scene evidence,
shared-garden spacing and legacy-size isolation, the actual shipped unshifted
road/terrain masks, and deterministic/idempotent admission retaining existing
buildings. The bearing envelope test now includes two-unit masses. Together
with diversity, bearing, placement and canvas-frame tests, 33 focused tests pass.
Build verification remains 277 files / 68.4 MiB, with no public-interface changes.
The full repository suite was not run. These are decorative display buildings,
not new semantic places or newly verified agent-navigation destinations.

### Streetfront scale correction (supersedes the compact-lot rules above)

The 176-building count passed its placement tests but failed the visual review:
the new houses looked miniature, and pale access spurs crossed open ground to
seemingly arbitrary streets. Two implementation causes were confirmed:

- `town_bearing_quad` multiplied height by parcel span along with horizontal
  dimensions. Compact lots therefore miniaturized every storey, not just width.
- Lot clearance used all displayed road cells, while orientation and approach
  searches used `wenyu_scene_paths`, a filtered walker-path list. Its exporter
  omitted major street categories, boundary-crossing paths and tunnels; runtime
  also discarded paths shorter than two units. The nearest visible street was
  not necessarily present in that search. A long south-door spur could be drawn
  toward a more distant retained path.

The geometric preview now gives new infill a **three-by-three-unit plot** rather
than two-by-two (50% greater nominal width/depth), and all architectural storeys
use a common vertical module (`3.4` times the authored normalized height).
Door, window, roof and wall heights remain coherent across different plot sizes.
The setback for new streetfront houses lies **inside the cleared plot**, rather
than in an extra full external lawn apron. This deliberately replaces the last
pass's one-tile external setback for density housing; it is not a claim that
the old numeric setback was retained. The whole plot must still clear the
conservative displayed-road and terrain masks, including water and woodland,
and the inset mesh cannot extend outside it. Legacy parcels keep their external
aprons. New-to-neighbor footprints retain the one-unit shared-landscape gap.

`town_street_frontage.mbt` reads the exact already-shipped road SVG, parses only
the canonical M/L road group (not the decorative green spine), clips segments
to the SVG ground rectangle, and indexes them in eight-unit spatial bins. This
reuses the displayed geometry directly, without a new calibration, new asset,
road regeneration or riverside shifts. Nearest queries have a bounded 1,024-key
cache. The geographic street adaptation uses this complete frontage index;
walker routes remain a separate unchanged concern.

Infill admission additionally requires its plot edge to be within **1.25 units**
of a displayed street. Long south-door spurs are replaced with muted short entry
walks from the street-facing lot edge, at most **1.75 units** long and checked
against water/woodland. An unsupported connection is omitted, not patched with
a long invented road. The cleared-land lookup respects zero-external-apron plot
bounds so it does not suppress an extra row of vegetation outside those plots.

The preview retains 176 display buildings and all 24 designs, while replacing
the 132 compact infill placements with larger streetfront sites. The preceding
44 retained records keep their identities, dimensions and locations; their
height treatment and nearest-street bearing are updated consistently. Normal
authored-sprite production, semantic/user buildings, agents and road geometry
are unchanged. These entrances remain display landscaping, not proof of a
walkable semantic route or operational agent destination.

Verification: 37 focused tests pass, including actual SVG index-versus-exhaustive
nearest search at 30 map locations, malformed-input rejection, common storey
heights across all 24 designs, bounded entry geometry, and the shipped terrain/
road fixture producing 176 legal three-unit streetfront lots. Browser review
confirmed 176 buildings, 24 designs, and no invalid lots or spacing conflicts;
the neighborhood view was inspected for size and the removal of long spurs.
Full repository tests were not run. The build stays within the existing asset
budget without adding a bitmap or external dependency.
