# Global road / terrain calibration audit

Status: **not calibrated for whole-map use**. This audit does not change the
live scene, terrain, OSM graph, or previous local-warp candidate. No new fit is
promoted. Design remains fixed for this comparison, consistent with the last
explicit authority decision; this does not decide a future OSM-first redesign.

Diagnostic SVGs referenced below are generated local review artifacts, not
repository or release assets: several embed the private planning image. Supply
`WENYU_REFERENCE_IMAGE` when reproducing them. The JSON evidence and MoonBit
scripts remain in the repository.

## What the pitch / roll / yaw check actually found

The ground renderer and full road-surface renderer use the same matrix:

```
screen = zoom * [[32, -32], [16, 16]] * world
       + [viewportWidth/2, viewportHeight/2] - zoom * cameraPan
```

Under an orthographic-camera convention this is equivalent to 30° elevation,
45° plan rotation, zero screen roll, and a pre-foreshortening scale of
32√2 pixels per world unit at zoom 1. The visible edge slope is atan(1/2),
about 26.565°; that is **not** the camera elevation. There is no focal length
or perspective lens in this renderer. A new regression test captures the
actual road Canvas transform and compares it with `golden_screen_x/y` at
three zooms and three ground positions, including the map extremes.

OSM already passed through WGS84 → UTM50N → the inverse geographic similarity
fit. The recorded 22.924° geographic rotation and 37.862 metres/tile belong to
that conversion, not to a second camera rotation. Applying them again is wrong.

Terrain comes from the design's generated semantic raster. No calibrated
camera intrinsics/extrinsics were retained for its illustrated source. A
plane homography can test relative perspective, but its eight coefficients
cannot honestly be presented as uniquely recovered physical pitch/roll/yaw,
focal length, camera distance, and scale for that artwork.

Changing the shared invertible camera cannot remove road/water intersections
in world coordinates. Those intersections must be resolved before projection.

## Global calibration experiment

`scripts/audit-town-calibration.mbtx` reconstructs the confirmed control pairs
using the same UTM series as the existing authoring tool. It reproduces the
existing original RMS to within 0.00001 tiles, then fits OSM → fixed design
directly. It does **not** compose with the previous nearest-corridor mesh warp.
All 775 source edges participate; none are simplified or deleted.

| Fit | Four-anchor RMS, tiles | Candidate holdout RMS, tiles | Water-conflicting edges | Edges partly outside design bounds |
| --- | ---: | ---: | ---: | ---: |
| Original geographic placement | 0.476 | 18.135 | 96 | 38 |
| Direct global affine | 0.212 | 19.697 | 85 | 91 |
| Direct global perspective | approximately zero | 23,929.690 | invalid | invalid |

The two holdouts are **unconfirmed candidate identities**, not independent
ground truth. Their residuals expose sensitivity, not definitive accuracy.
Water metrics sample road centerlines against the reference raster (river,
lake, and bridge cells), excluding recorded source bridge spans. They are
diagnostics, not proof that a current/planned crossing is invalid. Bounds use
the raster's integer-centred tile cells, including half-cell outer edges.

The affine candidate moves a map corner by 28.862 tiles. Its out-of-bounds
sample fraction rises from 0.382% to 6.047%; lower visible water conflicts
cannot be treated as success while more roads leave the map.

The perspective candidate fits four controls with eight degrees of freedom,
but its denominator crosses zero inside the map. It has a projective pole:
parts of the map go through infinity. Reject it before rendering or scoring
geometry. The JSON retains raw sampled diagnostics for reproducibility but
sets `geometryMetricsValid: false`; its SVG panel deliberately omits roads.

Neither candidate is a safe replacement for the live registration.

## Why the calibration is underconstrained

The four confirmed controls all belong to one central river-bridge chain.
Their convex hull covers only **0.4783%** of the design. The existing report
already fails its whole-map review gates. The design picks themselves have
2–3 tile uncertainty, larger than the fitted RMS. More model flexibility can
fit that uncertainty while making distant parts of the map worse.

For whole-map acceptance (not for starting a trial), identify at least six reviewed fit
landmarks distributed over at least three map quadrants and 30% of its area,
plus two separately reviewed holdouts (the repository's existing acceptance
policy). In particular, add west-side and perimeter correspondences, not
more crossings from the same short central chain. Match physical identities,
not merely the nearest-looking roads. Keep design-only planned roads separate
from current OSM features that have no real correspondence.

Then compare similarity, affine, and perspective by held-out residuals,
leave-one-out stability, map-boundary retention, Jacobian orientation, and
water/bridge correspondence. Select the simplest supported model, compile
all roads/bridges/placement from that one registration, and only then review
the town camera. Do not stack another unconstrained local warp on top.

## Reproduce and inspect

From the repository root:

```
moon run --target native scripts/audit-town-calibration.mbtx
```

Outputs:

- `docs/project/town-calibration-audit.json`: control pairs, exact normalized
  matrices, metrics, explicit rejection/eligibility flags.
- `docs/project/town-calibration-audit.svg`: same-camera top-down comparison
  of fixed terrain/design roads and the complete source OSM network.

The script checks synthetic perspective recovery (including an independent
test point), singular-system rejection, camera round trips at three zooms,
and reproduction of the existing geographic fit. It makes no network calls.

## Unlocked-browser follow-up

The Mac was subsequently unlocked. Inspected the live `scene=6` registration
review at street scale and whole-map overview, the generated comparison SVG,
the local full-resolution semantic design, the [labeled original planning
plate](https://www.kechuangfuwu.com/ueditor/fileupload/file/20210304/1614839499074030180.jpg),
and [OpenStreetMap's wider district view](https://www.openstreetmap.org/#map=13/40.11540/116.43580).

The live canvas visibly retains displaced crossings and rose conflict marks
even though ground surfaces share one projection. The original planning plate
is an oblique illustration; the generated semantic image is a separate
reinterpretation, not an orthorectified survey with retained camera metadata.
Present-day OSM also need not contain the same planned roads. The comparison
therefore mixes projection, generated-image deformation, and potentially
genuine planned/current layout differences. Do not claim that every mismatch
is camera error, or that every mismatch is necessarily a planned change.

No additional **confirmed** controls were added: the unlabeled western design
features could not be confidently tied to named OSM features. An OSM feature
query can establish a real-world identity, but cannot establish that an
unlabeled feature in the generated design is the same place. Similar-looking
bends or junctions must not be promoted solely to improve numerical fit.

The local preview server had stopped and was restarted against the existing
dist directory. The audit SVG is available temporarily at
`http://127.0.0.1:17842/town-calibration-audit.svg` (copied diagnostic output,
not part of the release build). The SVG was visually inspected; it is still
generated evidence, not a screenshot of an improved town. No runtime map
registration or terrain source was changed in this follow-up.

At this stage, additional geographic correspondences were still needed before
whole-map acceptance. This was not a mathematical prerequisite for attempting
a three-point affine fit. The Downloads follow-up below supersedes the earlier
request to stop until CAD/GIS or reviewer-supplied controls were available.

## Downloads original: three-point trial

Found and visually inspected `wenyuvalley.jpg` in the user's Downloads:
2274 × 1280 pixels, SHA256
`8363abfdeda33d759a185c8a54c3ef8f971711a4dbf149028ee9447e38f90e62`.
It is a higher-resolution version of the planning illustration, not a surveyed
top-down map. The original file was not modified.

The user is right: **three non-collinear correspondence pairs suffice for a
first affine fit**. Six parameters describe two translations and a general
2 × 2 linear map (including unequal scale and shear). The six-landmark rule
above is an acceptance policy, not a requirement to begin calibration.
A general planar perspective transform instead needs four pairs in general
position. Neither operation independently recovers all physical camera
parameters from an illustration.

To isolate the terrain-generation stage, `scripts/verify-wenyu-three-points.mbtx`
fits original-image pixels directly to generated-semantic-image pixels. It
does **not** fit OSM and does not compose with the existing runtime mesh warp.
Three approximate visual correspondences are shown on both images:

| Pick | Feature | Original pixels | Generated pixels | Role |
| --- | --- | --- | --- | --- |
| A | Upper arterial / river crossing | 1080, 144 | 728, 35 | Fit |
| B | Southwest arterial junction | 168, 693 | 406, 757 | Fit |
| C | Southeast highway / river crossing | 1790, 838 | 1450, 637 | Fit |
| D | Large west-central junction | 627, 397 | 548, 439 | Check only |

These are provisional visual matches, not newly certified geographic controls.
Manual-pick uncertainty is approximately 12 original pixels and 6 generated
pixels per point. The exact affine fit predicts D at (559.782, 373.181),
**66.865 pixels / approximately 10.238 terrain tiles** from its observed
generated-image location. The fitted points have effectively zero error by
construction; that is not independent verification. The annotated SVG was
inspected in the local browser to check the marker placement and discrepancy.

This first-pass check does not support treating the generated image as a
single affine remapping of the original. It does **not** yet distinguish
perspective from non-projective generation deformation or correspondence
error. Next, test a four-point perspective model with an additional excluded
check before assigning the residual to image generation. Preserve the design
and full OSM network during this work; this result is not a runtime fix.

Two real western locations were separately verified using OSM feature queries:
[Litang Road / Wenyu River](https://www.openstreetmap.org/query?lat=40.15060&lon=116.40487#map=15/40.15141/116.41753)
(bridge ways 106616524 and 106616542), and
[Litang Road / Beiqing Road](https://www.openstreetmap.org/query?lat=40.10292&lon=116.40603#map=15/40.10399/116.42152).
Those query coordinates are approximate map-click locations, not surveyed
centres. Neither was promoted into the fit: their correspondence to the
planning image's selected junctions was not established. Do not conflate
verifying an OSM road name with identifying that road in the illustration.

Reproduce from the repository root, supplying the original image path:

```sh
WENYU_REFERENCE_IMAGE=/path/to/private/wenyuvalley.jpg moon run --target native scripts/verify-wenyu-three-points.mbtx
```

Outputs are `docs/project/wenyu-three-point-trial.json` (picks, transform,
residual and explicit `osmFit: false` / `runtimeEligible: false`) and
`docs/project/wenyu-three-point-trial.svg` (self-contained annotated original
and generated reference). The script checks exact recovery at the three
anchors, a synthetic affine transform at an excluded point, and rejection of
collinear/duplicate controls. It makes no network calls or runtime changes.

## Four-point perspective follow-up

The next trial preserves A–D exactly and freezes three additional visual picks
in `wenyu-perspective-picks.json` before solving. **A/B/C/E fit; D/F/G are
excluded checks.** E is the river crossing beside the large northern field;
F is the narrow upper crossing east of A; G is the diagonal river crossing
south of the oval riverside park. These identities are visual correspondences
between the two illustrations, not newly established OSM controls.

`scripts/verify-wenyu-perspective.mbtx` solves a normalized eight-parameter
homography and compares it with both the previous three-input affine model
and a four-input affine model using exactly the same ABCE inputs. Normalized
least-squares equations use partial pivoting and reject singular systems.

| Model | Fit RMS, generated pixels | D/F/G check RMS, pixels | Pole within original image |
| --- | ---: | ---: | --- |
| Previous affine ABC | approximately 0 | 50.400 | No |
| Affine ABCE, same inputs as perspective | 30.499 | 41.873 | No |
| Perspective ABCE | approximately 0 | 28.361 | No |

Individual excluded check errors change as follows:

| Check | Previous affine, pixels | Perspective, pixels | Perspective, approximate terrain tiles |
| --- | ---: | ---: | ---: |
| D, west-central junction | 66.865 | 20.664 | 3.164 |
| F, upper crossing | 43.134 | 17.129 | 2.623 |
| G, crossing south of oval park | 35.903 | 41.142 | 6.299 |

The perspective model improves aggregate check RMS by about 44% relative to
the previous trial and 32% relative to the same-input affine comparator. It
does not improve every location. In particular G gets worse. Exact fitting
of four controls is expected and is not an accuracy claim.

The solver also performs 32 single-coordinate perturbations of the four fit
picks (±12 original pixels or ±6 generated pixels). None produces a singular
solve or an in-image pole. The largest resulting prediction movements are
22.098 pixels at D, 12.756 at F, and 15.723 at G. These are sensitivity probes,
**not** confidence intervals or bounds on simultaneous picking errors. Check
point uncertainty is not included in those movement values. D/F residuals
remain comparable to plausible picking uncertainty; the remaining G mismatch
warrants inspecting its road centre and the local planned corridor before
attributing it to generation deformation.

Conclusion: perspective explains part of the original-to-generated mismatch,
but this trial does not certify a globally calibrated map or prove that the
remaining residual is AI distortion. Do not apply this image-pixel transform
directly to OSM grid coordinates: that is a different coordinate domain.
The design remains authoritative; no terrain, OSM edges, bridge spans, or live
registration settings were changed. This also avoids simplifying the road
network to hide disagreement.

Reproduce:

```sh
WENYU_REFERENCE_IMAGE=/path/to/private/wenyuvalley.jpg moon run --target native scripts/verify-wenyu-perspective.mbtx
```

The JSON and self-contained annotated SVG are
`docs/project/wenyu-perspective-trial.json` and
`docs/project/wenyu-perspective-trial.svg`. The SVG was inspected in the local
browser. Solver checks cover synthetic projective recovery at an excluded
point, duplicate-control rejection, in-image horizon detection, zero-
denominator rejection, and exact recovery of the four real trial picks.
Next calibration work should review the residual crossing, establish spread
OSM-to-original landmark identities, and assess the composed OSM-to-fixed-
design transform with the complete source network before any runtime promotion.

## OSM → original → fixed-design composition

Follow-up inspection used a magnified, rotated view of the published label to
read **立汤路 (Litang Road)** unambiguously. The label and continuous arterial
trace support matching original pick A to the Litang/Wenyu crossing. Its
previously queried OSM position is approximately (116.40487, 40.15060).
The pair is useful for a provisional trial, not survey certification.

The magnified original/generated view of G shows the same crossing south of
the oval park. G remains unchanged and excluded from the geographic fit;
it was not moved toward the predicted position. Current OSM feature queries
also confirmed the named crossing sequence:

- [Qinbei Road bridge, way 47518657](https://www.openstreetmap.org/way/47518657).
- [Future Science City Road bridge, way 991390169](https://www.openstreetmap.org/way/991390169).
- [Future Science City East Road bridge, way 991390168](https://www.openstreetmap.org/way/991390168)
  and its [road way 395533857](https://www.openstreetmap.org/way/395533857).

Geographic coordinates for the central crossings retain the existing official
table's WGS84 assumption. The new configuration is
`wenyu-osm-chain-controls.json`: fit A, Qinbei Q, Science City East X and
Jingcheng C; exclude G. Q/X centres are manual visual picks in the original
and semantic images. The `confirmed` review labels identify the road-name
review, not a high-accuracy original-pixel survey; the configuration as a whole
is explicitly provisional and runtime-ineligible. Western junction B is still
not used. Three central fit controls remain clustered, despite adding A.

The offline audit now has an opt-in composed mode. It reconstructs the OSM
source-grid coordinates from geography, fits source grid → original pixels
using affine and perspective alternatives, then applies the previous ABCE
original → generated perspective matrix. Generated pixels are converted to
256 × 144 design-grid units. Composition is checked numerically against
sequential evaluation at three synthetic interior points. It does not apply
the image-pixel matrix directly to OSM grid numbers or stack the runtime mesh.

| Model | Fit RMS, design tiles | Excluded G error, tiles | Water-conflicting edges | Edges partly outside | Outside sample fraction |
| --- | ---: | ---: | ---: | ---: | ---: |
| Existing geographic placement | 27.989 | 0.676 | 96 | 38 | 0.382% |
| Original affine → design perspective | 7.430 | 10.737 | 112 | 400 | 48.195% |
| Original perspective → design perspective | 7.240 | 16.021 | 105 | 441 | 55.043% |

The baseline fit RMS above uses the **new four-control set**, including A;
it is not comparable to the old four-central-bridge RMS without that caveat.
For the first leg alone, affine fit/check errors are 22.803/85.788 original
pixels; perspective fit/check errors are approximately 0/77.267 pixels.
Neither first-leg nor combined matrix has a pole inside the stored source
grid, but neither passes the geometric checks. **Both candidates are rejected.**
All 775 source edges and 3,980 source path vertices remain in the calculation;
the SVG clips only for display and explicitly reports what leaves the image.

The most useful new evidence is the upstream coverage discrepancy. Under the
stored geographic conversion, A is at **(104.781, −50.213)**, whereas the
stored grid domain is 256 × 144 and its design target is (111.464, 5.356).
The nearest stored road vertex is 52.735 tiles away. The graph therefore does
not supply the upstream crossing needed by this original-plan correspondence.
This is evidence of an extent/registration mismatch, **not proof of which
upstream extraction or clipping operation caused it**. The raw geographic
extract and its producer were not found in the scoped source-file search.

The safe repair path is to obtain a provenance-preserving wider OSM extract,
retain geographic way/node IDs and unclipped geometry, establish western and
perimeter correspondences, and only crop after the design registration is
evaluated. This must not be presented as “retrieve more roads and the current
fit will work”: the fit itself still fails the excluded bridge check. No
runtime promotion, road deletion, terrain change, or camera change occurred.

Reproduce from the repository root:

```sh
WENYU_COMPOSED_TRIAL=1 moon run --target native scripts/audit-town-calibration.mbtx
```

Outputs: `docs/project/wenyu-osm-composed-trial.json` and
`docs/project/wenyu-osm-composed-trial.svg`. The additional
`wenyu-crossing-detail.svg` comes from rerunning
`scripts/verify-wenyu-perspective.mbtx`. Both SVGs were visually inspected;
the composed SVG visibly exposes the rejected candidates' compressed road
placement and out-of-bounds loss, rather than presenting them as improved UI.

## Centre first, then a small affine adjustment

Following the user's pivot hint, the audit now explicitly uses
`targetCentre + linear * (point - sourceCentre)`. The source and destination
centres are calculated separately from the same weighted landmark pairs;
they are not the image bounds centre, camera pan, or global coordinate origin.
`fit_centred` solves only the four linear coefficients after subtracting the
two centres. `centred_matrix` then restores the destination centre and encodes
the result using the existing normalized matrix convention.

This test returns to the existing four central bridge controls, not the
subsequent upstream hypothesis or two-stage perspective chain. With these
controls, source and destination centres already coincide: their displacement
is **3.493e-9 tiles**. The existing geographic similarity fit had already
aligned their weighted means. The unrestricted centre-first affine and the
previous six-parameter affine differ at map corners by only **2.218e-11 tiles**.
Thus centring is the correct explicit order, but it does not establish a
missing-pivot bug in the earlier unrestricted fit. Changing the pivot while
retaining a freely solved translation cannot change that affine mapping.

For a deliberately small trial, the audit also blends the linear part toward
identity while keeping both centres explicit. It limits total displacement
to **two tiles** at every map corner (therefore everywhere in the rectangle,
by convexity of the affine displacement norm). The two-tile cap is a trial
interpretation of “slight changes”, not a geographic accuracy tolerance.

| Model | Central fit RMS, tiles | Water-conflicting edges | Edges partly outside | Outside sample fraction |
| --- | ---: | ---: | ---: | ---: |
| Source placement | 0.476397 | 96 | 38 | 0.382% |
| Align weighted centres only | 0.476397 | 96 | 38 | 0.382% |
| Centre first + bounded affine | 0.450197 | 94 | 54 | 0.705% |

The remaining two candidate holdouts are still unconfirmed, so their errors
are diagnostic only. Neither centre-only nor bounded-affine output is promoted
to runtime; a lower water count alone does not offset increased boundary loss.
All 775 roads are retained. If the intended centre is a different visual
landmark, it must be identified as a source/target pair rather than silently
substituted for the existing bridge-control centre.

Run `WENYU_CENTERED_TRIAL=1 moon run --target native scripts/audit-town-calibration.mbtx`
to reproduce `wenyu-centered-trial.json` and `wenyu-centered-trial.svg`.
Regression assertions verify centre-to-centre mapping, recovery of a synthetic
pivoted affine, equivalence to the unrestricted fit, and the two-tile movement
cap. This is an offline trial; no runtime camera or source geometry changed.

## Two independent image → OSM affine transforms

The latest user request changes the reference frame: fit **each image to OSM
independently**, then derive the relative image transform. This is not the
previous OSM → original → generated perspective chain, nor an adjustment to
the old tile-grid centre.

`scripts/fit-wenyu-common-osm.mbtx` implements two centred weighted
least-squares affines in EPSG:32650 (UTM zone 50N, metres). Both use the
unchanged A/Q/X/C correspondences in `wenyu-osm-chain-controls.json`; G remains
excluded from both fits. Source pixels are native-resolution, x right/y down.
The target is easting/northing, not longitude/latitude degrees or screen space.

The shared geographic centre is `(453359.482920404, 4442271.234609119)` metres.
Each source has its own centroid. Using column vectors:

```text
OSM = sharedCentre + L_original × (originalPixel − [1479.25, 588.75])
L_original = [ -1.485125983   10.297558322 ]
             [  3.855946128   -8.698110359 ]

OSM = sharedCentre + L_generated × (generatedPixel − [1181, 412.25])
L_generated = [ 13.456584100  -5.566811839 ]
              [-12.643147899   9.152334981 ]
```

The full homogeneous matrices (rounded here; full precision in JSON) are:

```text
T_original = [ -1.485125983  10.297558322   449493.668068839 ]
             [  3.855946128  -8.698110359  4441688.338773373 ]
             [  0            0                  1         ]

T_generated = [ 13.456584100  -5.566811839   439762.175278713 ]
              [-12.643147899   9.152334981  4453429.742181286 ]
              [  0            0                  1         ]

T_original_to_generated = inverse(T_generated) × T_original
                       = [0.149173602  0.868291831   449.128133708]
                         [0.627377609  0.249098365  -662.454991049]
                         [0            0              1        ]
```

For placing geographic OSM roads on the unchanged design, the relevant
direction is simply `inverse(T_generated)`. The relative transform above is
for comparing original artwork with generated artwork; it is not another
transform to stack on top of OSM → design.

| Independent fit | Fit RMS, metres | Excluded G error, metres | Linear determinant |
| --- | ---: | ---: | ---: |
| Original → OSM | 230.966 | 163.652 | -26.789040 |
| Generated → OSM | 244.996 | 1033.806 | +52.777140 |

**These matrices are calculated, but not accepted for runtime.** Their
opposite determinant signs imply a reflection in the relative image mapping.
Both source images use the same pixel-axis convention and are not intended
to be mirrored. The generated controls have a source covariance condition
number of **2224.594**, versus **98.862** for the original: the selected bridge
chain is nearly collinear in generated pixels. This makes the unconstrained
affine solution sensitive to pick errors, especially away from that chain.
The excluded G correspondence disagrees by **63.327 generated pixels** under
the composed mapping. These results do not identify how much error belongs
to the manual picks versus the artwork; they do establish that this particular
fit is not a trustworthy whole-map calibration.

Three non-collinear pairs determine an affine mathematically. Three or more
points concentrated along the same river do not provide a well-conditioned
whole-map test. The next useful controls are independently identified
**off-river junctions**, spread across the map, plus excluded checks. Adding
more bridge-chain points or changing the centre alone does not supply that
missing two-dimensional leverage.

### OSM evidence and comparison display

The live OSM API was reached successfully at
<https://api.openstreetmap.org/api/0.6/way/991390168/full.json>; its response
identifies `未来科学城东路桥` and returns its geographic bridge outline. This
verifies feature identity, **not the exact point used as the bridge centre**.
The numerical trial deliberately retains the previous provisional coordinate
and pixel picks for comparability. Some geographic coordinates originate in
the earlier authority table and are assumed WGS84; they are not freshly
surveyed OSM intersection coordinates. The earlier `reviewStatus: confirmed`
must not be read as survey-grade confirmation.

The orange reference network is the retained OSM snapshot from 2026-08-10,
not a newly downloaded district extract. Its storage similarity is inverted
back to geographic metres using the recorded grid → UTM matrix. That old
matrix is used **only to decode the stored road geometry for display**, never
as a target in either new image fit. All **775 edges / 3980 path vertices**
are retained and asserted. The existing limited extraction extent is visible;
missing upstream roads have not been invented or substituted with design roads.

Both SVG panels use exactly the same north-up metric camera, centroid, scale
and display crop (12000 × 8302.703 metres). Each image is transformed directly
by its own SVG affine matrix. White circles are geographic targets, pink
crosses are transformed image picks, and pink connectors show residuals.
Orientation warnings are explicit. The UI review skill guided this controlled
side-by-side comparison; the result was visually inspected in the browser.

Original and generated image SHA-256 values were rechecked and remain
`8363abfdeda33d759a185c8a54c3ef8f971711a4dbf149028ee9447e38f90e62`
and `10d09f3fb45da0e6dbcfb89dee19051df23d8be4b6b5e28aafbd51817c64d93b`.

Reproduce from the repository root:

```sh
WENYU_REFERENCE_IMAGE=/path/to/private/wenyuvalley.jpg moon run --target native scripts/fit-wenyu-common-osm.mbtx
```

Outputs: `wenyu-common-osm-affines.json` and `wenyu-common-osm-affines.svg`
under `docs/project/`; the SVG is also published into the existing local
server's `dist` folder. Embedded regression assertions cover weighted affine
recovery, matched centroids, inverse round trips, composition order, collinear
control rejection, singular inverse rejection, a UTM central-meridian check,
and full retained road counts. The camera regression test also passes (1/1).
`moon info`, `moon fmt`, and `git diff --check` complete the verification;
no public interface change, live terrain edit, runtime promotion, commit or
push is part of this calculation.

## Replacement controls: four outer corners, 2026-09-06

> **Superseded SW claim:** The user rejected the southwest correspondence
> in the next review. SW is now `role: excluded`, and `fourCornerSetReady`
> is false. The table and area figures below describe the preceding candidate
> set, not four accepted controls. See the SW review note at the end.

The user correctly rejected the narrow, inaccurate bridge-chain selection.
The preceding two affine matrices are historical diagnostics, **not the
current recommended control set**. Do not reuse their A/Q/X/C selections for
another whole-map fit. New controls are recorded separately in
`wenyu-four-corner-controls.json`, with a review board in
`wenyu-four-corners.svg`.

These are the four outer corners of the shared **Litang–Jingcheng site
footprint**, not the literal rectangular bitmap corners. The original is
perspective artwork and includes a wide surrounding landscape; its geographic
northwest corner therefore appears near the top-middle of the canvas. Foggy
background corners were not assigned invented geographic coordinates.

| Corner | Geographic feature | Original native pixels | Generated native pixels | Image-pick radius, original / generated |
| --- | --- | --- | --- | --- |
| NW | 立汤路 × 温榆河 | (1060, 147) | (728, 37) | ±8 / ±4 px |
| NE | 京承高速 × 顺于路 | (1882, 614) | (1503, 416) | ±8 / ±5 px |
| SE | 京承高速 × 机场北线 | (1738, 971) | (1430, 722) | ±18 / ±12 px |
| SW | 立汤路 × 定泗路 | (175, 694) | (410, 760) | ±8 / ±5 px |

The old NW original pick `(1080,144)` was on the eastern bank/edge rather
than centred on the crossing. Magnified native-pixel review moved it to
`(1060,147)`. The southwest outer road junction is paired with **定泗路**,
not the previously considered 北清路 coordinate at latitude 40.10292.
NE was traced along the crossroad above the east-bank campus; SE is the
large interchange below the motorway's river crossing. The labelled original
plate identifies the western boundary as 立汤路 and the eastern as 京承高速:
<https://www.kechuangfuwu.com/ueditor/fileupload/file/20210304/1614839499074030180.jpg>.
Perimeter-road topology and intermediate crossing order were compared in both
images; picks were made before fitting, not moved toward predictions.

### Fresh geographic coordinates, reproducible from OSM ways

`wenyu-corner-osm-reference.json` preserves the fresh Overpass `out geom`
response with OSM base timestamp **2026-09-05T16:18:13Z**. The exact query,
bounds and endpoint are stored in the control manifest. This is a named
arterial/river reference subset, **not a replacement for the full road graph**.
No road-network simplification has been applied to runtime.

`scripts/find-wenyu-corner-controls.mbtx` computes 2D segment crossings of
named geographic ways and selects the relevant main carriageways. It removes
duplicate coordinates before averaging the selected crossing locations, so
shared nodes repeated in split ways do not bias the centre. Each control
retains the exact contributing way IDs and intersection coordinates:

- NW: two Litang carriageways `106616524`, `106616542`, intersecting the
  Wenyu centreline `226214870`.
- NE: two Jingcheng carriageways `158054660`, `158054718`, intersecting
  Shunyu `395699977`.
- SE: four crossings of Jingcheng `126860126`, `158054613` with Airport
  North `126860147`, `126860186`.
- SW: four distinct crossings selected on the primary Litang carriageways
  `1250750580`, `1250776519`, `1257119855`, `1257123252`, against Dingsi.
  Parallel service/bus alignments are excluded from this centre definition.

This gives a precise, inspectable **definition within OSM vector geometry**;
it does not make the raster picks survey-accurate. Grade-separated line
crossings are valid plan-view reference positions, not claims that routing
nodes connect. The 2021 illustration and AI terrain simplify interchange
geometry, especially at SE; its larger manual-pick radius is deliberate.
OSM changes since the design date remain a possible source of disagreement.

### Spread, visual review and scope

The ordered NW–NE–SE–SW quadrilateral is convex in both images. Its area
covers **25.094%** of the original canvas and **31.468%** of the generated
canvas. The script asserts the four selected geographic crossing counts
(2, 2, 4, 4), convexity, in-image coordinates, and greater than 20% area in
each raster. It also checks a synthetic segment intersection. These are
spread/geometry checks, not proof of calibration accuracy.

The review board deliberately leaves both images **unwarped** and shows the
same four labelled positions and perimeter on a third, north-up OSM reference
panel. Native-pixel zoom sheets were used to inspect the bridge, crossroads,
and interchange before recording the picks. The UI review skill guided this
landmark-first display, and the rendered board was checked in the browser.

Reproduce entirely in MoonBit, from the repository root:

```sh
moon run --target native scripts/find-wenyu-corner-controls.mbtx
```

The script reads the preserved snapshot by default. `WENYU_OSM_REFERENCE`
can select an explicitly downloaded alternative for a future review. This
turn replaces the **landmark selection**, not the live camera, terrain,
road layout, or registration. The preceding affine output remains unchanged
and unaccepted; it has not silently been relabelled as a four-corner fit.

### SW review: correspondence withdrawn

Historical review state, superseded by the corrected candidate below.

The previous statement that `(175,694)` in the original and `(410,760)`
in the generated terrain identify **立汤路 × 定泗路** was too strong. The
OSM vector computation correctly located that named intersection, but it did
not establish that the chosen raster junction was the same one. This is a
correspondence error, not an affine or arithmetic error.

Following the user's `the sw iswrong` correction, SW is excluded from fit
selection. The manifest retains its old coordinates strictly as the rejected
hypothesis and marks the four-corner set not ready. The board labels it
`SW?` and `EXCLUDED`, with a grey historical outline. Assertions verify that
only three provisional fit controls remain and SW keeps the rejected status.
No replacement coordinate is silently assigned and no affine is recalculated.

The preserved OSM snapshot also contains **立汤路 × 北清路**, around
latitude 40.103 rather than the Dingsi latitude 40.115. Its candidate
intersections are now included in `wenyu-corner-osm-intersections.json`.
This proves those are separate geographic junctions; it does **not by itself**
prove the lower raster pick is Beiqing Road. The road-name change considered
during review therefore remains a hypothesis, not a correction promoted to
the control manifest.

An additional published planning diagram was inspected in the browser:
<https://www.kechuangfuwu.com/vue/news?id=7110>. Its blue-green space map
helps trace landscape topology, but does not label the relevant southwest
crossroad clearly enough to settle this correspondence. Exact source images:
<https://www.kechuangfuwu.com/ueditor/fileupload/file/20201130/1606703840968000235.jpg>
and
<https://www.kechuangfuwu.com/ueditor/fileupload/file/20201130/1606703950609017936.png>.

At that review stage, the remaining ambiguity was whether the correction targeted the original
image pin, generated-image pin, or the geographic OSM assignment. A marked
correct junction on either image will resolve that distinction without another
unsupported road-name substitution. The UI review skill guided the explicit
rejected-state display; the source images and live town are unchanged.

### SW correction: hold OSM fixed, move both raster picks

The user clarified that SW was not the same junction across OSM and the two
images. The next trial keeps **立汤路 × 定泗路** fixed at
`116.405675675, 40.11513705` and moves both raster controls to the large
crossroad farther north along Litang Road:

| Reference | Rejected pixel | Corrected candidate pixel |
| --- | --- | --- |
| Original, 2274 × 1280 | (175, 694) | **(630, 403)**, ±12 px |
| Generated, 1672 × 941 | (410, 760) | **(548, 439)**, ±8 px |
| OSM WGS84 | 116.405675675, 40.11513705 | **Unchanged** |

The matching evidence is road and landscape ordering, not a fitted prediction:
the corrected junction lies on the labelled Litang boundary, north of the
central wetland. Its eastbound corridor runs past the north side of that
wetland toward the southeast airport interchange. In both artworks the old
pick lies farther south, below the wetland, and joins a different crossroad.
The named Dingsi corridor and its position relative to the river/airport
interchange were checked against the rendered
[OSM district map](https://www.openstreetmap.org/#map=14/40.12800/116.44200)
and the preserved named-way geometry. The raster junction itself is not
directly labelled Dingsi in the published artwork, so this remains a
**topology-reviewed manual candidate**, not a surveyed or user-confirmed point.

The revised manifest retains the old coordinates in `swCorrection`, restores
four provisional diagnostic-fit controls, and keeps `runtimeEligible: false`.
The NW, NE and SE picks and all four OSM coordinates are unchanged. The
unwarped comparison board shows green SW markers and displacement arrows,
with red crosses at the rejected positions. The UI review skill guided this
before/after display; the MoonBit skill keeps its generator reproducible.

Corrected hull coverage is **15.264%** of the original and **21.302%** of the
generated canvas. The previous arbitrary 20% acceptance floor is removed:
landmark identity must not be sacrificed to inflate coverage. Convexity,
in-image bounds and nonzero area remain checked. New regression assertions
lock the unchanged SW geographic coordinate and both corrected pixel picks;
the selected crossing counts remain 2/2/4/4. The previous coverage figures
above describe the rejected set only.

The generator and rendered review board were checked after this change.
The targeted camera regression also passes (1/1), using
`moon test --target js main/town_camera_registration_wbtest.mbt` from the UI
module. `moon info`, `moon fmt` and `git diff --check` complete successfully;
there are no tracked `.mbti` interface changes.
No new affine result is claimed here; no camera, road graph, source artwork,
or live town registration was changed.

### Four landmarks carried into the actual terrain grid

`scripts/mark-wenyu-terrain-controls.mbtx` reads the corrected corner manifest
and the provenance in `wenyu_reference_labels.json`. The generated reference
is 1672×941 pixels; the town terrain is 256×144 cells. Consequently the
continuous ground coordinates are `x = pixelX*256/1672` and
`y = pixelY*144/941`, without another affine fit or snapping to OSM roads.

| Control | Continuous terrain coordinate, approximately | Source-pixel containing cell | Stored terrain class |
| --- | --- | --- | --- |
| NW | (111.4641, 5.6621) | [111, 5] | grass-light |
| NE | (230.1244, 63.6599) | [230, 63] | campus |
| SE | (218.9474, 110.4867) | [219, 110] | campus |
| Corrected SW | (83.9043, 67.1796) | [84, 67] | campus |

Containing cells invert the segmentation's **floored source-pixel bounds**;
they are not always `floor(continuousCoordinate)`. For example pixel x=1430
belongs to cell 219 because its source interval starts at floor(219*1672/256).
The script checks this boundary case, source endpoints, pixel/grid round trips
and isometric inverse round trips. Stored terrain classes are reported
literally; they do not independently establish road/bridge identity.

The browser-verified `wenyu-terrain-four-corners.svg` compares the generated
reference, the existing terrain label preview, and a terrain-only projection
using the town's ground axes `screenX=32*(x-y)`, `screenY=16*(x+y)` before
camera translation/zoom. The last panel is explicitly **not a live screenshot**
and excludes the current OSM road overlay. The UI review skill guided this
separation so a misplaced live road cannot redefine a terrain control.
Full coordinates and inherited geographic anchors are saved in
`wenyu-terrain-four-corners.json`. These are transferred versions of the same
four provisional landmarks, not four new independent observations.

Reproduce with `moon run --target native scripts/mark-wenyu-terrain-controls.mbtx`.
Generation assertions, `moon info`, `moon fmt` and whitespace checks pass.
No runtime terrain, roads, camera or registration was changed.

### Four landmarks in the stored road map

`scripts/mark-wenyu-road-controls.mbtx` places the same geographic anchors in
the **stored OSM graph frame, before the live local warp**. It converts WGS84
to UTM 50N, then inverts the existing graph-storage similarity from
`wenyu-town-georef-v1.json`. This is coordinate decoding, not a new fit.
Terrain coordinates are not reused as road coordinates.

| Point | Road-grid coordinate, approximately | Distance to terrain target, tiles | Stored-road coverage |
| --- | --- | --- | --- |
| NW | (105.1686, -50.2464) | 56.2618 | Outside the retained 256×144 crop |
| NE | (237.4401, 52.8135) | 13.0830 | Within 0.0002 tiles of a retained segment |
| SE | (215.4917, 111.6716) | 3.6531 | Inside frame, but nearest retained segment is 8.4175 tiles away |
| Corrected SW | (65.3110, 45.9834) | 28.1955 | Within 0.022 tiles of a retained segment |

The NW and SE controls must **not** be described as four existing routing
junctions in the stored graph. NW was cropped out; the SE geographic centre
falls in a stored-geometry gap. The nearest segment is reported solely as a
coverage diagnostic, never substituted for the named landmark. The cause of
the SE gap has not been diagnosed in this step. NE/SW proximity is consistent
with the decoded coordinate frame, but proximity alone is not semantic proof.

`wenyu-road-four-corners.svg` keeps all **775 edges and 3980 vertices** in gold,
adds a separately dashed named-way/rivers context from the preserved September
OSM snapshot, and compares road anchors (pink circles) with terrain targets
(green crosses) on identical axes and scale. The grey context is not merged
into the graph. An expanded viewport reveals NW rather than clipping its pin.
These offsets are pre-warp discrepancies, not measurements of the current
live camera or the locally warped runtime overlay.

`wenyu-road-four-corners.json` stores coordinates, signed deltas, offsets and
nearest-edge diagnostics. The MoonBit generator asserts edge/vertex counts,
UTM central-meridian origin, similarity round trips, a segment-distance case,
and the four observed coverage conditions. The UI review skill guided the
separation of geographic anchors, missing geometry and terrain targets.
No runtime or source-map data is modified.

### Geographic road rebuild against the fixed terrain — 2026-09-06

Implemented a new mode in `scripts/fit-wenyu-common-osm.mbtx`. It starts from
geographic OSM ways, not the already cropped 775-edge graph. The pipeline is:

`WGS84 ways → UTM 50N → centered four-corner affine → fixed 256×144 terrain → display clipping`

The old graph, terrain raster, semantic labels and live registration are
unchanged. No local warp, snapping to roads, water-avoidance deletion, vertex
simplification or inferred crossing connections are used in this rebuild.
The affine solver subtracts the source and destination centroids before solving
the linear part, then restores the translation. Its source covariance condition
is 3.8165, substantially better spread than the previous bridge-chain fit.

#### Preserved geographic source

`wenyu-full-osm-reference.json` contains the Overpass response with OSM base
timestamp **2026-09-06T00:37:05Z**. The query covers latitude 40.07–40.19 and
longitude 116.34–116.53 and returns full geometry of matching highway and river
ways. “Uncropped” here means no old tile-frame crop is applied; this is still a
finite geographic extract, not a completeness claim for all OSM.

The candidate preserves **6,420 highway ways, 44,343 road vertices, 338
bridge-tagged highway ways and 30 river ways**. Road way IDs, ordered node IDs,
original WGS84 vertices and tags remain available alongside projected paths.
Road way counts are not directly comparable with the old graph's 775 split
edges. All named main-carriageway IDs used at the four corners are asserted
present, including the previously absent NW and SE context. This restores
source coverage; it does not certify exact alignment or routing connectivity.
The source is attributed to OpenStreetMap contributors under ODbL 1.0.

#### Affine and validation

For UTM easting `E`, northing `N` in metres, terrain coordinates are:

```text
x = 0.021505258512121966 E + 0.006746213366656356 N - 39536.72962121634
y = 0.0059070093413763234 E - 0.01658978691507238 N + 71085.21861921487
```

The four provisional corner correspondences have equal fitting weights.
Legacy Q/X/C/G bridge picks are excluded from the solve and reported separately.
They are held out from this fit, **not newly surveyed or independently verified
ground truth**. Their errors combine possible correspondence error and model
error; they must not be moved toward predictions simply to reduce residuals.

| Check | Error in terrain tiles |
| --- | ---: |
| NW, fitted | 2.21 |
| NE, fitted | 3.67 |
| SE, fitted | 3.62 |
| SW, fitted | 2.16 |
| Q — Qinbei, held out | 12.91 |
| X — Science City East, held out | 4.78 |
| C — Jingcheng, held out | 0.46 |
| G — Science City Road, held out | 7.52 |

Fitted RMS is **3.01 tiles**; held-out RMS is **7.85 tiles**. The numerical review
gates are maximum fitted error ≤4 tiles and maximum held-out error ≤3 tiles.
These are provisional engineering thresholds, not survey accuracy guarantees.
The held-out gate fails. Manual correspondence acceptance also remains false.
Accordingly `wenyu-rebuilt-road-candidate.json` has `runtimeEligible: false`
and is deliberately not installed as the town's live road source.

#### Visual review and remaining work

`wenyu-rebuilt-roads.svg` compares the historical pre-warp graph with the new
candidate over the identical fixed reference image. It overlays current OSM
river geometry using the same affine, so river-shape discrepancies can be
inspected without assuming every mismatch is a road-rendering problem. The
browser screenshot was inspected; labels, residuals, source attribution and
non-promotion status are visible. The UI review skill guided this explicit
separation of source coverage, observed landmarks and predicted positions.

The wider source and four-corner calibration improve the outer network, but
central bridge discrepancies remain. This evidence does not establish that
another camera pitch adjustment can solve them. Next, independently re-identify
Q/G/X on both images and current OSM, keeping the corner controls fixed. If
those correspondences are valid, test whether a global model is adequate for
the designed image before considering any explicitly documented design-specific
deformation. Do not silently bend the terrain to the present-day map.

Offline reproduction from the preserved response:

```sh
WENYU_FOUR_CORNER_FIT=1 WENYU_FULL_OSM=docs/project/wenyu-full-osm-reference.json moon run --target native scripts/fit-wenyu-common-osm.mbtx
```

The generator checks synthetic affine recovery, composition and inverse round
trips, centering, singular/collinear rejection, the UTM central-meridian origin,
unique way IDs, vertex/node count preservation, corner carriageway presence and
retention of out-of-frame vertices. `moon info`, `moon fmt` and the targeted
`town_camera_registration_wbtest.mbt` test pass (1/1). No public interface changes
are intended. This is an authoring rebuild and review artifact, not a completed
live-map calibration.

### Denser perspective calibration — 2026-09-06

The next review uses **13 landmark correspondences: 10 fitting points and 3
held-out checks**, frozen in `wenyu-dense-image-picks.json` before running the
fits. Four perimeter controls retain their previous terrain targets. Nine
additional road/river or road/road correspondences extend the checks through
the river corridor and southern streets. These remain manually identified
design-image candidates, not survey observations.

`scripts/fit-wenyu-dense-perspective.mbtx` derives named centerline crossings
from the preserved OSM geometry and records the contributing way IDs in
`wenyu-dense-source-landmarks.json`. Paired carriageway crossings are averaged;
their spread is recorded and bounded. A geometric crossing does **not** create
a routing connection. Proposed pairs with no matching geometry are not invented.

The source atlas and magnified pure-image coordinate view were inspected before
fitting. In particular, Qinbei's previous image pick `(1202,415)` was off the
diagonal bridge deck identified in this review; the new provisional pick is
`(1177,451)`. Fresh road–river centers replace legacy approximate map-click
geography for all five river crossings. The old files are preserved, and old
residuals are not directly compared with these revised correspondences.

#### Model comparison on exactly the same expanded set

| Model | Fitting RMS, tiles | Held-out RMS, tiles |
| --- | ---: | ---: |
| Previous four-corner affine, evaluated on new points | 5.74 | 4.06 |
| Affine fitted to the 10 training controls | 4.28 | 3.58 |
| Perspective fitted to the same 10 controls | **2.24** | **3.21** |

All fitting points have equal weight. No point is removed because of its
residual. The perspective model starts from normalized linear least squares
and is refined by minimizing geometric reprojection error. The three held-out
targets are never passed to that objective. Leave-one-training-point-out errors
are also recorded for both refitted models: the largest is 14.84 tiles for the
affine and 4.83 for the perspective model. This sensitivity check is not a
substitute for more independently established geographic correspondences.

The held-out bridge errors are **1.07 tiles** at Future Science City Road (R7)
and **1.09 tiles** at Jingcheng (R9). The provisional Litang–Beiqing street point
(S1) remains **5.35 tiles** off; it was marked low confidence before fitting and
is retained visibly in the score. Its image correspondence or the design's
street arrangement needs further verification. In particular, the new model
improves held-out RMS but has a worse maximum held-out error than the 10-point
affine (5.35 versus 4.86 tiles). Do not claim every street improved.

#### What the perspective term represents

The correction is a single planar homography, not a freeform local warp.
It permits position-dependent scale while retaining straight-line projective
geometry. Its area-equivalent local linear scale relative to the prior affine
is approximately **0.80× at NW and 1.23× at SE**. That is consistent with the
user's observation that a constant-scale affine was missing a near/far effect;
it does not prove that a physical camera alone caused every mismatch.

Camera yaw/pitch/roll and focal length are not uniquely recovered here. A
homography describes the planar mapping; physical pose recovery additionally
depends on camera calibration and assumptions. See the primary
[OpenCV homography explanation](https://docs.opencv.org/4.5.1/d9/dab/tutorial_homography.html).
An AI-generated design can also change individual street and river shapes.

The normalized correction matrix is stored in `wenyu-dense-perspective.json`.
Normalize both grid frames with `((x-128)/100, (y-72)/100)`; apply the stored
3×3 matrix with `h33=1`; divide by the projective denominator; denormalize.
Its input frame is the previous affine's output only for numerical convenience.
All full geographic ways are still present, so this does not reintroduce the
old storage crop. The complete mapping is the normalized projective correction
composed after the recorded WGS84 → UTM → four-corner affine chain.

All **6,420 ways and 44,343 road vertices** survive projection with their source
IDs, ordered nodes, tags and original WGS84 geometry. The denominator is positive
at every source vertex (range 0.0784–1.5268), so it cannot cross zero along a
straight source segment. The homography determinant is positive. Extrapolation
far outside the landmark footprint can still have strong scale changes; pole
safety alone does not imply geographic accuracy. Viewport clipping is applied
after projection. No runtime road source, terrain, topology or camera changes.

#### Review and verification

`wenyu-dense-perspective.svg` was inspected in the browser. The UI review skill
guided distinct fitting/held-out markers, residual lines, identical background
and viewport sizes, and a visible comparison table rather than hiding weak
points in a visually attractive overlay. R7/R9 alignment improves visibly;
S1 remains explicitly unresolved. The 3-tile maximum held-out gate still fails,
and `runtimeEligible` and manual acceptance remain false.

Reproduce offline:

```sh
WENYU_DENSE_FIT=1 moon run --target native scripts/fit-wenyu-dense-perspective.mbtx
```

The generator tests synthetic affine/projective recovery, a new-point prediction,
singular rejection, a denominator pole, a segment crossing, orientation and
source counts. It also stores a leave-one-out sensitivity audit. `moon check`
passes with existing workspace warnings; the targeted camera registration test
passes (1/1); `moon info` and `moon fmt` pass with no generated interface changes.

### Bottom-left and bottom-right coverage — eight additional candidates

Added **three bottom-left and five bottom-right** correspondences, bringing the
review to **21 points: 15 fitting controls and 6 held-out checks**. The prior
13-point JSON/SVG and its image picks remain intact. New source intersections
are in `wenyu-lower-source-landmarks.json`; image observations, uncertainty,
roles and revisions are in `wenyu-lower-image-picks.json`.

| ID | Named OSM intersection | Terrain-image pixel | Role |
| --- | --- | --- | --- |
| BL1 | 回南路 × 奥北公园西路 | (72,735) | Uncertain correspondence; validation-only |
| BL2 | 回南北路 × 奥北公园西路 | (103,633) | Uncertain correspondence; validation-only |
| BL4 | 立汤路 × 太平庄北街 | (335,918) | Fit; provisional near-edge pick |
| BR1 | 未来科学城路 × 英才南三街 | (1184,727) | Fit |
| BR4 | 鲁疃东路 × 英才南三街 | (1361,785) | Fit |
| BR7 | 未来科学城路 × 七北南路 | (1135,866) | Fit |
| BR8 | 未来科学城东路 × 七北南路 | (1204,888) | Validation-only |
| BR10 | 鲁疃路 × 七北南路 | (1258,902) | Fit |

These are topological design-image candidates, not surveyed coordinates.
The added right-side points were checked in a pure-image crop magnified roughly
3× with 10-pixel coordinate ticks. This caught several initial overview picks
inside building blocks rather than street centers. The refined pixels above
come from visible road junctions, not fitted predictions; `previousPixel` and
the reason for each correction are preserved. BR8 remains excluded from the
objective throughout. The UI review skill prompted this extra pixel-level
inspection instead of relying on the whole-town overlay.

The western pair is qualitatively different. Current OSM has two closely spaced
crossings, while the proposed design counterparts are separated by a large
green block. That may indicate altered layout or an incorrect correspondence.
BL1 and BL2 are therefore **checks of an unresolved hypothesis**, not reliable
ground truth, and neither influences the fit. BR9 (京承高速 × 定泗路) is omitted:
the simplified design highway/ramp geometry has no unambiguous counterpart.

`wenyu-lower-detail.svg` shows enlarged OSM and design panels for both lower
areas, with the eight IDs on both sides. Asterisks/white circles distinguish
validation-only observations. `wenyu-lower-perspective.svg` shows the full
21-point comparison. Both views were inspected in the browser.

#### Refit and explicit limitations

On the expanded set, the previous preview has fitting RMS 3.21 tiles and
held-out RMS 7.02 tiles. The new conservative projective refinement produces
2.99 and 6.91 tiles respectively. These are **not** directly comparable with
the earlier 13-point scores: the point set and several new image observations
are different. The unresolved BL1 check alone is 14.95 tiles off; the added
BR8 held-out junction is 4.61 tiles off. This step expands evidence coverage;
it does not complete lower-area alignment.

The unconstrained 15-control solution introduced a denominator sign change in
the wider OSM extract (minimum −0.13645). It was retained in the report as a
rejected candidate, not drawn as a valid full-source overlay. A guarded
refinement starts from the previous pole-safe preview and accepts only
positive-determinant, error-reducing steps whose denominator stays above 0.05
at every source vertex. The displayed candidate's range is
0.0500036–1.54190. Because the denominator is linear along each straight source
segment, this also prevents a segment from crossing a pole. This is a
conservative full-extract constraint and a feasible backtracking refinement,
not a claim of a globally optimal constrained fit or proof that a different
camera model cannot work.

All 6,420 highway ways and 44,343 road vertices retain their original geographic
geometry and tags. Terrain and the live town remain unchanged. Both the fitted
maximum-error and held-out maximum-error gates still fail; runtime eligibility
and manual acceptance remain false. Source coverage, uncertain correspondence,
fit quality and projection safety remain separate findings.

Reproduce the added-point review without overwriting the 13-point artifacts:

```sh
WENYU_LOWER_POINTS=1 WENYU_DENSE_FIT=1 moon run --target native scripts/fit-wenyu-dense-perspective.mbtx
```

The generator's existing affine/projective tests pass, with an additional
synthetic constrained-refinement test that verifies denominator safety and
reduction in geometric error. Generation also asserts 21 controls, six
holdouts, source counts and source-intersection spreads. No new runtime API is
introduced.

### Directional stretch sensitivity trial

The user's suggestion to stretch the bottom/left side is tested separately in
`scripts/trial-wenyu-directional-stretch.mbtx`. This is a manual sensitivity
experiment over the current 21-point preview, not another landmark fit. The
terrain, all image observations and the earlier reports remain unchanged.
“Bottom-left” means the displayed map direction; no physical camera pose or
near/far distance is inferred.

With the opposite top-right corner `(256,0)` held fixed, the additional
homography is:

```text
w  = 1 + k*((x-256)/256 - y/144)
x' = 256 + (x-256)/w
y' = y/w
```

At the bottom-left corner, distance from the pivot increases by `1/(1-2k)`.
This is a position-dependent projective adjustment, **not** a uniform 2% or 4%
scale and not a change to the terrain. The compared strengths are fixed at
0, 0.01 and 0.02 rather than optimized using validation observations.

| Trial | Bottom-left radial gain | Fitting RMS, tiles | Validation RMS, tiles |
| --- | ---: | ---: | ---: |
| Current 21-point preview | 1.0000× | 2.99 | 6.91 |
| Gentle, k=0.01 | 1.0204× | 2.93 | 5.70 |
| Stronger, k=0.02 | 1.0417× | 3.93 | 5.77 |

The gentle adjustment is the most promising of these three trials: it improves
both aggregate scores. Doubling it worsens fitting RMS. This supports testing
a small directional stretch, but does not establish that perspective alone
explains all streets. Validation includes the previously flagged uncertain
western correspondences, and remaining individual residuals are stored in
`wenyu-directional-stretch.json`. No trial is runtime-eligible or automatically
promoted.

The three-column `wenyu-directional-stretch.svg` shows identical full-town
viewports plus enlarged bottom-left details. The UI review skill guided the
matched scales and fixed landmarks so that the visual effect can be compared
directly. The rendered browser view was inspected; the middle trial moves the
western corridor in the suggested direction without the stronger trial's larger
displacement elsewhere.

The renderer clips segments against destination homogeneous half-spaces before
dividing by W. This prevents potential distant segments from being drawn across
infinity without deleting or rewriting their source geometry. Actual counts of
vertices behind the trial horizon are recorded (zero in all three trials).
This display-clipping implementation does not change the earlier full-extract
acceptance rule or claim a pole-unsafe model has passed it. All 6,420 source ways
and 44,343 vertices are traversed. Original source geometry and IDs remain in
the referenced input candidate.

Reproduce with `moon run --target native scripts/trial-wenyu-directional-stretch.mbtx`.
Assertions cover a fixed pivot, expected directional gain, in/out-of-viewport
segments, a horizon-crossing segment, source counts and finite viewport bounds
for every rendered segment. This is an authoring preview only; the live town
is unchanged.

### Optimized directional parameters (2026-09-06)

The follow-up search keeps the fixed terrain, top-right pivot and all 21 image
picks. It searches two nested additional-homography families over the previous
21-point projection, not over raw latitude/longitude:

```text
w = 1 + kLeft*(x-256)/256 - kBottom*y/144
x' = 256 + (x-256)/w
y' = y/w
```

The simpler family sets `kLeft = kBottom`. Each coefficient is searched in
`[-0.08, 0.08]` on a 0.001 grid, followed by 18 step halvings of a local neighbor
search, with at most 100 sweeps per scale. The objective is unweighted squared
Euclidean error on the 15 fitting landmarks only. Neither optimum hits the
search boundary. "Best" here means best found within this family, bounds and
frozen manual observations; it does not identify physical pitch/roll/yaw or
establish a globally optimal registration.

| Candidate | kLeft | kBottom | Fitting RMS, tiles | Withheld RMS, tiles |
| --- | ---: | ---: | ---: | ---: |
| Previous gentle trial | 0.010000 | 0.010000 | 2.93072 | 5.70234 |
| Best equal-strength fit | 0.0055659332 | 0.0055659332 | 2.80964 | 6.11262 |
| Best separate-strength fit | -0.0032560959 | 0.0119559708 | 2.78473 | 6.37969 |

The equal-strength optimum moves the bottom-left corner about 1.13% farther
from the fixed pivot, versus 2.04% previously. The split optimum prefers a
small left-side contraction and bottom-side expansion: the fitting picks do
not support progressively increasing both strengths. Extra numerical digits
make replay reproducible, not geographically accurate.

There is **no overall winner**. For example, the equal-strength fit improves S4
from 4.00 to 2.39 tiles, but worsens BL4 from 1.08 to 2.17 and the uncertain BL1
from 12.44 to 13.46. The split model saves only another 0.025 fitting tiles while
worsening aggregate withheld error. Keep the gentle preview as the comparison
reference; do not automatically replace it with a fit-only winner. The six
withheld points never enter the objective, but have been repeatedly inspected
through this investigation, so they are not fresh independent validation.
BL1/BL2 remain uncertain image-to-geography correspondences, not survey control.

The full-town plus bottom-left and bottom-right comparisons are in
`wenyu-optimized-stretch.svg`; every point's error and change from the gentle
trial are in `wenyu-optimized-stretch.json`. The UI review skill guided identical
viewports, visible parameter labels, both lower-corner crops and explicit
trade-off labeling. The rendered browser artifact was inspected. Visible
residual street mismatch remains; finer parameter search alone cannot establish
whether those mismatches are projection error, uncertain correspondence, or
differences between the designed place and current OSM.

All three finalists traverse 6,420 ways and 44,343 source vertices. Minimum
additional-transform denominators are respectively 0.977932, 0.987717 and
0.971255, with zero vertices behind the additional horizon. Clipping remains
display-only. These checks do not certify the earlier 0.05 full-composition
acceptance gate; `runtimeEligible` stays false and the live map is unchanged.

Reproduce with:

```sh
WENYU_OPTIMIZE_STRETCH=1 moon run --target native scripts/trial-wenyu-directional-stretch.mbtx
```

Default invocation still generates the original three sensitivity trials.
New assertions recover known synthetic equal/split parameters, prove an extreme
withheld observation cannot alter the selected parameters, verify control IDs
and the 15/6 split, and check every finalist's full-source horizon and viewport
clipping. Both modes ran successfully. `moon info`, `moon fmt` and the targeted
camera registration test passed (1/1); generated `.mbti` files are unchanged.

### Gentle roads projected onto the running terrain

The user explicitly approved trying the gentle `0.01 / 0.01` candidate on the
fixed terrain. Open `index.html?road-trial=gentle` for the switchable, terrain-only
trial. The normal URL continues to use the existing scene. This is approval to
show the candidate, not acceptance of its geographic accuracy or routing graph.

`WENYU_PROJECT_TERRAIN=1 moon run --target native scripts/trial-wenyu-directional-stretch.mbtx`
exports a transparent, design-grid SVG and `wenyu-gentle-ground-trial.json`.
The generator uses the same clipped gentle paths as the reviewed comparison,
checks 6,420 ways / 44,343 vertices, and preserves original source geometry in
the referenced candidate. No second fit, centering adjustment, or legacy local
warp is applied. The browser transports the SVG as an image; MoonBit remains
the authoring/calibration implementation.

The trial paints the existing canonical terrain, then applies the shared ground
camera to the road overlay: `(32x-32y, 16x+16y)`, followed by ordinary pan/zoom.
Terrain data, shoreline coordinates and semantic world state are unchanged.
Old road pixels are hidden with the existing neutral-ground recovery; old-fit
buildings and decorative walkers are omitted so they cannot obscure this test.
The view starts at whole-map scale and keeps subsequent camera movement free.
A visible trial notice and return link separate it from ordinary operation.
The accepted semantic canvas frame is cleared; this overlay is not navigation
authority. Existing calibration residuals and uncertain correspondences remain.

UI review kept the actual ground painter and camera rather than introducing a
different background. The desktop browser was inspected at the initial detail
scale and the final whole-map framing. The golden road network renders on the
isometric terrain; this does not imply every street now matches perfectly.
The generator assertions pass, JS checking and release compilation succeed,
and both camera-registration tests pass (2/2), including the new overlay at
three pan/zoom settings. `moon info` and `moon fmt` ran; no generated `.mbti`
changes. Broader gameplay/mobile tests were not run for this read-only trial.

### Whole riverside corridors, not per-point bank warps

The user rejected the local riverbank-clearance experiment because it made the
roads wavy, then clarified the intended operation: move the whole riverside
road while retaining its shape. The tile-normal adjustment and subsequent
filtered-displacement experiment are superseded, not accepted. Their lower
water-overlap scores did not establish acceptable road geometry. The historical
`adjust-wenyu-riverbanks.mbtx` can no longer overwrite the active overlay.

The active `shore=1` trial is now generated by
`moon run --target native scripts/translate-wenyu-riverside-corridors.mbtx`.
It starts again from the gentle global fit, not from either local-warp result.
One constant `(dx,dy)` is applied to all non-exempt OSM ways carrying each of
three verified riverside road names. There is no independent vertex movement,
per-way fit, smoothing of the source curve, or terrain adjustment.

| Whole corridor | Translation in terrain tiles | Sampled water overlap before → after |
| --- | --- | ---: |
| 温榆河左堤路 | (+1.0, −1.1) | 733 → 296 |
| 温榆河右堤路 | (−1.3, −0.7) | 427 → 390 |
| 温榆河绿道昌平段 | (+1.4, −0.4) | 275 → 134 |

Offsets are selected on a 0.1-tile grid within a 1.5-tile radius using uniform
quarter-tile samples and squared bank-clearance deficit with a movement penalty.
They are conservative placement candidates, not recovered camera parameters or
a claim that one translation fully resolves a curved shoreline. These sample
counts cover only the selected corridors and are not comparable to the earlier
all-road, differently sampled local-warp score.

All 338 tagged bridge ways, plus tagged tunnels/fords, stay exactly unchanged.
Rigidly shifting a road while fixing adjoining roads necessarily separates some
old shared junction positions. The preview represents those connections with
89 explicit, short display-only approach connectors at actual shared OSM node
IDs; it does not bend the shifted corridor or move a bridge deck to hide this.
Connector provenance and endpoints are recorded in `wenyu-rigid-corridors.json`.
These are not new accepted routing edges, and geographic source IDs/geometry
remain immutable in the referenced input. All 6,420 source ways / 44,343 source
vertices remain accounted for.

The generation assertions verify preservation of every segment length and
direction under translation, and exact equality of exempt bridge paths.
`wenyu-rigid-corridors.svg` compares the original and rigid placements, with an
enlarged river bend. The UI review retains identical views and original road
curves rather than optimizing pixel clearance at their expense. The active
runtime asset is `tilemap/wenyu-rigid-road-overlay.svg`; the previous bank
asset is not used. Terrain, camera projection and normal scene routing are
unchanged. Residual overlap and approach design still require review.

### Restore pads, green spine, architecture and characters in the rigid scene

The ground-only trial retained stale pale building pads from the semantic
snapshot while suppressing their buildings. Its old generated landscape spine
also had no placement relationship to the newly accepted display roads.

The rigid-corridor MoonBit generator now also emits `wenyu-rigid-scene.json`:
conservative road occupancy from the exact displayed polylines (including the
89 approach connectors), and complete in-bounds street paths for animation.
All original 6,420 ways and 44,343 road vertices remain in the road overlay.
The green spine uses the translated Changping greenway itself, clipped against
the fixed authored water mask; it does not move water or bridge geometry.

In the `road-trial=gentle&shore=1` preview, obsolete snapshot ground overlays are
replaced with reference-derived natural ground. New pads share their buildings'
anchors. Curated and procedural architecture reuse the existing spring assets,
scale rules and deterministic relocation, but validate their full footprint and
apron against the new road occupancy and fixed water/wetland/woodland exclusions.
Summed-area tables make these placement checks constant-time. Access paths are
display-only and refuse water/forest crossings; nearest-path queries are cached.

Twelve existing character sprites animate on the same corrected road curves,
at constant distance speed with continuous endpoint reversal. Reduced-motion
mode freezes their travel and bobbing. Buildings and characters are depth sorted
using the same ground camera. This restores scene artwork, not operational
agent routing, building entrance authority, or semantic hit areas. The original
gentle-only comparison and normal town remain separate.

Desktop browser verification showed 36 image-backed buildings, zero invalid
lots and zero overlapping lot pairs. Two new regression tests cover occupancy
rectangle boundaries and curved-path motion/endpoint reversal. The MoonBit skill
kept scene generation and movement in MoonBit; UI/UX guidance preserved the
existing artwork and required rendered checks rather than code-only validation.

Verification: 14 focused tests passed (2 new scene tests, 10 existing placement
tests, 2 camera registration tests); JS check/release build passed with existing
warnings. `moon info` and `moon fmt` completed with no public-interface diff.
Browser checks covered overview, zoom and animated character movement; phone
layout and operational agent navigation are not claimed as validated here.

### Undo riverside shifts; promote the retained scene to the production entry

User clarification: undo **only** the three riverside translations, preserving
buildings, characters, pads and the green spine, then merge into production.
The generator now disables shoreline fitting: all three applied translations
are `(0,0)`. Assertions verify that every complete road path equals the original
gentle projection and no shifted/unshifted junction connectors remain (0 vs 89).
All 338 bridge ways and the fixed authored water geometry remain unchanged.
Earlier shifted reports/assets are retained as historical evidence.

Active assets are now `wenyu-unshifted-road-overlay.svg` and
`wenyu-unshifted-scene.json`. Road occupancy, access endpoints, greenway planting
and animation paths are rebuilt from the unshifted coordinates. The normal
`index.html` outdoor view selects this presentation without any trial query;
the normal HUD, indoor/underground routes, user-created roads/buildings/scenery
and the previous semantic accepted-frame contract are retained. Runtime actor
interaction eligibility stays false for decorative road walkers. This is a
production **presentation** change, not a new operational routing graph.

The legacy `shore=1` review link remains compatible but no longer enables any
translation. Production omits the comparison banner/footer; explicit review
URLs still expose comparison UI. SVG packaging shares stroke styles, omits
only fully off-map geometry and rounds render/animation coordinates to four
decimal places (at most 0.00005 tile per axis). Source evidence and the exact
rollback assertions remain full precision. This keeps the release inside its
existing size limit without simplifying visible road topology.

The full production builder assembled and verified 277 files at 69.0 MiB
(within the existing 69 MiB byte limit). Browser verification on plain
`index.html` reported the overlay ready, riverside shifts false, 36 image-backed
buildings, 0 invalid lots and 0 overlapping pairs. The previous dist, including
authoring review pages, was backed up before deterministic release assembly at
`/private/tmp/moontown-pre-production.GLRRKm/dist`; original review documents
also remain under `docs/project/`. No remote deployment or Git push was made.
