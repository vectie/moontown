# Energy Valley Procedural Map

The runtime map is generated, not replayed from a fixed image. The original
Wenyu Valley material remains the design evidence and visual regression
reference; the React/Canvas runtime encodes its spatial relationships as a
deterministic planning grammar.

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
9. The 13 built-in civic services are placed by district intent, shifted by the
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

The generated runtime deliberately does not ship these large authoring
artifacts. They are inputs to design and review, not a static background.

## Runtime generation pipeline

`src/ui/rabbita-town/energy-valley/engine/world.ts` runs the following stages:

1. Normalize the seed and derive all random streams from it.
2. Create the main river, tributary, lake, and lake outlet from continuous
   curves and noisy shore boundaries.
3. Classify every cell into a semantic district.
4. Grow wetlands around water, fields in the farm belt, and forest/meadow
   cover from district-specific probabilities.
5. Lay three bridge spines, a civic grid, campus connector, and stepped
   wetland promenade.
6. Place civic modules near district anchors by searching candidate parcels.
   Candidate scoring prefers the intended district, road adjacency, low
   displacement, and collision-free footprints.
7. Add civic plazas.
8. Grow ambient urban fabric only on buildable cells next to roads, using
   district density to select form and height.
9. Freeze the generated terrain baseline. Persistence records only the
   player's delta from that baseline.

The Canvas renderer then applies the visual vocabulary: animated water,
wetland pools and reeds, crop rows, flower meadows, forest canopy, dense
background blocks, procedural civic buildings, weather, lighting, and agents.

## Seed and persistence behavior

- The default seed is stable, so first launch and automated screenshots are
  reproducible.
- The six-character seed label appears under the town name.
- **Reset this valley** removes player construction but preserves the seed.
- **Generate a new valley** creates a new seed and reruns the full pipeline.
- Saves store terrain deltas and custom buildings, not the generated map.

## Regression gates

`energy-valley/engine/world.test.ts` checks multiple seeds for:

- deterministic replay and cross-seed variation;
- minimum river/lake, wetland, field, forest, and urban coverage;
- three bridge corridors;
- 13 unique civic modules;
- road access for every civic building;
- a frozen generated baseline for delta persistence.

Visual review should compare several seeds with the top-down semantic and
isometric references. A valid variant may move details, but it should still
read immediately as river-led Energy Valley rather than a generic grid town.

## Updating the grammar from a new masterplan

1. Preserve the new source and provenance outside the runtime bundle.
2. Rebuild or update the semantic terrain labels.
3. Re-extract building footprints and review the class coverage summary.
4. Measure the topology: water corridors, district centers, density gradients,
   farm/forest ratios, road hierarchy, and bridge count.
5. Change grammar parameters or rules, not one-off runtime coordinates.
6. Add or tighten invariants before accepting the new result.
7. Render the default seed plus at least three alternate seeds at desktop and
   narrow window sizes.
8. Verify building, road, forest, reset, regenerate, save, and reload flows in
   the packaged Lepusa app.
