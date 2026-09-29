# Wenyu landmark studio — implementation and evidence review

Date: 2026-09-06. User approved the reference direction and requested multi-angle research followed by draggable 3D studies with surroundings and lighting. All four named landmarks are included; “three visualisation” was interpreted as the requested 3D visualizations, not an instruction to omit one landmark.

## Outcome and boundary

Implemented an isolated MoonBit model module with a Three.js browser adapter at `src/ui/landmark-studio/`. Local preview: `http://127.0.0.1:17843/index.html`. Four selectable dioramas; no edits to the production town map, roads, bearings, semantic entities or asset manifest.

The office developments remain coherent groups. Bridges have their own river settings. Context includes planted banks or campus grounds, varied trees, flowers, walking paths, benches, lamps, vehicles and people. This environmental composition is illustrative, not a surveyed reconstruction.

The UI/UX reference-review skill prioritized architectural silhouette and a dominant inspectable scene, with quiet controls rather than a dashboard of cards. MoonBit owns model coordinates, curves, facade subdivisions, structural members, landscaping and metadata. JavaScript is the generic Three.js rendering/UI boundary expressly requested for this study.

## Additional multi-angle research

All images below were visually inspected in the browser, beyond the original reference set. Source photos are linked, not downloaded into the product.

### 未来中心

[Official project profile](https://www.kechuangfuwu.com/vue/parkService/project?id=31).

- [Annotated aerial rendering](https://www.kechuangfuwu.com/ueditor/fileupload/file/20190821/1566354187609093039.jpg): six lower courtyard blocks plus the taller No. 7 composition; the image labels lower blocks 45 m and No. 7 80 m. These are design-reference heights, not independently measured as-built values.
- [Other oblique grouping diagram](https://www.kechuangfuwu.com/ueditor/fileupload/file/20190821/1566353869691079929.jpg): confirms the ordered rows, landscape gaps and separate taller group. It is a diagram, not a current photograph.
- Together with the previously inspected [axial photograph](https://www.kechuangfuwu.com/ueditor/fileupload/file/20240726/1721961738519014567.jpg), these inform courtyard voids and pale facade frames. Floor rhythm and unseen elevations remain simplified.

### 未来视界

[Official project profile](https://www.kechuangfuwu.com/vue/parkService/project?id=36).

- [Axonometric program diagram](https://www.kechuangfuwu.com/ueditor/fileupload/file/20240725/1721878090189018180.png): shows three taller volumes and three connected, lobed creative-office footprints, with roof-garden spaces.
- [Six-building composition diagram](https://www.kechuangfuwu.com/ueditor/fileupload/file/20190821/1566375938137062237.jpg): another supporting massing view.
- These corrected an overly generic rounded-box interpretation. The model uses sampled closed curves for the lower offices and perimeter-following mullions/amber strips. Exact outlines and heights are provisional, with no claim to reproduce the diagram's areas.

### Both bridges

[Official government aerial photograph, published 2023-04-03](https://www.beijing.gov.cn/renwen/bjgk/cpgk/cpfg/202304/t20230403_2965742.html): [full image](https://www.beijing.gov.cn/renwen/bjgk/cpgk/cpfg/202304/W020230403544690157686.jpg).

This supplies a useful common context: the wave bridge in the foreground and the arch crossing behind, with wooded riverbanks and approach roads. Identification is cross-checked against the explicitly captioned [operator's bridge article](https://www.kechuangfuwu.com/vue/news?id=7526), rather than inferred from the aerial page's generic caption alone.

- [Wave-lattice interior](https://www.kechuangfuwu.com/ueditor/fileupload/file/20220713/1657702803895058089.png): a narrow pedestrian route inside the lattice. Combined with the aerial, this supports keeping the main carriageway open and placing the lattice at its edges. Transverse profiles and exact member spacing are approximations.
- [Arch bridge approach at night](https://www.kechuangfuwu.com/ueditor/fileupload/file/20220713/1657702803546035447.png): shows the ribs leaning inward toward the crown; the model uses a six-sided swept section instead of a constant-radius tube.
- [Construction contractor's account](https://szjt.bmrb.com.cn/menu173/newsDetail/4042.html) independently describes 鲁疃西路桥 with a 45 m full deck width and 568 m total length. The study models a cropped crossing with illustrative approaches; it does not relabel the full length as the arch span.

## Review and corrective passes

- Reduced excessive fill light and exposure after the first screenshots washed out facade and planting colors.
- Corrected default camera framing to reduce empty headroom; responsive resize preserves an appropriate fit instead of cropping the scene on a narrow screen.
- Excluded the exhibition plinth and studio floor from the reflected view after discovering they obscured the river reflection.
- Improved contrast of canvas annotations in blue-hour mode.
- Kept model and landscape geometry separate for contextual versus isolated inspection; clay mode affects the architecture, not the whole scene.
- Pinned renderer dependencies locally and kept original photographs out of runtime textures.

## Validation and known limits

`moon check`, `moon test` (5 passing), `moon info`, `moon fmt`, release build and `.mbtx` assembly completed for the standalone module. The generated public interface exposes one function returning renderer-neutral study data.

Browser review: all four scenes displayed; drag changed horizontal and vertical camera angles; keyboard orbit and zoom changed the camera; rear/clay/isolation and top/orthographic views displayed correctly; lighting switches altered the scene; the reference gallery loaded its source images. The 390 × 844 layout was inspected and its initial framing corrected. No runtime JavaScript errors were observed in these checks. Touch hardware and physical right-button panning were not separately tested.

These are reference-led, stylized architectural studies. No surveyed model coordinates, exact rear elevations, engineering-certified geometry, calibrated integration bearings or accurate surrounding parcel maps are claimed. Lattice density, hanger geometry, floor rhythm and some heights are approximated. The next gate is the user's visual review, followed by refinement and only then map integration approval.

## Detail refinement — 2026-09-06

Request: retain the accepted general shapes, find additional photographs and refine the models. The pass remains isolated from the town map and on `main`; no commit or push was requested.

### Seven additional photographs inspected

All seven were opened and visually inspected, not selected from search captions alone. They are now at the front of the corresponding in-viewer galleries (21 entries / 20 distinct images overall).

- Future Center: [axial facade photograph](https://5b0988e595225.cdn.sohucs.com/images/20191205/4b8941fb89cd489cb8076f4f03829914.jpeg) and [courtyard-side interior glazing photograph](https://5b0988e595225.cdn.sohucs.com/images/20191205/8d5162cd9fba47eeae75c16b1320404e.jpeg), published in the [2019 project article](https://www.sohu.com/a/358608273_100004382). These show pale vertical framing with finer dark glazing divisions, transoms and planted edges. They are not measured elevation drawings.
- Future Vision: [oblique campus photograph](https://www.kechuangfuwu.com/ueditor/fileupload/file/20240725/1721893131158088336.jpg) and [ground-level tower entrance photograph](https://www.kechuangfuwu.com/ueditor/fileupload/file/20240725/1721890845348050943.jpg) from the [park operator](https://www.kechuangfuwu.com/vue/parkService/project?id=36&menu=%E9%A6%96%E9%A1%B5). These resolve finer glazing grids, roof-edge planting, amber strips and an arrival canopy. The model adds small entrance assemblies; it does not claim an exact reconstruction of the hotel's larger canopy.
- East bridge: [low riverbank photograph](https://r1.visitbeijing.com.cn/vbj-s/2017/1225/20171225051108793.jpg), published by [Visit Beijing](https://s.visitbeijing.com.cn/gallery/7172), with SIPA attribution retained. It supplements the existing pedestrian-interior photograph with the edge girder and V-pier relationship. Source image rights remain with the publisher.
- Arch bridge: [riverbank inspection photograph](https://file.bmrb.com.cn/file/upload/2023/01/28/1674887088490.jpg) and [walkway close-up](https://file.bmrb.com.cn/file/upload/2023/01/28/1674887187558.jpg), from the [municipal engineering institute's 2023 inspection report](https://www.szgcyjy.com/menu143/newsDetail/14766.html). These reveal arch panel joints, horizontal railings, slab paving and the darker bridge fascia. The report covers several bridges: only the explicitly captioned Future Science City images were used.

### Implemented details

- Bridge architecture: rectangular wave-lattice diagonals, base plates, arch panel seams, hanger end sleeves and foot fittings, inner pedestrian rails, tile joints, tactile strips, drainage grates, expansion joints and forked streetlights. The arch curve, wave envelope, main layout and open carriageway are retained.
- Under-deck review: an initial exposed girder grid looked too prominent in reflections and did not match the documented box-girder structure. Replaced it with a closed dark soffit and restrained edge flanges.
- Office architecture: recessed-looking spandrel bands, secondary mullions/transoms, courtyard-facing glazing grids, inset roof finishes, parapets, screened plant equipment, planted roof edges, door frames/handles, canopy framing and project-name signage.
- Context: continuous curved bank paths replace the prior chain of short paving boxes; reeds and stones add shoreline scale. Landscape layout remains illustrative.
- Inspection UX: a model-authored Detail target and camera offset for each study; users can continue freely orbiting from these close-ups. Generic oriented-section and sign rendering remain in the Three.js adapter; all model placement and dimensions remain MoonBit-authored. Repeated parts are instanced and generated sign textures are disposed on model switches.

The UI/UX skill drove close-range visual verification and the direct Detail control, while the MoonBit guide kept the geometry and regression checks in the model module. No new runtime dependency or remote script was added.

### Validation and remaining uncertainty

MoonBit check, **7 tests**, info, formatting, release build and assembly pass. The public interface remains `studies() -> Json`; new detail metadata is renderer-neutral JSON. Tests additionally guard rectangular wave-member counts/endpoints and bridge underside/walkway commands.

Desktop browser review covered all four Detail views, visible facade/sign/canopy changes, bridge section geometry, pointer orbit and daylight/golden/blue-hour modes. No runtime JavaScript errors were reported. The expanded gallery was opened; all seven new source images also loaded separately during research. A phone viewport override did not apply to the active tab during this pass and was reset; responsive verification from the initial implementation has not been repeated successfully for this refinement.

Fixing sizes, equipment layouts, roof furniture, entrance locations, panel spacing and paving dimensions are interpretations, not verified fabrication details. The models remain stylized studies, not photogrammetry or engineering models. Await user visual review before any town-map integration.
