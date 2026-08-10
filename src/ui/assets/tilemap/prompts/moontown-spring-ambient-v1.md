# MoonTown spring ambient building pack

This pack gives MoonTown's anonymous urban fabric distinct, readable silhouettes
without replacing the live procedural map. It contains ten independent cutouts
for each of eight ambient `TownCanvasBuilding` styles. Every final asset is a
512-by-512 RGBA WebP with alpha; none is a town plate, ground tile, or UI mockup.

## Shared ImageGen prompt

Use case: `stylized-concept`

Asset type: one modular ambient building sprite for MoonTown's procedural
isometric game map.

Primary request: create one isolated contemporary eco-town building matching
the supplied archetype. Preserve a bold, recognizable silhouette at small
scale and use only two or three role-specific architectural cues. This is one
building cutout, not a neighborhood scene.

Scene/backdrop: a perfectly flat, solid `#ff00ff` chroma-key background for
removal. The background must be one uniform color with no gradient, texture,
lighting variation, floor plane, reflection, or shadow. Do not use `#ff00ff`
anywhere in the building.

Style/medium: polished contemporary game art balanced between flat vector
illustration and restrained stylized 3D. Use crisp semi-flat cel shading, thin
deep blue-gray outlines, clean geometric masses, matte warm-white walls,
restrained natural timber, pale-cyan glass, spring green planting, and at most
one tiny terracotta or soft-yellow accent. Keep façades quiet and simplify
foliage into a few graphic masses.

Composition/framing: consistent orthographic isometric camera, 45-degree
azimuth and approximately 32-degree elevation. Center the entire uncropped
building with generous transparent-safe padding. Fit the normalized runtime
ground-center anchor at `(0.50, 0.80)`, the front footprint vertex at
`(0.50, 0.96)`, and the visible footprint to approximately `0.64` of image
width. Do not mirror or rotate a finished sprite; fixed perspective and
lighting must remain consistent across the pack.

Lighting/mood: bright, clear spring daylight with restrained directional
shading, crisp edges, and no atmospheric effects.

Constraints: no baked ground, scene plate, road, pavement, street furniture,
tree outside the building's own tiny court or planter, person, vehicle, label,
sign, logo, UI, icon, cast shadow, contact shadow, reflection, or watermark.
The runtime owns footprint scale, placement, depth order, selection treatment,
shadows, hit testing, labels, residents, roads, and district composition.

## Avoid

Oil painting, painterly rendering, visible brush strokes, watercolor, gouache,
airbrush texture, canvas texture, photorealism, architectural visualization,
PBR material noise, granular foliage, individual leaves, noisy façades,
hundreds of tiny windows, over-detailed roof equipment, excessive street
furniture, crowds, cars, road markings, UI clutter, floating holograms, glowing
data highways, neon city, cyberpunk, science-fiction megastructures, giant or
humanoid robots, skyscraper skyline, mega-building, shopping-mall podium,
autumn foliage, mustard cast, muddy beige, gray-brown palette, dirty filter,
overcast weather, fog, haze, bloom, soft focus, dreamy diffusion, sunset
lighting, candy colors, neon green, plastic mobile-game gloss, childish chibi
proportions, empty sterile scene composition, chaotic urban layout, illegible
text, warped geometry, inconsistent perspective, duplicated details, old
kingdom motifs, watermark, and brand logos.

## P0 generation gates

Every variant 4 through 9 source must pass all of these gates before
post-processing:

- The exact macro silhouette and every explicit count in its archetype capsule
  must read clearly at thumbnail scale. Variants 4 and 5 must remain distinct
  from variants 0 through 3 of the same style; variants 6 and 7 must remain
  distinct from variants 0 through 5; variants 8 and 9 must remain distinct
  from variants 0 through 7.
- Create exactly one isolated building cutout—not a scene, district, multi-item
  sheet, or user interface—with the fixed orthographic 45-degree isometric
  camera at approximately 32-degree elevation.
- Use one perfectly uniform `#ff00ff` source background and none of that key
  color inside the building. The final deliverable must be a 512-by-512 RGBA
  WebP with alpha.
- Preserve the `(0.50, 0.80)` runtime anchor, front footprint vertex at
  y=`0.96`, normalized footprint width `0.64`, full silhouette, and generous
  transparent-safe padding. Never mirror or rotate a finished sprite.
- When an archetype specifies an opaque bounding-box range, fit the final
  non-transparent silhouette inside both inclusive pixel ranges without
  stretching, clipping, or violating the common anchor.
- When an archetype specifies a floor gate, render exactly that storey
  distribution; roof lanterns, clerestories, parapets, and canopies do not count
  as extra floors.
- Keep the warm-white, natural-timber, pale-cyan, and spring-green palette with
  crisp semi-flat cel shading balanced between flat vector illustration and
  restrained stylized 3D. Limit the design to two or three role-specific cues,
  sparse windows, and simplified graphic foliage.
- Include no scene plate, ground, road, shadow, person, vehicle, prop, text,
  logo, or UI. Every prohibition in the shared constraints and **Avoid** section
  is mandatory, including the painterly, PBR, architectural-visualization,
  neon, science-fiction, old-kingdom, weather, and detail-density exclusions.
- Generate each file with its own built-in ImageGen `stylized-concept` call.
  The runtime must keep drawing the complete procedural fallback until the
  selected WebP is ready.

## Exact archetypes

Generate each file separately using the shared prompt plus exactly one of these
archetype descriptions:

- `block-0.webp`: two-storey compact mixed-use block with stepped warm-white
  volumes, a central stack of planted terraces, vertical timber fins, cyan
  corner glazing, and one recessed timber entry.
- `block-1.webp`: two-storey paired neighborhood block with a rounded glazed
  corner wing, a rectilinear companion wing, a sheltered central passage, a
  small coral canopy, and a restrained roof-edge planter.
- `block-2.webp`: two-storey stepped neighborhood market block with three
  staggered warm-white volumes, a recessed cyan-glazed corner shop, one
  continuous timber market awning, and a compact rooftop herb planter.
- `block-3.webp`: two-storey split garden mixed-use block formed by two offset
  wings around a narrow planted breezeway, with a short glazed link, quiet
  timber work bays, and two shallow planted roof edges.
- `block-4.webp`: two-storey checkerboard neighborhood block whose alternating
  square bays create deep open corner notches, with quiet cyan glazing,
  restrained timber faces, and one compact planted roof patch.
- `block-5.webp`: two-storey gateway bridge block with two solid side piers and
  exactly one upper bar spanning a broad full-height ground portal, finished
  with a slim planted roof edge and no courtyard ring.
- `block-6.webp`: two-storey bow-tie neighborhood block where exactly two
  trapezoidal wings meet at one narrow cyan-glazed waist to create four splayed
  outer corners; include no bridge, courtyard, or notched checkerboard.
- `block-7.webp`: single solid two-storey triangular-wedge block with three
  unequal façades, one clipped entry tip, and one small triangular roof garden;
  include no inner court or paired wing.
- `block-8.webp`: continuous two-storey pentagonal shield-plan neighborhood
  block with exactly five outer sides and exactly one square bite removed from
  the rear-right corner. Reject Block-7 triangular massing: retain five outer
  sides. Reject Block-4 checkerboard massing: allow only one bite. Reject
  Civic-5/7 polygon symmetry and any enclosed ring. Opaque bounding box: width
  420–432 px, height 310–370 px, inclusive.
- `block-9.webp`: continuous two-storey M-plan neighborhood block formed by one
  rear spine, exactly three fused forward bays, and exactly two open front
  notches. Reject Campus-4 comb, row façades, Block-4 checkerboard, and
  courtyard massing. All three forward bays must remain fused to the rear
  spine; no detached bays. Opaque bounding box: width 420–432 px, height
  310–370 px, inclusive.
- `campus-0.webp`: two-storey learning campus of two distinct wings joined by a
  cyan-glazed skybridge around a small green court, with one tree, a linear roof
  garden, timber panels, and a broad entry canopy.
- `campus-1.webp`: two-storey angular learning pavilion with an offset satellite
  wing, a long timber bridge-canopy, a triangular skylight, generous cyan
  glazing, and one compact planted roof court.
- `campus-2.webp`: two-storey greenhouse research campus with two calm
  laboratory wings joined by a modest pitched cyan-glass growing house, a
  sheltered garden court, timber sun screens, and one restrained solar strip.
- `campus-3.webp`: two-storey maker learning campus pairing a compact classroom
  wing with a higher workshop bay, connected by a covered timber arcade around
  a small project court, with one sawtooth clerestory and one soft-yellow
  workshop door.
- `campus-4.webp`: comb-plan learning campus with one two-storey academic spine,
  exactly three short single-storey studio fingers, and one linear roof garden;
  include no bridge, greenhouse, or court ring.
- `campus-5.webp`: low two-storey cruciform campus with four shallow learning
  wings centered on one square cyan-glazed commons hub, plus restrained timber
  canopies and one compact roof garden.
- `campus-6.webp`: exactly three detached two-storey pavilion cubes stepping
  diagonally and joined by exactly two low cyan-glazed links, with a roof garden
  on the middle cube only.
- `campus-7.webp`: one continuous two-storey rectilinear S-ribbon framing
  exactly two opposite open garden pockets; include no detached nodes, bridge,
  comb, cross, or closed ring.
- `campus-8.webp`: Y-plan campus with exactly three equal two-storey wings fused
  to one low one-storey triangular cyan-glazed central hub. Reject Campus-5
  four-arm cross, Campus-1 boomerang, Block-7 solid triangle, and Civic-8
  trefoil. Include no courts, bridges, or detached nodes. Opaque bounding box:
  width 420–432 px, height 270–330 px, inclusive.
- `campus-9.webp`: continuous N-plan campus with exactly two parallel equal
  two-storey bars, exactly one low one-storey diagonal ground-connected link,
  and exactly two opposite open triangular garden pockets. Reject Campus-0
  skybridge, Campus-6 chain, Campus-7 S-plan, and Industrial-5 Z-plan. The
  diagonal link must remain ground-connected, never elevated or detached.
  Opaque bounding box: width 420–432 px, height 270–330 px, inclusive.
- `civic-0.webp`: three-storey public-service building combining a rounded low
  chamber and a taller administration volume, divided by a full-height cyan
  atrium, with a yellow entry canopy and one curved roof planter.
- `civic-1.webp`: three-storey stepped civic library with a broad semicircular
  public hall, a quiet rectangular upper volume, a planted roof promenade that
  follows the curve, and a centered timber-framed entrance.
- `civic-2.webp`: low two-storey neighborhood assembly and forum pavilion formed
  by two splayed trapezoidal wings beneath one folded unifying roof, with a
  central cyan-glazed foyer and a recessed timber forum entrance.
- `civic-3.webp`: low two-storey crescent wellness and community center wrapping
  a planted inner court, with continuous pale-cyan glazing, a compact
  rectilinear side wing, and one broad sheltered entrance.
- `civic-4.webp`: compact three-storey terraced council house whose three offset
  rectilinear tiers create broad civic terraces, with one centered cyan chamber
  bay and a restrained timber entrance canopy.
- `civic-5.webp`: low two-storey hexagonal neighborhood forum with six clean
  faceted sides beneath one broad unifying roof, a recessed cyan-glazed public
  chamber, and one clear timber-framed entrance.
- `civic-6.webp`: solid three-storey racetrack-plan civic hall with one
  continuous oval mass and no inner court, marked by one straight timber entry
  blade and one small offset square roof lantern or planted patch; include no
  crescent opening or ring. Opaque bounding box: width 400–432 px, height
  350–410 px, inclusive.
- `civic-7.webp`: solid three-storey diamond-plan civic forum with four clipped
  corners, one diagonal full-height opaque-cyan atrium slash, and one small
  off-center flat-roof court or lantern; include no gables, parallel halls,
  church, cottage, or old-kingdom styling. Opaque bounding box: width 400–432
  px, height 370–430 px, inclusive.
- `civic-8.webp`: solid three-storey trefoil civic hall made from exactly three
  equal fused architectural lobes with straight clipped joins, one triangular
  foyer, and one small flat roof lantern; contain no internal void. Reject
  Courtyard-7 figure-eight, every enclosed ring, Civic-0/1/3 curved
  compositions, and Civic-6 oval. Reject clover, flower, logo, petal-outline,
  dome, spire, religious, and old-kingdom readings. Opaque bounding box: width
  410–432 px, height 360–420 px, inclusive.
- `civic-9.webp`: solid keyhole-plan civic hall formed by exactly one circular
  three-storey chamber and one broad straight one-storey foyer stem measuring
  25–30% of total building length, topped by one raised square cyan lantern.
  Reject Civic-6 continuous racetrack, Civic-5 polygon, courtyard rings, tower
  or campus scale, and every dome. Preserve one solid circular chamber plus one
  short broad stem. Opaque bounding box: width 400–432 px, height 350–410 px,
  inclusive.
- `courtyard-0.webp`: three-storey U-shaped community housing block with two
  parallel wings around a rectangular planted court, a glazed rear bridge,
  sparse timber accents, and a simple front portal.
- `courtyard-1.webp`: three-storey stepped C-shaped community block framing a
  green courtyard and single small tree, with staggered terraces, a tall cyan
  common-room bay, balcony planters, and a timber entrance canopy.
- `courtyard-2.webp`: three-storey four-wing garden cooperative ring enclosing a
  generous square planted court, with stepped corner volumes, restrained timber
  balcony bands, one light glazed link, and a clearly open front portal.
- `courtyard-3.webp`: three-wing pinwheel learning court with bent teaching
  wings radiating around a compact planted center, linked by one short
  cyan-glazed bridge and grounded by a slim timber entrance canopy.
- `courtyard-4.webp`: three-storey H-plan garden cooperative with two parallel
  residential bars joined by one centered crossbar, framing exactly two open
  rectangular planted courts.
- `courtyard-5.webp`: three-storey triangular residential ring formed by three
  straight wings around one triangular planted court, with one clear
  ground-level portal and no fourth wing or circular court.
- `courtyard-6.webp`: three-storey octagonal residential ring with eight clean
  faceted sides, one octagonal garden court, and exactly two opposite
  ground-level portals.
- `courtyard-7.webp`: one continuous three-storey figure-eight residential
  ribbon enclosing exactly two equal round garden courts joined at one narrow
  shared waist.
- `courtyard-8.webp`: continuous three-storey teardrop residential ring with one
  matching teardrop garden court, one rounded head tapering to one point, and
  exactly one ground-level portal at the tip. Reject Courtyard-5 triangle,
  Courtyard-6 octagon, Courtyard-7 twin loops, and civic solid massing. Reject
  heart, map-pin, icon, or top-cleft silhouettes. Opaque bounding box: width
  410–432 px, height 350–410 px, inclusive.
- `courtyard-9.webp`: continuous three-storey square-spiral G-plan residential
  ribbon wrapping exactly 1.5 turns around one off-center square garden court,
  with one front opening and an inner tail at least 40% of opaque bounding-box
  width. Reject Courtyard-1 simple C, Courtyard-2 closed square, Campus-7
  S-plan, and Courtyard-4 twin courts. Include no detached bar. Opaque bounding
  box: width 420–432 px, height 350–410 px, inclusive.
- `industrial-0.webp`: low two-storey maker shed with three restrained sawtooth
  roof bays, cyan clerestory glazing, slim roof-edge planting, and a continuous
  pale-cyan front work canopy.
- `industrial-1.webp`: two-storey fabrication hall with stepped monitor roofs,
  continuous clerestory windows, one small solar array, a large cyan loading
  door, and a modest timber side-entry canopy.
- `industrial-2.webp`: two-storey neighborhood mobility depot with two broad
  cyan service bays beneath a planted butterfly roof, a compact center dispatch
  bay, and one slender side canopy; show no vehicles or road markings.
- `industrial-3.webp`: two offset repair halls with a square cyan clerestory
  lantern centered over the taller rear volume, one broad service door, quiet
  timber work-bay screens, and a modest timber entrance canopy.
- `industrial-4.webp`: long mono-pitch wedge hall with one full-length cyan
  clerestory beneath the raised roof edge and exactly three broad service bays;
  show no vehicles, road markings, or extra roof machinery.
- `industrial-5.webp`: Z-plan industrial workshop made from two offset flat-roof
  bars, with one solar canopy spanning their overlap and one deep open corner
  recess; include no sawtooth, butterfly, or barrel roof.
- `industrial-6.webp`: one long shallow barrel-vault processing hall with a
  full-height cyan end bay and exactly two low rectangular side lean-tos; it
  must not read as a greenhouse or transit shed.
- `industrial-7.webp`: T-plan industrial depot with one tall stem intersecting
  one low crossbar beneath two mono-pitch roof planes that slope in the same
  screen direction, and exactly two broad service doors; do not mirror either
  roof plane or add a third door. Opaque bounding box: width 420–432 px, height
  270–335 px, inclusive.
- `industrial-8.webp`: continuous two-storey L-plan repair plant with exactly
  one long low workshop leg and one shorter taller perpendicular leg fused at
  the outer elbow beneath flat roofs, exactly one raised square cyan clerestory
  cube at the elbow, and exactly two broad service bays on the long leg. Reject
  Industrial-7 T-plan: include no centered stem or crossbar. Reject Industrial-3
  offset pair or lantern, lowrise or campus proportions, detached tower or
  silo, and a third service bay. Opaque bounding box: width 420–432 px, height
  280–340 px, inclusive.
- `industrial-9.webp`: continuous two-storey F-plan depot with one long low
  spine, exactly two unequal perpendicular fingers on the same side, exactly
  two open service courts, flat roofs at exactly two heights, and exactly two
  broad cyan service doors at the finger ends. Reject Campus-4 comb: retain two
  fingers, not three. Reject Industrial-7 T-plan, Industrial-5 Z-plan,
  courtyard or ground-plate massing, and detached bars. Opaque bounding box:
  width 420–432 px, height 270–335 px, inclusive.
- `lowrise-0.webp`: paired two-storey garden homes formed from offset compact
  volumes, with cyan box-bay windows, two timber doors, a shared recessed
  passage, and one sheltered balcony planter.
- `lowrise-1.webp`: two-storey garden residence pairing a softly curved glazed
  corner wing with a rectilinear timber-screened wing and a compact planted
  roof terrace.
- `lowrise-2.webp`: rectilinear two-storey L-shaped garden house with a planted
  roof court nested inside the L, broad pale-cyan windows, a centered timber
  entry bay, and restrained perimeter planters.
- `lowrise-3.webp`: narrow split-level live-work atelier pairing a tall studio
  volume and a short side wing, with one double-height cyan work window, a
  timber-framed entrance, and a compact upper garden terrace.
- `lowrise-4.webp`: single-storey T-plan patio bungalow with a broad garden room
  across the top of the T, a short entry stem, one sheltered side patio, and one
  offset cyan clerestory.
- `lowrise-5.webp`: paired two-storey garden homes with opposing mono-pitch roofs
  rising away from one narrow planted center seam, two simple cyan end bays,
  and clearly separate timber entrances.
- `lowrise-6.webp`: compact two-storey top-heavy cantilever house with one
  shifted upper volume projecting over a smaller ground volume to create one
  large sheltered corner void, plus one flat roof planter and one unmistakably
  domestic timber front door; include no courtyard ring, service bay, or
  commercial canopy. Opaque bounding box: width 390–425 px, height 320–380 px,
  inclusive.
- `lowrise-7.webp`: compact domestic two-storey vertical wedge loft with one
  mono-pitch main volume, one full-height cyan home-studio window, and one lower
  perpendicular flat-roof annex with a planted edge and clearly residential
  timber door; include no loading door, service bay, depot proportions, office
  scale, campus scale, paired house, or courtyard block. Opaque bounding box:
  width 400–432 px, height 300–360 px, inclusive.
- `lowrise-8.webp`: compact square two-storey domestic house with exactly one
  large quarter-circle full-height bite removed from the front-left corner to
  form one curved sheltered terrace, plus one flat roof garden patch and one
  timber front door. Reject Lowrise-1 convex rounded wing, Lowrise-6 rectangular
  cantilever void, civic curves, and every commercial or service cue. The
  quarter-circle must be a concave bite, not a projecting lobe. Opaque bounding
  box: width 390–420 px, height 320–380 px, inclusive.
- `lowrise-9.webp`: compact two-storey rotated-stack house with exactly one
  horizontal rectangular ground volume crossed centrally by exactly one
  narrower upper volume rotated 90 degrees, creating exactly two opposite
  sheltered terraces, plus one small roof planter and one domestic front door.
  Reject Lowrise-6 same-axis cantilever, Lowrise-0 paired boxes, Campus-5 ground
  cross, Industrial-7 T-plan or depot scale, every bridge, and every paired
  prong. Opaque bounding box: width 390–425 px, height 320–380 px, inclusive.
- `row-0.webp`: three joined three-storey shop-house bays with a clear repeated
  rhythm, dark restrained storefront awnings, cyan glazing, alternating timber
  fins, and only two tiny roof planters.
- `row-1.webp`: three joined three-storey townhouses with staggered narrow bays,
  warm timber balcony planters, open roof terraces, one pale-yellow center shop
  canopy, and a small angled corner bay.
- `row-2.webp`: three-storey continuous straight-lintel gallery bar with one
  long rectangular mass, a deeply shaded ground-floor gallery, evenly repeated
  cyan window bays, sparse timber screens, and one shallow gray roof.
- `row-3.webp`: four-bay descending terrace row whose linked homes step down one
  bay at a time, with flat timber roof terraces, tall cyan windows, four clearly
  separated entrances, and restrained front planters.
- `row-4.webp`: four-bay terrace arranged as one shallow chevron V-plan, unified
  by one continuous roof line and one continuous timber shade canopy, with
  restrained repeated cyan bays.
- `row-5.webp`: five-bay terrace with an exact high-low-high-low-high roof rhythm
  and one full-height central passage through the middle high bay, with five
  clear entrances and no continuous arcade.
- `row-6.webp`: five equal three-storey bays arrayed along one shallow concave
  arc with one continuous curved roof line; include no chevron, height stepping,
  or central passage.
- `row-7.webp`: four equal three-storey maisonette cubes separated by exactly
  three full-height planted slots and joined only by one slim upper timber
  gallery.
- `row-8.webp`: exactly six equal attached three-storey bays arranged on one
  shallow convex arc with a symmetric three-level parapet crown: the outer pair
  low, the next pair medium, and the center pair high; include exactly six
  doors. Reject Row-6 concave five-bay arc, Row-3 one-way descent, Row-5
  alternating straight row, and civic-scale curves. Include no gables. Opaque
  bounding box: width 420–432 px, height 390–450 px, inclusive.
- `row-9.webp`: exactly five equal attached three-storey bays forming one crisp
  90-degree L-corner row, with three bays on the long leg, two on the short leg,
  one level flat roof, exactly five doors, and an open inner corner. Reject
  straight Rows 0/2/5/7, Row-4 chevron, Rows 6/8 arcs, courtyard U or C massing,
  and detached corner buildings. Opaque bounding box: width 420–432 px, height
  390–450 px, inclusive.
- `tower-0.webp`: slender eight-storey planted midrise with a full-height cyan
  glass bay, asymmetric stepped terraces, one rooftop garden, sparse vertical
  windows, and a small coral entry canopy.
- `tower-1.webp`: slender eight-storey split-volume midrise with a narrow cyan
  central glass spine, alternating planted ledges, a tiered roof garden, timber
  accent panels, and a calm framed entrance.
- `tower-2.webp`: slender eight-storey wellness shaft punctured by exactly three
  large recessed sky terraces, each with a pale-cyan back wall, warm timber
  lining, and concentrated planting, plus one compact roof garden.
- `tower-3.webp`: slender energy-observatory shaft capped by an offset two-floor
  cyan-glazed top lantern and a small solar pergola over its planted roof, with
  quiet horizontal window bands and no glowing or science-fiction elements.
- `tower-4.webp`: compact eight-storey paired-prong midrise with two vertical
  shafts separated by one full-height open slot and joined by exactly one
  planted mid-level bridge; never close the slot or add a second bridge.
- `tower-5.webp`: single eight-storey rounded capsule shaft wrapped by exactly
  two broad horizontal green belts, with sparse cyan window bands, a quiet
  timber entry, and no stepped terraces, prongs, or top lantern.
- `tower-6.webp`: single eight-storey triangular-plan midrise with three
  chamfered faces, one vertical cyan atrium seam, sparse timber fins, and one
  roof garden; include no terraces, prongs, or top lantern.
- `tower-7.webp`: single eight-storey tapered-wedge midrise whose flush floor
  plates narrow monotonically upward to one small roof garden, with one broad
  cyan face and no balconies, steps, bridge, or green belts.
- `tower-8.webp`: single constant-width regular-hexagonal eight-storey shaft
  with exactly six equal sides, one recessed full-height cyan groove on one
  face, one flat hexagonal roof garden, and exactly seven sparse window bands
  above the entry. Reject Tower-5 capsule or green belts, Tower-6 triangle,
  Tower-7 taper, Civic-5 low hexagon, and every terrace, prong, or top lantern.
  Opaque bounding box: width 210–250 px, height 450–472 px, inclusive.
- `tower-9.webp`: single constant-width narrow rectangular eight-storey blade
  tower whose visible depth is at most 40% of façade width, capped by one
  diagonal mono-pitch crown rising left-to-right, with one solid pale-cyan end
  face and exactly seven sparse window bands above the entry. Reject Tower-7
  taper: keep both vertical sides parallel. Reject Tower-3 lantern or
  cantilever, Tower-4 prongs, Industrial-4 low wedge, and every balcony,
  terrace, or green belt. Opaque bounding box: width 180–225 px, height 450–472
  px, inclusive.

## Built-in ImageGen and chroma workflow

1. Use the built-in ImageGen path and issue one `stylized-concept` generation
   call per file; all ten variants are separate prompts, not a multi-building
   sheet.
2. Generate a square high-resolution source on the exact flat `#ff00ff`
   background. Copy the selected project-bound source from the generated-images
   location into a workspace staging directory before post-processing.
3. Remove the background with the installed ImageGen helper, using border
   auto-key sampling, a soft matte, and despill:

   ```bash
   python "${CODEX_HOME:-$HOME/.codex}/skills/.system/imagegen/scripts/remove_chroma_key.py" \
     --input <source> \
     --out <alpha-output.webp> \
     --auto-key border \
     --soft-matte \
     --transparent-threshold 12 \
     --opaque-threshold 220 \
     --despill
   ```

4. Fit without stretching or cropping, then downsample to the final 512-square
   RGBA WebP. Preserve the `(0.50, 0.80)` anchor, `(0.50, 0.96)` front vertex,
   and `0.64` normalized footprint width.
5. Validate 512-by-512 dimensions, alpha presence, fully transparent corners,
   plausible opaque subject coverage, clean antialiased edges, no magenta
   fringe, and no baked scene plate or shadow. If a thin fringe remains, retry
   once with `--edge-contract 1`.

## Runtime gate

Ambient art is eligible only when `module_key` and `authored_id` are both absent,
the live style is one of `block`, `campus`, `civic`, `courtyard`, `industrial`,
`lowrise`, `row`, or `tower`, and zoom is at least `0.18`. The pure selector is
`golden_spring_ambient_building_asset_candidate(building, zoom)`; path selection
uses `golden_spring_ambient_building_asset_path(building, zoom)` and
`golden_spring_ambient_asset_path_for_variant(style, variant)`.

Choose a variant in the inclusive range 0 through 9 with the stable hash salted
by `moontown-spring-ambient-v1` and based only on canonical style, live place ID
and interior seed. Let `r = mod(hash, 10)`: residues 8 and 9 promote directly to
the two new variants; residues 0 through 7 retain the prior `mod(hash, 8)`
choice. This preserves 80 percent of existing assignments while introducing
the new art evenly. Animation time must never influence asset choice. Draw the
WebP only after its cache record is ready and reports valid natural dimensions;
during loading, on error, when missing, or when ineligible, render the complete
procedural building in that same frame. This keeps semantic geometry
authoritative and prevents frame-to-frame sprite flashing.
