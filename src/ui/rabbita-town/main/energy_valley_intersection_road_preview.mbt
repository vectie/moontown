///|
/// The single map view is enabled by the checked-in, fully validated graph.
/// If that asset is invalid, the renderer fails closed to the canonical map.
fn energy_valley_intersection_road_preview_active() -> Bool {
  if reference_osm_block_graph_ready() {
    reference_osm_cartoon_road_graph_prepare()
  } else {
    reference_intersection_preview_graph_ready()
  }
}

///|
/// One explicit authoring-only spring cutout. It is never constructed from a
/// Place, TownCanvasBuilding, parcel, or any other semantic snapshot projection.
priv struct IntersectionRoadPreviewBuilding {
  id : String
  style : String
  asset_path : String
  x : Int
  y : Int
  width : Int
  depth : Int
  apron : Int
  depth_key : Int
} derive(Debug, Eq)

///|
/// Cache the presentation-only procedural layer by blueprint identity. Lot
/// discovery is deliberately not animation-frame work; changing the world
/// blueprint invalidates the cache and reruns the same deterministic search.
let intersection_road_preview_procedural_cache : Map[
  String,
  Array[IntersectionRoadPreviewBuilding],
] = Map([])

///|
let intersection_road_preview_fixed_cache : Map[
  String,
  Array[IntersectionRoadPreviewBuilding],
] = Map([])

///|
let intersection_road_preview_depth_cache : Map[
  String,
  Map[Int, Array[IntersectionRoadPreviewBuilding]],
] = Map([])

///|
let intersection_road_preview_land_cache : Map[String, Map[String, String]] = Map([],
)

///|
let intersection_road_preview_stale_ground_cache : Map[
  String,
  Map[String, Bool],
] = Map([])

///|
let intersection_road_preview_installation_cache : Map[
  String,
  Map[Int, Array[@energy_valley_contract.Installation]],
] = Map([])

///|
let intersection_road_preview_water_cache : Map[
  String,
  Array[(Int, Int, String)],
] = Map([])

///|
fn intersection_road_preview_graph_identity() -> String {
  if reference_osm_block_graph_ready() &&
    reference_osm_cartoon_road_graph_prepare() {
    "osm-cartoon-road:v1:{reference_osm_cartoon_road_node_count()}:{reference_osm_cartoon_road_edge_count()}"
  } else if reference_intersection_preview_graph_ready() {
    "wenyu-source-graph:145:216"
  } else {
    "graph-unavailable"
  }
}

///|
fn intersection_road_preview_cache_key(
  snapshot : @energy_valley_contract.TownSnapshot,
) -> String {
  "{snapshot.world.blueprint_digest}:{snapshot.world.places.length()}:{snapshot.world.installations.length()}:{intersection_road_preview_graph_identity()}"
}

///|
/// Resolve only fixed ambient-pack paths; curated preview art cannot borrow a
/// civic module identity or introduce an arbitrary URL.
fn intersection_road_preview_building_asset_path(
  style : String,
  variant : Int,
) -> String? {
  golden_spring_ambient_asset_path_for_variant(style, variant)
}

///|
fn intersection_road_preview_vector_style_supported(style : String) -> Bool {
  match style {
    "home" | "custom-home" | "market" | "garden" | "lab" | "plaza" | "radar" =>
      true
    _ => false
  }
}

///|
fn intersection_road_preview_building_geometry_valid(
  building : IntersectionRoadPreviewBuilding,
) -> Bool {
  let asset_style = !building.asset_path.is_empty() &&
    golden_spring_ambient_style_supported(building.style)
  let vector_style = building.asset_path.is_empty() &&
    intersection_road_preview_vector_style_supported(building.style)
  building.x >= 0 &&
  building.y >= 0 &&
  // All preview skins share one authored lot contract: a 5×5 footprint plus
  // one tile on every side, i.e. a 7×7 reserved ground envelope.
  building.width == 5 &&
  building.depth == 5 &&
  building.apron == 1 &&
  building.width + building.apron * 2 == 7 &&
  building.depth + building.apron * 2 == 7 &&
  building.x - building.apron >= 0 &&
  building.y - building.apron >= 0 &&
  building.x + building.width + building.apron <= 256 &&
  building.y + building.depth + building.apron <= 144 &&
  (asset_style || vector_style) &&
  building.depth_key ==
  building.x + building.y + building.width + building.depth
}

///|
fn intersection_road_preview_building_center(
  building : IntersectionRoadPreviewBuilding,
) -> (Double, Double) {
  (
    building.x.to_double() + building.width.to_double() / 2.0,
    building.y.to_double() + building.depth.to_double() / 2.0,
  )
}

///|
fn intersection_road_preview_sort_equal_depth(
  buildings : Array[IntersectionRoadPreviewBuilding],
) -> Unit {
  buildings.sort_by((left, right) => left.id.compare(right.id))
}

///|
/// Curated single-view placement. These thirty fixed lots are generated from
/// the reviewed graph cells, each with a one-tile apron. All use the same
/// five-tile footprint and the same isometric-facing asset family. The style
/// mix is intentional: the pack's row/tower/civic skins are admitted only at
/// these reviewed, fixed orientations rather than being rotated procedurally.
fn intersection_road_preview_fixed_building(
  id : String,
  style : String,
  variant : Int,
  x : Int,
  y : Int,
) -> IntersectionRoadPreviewBuilding {
  {
    id,
    style,
    asset_path: intersection_road_preview_building_asset_path(style, variant).unwrap_or(
      "",
    ),
    x,
    y,
    width: 5,
    depth: 5,
    apron: 1,
    depth_key: x + y + 10,
  }
}

///|
fn intersection_road_preview_curated_buildings() -> Array[
  IntersectionRoadPreviewBuilding,
] {
  let cache_key = intersection_road_preview_graph_identity()
  match intersection_road_preview_fixed_cache.get(cache_key) {
    Some(cached) => return cached
    None => ()
  }
  let raw = [
    intersection_road_preview_fixed_building(
      "building-01", "lowrise", 2, 201, 5,
    ),
    intersection_road_preview_fixed_building(
      "building-02", "courtyard", 3, 10, 119,
    ),
    intersection_road_preview_fixed_building(
      "building-03", "block", 4, 130, 130,
    ),
    intersection_road_preview_fixed_building("building-04", "campus", 3, 93, 22),
    intersection_road_preview_fixed_building(
      "building-05", "industrial", 3, 213, 98,
    ),
    intersection_road_preview_fixed_building("building-06", "tower", 2, 11, 50),
    intersection_road_preview_fixed_building(
      "building-07", "courtyard", 3, 121, 74,
    ),
    intersection_road_preview_fixed_building(
      "building-08", "campus", 3, 67, 119,
    ),
    intersection_road_preview_fixed_building("building-09", "block", 4, 164, 43),
    intersection_road_preview_fixed_building(
      "building-10", "industrial", 3, 70, 68,
    ),
    intersection_road_preview_fixed_building(
      "building-11", "lowrise", 2, 45, 19,
    ),
    intersection_road_preview_fixed_building("building-12", "row", 3, 249, 70),
    intersection_road_preview_fixed_building(
      "building-13", "campus", 3, 127, 37,
    ),
    intersection_road_preview_fixed_building("building-14", "block", 4, 38, 84),
    intersection_road_preview_fixed_building(
      "building-15", "industrial", 3, 188, 86,
    ),
    intersection_road_preview_fixed_building(
      "building-16", "lowrise", 2, 102, 133,
    ),
    intersection_road_preview_fixed_building(
      "building-17", "courtyard", 3, 6, 77,
    ),
    intersection_road_preview_fixed_building("building-18", "campus", 3, 57, 41),
    intersection_road_preview_fixed_building("building-19", "block", 4, 93, 63),
    intersection_road_preview_fixed_building("building-20", "civic", 3, 37, 61),
    intersection_road_preview_fixed_building(
      "building-21", "lowrise", 2, 91, 43,
    ),
    intersection_road_preview_fixed_building(
      "building-22", "courtyard", 3, 136, 54,
    ),
    intersection_road_preview_fixed_building(
      "building-23", "campus", 3, 218, 16,
    ),
    intersection_road_preview_fixed_building("building-24", "block", 4, 111, 13),
    intersection_road_preview_fixed_building(
      "building-25", "industrial", 3, 9, 97,
    ),
    intersection_road_preview_fixed_building("building-26", "tower", 6, 82, 133),
    intersection_road_preview_fixed_building(
      "building-27", "courtyard", 3, 127, 114,
    ),
    intersection_road_preview_fixed_building("building-28", "campus", 3, 24, 70),
    intersection_road_preview_fixed_building("building-29", "block", 4, 201, 91),
    intersection_road_preview_fixed_building("building-30", "row", 4, 45, 73),
  ]
  let placed = intersection_road_preview_relocate_fixed_buildings(raw)
  intersection_road_preview_fixed_cache[cache_key] = placed
  placed
}

///|
fn intersection_road_preview_procedural_style_allowed(style : String) -> Bool {
  match style {
    "campus"
    | "courtyard"
    | "lowrise"
    | "block"
    | "industrial"
    | "civic"
    | "row"
    | "tower" => true
    _ => false
  }
}

///|
fn intersection_road_preview_reference_cell_buildable(x : Int, y : Int) -> Bool {
  match reference_tile_kind_at(x, y) {
    Some("river" | "lake" | "water" | "wetland" | "forest" | "bridge") => false
    Some(_) => true
    // Some authored locations are outside the sparse reference labels. They
    // are still valid dry ground unless an explicit water/road/forest kind
    // vetoes them.
    None => true
  }
}

///|
/// The one-tile apron is reserved land: neither the footprint nor the apron
/// may contain a displayed graph cell. The immediately adjacent outer ring
/// must touch the graph so the lot fronts a road without collapsing into it.
fn intersection_road_preview_apron_valid(
  building : IntersectionRoadPreviewBuilding,
) -> Bool {
  if !intersection_road_preview_building_geometry_valid(building) {
    return false
  }
  let graph_ready = energy_valley_intersection_road_preview_active()
  let osm_ready = graph_ready && reference_osm_block_graph_ready()
  let mut frontage = false
  for y in (building.y - building.apron)..<=(building.y + building.depth) {
    for x in (building.x - building.apron)..<=(building.x + building.width) {
      if x < 0 || y < 0 || x >= 256 || y >= 144 {
        return false
      }
      if !intersection_road_preview_reference_cell_buildable(x, y) ||
        (!osm_ready && reference_intersection_preview_graph_cell_at(x, y)) {
        return false
      }
    }
  }
  if osm_ready {
    return reference_osm_cartoon_road_lot_valid(
      building.x,
      building.y,
      building.width,
      building.depth,
      building.apron,
    )
  }
  if graph_ready {
    let minimum_x = building.x - building.apron - 1
    let maximum_x = building.x + building.width + building.apron
    let minimum_y = building.y - building.apron - 1
    let maximum_y = building.y + building.depth + building.apron
    for y in minimum_y..<=maximum_y {
      for x in minimum_x..<=maximum_x {
        let on_outer_ring = x == minimum_x ||
          x == maximum_x ||
          y == minimum_y ||
          y == maximum_y
        if on_outer_ring && reference_intersection_preview_graph_cell_at(x, y) {
          frontage = true
        }
      }
    }
  }
  frontage || !graph_ready
}

///|
/// Procedural and curated buildings share the exact same lot contract. This
/// keeps the displayed road, the 5×5 footprint, and the complete one-tile
/// apron as a single source of truth.
fn intersection_road_preview_procedural_lot_valid(
  building : IntersectionRoadPreviewBuilding,
) -> Bool {
  intersection_road_preview_apron_valid(building)
}

///|
fn intersection_road_preview_buildings_overlap(
  left : IntersectionRoadPreviewBuilding,
  right : IntersectionRoadPreviewBuilding,
) -> Bool {
  !(left.x + left.width + left.apron <= right.x - right.apron ||
  right.x + right.width + right.apron <= left.x - left.apron ||
  left.y + left.depth + left.apron <= right.y - right.apron ||
  right.y + right.depth + right.apron <= left.y - left.apron)
}

///|
/// Keep every curated building, but move it to the nearest legal lot when a
/// source anchor falls across the reviewed graph. Search order is deterministic
/// and preserves the authored style/orientation while giving the full
/// footprint and apron clear ground.
fn intersection_road_preview_relocate_fixed_buildings(
  raw : Array[IntersectionRoadPreviewBuilding],
) -> Array[IntersectionRoadPreviewBuilding] {
  let result : Array[IntersectionRoadPreviewBuilding] = []
  for building in raw {
    let mut placed : IntersectionRoadPreviewBuilding? = None
    for radius in 0..<=24 {
      for dy in -radius..<=radius {
        let remaining = radius - dy.abs()
        let horizontal_offsets : Array[Int] = if remaining == 0 {
          [0]
        } else {
          [-remaining, remaining]
        }
        for dx in horizontal_offsets {
          if placed is None {
            let candidate = {
              ..building,
              x: building.x + dx,
              y: building.y + dy,
              depth_key: building.x +
              dx +
              building.y +
              dy +
              building.width +
              building.depth,
            }
            let mut conflict = false
            for existing in result {
              if intersection_road_preview_buildings_overlap(
                  candidate, existing,
                ) {
                conflict = true
              }
            }
            if intersection_road_preview_building_geometry_valid(candidate) &&
              intersection_road_preview_apron_valid(candidate) &&
              !conflict {
              placed = Some(candidate)
            }
          }
        }
      }
    }
    match placed {
      Some(candidate) => result.push(candidate)
      None => ()
    }
  }
  result
}

///|
/// Place additional procedural lots near their old source anchors without
/// allowing them to overlap fixed lots or one another. This keeps the old
/// generated density while making the reviewed graph/apron contract the sole
/// placement authority.
fn intersection_road_preview_relocate_procedural_buildings(
  raw : Array[IntersectionRoadPreviewBuilding],
  occupied : Array[IntersectionRoadPreviewBuilding],
) -> Array[IntersectionRoadPreviewBuilding] {
  let result : Array[IntersectionRoadPreviewBuilding] = []
  for building in raw {
    let mut placed : IntersectionRoadPreviewBuilding? = None
    // A bounded local search preserves the source district while still
    // escaping stale road/building coordinates from the old snapshot.
    for radius in 0..<=12 {
      for dy in -radius..<=radius {
        let remaining = radius - dy.abs()
        let horizontal_offsets : Array[Int] = if remaining == 0 {
          [0]
        } else {
          [-remaining, remaining]
        }
        for dx in horizontal_offsets {
          if placed is None {
            let candidate = {
              ..building,
              x: building.x + dx,
              y: building.y + dy,
              depth_key: building.x + dx + building.y + dy + 10,
            }
            let mut conflict = false
            for existing in occupied {
              if intersection_road_preview_buildings_overlap(
                  candidate, existing,
                ) {
                conflict = true
              }
            }
            for existing in result {
              if intersection_road_preview_buildings_overlap(
                  candidate, existing,
                ) {
                conflict = true
              }
            }
            if intersection_road_preview_building_geometry_valid(candidate) &&
              intersection_road_preview_procedural_lot_valid(candidate) &&
              !conflict {
              placed = Some(candidate)
            }
          }
        }
      }
    }
    match placed {
      Some(candidate) => result.push(candidate)
      None => ()
    }
  }
  result
}

///|
/// Restore a dense, deterministic procedural layer between the fixed lots.
/// The semantic profile supplies style and stable variant seed; every accepted
/// candidate is relocated through the same 5×5 + one-tile-apron contract.
fn intersection_road_preview_procedural_buildings(
  snapshot : @energy_valley_contract.TownSnapshot,
  fixed : Array[IntersectionRoadPreviewBuilding],
) -> Array[IntersectionRoadPreviewBuilding] {
  let cache_key = intersection_road_preview_cache_key(snapshot)
  match intersection_road_preview_procedural_cache.get(cache_key) {
    Some(cached) => cached
    None => {
      let raw : Array[IntersectionRoadPreviewBuilding] = []
      let sources = town_snapshot_canvas_buildings(snapshot)
      sources.sort_by((left, right) => {
        if left.y == right.y {
          left.x.compare(right.x)
        } else {
          left.y.compare(right.y)
        }
      })
      for source in sources {
        if raw.length() >= 64 ||
          source.authored_id is Some ||
          !intersection_road_preview_procedural_style_allowed(source.style) {
          continue
        }
        let variant = golden_spring_ambient_building_variant(
          source.style,
          source.place_id,
          source.interior_seed,
        )
        match
          intersection_road_preview_building_asset_path(source.style, variant) {
          None => continue
          Some(asset_path) =>
            raw.push({
              id: "procedural-source-{raw.length()}",
              style: source.style,
              asset_path,
              x: source.x,
              y: source.y,
              width: 5,
              depth: 5,
              apron: 1,
              depth_key: source.x + source.y + 10,
            })
        }
      }
      // Reserve the original MoonTown vector forms before the image-backed
      // density pass. If images fill the pool first, every vector candidate
      // is correctly rejected as overlapping and the procedural layer becomes
      // visually empty even though its draw path is live.
      let vector_styles = ["home", "market", "garden", "lab", "plaza", "radar"]
      let mut vector_count = 0
      for phase_y in 0..<2 {
        for phase_x in 0..<2 {
          for row in 0..<18 {
            for col in 0..<32 {
              if vector_count < 24 {
                let x = 6 + col * 8 + phase_x
                let y = 6 + row * 8 + phase_y
                if x + 6 < 256 && y + 6 < 144 {
                  let style = vector_styles[vector_count %
                    vector_styles.length()]
                  let candidate : IntersectionRoadPreviewBuilding = {
                    id: "procedural-vector-{vector_count}-{x}-{y}",
                    style,
                    asset_path: "",
                    x,
                    y,
                    width: 5,
                    depth: 5,
                    apron: 1,
                    depth_key: x + y + 10,
                  }
                  let mut overlaps_raw = false
                  for existing in raw {
                    if intersection_road_preview_buildings_overlap(
                        candidate, existing,
                      ) {
                      overlaps_raw = true
                    }
                  }
                  if !overlaps_raw &&
                    intersection_road_preview_procedural_lot_valid(candidate) {
                    raw.push(candidate)
                    vector_count += 1
                  }
                }
              }
            }
          }
        }
      }
      // The old snapshot can be sparse after a migration. Fill the remaining
      // density from a deterministic, phase-shifted native grid, admitting a
      // slot only when its 7×7 apron fronts the reviewed graph. This is still
      // a MoonBit presentation calculation; no Python/runtime asset is used.
      if reference_intersection_preview_graph_ready() {
        let styles = [
          "lowrise", "industrial", "tower", "courtyard", "campus", "row", "civic",
        ]
        for phase_y in 0..<2 {
          for phase_x in 0..<2 {
            for row in 0..<18 {
              for col in 0..<32 {
                if raw.length() < 96 {
                  let x = 2 + col * 8 + phase_x
                  let y = 2 + row * 8 + phase_y
                  if x + 6 < 256 && y + 6 < 144 {
                    // Rotate through the authored pack so every reference
                    // silhouette is represented instead of letting a hash
                    // starve one of the seven requested styles.
                    let style = styles[raw.length() % styles.length()]
                    let source_id = "grid-{x}-{y}"
                    let stable_source_id = @energy_valley_contract.stable_id(
                      "preview-grid", source_id,
                    ).unwrap()
                    let variant = golden_spring_ambient_building_variant(
                      style,
                      stable_source_id,
                      x * 31 + y * 17,
                    )
                    match
                      intersection_road_preview_building_asset_path(
                        style, variant,
                      ) {
                      None => ()
                      Some(asset_path) => {
                        let candidate : IntersectionRoadPreviewBuilding = {
                          id: "procedural-grid-{x}-{y}",
                          style,
                          asset_path,
                          x,
                          y,
                          width: 5,
                          depth: 5,
                          apron: 1,
                          depth_key: x + y + 10,
                        }
                        let mut overlaps_raw = false
                        for existing in raw {
                          if intersection_road_preview_buildings_overlap(
                              candidate, existing,
                            ) {
                            overlaps_raw = true
                          }
                        }
                        if intersection_road_preview_building_geometry_valid(
                            candidate,
                          ) &&
                          intersection_road_preview_procedural_lot_valid(
                            candidate,
                          ) &&
                          !overlaps_raw {
                          raw.push(candidate)
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
      let placed = intersection_road_preview_relocate_procedural_buildings(
        raw, fixed,
      )
      intersection_road_preview_procedural_cache[cache_key] = placed
      placed
    }
  }
}

///|
fn intersection_road_preview_buildings_by_depth(
  snapshot : @energy_valley_contract.TownSnapshot,
) -> Map[Int, Array[IntersectionRoadPreviewBuilding]] {
  let cache_key = intersection_road_preview_cache_key(snapshot)
  match intersection_road_preview_depth_cache.get(cache_key) {
    Some(cached) => return cached
    None => ()
  }
  let result : Map[Int, Array[IntersectionRoadPreviewBuilding]] = Map([])
  let fixed = intersection_road_preview_curated_buildings()
  for building in fixed {
    if intersection_road_preview_building_geometry_valid(building) {
      match result.get(building.depth_key) {
        Some(items) => items.push(building)
        None => result[building.depth_key] = [building]
      }
    }
  }
  for
    building in intersection_road_preview_procedural_buildings(snapshot, fixed) {
    if intersection_road_preview_building_geometry_valid(building) {
      match result.get(building.depth_key) {
        Some(items) => items.push(building)
        None => result[building.depth_key] = [building]
      }
    }
  }
  for _, buildings in result {
    intersection_road_preview_sort_equal_depth(buildings)
  }
  let (invalid_lots, overlapping_pairs) = intersection_road_preview_building_contract_errors(
    result,
  )
  intersection_road_preview_record_building_contract(
    invalid_lots, overlapping_pairs,
  )
  intersection_road_preview_depth_cache[cache_key] = result
  result
}

///|
fn intersection_road_preview_building_counts(
  buildings : Map[Int, Array[IntersectionRoadPreviewBuilding]],
) -> (Int, Int) {
  let mut image_count = 0
  let mut vector_count = 0
  for _, items in buildings {
    for building in items {
      if building.asset_path.is_empty() {
        vector_count += 1
      } else {
        image_count += 1
      }
    }
  }
  (image_count, vector_count)
}

///|
fn intersection_road_preview_building_contract_errors(
  buildings : Map[Int, Array[IntersectionRoadPreviewBuilding]],
) -> (Int, Int) {
  let flattened : Array[IntersectionRoadPreviewBuilding] = []
  for _, items in buildings {
    for building in items {
      flattened.push(building)
    }
  }
  let mut invalid_lots = 0
  let mut overlapping_pairs = 0
  for index, building in flattened {
    if !intersection_road_preview_apron_valid(building) {
      invalid_lots += 1
    }
    for other_index in (index + 1)..<flattened.length() {
      if intersection_road_preview_buildings_overlap(
          building,
          flattened[other_index],
        ) {
        overlapping_pairs += 1
      }
    }
  }
  (invalid_lots, overlapping_pairs)
}

///|
extern "js" fn intersection_road_preview_record_building_counts(
  image_count : Int,
  vector_count : Int,
) -> Unit =
  #| (imageCount, vectorCount) => {
  #|   globalThis.__moontownIntersectionRoadPreviewBuildingCounts = {
  #|     image: imageCount,
  #|     vector: vectorCount,
  #|     total: imageCount + vectorCount,
  #|   };
  #|   const root = globalThis.document?.documentElement;
  #|   if (root) {
  #|     root.dataset.previewImageBuildings = String(imageCount);
  #|     root.dataset.previewVectorBuildings = String(vectorCount);
  #|     root.dataset.previewTotalBuildings = String(imageCount + vectorCount);
  #|   }
  #| }

///|
extern "js" fn intersection_road_preview_record_building_contract(
  invalid_lots : Int,
  overlapping_pairs : Int,
) -> Unit =
  #| (invalidLots, overlappingPairs) => {
  #|   const root = globalThis.document?.documentElement;
  #|   if (!root) return;
  #|   root.dataset.previewInvalidBuildingLots = String(invalidLots);
  #|   root.dataset.previewOverlappingBuildingPairs = String(overlappingPairs);
  #| }

///|
/// A contact shadow is clipped to the exact projected footprint. Even if a
/// browser rasterizes the ellipse generously, no shadow pixel can cross the
/// curated footprint into the preview road graph.
extern "js" fn golden_draw_intersection_road_preview_building_shadow(
  context : @dom.CanvasRenderingContext2D,
  sx : Double,
  sy : Double,
  width : Double,
  depth : Double,
  zoom : Double,
) -> Unit =
  #| (context, sx, sy, width, depth, zoom) => {
  #|   const halfX = 16 * zoom;
  #|   const halfY = 8 * zoom;
  #|   const footprint = [
  #|     [sx + (depth - width) * halfX,
  #|      sy - (width + depth) * halfY],
  #|     [sx + (width + depth) * halfX,
  #|      sy + (width - depth) * halfY],
  #|     [sx + (width - depth) * halfX,
  #|      sy + (width + depth) * halfY],
  #|     [sx - (width + depth) * halfX,
  #|      sy + (depth - width) * halfY],
  #|   ];
  #|   context.save();
  #|   context.beginPath();
  #|   context.moveTo(footprint[0][0], footprint[0][1]);
  #|   for (let index = 1; index < footprint.length; index += 1) {
  #|     context.lineTo(footprint[index][0], footprint[index][1]);
  #|   }
  #|   context.closePath();
  #|   context.clip();
  #|   context.fillStyle = "rgba(39,61,70,0.16)";
  #|   context.beginPath();
  #|   context.ellipse(
  #|     sx + 2 * zoom,
  #|     sy + 2 * zoom,
  #|     (width + depth) * 9.5 * zoom,
  #|     (width + depth) * 3.5 * zoom,
  #|     0,
  #|     0,
  #|     Math.PI * 2,
  #|   );
  #|   context.fill();
  #|   context.restore();
  #| }

///|
/// Avoid a transient standalone shadow while an image is still loading. The
/// normal spring draw call below remains the sole cache allocator and repaint
/// scheduler; this probe only observes an already-ready record.
extern "js" fn intersection_road_preview_building_asset_ready(
  asset_path : String,
) -> Bool =
  #| assetPath => {
  #|   const record = globalThis.__moontownSpringCivicBuildingAssets
  #|     ?.get(assetPath);
  #|   return record?.state === "ready" &&
  #|     Boolean(record?.image?.naturalWidth) &&
  #|     Boolean(record?.image?.naturalHeight);
  #| }

///|
/// Make the 7×7 lot contract visible on the map. The outer diamond is the
/// footprint-plus-apron envelope; the inner diamond is the 5×5 building
/// footprint. This is a low-alpha guide painted below the graph and sprites,
/// so it cannot hide a road or change the building silhouette.
extern "js" fn golden_draw_intersection_road_preview_building_lot(
  context : @dom.CanvasRenderingContext2D,
  sx : Double,
  sy : Double,
  zoom : Double,
  land_type : String,
) -> Unit =
  #| (context, sx, sy, zoom, landType) => {
  #|   // A square world lot projects to an isometric diamond: x spans
  #|   // (w+d)*16px and y spans (w+d)*8px at zoom 1. For a square of side
  #|   // `size`, that is size*32px by size*16px. Keeping the two half-axes
  #|   // distinct is what makes the visible 7x7 contract read as a rectangle
  #|   // instead of a pinched diamond.
  #|   const diamond = size => {
  #|     const halfX = size * 32 * zoom;
  #|     const halfY = size * 16 * zoom;
  #|     return [
  #|       [sx, sy - halfY],
  #|       [sx + halfX, sy],
  #|       [sx, sy + halfY],
  #|       [sx - halfX, sy],
  #|     ];
  #|   };
  #|   const paint = (points, fill, stroke, width) => {
  #|     context.beginPath();
  #|     context.moveTo(points[0][0], points[0][1]);
  #|     for (let index = 1; index < points.length; index += 1) {
  #|       context.lineTo(points[index][0], points[index][1]);
  #|     }
  #|     context.closePath();
  #|     context.fillStyle = fill;
  #|     context.fill();
  #|     context.strokeStyle = stroke;
  #|     context.lineWidth = width;
  #|     context.stroke();
  #|   };
  #|   context.save();
  #|   context.lineJoin = "round";
  #|   // Keep the apron boundary visually separate from the building art.
  #|   // The dashed outer edge is the reserved one-tile ring; the solid inner
  #|   // edge is the exact 5x5 footprint.
  #|   context.setLineDash([4, 3]);
  #|   const plaza = landType === "plaza";
  #|   paint(
  #|     diamond(7),
  #|     plaza ? "rgba(244,235,202,0.26)" : "rgba(74,111,78,0.18)",
  #|     plaza ? "rgba(151,122,69,0.82)" : "rgba(52,87,70,0.78)",
  #|     Math.max(2.0, 2.35 * zoom),
  #|   );
  #|   context.setLineDash([]);
  #|   paint(
  #|     diamond(5),
  #|     "rgba(255,255,255,0.07)",
  #|     "rgba(255,255,255,0.86)",
  #|     Math.max(1.25, 1.45 * zoom),
  #|   );
  #|   context.restore();
  #| }

///|
/// Draw one validated placement. The authored image is preferred; while it is
/// loading, the same lot receives the established procedural MoonTown fallback
/// at the identical coordinates.
fn intersection_road_preview_draw_procedural_fallback(
  context : @dom.CanvasRenderingContext2D,
  building : IntersectionRoadPreviewBuilding,
  viewport_width : Int,
  viewport_height : Int,
) -> Unit {
  // Reuse the established MoonTown procedural geometry only when the matching
  // image cutout is unavailable. The synthetic record is presentation-only:
  // it has no module, authored id, hit target, or snapshot/place identity.
  let place_id = @energy_valley_contract.stable_id(
    "preview-procedural-building",
    building.id,
  ).unwrap()
  let floors = match building.style {
    "tower" => 8
    "civic" | "courtyard" | "campus" | "row" => 3
    _ => 2
  }
  let procedural : TownCanvasBuilding = {
    place_id,
    name: "",
    style: building.style,
    x: building.x,
    y: building.y,
    width: building.width,
    depth: building.depth,
    entrance_x: None,
    entrance_y: None,
    floors,
    interior_seed: building.x * 31 + building.y * 17,
    module_key: None,
    authored_id: None,
  }
  golden_draw_building(
    context, procedural, false, "", viewport_width, viewport_height, 12.0,
  )
}

///|
fn golden_draw_intersection_road_preview_building(
  context : @dom.CanvasRenderingContext2D,
  building : IntersectionRoadPreviewBuilding,
  viewport_width : Int,
  viewport_height : Int,
) -> Unit {
  let (center_x, center_y) = intersection_road_preview_building_center(building)
  let sx = golden_screen_x(center_x, center_y, viewport_width)
  let sy = golden_screen_y(center_x, center_y, viewport_height)
  let zoom = golden_valley_camera_zoom()
  if golden_spring_building_asset_visible(
      sx,
      sy,
      building.width.to_double(),
      building.depth.to_double(),
      zoom,
      viewport_width,
      viewport_height,
    ) {
    if !building.asset_path.is_empty() &&
      intersection_road_preview_building_asset_ready(building.asset_path) {
      golden_draw_intersection_road_preview_building_shadow(
        context,
        sx,
        sy,
        building.width.to_double(),
        building.depth.to_double(),
        zoom,
      )
    }
    let image_drawn = if building.asset_path.is_empty() {
      false
    } else {
      golden_draw_spring_civic_building_asset(
        context,
        building.asset_path,
        sx,
        sy,
        building.width.to_double(),
        building.depth.to_double(),
        zoom,
        false,
      )
    }
    if !image_drawn {
      intersection_road_preview_draw_procedural_fallback(
        context, building, viewport_width, viewport_height,
      )
    }
  }
}

///|
/// Preserve standalone scenery while removing fixtures that would reveal the
/// hidden legacy roads or Line 17. This is presentation-only; installation
/// identity and interaction remain outside the accepted Canvas frame.
fn intersection_road_preview_installation_visible(
  installation : @energy_valley_contract.Installation,
) -> Bool {
  match installation.kind {
    @energy_valley_contract.MetroAlignment
    | @energy_valley_contract.TransitEntrance
    | @energy_valley_contract.Signage => false
    @energy_valley_contract.Tree | @energy_valley_contract.Light =>
      town_snapshot_installation_tag(installation, "road-mask:") is None
    @energy_valley_contract.Boardwalk | @energy_valley_contract.Bench => true
    @energy_valley_contract.Custom("planter") => true
    @energy_valley_contract.Custom(_) => false
  }
}

///|
fn intersection_road_preview_installations_by_depth(
  snapshot : @energy_valley_contract.TownSnapshot,
) -> Map[Int, Array[@energy_valley_contract.Installation]] {
  let cache_key = intersection_road_preview_cache_key(snapshot)
  match intersection_road_preview_installation_cache.get(cache_key) {
    Some(cached) => return cached
    None => ()
  }
  let result : Map[Int, Array[@energy_valley_contract.Installation]] = Map([])
  for depth, items in town_snapshot_installations_by_depth(snapshot) {
    for installation in items {
      if intersection_road_preview_installation_visible(installation) {
        match result.get(depth) {
          Some(visible) => visible.push(installation)
          None => result[depth] = [installation]
        }
      }
    }
  }
  intersection_road_preview_installation_cache[cache_key] = result
  result
}

///|
/// Draw the selected road structure in the established MoonTown cartoon style.
/// The OSM payload supplies reference topology only; its dense raw linework is
/// never painted. Parallel carriageways and junction complexes have already
/// been contracted by `reference_osm_cartoon_road_graph_prepare`.
extern "js" fn golden_draw_intersection_road_preview_graph(
  context : @dom.CanvasRenderingContext2D,
  camera_x : Double,
  camera_y : Double,
  zoom : Double,
  viewport_width : Int,
  viewport_height : Int,
) -> Unit =
  #| (context, cameraX, cameraY, zoom, viewportWidth, viewportHeight) => {
  #|   const osmReady =
  #|     globalThis.__moontownEnergyValleyOsmBlockGraphValidated === true;
  #|   const snapshot = osmReady
  #|     ? globalThis.__moontownEnergyValleyCartoonRoadGraph
  #|     : globalThis.__wenyuReferenceIntersections;
  #|   const edgesSource = osmReady
  #|     ? snapshot?.edges
  #|     : snapshot?.previewGraph?.edges;
  #|   const expectedEdges = osmReady ? snapshot?.metrics?.edges : 216;
  #|   if (!Array.isArray(edgesSource) || !expectedEdges ||
  #|     edgesSource.length !== expectedEdges ||
  #|     (!osmReady &&
  #|       globalThis.__wenyuReferenceIntersectionPreviewGraphValidated !== true)
  #|   ) return;
  #|   const toScreen = point => {
  #|     const x = point[0] / 1000;
  #|     const y = point[1] / 1000;
  #|     return [
  #|       ((x - y) * 32 - cameraX) * zoom + viewportWidth / 2,
  #|       ((x + y) * 16 - cameraY) * zoom + viewportHeight / 2,
  #|     ];
  #|   };
  #|   const visible = path => {
  #|     let minimumX = Infinity;
  #|     let minimumY = Infinity;
  #|     let maximumX = -Infinity;
  #|     let maximumY = -Infinity;
  #|     for (const point of path) {
  #|       const screen = toScreen(point);
  #|       minimumX = Math.min(minimumX, screen[0]);
  #|       minimumY = Math.min(minimumY, screen[1]);
  #|       maximumX = Math.max(maximumX, screen[0]);
  #|       maximumY = Math.max(maximumY, screen[1]);
  #|     }
  #|     const margin = 48;
  #|     return maximumX >= -margin && minimumX <= viewportWidth + margin &&
  #|       maximumY >= -margin && minimumY <= viewportHeight + margin;
  #|   };
  #|   const trace = (path, smooth = osmReady) => {
  #|     if (!Array.isArray(path) || path.length < 2) return false;
  #|     const first = toScreen(path[0]);
  #|     context.beginPath();
  #|     context.moveTo(first[0], first[1]);
  #|     if (smooth && path.length > 2) {
  #|       for (let index = 1; index < path.length - 1; index += 1) {
  #|         const point = toScreen(path[index]);
  #|         const next = toScreen(path[index + 1]);
  #|         context.quadraticCurveTo(
  #|           point[0], point[1],
  #|           (point[0] + next[0]) / 2,
  #|           (point[1] + next[1]) / 2,
  #|         );
  #|       }
  #|       const last = toScreen(path[path.length - 1]);
  #|       context.lineTo(last[0], last[1]);
  #|     } else {
  #|       for (let index = 1; index < path.length; index += 1) {
  #|         const point = toScreen(path[index]);
  #|         context.lineTo(point[0], point[1]);
  #|       }
  #|     }
  #|     return true;
  #|   };
  #|   const edges = edgesSource.filter(edge =>
  #|     Array.isArray(edge?.pathMillis) && visible(edge.pathMillis) &&
  #|       (!osmReady || edge.rank === "primary" ||
  #|         (edge.rank === "secondary" && zoom >= 0.34) ||
  #|         (edge.rank === "local" && zoom >= 0.34))
  #|   );
  #|   context.save();
  #|   context.lineCap = "round";
  #|   context.lineJoin = "round";
  #|   context.setLineDash([]);
  #|   if (osmReady) {
  #|     // Soft ground contact, warm curb, and slate asphalt echo the original
  #|     // isometric road tiles without bringing back their stair-step shape.
  #|     context.save();
  #|     context.translate(0, Math.max(1.4, 2.7 * zoom));
  #|     context.strokeStyle = "rgba(48,72,54,0.24)";
  #|     for (const rank of ["local", "secondary", "primary"]) {
  #|       context.lineWidth = rank === "primary"
  #|         ? Math.max(11.0, 17.5 * zoom)
  #|         : rank === "secondary" ? Math.max(9.0, 14.0 * zoom)
  #|           : Math.max(7.0, 10.5 * zoom);
  #|       for (const edge of edges) {
  #|         if (edge.rank === rank && trace(edge.pathMillis)) context.stroke();
  #|       }
  #|     }
  #|     context.restore();
  #|     context.strokeStyle = "#f4eee2";
  #|     for (const rank of ["local", "secondary", "primary"]) {
  #|       context.lineWidth = rank === "primary"
  #|         ? Math.max(9.5, 15.0 * zoom)
  #|         : rank === "secondary" ? Math.max(7.5, 11.8 * zoom)
  #|           : Math.max(6.0, 8.8 * zoom);
  #|       for (const edge of edges) {
  #|         if (edge.rank === rank && trace(edge.pathMillis)) context.stroke();
  #|       }
  #|     }
  #|     for (const rank of ["local", "secondary", "primary"]) {
  #|       context.strokeStyle = rank === "primary" ? "#5f707a" :
  #|         rank === "secondary" ? "#7b878c" : "#929a99";
  #|       context.lineWidth = rank === "primary"
  #|         ? Math.max(5.8, 9.2 * zoom)
  #|         : rank === "secondary" ? Math.max(4.5, 7.0 * zoom)
  #|           : Math.max(3.4, 5.2 * zoom);
  #|       for (const edge of edges) {
  #|         if (edge.rank === rank && trace(edge.pathMillis)) context.stroke();
  #|       }
  #|     }
  #|     if (zoom >= 0.62) {
  #|       context.setLineDash([Math.max(5, 10 * zoom), Math.max(4, 8 * zoom)]);
  #|       context.strokeStyle = "rgba(247,241,222,0.88)";
  #|       context.lineWidth = Math.max(1.0, 1.45 * zoom);
  #|       for (const edge of edges) {
  #|         if (edge.rank === "primary" && trace(edge.pathMillis)) {
  #|           context.stroke();
  #|         }
  #|       }
  #|       context.setLineDash([]);
  #|     }
  #|   } else {
  #|     context.strokeStyle = "rgba(247,244,235,0.97)";
  #|     context.lineWidth = Math.max(4.4, 8.0 * zoom);
  #|     for (const edge of edges) if (trace(edge.pathMillis, false)) {
  #|       context.stroke();
  #|     }
  #|     context.strokeStyle = "#405866";
  #|     context.lineWidth = Math.max(2.4, 5.0 * zoom);
  #|     for (const edge of edges) if (trace(edge.pathMillis, false)) {
  #|       context.stroke();
  #|     }
  #|   }
  #|   for (const edge of edges) {
  #|     const bridgePaths = osmReady
  #|       ? edge.bridgePaths || []
  #|       : (edge.bridgeSpans || []).map(span =>
  #|           edge.pathMillis.slice(span.fromIndex, span.toIndex + 1));
  #|     for (const path of bridgePaths) {
  #|       context.setLineDash([]);
  #|       context.strokeStyle = "rgba(250,248,239,0.99)";
  #|       context.lineWidth = Math.max(6.0, 10.0 * zoom);
  #|       if (trace(path)) context.stroke();
  #|       context.strokeStyle = "#a98c66";
  #|       context.lineWidth = Math.max(4.0, 7.5 * zoom);
  #|       if (trace(path)) context.stroke();
  #|       context.strokeStyle = "#5f707a";
  #|       context.lineWidth = Math.max(2.8, 5.5 * zoom);
  #|       if (trace(path)) context.stroke();
  #|     }
  #|   }
  #|   context.restore();
  #| }

///|
/// Return a smooth, deterministic position on one of the validated graph
/// edges. Preview agents must use this source-skeleton path rather than the
/// semantic snapshot's legacy route positions; otherwise they visibly slide
/// across grass or stop at stale road cells. The coordinate is sampled by
/// distance along the polyline, so diagonal/curved source steps do not create
/// the old tile-to-tile teleporting.
extern "js" fn reference_intersection_preview_graph_walker_coordinate(
  walker_index : Int,
  elapsed_seconds : Double,
  axis : Int,
  reduced_motion : Bool,
) -> Double =
  #| (walkerIndex, elapsedSeconds, axis, reducedMotion) => {
  #|   const osmReady =
  #|     globalThis.__moontownEnergyValleyOsmBlockGraphValidated === true;
  #|   const graph = osmReady
  #|     ? globalThis.__moontownEnergyValleyCartoonRoadGraph
  #|     : globalThis.__wenyuReferenceIntersections;
  #|   const edges = osmReady ? graph?.edges : graph?.previewGraph?.edges;
  #|   const expected = osmReady ? graph?.metrics?.edges : 216;
  #|   const valid = Array.isArray(edges) && expected > 0 &&
  #|     edges.length === expected &&
  #|     (osmReady ||
  #|       globalThis.__wenyuReferenceIntersectionPreviewGraphValidated === true);
  #|   if (!valid) return 0;
  #|   let cache = globalThis.__moontownIntersectionWalkerEdges;
  #|   if (cache?.source !== graph || !Array.isArray(cache?.edges)) {
  #|     const ranked = edges.map(edge => {
  #|       const raw = Array.isArray(edge?.pathMillis) ? edge.pathMillis : [];
  #|       const points = raw.map(point => [point[0] / 1000, point[1] / 1000]);
  #|       const lengths = [0];
  #|       let total = 0;
  #|       for (let index = 1; index < points.length; index += 1) {
  #|         total += Math.hypot(
  #|           points[index][0] - points[index - 1][0],
  #|           points[index][1] - points[index - 1][1],
  #|         );
  #|         lengths.push(total);
  #|       }
  #|       return { points, lengths, total };
  #|     }).filter(item => item.total > 12)
  #|       .sort((left, right) => right.total - left.total);
  #|     cache = { source: graph, edges: ranked.slice(0, 24) };
  #|     globalThis.__moontownIntersectionWalkerEdges = cache;
  #|   }
  #|   if (!cache.edges.length) return 0;
  #|   const edge = cache.edges[Math.abs(walkerIndex) % cache.edges.length];
  #|   const { points, lengths, total } = edge;
  #|   if (!Array.isArray(points) || points.length < 2) return 0;
  #|   if (!(total > 0)) return points[0][axis === 0 ? 0 : 1];
  #|   const phase = ((Math.abs(walkerIndex) * 0.137) % 1 + 1) % 1;
  #|   const progress = reducedMotion
  #|     ? phase
  #|     : ((elapsedSeconds * 0.075 + phase) % 1 + 1) % 1;
  #|   const distance = progress * total;
  #|   let segment = 1;
  #|   while (segment < lengths.length && lengths[segment] < distance) {
  #|     segment += 1;
  #|   }
  #|   const previous = points[Math.max(0, segment - 1)];
  #|   const next = points[Math.min(points.length - 1, segment)];
  #|   const startDistance = lengths[Math.max(0, segment - 1)];
  #|   const span = Math.max(0.000001, lengths[Math.min(lengths.length - 1, segment)] - startDistance);
  #|   const local = Math.max(0, Math.min(1, (distance - startDistance) / span));
  #|   const x = previous[0] + (next[0] - previous[0]) * local;
  #|   const y = previous[1] + (next[1] - previous[1]) * local;
  #|   return axis === 0 ? x : y;
  #| }

///|
fn intersection_road_preview_graph_walkers(
  elapsed_seconds : Double,
  reduced_motion : Bool,
) -> Array[GoldenValleyCanvasAgent] {
  let roles = [
    "worker", "researcher", "resident", "keeper", "worker", "resident",
  ]
  let colors = [
    "#7dd3fc", "#a5b4fc", "#f9a8d4", "#fcd34d", "#67e8f9", "#86efac",
  ]
  let result : Array[GoldenValleyCanvasAgent] = []
  for index in 0..<roles.length() {
    let x = reference_intersection_preview_graph_walker_coordinate(
      index, elapsed_seconds, 0, reduced_motion,
    )
    let y = reference_intersection_preview_graph_walker_coordinate(
      index, elapsed_seconds, 1, reduced_motion,
    )
    result.push({
      x,
      y,
      sprite_path: golden_valley_agent_sprite_path(roles[index], index),
      facing_left: false,
      bob: if reduced_motion {
        0.0
      } else {
        elapsed_seconds * 9.0 + index.to_double()
      },
      work_color: colors[index],
      activity_glyph: "",
      activity_label: "",
      preview: false,
      selected: false,
    })
  }
  result
}

///|
/// The single map frame: canonical terrain, atmosphere, standalone scenery,
/// actor pixels, thirty fixed lots, and the dense procedural layer remain. Legacy
/// buildings/transport and every semantic hit area stay omitted; clearing
/// pointer authority also makes retained pixels non-interactive.

///|
fn intersection_road_view_stale_ground_cells(
  snapshot : @energy_valley_contract.TownSnapshot,
) -> Map[String, Bool] {
  let cache_key = intersection_road_preview_cache_key(snapshot)
  match intersection_road_preview_stale_ground_cache.get(cache_key) {
    Some(cached) => return cached
    None => ()
  }
  let result : Map[String, Bool] = Map([])
  for building in town_snapshot_canvas_buildings(snapshot) {
    // The generated world paints a one-tile campus/urban apron around each
    // old footprint. Include that apron so removing the old sprite does not
    // leave its pale pad behind.
    for y in (building.y - 1)..<=(building.y + building.depth) {
      for x in (building.x - 1)..<=(building.x + building.width) {
        if x >= 0 && y >= 0 && x < 256 && y < 144 {
          result[town_canvas_road_key(x, y)] = true
        }
      }
    }
  }
  intersection_road_preview_stale_ground_cache[cache_key] = result
  result
}

///|
/// Recover the original reference surface below a removed generated lot.
/// Campus/urban labels are deliberately returned as grass here: those labels
/// describe the old generated pad, not a surviving plaza in this one view.
fn intersection_road_view_stale_ground_terrain(x : Int, y : Int) -> String {
  if !reference_tile_snapshot_ready() {
    return "grass"
  }
  match reference_tile_kind_at(x, y) {
    Some("river" | "lake" | "water") => "water"
    Some("wetland") => "wetland"
    Some("forest") => "forest"
    Some("grass-flower-pink" | "grass-flower-yellow") => "meadow"
    Some("farm" | "field") => "field"
    Some("grass-light") => "grass"
    Some("urban" | "urban-dense" | "campus" | "plaza") => "grass"
    _ => "grass"
  }
}

///|
extern "js" fn intersection_road_view_benchmark_now() -> Double =
  #| () => globalThis.performance?.now?.() ?? Date.now()

///|
extern "js" fn intersection_road_view_static_cache_key(
  base_key : String,
  viewport_width : Int,
  viewport_height : Int,
  hour : Double,
) -> String =
  #| (baseKey, width, height, hour) => {
  #|   const camera = globalThis.__moontownGoldenValleyCamera ?? {
  #|     x: 1792, y: 3200, zoom: 0.42,
  #|   };
  #|   const canvas = globalThis.document?.getElementById("energy-valley-canvas");
  #|   const progress = (hour - 6) / 13;
  #|   const daylight = progress <= 0 || progress >= 1
  #|     ? 0
  #|     : Math.sin(progress * Math.PI);
  #|   const light = daylight > 0.5 ? "day" : daylight > 0.15 ? "dusk" : "night";
  #|   return [
  #|     baseKey, width, height, canvas?.width ?? 0, canvas?.height ?? 0,
  #|     Number(camera.x).toFixed(4), Number(camera.y).toFixed(4),
  #|     Number(camera.zoom).toFixed(6), light,
  #|   ].join(":");
  #| }

///|
extern "js" fn intersection_road_view_draw_static_cache(
  context : @dom.CanvasRenderingContext2D,
  cache_key : String,
) -> Bool =
  #| (context, cacheKey) => {
  #|   const cache = globalThis.__moontownIntersectionStaticCanvas;
  #|   if (!cache?.ready || cache.key !== cacheKey || !cache.canvas) return false;
  #|   context.save();
  #|   context.setTransform(1, 0, 0, 1, 0, 0);
  #|   context.drawImage(cache.canvas, 0, 0);
  #|   context.restore();
  #|   return true;
  #| }

///|
extern "js" fn intersection_road_view_static_cache_supported() -> Bool =
  #| () => typeof globalThis.document?.createElement === "function"

///|
extern "js" fn intersection_road_view_prepare_static_cache(
  context : @dom.CanvasRenderingContext2D,
  cache_key : String,
) -> @dom.CanvasRenderingContext2D =
  #| (context, cacheKey) => {
  #|   if (typeof globalThis.document?.createElement !== "function") {
  #|     return context;
  #|   }
  #|   const canvas = globalThis.document.createElement("canvas");
  #|   canvas.width = context.canvas.width;
  #|   canvas.height = context.canvas.height;
  #|   const staticContext = canvas.getContext("2d");
  #|   staticContext.setTransform(context.getTransform());
  #|   globalThis.__moontownIntersectionStaticCanvas = {
  #|     key: cacheKey, canvas, context: staticContext, ready: false,
  #|   };
  #|   return staticContext;
  #| }

///|
extern "js" fn intersection_road_view_commit_static_cache(
  context : @dom.CanvasRenderingContext2D,
  cache_key : String,
) -> Unit =
  #| (context, cacheKey) => {
  #|   const cache = globalThis.__moontownIntersectionStaticCanvas;
  #|   if (!cache || cache.key !== cacheKey) return;
  #|   cache.ready = true;
  #|   context.save();
  #|   context.setTransform(1, 0, 0, 1, 0, 0);
  #|   context.drawImage(cache.canvas, 0, 0);
  #|   context.restore();
  #| }

///|
fn intersection_road_view_tile_on_screen(
  x : Int,
  y : Int,
  viewport_width : Int,
  viewport_height : Int,
) -> Bool {
  let sx = golden_screen_x(
    x.to_double() + 0.5,
    y.to_double() + 0.5,
    viewport_width,
  )
  let sy = golden_screen_y(
    x.to_double() + 0.5,
    y.to_double() + 0.5,
    viewport_height,
  )
  sx >= -80.0 &&
  sx <= viewport_width.to_double() + 80.0 &&
  sy >= -80.0 &&
  sy <= viewport_height.to_double() + 80.0
}

///|
/// Keep a bounded rolling frame profile on the document root. This has no
/// rendering authority; it makes the live map's actual frame cost observable
/// without a second Canvas or a development-only build.
extern "js" fn intersection_road_view_record_benchmark(
  prepare_ms : Double,
  terrain_ms : Double,
  graph_ms : Double,
  objects_ms : Double,
  finish_ms : Double,
  total_ms : Double,
) -> Unit =
  #| (prepare, terrain, graph, objects, finish, total) => {
  #|   let state = globalThis.__moontownIntersectionFrameBenchmark;
  #|   if (!state) {
  #|     state = { samples: [] };
  #|     globalThis.__moontownIntersectionFrameBenchmark = state;
  #|   }
  #|   state.samples.push({ prepare, terrain, graph, objects, finish, total });
  #|   if (state.samples.length > 90) state.samples.shift();
  #|   if (state.samples.length % 10 !== 0) return;
  #|   const root = globalThis.document?.documentElement;
  #|   if (!root) return;
  #|   const mean = key => state.samples.reduce(
  #|     (sum, sample) => sum + sample[key], 0,
  #|   ) / state.samples.length;
  #|   const p95 = key => state.samples.map(sample => sample[key])
  #|     .sort((left, right) => left - right)[
  #|       Math.min(state.samples.length - 1, Math.floor(state.samples.length * 0.95))
  #|     ];
  #|   root.dataset.intersectionFrameMeanMs = mean("total").toFixed(2);
  #|   root.dataset.intersectionFrameP95Ms = p95("total").toFixed(2);
  #|   root.dataset.intersectionPrepareMeanMs = mean("prepare").toFixed(2);
  #|   root.dataset.intersectionTerrainMeanMs = mean("terrain").toFixed(2);
  #|   root.dataset.intersectionGraphMeanMs = mean("graph").toFixed(2);
  #|   root.dataset.intersectionObjectsMeanMs = mean("objects").toFixed(2);
  #|   root.dataset.intersectionFinishMeanMs = mean("finish").toFixed(2);
  #| }

///|
/// Each accepted preview building owns its footprint and one-tile apron in
/// the same terrain pass that paints the old map. This is deliberately a
/// presentation-only projection: it changes the land skin under the new
/// image asset without mutating the semantic TownSnapshot or parcel graph.
fn intersection_road_preview_building_land_type(style : String) -> String {
  match style {
    "campus" | "courtyard" | "civic" => "plaza"
    "industrial" | "lowrise" | "block" | "row" | "tower" => "urban"
    _ => "grass"
  }
}

///|
/// Return the land-type overrides for every new footprint and its apron. Graph
/// cells are left to the road painter so a frontage road always remains
/// visible; all other cells receive the building's explicit urban/plaza skin.
fn intersection_road_preview_building_land_cells(
  buildings : Map[Int, Array[IntersectionRoadPreviewBuilding]],
  cache_key : String,
) -> Map[String, String] {
  match intersection_road_preview_land_cache.get(cache_key) {
    Some(cached) => return cached
    None => ()
  }
  let result : Map[String, String] = Map([])
  for _, items in buildings {
    for building in items {
      let land_type = intersection_road_preview_building_land_type(
        building.style,
      )
      for y in (building.y - building.apron)..<=(building.y + building.depth) {
        for x in (building.x - building.apron)..<=(building.x + building.width) {
          if x >= 0 &&
            y >= 0 &&
            x < 256 &&
            y < 144 &&
            !reference_intersection_preview_graph_cell_at(x, y) {
            result[town_canvas_road_key(x, y)] = land_type
          }
        }
      }
    }
  }
  intersection_road_preview_land_cache[cache_key] = result
  result
}

///|
fn draw_intersection_road_preview_frame(
  context : @dom.CanvasRenderingContext2D,
  snapshot : @energy_valley_contract.TownSnapshot,
  view : TownCanvasViewState,
  viewport_width : Int,
  viewport_height : Int,
) -> Bool {
  let benchmark_start = intersection_road_view_benchmark_now()
  if reference_osm_block_graph_ready() &&
    !reference_osm_cartoon_road_graph_prepare() {
    return false
  }
  // Pointer authority is released before any authoring-only pixels are drawn;
  // even a later rendering failure cannot leave a stale semantic frame active.
  golden_valley_clear_canvas_frame()
  context.clear_rect(
    0.0,
    0.0,
    viewport_width.to_double(),
    viewport_height.to_double(),
  )
  let roads = town_snapshot_canvas_roads(snapshot)
  let road_lookup = town_snapshot_canvas_road_lookup(roads)
  let authoritative_transport = authoritative_energy_valley_transport_ready()
  let presentation_ready = !authoritative_transport &&
    reference_road_presentation_snapshot_ready()
  let canvas_cols = town_snapshot_canvas_cols(snapshot)
  let canvas_rows = town_snapshot_canvas_rows(snapshot)
  let stale_ground_cells = intersection_road_view_stale_ground_cells(snapshot)
  let preview_buildings = intersection_road_preview_buildings_by_depth(snapshot)
  let preview_cache_key = intersection_road_preview_cache_key(snapshot)
  let (image_building_count, vector_building_count) = intersection_road_preview_building_counts(
    preview_buildings,
  )
  intersection_road_preview_record_building_counts(
    image_building_count, vector_building_count,
  )
  let building_land_cells = intersection_road_preview_building_land_cells(
    preview_buildings, preview_cache_key,
  )
  let benchmark_prepared = intersection_road_view_benchmark_now()
  let static_cache_key = intersection_road_view_static_cache_key(
    preview_cache_key,
    viewport_width,
    viewport_height,
    view.hour,
  )
  let static_cache_supported = intersection_road_view_static_cache_supported()
  if !intersection_road_view_draw_static_cache(context, static_cache_key) {
    let static_context = intersection_road_view_prepare_static_cache(
      context, static_cache_key,
    )
    golden_draw_background(
      static_context,
      viewport_width,
      viewport_height,
      view.hour,
    )
    let animated_water : Array[(Int, Int, String)] = []
    for y in 0..<canvas_rows {
      for x in 0..<canvas_cols {
        // Reuse the old map's complete tile painter. Only its separate bridge
        // glyph is disabled; this keeps every terrain value and pattern exact.
        let road = road_lookup.get(town_canvas_road_key(x, y))
        let key = town_canvas_road_key(x, y)
        // A reviewed lot owns the full 7×7 land envelope. Check it before the
        // hidden legacy road lookup so one stale semantic road cell cannot
        // punch a differently colored tile through an otherwise uniform lot.
        let terrain_override = match building_land_cells.get(key) {
          Some(land_type) => Some(land_type)
          None if road is Some(_) =>
            // Old semantic roads remain in the snapshot for compatibility, but
            // their paving must not leak into this single presentation. The
            // reviewed graph owns every visible road pixel.
            Some(intersection_road_view_stale_ground_terrain(x, y))
          None if stale_ground_cells.contains(key) =>
            Some(intersection_road_view_stale_ground_terrain(x, y))
          _ => None
        }
        let road_visible = golden_canonical_old_map_road_visible(
          road, authoritative_transport, presentation_ready,
        )
        let terrain = terrain_override.unwrap_or(
          golden_canonical_old_map_terrain(
            snapshot, road_lookup, road, road_visible, authoritative_transport, x,
            y,
          ),
        )
        if (terrain == "water" || terrain == "bridge") &&
          intersection_road_view_tile_on_screen(
            x, y, viewport_width, viewport_height,
          ) {
          animated_water.push((x, y, terrain))
        }
        golden_draw_tile(
          static_context, snapshot, road_lookup, authoritative_transport, presentation_ready,
          false, terrain_override, x, y, viewport_width, viewport_height,
        )
      }
    }
    for _, buildings in preview_buildings {
      for building in buildings {
        let (center_x, center_y) = intersection_road_preview_building_center(
          building,
        )
        golden_draw_intersection_road_preview_building_lot(
          static_context,
          golden_screen_x(center_x, center_y, viewport_width),
          golden_screen_y(center_x, center_y, viewport_height),
          golden_valley_camera_zoom(),
          intersection_road_preview_building_land_type(building.style),
        )
      }
    }
    if static_cache_supported {
      intersection_road_preview_water_cache[static_cache_key] = animated_water
      intersection_road_view_commit_static_cache(context, static_cache_key)
    }
  }
  // Water retains its original animation. Its complete diamond overwrites the
  // cached water tile before roads and bridges are painted, so caching cannot
  // freeze or lower the quality of the shoreline animation.
  match
    (if static_cache_supported {
      intersection_road_preview_water_cache.get(static_cache_key)
    } else {
      None
    }) {
    Some(animated_water) =>
      for item in animated_water {
        let (x, y, terrain) = item
        golden_draw_tile(
          context,
          snapshot,
          road_lookup,
          authoritative_transport,
          presentation_ready,
          false,
          Some(terrain),
          x,
          y,
          viewport_width,
          viewport_height,
        )
      }
    None => ()
  }
  let benchmark_terrain = intersection_road_view_benchmark_now()
  golden_draw_intersection_road_preview_graph(
    context,
    golden_valley_camera_x(),
    golden_valley_camera_y(),
    golden_valley_camera_zoom(),
    viewport_width,
    viewport_height,
  )
  let benchmark_graph = intersection_road_view_benchmark_now()
  let installations = intersection_road_preview_installations_by_depth(snapshot)
  // Do not reuse semantic agents here: their route positions belong to the
  // hidden legacy road graph. These six image-only walkers are sampled from
  // validated intersection polylines and therefore stay on the visible road.
  let agents = intersection_road_preview_graph_walkers(
    golden_animation_seconds(),
    golden_prefers_reduced_motion(),
  )
  golden_begin_spring_civic_building_asset_frame()
  for depth in 0..<(canvas_cols + canvas_rows + 32) {
    match installations.get(depth) {
      Some(items) =>
        golden_draw_town_snapshot_installations(
          context,
          items,
          authoritative_transport,
          viewport_width,
          viewport_height,
          view.hour,
        )
      None => ()
    }
    // Actors are pixels only in this authoring view: the semantic frame stays
    // cleared, so neither residents nor the player acquire hit areas.
    golden_draw_agents_at_depth(
      context, agents, depth, viewport_width, viewport_height,
    )
    match preview_buildings.get(depth) {
      Some(buildings) =>
        for building in buildings {
          golden_draw_intersection_road_preview_building(
            context, building, viewport_width, viewport_height,
          )
        }
      None => ()
    }
  }
  golden_end_spring_civic_building_asset_frame()
  let benchmark_objects = intersection_road_view_benchmark_now()
  golden_draw_weather(
    context,
    view.weather,
    view.tick,
    viewport_width,
    viewport_height,
  )
  golden_draw_day_night(context, viewport_width, viewport_height, view.hour)
  golden_ctx_global_alpha(context, 1.0)
  golden_draw_energy_valley_coordinate_grid(
    context,
    golden_valley_camera_x(),
    golden_valley_camera_y(),
    golden_valley_camera_zoom(),
    viewport_width,
    viewport_height,
    energy_valley_coordinate_grid_spacing(golden_valley_camera_zoom()),
  )
  intersection_reference_draw_points(context, viewport_width, viewport_height)
  let benchmark_finish = intersection_road_view_benchmark_now()
  intersection_road_view_record_benchmark(
    benchmark_prepared - benchmark_start,
    benchmark_terrain - benchmark_prepared,
    benchmark_graph - benchmark_terrain,
    benchmark_objects - benchmark_graph,
    benchmark_finish - benchmark_objects,
    benchmark_finish - benchmark_start,
  )
  true
}
