# Energy Valley Procedural Map

The town is generated from a stable seed while retaining the composition of
the large Wenyu masterplan. Terrain comes from
`src/ui/assets/tilemap/wenyu_reference_labels.json`; connected streets come
from `src/ui/assets/tilemap/wenyu_reference_roads.json`. Both use the same
256 × 144 alignment derived from the original Wenyu image. The canonical seed
renders that plan directly; other seeds preserve its topology while
procedurally varying selected terrain, road placement, hydrology, urban
fabric, and civic-module placement.

## What must remain recognizably Energy Valley

Every seed preserves these relationships:

1. The long Wenyu river system, tributaries, lakes, wetlands, and bridge chain
   remain the map's dominant organizing feature.
2. The large central urban concentration and its surrounding satellite
   settlements retain their relative hierarchy.
3. Campus, dense urban, low-rise urban, farmland, and forest keep the same
   broad districts and density gradient as the reference.
4. Major roads retain the long cross-valley connections; local roads remain
   finer-grained inside settlements.
5. The 16 authored functional modules are placed by district intent, shifted
   by the seed, checked for collisions, and required to touch the road network.
6. Wenyu's typed building cells are compiled into the new system's coarser
   gameplay parcels. The 256×144 source grid remains the alignment authority,
   while a 3×3 semantic-to-planning lattice prevents individual source pixels
   from becoming tiny buildings. The new system still owns rendering,
   procedural floor profiles, interactions, civic placement, and runtime work;
   Wenyu supplies district, density, and archetype evidence.

These are topology and hierarchy constraints, not literal coordinates.

## Evidence chain

The authoring evidence is applied in this order:

1. `src/ui/assets/tilemap/wenyu_topdown_semantic.png` is the cleaned top-down
   planning reference used for broader landscape character.
2. `src/ui/assets/tilemap/wenyu_reference_labels.json` records the full 256×144
   semantic grid. It was produced from the source masterplan through image
   interpretation, HSV/color segmentation, water smoothing, and a mixed
   water-road bridge recovery pass. This is the canonical terrain contract.
3. `src/ui/assets/tilemap/wenyu_reference_roads.json` is the connected road
   contract generated from the continuous neutral road surface in the
   top-down masterplan. Its authoring script keeps the largest connected road
   surface, thins it to centerlines, projects it to the gameplay grid, repairs
   diagonal-only joins, simplifies raster stair-steps into topology-safe
   rectilinear corridors, and classifies major roads, local roads, and bridges.
   The simplifier keeps junctions fixed, rejects routes that would touch or
   cross another corridor, and limits drift from the source trace. The raw
   `M/R/b` terrain samples remain hierarchy evidence but are not rendered
   directly.
4. `src/ui/assets/tilemap/wenyu_reference_buildings.json` extracts exact
   building footprint cells, rejects road seams, constrains candidates to
   urban/campus terrain, and classifies the result into low-rise, row, block,
   tower, courtyard, campus, civic, and industrial forms. Its typed cells and
   component anchors are aggregated into gameplay-parcel votes; they are never
   rendered directly.
5. `src/ui/assets/tilemap/wenyu_reference_tilemap_iso.png` is the original
   large isometric bake and the visual parity reference.
6. `src/ui/assets/tilemap/modules/wenyu-town-modules.json` is the authored
   civic-module registry and district-placement evidence.

The raster is comparison evidence, not the runtime map. The current canvas
reads semantic labels and generated MoonBit world state, so terrain remains
interactive and agents can route to buildings doing real work.

## Runtime generation pipeline

The MoonBit implementation is split by responsibility:

- `main/energy_valley_seed.mbt` normalizes and persists the seed.
- `main/exact_energy_valley_world.mbt` adapts the 256×144 reference grammar
  into the current canvas contract, including new-system procedural urban
  fabric, collision-free civic placement, and reserved civic parcels.
- `main/energy_valley_parcels.mbt` compiles 3×3 semantic planning cells into
  6×6 urban or 9×9 campus buckets, searches each bucket for a collision-free
  footprint, and assigns one coherent paved lot and structure anchor.
- `main/energy_valley_road_network.mbt` consumes the connected centerline
  contract, restores land beneath obsolete raw road samples, and keeps every
  diagonal join cardinal so routing and rendering share one graph.
- `main/energy_valley_building_access.mbt` connects each civic entrance to
  the shared graph with a shortest cardinal access spur.
- `main/wenyu_reference_structure_bridge.mbt` maps the Wenyu JSON vocabulary
  into the new system's structure vocabulary by voting over each gameplay
  parcel, then applies seed-stable floor profiles without bypassing the current
  renderer.
- `main/energy_valley_canvas.mbt` renders that semantic world and alternate
  seeds through the MoonBit Canvas bindings with the existing isometric camera,
  visual language, depth order, and building interactions.
- `main/tilemap_reference*.mbt` keeps the extracted Energy Valley geometry
  available as guardrails for the grammar.
- `main/tilemap_reference.mbt`, `main/tilemap_roads.mbt`, and
  `main/wenyu_modules.mbt` connect the generated result to the existing
  MoonBit/Rabbita view layer.

Generation runs in these stages:

1. Load and schema-check the 256×144 Wenyu terrain, connected road, and
   building rows before the MoonBit application starts. Index each building
   cell by its typed source component and component anchor.
2. Normalize the seed and derive every variation from it.
3. Compile the connected centerline road layer before parcel generation. Raw
   road pixels are replaced by inferred surrounding land unless they belong to
   that centerline. This turns 965 disconnected semantic fragments into one
   four-neighbor graph while retaining 75 authored land blocks. Degree-two
   corridor bends are constrained so at least four straight cells remain for
   every turning cell. Treat raw urban and campus labels as planning evidence
   rather than final paving, so fragmented source pixels do not create a
   checkerboard in the playable map.
4. Aggregate each 3×3 semantic planning cell by its dominant buildable class.
   Group urban cells into 6×6 buckets and campus cells into 9×9 buckets. Within
   each bucket, score candidate footprints by source land-use match, Wenyu
   building evidence, road adjacency, and collision safety. The dominant Wenyu
   building code selects the new-system archetype; procedural generation fills
   parcels that have no source archetype. Only accepted parcels receive a
   coherent urban or campus ground treatment.
5. Place all 16 civic modules near their authored district anchors.
   The search preserves district intent, rejects water, bridge, and road cells,
   keeps a one-cell separation between footprints, and selects a perimeter
   entrance near the road network. Each accepted footprint is then converted
   with its one-cell apron into a shared campus parcel while adjacent roads,
   bridges, and water remain untouched.
6. Connect every civic entrance to the largest road component with a shortest
   cardinal spur, clearing only ambient structures crossed by that access.
7. Feed semantic tile kinds, road overlays, module positions,
   and entrances into the existing Rabbita renderer and runtime work views.

The module material remains identity and protocol evidence. The runtime
generator encodes district anchors for those services, then searches around
each anchor; the anchors are not final placement commands.

## Seed and persistence behavior

- The default seed (`20260727`) is stable and is the exact semantic-reference
  baseline, so launch and comparison screenshots are reproducible.
- Add `?seed=<integer>` to the town URL to select a valley. The choice is
  remembered in local storage for later navigation.
- The six-character base-36 seed label appears under the town name.
- The same seed always produces the same terrain and module placement; another
  seed changes both while preserving the Energy Valley constraints.

## Regression gates

`main/exact_energy_valley_world_wbtest.mbt` checks multiple seeds for:

- deterministic replay and cross-seed variation;
- substantial water and road coverage plus working bridge crossings;
- all authored civic modules retained;
- in-bounds, collision-free, buildable footprints;
- road access for every civic building;
- procedural ambient structures restricted to matching Wenyu
  urban/campus ground;
- one structure anchor per accepted parcel with a multi-cell footprint aligned
  to the shared 3×3 planning lattice;
- every civic footprint reserved as a campus parcel with no ambient overlap;
- deterministic and seed-sensitive module placement.

`main/energy_valley_origin_migration_wbtest.mbt` separately locks the default
seed's reference-derived topology, build pricing, build constraints, demolition
refund, and real-work request surface.

Visual review should compare several seeds with the top-down semantic and
isometric references. A valid variant may move details, but it should still
read immediately as river-led Energy Valley rather than a generic grid town.

## Updating the grammar from a new masterplan

1. Preserve the new source and provenance outside the runtime bundle.
2. Rebuild or update the semantic terrain labels.
3. Run `python3 scripts/derive-wenyu-road-graph.py` and require one
   four-neighbor road component, stable enclosed-block count, and a
   `degreeTwoTurnPermille` no greater than 200 before accepting the output.
4. Re-extract building footprints and review the class coverage summary.
5. Measure the topology: water corridors, district centers, density gradients,
   farm/forest ratios, road hierarchy, and bridge count.
6. Change the semantic reference or grammar rules, not one-off runtime
   coordinates.
7. Add or tighten invariants before accepting the new result.
8. Render the default seed plus at least three alternate seeds at desktop and
   narrow window sizes.
9. Verify building, road, forest, reset, regenerate, save, and reload flows in
   the packaged Lepusa app.
