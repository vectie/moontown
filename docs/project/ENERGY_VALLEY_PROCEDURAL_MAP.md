# Energy Valley Procedural Map

The town is generated from a stable seed while retaining the geography that
makes Wenyu Energy Valley recognizable. The original Wenyu Valley material is
both design evidence and a visual regression reference. The MoonBit runtime
encodes its spatial relationships as a deterministic planning grammar instead
of treating one set of building coordinates as the town.

## What must remain recognizably Energy Valley

Every seed preserves these relationships:

1. A broad, meandering main river crosses the eastern side of the town.
2. A western tributary feeds a central lake and wetland system, then rejoins
   the main river.
3. Three district spines cross the water as bridges and connect the whole road
   graph.
4. A dense gridded civic and innovation core sits west of the main river.
5. The lake is bordered by learning and exchange districts.
6. Agricultural parcels occupy the space between the civic core and river.
7. Forest buffers protect the edges and riparian corridor.
8. Community and showcase districts sit outside the civic center rather than
   forming one uniform building field.
9. The 16 built-in civic services are placed by district intent, shifted by the
   seed, checked for collisions, and required to touch the road network.
10. Background urban fabric grows along roads with district-specific density
    and a mix of low-rise, row, courtyard, campus, and tower forms.

These are topology and hierarchy constraints, not literal coordinates.

## Evidence chain

The earlier authoring process remains useful because it separates visual
evidence from runtime implementation:

1. `src/ui/assets/tilemap/wenyu_topdown_semantic.png` is the cleaned top-down
   planning reference.
2. `src/ui/assets/tilemap/wenyu_reference_labels.json` records a 256×144
   semantic grid. It was produced from the source masterplan through image
   interpretation, HSV/color segmentation, water smoothing, and a mixed
   water-road bridge recovery pass.
3. `src/ui/assets/tilemap/wenyu_reference_buildings.json` extracts exact
   building footprint cells, rejects road seams, constrains candidates to
   urban/campus terrain, and classifies the result into low-rise, row, block,
   tower, courtyard, campus, civic, and industrial forms.
4. `src/ui/assets/tilemap/wenyu_reference_tilemap_iso.png` is the previous
   isometric bake used for visual comparison.
5. `src/ui/assets/tilemap/modules/wenyu-town-modules.json` is the authored
   civic-module registry and district-placement evidence.

The raster remains a useful reference underlay in the standalone viewport.
The semantic runtime does not infer gameplay from raster pixels: terrain,
districts, roads, entrances, and module placement come from the grammar.

## Runtime generation pipeline

The MoonBit implementation is split by responsibility:

- `main/energy_valley_seed.mbt` normalizes and persists the seed.
- `main/energy_valley_grammar.mbt` generates terrain, hydrology, districts,
  road hierarchy, bridges, wetlands, farms, and forests.
- `main/energy_valley_placement.mbt` turns the authored module registry into a
  collision-free, road-connected procedural layout.
- `main/energy_valley_canonical_world.mbt` records the exact 56×52 semantic
  output of the accepted Energy Valley build for seed `20260727`: terrain,
  roads, bridges, plazas, ambient structure kinds, and floor counts. It is a
  regression fixture and canonical launch result, not a raster screenshot.
- `main/energy_valley_canvas.mbt` renders that semantic world and alternate
  procedural seeds through the MoonBit Canvas bindings with the accepted
  isometric camera and depth order.
- `main/tilemap_reference*.mbt` keeps the extracted Energy Valley geometry
  available as guardrails for the grammar.
- `main/tilemap_reference.mbt`, `main/tilemap_roads.mbt`, and
  `main/wenyu_modules.mbt` connect the generated result to the existing
  MoonBit/Rabbita view layer.

Generation runs in these stages:

1. Normalize the seed and derive all random streams from it.
2. Create the main river, tributaries, and lakes around the extracted
   hydrology. Deep reference-water cells are kept as immutable geographical
   guardrails while shorelines and secondary water features vary by seed.
3. Classify every cell into a semantic district.
4. Grow wetlands around water, fields in the farm belt, and forest/meadow
   cover from district-specific probabilities.
5. Lay seeded bridge spines, civic roads, research connectors, local lanes,
   and retained portions of the reference road hierarchy.
6. Place civic modules near district anchors by searching candidate parcels.
   The search preserves district intent, rejects water/wetland/road cells,
   keeps a two-cell separation between footprints, and requires a perimeter
   entrance on the road network.
7. Feed the generated semantic tile kinds, road overlays, module positions,
   and entrances into the existing Rabbita renderer and runtime work views.

The module JSON remains a semantic registry: identity, purpose, footprint,
preferred district, building style, and work protocol are authored. Its
coordinates are only search anchors. They are not final placement commands.

## Seed and persistence behavior

- The default seed (`20260727`) is stable, so launch and screenshots are
  reproducible. It replays the exact accepted semantic world; this prevents
  later generator tuning from silently moving its roads, water, plazas, or
  urban fabric.
- Add `?seed=<integer>` to the town URL to select a valley. The choice is
  remembered in local storage for later navigation.
- The six-character base-36 seed label appears under the town name.
- The same seed always produces the same terrain and module placement; another
  seed changes both while preserving the Energy Valley constraints.

## Regression gates

`main/energy_valley_grammar_wbtest.mbt` checks multiple seeds for:

- deterministic replay and cross-seed variation;
- substantial water and road coverage plus working bridge crossings;
- all authored civic modules retained;
- in-bounds, collision-free, buildable footprints;
- road access for every civic building;
- deterministic and seed-sensitive module placement.

`main/energy_valley_exact_parity_wbtest.mbt` separately locks the canonical
seed's grid dimensions, key river/bridge/civic anchors, build pricing, build
constraints, demolition refund, and real-work request surface.

Visual review should compare several seeds with the top-down semantic and
isometric references. A valid variant may move details, but it should still
read immediately as river-led Energy Valley rather than a generic grid town.

## Updating the grammar from a new masterplan

1. Preserve the new source and provenance outside the runtime bundle.
2. Rebuild or update the semantic terrain labels.
3. Re-extract building footprints and review the class coverage summary.
4. Measure the topology: water corridors, district centers, density gradients,
   farm/forest ratios, road hierarchy, and bridge count.
5. Change `energy_valley_grammar.mbt` parameters or rules, not one-off runtime
   coordinates.
6. Add or tighten invariants before accepting the new result.
7. Render the default seed plus at least three alternate seeds at desktop and
   narrow window sizes.
8. Verify building, road, forest, reset, regenerate, save, and reload flows in
   the packaged Lepusa app.
