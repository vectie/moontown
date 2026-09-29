///|
let town_bearing_families : Array[String] = [
  "lowrise", "row", "courtyard", "block", "campus", "civic", "industrial", "tower",
]

///|
/// Synthetic display identities carry their explicit variant. Existing source
/// identities keep a stable hash choice and are never renamed or retyped.
fn town_bearing_variant(id : String) -> Int {
  for variant in 0..<3 {
    if id.has_prefix("procedural-grid-diversity-\{variant}-") {
      return variant
    }
  }
  energy_valley_mod(ecosystem_stable_hash(id), 3)
}

///|
fn town_bearing_find_diversity_lot(
  style : String,
  variant : Int,
  occupied : Array[IntersectionRoadPreviewBuilding],
) -> IntersectionRoadPreviewBuilding? {
  let seed = energy_valley_mod(
    ecosystem_stable_hash("\{style}:\{variant}"),
    576,
  )
  // Prefer a full four-tile composition; compact versions must still reserve
  // a complete apron. No zero-apron, water, woodland, or road exceptions.
  for span in [4, 3] {
    for phase in 0..<16 {
      for i in 0..<576 {
        let (x, y) = town_scene_infill_site(i + seed, phase % 4, phase / 4)
        if !wenyu_scene_region_clear(
            wenyu_scene_prefix,
            x - 1,
            y - 1,
            span + 2,
            span + 2,
          ) {
          continue
        }
        let candidate : IntersectionRoadPreviewBuilding = {
          id: "procedural-grid-diversity-\{variant}-\{style}-\{x}-\{y}",
          style,
          asset_path: intersection_road_preview_building_asset_path(
            style, variant,
          ).unwrap_or(""),
          x,
          y,
          width: span,
          depth: span,
          apron: 1,
          depth_key: x + y + span * 2,
        }
        if !intersection_road_preview_building_geometry_valid(candidate) ||
          !wenyu_scene_lot_valid(candidate) {
          continue
        }
        let mut conflict = false
        for other in occupied {
          if intersection_road_preview_buildings_overlap(candidate, other) {
            conflict = true
            break
          }
        }
        if !conflict {
          return Some(candidate)
        }
      }
    }
  }
  None
}

///|
/// Complete the architectural vocabulary AFTER normal admission, so narrow
/// buildable pockets cannot silently eliminate every civic/market/workshop.
/// Only new decorative infill is added. All existing lots/identities survive.
fn town_bearing_complete_mix(
  buildings : Map[Int, Array[IntersectionRoadPreviewBuilding]],
) -> Unit {
  if wenyu_scene_prefix.length() != 257 * 145 ||
    wenyu_scene_road_prefix.length() != 257 * 145 {
    return
  }
  let occupied : Array[IntersectionRoadPreviewBuilding] = []
  let seen : Map[String, Bool] = Map([])
  for _, items in buildings {
    for building in items {
      occupied.push(building)
      seen["\{building.style}:\{town_bearing_variant(building.id)}"] = true
    }
  }
  for style in town_bearing_families {
    for variant in 0..<3 {
      if seen.contains("\{style}:\{variant}") {
        continue
      }
      match town_bearing_find_diversity_lot(style, variant, occupied) {
        None => () // Lack of safe land is visible in the coverage diagnostics.
        Some(building) => {
          occupied.push(building)
          match buildings.get(building.depth_key) {
            Some(items) => items.push(building)
            None => buildings[building.depth_key] = [building]
          }
        }
      }
    }
  }
}
